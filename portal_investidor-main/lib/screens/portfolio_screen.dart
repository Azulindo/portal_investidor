import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../services/api_service.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/portfolio.dart';
import '../utils/ui_helpers.dart';
import '../widgets/barra_progresso_obra.dart';
import '../widgets/co_card.dart';
import '../widgets/co_drawer.dart';
import 'project_details_screen.dart';

/// O portfólio, a par da página /portfolio do site: contadores no cabeçalho,
/// filtros de estado, cidade e comercialização, e os empreendimentos
/// agrupados nas três secções.
///
/// Os cálculos (grupos de estado, ordem, progresso, contagens) estão em
/// utils/portfolio.dart e são os mesmos do site.
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key, this.apenasAVendaInicial = false});

  /// Abre já com o filtro de comercialização ligado.
  ///
  /// É o que o menu usa para "Em comercialização". No site isso é uma página
  /// à parte, mas a lista é exatamente a mesma do portfólio filtrado — fazer
  /// aqui um segundo ecrã era duplicar tudo para o mesmo resultado, e cada
  /// regra nova teria de ser mudada em dois sítios.
  final bool apenasAVendaInicial;

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  /// null = todos. Os valores são os grupos de Portfolio.grupoDeEstado.
  ///
  /// Antes os filtros comparavam o estado por igualdade exata
  /// (status == 'Construção'), e por isso um projeto marcado como
  /// "Em construção" não aparecia em filtro nenhum.
  String? _grupo;
  String? _cidade;
  bool _apenasAVenda = false;

  late Future<List<dynamic>> _portfolioFuture;

  static const Map<String, String> _nomesDosGrupos = {
    'ativo': 'Em construção',
    'desenvolvimento': 'Em desenvolvimento',
    'concluido': 'Concluídos',
  };

  @override
  void initState() {
    super.initState();
    _apenasAVenda = widget.apenasAVendaInicial;
    _portfolioFuture = ApiService().buscarPortfolio();
  }

  void _recarregar() {
    setState(() {
      _portfolioFuture = ApiService().buscarPortfolio();
    });
  }

  Future<void> _refreshPortfolio() async {
    _recarregar();
    await _portfolioFuture.catchError((_) => <dynamic>[]);
  }

  bool get _temFiltro =>
      _grupo != null || _cidade != null || _apenasAVenda;

  void _limparFiltros() => setState(() {
        _grupo = null;
        _cidade = null;
        _apenasAVenda = false;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: COColors.brand900,
      drawer: const CoDrawer(),
      appBar: AppBar(
        title: const Text(
          'O NOSSO PORTFÓLIO',
          style: TextStyle(
            letterSpacing: 1.5,
            fontSize: 13,
            fontWeight: COTokens.fwBold,
            color: COColors.white,
          ),
        ),
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
        child: FutureBuilder<List<dynamic>>(
          future: _portfolioFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _skeleton();
            }

            if (snapshot.hasError) {
              final mensagem = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Erro ao carregar os projetos.';
              return UIHelpers.buildErrorState(
                message: mensagem,
                onRetry: _recarregar,
              );
            }

            final todos =
                (snapshot.data ?? []).whereType<Map>().toList();
            if (todos.isEmpty) {
              return const Center(
                child: Text(
                  'Ainda não há empreendimentos para mostrar.',
                  style: TextStyle(color: COColors.neutral500),
                ),
              );
            }

            final visiveis = Portfolio.ordenarPorComercializacao(
              Portfolio.filtrar(
                todos,
                grupo: _grupo,
                cidade: _cidade,
                apenasAVenda: _apenasAVenda,
              ),
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                COTokens.space6,
                0,
                COTokens.space6,
                COTokens.space12,
              ),
              children: [
                _contadores(todos),
                const SizedBox(height: COTokens.space6),
                _filtros(todos),
                const SizedBox(height: COTokens.space6),

                if (visiveis.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: COTokens.space8,
                    ),
                    child: Text(
                      'Nenhum empreendimento corresponde a estes filtros.',
                      style: COText.small,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  // Com um estado escolhido já não vale a pena repetir o
                  // cabeçalho do grupo — a lista é toda desse grupo.
                  ..._grupo != null
                      ? [for (final p in visiveis) _cartao(p)]
                      : _porGrupos(visiveis),
              ],
            );
          },
        ),
      ),
    );
  }

  /// As três secções, pela ordem do site: a andar, a nascer, feitas.
  List<Widget> _porGrupos(List<Map> visiveis) {
    final widgets = <Widget>[];

    for (final grupo in ['ativo', 'desenvolvimento', 'concluido']) {
      final doGrupo = visiveis
          .where((p) =>
              Portfolio.grupoDeEstado(Portfolio.texto(p, 'status')) == grupo)
          .toList();
      if (doGrupo.isEmpty) continue;

      widgets.add(CoOverline(_nomesDosGrupos[grupo]!));
      widgets.addAll(doGrupo.map(_cartao));
      widgets.add(const SizedBox(height: COTokens.space6));
    }

    return widgets;
  }

  Widget _contadores(List<Map> todos) {
    final ativos = Portfolio.quantosNoGrupo(todos, 'ativo');
    final dev = Portfolio.quantosNoGrupo(todos, 'desenvolvimento');
    final feitos = Portfolio.quantosNoGrupo(todos, 'concluido');
    final fracoes = Portfolio.totalFracoes(todos);

    // A mesma linha do cabeçalho do site, com os zeros fora: "0 concluídos"
    // não diz nada a ninguém.
    final partes = [
      if (ativos > 0) '$ativos em construção',
      if (feitos > 0) '$feitos ${feitos == 1 ? 'concluído' : 'concluídos'}',
      if (dev > 0) '$dev em desenvolvimento',
      if (fracoes > 0) '$fracoes ${fracoes == 1 ? 'fração' : 'frações'}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoOverline('Porto e Vila Nova de Gaia', espacoAbaixo: 4),
        Text('Empreendimentos', style: COText.h1),
        if (partes.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(partes.join('  ·  '), style: COText.small),
        ],
      ],
    );
  }

  Widget _filtros(List<Map> todos) {
    final cidades = Portfolio.cidades(todos);
    final aVenda = todos.where(Portfolio.estaAVenda).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estado, em fileira horizontal: cabem os quatro sem apertar o ecrã.
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chip(
                texto: 'Todos',
                ativo: _grupo == null,
                aoCarregar: () => setState(() => _grupo = null),
              ),
              for (final grupo in ['ativo', 'desenvolvimento', 'concluido'])
                if (Portfolio.quantosNoGrupo(todos, grupo) > 0)
                  _chip(
                    texto:
                        '${_nomesDosGrupos[grupo]} (${Portfolio.quantosNoGrupo(todos, grupo)})',
                    ativo: _grupo == grupo,
                    aoCarregar: () => setState(() => _grupo = grupo),
                  ),
            ],
          ),
        ),
        const SizedBox(height: COTokens.space2),

        Row(
          children: [
            // O filtro de cidade só aparece com mais do que uma: com uma só
            // não filtra nada.
            if (cidades.length > 1)
              Expanded(child: _filtroCidade(cidades))
            else
              const Spacer(),
            if (aVenda > 0) ...[
              const SizedBox(width: COTokens.space2),
              _chip(
                texto: 'Com frações ($aVenda)',
                ativo: _apenasAVenda,
                aoCarregar: () =>
                    setState(() => _apenasAVenda = !_apenasAVenda),
              ),
            ],
          ],
        ),

        if (_temFiltro) ...[
          const SizedBox(height: COTokens.space2),
          InkWell(
            onTap: _limparFiltros,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'limpar filtros',
                style: COText.caption.copyWith(
                  color: COColors.brand300,
                  fontWeight: COTokens.fwMedium,
                  decoration: TextDecoration.underline,
                  decorationColor: COColors.brand300,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _filtroCidade(List<String> cidades) {
    return DropdownButtonFormField<String?>(
      initialValue: _cidade,
      isExpanded: true,
      dropdownColor: COColors.brand700,
      iconEnabledColor: COColors.brand300,
      style: COText.small.copyWith(color: COColors.white),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: COColors.brand700.withValues(alpha: 0.4),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(COTokens.radiusSm),
          borderSide: const BorderSide(color: COColors.brand700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(COTokens.radiusSm),
          borderSide: const BorderSide(color: COColors.brand700),
        ),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text('Todas as cidades', style: COText.small),
        ),
        for (final c in cidades)
          DropdownMenuItem<String?>(
            value: c,
            child: Text(
              c,
              style: COText.small.copyWith(color: COColors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (v) => setState(() => _cidade = v),
    );
  }

  Widget _chip({
    required String texto,
    required bool ativo,
    required VoidCallback aoCarregar,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: COTokens.space2),
      child: GestureDetector(
        onTap: aoCarregar,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: ativo
                ? COColors.brand300
                : COColors.brand700.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(COTokens.radiusSm),
            border: Border.all(
              color: ativo ? COColors.white : COColors.brand700,
              width: COTokens.borderWidth,
            ),
          ),
          child: Center(
            child: Text(
              texto.toUpperCase(),
              style: COText.caption.copyWith(
                color: ativo ? COColors.brand900 : COColors.brand300,
                fontWeight: COTokens.fwBold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cartao(Map project) {
    final id = Portfolio.inteiro(project, 'id') ?? 0;
    final titulo = Portfolio.texto(project, 'name').isEmpty
        ? 'Projeto sem título'
        : Portfolio.texto(project, 'name');
    final cidade = Portfolio.texto(project, 'city');
    final imageUrl = Portfolio.texto(project, 'mainImageUrl');
    final anoFim = Portfolio.anoFim(project);
    final fracoes = Portfolio.inteiro(project, 'nFractions');
    final estado = Portfolio.texto(project, 'status');

    // A tag inclui o id e não o índice da lista: com os filtros a mexer, o
    // índice do mesmo projeto mudava e a animação saltava para outro cartão.
    final heroTag = 'hero-portfolio-$id';

    return CoCard(
      semPadding: true,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectDetailsScreen(
            projectId: id,
            heroTag: heroTag,
            initialImageUrl: imageUrl,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 200,
                child: Hero(
                  tag: heroTag,
                  child: Material(
                    type: MaterialType.transparency,
                    child: imageUrl.isEmpty
                        ? _semImagem(Icons.image_not_supported)
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _semImagem(Icons.broken_image),
                          ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: UIHelpers.buildStatusBadge(estado),
              ),
              if (Portfolio.estaAVenda(project))
                Positioned(
                  top: 12,
                  left: 12,
                  child: _selo('Frações disponíveis'),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(COTokens.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: COText.h2.copyWith(fontWeight: COTokens.fwBold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (cidade.isNotEmpty)
                  CoLinhaInfo(
                    icone: Icons.location_on_outlined,
                    texto: cidade,
                  ),
                if (anoFim != null)
                  CoLinhaInfo(
                    icone: Icons.calendar_today_outlined,
                    texto: 'Conclusão prevista: $anoFim',
                  ),
                if (fracoes != null)
                  CoLinhaInfo(
                    icone: Icons.home_work_outlined,
                    texto: '$fracoes ${fracoes == 1 ? 'fração' : 'frações'}',
                  ),
                // Nos concluídos a barra toda cheia não acrescenta nada.
                BarraProgressoObra(
                  projeto: project,
                  ocultarConcluida: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Etiqueta de comercialização, igual à do site.
  Widget _selo(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: COColors.brand900.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        texto.toUpperCase(),
        style: COText.caption.copyWith(
          color: COColors.white,
          fontSize: 10,
          fontWeight: COTokens.fwBold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _semImagem(IconData icone) {
    return ColoredBox(
      color: COColors.brand700,
      child: Center(
        child: Icon(icone, color: COColors.neutral500, size: 44),
      ),
    );
  }

  Widget _skeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(COTokens.space6),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: COColors.brand700.withValues(alpha: 0.4),
          highlightColor: COColors.brand300.withValues(alpha: 0.1),
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
