import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../widgets/co_drawer.dart';
import '../services/api_service.dart';
import '../utils/ui_helpers.dart';
import 'project_details_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  String _filtroAtivo = 'Todos';
  final List<String> _categorias = ['Todos', 'Em Angariação', 'Em Curso', 'Concluído'];

  late Future<List<dynamic>> _portfolioFuture;

  @override
  void initState() {
    super.initState();
    _portfolioFuture = ApiService().buscarPortfolio();
  }

  Future<void> _refreshPortfolio() async {
    setState(() {
      _portfolioFuture = ApiService().buscarPortfolio();
    });
    await _portfolioFuture.catchError((_) => <dynamic>[]);
  }

  String _obterStatus(Map<String, dynamic> project) {
    final steps = project['steps'] as List? ?? [];
    if (steps.isEmpty) return 'Em breve';
    final currentStepId = int.tryParse(project['currentStepId']?.toString() ?? '');
    if (currentStepId == null) return 'Desconhecido';
    final lastStep = steps.last;
    final lastStepId = int.tryParse(lastStep['id']?.toString() ?? lastStep['stepId']?.toString() ?? '');
    if (currentStepId == lastStepId) return 'Concluído';
    return 'Em Curso';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: COColors.brand900,
      drawer: const CoDrawer(),
      appBar: AppBar(
        title: const Text('PORTFÓLIO', style: TextStyle(letterSpacing: 1.5, fontSize: 13, fontWeight: COTokens.fwBold, color: COColors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: COColors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPortfolio,
        color: COColors.white,
        backgroundColor: COColors.brand900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: COTokens.space6, vertical: 10),
                itemCount: _categorias.length,
                itemBuilder: (context, index) {
                  final categoria = _categorias[index];
                  final bool isSelected = _filtroAtivo == categoria;
                  return GestureDetector(
                    onTap: () => setState(() => _filtroAtivo = categoria),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? COColors.brand300 : COColors.brand700.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Colors.white : COColors.brand700.withOpacity(0.6), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          categoria.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? COColors.brand900 : COColors.brand300,
                            fontSize: 11,
                            fontWeight: COTokens.fwBold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _portfolioFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _construirSkeletonLoading();
                  }

                  if (snapshot.hasError) {
                    final mensagem = snapshot.error is ApiException
                        ? (snapshot.error as ApiException).message
                        : 'Erro ao carregar os projetos.';
                    return UIHelpers.buildErrorState(
                      message: mensagem,
                      onRetry: () {
                        setState(() {
                          _portfolioFuture = ApiService().buscarPortfolio();
                        });
                      },
                    );
                  }

                  final projects = snapshot.data ?? [];
                  final statusProj = _obterStatus;
                  final projsFiltrados = projects.whereType<Map<String, dynamic>>().where((p) {
                    if (_filtroAtivo == 'Todos') return true;
                    final status = statusProj(p);
                    return status == _filtroAtivo;
                  }).toList();

                  if (projsFiltrados.isEmpty) {
                    return Center(
                      child: Text('Nenhum projeto $_filtroAtivo disponível.',
                          style: const TextStyle(color: COColors.neutral500)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(COTokens.space6),
                    itemCount: projsFiltrados.length,
                    itemBuilder: (context, index) {
                      final project = projsFiltrados[index];
                      final id = int.tryParse(project['id']?.toString() ?? '') ?? 0;
                      final titulo = project['name']?.toString() ?? 'Projeto sem título';
                      final cidade = project['city']?.toString() ?? '';
                      final stepsList = project['steps'] as List? ?? [];
                      final descricao = stepsList.isNotEmpty && stepsList[0] is Map
                          ? (stepsList[0]['description']?.toString() ?? '')
                          : 'Sem descrição';
                      final status = _obterStatus(project);
                      final imageUrl = project['mainImageUrl']?.toString() ?? '';
                      final projectKey = 'hero-portfolio-$index';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectDetailsScreen(
                                projectId: id,
                                heroTag: projectKey,
                                initialImageUrl: imageUrl,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: COTokens.space6),
                          decoration: BoxDecoration(
                            color: COColors.brand700.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(COTokens.radiusSm),
                            border: Border.all(color: COColors.brand700.withOpacity(0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(COTokens.radiusSm)),
                                    child: Hero(
                                      tag: projectKey,
                                      child: Material(
                                        type: MaterialType.transparency,
                                        child: imageUrl.isNotEmpty
                                            ? Image.network(
                                                imageUrl,
                                                height: 200,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stack) {
                                                  return Container(
                                                    height: 200,
                                                    color: COColors.brand700,
                                                    child: const Center(
                                                      child: Icon(Icons.broken_image, color: COColors.brand300, size: 50),
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                height: 200,
                                                color: COColors.brand700,
                                                child: const Center(
                                                  child: Icon(Icons.image_not_supported, color: COColors.neutral500, size: 50),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: status == 'Concluído' ? Colors.green.withOpacity(0.2) : COColors.brand300.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: status == 'Concluído' ? Colors.green.withOpacity(0.5) : COColors.brand300.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: status == 'Concluído' ? Colors.greenAccent : COColors.brand300,
                                          fontWeight: COTokens.fwBold,
                                          fontSize: 10,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(COTokens.space4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cidade.isNotEmpty ? '$titulo - $cidade' : titulo,
                                      style: const TextStyle(color: COColors.white, fontSize: 18, fontWeight: COTokens.fwBold),
                                    ),
                                    const SizedBox(height: COTokens.space2),
                                    Text(
                                      descricao,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: COColors.neutral500, fontSize: 13, height: 1.4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(COTokens.space6),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: COColors.brand700.withOpacity(0.4),
          highlightColor: COColors.brand300.withOpacity(0.1),
          child: Container(
            margin: const EdgeInsets.only(bottom: COTokens.space6),
            height: 280,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(COTokens.radiusSm),
            ),
          ),
        );
      },
    );
  }
}
