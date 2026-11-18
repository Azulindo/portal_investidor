import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';

// =========================================================
// ESQUELETO DE CARREGAMENTO
// =========================================================

/// A forma do painel enquanto os dados nao chegam.
///
/// Segue o que o ecra vai mesmo mostrar: saudacao, o numero grande, e dois
/// cartoes de empreendimento. Se o painel mudar de forma, isto tem de
/// mudar com ele — um esqueleto que nao bate certo com o que aparece a
/// seguir e pior do que nenhum, porque o conteudo salta.
class EsqueletoPainel extends StatelessWidget {
  const EsqueletoPainel({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: COColors.brand700,
      highlightColor: COColors.brand500,
      child: ListView(
        padding: const EdgeInsets.all(COTokens.space6),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          SizedBox(height: COTokens.space4),
          OssoEsqueleto(largura: 170, altura: 22),
          SizedBox(height: COTokens.space6),
          OssoEsqueleto(largura: 210, altura: 28),
          SizedBox(height: 10),
          OssoEsqueleto(largura: 150, altura: 12),
          SizedBox(height: 14),
          OssoEsqueleto(largura: double.infinity, altura: 2),
          SizedBox(height: COTokens.space8),
          OssoEsqueleto(largura: 180, altura: 18),
          SizedBox(height: COTokens.space4),
          _CartaoEsqueleto(),
          SizedBox(height: COTokens.space4),
          _CartaoEsqueleto(),
        ],
      ),
    );
  }
}

class _CartaoEsqueleto extends StatelessWidget {
  const _CartaoEsqueleto();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: COColors.brand700),
        borderRadius: BorderRadius.circular(COTokens.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OssoEsqueleto(largura: double.infinity, altura: 190, raio: 0),
          Padding(
            padding: const EdgeInsets.all(COTokens.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                OssoEsqueleto(largura: 140, altura: 18),
                SizedBox(height: 9),
                OssoEsqueleto(largura: 200, altura: 12),
                SizedBox(height: 18),
                OssoEsqueleto(largura: double.infinity, altura: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Um retangulo cinzento. O Shimmer por cima e que lhe da o brilho.
class OssoEsqueleto extends StatelessWidget {
  const OssoEsqueleto({
    super.key,
    required this.largura,
    required this.altura,
    this.raio = 4,
  });

  final double largura;
  final double altura;
  final double raio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: largura,
      height: altura,
      decoration: BoxDecoration(
        color: COColors.brand700,
        borderRadius: BorderRadius.circular(raio),
      ),
    );
  }
}
