import 'package:flutter/material.dart';

import '../models/sale_order.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/carteira.dart';
import 'co_card.dart';

/// As encomendas do cliente, cada uma a abrir as suas faturas.
///
/// Lista, não cartões: cada encomenda é uma linha separada da seguinte por um
/// risco fino. Antes eram três caixas com borda seguidas das caixas dos
/// totais e da obra, e o ecrã lia-se como uma grelha de molduras.
class SecaoEncomendas extends StatefulWidget {
  const SecaoEncomendas({super.key, required this.encomendas});

  final List<SaleOrder> encomendas;

  @override
  State<SecaoEncomendas> createState() => _SecaoEncomendasState();
}

class _SecaoEncomendasState extends State<SecaoEncomendas> {
  /// Encomendas abertas, pelo id.
  final Set<int> _abertas = {};

  @override
  Widget build(BuildContext context) {
    if (widget.encomendas.isEmpty) return const SizedBox.shrink();

    // Agrupadas pelo nome do empreendimento, mantendo a ordem de chegada.
    final porProjeto = <String, List<SaleOrder>>{};
    for (final o in widget.encomendas) {
      porProjeto.putIfAbsent(o.projectName, () => []).add(o);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoTitulo('As suas aquisições'),
        for (final grupo in porProjeto.entries) ...[
          if (grupo.key.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: COTokens.space2, bottom: 2),
              child: Text(grupo.key, style: COText.caption),
            ),
          for (final o in grupo.value) _linha(o),
        ],
      ],
    );
  }

  Widget _linha(SaleOrder o) {
    final aberta = _abertas.contains(o.id);
    final temFaturas = o.invoices.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: COColors.brand700, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            // Sem faturas não há nada para abrir, por isso nem fica clicável.
            onTap: !temFaturas
                ? null
                : () => setState(() {
                      aberta ? _abertas.remove(o.id) : _abertas.add(o.id);
                    }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: COTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.name,
                          style: COText.small.copyWith(color: COColors.white),
                        ),
                      ),
                      Text(
                        Carteira.euros(o.amountTotal),
                        style: COText.body.copyWith(
                          color: COColors.white,
                          fontWeight: COTokens.fwMedium,
                        ),
                      ),
                      if (temFaturas) ...[
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: aberta ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.expand_more,
                            size: 16,
                            color: COColors.neutral500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      Carteira.data(o.date),
                      if (o.fractions.isNotEmpty)
                        'frações ${o.fractions.join(', ')}',
                      if (!temFaturas)
                        'sem faturas'
                      else
                        '${Carteira.euros(o.pago)} pagos',
                    ].join('  ·  '),
                    style: COText.caption,
                  ),
                ],
              ),
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child:
                aberta ? _faturas(o) : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _faturas(SaleOrder o) {
    return Padding(
      // Encostadas à direita da linha da encomenda, para se perceber que
      // pertencem àquela e não à seguinte.
      padding: const EdgeInsets.only(
        left: COTokens.space4,
        bottom: COTokens.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final f in o.invoices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.name, style: COText.caption),
                        Text(
                          '${Carteira.data(f.date)}  ·  ${f.estado.toLowerCase()}',
                          style: COText.caption.copyWith(
                            color: f.paymentState == 'paid'
                                ? COColors.brand300
                                : COColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: COTokens.space2),
                  Text(
                    Carteira.euros(f.amountTotal),
                    style: COText.caption.copyWith(color: COColors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
