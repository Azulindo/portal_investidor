import 'package:flutter/material.dart';

import '../models/sale_order.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/carteira.dart';
import 'co_card.dart';

/// Os totais do investidor, como no cabeçalho do portal do site: o que tem em
/// carteira, o investimento total, o pago, o por pagar, e a barra de
/// progresso.
///
/// As contas estão em utils/carteira.dart, fora daqui, e testadas — é
/// dinheiro, e tem de dar o mesmo que o site.
///
/// No site isto é uma linha larga com uma divisória vertical ao meio. Num
/// telemóvel fica por blocos: a carteira, os três valores e a barra.
class SecaoCarteira extends StatelessWidget {
  const SecaoCarteira({
    super.key,
    required this.encomendas,
    required this.nomesDosProjetos,
  });

  final List<SaleOrder> encomendas;

  /// Os empreendimentos do cliente, pela ordem em que se mostram.
  final List<String> nomesDosProjetos;

  @override
  Widget build(BuildContext context) {
    // Sem encomendas não há nada para somar. Aparecem só os cartões de obra,
    // como antes — é o caso de quem ainda não comprou nada.
    if (encomendas.isEmpty) return const SizedBox.shrink();

    final linhas = Carteira.porEmpreendimento(nomesDosProjetos, encomendas);
    final total = Carteira.investimentoTotal(encomendas);
    final pago = Carteira.totalPago(encomendas);
    final porPagar = Carteira.totalPorPagar(encomendas);
    final pct = Carteira.percentagemPaga(encomendas);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoOverline('Os seus investimentos'),

        CoCard(
          destacado: true,
          margin: const EdgeInsets.only(bottom: COTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('INVESTIMENTO TOTAL', style: COText.overline),
              const SizedBox(height: 4),
              Text(
                Carteira.euros(total),
                style: COText.h1.copyWith(fontSize: 28),
              ),
              const SizedBox(height: COTokens.space4),
              Row(
                children: [
                  Expanded(child: _valor('Pago', pago)),
                  Container(
                    width: COTokens.borderWidth,
                    height: 34,
                    color: COColors.brand700,
                  ),
                  Expanded(child: _valor('Por pagar', porPagar)),
                ],
              ),
              const SizedBox(height: COTokens.space4),
              _barra(pct),
            ],
          ),
        ),

        if (linhas.isNotEmpty) _emCarteira(linhas),
      ],
    );
  }

  Widget _valor(String etiqueta, double valor) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta.toUpperCase(), style: COText.overline),
          const SizedBox(height: 2),
          Text(
            Carteira.euros(valor),
            style: COText.valor.copyWith(color: COColors.white),
          ),
        ],
      ),
    );
  }

  Widget _barra(int pct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('PROGRESSO', style: COText.overline)),
            Text(
              '$pct%',
              style: COText.small.copyWith(
                color: COColors.white,
                fontWeight: COTokens.fwBold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            backgroundColor: COColors.brand700,
            valueColor: const AlwaysStoppedAnimation(COColors.brand300),
          ),
        ),
      ],
    );
  }

  Widget _emCarteira(List<LinhaCarteira> linhas) {
    final fracoes = Carteira.totalFracoes(linhas);

    return CoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('EM CARTEIRA', style: COText.overline),
          const SizedBox(height: 4),
          Text(
            '${Carteira.contagem(linhas.length, 'empreendimento', 'empreendimentos')}'
            '  ·  ${Carteira.contagem(fracoes, 'fração', 'frações')}',
            style: COText.body.copyWith(fontWeight: COTokens.fwMedium),
          ),
          const SizedBox(height: COTokens.space2),
          for (final linha in linhas)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      linha.empreendimento,
                      style: COText.small,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: COTokens.space2),
                  Text(
                    Carteira.contagem(linha.fracoes, 'fração', 'frações'),
                    style: COText.caption.copyWith(color: COColors.brand300),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
