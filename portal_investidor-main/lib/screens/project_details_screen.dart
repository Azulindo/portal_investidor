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
          final safeCurrentStepId = info.currentStepId ?? 0;

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

          return CustomScrollView(
            slivers: [
              // CABEÇALHO COM A GALERIA DE IMAGENS
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: COColors.brand900,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (galeria.isNotEmpty)
                        PageView.builder(
                          controller: _galeriaController,
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
                                  width: _paginaAtual == index ? 16 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _paginaAtual == index ? Colors.white : COColors.brand500,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // CONTEÚDO DO PROJETO
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(COTokens.space6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(titulo, style: const TextStyle(color: COColors.white, fontSize: 24, fontWeight: COTokens.fwBold, height: 1.2)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: status == 'Concluído' ? Colors.green.withValues(alpha: 0.2) : COColors.brand300.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: status == 'Concluído' ? Colors.green.withValues(alpha: 0.5) : COColors.brand300.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: status == 'Concluído' ? Colors.greenAccent : COColors.brand300,
                                fontWeight: COTokens.fwBold,
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (info.city.isNotEmpty || info.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [info.address, info.city].where((s) => s.isNotEmpty).join(', '),
                          style: const TextStyle(color: COColors.neutral500, fontSize: 13),
                        ),
                      ],

                      const SizedBox(height: COTokens.space6),

                      const Text('SOBRE O PROJETO', style: TextStyle(color: COColors.neutral500, fontSize: 12, fontWeight: COTokens.fwBold, letterSpacing: 1.5)),
                      const SizedBox(height: COTokens.space4),
                      Text(descricao, style: const TextStyle(color: COColors.brand300, fontSize: 16, height: 1.6)),

                      const SizedBox(height: 32),

                      // ETAPAS DO PROJETO (projectSteps)
                      if (steps.isNotEmpty) ...[
                        const Text('ETAPAS DO DESENVOLVIMENTO', style: TextStyle(color: COColors.neutral500, fontSize: 12, fontWeight: COTokens.fwBold, letterSpacing: 1.5)),
                        const SizedBox(height: COTokens.space4),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: steps.length,
                          itemBuilder: (context, index) {
                            final step = steps[index];

                            final isCurrent = step.stepId == safeCurrentStepId;
                            final isDone = step.stepId <= safeCurrentStepId;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Linha do tempo visual (Bolinha + Traço)
                                Column(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: isCurrent ? Colors.greenAccent : (isDone ? Colors.green : COColors.brand700),
                                        shape: BoxShape.circle,
                                        border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                                      ),
                                    ),
                                    if (index != steps.length - 1)
                                      Container(
                                        width: 2,
                                        height: 50,
                                        color: isDone ? Colors.green : COColors.brand700,
                                      ),
                                  ],
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