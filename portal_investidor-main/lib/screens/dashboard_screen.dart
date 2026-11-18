import 'package:flutter/material.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../services/api_service.dart';
import '../services/aviso_versao.dart';
import '../services/notificacoes_push.dart';
import '../widgets/co_drawer.dart';
import '../models/investidor_model.dart';
import '../models/sale_order.dart';
import '../models/user_model.dart';
import '../utils/carteira.dart';
import '../utils/ui_helpers.dart';
import 'documents_screen.dart';
import '../widgets/sino_notificacoes.dart';
import '../widgets/painel_cabecalho.dart';
import '../widgets/painel_cartao_obra.dart';
import '../widgets/painel_esqueleto.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  late Future<InvestidorModel?> _investidorFuture;

  /// As encomendas vêm de um endpoint à parte (/document/sale-orders) e são o
  /// que alimenta os totais. Não travam o painel: se falharem, mostram-se as
  /// obras sem os totais, em vez de um ecrã de erro por cima de dados que já
  /// chegaram bem.
  late Future<List<SaleOrder>> _encomendasFuture;

  @override
  void initState() {
    super.initState();
    _carregar();
    // O painel é onde se chega depois do login e ao arrancar com sessão:
    // é aqui que se pede autorização e se regista o telemóvel para push.
    NotificacoesPush.ativarParaSessao();
    // Depois do primeiro frame, para o SnackBar ter onde aparecer.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AvisoVersao.verificar(context);
    });
  }

  void _carregar() {
    _investidorFuture = _apiService.buscarDadosDoInvestidor(
      ApiService.idLogado ?? 0,
    );
    _encomendasFuture = _apiService
        .buscarOrdensDeCompra()
        // Sem isto, uma falha aqui aparecia como um erro não tratado.
        .catchError((_) => <SaleOrder>[]);
  }

  void _recarregar() {
    // Quem puxa para atualizar quer dados novos, nao os de ha dois
    // minutos: a cache do ApiService tem de sair da frente.
    ApiService.limparCache();
    setState(_carregar);
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
              // Era um circulo a rodar no meio do ecra. O esqueleto nao
              // torna nada mais rapido, mas o olho ja sabe onde as coisas
              // vao aparecer e a espera sente-se menor.
              return const EsqueletoPainel();
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
                    elevation: 0,
                    scrolledUnderElevation: 0,
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

            // Como o portal do site: a faixa navy em cima com os totais e,
            // por baixo, o fundo claro com um cartão branco por
            // empreendimento.
            return FutureBuilder<List<SaleOrder>>(
              future: _encomendasFuture,
              builder: (context, snap) {
                // Encomendas em falta ou falhadas não escondem as obras: os
                // cartões aparecem na mesma, sem a parte do dinheiro.
                final encomendas = snap.data ?? const <SaleOrder>[];
                final aCarregar =
                    snap.connectionState == ConnectionState.waiting;

                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      pinned: true,
                      backgroundColor: COColors.brand900,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      leading: Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu, color: COColors.white),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      actions: [
                        const SinoNotificacoes(),
                        // As faturas estavam a dois toques, dentro do menu
                        // lateral. Para quem abre a app por causa do que
                        // deve, são o destino mais provável.
                        TextButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DocumentsScreen(),
                            ),
                          ),
                          icon: const Icon(
                            Icons.receipt_long_outlined,
                            size: 18,
                            color: COColors.brand300,
                          ),
                          label: const Text(
                            'Faturas',
                            style: TextStyle(
                              color: COColors.brand300,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: COTokens.space2),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          COTokens.space4,
                          COTokens.space2,
                          COTokens.space4,
                          COTokens.space8,
                        ),
                        child: CabecalhoPainel(
                          nome: user.name,
                          obras: obras,
                          encomendas: encomendas,
                          aCarregar: aCarregar,
                          aoTocarEmpreendimento: _irParaEmpreendimento,
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Container(
                        color: COColors.fundoClaro,
                        padding: const EdgeInsets.fromLTRB(
                          COTokens.space4,
                          COTokens.space6,
                          COTokens.space4,
                          40,
                        ),
                        child: obras.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: COTokens.space8,
                                ),
                                child: Text(
                                  'Ainda não tem empreendimentos associados à '
                                  'sua conta. Assim que tiver, aparecerão aqui.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: COColors.brand500,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  for (var i = 0; i < obras.length; i++)
                                    ObraCardWidget(
                                      marcador: SizedBox(
                                        key: _chaveDe(obras[i]),
                                        height: 1,
                                      ),
                                      obra: obras[i],
                                      heroTag:
                                          'hero-dashboard-${obras[i].id}-$i',
                                      encomendas: Carteira.doEmpreendimento(
                                        obras[i].title,
                                        encomendas,
                                      ),
                                      aCarregarEncomendas: aCarregar,
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Uma chave por empreendimento, para a carteira lá de cima poder descer
  /// até ao cartão certo.
  final Map<int, GlobalKey> _chaves = {};
  GlobalKey _chaveDe(ConstructionItem obra) =>
      _chaves.putIfAbsent(obra.id, () => GlobalKey());

  void _irParaEmpreendimento(ConstructionItem obra) {
    final contexto = _chaves[obra.id]?.currentContext;
    if (contexto == null) return;
    // A chave está num marcador de 1px acima do cartão (ver
    // ObraCardWidget.marcador), e não no cartão: um cartão mais alto do que
    // o ecrã, com alinhamento ao topo, ficava a meio; e o topo exato ficava
    // por baixo da barra de cima.
    Scrollable.ensureVisible(
      contexto,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }
}
