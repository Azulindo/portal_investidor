import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/services/api_service.dart';

/// Quando é que a app deve dar a sessão por acabada.
///
/// A API corta a sessão de duas maneiras diferentes e só uma é um 401. A
/// outra — a conta bloqueada no backoffice — chega como 403, porque o token
/// continua válido; o que deixou de valer foi a conta. A app só olhava para
/// o 401, e num 403 dizia "não tem permissão para ver isto" e deixava a
/// pessoa presa num ecrã que nunca carregava.
///
/// Os códigos são os do requireAuth.ts da API. Se mudarem lá, é aqui que se
/// dá por isso.
void main() {
  String corpo(String codigo) =>
      '{"status":403,"message":"qualquer coisa","code":"$codigo"}';

  group('Termina a sessão', () {
    test('um 401 é sempre sessão expirada, venha o que vier no corpo', () {
      expect(FimDeSessao.motivoPara(401, ''), FimDeSessao.expirada);
      expect(
        FimDeSessao.motivoPara(401, corpo('AUTH_INVALID_TOKEN')),
        FimDeSessao.expirada,
      );
      expect(
        FimDeSessao.motivoPara(401, corpo('AUTH_MISSING_TOKEN')),
        FimDeSessao.expirada,
      );
    });

    test('um 403 com AUTH_ACCOUNT_BLOCKED é conta bloqueada', () {
      expect(
        FimDeSessao.motivoPara(403, corpo('AUTH_ACCOUNT_BLOCKED')),
        FimDeSessao.bloqueada,
      );
    });
  });

  group('Não termina a sessão', () {
    test('um 403 de falta de permissão deixa a sessão de pé', () {
      // É o caso de um cliente a pedir uma rota de admin. Mandá-lo para o
      // login seria pior do que a mensagem de sempre.
      expect(FimDeSessao.motivoPara(403, corpo('AUTH_FORBIDDEN')), isNull);
    });

    test('um 403 sem código nenhum não conta', () {
      expect(FimDeSessao.motivoPara(403, ''), isNull);
      expect(FimDeSessao.motivoPara(403, '{"message":"nao pode"}'), isNull);
    });

    test('um 403 com corpo que não é JSON não rebenta', () {
      expect(FimDeSessao.motivoPara(403, '<html>502</html>'), isNull);
    });

    test('os outros erros não mexem na sessão', () {
      for (final estado in [400, 404, 409, 422, 500, 503]) {
        expect(
          FimDeSessao.motivoPara(estado, corpo('AUTH_ACCOUNT_BLOCKED')),
          isNull,
          reason: 'o $estado não devia terminar a sessão',
        );
      }
    });
  });

  group('As mensagens', () {
    test('dizem coisas diferentes, porque os casos são diferentes', () {
      // "Expirou" resolve-se a entrar outra vez; "bloqueada" não, e por
      // isso tem de dizer com quem falar.
      expect(FimDeSessao.expirada.mensagem, contains('Inicie sessão'));
      expect(FimDeSessao.bloqueada.mensagem, contains('bloqueada'));
      expect(
        FimDeSessao.bloqueada.mensagem,
        contains('geral@cleveroption.pt'),
      );
    });

    test('são as mesmas do site, palavra por palavra', () {
      // Copiadas do AVISO_FIM_SESSAO em website-cleveroption-1/lib/
      // fimSessao.ts. Quem for bloqueado tem de ler o mesmo no telemóvel e
      // no computador.
      expect(
        FimDeSessao.expirada.mensagem,
        'A sua sessão terminou. Inicie sessão novamente.',
      );
      expect(
        FimDeSessao.bloqueada.mensagem,
        'A sua conta está bloqueada. Para mais informações contacte '
        'geral@cleveroption.pt.',
      );
    });
  });
}
