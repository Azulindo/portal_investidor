import 'package:flutter/material.dart';

import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';

/// A zona clara do painel e da página do empreendimento: sobe por cima do
/// navy como uma folha, com os cantos de cima redondos e uma sombra leve.
/// Antes era um corte a direito entre o azul e o branco.
class FolhaClara extends StatelessWidget {
  const FolhaClara({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: COColors.fundoClaro,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        COTokens.space4,
        COTokens.space6,
        COTokens.space4,
        40,
      ),
      child: child,
    );
  }
}

/// Um cartão branco da zona clara, como os do portal do site. Aparece com o
/// [Revelar] quando chega ao ecrã.
class BlocoClaro extends StatelessWidget {
  const BlocoClaro({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Revelar(
      child: Container(
        margin: const EdgeInsets.only(bottom: COTokens.space4),
        padding: const EdgeInsets.all(COTokens.space4),
        decoration: BoxDecoration(
          color: COColors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F002847),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// Faz o [child] subir e aparecer na primeira vez que entra no ecrã ao
/// descer a página. Depois fica quieto: não volta a animar ao subir e descer.
///
/// Vigia a posição do scroll em vez de construir os cartões só quando
/// aparecem, para todos existirem desde o início (a carteira do painel desce
/// até ao cartão de um empreendimento, e precisa de saber onde ele está).
class Revelar extends StatefulWidget {
  const Revelar({super.key, required this.child});

  final Widget child;

  @override
  State<Revelar> createState() => _RevelarState();
}

class _RevelarState extends State<Revelar> {
  ScrollPosition? _posicao;
  bool _visto = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_visto) return;
    final nova = Scrollable.maybeOf(context)?.position;
    if (nova != _posicao) {
      _posicao?.removeListener(_verificar);
      _posicao = nova?..addListener(_verificar);
    }
    // Sem scroll à volta (ou com animações desligadas) mostra-se logo.
    if (_posicao == null || MediaQuery.of(context).disableAnimations) {
      _visto = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificar());
  }

  void _verificar() {
    if (_visto || !mounted) return;
    final caixa = context.findRenderObject();
    if (caixa is! RenderBox || !caixa.attached) return;
    final topo = caixa.localToGlobal(Offset.zero).dy;
    if (topo < MediaQuery.of(context).size.height * 0.92) {
      _posicao?.removeListener(_verificar);
      setState(() => _visto = true);
    }
  }

  @override
  void dispose() {
    _posicao?.removeListener(_verificar);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visto ? Offset.zero : const Offset(0, 0.08),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visto ? 1 : 0,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// O topo navy a ficar para trás ao descer: sobe mais devagar do que o resto
/// (parallax) e vai desvanecendo, enquanto a folha clara passa por cima.
class Paralaxe extends StatefulWidget {
  const Paralaxe({super.key, required this.child, this.fator = 0.4});

  final Widget child;

  /// 0 sobe com o resto; 0.4 sobe a 60% da velocidade.
  final double fator;

  @override
  State<Paralaxe> createState() => _ParalaxeState();
}

class _ParalaxeState extends State<Paralaxe> {
  ScrollPosition? _posicao;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nova = Scrollable.maybeOf(context)?.position;
    if (nova != _posicao) {
      _posicao?.removeListener(_mudou);
      _posicao = nova?..addListener(_mudou);
    }
  }

  void _mudou() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _posicao?.removeListener(_mudou);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _posicao;
    final desvio =
        (p != null && p.hasPixels) ? p.pixels.clamp(0.0, 600.0) : 0.0;
    if (desvio == 0 || MediaQuery.of(context).disableAnimations) {
      return widget.child;
    }
    return Transform.translate(
      offset: Offset(0, desvio * widget.fator),
      child: Opacity(
        opacity: (1 - desvio / 420).clamp(0.0, 1.0),
        child: widget.child,
      ),
    );
  }
}
