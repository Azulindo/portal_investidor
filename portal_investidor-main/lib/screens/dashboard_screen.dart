import 'package:flutter/material.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../services/api_service.dart';
import '../services/notificacoes_push.dart';
import '../widgets/co_card.dart';
import '../widgets/co_drawer.dart';
import '../models/investidor_model.dart';
import '../models/sale_order.dart';
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

            return CustomScrollView(
              slivers: [
                // O logótipo saiu daqui. Já está no menu lateral e na página
                // de entrada; repeti-lo em cima de cada ecrã interno gastava
                // 100px de altura sem dizer nada de novo. O que fica é o
                // botão do menu — o título do ecrã é o "Olá, ..." em baixo.
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
                    // lateral. Para quem abre a app por causa do que deve,
                    // sao o destino mais provavel.
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
                SliverPadding(
                  padding: const EdgeInsets.all(COTokens.space6),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // O painel dizia duas vezes a mesma coisa: listava os
                      // empreendimentos em "As suas aquisicoes" e outra vez
                      // em "Estado das obras". Sem fazer scroll via-se os
                      // totais e meia lista de encomendas — obra nenhuma,
                      // que e o que a pessoa vem ca ver.
                      //
                      // Agora e um cartao por empreendimento com as duas
                      // coisas juntas, e os dois cabem no ecra.
                      FutureBuilder<List<SaleOrder>>(
                        future: _encomendasFuture,
                        builder: (context, snap) {
                          // Encomendas em falta ou falhadas nao escondem as
                          // obras: o cartao aparece na mesma, sem a parte
                          // do dinheiro.
                          final encomendas = snap.data ?? const <SaleOrder>[];
                          final aCarregar =
                              snap.connectionState == ConnectionState.waiting;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CabecalhoPainel(
                                nome: user.name,
                                encomendas: encomendas,
                                aCarregar: aCarregar,
                              ),
                              const SizedBox(height: COTokens.space8),
                              const CoTitulo('Os seus empreendimentos'),

                              if (obras.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: COTokens.space8,
                                  ),
                                  child: Column(
                                    children: [
                                      Opacity(
                                        opacity: 0.2,
                                        child: Image.asset(
                                          'assets/images/logo.png',
                                          height: 80,
                                        ),
                                      ),
                                      const SizedBox(height: COTokens.space6),
                                      const Text(
                                        'Ainda não existem registos associados ao seu perfil.',
                                        style: COText.caption,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ...List.generate(
                                  obras.length,
                                  (index) => ObraCardWidget(
                                    obra: obras[index],
                                    heroTag:
                                        'hero-dashboard-${obras[index].id}-$index',
                                    encomendas: Carteira.doEmpreendimento(
                                      obras[index].title,
                                      encomendas,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),

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
