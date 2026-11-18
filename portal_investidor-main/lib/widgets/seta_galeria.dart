import 'package:flutter/material.dart';

// =========================================================
// BOTÃO DE SETA PARA NAVEGAR NA GALERIA DE IMAGENS
// (a galeria do topo do detalhe do empreendimento)
// =========================================================
class SetaGaleria extends StatelessWidget {
  final IconData icon;
  final bool visible;
  final VoidCallback onPressed;

  const SetaGaleria({
    super.key,
    required this.icon,
    required this.visible,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !visible,
        child: Material(
          color: Colors.black.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}
