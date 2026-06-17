import 'package:flutter/material.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';

class UIHelpers {
  // Ecrã de carregamento total com o logótipo a pulsar
  static Future<void> showLoadingDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      // barrierColor define a cor de fundo. Ao usar a cor da app, 
      // esconde completamente os campos de texto do login!
      barrierColor: COColors.brand900, 
      builder: (BuildContext context) {
        return const Center(
          child: _PulseLogoLoading(), // Animação do logo real
        );
      },
    );
  }

  // Barra de erro flutuante (mantida igual)
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: COTokens.fwMedium,
          ),
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(COTokens.radiusSm),
        ),
        margin: const EdgeInsets.all(COTokens.space4),
      ),
    );
  }

  /// Widget de estado de erro reutilizável, com opção de "Tentar novamente"
  /// e, opcionalmente, um botão para voltar atrás. Usado dentro de
  /// FutureBuilders/conteúdo de ecrãs para evitar ficar bloqueado numa
  /// tela de erro sem saída.
  static Widget buildErrorState({
    required String message,
    VoidCallback? onRetry,
    bool showBackButton = false,
    BuildContext? context,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(COTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: COColors.brand300),
            const SizedBox(height: COTokens.space4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: COColors.neutral500, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: COTokens.space6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, color: COColors.brand300, size: 18),
                    label: const Text('TENTAR NOVAMENTE',
                        style: TextStyle(color: COColors.brand300, fontWeight: COTokens.fwBold, letterSpacing: 1, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: COColors.brand500),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(COTokens.radiusSm)),
                    ),
                  ),
                if (onRetry != null && showBackButton && context != null)
                  const SizedBox(width: COTokens.space4),
                if (showBackButton && context != null)
                  TextButton.icon(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back, color: COColors.neutral500, size: 18),
                    label: const Text('VOLTAR',
                        style: TextStyle(color: COColors.neutral500, fontWeight: COTokens.fwBold, letterSpacing: 1, fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET DE ANIMAÇÃO (Logótipo original a pulsar) ---
class _PulseLogoLoading extends StatefulWidget {
  const _PulseLogoLoading();

  @override
  State<_PulseLogoLoading> createState() => _PulseLogoLoadingState();
}

class _PulseLogoLoadingState extends State<_PulseLogoLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // A animação dura 1 segundo para cada lado (acender e apagar)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); 

    // Anima a opacidade entre 40% e 100%
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Image.asset(
        'assets/images/logo.png', // O teu logótipo com as cores originais
        height: 70, 
        fit: BoxFit.contain,
      ),
    );
  }
}
