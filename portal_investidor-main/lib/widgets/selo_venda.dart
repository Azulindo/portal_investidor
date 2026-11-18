import 'package:flutter/material.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';

/// Se ainda há frações para vender (no topo do detalhe do empreendimento).
///
/// Estava escrito com seis cores à mão — um azul-arroxeado do Material e três
/// cinzentos — que não são da marca nenhuma e ficavam a destoar sobre o navy.
/// Passou a usar o teal, que é a cor do que a pessoa pode fazer alguma coisa,
/// e o cinzento da casa quando já não há nada a fazer.
class SeloVenda extends StatelessWidget {
  final bool forSale;
  const SeloVenda({super.key, required this.forSale});

  @override
  Widget build(BuildContext context) {
    final cor = forSale ? COColors.accent : COColors.brand300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            forSale ? Icons.apartment : Icons.lock_outline,
            color: cor,
            size: 20,
          ),
          const SizedBox(width: 5),
          Text(
            forSale
                ? 'FRAÇÕES DISPONÍVEIS PARA VENDA'
                : 'TODAS AS FRAÇÕES VENDIDAS',
            style: const TextStyle(
              // A 10px com espaçamento, o branco é o que se lê de relance.
              color: COColors.white,
              fontWeight: COTokens.fwBold,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
