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
}
