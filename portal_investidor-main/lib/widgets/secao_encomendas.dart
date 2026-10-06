import 'package:flutter/material.dart';

import '../models/sale_order.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/carteira.dart';
import 'co_card.dart';

/// As encomendas do cliente, cada uma a abrir as suas faturas.
///
/// No site estas vivem dentro do cartão de cada empreendimento. Aqui ficam
/// numa secção própria, agrupadas por empreendimento: num telemóvel os
/// cartões de obra já são altos, e enfiar-lhes as encomendas dentro obrigava
/// a rolar muito antes de se chegar à obra seguinte.
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
        const CoOverline('As suas aquisições'),
        for (final grupo in porProjeto.entries) ...[
          if (grupo.key.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: COTokens.space2),
              child: Text(
                grupo.key,
                style: COText.body.copyWith(fontWeight: COTokens.fwBold),
              ),
            ),
          for (final o in grupo.value) _cartao(o),
          const SizedBox(height: COTokens.space2),
        ],
      ],
    );
  }

  Widget _cartao(SaleOrder o) {
    final aberta = _abertas.contains(o.id);

    return CoCard(
      semPadding: true,
      margin: const EdgeInsets.only(bottom: COTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            // Sem faturas não há nada para abrir, por isso nem fica clicável.
            onTap: o.invoices.isEmpty
                ? null
                : () => setState(() {
                      aberta ? _abertas.remove(o.id) : _abertas.add(o.id);
                    }),
            child: Padding(
              padding: const EdgeInsets.all(COTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.name,
                          style: COText.small.copyWith(
                            color: COColors.white,
                            fontWeight: COTokens.fwMedium,
                          ),
                        ),
                      ),
                      Text(
                        Carteira.euros(o.amountTotal),
                        style: COText.valor.copyWith(
                          color: COColors.white,
                          fontSize: 17,
                        ),
                      ),
                      if (o.invoices.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: aberta ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.expand_more,
                            size: 18,
                            color: COColors.brand300,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      Carteira.data(o.date),
                      if (o.fractions.isNotEmpty)
                        'Frações ${o.fractions.join(', ')}',
                      if (o.invoices.isEmpty)
                        'Sem faturas'
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
            child: aberta
                ? _faturas(o)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _faturas(SaleOrder o) {
    return Padding
      (padding: const EdgeInsets.fromLTRB(
        COTokens.space4,
        0,
        COTokens.space4,
        COTokens.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: COColors.brand700, height: COTokens.space4),
          for (final f in o.invoices)
            Padding(
              padding: const EdgeInsets.only(bottom: COTokens.space2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.name, style: COText.small),
                        Text(Carteira.data(f.date), style: COText.caption),
                      ],
                    ),
                  ),
                  const SizedBox(width: COTokens.space2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Carteira.euros(f.amountTotal),
                        style: COText.small.copyWith(color: COColors.white),
                      ),
                      const SizedBox(height: 2),
                      _selo(f),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Etiqueta do estado da fatura. Fica sóbria de propósito: o estado lê-se
  /// na palavra, e um painel de dinheiro cheio de cores alarma sem razão.
  Widget _selo(Invoice f) {
    final pago = f.paymentState == 'paid';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: COColors.white.withValues(alpha: pago ? 0.16 : 0.06),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: COColors.brand300.withValues(alpha: pago ? 0.7 : 0.35),
        ),
      ),
      child: Text(
        f.estado.toUpperCase(),
        style: COText.caption.copyWith(
          color: pago ? COColors.white : COColors.brand300,
          fontSize: 10,
          fontWeight: COTokens.fwBold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
