import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _tokenKey = 'auth_token';

  /// Guarda o ID do utilizador e o token JWT após o login
  static Future<void> guardarSessao(int userId, [String? token]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    }
  }

  /// Verifica se já existe uma sessão guardada (ID do utilizador)
  static Future<int?> verificarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  /// Devolve o token JWT guardado, ou null se não existir
  static Future<String?> obterToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Apaga a sessão ao fazer logout
  static Future<void> limparSessao() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_tokenKey);
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
