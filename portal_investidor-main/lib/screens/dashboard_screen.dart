import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../services/api_service.dart';
import '../services/privacy_service.dart';
import '../widgets/co_drawer.dart';
import '../models/investidor_model.dart';
import '../models/user_model.dart';
import '../utils/ui_helpers.dart';
import 'project_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<InvestidorModel?> _investidorFuture;

  @override
  void initState() {
    super.initState();
    _investidorFuture = _apiService.buscarDadosDoInvestidor(ApiService.idLogado ?? 0);
  }

  void _recarregar() {
    setState(() {
      _investidorFuture = _apiService.buscarDadosDoInvestidor(ApiService.idLogado ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: COColors.brand900,
      drawer: const CoDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          _recarregar();
          await _investidorFuture.catchError((_) => null);
        },
        color: COColors.white,
        backgroundColor: COColors.brand900,
        child: FutureBuilder<InvestidorModel?>(
          future: _investidorFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: COColors.white));
            }

            if (snapshot.hasError || snapshot.data == null) {
              final mensagem = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Não foi possível carregar os seus dados. Verifique a sua ligação à internet.';

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    pinned: true,
                    backgroundColor: COColors.brand900,
                    leading: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: COColors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      title: Image.asset('assets/images/logo.png', height: 45),
                      centerTitle: true,
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: UIHelpers.buildErrorState(
                      message: mensagem,
                      onRetry: _recarregar,
                    ),
                  ),
                ],
              );
            }

            final user = snapshot.data!;
            final obras = user.obras;

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 100,
                  floating: true,
                  pinned: true,
                  backgroundColor: COColors.brand900,
                  leading: Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu, color: COColors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    title: Image.asset('assets/images/logo.png', height: 65),
                    centerTitle: true,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(COTokens.space6),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text('Olá, ${user.name}',
                          style: const TextStyle(fontSize: 22, fontWeight: COTokens.fwBold, color: COColors.white)),
                      const SizedBox(height: 4),
                      const Text('Bem-vindo ao seu painel de investimentos.',
                          style: TextStyle(color: COColors.brand300, fontSize: 13)),
                      const SizedBox(height: COTokens.space6),

                      const Text('STATUS DAS OBRAS',
                          style: TextStyle(
                              color: COColors.brand300,
                              fontSize: 11,
                              fontWeight: COTokens.fwBold,
                              letterSpacing: 1.5)),
                      const SizedBox(height: COTokens.space4),

                      if (obras.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: COTokens.space8),
                          child: Column(
                            children: [
                              Opacity(opacity: 0.2, child: Image.asset('assets/images/logo.png', height: 80)),
                              const SizedBox(height: COTokens.space6),
                              const Text('Ainda não existem registos associados ao seu perfil.',
                                  style: TextStyle(color: COColors.neutral500, fontSize: 14)),
                            ],
                          ),
                        )
                      else
                        ...List.generate(obras.length, (index) => ObraCardWidget(
                              obra: obras[index],
                              heroTag: 'hero-dashboard-${obras[index].id}-$index',
                            )),

                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =========================================================
// CARD DE OBRA (SIMPLIFICADO)
// Mostra imagem, nome, cidade, data prevista de conclusão e
// uma timeline horizontal numerada com destaque até currentStep.
// Ao tocar, abre o ProjectDetailsScreen (que busca os detalhes
// completos via GET /api/project/details?projectId=id).
// =========================================================
class ObraCardWidget extends StatelessWidget {
  final ConstructionItem obra;
  final String heroTag;

  const ObraCardWidget({super.key, required this.obra, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final urlImagem = obra.imageUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailsScreen(
              projectId: obra.id,
              heroTag: obra.imageUrl,
              initialImageUrl: obra.imageUrl,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: COTokens.space6),
        decoration: BoxDecoration(
          color: COColors.brand700.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(COTokens.radiusSm),
          border: Border.all(color: COColors.brand700.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEM PRINCIPAL DO PROJETO (com Hero para a transição)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(COTokens.radiusSm)),
                  child: Hero(
                    tag: heroTag,
                    child: Material(
                      type: MaterialType.transparency,
                      child: urlImagem.isNotEmpty
                          ? Image.network(
                              urlImagem,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _imagePlaceholder(broken: true);
                              },
                            )
                          : _imagePlaceholder(broken: false),
                    ),
                  ),
                ),
                if (obra.status.isNotEmpty)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: UIHelpers.buildStatusBadge(obra.status),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(COTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NOME DO PROJETO
                  Text(
                    obra.title,
                    style: const TextStyle(
                      color: COColors.white,
                      fontSize: 16,
                      fontWeight: COTokens.fwBold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // CIDADE
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: COColors.brand300, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          obra.location,
                          style: const TextStyle(color: COColors.brand300, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // DATA PREVISTA DE CONCLUSÃO
                  if (obra.dataFim != null && obra.dataFim!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: COColors.brand300, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Data Prevista de Conclusão: ${obra.dataFim}',
                            style: const TextStyle(color: COColors.brand300, fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: COTokens.space6),

                  // TIMELINE HORIZONTAL DAS FASES
                  if (obra.status == 'Desenvolvimento')
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Projeto em desenvolvimento.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: COColors.brand300, fontSize: 14),
                          ),
                          Text(
                            'Timeline disponível em breve!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: COColors.brand300, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else if (obra.steps.isNotEmpty)
                    _Timeline(obra: obra),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder({required bool broken}) {
    return Container(
      height: 180,
      color: COColors.brand700,
      child: Center(
        child: broken
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_outlined, color: COColors.brand300, size: 40),
                  const SizedBox(height: 8),
                  const Text(
                    'Imagem indisponível',
                    style: TextStyle(color: COColors.neutral500, fontSize: 12),
                  ),
                ],
              )
            : const Icon(Icons.image_outlined, color: COColors.brand500, size: 40),
      ),
    );
  }
}

// =========================================================
// TIMELINE HORIZONTAL (interna ao card)
// Bolas numeradas (stepOrder) + nome do step por baixo.
// Destacadas (cor brand300) até ao step cujo stepOrder == currentStep.
// =========================================================
class _Timeline extends StatelessWidget {
  final ConstructionItem obra;

  const _Timeline({required this.obra});

  @override
  Widget build(BuildContext context) {
    final steps = obra.steps;
    final currentIndex = steps.indexWhere((s) => s.stepOrder == obra.currentStep);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isCurrent = index == currentIndex;
        final isDone = currentIndex != -1 && index <= currentIndex;
        final showLeftLine = index > 0;
        final showRightLine = index < steps.length - 1;
        final leftLineDone = currentIndex != -1 && index <= currentIndex;
        final rightLineDone = currentIndex != -1 && index < currentIndex;

        final Color dotColor = isCurrent
            ? Colors.greenAccent
            : (isDone ? Colors.green : COColors.brand700);
        final Color dotBorder = isCurrent ? Colors.white : dotColor;

        return Expanded(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: showLeftLine
                        ? Container(height: 2, color: leftLineDone ? Colors.green : COColors.brand700)
                        : const SizedBox(),
                  ),
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                      border: isCurrent ? Border.all(color: dotBorder, width: 2) : null,
                    ),
                  ),
                  Expanded(
                    child: showRightLine
                        ? Container(height: 2, color: rightLineDone ? Colors.green : COColors.brand700)
                        : const SizedBox(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  step.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrent ? Colors.white : (isDone ? COColors.brand300 : COColors.neutral500),
                    fontSize: 10,
                    fontWeight: isCurrent ? COTokens.fwBold : COTokens.fwRegular,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
