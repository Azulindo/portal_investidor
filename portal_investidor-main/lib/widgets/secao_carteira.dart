import 'package:flutter/material.dart';

import '../models/sale_order.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/carteira.dart';

/// Os totais do investidor: o que investiu, o que já pagou, o que falta, e
/// o que tem em carteira.
///
/// Sem cartões. O painel tinha seis caixas seguidas, todas com borda de 1px,
/// e a borda deixa de separar quando está em todo o lado. Aqui as secções
/// separam-se por espaço e por um risco fino, e a caixa fica reservada ao que
/// se toca. As contas continuam em utils/carteira.dart, testadas.
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
    // Sem encomendas não há nada para somar — é o caso de quem ainda não
    // comprou nada. Mostram-se só os cartões de obra, como antes.
    if (encomendas.isEmpty) return const SizedBox.shrink();

    final linhas = Carteira.porEmpreendimento(nomesDosProjetos, encomendas);
    final total = Carteira.investimentoTotal(encomendas);
    final pago = Carteira.totalPago(encomendas);
    final porPagar = Carteira.totalPorPagar(encomendas);
    final pct = Carteira.percentagemPaga(encomendas);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // O número é a coisa mais importante do ecrã, por isso é o que é
        // grande. A etiqueta fica pequena e em caixa normal: em maiúsculas
        // competia com ele.
        Text('Investimento total', style: COText.small),
        const SizedBox(height: 2),
        Text(
          Carteira.euros(total),
          style: COText.h1.copyWith(fontSize: 34, height: 1.1),
        ),

        const SizedBox(height: COTokens.space6),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _valor('Pago', pago)),
            Expanded(child: _valor('Por pagar', porPagar)),
          ],
        ),

        const SizedBox(height: COTokens.space4),
        _barra(pct),

        const SizedBox(height: COTokens.space9),
        _emCarteira(linhas),
      ],
    );
  }

  Widget _valor(String etiqueta, double valor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: COText.caption),
        const SizedBox(height: 2),
        Text(
          Carteira.euros(valor),
          style: COText.body.copyWith(
            color: COColors.white,
            fontWeight: COTokens.fwMedium,
          ),
        ),
      ],
    );
  }

  /// Barra fina, sem a palavra "Progresso": a percentagem ao lado já diz o
  /// que é.
  Widget _barra(int pct) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: COColors.brand700,
              valueColor: const AlwaysStoppedAnimation(COColors.brand300),
            ),
          ),
        ),
        const SizedBox(width: COTokens.space4),
        Text(
          '$pct% pago',
          style: COText.caption.copyWith(color: COColors.brand300),
        ),
      ],
    );
  }

  Widget _emCarteira(List<LinhaCarteira> linhas) {
    if (linhas.isEmpty) return const SizedBox.shrink();
    final fracoes = Carteira.totalFracoes(linhas);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Em carteira: '
          '${Carteira.contagem(linhas.length, 'empreendimento', 'empreendimentos')}'
          ', ${Carteira.contagem(fracoes, 'fração', 'frações')}',
          style: COText.small,
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
                    style: COText.small.copyWith(color: COColors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: COTokens.space2),
                Text(
                  Carteira.contagem(linha.fracoes, 'fração', 'frações'),
                  style: COText.caption,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
