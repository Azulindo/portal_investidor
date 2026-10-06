import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import 'co_card.dart';
import 'visualizador_imagens.dart';

/// Galeria da obra — o equivalente à "Galeria da Obra" do site.
///
/// No site é uma grelha de imagens grandes. Aqui é uma fila que se arrasta na
/// horizontal, e cada imagem abre em ecrã inteiro: num telemóvel uma grelha
/// de fotos grandes obriga a rolar meio ecrã por imagem, e esta galeria é
/// acompanhamento de obra — vê-se de seguida, não uma a uma.
///
/// São as imagens de categoria "obra" de GET /project/details. Não se
/// confundem com as fotos dos passos da timeline, que continuam na timeline:
/// a timeline conta o progresso, esta galeria mostra a obra.
class SecaoGaleriaObra extends StatelessWidget {
  const SecaoGaleriaObra({super.key, required this.imagens});

  final List<ProjectImage> imagens;

  @override
  Widget build(BuildContext context) {
    if (imagens.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoOverline('Galeria da obra'),
        Text(
          imagens.length == 1
              ? '1 fotografia do acompanhamento'
              : '${imagens.length} fotografias do acompanhamento',
          style: COText.caption,
        ),
        const SizedBox(height: COTokens.space4),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imagens.length,
            separatorBuilder: (_, _) => const SizedBox(width: COTokens.space2),
            itemBuilder: (context, i) => _miniatura(context, i),
          ),
        ),
      ],
    );
  }

  Widget _miniatura(BuildContext context, int indice) {
    final img = imagens[indice];

    return GestureDetector(
      onTap: () => VisualizadorImagens.abrir(
        context,
        imagens: imagens.map((i) => i.imageUrl).toList(),
        legendas: imagens.map((i) => i.imageDescription).toList(),
        inicial: indice,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(COTokens.radiusSm),
        child: Image.network(
          img.imageUrl,
          width: 210,
          height: 150,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progresso) =>
              progresso == null ? child : _vazio(const SizedBox.shrink()),
          errorBuilder: (_, _, _) => _vazio(
            const Icon(
              Icons.broken_image_outlined,
              color: COColors.brand300,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// Caixa do tamanho da miniatura, para a fila não saltar enquanto carrega
  /// nem encolher quando uma imagem falha.
  Widget _vazio(Widget dentro) {
    return Container(
      width: 210,
      height: 150,
      color: COColors.brand700,
      alignment: Alignment.center,
      child: dentro,
    );
  }
}
