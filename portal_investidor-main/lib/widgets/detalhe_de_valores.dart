import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/sale_order.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/carteira.dart';

/// As contas de um empreendimento, abertas.
///
/// O cartão do painel mostra duas linhas — pago e por pagar — porque é o que
/// cabe. Mas "por pagar" junta duas coisas que para quem compra não são a
/// mesma: o que já foi faturado e está à espera de pagamento, e o que ainda
/// nem foi faturado. Esta folha separa-as, com a mesma barra de três fatias
/// que o site usa nas encomendas.
class DetalheDeValores extends StatelessWidget {
  const DetalheDeValores({
    super.key,
    required this.empreendimento,
    required this.encomendas,
  });

  final String empreendimento;
  final List<SaleOrder> encomendas;

  static Future<void> abrir(
    BuildContext context, {
    required String empreendimento,
    required List<SaleOrder> encomendas,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DetalheDeValores(
        empreendimento: empreendimento,
        encomendas: encomendas,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = Carteira.investimentoTotal(encomendas);
    final pago = Carteira.totalPago(encomendas);
    final porFaturar =
        encomendas.fold<double>(0, (soma, o) => soma + o.porFaturar);
    final faturadoPorPagar =
        encomendas.fold<double>(0, (soma, o) => soma + o.faturadoPorPagar);
    final percentagem = Carteira.percentagemPaga(encomendas);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(COTokens.space6),
        decoration: BoxDecoration(
          color: COColors.brand700,
          borderRadius: BorderRadius.circular(COTokens.radiusSm),
          border: Border.all(
            color: COColors.brand500,
            width: COTokens.borderWidth,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A pega, que é como se percebe que isto se arrasta para baixo.
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: COTokens.space6),
                decoration: BoxDecoration(
                  color: COColors.brand500,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              empreendimento,
              style: COText.h2.copyWith(fontWeight: COTokens.fwBold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              total > 0
                  ? '${Carteira.euros(total)} no total · $percentagem% liquidado'
                  : 'Sem valores registados',
              style: COText.caption,
            ),

            const SizedBox(height: COTokens.space6),
            _Barra(total: total, pago: pago, faturado: faturadoPorPagar),
            const SizedBox(height: COTokens.space6),

            _Linha(
              cor: COColors.accent,
              etiqueta: 'Pago',
              explicacao: 'Faturas já liquidadas.',
              valor: pago,
            ),
            if (faturadoPorPagar > 0)
              _Linha(
                cor: COColors.brand300,
                etiqueta: 'Faturado, por pagar',
                explicacao: 'A fatura já foi emitida e aguarda pagamento.',
                valor: faturadoPorPagar,
              ),
            if (porFaturar > 0)
              _Linha(
                cor: COColors.brand900,
                etiqueta: 'Ainda por faturar',
                explicacao: 'Faz parte do valor acordado, sem fatura emitida.',
                valor: porFaturar,
              ),

            if (encomendas.length > 1) ...[
              const SizedBox(height: COTokens.space2),
              Text(
                Carteira.contagem(encomendas.length, 'encomenda', 'encomendas'),
                style: COText.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A mesma barra de três fatias das encomendas, aqui com os totais do
/// empreendimento.
class _Barra extends StatelessWidget {
  const _Barra({
    required this.total,
    required this.pago,
    required this.faturado,
  });

  final double total;
  final double pago;
  final double faturado;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();

    final restante = math.max(0.0, total - pago - faturado);

    // Peso em milésimos, e não o valor em euros: um flex de 142 500 000 é um
    // número sem razão de ser dentro de uma barra de 6px. O mínimo de 1 evita
    // que uma fatia pequena arredonde para zero e desapareça.
    int peso(double v) => math.max(1, ((v / total) * 1000).round());

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        // A largura tem de ser dita: dentro de uma Column alinhada à esquerda
        // um Row só com Expanded não tem largura própria e a barra sumia.
        width: double.infinity,
        height: 6,
        child: Row(
          // Esticar, senão um ColoredBox sem filho fica com altura zero.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pago > 0)
              Expanded(
                flex: peso(pago),
                child: const ColoredBox(color: COColors.accent),
              ),
            if (faturado > 0)
              Expanded(
                flex: peso(faturado),
                child: const ColoredBox(color: COColors.brand300),
              ),
            if (restante > 0)
              Expanded(
                flex: peso(restante),
                child: const ColoredBox(color: COColors.brand900),
              ),
          ],
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.cor,
    required this.etiqueta,
    required this.explicacao,
    required this.valor,
  });

  final Color cor;
  final String etiqueta;
  final String explicacao;
  final double valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: COTokens.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4, right: COTokens.space4),
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(2),
              // O "por faturar" é navy sobre navy: sem contorno não se via.
              border: Border.all(color: COColors.brand500),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(
                    color: COColors.white,
                    fontSize: 14,
                    fontWeight: COTokens.fwBold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(explicacao, style: COText.caption),
              ],
            ),
          ),
          const SizedBox(width: COTokens.space4),
          Text(
            Carteira.euros(valor),
            style: const TextStyle(
              color: COColors.white,
              fontSize: 15,
              fontWeight: COTokens.fwBold,
            ),
          ),
        ],
      ),
    );
  }
}
