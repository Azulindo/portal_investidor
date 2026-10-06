import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/video.dart';
import 'co_card.dart';

/// Vídeo do empreendimento.
///
/// No site é uma iframe do YouTube debaixo da timeline. Aqui mostra-se a
/// miniatura e abre-se no YouTube: num telemóvel a app do YouTube dá um
/// leitor melhor do que um vídeo embebido numa webview, e evita juntar uma
/// dependência de webview à app só por causa disto.
///
/// Sem vídeo, ou com um URL que não se reconheça, a secção não aparece — o
/// site faz o mesmo.
class SecaoVideo extends StatelessWidget {
  const SecaoVideo({super.key, required this.videoUrl});

  final String? videoUrl;

  @override
  Widget build(BuildContext context) {
    final id = Video.idDoYoutube(videoUrl);
    if (id == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoOverline('Vídeo'),
        CoCard(
          semPadding: true,
          margin: EdgeInsets.zero,
          onTap: () => _abrir(context, id),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  Video.miniatura(id),
                  fit: BoxFit.cover,
                  // Sem miniatura (vídeo privado ou apagado) fica o fundo e o
                  // botão, que continuam a dizer que há um vídeo para ver.
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: COColors.brand700),
                ),
                const ColoredBox(color: Color(0x33000000)),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(COTokens.space4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: COColors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: COColors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: COTokens.space2),
        Text('Abre no YouTube.', style: COText.caption),
      ],
    );
  }

  Future<void> _abrir(BuildContext context, String id) async {
    bool ok;
    try {
      ok = await launchUrl(
        Uri.parse(Video.paraAbrir(id)),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o vídeo.'),
          backgroundColor: COColors.brand700,
        ),
      );
    }
  }
}
