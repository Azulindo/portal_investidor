import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _tokenKey = 'auth_token';

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

  /// Guarda o ID do utilizador e o token JWT após o login
  static Future<void> guardarSessao(int userId, [String? token]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    if (token != null) {
      await _cofre.write(key: _tokenKey, value: token);
    }
  }

  /// Verifica se já existe uma sessão guardada (ID do utilizador)
  static Future<int?> verificarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  /// Devolve o token JWT guardado, ou null se não existir
  static Future<String?> obterToken() async {
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
    await _cofre.delete(key: _tokenKey);
  }

  /// NOVO: Verifica se a sessão guardada ainda é válida - ou seja, se existe
  /// um user_id e um token guardados E o token ainda não expirou.
  /// Se o token já tiver expirado, limpa a sessão guardada (para não ficar
  /// "meio autenticado") e devolve null, obrigando a um novo login.
  /// Devolve o user_id se a sessão for válida, ou null caso contrário.
  static Future<int?> obterSessaoValida() async {
    final userId = await verificarSessao();
    final token = await obterToken();

    if (userId == null || token == null) return null;

    if (_tokenExpirado(token)) {
      await limparSessao();
      return null;
    }

    return userId;
  }

  /// Decodifica o claim "exp" do JWT (sem validar a assinatura - isso é
  /// sempre feito no servidor) e compara com a hora atual.
  static bool _tokenExpirado(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      String payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }

      final decoded = utf8.decode(base64.decode(payload));
      final Map<String, dynamic> json = jsonDecode(decoded);
      final exp = json['exp'];
      if (exp == null) return false;

      final expiraEm = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
      return DateTime.now().isAfter(expiraEm);
    } catch (_) {
      // Token ilegível/corrompido - trata como expirado para forçar login.
      return true;
    }
  }
}
