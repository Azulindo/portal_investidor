import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/utils/token_de_email.dart';

/// Tirar o token de um link colado do email.
///
/// Isto e o que substitui os deep links enquanto nao houver nenhum, por isso
/// tem de aguentar o que as pessoas colam de verdade: o link inteiro, o link
/// partido em linhas pelo cliente de email, ou so o token.
void main() {
  const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJpZCI6MX0.abc-123_XYZ';

  group('O que deve dar token', () {
    test('o link inteiro do email', () {
      expect(
        TokenDeEmail.extrair(
          'https://cleveroption.pt/redefinir-password?token=$jwt',
        ),
        jwt,
      );
    });

    test('o link com mais parametros a seguir', () {
      expect(
        TokenDeEmail.extrair(
          'https://cleveroption.pt/confirmar-email?token=$jwt&origem=email',
        ),
        jwt,
      );
    });

    test('o token nao e o primeiro parametro', () {
      expect(
        TokenDeEmail.extrair('https://x.pt/a?origem=email&token=$jwt'),
        jwt,
      );
    });

    test('o link partido em linhas pelo cliente de email', () {
      expect(
        TokenDeEmail.extrair('https://cleveroption.pt/redefinir-password\n'
            '?token=$jwt'),
        jwt,
      );
    });

    test('o token colado sozinho', () {
      expect(TokenDeEmail.extrair(jwt), jwt);
      expect(TokenDeEmail.extrair('  $jwt  '), jwt);
    });

    test('o token codificado no URL', () {
      expect(
        TokenDeEmail.extrair('https://x.pt/a?token=abc%2Edef%2Eghi'),
        'abc.def.ghi',
      );
    });
  });

  group('O que nao deve dar token', () {
    test('vazio ou so espacos', () {
      expect(TokenDeEmail.extrair(null), isNull);
      expect(TokenDeEmail.extrair(''), isNull);
      expect(TokenDeEmail.extrair('   '), isNull);
    });

    test('uma frase colada por engano', () {
      // Um token e um JWT, com tres partes separadas por pontos. Sem isso
      // mandavamos qualquer coisa para a API e a mensagem de erro vinha de
      // la, em vez de se explicar aqui o que a pessoa tem de colar.
      expect(TokenDeEmail.extrair('bom dia, aqui esta o meu codigo'), isNull);
      expect(TokenDeEmail.extrair('123456'), isNull);
    });

    test('um link sem token nenhum', () {
      expect(
        TokenDeEmail.extrair('https://cleveroption.pt/redefinir-password'),
        isNull,
      );
    });

    test('token= vazio', () {
      expect(TokenDeEmail.extrair('https://x.pt/a?token=&b=1'), isNull);
    });
  });
}
