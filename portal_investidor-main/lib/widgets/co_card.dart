import 'package:flutter/material.dart';

import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';

/// O cartão da Cleveroption.
///
/// O design system é curto e claro quanto a isto: 1px sólido, canto de 5px,
/// 20px por dentro, sem sombras. Antes o portfólio, o painel e os documentos
/// construíam cada um o seu, com bordas por transparência e raios diferentes —
/// era o que fazia a app parecer menos arrumada do que o site.
///
/// Sobre fundo escuro a borda é a `neutral500` esbatida, para marcar o limite
/// sem desenhar uma grade. [destacado] acende-a, para o cartão que o ecrã
/// quer pôr à frente.
class CoCard extends StatelessWidget {
  const CoCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(COTokens.cardPadding),
    this.margin = const EdgeInsets.only(bottom: COTokens.space6),
    this.destacado = false,
    this.semPadding = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool destacado;

  /// Para cartões que começam com uma imagem a sangrar até à borda: o padding
  /// passa a ser posto por dentro, só no texto.
  final bool semPadding;

  @override
  Widget build(BuildContext context) {
    final conteudo = ClipRRect(
      borderRadius: BorderRadius.circular(COTokens.radiusSm),
      child: Padding(
        padding: semPadding ? EdgeInsets.zero : padding,
        child: child,
      ),
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: COColors.brand700.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(COTokens.radiusSm),
        border: Border.all(
          color: destacado
              ? COColors.neutral500
              : COColors.neutral500.withValues(alpha: 0.45),
          width: COTokens.borderWidth,
        ),
        // Sem sombra: o sistema pede contenção.
      ),
      child: onTap == null
          ? conteudo
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(COTokens.radiusSm),
                child: conteudo,
              ),
            ),
    );
  }
}

/// Etiqueta de secção — "STATUS DAS OBRAS", "DOCUMENTOS".
///
/// Sempre em maiúsculas, como o brandbook manda, e com o espaço por baixo já
/// incluído, para não haver três SizedBox diferentes espalhados pelos ecrãs.
class CoOverline extends StatelessWidget {
  const CoOverline(this.texto, {super.key, this.espacoAbaixo = COTokens.space4});

  final String texto;
  final double espacoAbaixo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: espacoAbaixo),
      child: Text(texto.toUpperCase(), style: COText.overline),
    );
  }
}

/// Linha de "etiqueta → valor" com um ícone à frente, como aparece nos
/// cartões do portfólio (cidade, conclusão, frações).
class CoLinhaInfo extends StatelessWidget {
  const CoLinhaInfo({super.key, required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icone, color: COColors.brand300, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: COText.small,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
