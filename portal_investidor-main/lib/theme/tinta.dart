import 'package:flutter/widgets.dart';

import 'co_colors.dart';

/// Marca uma zona do ecrã como clara (fundo branco), como o corpo do painel
/// e da página do empreendimento — o portal do site é assim.
///
/// A app nasceu toda sobre o navy, e as secções escrevem as cores do navy
/// (texto branco, legendas brand300, linhas brand700). Em vez de cada uma ter
/// duas versões, pedem a cor ao contexto com [TintaContexto.cor]: fora de uma
/// Superficie clara recebem a mesma cor; dentro, a sua equivalente clara.
class Superficie extends InheritedWidget {
  const Superficie({super.key, this.clara = true, required super.child});

  final bool clara;

  static bool eClara(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Superficie>()?.clara ?? false;

  @override
  bool updateShouldNotify(Superficie antiga) => antiga.clara != clara;
}

/// A troca das cores do navy pelas do fundo claro.
///
/// É uma troca de papéis, não de tons: o texto principal (branco) passa a
/// navy, o fundo (navy) passa a branco, o secundário (brand300) passa ao
/// brand500, que é o secundário legível sobre branco, e as linhas e
/// superfícies escuras passam às claras do site. O accent fica igual.
class Tinta {
  Tinta._();

  static Color clara(Color c) {
    if (c == COColors.white) return COColors.brand900;
    if (c == COColors.brand900) return COColors.white;
    if (c == COColors.brand700) return COColors.neutral100;
    if (c == COColors.brand500) return COColors.bordaClara;
    if (c == COColors.brand300) return COColors.brand500;
    if (c == COColors.neutral500) return COColors.brand500;
    return c;
  }
}

extension TintaContexto on BuildContext {
  /// A cor [c] (pensada para o navy) na superfície onde este contexto está.
  Color cor(Color c) => Superficie.eClara(this) ? Tinta.clara(c) : c;

  /// O mesmo para um estilo de texto: troca-lhe a cor.
  TextStyle estilo(TextStyle s) => Superficie.eClara(this) && s.color != null
      ? s.copyWith(color: Tinta.clara(s.color!))
      : s;
}
