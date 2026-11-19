import 'package:flutter/material.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../services/api_service.dart';
import '../services/aviso_versao.dart';
import '../services/notificacoes_push.dart';
import '../widgets/co_drawer.dart';
import '../widgets/efeitos.dart';
import '../widgets/painel_anuncios.dart';
import '../models/investidor_model.dart';
import '../models/sale_order.dart';
import '../models/user_model.dart';
import '../utils/carteira.dart';
import '../utils/ui_helpers.dart';
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
                      // O símbolo da Cleveroption no topo do painel, preso à
                      // barra. Era o logótipo inteiro, mas com o nome escrito
                      // (e a margem que a imagem tem à volta) cabia minúsculo
                      // entre o menu e as Faturas. O símbolo sozinho lê-se a
                      // este tamanho. É o mesmo dos pinos do mapa (branco,
                      // sem fundo, gerado por loja/gerar.ps1).
                      centerTitle: true,
                      title: Image.asset(
                        'assets/images/simbolo_mapa.png',
                        height: 38,
                        fit: BoxFit.contain,
                        semanticLabel: 'Clever Option',
                      ),
                      // Havia aqui também um botão "Faturas". Saiu: as faturas
                      // abrem-se no próprio painel (tocar numa aquisição) e
                      // continuam no menu lateral, e sem ele o símbolo fica
                      // centrado e com espaço.
                      actions: const [
                        SinoNotificacoes(),
                        SizedBox(width: COTokens.space2),
                      ],
                    ),
                    SliverToBoxAdapter(
                      // Ao descer, o topo fica para trás mais devagar e
                      // desvanece, e a folha clara passa-lhe por cima.
                      child: Paralaxe(
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
                    ),
                    // Um SliverToBoxAdapter, e não o SliverFillRemaining que
                    // estava: esse mede o filho pelas medidas intrínsecas, que
                    // a régua da obra (lista horizontal) e a barra das
                    // aquisições (LayoutBuilder) não sabem dar — a altura saía
                    // curta e o último cartão ficava cortado em baixo.
                    SliverToBoxAdapter(
                      child: FolhaClara(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Os anúncios em destaque, antes dos
                            // empreendimentos, como no topo da Área Reservada.
                            const PainelAnuncios(),
                            obras.isEmpty
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
                                        Revelar(
                                          child: ObraCardWidget(
                                            marcador: SizedBox(
                                              key: _chaveDe(obras[i]),
                                              height: 1,
                                            ),
                                            obra: obras[i],
                                            heroTag:
                                                'hero-dashboard-${obras[i].id}-$i',
                                            encomendas:
                                                Carteira.doEmpreendimento(
                                                  obras[i].title,
                                                  encomendas,
                                                ),
                                            aCarregarEncomendas: aCarregar,
                                          ),
                                        ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                    // Quando há pouco conteúdo, o resto do ecrã fica claro e
                    // não com o navy do fundo a aparecer por baixo da folha.
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: ColoredBox(color: COColors.fundoClaro),
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
