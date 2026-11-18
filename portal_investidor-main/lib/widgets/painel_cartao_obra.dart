import 'package:flutter/material.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import 'co_card.dart';
import '../models/sale_order.dart';
import '../models/user_model.dart';
import '../utils/carteira.dart';
import '../utils/portfolio.dart';
import '../utils/ui_helpers.dart';
import '../screens/project_details_screen.dart';
import 'co_imagem.dart';
import 'detalhe_de_valores.dart';
import 'visualizador_imagens.dart';


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
      // Sem pagina nao ha para onde ir: a API responde 404 aos detalhes de um
      // empreendimento so de historial. O cartao fica sem toque, em vez de
      // levar a pessoa a um ecra de erro.
      onTap: obra.temPagina
          ? () {
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
            }
          : null,
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
                          // Tocar na fotografia abre-a em grande, em vez de
                          // abrir o empreendimento: e o gesto que se espera
                          // de uma imagem, e o resto do cartao continua a
                          // levar aos detalhes.
                          ? GestureDetector(
                              onTap: () => VisualizadorImagens.abrir(
                                context,
                                imagens: [urlImagem],
                                legendas: [obra.title],
                              ),
                              child: CoImagem(
                                urlImagem,
                                altura: 190,
                                largura: double.infinity,
                                erro: _imagePlaceholder(broken: true),
                              ),
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
                        // Em minúsculas porque vem a meio da linha.
                        Portfolio.conclusao(obra.status, obra.anoFim!)
                            .toLowerCase(),
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

                  if (encomendas.isNotEmpty) _dinheiro(context),
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

  /// O pago e o por pagar deste empreendimento.
  ///
  /// Saem das encomendas, as mesmas contas da carteira, para o cartao e o
  /// total la de cima nunca discordarem.
  ///
  /// O par e "pago" e "por pagar", e nao o total e o que falta: os dois
  /// somam o valor da encomenda, por isso o total continua a ler-se sem
  /// precisar de uma terceira coluna num cartao de telemovel.
  Widget _dinheiro(BuildContext context) {
    final pago = Carteira.totalPago(encomendas);
    final porPagar = Carteira.totalPorPagar(encomendas);

    return Padding(
      padding: const EdgeInsets.only(top: COTokens.space4),
      child: GestureDetector(
        // Toque proprio, separado do resto do cartao: "por pagar" junta o que
        // ja foi faturado com o que ainda nem foi, e essa diferenca nao cabe
        // aqui. Quem quiser saber, toca.
        onTap: encomendas.isEmpty
            ? null
            : () => DetalheDeValores.abrir(
                  context,
                  empreendimento: obra.title,
                  encomendas: encomendas,
                ),
        // Sem isto o toque so conta em cima dos numeros, e falha no espaco
        // entre eles.
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.only(top: COTokens.space4),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: COColors.brand700)),
          ),
          child: Row(
            children: [
              Expanded(child: _valor('Pago', Carteira.euros(pago))),
              Expanded(
                child: _valor(
                  'Por pagar',
                  Carteira.euros(porPagar),
                  // O que falta pagar e a unica coisa aqui sobre a qual a
                  // pessoa tem de agir, por isso e a unica com cor.
                  cor: porPagar > 0 ? COColors.accent : COColors.white,
                ),
              ),
              // A pista de que isto se toca. Sem encomendas nao ha o que
              // mostrar, e entao tambem nao aparece.
              if (encomendas.isNotEmpty)
                const Icon(
                  Icons.chevron_right,
                  color: COColors.brand300,
                  size: 20,
                ),
            ],
          ),
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
