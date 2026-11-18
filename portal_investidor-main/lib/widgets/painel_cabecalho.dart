import 'package:flutter/material.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../models/sale_order.dart';
import '../utils/carteira.dart';
import 'painel_esqueleto.dart';


// =========================================================
// CABECALHO DO PAINEL
// =========================================================

/// O numero grande do painel.
///
/// Era o investimento total. Mas num modelo em que a Cleveroption constroi
/// e vende, o total e um numero estatico que o investidor ja sabe de cor —
/// nao e por causa dele que abre a app. O que o traz ca e o que ainda deve.
/// O total passa para a linha de baixo, onde continua a dar contexto.
class CabecalhoPainel extends StatelessWidget {
  const CabecalhoPainel({
    super.key,
    required this.nome,
    required this.encomendas,
    required this.aCarregar,
  });

  final String nome;
  final List<SaleOrder> encomendas;
  final bool aCarregar;

  /// So o primeiro nome. "Ola, Guilherme Goncalves" ocupava duas linhas em
  /// muitos telemoveis e nao dizia mais do que "Ola, Guilherme".
  String get _primeiroNome => nome.trim().split(RegExp(r'\s+')).first;

  @override
  Widget build(BuildContext context) {
    final saudacao = Text(
      _primeiroNome.isEmpty ? 'Olá' : 'Olá, $_primeiroNome',
      style: COText.h1.copyWith(fontSize: 22),
    );

    // Sem encomendas nao ha numeros para mostrar: fica so a saudacao, em
    // vez de um "0 €" que parecia um erro.
    if (encomendas.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          saudacao,
          if (aCarregar) ...[
            const SizedBox(height: COTokens.space4),
            const OssoEsqueleto(largura: 180, altura: 28),
          ],
        ],
      );
    }

    final porPagar = Carteira.totalPorPagar(encomendas);
    final total = Carteira.investimentoTotal(encomendas);
    final pct = Carteira.percentagemPaga(encomendas);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        saudacao,
        const SizedBox(height: COTokens.space4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              Carteira.euros(porPagar),
              style: COText.h1.copyWith(fontSize: 28, height: 1.1),
            ),
            const SizedBox(width: 10),
            const Text('por pagar', style: COText.small),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'de ${Carteira.euros(total)} no total  ·  $pct% liquidado',
          style: COText.caption,
        ),
        const SizedBox(height: 10),
        // A barra repete o que a linha de cima diz por extenso, mas le-se
        // sem ler.
        Semantics(
          label: '$pct por cento liquidado',
          child: SizedBox(
            height: 2,
            child: Row(
              children: [
                Expanded(
                  flex: pct.clamp(0, 100),
                  child: Container(color: COColors.accent),
                ),
                Expanded(
                  flex: (100 - pct).clamp(0, 100),
                  child: Container(color: COColors.brand700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
