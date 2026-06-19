import 'package:flutter/material.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../utils/ui_helpers.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final int projectId;
  final String heroTag;
  final String initialImageUrl;

  const ProjectDetailsScreen({
    super.key,
    required this.projectId,
    required this.heroTag,
    required this.initialImageUrl,
  });

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  int _paginaAtual = 0;
  late Future<ProjectDetailModel> _projectFuture;
  final PageController _galeriaController = PageController();
  double _dragAcumulado = 0;
  // --- TEMPORÁRIO: só para diagnóstico do swipe ---
  int _debugUpdates = 0;
  double _debugUltimoDelta = 0;
  bool _debugDragDetectado = false;
  int _debugTaps = 0;
  int _debugPointerDown = 0;

  @override
  void initState() {
    super.initState();
    _projectFuture = ApiService().buscarDetalhesProjeto(widget.projectId);
  }

  @override
  void dispose() {
    _galeriaController.dispose();
    super.dispose();
  }

  void _tentarNovamente() {
    setState(() {
      _projectFuture = ApiService().buscarDetalhesProjeto(widget.projectId);
    });
  }

  void _irParaImagem(int index, int total) {
    if (index < 0 || index >= total) return;
    _galeriaController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: COColors.brand900,
      body: FutureBuilder<ProjectDetailModel>(
        future: _projectFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            final mensagem = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Erro ao carregar os detalhes do projeto.';

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: COColors.brand900,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: UIHelpers.buildErrorState(
                    message: mensagem,
                    onRetry: _tentarNovamente,
                    showBackButton: true,
                    context: context,
                  ),
                ),
              ],
            );
          }

          final project = snapshot.data;
          if (project == null) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: COColors.brand900,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: UIHelpers.buildErrorState(
                    message: 'Projeto não encontrado.',
                    onRetry: _tentarNovamente,
                    showBackButton: true,
                    context: context,
                  ),
                ),
              ],
            );
          }

          final info = project.info;
          final steps = project.steps;
          // Número do "stepOrder" do passo atual (NÃO é o id de um step).
          // Antes chamava-se "safeCurrentStepId" e era comparado a "step.stepId".
          final safeCurrentStep = info.currentStep ?? 0;

          // Galeria: imagens do endpoint, ou fallback para a imagem inicial
          List<String> galeria = project.galeria;
          if (galeria.isEmpty) {
            if (info.mainImageUrl != null && info.mainImageUrl!.isNotEmpty) {
              galeria.add(info.mainImageUrl!);
            } else if (widget.initialImageUrl.isNotEmpty) {
              galeria.add(widget.initialImageUrl);
            }
          }

          final titulo = info.name;
          final descricao = info.description;
          final status = info.status;

          return Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 320,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (galeria.isNotEmpty)
                          Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (event) {
                              setState(() => _debugPointerDown++);
                            },
                            child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() => _debugTaps++);
                            },
                            onHorizontalDragStart: (details) {
                              setState(() => _debugDragDetectado = true);
                            },
                            onHorizontalDragUpdate: (details) {
                              _dragAcumulado += details.delta.dx;
                              setState(() {
                                _debugUpdates++;
                                _debugUltimoDelta = details.delta.dx;
                              });
                            },
                            onHorizontalDragEnd: (details) {
                              final velocidade = details.primaryVelocity ?? 0;
                              const limiarDistancia = 60.0;
                              const limiarVelocidade = 300.0;
                              if (_dragAcumulado < -limiarDistancia || velocidade < -limiarVelocidade) {
                                _irParaImagem(_paginaAtual + 1, galeria.length);
                              } else if (_dragAcumulado > limiarDistancia || velocidade > limiarVelocidade) {
                                _irParaImagem(_paginaAtual - 1, galeria.length);
                              }
                              _dragAcumulado = 0;
                              setState(() => _debugDragDetectado = false);
                            },
                            // NOTA: o PageView deixou de usar o seu próprio gesto de
                            // arrastar (physics: NeverScrollableScrollPhysics) porque
                            // algo fora deste ficheiro estava a "engolir" o gesto antes
                            // de chegar ao PageView. Este GestureDetector trata o swipe
                            // diretamente e chama o mesmo método (_irParaImagem) que já
                            // funciona nas setas, garantindo que o swipe funciona sempre.
                            child: PageView.builder(
                              controller: _galeriaController,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: galeria.length,
                              onPageChanged: (index) {
                                setState(() => _paginaAtual = index);
                              },
                              itemBuilder: (context, index) {
                                final isPrimeiraFoto = index == 0;
                                final imagemWidget = Image.network(
                                  galeria[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) => Container(
                                    color: COColors.brand700,
                                    child: const Center(
                                      child: Icon(Icons.broken_image, color: COColors.brand300, size: 50),
                                    ),
                                  ),
                                );

                                if (isPrimeiraFoto) {
                                  return Hero(
                                    tag: widget.heroTag,
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(COTokens.radiusSm)),
                                        child: imagemWidget,
                                      ),
                                    ),
                                  );
                                }
                                return imagemWidget;
                              },
                            ),
                          ),
                          )
                        else
                          Container(color: COColors.brand700),

                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.6),
                                Colors.transparent,
                                COColors.brand900,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),

                        // SETAS DE NAVEGAÇÃO DA GALERIA
                        if (galeria.length > 1) ...[
                          Positioned(
                            left: 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _GalleryArrowButton(
                                icon: Icons.chevron_left,
                                visible: _paginaAtual > 0,
                                onPressed: () => _irParaImagem(_paginaAtual - 1, galeria.length),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _GalleryArrowButton(
                                icon: Icons.chevron_right,
                                visible: _paginaAtual < galeria.length - 1,
                                onPressed: () => _irParaImagem(_paginaAtual + 1, galeria.length),
                              ),
                            ),
                          ),
                        ],

                        if (galeria.length > 1)
                          Positioned(
                            bottom: 24,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(galeria.length, (index) {
                                return GestureDetector(
                                  onTap: () => _irParaImagem(index, galeria.length),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    width: _paginaAtual == index ? 24 : 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      color: _paginaAtual == index ? Colors.white : COColors.brand500,
                                      borderRadius: BorderRadius.circular(4.5),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ===========================================
                  // CONTEÚDO DO PROJETO — scroll independente da galeria
                  // ===========================================
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(COTokens.space6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titulo, style: const TextStyle(color: COColors.white, fontSize: 24, fontWeight: COTokens.fwBold, height: 1.2)),

                          if (info.city.isNotEmpty || info.address.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              [info.address, info.city].where((s) => s.isNotEmpty).join(', '),
                              style: const TextStyle(color: COColors.neutral500, fontSize: 13),
                            ),
                          ],

                          if (info.nFractions != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.apartment, color: COColors.neutral500, size: 20),
                                const SizedBox(width: 5),
                                Text(
                                  '${info.nFractions} frações',
                                  style: const TextStyle(color: COColors.neutral500, fontSize: 15),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              UIHelpers.buildStatusBadge(status),
                              if (status != 'Desenvolvimento')
                                _ForSaleBadge(forSale: info.forSale),
                            ],
                          ),

                          const SizedBox(height: COTokens.space6),

                          const Text('SOBRE O PROJETO', style: TextStyle(color: COColors.neutral500, fontSize: 12, fontWeight: COTokens.fwBold, letterSpacing: 1.5)),
                          const SizedBox(height: COTokens.space4),
                          Text(descricao, style: const TextStyle(color: COColors.brand300, fontSize: 16, height: 1.6)),

                          const SizedBox(height: 32),

                          // ETAPAS DO PROJETO (projectSteps)
                          if (status == 'Desenvolvimento') ...[
                            const Text('ETAPAS DO DESENVOLVIMENTO', style: TextStyle(color: COColors.neutral500, fontSize: 12, fontWeight: COTokens.fwBold, letterSpacing: 1.5)),
                            const SizedBox(height: COTokens.space4),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Projeto em desenvolvimento.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: COColors.brand300, fontSize: 15),
                                ),
                                Text(
                                  'Timeline disponível em breve!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: COColors.brand300, fontSize: 15),
                                ),
                              ],
                            ),
                          ] else if (steps.isNotEmpty) ...[
                            const Text('ETAPAS DO DESENVOLVIMENTO', style: TextStyle(color: COColors.neutral500, fontSize: 12, fontWeight: COTokens.fwBold, letterSpacing: 1.5)),
                            const SizedBox(height: COTokens.space4),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: steps.length,
                              itemBuilder: (context, index) {
                                final step = steps[index];

                                // ALTERADO: antes comparava "step.stepId" com "safeCurrentStepId".
                                // Agora compara o número de ordem ("stepOrder") com "safeCurrentStep".
                                final isCurrent = step.stepOrder == safeCurrentStep;
                                final isDone = step.stepOrder <= safeCurrentStep;
                                final isLast = index == steps.length - 1;

                                // Cor da linha que liga este passo ao próximo:
                                // - antes do atual (já concluído): verde
                                // - a sair do passo atual (a avançar): verde
                                // - ainda não chegámos lá: cinzento neutro
                                final Color corLinha = isCurrent
                                    ? Colors.green
                                    : (isDone ? Colors.green : COColors.brand700);

                                // IntrinsicHeight garante que a linha entre as bolinhas
                                // acompanha a altura real da descrição (deixa de cortar
                                // quando o texto do passo é mais longo).
                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          clipBehavior: Clip.none,
                                          children: [
                                            if (!isLast && !isCurrent)
                                              Positioned(
                                                top: 16,
                                                left: 7,
                                                bottom: 0,
                                                child: Container(width: 2, color: corLinha),
                                              ),
                                            if (!isLast && isCurrent)
                                              Positioned(
                                                top: 16,
                                                bottom: 0,
                                                left: 0,
                                                right: 0,
                                                child: _PulsingForwardConnector(color: corLinha),
                                              ),
                                            Positioned(
                                              top: 0,
                                              left: 0,
                                              child: Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: isCurrent ? Colors.greenAccent : (isDone ? Colors.green : COColors.brand700),
                                                  shape: BoxShape.circle,
                                                  border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Detalhes da Etapa
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              step.name,
                                              style: TextStyle(
                                                color: isCurrent ? Colors.white : (isDone ? COColors.brand300 : COColors.neutral500),
                                                fontWeight: isCurrent ? COTokens.fwBold : FontWeight.normal,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              step.description,
                                              style: const TextStyle(color: COColors.neutral500, fontSize: 13),
                                            ),
                                            const SizedBox(height: 16),
                                          ],
                                        ),
                                      ),
                                      // FOTO DA ETAPA (se existir)
                                      if (step.imageUrl != null && step.imageUrl!.isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () {
                                            final indexNaGaleria = galeria.indexOf(step.imageUrl!);
                                            if (indexNaGaleria != -1) {
                                              _irParaImagem(indexNaGaleria, galeria.length);
                                            } else {
                                              showDialog(
                                                context: context,
                                                builder: (context) => Dialog(
                                                  backgroundColor: Colors.transparent,
                                                  insetPadding: const EdgeInsets.all(16),
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      InteractiveViewer(
                                                        panEnabled: true,
                                                        minScale: 0.5,
                                                        maxScale: 4,
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(COTokens.radiusSm),
                                                          child: Image.network(step.imageUrl!, fit: BoxFit.contain),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        top: 0,
                                                        right: 0,
                                                        child: IconButton(
                                                          icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
                                                          onPressed: () => Navigator.of(context).pop(),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(COTokens.radiusSm),
                                            child: Image.network(
                                              step.imageUrl!,
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stack) => Container(
                                                width: 56,
                                                height: 56,
                                                color: COColors.brand700,
                                                child: const Icon(Icons.broken_image, color: COColors.brand300, size: 20),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],

                          const SizedBox(height: 24),

                          // BOTÃO DE MANIFESTAR INTERESSE
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Interesse registado! Um gestor irá contactá-lo.'), backgroundColor: COColors.brand500),
                                );
                              },
                              icon: const Icon(Icons.mail_outline, color: COColors.brand900),
                              label: const Text('MANIFESTAR INTERESSE', style: TextStyle(color: COColors.brand900, fontWeight: COTokens.fwBold, letterSpacing: 1.5)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: COColors.brand300,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(COTokens.radiusSm)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // BOTÃO DE VOLTAR — sobreposto à galeria fixa, já que esta
              // deixou de estar dentro de um SliverAppBar com leading automático.
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        SizedBox(
          height: 320,
          width: double.infinity,
          child: Hero(
            tag: widget.heroTag,
            child: Material(
              type: MaterialType.transparency,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(COTokens.radiusSm)),
                child: widget.initialImageUrl.isNotEmpty
                    ? Image.network(widget.initialImageUrl, fit: BoxFit.cover)
                    : Container(color: COColors.brand700),
              ),
            ),
          ),
        ),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(color: COColors.brand300),
          ),
        ),
      ],
    );
  }
}

// =========================================================
// BOTÃO DE SETA PARA NAVEGAR NA GALERIA DE IMAGENS
// =========================================================
class _GalleryArrowButton extends StatelessWidget {
  final IconData icon;
  final bool visible;
  final VoidCallback onPressed;

  const _GalleryArrowButton({
    required this.icon,
    required this.visible,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !visible,
        child: Material(
          color: Colors.black.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// LIGAÇÃO "A AVANÇAR" — efeito de "loading" com um brilho que
// desliza de cima para baixo ao longo da linha, em loop.
// =========================================================
class _PulsingForwardConnector extends StatefulWidget {
  final Color color;

  const _PulsingForwardConnector({required this.color});

  @override
  State<_PulsingForwardConnector> createState() => _PulsingForwardConnectorState();
}

class _PulsingForwardConnectorState extends State<_PulsingForwardConnector> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Vai de -1 a 1: o brilho começa totalmente acima da linha
        // (invisível) e termina totalmente abaixo (invisível), por
        // isso o "salto" do loop nunca se nota.
        final slide = -1.0 + (2 * _controller.value);
        return Center(
          child: SizedBox(
            width: 2,
            height: double.infinity,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.color.withValues(alpha: 0.12),
                    widget.color,
                    widget.color.withValues(alpha: 0.12),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                  transform: _SlidingGradientTransform(slide),
                ).createShader(bounds);
              },
              child: ColoredBox(color: widget.color),
            ),
          ),
        );
      },
    );
  }
}

class _ForSaleBadge extends StatelessWidget {
  final bool forSale;
  const _ForSaleBadge({required this.forSale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: forSale ? const Color(0xFF1A237E) : const Color(0xFF4A4A4A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: forSale ? const Color(0xFF7986CB) : const Color(0xFF9E9E9E),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            forSale ? Icons.apartment : Icons.lock_outline,
            color: forSale ? const Color(0xFFB3BCEF) : const Color(0xFFBDBDBD),
            size: 20,
          ),
          const SizedBox(width: 5),
          Text(
            forSale ? 'FRAÇÕES DISPONÍVEIS PARA VENDA' : 'TODAS AS FRAÇÕES VENDIDAS',
            style: TextStyle(
              color: forSale ? const Color(0xFFB3BCEF) : const Color(0xFFBDBDBD),
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

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(0.0, bounds.height * slidePercent, 0.0);
  }
}

