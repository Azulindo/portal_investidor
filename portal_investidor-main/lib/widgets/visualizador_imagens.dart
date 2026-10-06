import 'package:flutter/material.dart';

import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';

/// Imagens em ecrã inteiro: arrasta-se para o lado para passar à seguinte e
/// faz-se zoom com dois dedos.
///
/// Substitui o Dialog que o detalhe do empreendimento tinha para a foto de um
/// passo: esse já fazia zoom, mas não passava à imagem seguinte nem mostrava
/// legenda, e numa galeria de obra passar à seguinte é o gesto principal.
class VisualizadorImagens extends StatefulWidget {
  const VisualizadorImagens({
    super.key,
    required this.imagens,
    this.legendas = const [],
    this.inicial = 0,
  });

  final List<String> imagens;

  /// Opcionais e à mesma ordem das imagens; cada uma pode ser null.
  final List<String?> legendas;
  final int inicial;

  static Future<void> abrir(
    BuildContext context, {
    required List<String> imagens,
    List<String?> legendas = const [],
    int inicial = 0,
  }) {
    if (imagens.isEmpty) return Future.value();
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VisualizadorImagens(
          imagens: imagens,
          legendas: legendas,
          inicial: inicial,
        ),
      ),
    );
  }

  @override
  State<VisualizadorImagens> createState() => _VisualizadorImagensState();
}

class _VisualizadorImagensState extends State<VisualizadorImagens> {
  late final PageController _controller;
  late int _atual;

  @override
  void initState() {
    super.initState();
    _atual = widget.inicial.clamp(0, widget.imagens.length - 1);
    _controller = PageController(initialPage: _atual);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? get _legenda =>
      _atual < widget.legendas.length ? widget.legendas[_atual] : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.imagens.length,
              onPageChanged: (i) => setState(() => _atual = i),
              itemBuilder: (context, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.imagens[i],
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: COColors.neutral500,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              top: COTokens.space2,
              right: COTokens.space2,
              child: IconButton(
                icon: const Icon(Icons.close, color: COColors.white, size: 26),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Fechar',
              ),
            ),

            // Contador e legenda em baixo. Sobre uma foto clara o texto
            // branco sozinho desaparecia, daí a faixa escura.
            if (widget.imagens.length > 1 || (_legenda?.isNotEmpty ?? false))
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(COTokens.space4),
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.imagens.length > 1)
                        Text(
                          '${_atual + 1} / ${widget.imagens.length}',
                          style: COText.caption.copyWith(
                            color: COColors.brand300,
                          ),
                        ),
                      if (_legenda?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 4),
                        Text(
                          _legenda!,
                          style: COText.small.copyWith(color: COColors.white),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
