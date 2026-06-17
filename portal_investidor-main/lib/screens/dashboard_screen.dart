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
                    title: Image.asset('assets/images/logo.png', height: 45),
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

                      // CARTÃO DE SALDO
                      Container(
                        padding: const EdgeInsets.all(COTokens.space6),
                        decoration: BoxDecoration(
                            color: COColors.white,
                            borderRadius: BorderRadius.circular(COTokens.radiusSm)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TOTAL FINANCIADO',
                                style: TextStyle(
                                    color: COColors.neutral500,
                                    fontWeight: COTokens.fwMedium,
                                    fontSize: 11,
                                    letterSpacing: 1.5)),
                            const SizedBox(height: 8),
                            Consumer<PrivacyService>(
                              builder: (context, privacyService, child) {
                                return Row(
                                  children: [
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      transitionBuilder: (Widget child, Animation<double> animation) {
                                        return FadeTransition(opacity: animation, child: child);
                                      },
                                      child: Text(
                                        key: ValueKey(privacyService.isMasked),
                                        privacyService.maskCurrency(user.totalInvested),
                                        style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: COTokens.fwBold,
                                            color: COColors.brand900),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      icon: Icon(
                                          privacyService.isMasked ? Icons.visibility_off : Icons.visibility,
                                          color: COColors.brand900),
                                      onPressed: () => privacyService.toggleMask(),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Container(height: 1, color: COColors.neutral100),
                            const SizedBox(height: 12),
                            Text(
                              user.roiEsperado != null
                                  ? 'ROI Contratual Estimado: ${user.roiEsperado!.toStringAsFixed(1)}%'
                                  : 'ROI Contratual Estimado: informação não disponível',
                              style: const TextStyle(
                                  color: COColors.brand500,
                                  fontSize: 12,
                                  fontWeight: COTokens.fwMedium),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: COTokens.space8),

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
              heroTag: heroTag,
              initialImageUrl: obra.imageUrl,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: COTokens.space6),
        decoration: BoxDecoration(
          color: COColors.brand700.withOpacity(0.3),
          borderRadius: BorderRadius.circular(COTokens.radiusSm),
          border: Border.all(color: COColors.brand700.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEM PRINCIPAL DO PROJETO (com Hero para a transição)
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
                  if (obra.steps.isNotEmpty) _Timeline(obra: obra),
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
    // Índice (na lista, já com a ordem em que vem da API) do step atual.
    // -1 se currentStep não corresponder ao "stepOrder" de nenhum step.
    // ALTERADO: antes comparava "s.id" com "obra.currentStepId".
    final currentIndex = steps.indexWhere((s) => s.stepOrder == obra.currentStep);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isHighlighted = currentIndex != -1 && index <= currentIndex;

        final showLeftLine = index > 0;
        final showRightLine = index < steps.length - 1;
        // Linha à direita só destacada se houver step destacado depois deste.
        final rightLineHighlighted = currentIndex != -1 && index < currentIndex;
        final leftLineHighlighted = isHighlighted;

        return Expanded(
          child: Column(
            children: [
              // BOLA + LINHAS
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: showLeftLine
                        ? Container(
                            height: 2,
                            color: leftLineHighlighted ? COColors.brand300 : COColors.brand700,
                          )
                        : const SizedBox(),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHighlighted ? COColors.brand300 : Colors.transparent,
                      border: Border.all(
                        color: isHighlighted ? COColors.brand300 : COColors.brand500,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '${step.stepOrder}',
                      style: TextStyle(
                        color: isHighlighted ? COColors.brand900 : COColors.brand300,
                        fontSize: 11,
                        fontWeight: COTokens.fwBold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: showRightLine
                        ? Container(
                            height: 2,
                            color: rightLineHighlighted ? COColors.brand300 : COColors.brand700,
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // NOME DO STEP
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  step.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isHighlighted ? COColors.white : COColors.neutral500,
                    fontSize: 10,
                    fontWeight: isHighlighted ? COTokens.fwMedium : COTokens.fwRegular,
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
