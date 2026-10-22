import 'package:flutter/material.dart';

class COColors {
  static const Color brand900 = Color(0xFF002847); // Navy Principal
  static const Color brand700 = Color(0xFF1F4662);
  static const Color brand500 = Color(0xFF4D647A);
  static const Color brand300 = Color(0xFFA6B4C1);
  static const Color brand100 = Color(0xFFE9EEF2);

  /// O teal da marca. Estava escrito a mao em dois sitios — na etiqueta de
  /// estado e no chip de fracoes a venda — com o mesmo valor copiado.
  /// Usa-se com conta: so no que a pessoa tem de fazer alguma coisa.
  static const Color accent = Color(0xFF5BBFBF);

  static const Color white = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFF5F8FB);
  static const Color neutral100 = Color(0xFFE8EDF1);
  static const Color neutral300 = Color(0xFFCCD5DD);
  /// A cor das legendas, que sao o texto mais pequeno da app (11-12px).
  /// Era 0xFF7F94A7, que dava 4.33:1 dentro de um CoCard — abaixo do minimo
  /// de 4.5:1. Subiu o suficiente para passar nos dois fundos onde aparece:
  /// 4.65:1 no cartao e 5.16:1 sobre o navy.
  static const Color neutral500 = Color(0xFF849AAC);
  static const Color neutral900 = Color(0xFF0F1B26);
}
