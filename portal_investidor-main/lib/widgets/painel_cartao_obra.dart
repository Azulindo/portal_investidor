import 'package:flutter/material.dart';

import '../models/sale_order.dart';
import '../models/user_model.dart';
import '../screens/project_details_screen.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import 'co_imagem.dart';
import 'painel_aquisicao.dart';
import 'visualizador_imagens.dart';

/// Um empreendimento no painel, como o cartão do portal do site
/// (PortalDashboard.tsx, project-card): a fotografia com o estado, o nome e a
/// morada, as frações da pessoa e o ano previsto, a régua da obra com as
/// fotografias de cada fase e, por baixo, as aquisições.
///
/// Branco, sobre o fundo claro do painel, como no site.
class ObraCardWidget extends StatelessWidget {
  const ObraCardWidget({
    super.key,
    required this.obra,
    required this.heroTag,
    this.encomendas = const [],
    this.aCarregarEncomendas = false,
    this.marcador,
  });

  /// Um widget invisível posto acima do cartão, para quem quiser descer
  /// até ele (a carteira do painel) o deixar logo abaixo da barra de cima.
  final Widget? marcador;

  final ConstructionItem obra;
  final String heroTag;

  /// As encomendas deste empreendimento. Vazia enquanto o pedido não chega
  /// ou se falhar: o cartão mostra o resto na mesma.
  final List<SaleOrder> encomendas;
  final bool aCarregarEncomendas;

  void _abrirEmpreendimento(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailsScreen(
          projectId: obra.id,
          heroTag: obra.imageUrl,
          initialImageUrl: obra.imageUrl,
        ),
      ),
    );
  }

  /// Rua e cidade, como o "Prelada, Porto" do site.
  String get _morada => [
        if ((obra.address ?? '').trim().isNotEmpty) obra.address!.trim(),
        if (obra.location.isNotEmpty && obra.location != obra.address)
          obra.location,
      ].join(', ');

  @override
  Widget build(BuildContext context) {
    final fracoes = SaleOrder.ordenarFracoes(
      encomendas.expand((o) => o.fractions),
    );

    final cartao = _cartao(context, fracoes);
    if (marcador == null) return cartao;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        cartao,
        // A barra de cima (com a da hora) tem à volta de 90px.
        Positioned(top: -104, left: 0, right: 0, child: marcador!),
      ],
    );
  }

  Widget _cartao(BuildContext context, List<String> fracoes) {
    return Container(
      margin: const EdgeInsets.only(bottom: COTokens.space6),
      padding: const EdgeInsets.all(COTokens.space4),
      decoration: BoxDecoration(
        color: COColors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F002847),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imagem(context),
          const SizedBox(height: COTokens.space4),
          // O nome leva aos detalhes (quando há página); o resto do cartão
          // tem os seus próprios toques.
          InkWell(
            onTap: obra.temPagina ? () => _abrirEmpreendimento(context) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        obra.title,
                        style: Claro.titulo.copyWith(fontSize: 20),
                      ),
                    ),
                    if (obra.temPagina)
                      const Icon(Icons.chevron_right,
                          color: COColors.brand500, size: 22),
                  ],
                ),
                if (_morada.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(_morada,
                      style: Claro.etiqueta.copyWith(fontSize: 14)),
                ],
              ],
            ),
          ),
          const SizedBox(height: COTokens.space4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('As suas frações', style: Claro.etiqueta),
                    const SizedBox(height: 6),
                    if (fracoes.isNotEmpty)
                      ChipsFracoes(fracoes)
                    else
                      Text(aCarregarEncomendas ? '…' : '—',
                          style: Claro.valor),
                  ],
                ),
              ),
              const SizedBox(width: COTokens.space4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Final previsto', style: Claro.etiqueta),
                  const SizedBox(height: 6),
                  Text(obra.anoFim ?? 'A confirmar', style: Claro.valor),
                ],
              ),
            ],
          ),
          if (obra.steps.isNotEmpty) ...[
            const SizedBox(height: COTokens.space6),
            Text('ESTADO DA OBRA', style: Claro.seccao),
            const SizedBox(height: COTokens.space4),
            ReguaObra(obra: obra),
          ],
          const SizedBox(height: COTokens.space6),
          const Divider(height: 1, color: COColors.bordaClara),
          const SizedBox(height: COTokens.space4),
          Text('AQUISIÇÕES', style: Claro.seccao),
          const SizedBox(height: COTokens.space4),
          if (encomendas.isEmpty)
            Text(
              aCarregarEncomendas
                  ? 'A carregar…'
                  : 'Sem aquisições associadas a este empreendimento.',
              style: Claro.etiqueta.copyWith(fontSize: 13),
            )
          else
            ListaAquisicoes(encomendas: encomendas, empreendimento: obra.title),
        ],
      ),
    );
  }

  Widget _imagem(BuildContext context) {
    final url = obra.imageUrl;
    final selos = [
      if (obra.status.isNotEmpty) obra.status,
      if (obra.estaAVenda) 'Em comercialização',
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          Hero(
            tag: heroTag,
            child: Material(
              type: MaterialType.transparency,
              child: url.isEmpty
                  ? _semImagem(Icons.image_outlined)
                  : GestureDetector(
                      // Tocar na fotografia abre-a em grande.
                      onTap: () => VisualizadorImagens.abrir(
                        context,
                        imagens: [url],
                        legendas: [obra.title],
                      ),
                      child: CoImagem(
                        url,
                        altura: 200,
                        largura: double.infinity,
                        erro: _semImagem(Icons.broken_image_outlined),
                      ),
                    ),
            ),
          ),
          if (selos.isNotEmpty)
            Positioned(
              top: 10,
              left: 10,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final s in selos) _selo(s)],
              ),
            ),
        ],
      ),
    );
  }

  Widget _selo(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: COColors.white,
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x2E002847), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: COColors.brand900,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _semImagem(IconData icone) {
    return Container(
      height: 200,
      width: double.infinity,
      color: COColors.neutral100,
      child: Icon(icone, color: COColors.brand300, size: 40),
    );
  }
}

/// As fases da obra lado a lado, cada uma com a sua fotografia, o número numa
/// bolinha e o nome — a card-timeline do site. Desliza para o lado e abre
/// centrada na fase em curso.
class ReguaObra extends StatefulWidget {
  const ReguaObra({super.key, required this.obra});

  final ConstructionItem obra;

  @override
  State<ReguaObra> createState() => _ReguaObraState();
}

class _ReguaObraState extends State<ReguaObra> {
  static const double _largura = 132;
  final _scroll = ScrollController();

  List<ConstructionStep> get _fases => widget.obra.steps;

  /// Quando a fase atual é a última, a obra está concluída: ficam todas
  /// feitas e nenhuma "em curso", como no site.
  bool get _concluida {
    if (_fases.isEmpty) return false;
    final ultima =
        _fases.map((s) => s.stepOrder).reduce((a, b) => a > b ? a : b);
    return widget.obra.currentStep >= ultima;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final i =
          _fases.indexWhere((s) => s.stepOrder == widget.obra.currentStep);
      if (i <= 0) return;
      final vista = _scroll.position.viewportDimension;
      final alvo = i * _largura - (vista - _largura) / 2;
      _scroll.jumpTo(alvo.clamp(0, _scroll.position.maxScrollExtent));
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final atual = widget.obra.currentStep;
    return SizedBox(
      height: 178,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        itemCount: _fases.length,
        itemBuilder: (context, i) {
          final f = _fases[i];
          final feita = _concluida || f.stepOrder < atual;
          final emCurso = !_concluida && f.stepOrder == atual;
          // A linha à esquerda acende quando esta fase já começou; à
          // direita, quando a seguinte já começou.
          final esquerdaAcesa = feita || emCurso;
          final direitaAcesa = feita;
          return SizedBox(
            width: _largura,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _foto(f),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 26,
                  child: Row(
                    children: [
                      Expanded(
                        child: i == 0
                            ? const SizedBox()
                            : _linha(esquerdaAcesa),
                      ),
                      _bolinha(f.stepOrder, feita, emCurso),
                      Expanded(
                        child: i == _fases.length - 1
                            ? const SizedBox()
                            : _linha(direitaAcesa),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    f.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.35,
                      letterSpacing: 0.5,
                      fontWeight: feita || emCurso
                          ? FontWeight.w600
                          : COTokens.fwRegular,
                      color: feita || emCurso
                          ? COColors.brand900
                          : COColors.brand500,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _foto(ConstructionStep f) {
    final url = f.imageUrl;
    final semFoto = Container(
      height: 88,
      width: double.infinity,
      color: COColors.neutral100,
      alignment: Alignment.center,
      child: Opacity(
        opacity: 0.45,
        child: Image.asset(
          'assets/images/logo.png',
          width: 70,
          color: COColors.brand500,
          colorBlendMode: BlendMode.srcIn,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: url == null || url.isEmpty
          ? semFoto
          : GestureDetector(
              onTap: () => VisualizadorImagens.abrir(
                context,
                imagens: [url],
                legendas: [f.name],
              ),
              child: CoImagem(url,
                  altura: 88, largura: double.infinity, erro: semFoto),
            ),
    );
  }

  Widget _linha(bool acesa) => Container(
        height: 1.5,
        color: acesa ? COColors.brand900 : COColors.bordaClara,
      );

  Widget _bolinha(int numero, bool feita, bool emCurso) {
    final Color fundo = feita
        ? COColors.brand900
        : (emCurso ? COColors.white : const Color(0xFFD8E1E9));
    final Color texto = feita
        ? COColors.white
        : (emCurso ? COColors.brand900 : const Color(0xFF7F94A7));
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fundo,
        shape: BoxShape.circle,
        border: Border.all(
          color: feita || emCurso ? COColors.brand900 : COColors.bordaClara,
          width: emCurso ? 2 : 1,
        ),
      ),
      child: Text(
        '$numero',
        style: TextStyle(
          color: texto,
          fontSize: 10,
          fontWeight: emCurso ? COTokens.fwBold : FontWeight.w600,
        ),
      ),
    );
  }
}
