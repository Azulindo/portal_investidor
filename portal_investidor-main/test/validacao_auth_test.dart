import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/utils/validacao_auth.dart';

/// As regras aqui testadas têm de bater com as do site
/// (components/RegistoForm.tsx), que espelham o schemaRegisto (Zod) da API.
/// Se um destes testes falhar, o registo da app vai ser recusado pelo
/// servidor — ou pior, recusado pela app quando o servidor o aceitaria.
void main() {
  group('email', () {
    test('aceita endereços normais', () {
      expect(ValidacaoAuth.email('joao.silva@email.com'), isNull);
      expect(ValidacaoAuth.email('a+b@dominio-com-hifen.pt'), isNull);
      expect(ValidacaoAuth.email('  comEspacos@email.com  '), isNull);
    });

    test('recusa o que não é endereço', () {
      for (final mau in ['', 'sem-arroba', 'a@b', 'a@b.c', 'a @b.com']) {
        expect(ValidacaoAuth.email(mau), isNotNull, reason: 'devia recusar "$mau"');
      }
    });
  });

  group('telemóvel', () {
    test('conta só os dígitos, ignora espaços, hífens e indicativo', () {
      expect(ValidacaoAuth.telemovel('+351 912 000 000'), isNull);
      expect(ValidacaoAuth.telemovel('912-000-000'), isNull);
      expect(ValidacaoAuth.telemovel('912000000'), isNull);
    });

    test('recusa menos de 9 dígitos', () {
      expect(ValidacaoAuth.telemovel('91200000'), isNotNull);
      expect(ValidacaoAuth.telemovel(''), isNotNull);
    });
  });

  group('palavra-passe', () {
    test('aceita uma que cumpre as cinco regras', () {
      expect(ValidacaoAuth.password('Abcdef1!'), isNull);
      expect(ValidacaoAuth.password('OutraBoa9#'), isNull);
    });

    test('recusa, e diz qual é a regra que falta', () {
      expect(ValidacaoAuth.password('Ab1!'), contains('8 caracteres'));
      expect(ValidacaoAuth.password('ABCDEF1!'), contains('minúscula'));
      expect(ValidacaoAuth.password('abcdef1!'), contains('maiúscula'));
      expect(ValidacaoAuth.password('Abcdefg!'), contains('número'));
      expect(ValidacaoAuth.password('Abcdefg1'), contains('especial'));
    });

    test('os cinco símbolos que a API aceita passam', () {
      for (final s in ['@', r'$', '!', '%', '*', '?', '&', '#']) {
        expect(ValidacaoAuth.password('Abcdefg1$s'), isNull,
            reason: 'devia aceitar o símbolo "$s"');
      }
    });

    test('um símbolo fora da lista da API não conta', () {
      // A API só aceita @$!%*?&# — se a app deixasse passar outro, o registo
      // era recusado no servidor com uma mensagem pior.
      expect(ValidacaoAuth.password('Abcdefg1-'), contains('especial'));
    });
  });

  group('confirmação', () {
    test('tem de ser igual à palavra-passe', () {
      expect(ValidacaoAuth.confirmacao('Abcdef1!', 'Abcdef1!'), isNull);
      expect(ValidacaoAuth.confirmacao('Outra1!', 'Abcdef1!'),
          contains('não coincidem'));
      expect(ValidacaoAuth.confirmacao('', 'Abcdef1!'), contains('Confirme'));
    });
  });

  group('nome', () {
    test('pelo menos duas letras, e diz de que campo se trata', () {
      expect(ValidacaoAuth.nome('João', campo: 'primeiro nome'), isNull);
      expect(ValidacaoAuth.nome('J', campo: 'primeiro nome'),
          contains('primeiro nome'));
      expect(ValidacaoAuth.nome('  ', campo: 'último nome'),
          contains('último nome'));
    });
  });
}
