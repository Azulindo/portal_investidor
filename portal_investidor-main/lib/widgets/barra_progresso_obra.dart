import 'package:flutter/material.dart';

import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/portfolio.dart';

/// Em que fase da obra está o empreendimento, numa barra segmentada: um traço
/// por fase, cheio nas que já passaram e marcado na que está a decorrer.
///
/// Equivalente ao ProgressoObra do site. As fases e o currentStep já vêm
/// dentro de /project/portfolio, por isso não custa um pedido extra.
class BarraProgressoObra extends StatelessWidget {
  const BarraProgressoObra({
    super.key,
    required this.projeto,
    this.ocultarConcluida = false,
  });

  /// O empreendimento tal como vem de /project/portfolio.
  final Map projeto;

  /// Nos cartões dos concluídos a barra toda cheia não acrescenta nada.
  final bool ocultarConcluida;

  @override
  Widget build(BuildContext context) {
    final p = Portfolio.progresso(projeto);
    // Sem timeline, ou sem a API dizer em que fase está, não se mostra nada —
    // em vez de se inventar uma fase.
    if (p == null) return const SizedBox.shrink();
    if (ocultarConcluida && p.concluida) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: COTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.descricao,
            style: COText.caption.copyWith(color: COColors.brand300),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          // Semantics com a mesma descrição: para um leitor de ecrã a barra é
          // só um monte de caixas, e a frase é o que interessa.
          Semantics(
            label: p.descricao,
            child: Row(
              children: [
                for (var i = 0; i < p.total; i++)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(right: i == p.total - 1 ? 0 : 3),
                      color: p.concluida || i < p.feitos
                          ? COColors.brand300
                          : i == p.feitos
                              // A fase a decorrer: a meio caminho entre feita
                              // e por fazer.
                              ? COColors.brand300.withValues(alpha: 0.55)
                              : COColors.brand700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
