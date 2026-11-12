import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _tokenKey = 'auth_token';

  /// O refresh token, que vive mais do que o de acesso e vale mais: com ele
  /// pedem-se tokens de acesso novos. Fica no cofre, ao lado do outro.
  static const String _refreshKey = 'refresh_token';

  /// Com quanta antecedência se pede um token novo.
  ///
  /// O de acesso dura 15 minutos. Renovar um pouco antes de ele morrer evita
  /// apanhar o 401 a meio de um pedido — e os relógios do telemóvel e do
  /// servidor nunca estão exatamente iguais.
  static const Duration _margemDeRenovacao = Duration(minutes: 1);

  /// O token vive aqui, nao em SharedPreferences.
  ///
  /// As SharedPreferences sao um ficheiro XML em claro na pasta da app. Num
  /// telemovel com root, ou numa copia de seguranca, o token le-se com um
  /// editor de texto — e com ele entra-se na conta do investidor sem saber a
  /// palavra-passe. Isto guarda-o no Keystore do Android ou no Keychain do
  /// iOS, onde fica cifrado pelo sistema.
  ///
  /// O ID do utilizador fica onde estava: e so um numero, nao abre nada.
  static const FlutterSecureStorage _cofre = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Na web nao se usa o cofre.
  ///
  /// Duas razoes. A pratica: o flutter_secure_storage nao arranca numa
  /// compilacao de release para web — rebenta com MissingPluginException
  /// antes do runApp e o ecra fica branco. Em profile passa, o que torna isto
  /// facil de nao dar por ele.
  ///
  /// A de fundo: mesmo que arrancasse, na web nao ha Keystore nem Keychain. A
  /// implementacao web cifra para dentro do localStorage com uma chave que
  /// tambem la esta, o que protege de pouco. Nao vale a pena trocar o arranque
  /// da app por isso.
  ///
  /// Onde isto conta mesmo — o telemovel, que e o produto — nada muda.
  static bool get _usaCofre => !kIsWeb;

  /// Guarda o ID do utilizador e o token JWT após o login
  static Future<void> guardarSessao(int userId, [String? token]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    if (token == null) return;

    await guardarToken(token);
  }

  /// Guarda só o token de acesso. Usa-se no login e a cada renovação.
  static Future<void> guardarToken(String token) async {
    if (_usaCofre) {
      await _cofre.write(key: _tokenKey, value: token);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    }
  }

  /// Guarda o refresh token. A API manda-o no login e troca-o a cada
  /// renovação; quando a resposta o traz a null é para manter o que já se
  /// tem (dois pedidos em paralelo), por isso aqui null não apaga nada.
  static Future<void> guardarRefreshToken(String? refreshToken) async {
    if (refreshToken == null) return;
    if (_usaCofre) {
      await _cofre.write(key: _refreshKey, value: refreshToken);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_refreshKey, refreshToken);
    }
  }

  static Future<String?> obterRefreshToken() async {
    if (!_usaCofre) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshKey);
    }
    return _cofre.read(key: _refreshKey);
  }

  /// Verifica se já existe uma sessão guardada (ID do utilizador)
  static Future<int?> verificarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  /// Devolve o token JWT guardado, ou null se não existir
  static Future<String?> obterToken() async {
    if (!_usaCofre) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    }

    final guardado = await _cofre.read(key: _tokenKey);
    if (guardado != null) return guardado;
    return _mudarTokenAntigoDeSitio();
  }

  /// Quem ja tinha a app instalada tem o token no sitio antigo. Em vez de o
  /// obrigar a entrar outra vez, passa-se o token para o cofre na primeira
  /// vez que e pedido e apaga-se o que estava em claro.
  ///
  /// Pode sair daqui em algumas versoes, quando ninguem tiver ficado para
  /// tras: a partir dai e so codigo a tratar de um caso que ja nao existe.
  static Future<String?> _mudarTokenAntigoDeSitio() async {
    final prefs = await SharedPreferences.getInstance();
    final antigo = prefs.getString(_tokenKey);
    if (antigo == null) return null;

    await _cofre.write(key: _tokenKey, value: antigo);
    await prefs.remove(_tokenKey);
    return antigo;
  }

  /// Apaga a sessão ao fazer logout
  static Future<void> limparSessao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    // Apaga tambem a chave antiga: se o logout acontecer antes de o token
    // chegar a ser mudado de sitio, nao pode ficar la para tras.
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    if (_usaCofre) {
      await _cofre.delete(key: _tokenKey);
      await _cofre.delete(key: _refreshKey);
    }
  }

  /// Há sessão guardada que ainda dá para usar: id, token, e ou o token
  /// serve ou existe um refresh token para pedir outro.
  ///
  /// Antes, um token expirado limpava a sessão e mandava a pessoa de volta ao
  /// login. Com o token de acesso a durar 15 minutos isso passou a estar
  /// errado: expirado deixou de querer dizer acabado — quem tem refresh token
  /// continua com sessão, e a renovação faz-se no primeiro pedido.
  static Future<int?> obterSessaoValida() async {
    final userId = await verificarSessao();
    final token = await obterToken();

    if (userId == null || token == null) return null;

    if (precisaDeRenovar(token) && await obterRefreshToken() == null) {
      await limparSessao();
      return null;
    }

    return userId;
  }

  /// Está na hora de pedir um token de acesso novo.
  ///
  /// Pura de propósito, e por isso testável: o resto desta classe fala com o
  /// cofre, que num teste não existe.
  static bool precisaDeRenovar(String? token) {
    if (token == null || token.isEmpty) return true;

    final fim = expiraEm(token);
    // Sem "exp" legível trata-se como se estivesse a acabar. A API mete
    // sempre o claim, por isso um token sem ele ou não se lê, ou não veio de
    // onde devia — e pedir um a mais não estraga nada.
    if (fim == null) return true;

    return DateTime.now().add(_margemDeRenovacao).isAfter(fim);
  }

  /// Quando o token de acesso morre, lido do claim "exp". null quando o token
  /// não se lê ou não traz "exp".
  ///
  /// A assinatura não se verifica aqui — isso é sempre do servidor. Isto só
  /// serve para saber quando pedir outro.
  static DateTime? expiraEm(String token) {
    try {
      final partes = token.split('.');
      if (partes.length != 3) return null;

      String payload = partes[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final json = jsonDecode(utf8.decode(base64.decode(payload)));
      final exp = (json as Map)['exp'];
      if (exp is! int) return null;

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (_) {
      return null;
    }
  }
}
