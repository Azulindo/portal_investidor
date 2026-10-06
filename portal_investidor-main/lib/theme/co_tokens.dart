import 'package:flutter/material.dart';

import 'co_colors.dart';

/// Os valores do design system da Cleveroption, num sítio só.
///
/// Fonte: "Regras, etc/cleveroption-global.css" e o README do design-system.
/// Antes cada ecrã escolhia os seus tamanhos à mão (22, 18, 13, 11...), e era
/// por isso que nada alinhava com nada. Tudo o que for texto, espaço, canto ou
/// borda sai daqui.
class COTokens {
  // ── Cantos ────────────────────────────────────────────────
  /// Botões: cantos vivos, como manda a marca.
  static const double radiusNone = 0.0;
  /// Cartões e imagens: 5px.
  static const double radiusSm = 5.0;

  // ── Espaçamento ───────────────────────────────────────────
  static const double space2 = 8.0;
  static const double space4 = 16.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  /// Os dois ritmos maiores do sistema, para separar blocos e secções.
  static const double space9 = 36.0;
  static const double space12 = 54.0;

  /// Espaço dentro de um cartão.
  static const double cardPadding = 20.0;
  /// Altura do cabeçalho.
  static const double headerHeight = 72.0;
  /// Espessura das bordas. O sistema não usa bordas grossas.
  static const double borderWidth = 1.0;

  // ── Pesos ─────────────────────────────────────────────────
  static const FontWeight fwLight = FontWeight.w300;
  static const FontWeight fwRegular = FontWeight.w400;
  static const FontWeight fwMedium = FontWeight.w500;
  static const FontWeight fwBold = FontWeight.w700;
}

/// A escala de tipos do sistema: 24 / 20 / 16 / 14 / 12.
///
/// As cores por omissão são as de fundo escuro, que é o da app inteira. Para
/// as usar sobre fundo claro, é só `COText.h1.copyWith(color: ...)`.
class COText {
  const COText._();

  /// Títulos de ecrã.
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: COTokens.fwBold,
    height: 1.2,
    color: COColors.white,
  );

  /// Títulos de secção e nomes de empreendimento.
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: COTokens.fwRegular,
    height: 1.25,
    color: COColors.white,
  );

  /// Texto corrente.
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: COTokens.fwRegular,
    height: 1.5,
    color: COColors.white,
  );

  /// Texto secundário: cidades, datas, apoios.
  static const TextStyle small = TextStyle(
    fontSize: 14,
    fontWeight: COTokens.fwLight,
    height: 1.45,
    color: COColors.brand300,
  );

  /// Legendas e notas de rodapé.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: COTokens.fwLight,
    height: 1.4,
    color: COColors.neutral500,
  );

  /// Etiquetas de secção, sempre em maiúsculas ("STATUS DAS OBRAS").
  static const TextStyle overline = TextStyle(
    fontSize: 12,
    fontWeight: COTokens.fwMedium,
    letterSpacing: 1.2,
    height: 1.2,
    color: COColors.brand300,
  );

  /// Números que são o ponto do bloco (totais, contagens).
  static const TextStyle valor = TextStyle(
    fontSize: 20,
    fontWeight: COTokens.fwBold,
    height: 1.2,
    color: COColors.brand300,
  );
}
