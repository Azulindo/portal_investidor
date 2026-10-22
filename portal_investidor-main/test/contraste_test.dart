import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/theme/co_colors.dart';

/// O contraste das cores de texto da app, pela formula da WCAG.
///
/// Isto existe porque o `neutral500` ja esteve em 4.33:1 dentro de um cartao,
/// abaixo do minimo, e ninguem reparou: e a cor das legendas, que sao o texto
/// mais pequeno que a app mostra. Se alguem voltar a escurecer uma destas
/// cores, ou escurecer o fundo dos cartoes, o teste cai aqui em vez de cair
/// no telemovel de um investidor.
///
/// Minimos da WCAG AA: 4.5:1 para texto normal, 3:1 para texto grande.
void main() {
  group('Contraste do texto', () {
    test('as legendas leem-se sobre o navy e dentro de um cartao', () {
      expect(contraste(COColors.neutral500, COColors.brand900),
          greaterThanOrEqualTo(4.5));
      expect(contraste(COColors.neutral500, _fundoDoCartao()),
          greaterThanOrEqualTo(4.5));
    });

    test('o texto secundario le-se sobre o navy e dentro de um cartao', () {
      expect(contraste(COColors.brand300, COColors.brand900),
          greaterThanOrEqualTo(4.5));
      expect(contraste(COColors.brand300, _fundoDoCartao()),
          greaterThanOrEqualTo(4.5));
    });

    test('o texto principal e o teal leem-se sobre o navy', () {
      expect(contraste(COColors.white, COColors.brand900),
          greaterThanOrEqualTo(4.5));
      expect(contraste(COColors.accent, COColors.brand900),
          greaterThanOrEqualTo(4.5));
    });

    test('o brand500 continua a nao servir para texto sobre o navy', () {
      // Nao e um erro: o brand500 e cor de bordas e de fundos, nao de letras.
      // O teste guarda essa decisao, para nao voltar a ser usado em texto.
      expect(contraste(COColors.brand500, COColors.brand900), lessThan(4.5));
    });
  });
}

/// O fundo real de um [CoCard]: brand700 a 28% por cima do navy.
///
/// Calculado e nao escrito a mao, para o teste acompanhar se alguem mexer na
/// transparencia do cartao.
Color _fundoDoCartao() => _sobrepor(
      COColors.brand700.withValues(alpha: 0.28),
      COColors.brand900,
    );

Color _sobrepor(Color frente, Color fundo) {
  double misturar(double f, double t) => t + (f - t) * frente.a;
  return Color.from(
    alpha: 1,
    red: misturar(frente.r, fundo.r),
    green: misturar(frente.g, fundo.g),
    blue: misturar(frente.b, fundo.b),
  );
}

/// Razao de contraste da WCAG entre duas cores opacas.
double contraste(Color a, Color b) {
  final la = _luminancia(a);
  final lb = _luminancia(b);
  final clara = math.max(la, lb);
  final escura = math.min(la, lb);
  return (clara + 0.05) / (escura + 0.05);
}

double _luminancia(Color c) =>
    0.2126 * _canal(c.r) + 0.7152 * _canal(c.g) + 0.0722 * _canal(c.b);

double _canal(double v) =>
    v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
