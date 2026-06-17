import 'package:flutter/material.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../services/api_service.dart';
import '../utils/ui_helpers.dart';
import 'dashboard_screen.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final LocalAuthentication auth = LocalAuthentication();

  bool _obscurePassword = true;

  void _fazerLogin() async {
    UIHelpers.showLoadingDialog(context);

    try {
      final resultado = await _apiService.fazerLoginJson(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 👇 SÓ usa o context se o widget ainda estiver montado
      if (!mounted) return;

      Navigator.pop(context); // fecha o loading

      final bool sucesso = resultado.$1;
      final String mensagem = resultado.$2;
      final int? userId = resultado.$3;
      final String? token = resultado.$4;

      if (sucesso && userId != null) {
        await AuthService.guardarSessao(userId, token);
        ApiService.idLogado = userId;
        ApiService.definirToken(token);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (c, a1, a2) => const DashboardScreen(),
            transitionsBuilder: (c, anim, a2, child) => FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      } else {
        UIHelpers.showErrorSnackBar(context, mensagem);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      UIHelpers.showErrorSnackBar(context, 'Ocorreu um erro inesperado.');
    }
  }

  Future<void> _entrarComBiometria() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biometria em manutenção (Aguarda integração de Cache).'), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: COColors.brand900,
      resizeToAvoidBottomInset: true,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: COTokens.space6, vertical: COTokens.space8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: COTokens.space8, vertical: COTokens.space4),
                child: Image.asset('assets/images/logo.png', height: 130, fit: BoxFit.contain),
              ),
              const SizedBox(height: COTokens.space8),
              const Text('PORTAL DO INVESTIDOR', style: TextStyle(color: COColors.brand300, fontSize: 11, fontWeight: COTokens.fwMedium, letterSpacing: 2)),
              const SizedBox(height: COTokens.space6),

              TextField(
                controller: _emailController, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: COColors.white, fontSize: 14, fontWeight: COTokens.fwRegular),
                decoration: InputDecoration(labelText: 'Email', labelStyle: const TextStyle(color: COColors.brand300, fontSize: 13), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(COTokens.radiusSm), borderSide: const BorderSide(color: COColors.brand700)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(COTokens.radiusSm), borderSide: const BorderSide(color: COColors.brand300, width: 1.5)), filled: true, fillColor: COColors.brand700),
              ),
              const SizedBox(height: COTokens.space4),

              TextField(
                controller: _passwordController, obscureText: _obscurePassword, style: const TextStyle(color: COColors.white, fontSize: 14, fontWeight: COTokens.fwRegular),
                decoration: InputDecoration(labelText: 'Password', labelStyle: const TextStyle(color: COColors.brand300, fontSize: 13), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(COTokens.radiusSm), borderSide: const BorderSide(color: COColors.brand700)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(COTokens.radiusSm), borderSide: const BorderSide(color: COColors.brand300, width: 1.5)), filled: true, fillColor: COColors.brand700, suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: COColors.brand300, size: 20), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
              ),
              const SizedBox(height: COTokens.space8),

              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _fazerLogin, style: ElevatedButton.styleFrom(backgroundColor: COColors.white, padding: const EdgeInsets.symmetric(vertical: 20), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero), elevation: 0), child: const Text('ENTRAR', style: TextStyle(color: COColors.brand900, letterSpacing: 2, fontWeight: COTokens.fwBold, fontSize: 13)))),
              const SizedBox(height: COTokens.space4),

              GestureDetector(onTap: _entrarComBiometria, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: COColors.brand700.withValues(alpha: 0.3), shape: BoxShape.circle, border: Border.all(color: COColors.brand500)), child: const Icon(Icons.fingerprint_rounded, size: 32, color: COColors.brand300))),
              const SizedBox(height: 8),
              const Text('Acesso Rápido', style: TextStyle(color: COColors.brand500, fontSize: 11, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }
}
