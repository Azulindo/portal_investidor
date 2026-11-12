import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/services/api_service.dart';
import 'package:portal_investidor/services/auth_service.dart';

/// Renovação da sessão.
///
/// Desde que a API passou a usar tokens curtos, o de acesso dura 15 minutos e
/// é o refresh token que mantém a sessão (`POST /auth/refresh`). Antes disto a
/// app guardava o token e usava-o até a API o recusar — contra o servidor a
/// sério, o utilizador era deitado fora do portal a cada quarto de hora.
///
/// As duas peças testáveis são as puras: quando se decide renovar, e como se
/// lê a resposta. A chamada em si não se pode simular, porque o ApiService
/// cria o cliente http por dentro.

/// Um JWT de mentira: só o payload conta, que é o que a app lê. A assinatura
/// nunca é verificada no telemóvel — isso é sempre do servidor.
String jwt(Map<String, dynamic> payload) {
  String semPreenchimento(String s) => s.replaceAll('=', '');
  final cabecalho = semPreenchimento(
    base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256'}))),
  );
  final corpo = semPreenchimento(
    base64Url.encode(utf8.encode(jsonEncode(payload))),
  );
  return '$cabecalho.$corpo.assinatura-de-mentira';
}

String jwtQueExpiraEm(Duration daqui) => jwt({
      'id': 999,
      'exp': DateTime.now().add(daqui).millisecondsSinceEpoch ~/ 1000,
    });

void main() {
  group('quando renovar', () {
    test('um token com tempo de sobra não se renova', () {
      expect(
        AuthService.precisaDeRenovar(jwtQueExpiraEm(const Duration(minutes: 14))),
        isFalse,
      );
    });

    test('um token a acabar renova-se antes de morrer', () {
      // A margem é de um minuto: assim a renovação não acontece a meio de um
      // pedido, e os relógios do telemóvel e do servidor podem divergir um
      // pouco sem estragar nada.
      expect(
        AuthService.precisaDeRenovar(jwtQueExpiraEm(const Duration(seconds: 30))),
        isTrue,
      );
    });

    test('um token já expirado renova-se', () {
      expect(
        AuthService.precisaDeRenovar(jwtQueExpiraEm(const Duration(minutes: -5))),
        isTrue,
      );
    });

    test('sem token, ilegível ou sem "exp", renova-se', () {
      expect(AuthService.precisaDeRenovar(null), isTrue);
      expect(AuthService.precisaDeRenovar(''), isTrue);
      expect(AuthService.precisaDeRenovar('isto-nao-e-um-jwt'), isTrue);
      expect(AuthService.precisaDeRenovar('a.b.c'), isTrue);
      expect(AuthService.precisaDeRenovar(jwt({'id': 999})), isTrue);
    });

    test('o "exp" lê-se como segundos desde a época', () {
      final fim = DateTime.now().add(const Duration(minutes: 10));
      final lido = AuthService.expiraEm(
        jwt({'exp': fim.millisecondsSinceEpoch ~/ 1000}),
      );

      expect(lido, isNotNull);
      // Ao segundo, que é a resolução do claim.
      expect(lido!.difference(fim).inSeconds.abs(), lessThanOrEqualTo(1));
    });
  });

  group('resposta da renovação', () {
    test('traz o par de tokens novo', () {
      final tokens = ApiService.tokensDeRenovacao(jsonEncode({
        'status': 200,
        'code': 'AUTH_SESSION_REFRESHED',
        'data': {
          'token': 'acesso-novo',
          'refreshToken': 'renovacao-nova',
          'expiresIn': 900,
        },
      }));

      expect(tokens, isNotNull);
      expect(tokens!.$1, 'acesso-novo');
      expect(tokens.$2, 'renovacao-nova');
    });

    test('refreshToken a null quer dizer "mantém o que tens"', () {
      // Acontece quando dois pedidos renovam ao mesmo tempo: o refresh token
      // novo foi na resposta do outro. Apagar o que está guardado por causa
      // deste null deitava a sessão fora.
      final tokens = ApiService.tokensDeRenovacao(jsonEncode({
        'data': {'token': 'acesso-novo', 'refreshToken': null},
      }));

      expect(tokens, isNotNull);
      expect(tokens!.$1, 'acesso-novo');
      expect(tokens.$2, isNull);
    });

    test('uma resposta sem token não serve para nada', () {
      expect(
        ApiService.tokensDeRenovacao(jsonEncode({'data': {'expiresIn': 900}})),
        isNull,
      );
      expect(
        ApiService.tokensDeRenovacao(jsonEncode({'data': {'token': ''}})),
        isNull,
      );
      expect(ApiService.tokensDeRenovacao(jsonEncode({'data': 'nada'})), isNull);
      expect(ApiService.tokensDeRenovacao('<html>erro</html>'), isNull);
      expect(ApiService.tokensDeRenovacao(''), isNull);
    });
  });

  group('um refresh recusado é uma sessão que acabou', () {
    test('a API usa os mesmos códigos dos pedidos autenticados', () {
      // É o que está escrito no auth.controller da API, e é o que deixa a app
      // tratar os dois casos no mesmo sítio.
      expect(
        FimDeSessao.motivoPara(401, '{"code":"AUTH_TOKEN_EXPIRED"}'),
        FimDeSessao.expirada,
      );
      expect(
        FimDeSessao.motivoPara(401, '{"code":"AUTH_INVALID_TOKEN"}'),
        FimDeSessao.expirada,
      );
      expect(
        FimDeSessao.motivoPara(403, '{"code":"AUTH_ACCOUNT_BLOCKED"}'),
        FimDeSessao.bloqueada,
      );
    });
  });
}
