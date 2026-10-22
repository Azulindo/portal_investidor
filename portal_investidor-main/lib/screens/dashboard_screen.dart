import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../services/api_service.dart';
import '../widgets/co_card.dart';
import '../widgets/co_drawer.dart';
import '../models/investidor_model.dart';
import '../models/sale_order.dart';
import '../models/user_model.dart';
import '../utils/carteira.dart';
import '../utils/ui_helpers.dart';
import 'documents_screen.dart';
import 'project_details_screen.dart';
import '../widgets/co_imagem.dart';

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
              return const _PainelEsqueleto();
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
                              _Cabecalho(
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

  /// As encomendas deste empreendimento, para o cartao poder dizer quanto
  /// esta investido e quanto falta pagar. Vazia enquanto o pedido das
  /// encomendas nao chega, ou se falhar: nesse caso o cartao mostra o
  /// resto na mesma.
  final List<SaleOrder> encomendas;

  const ObraCardWidget({
    super.key,
    required this.obra,
    required this.heroTag,
    this.encomendas = const [],
  });

  @override
  Widget build(BuildContext context) {
    final urlImagem = obra.imageUrl;

    return CoCard(
      semPadding: true,
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
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEM PRINCIPAL DO PROJETO (com Hero para a transição)
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Hero(
                    tag: heroTag,
                    child: Material(
                      type: MaterialType.transparency,
                      child: urlImagem.isNotEmpty
                          ? CoImagem(
                              urlImagem,
                              altura: 190,
                              largura: double.infinity,
                              erro: _imagePlaceholder(broken: true),
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
              padding: const EdgeInsets.all(COTokens.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NOME DO PROJETO
                  Text(
                    obra.title,
                    style: COText.h2.copyWith(fontWeight: COTokens.fwBold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // Eram tres linhas com icone, uma por cima da outra.
                  // Numa so poupa-se altura e le-se de uma vez.
                  Text(
                    [
                      if (obra.location.isNotEmpty) obra.location,
                      if (_fracoes > 0)
                        Carteira.contagem(_fracoes, 'fração', 'frações'),
                      if (obra.anoFim != null)
                        'conclusão prevista ${obra.anoFim}',
                    ].join('  ·  '),
                    style: COText.caption,
                  ),

                  const SizedBox(height: COTokens.space4),

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
                            style: TextStyle(
                              color: COColors.brand300,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Timeline disponível em breve!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: COColors.brand300,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (obra.steps.isNotEmpty)
                    _Timeline(obra: obra),

                  if (encomendas.isNotEmpty) _dinheiro(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Quantas fracoes a pessoa tem aqui, sem repeticoes — a mesma fracao
  /// pode vir em mais do que uma encomenda (um reforco, uma alteracao).
  int get _fracoes => encomendas.expand((o) => o.fractions).toSet().length;

  /// O investido e o por pagar deste empreendimento.
  ///
  /// Saem das encomendas, as mesmas contas da carteira, para o cartao e o
  /// total la de cima nunca discordarem.
  Widget _dinheiro() {
    final investido = Carteira.investimentoTotal(encomendas);
    final porPagar = Carteira.totalPorPagar(encomendas);

    return Padding(
      padding: const EdgeInsets.only(top: COTokens.space4),
      child: Container(
        padding: const EdgeInsets.only(top: COTokens.space4),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: COColors.brand700)),
        ),
        child: Row(
          children: [
            Expanded(child: _valor('Investido', Carteira.euros(investido))),
            Expanded(
              child: _valor(
                'Por pagar',
                Carteira.euros(porPagar),
                // O que falta pagar e a unica coisa aqui sobre a qual a
                // pessoa tem de agir, por isso e a unica com cor.
                cor: porPagar > 0 ? COColors.accent : COColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _valor(String etiqueta, String valor, {Color cor = COColors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: COText.caption),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            color: cor,
            fontSize: 15,
            fontWeight: COTokens.fwBold,
          ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder({required bool broken}) {
    return Container(
      height: 190,
      color: COColors.brand700,
      child: Center(
        child: broken
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: COColors.brand300,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Imagem indisponível',
                    style: TextStyle(color: COColors.neutral500, fontSize: 12),
                  ),
                ],
              )
            : const Icon(
                Icons.image_outlined,
                color: COColors.brand500,
                size: 40,
              ),
      ),
    );
  }
}

// =========================================================
// TIMELINE HORIZONTAL (interna ao card)
// Uma bolinha por fase, acesas até à fase atual, e por baixo uma linha a
// dizer em que fase vai a obra.
// =========================================================
class _Timeline extends StatelessWidget {
  final ConstructionItem obra;

  const _Timeline({required this.obra});

  @override
  Widget build(BuildContext context) {
    final steps = obra.steps;
    final currentIndex = steps.indexWhere(
      (s) => s.stepOrder == obra.currentStep,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _regua(steps, currentIndex),
        if (currentIndex != -1) ...[
          const SizedBox(height: 8),
          Text(
            'Fase ${currentIndex + 1} de ${steps.length} · '
            '${steps[currentIndex].name}',
            style: COText.caption.copyWith(color: COColors.brand300),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _regua(List<ConstructionStep> steps, int currentIndex) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final isCurrent = index == currentIndex;
        final isDone = currentIndex != -1 && index <= currentIndex;
        final showLeftLine = index > 0;
        final showRightLine = index < steps.length - 1;
        final leftLineDone = currentIndex != -1 && index <= currentIndex;
        final rightLineDone = currentIndex != -1 && index < currentIndex;

        // Os verdes do Material (greenAccent/green) saiam fora da marca:
        // a Cleveroption nao tem verde em sitio nenhum. A regua passa a ser
        // monocromatica sobre o navy — por fazer e escuro, feito e cinza
        // claro, a fase atual e branca. Le-se melhor e e da casa.
        final Color dotColor = isCurrent
            ? COColors.white
            : (isDone ? COColors.brand300 : COColors.brand700);

        return Expanded(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: showLeftLine
                        ? Container(
                            height: 1,
                            color: leftLineDone
                                ? COColors.brand300
                                : COColors.brand700,
                          )
                        : const SizedBox(),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                    ),
                  ),
                  Expanded(
                    child: showRightLine
                        ? Container(
                            height: 1,
                            color: rightLineDone
                                ? COColors.brand300
                                : COColors.brand700,
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
              // Aqui estava o nome da fase debaixo de cada bolinha. Com cinco
              // fases num telemóvel cada coluna fica com ~60px, e nomes como
              // "Fundações" ou "Acabamentos" partiam-se a meio da palavra
              // ("Fundaçõ / es"). O nome da fase passou para uma linha só,
              // debaixo da régua — é também como o cartão do portfólio o
              // mostra, por isso os dois ecrãs passam a ler-se igual.
            ],
          ),
        );
      }),
    );
  }
}

// =========================================================
// CABECALHO DO PAINEL
// =========================================================

/// O numero grande do painel.
///
/// Era o investimento total. Mas num modelo em que a Cleveroption constroi
/// e vende, o total e um numero estatico que o investidor ja sabe de cor —
/// nao e por causa dele que abre a app. O que o traz ca e o que ainda deve.
/// O total passa para a linha de baixo, onde continua a dar contexto.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({
    required this.nome,
    required this.encomendas,
    required this.aCarregar,
  });

  final String nome;
  final List<SaleOrder> encomendas;
  final bool aCarregar;

  /// So o primeiro nome. "Ola, Guilherme Goncalves" ocupava duas linhas em
  /// muitos telemoveis e nao dizia mais do que "Ola, Guilherme".
  String get _primeiroNome => nome.trim().split(RegExp(r'\s+')).first;

  @override
  Widget build(BuildContext context) {
    final saudacao = Text(
      _primeiroNome.isEmpty ? 'Olá' : 'Olá, $_primeiroNome',
      style: COText.h1.copyWith(fontSize: 22),
    );

    // Sem encomendas nao ha numeros para mostrar: fica so a saudacao, em
    // vez de um "0 €" que parecia um erro.
    if (encomendas.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          saudacao,
          if (aCarregar) ...[
            const SizedBox(height: COTokens.space4),
            const _Osso(largura: 180, altura: 28),
          ],
        ],
      );
    }

    final porPagar = Carteira.totalPorPagar(encomendas);
    final total = Carteira.investimentoTotal(encomendas);
    final pct = Carteira.percentagemPaga(encomendas);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        saudacao,
        const SizedBox(height: COTokens.space4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              Carteira.euros(porPagar),
              style: COText.h1.copyWith(fontSize: 28, height: 1.1),
            ),
            const SizedBox(width: 10),
            const Text('por pagar', style: COText.small),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'de ${Carteira.euros(total)} investidos  ·  $pct% liquidado',
          style: COText.caption,
        ),
        const SizedBox(height: 10),
        // A barra repete o que a linha de cima diz por extenso, mas le-se
        // sem ler.
        Semantics(
          label: '$pct por cento liquidado',
          child: SizedBox(
            height: 2,
            child: Row(
              children: [
                Expanded(
                  flex: pct.clamp(0, 100),
                  child: Container(color: COColors.accent),
                ),
                Expanded(
                  flex: (100 - pct).clamp(0, 100),
                  child: Container(color: COColors.brand700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================
// ESQUELETO DE CARREGAMENTO
// =========================================================

/// A forma do painel enquanto os dados nao chegam.
///
/// Segue o que o ecra vai mesmo mostrar: saudacao, o numero grande, e dois
/// cartoes de empreendimento. Se o painel mudar de forma, isto tem de
/// mudar com ele — um esqueleto que nao bate certo com o que aparece a
/// seguir e pior do que nenhum, porque o conteudo salta.
class _PainelEsqueleto extends StatelessWidget {
  const _PainelEsqueleto();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: COColors.brand700,
      highlightColor: COColors.brand500,
      child: ListView(
        padding: const EdgeInsets.all(COTokens.space6),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          SizedBox(height: COTokens.space4),
          _Osso(largura: 170, altura: 22),
          SizedBox(height: COTokens.space6),
          _Osso(largura: 210, altura: 28),
          SizedBox(height: 10),
          _Osso(largura: 150, altura: 12),
          SizedBox(height: 14),
          _Osso(largura: double.infinity, altura: 2),
          SizedBox(height: COTokens.space8),
          _Osso(largura: 180, altura: 18),
          SizedBox(height: COTokens.space4),
          _CartaoEsqueleto(),
          SizedBox(height: COTokens.space4),
          _CartaoEsqueleto(),
        ],
      ),
    );
  }
}

class _CartaoEsqueleto extends StatelessWidget {
  const _CartaoEsqueleto();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: COColors.brand700),
        borderRadius: BorderRadius.circular(COTokens.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Osso(largura: double.infinity, altura: 190, raio: 0),
          Padding(
            padding: const EdgeInsets.all(COTokens.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Osso(largura: 140, altura: 18),
                SizedBox(height: 9),
                _Osso(largura: 200, altura: 12),
                SizedBox(height: 18),
                _Osso(largura: double.infinity, altura: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Um retangulo cinzento. O Shimmer por cima e que lhe da o brilho.
class _Osso extends StatelessWidget {
  const _Osso({required this.largura, required this.altura, this.raio = 4});

  final double largura;
  final double altura;
  final double raio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: largura,
      height: altura,
      decoration: BoxDecoration(
        color: COColors.brand700,
        borderRadius: BorderRadius.circular(raio),
      ),
    );
  }
}
