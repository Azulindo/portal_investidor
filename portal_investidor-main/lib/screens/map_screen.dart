import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/mapa.dart';
import '../utils/portfolio.dart';
import '../utils/ui_helpers.dart';
import '../widgets/co_drawer.dart';
import 'project_details_screen.dart';
import '../widgets/co_imagem.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _api = ApiService();
  final MapController _mapController = MapController();
  bool _mapReady = false;
  List<dynamic> _projects = [];
  bool _loading = true;
  String? _error;
  // A legenda serve de filtro: só aparecem os pinos dos grupos ligados.
  Set<String> _gruposLigados = Portfolio.grupos.toSet();

  bool _passaNoFiltro(dynamic project) => _gruposLigados
      .contains(Portfolio.grupoDeEstado(project['status'] as String?));

  @override
  void initState() {
    super.initState();
    _carregarProjetos();
  }

  Future<void> _carregarProjetos() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.buscarPortfolio();
      setState(() { _projects = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  /// A cor do pino.
  ///
  /// Comparava o estado por igualdade — case 'Construção', case
  /// 'Desenvolvimento' — mas a API escreve "Em construção" e "Em
  /// desenvolvimento". Nenhum dos dois casos batia certo, por isso saíam
  /// todos cinzentos menos os concluídos. É o mesmo erro que já tinha
  /// aparecido nos filtros do portfólio e na etiqueta dos cartões; agora
  /// os três usam a mesma função.
  Color _corPorStatus(String? status) =>
      UIHelpers.corDoGrupo(status, fundoClaro: true);

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    for (final project in _projects) {
      final lat = (project['latitude'] as num?)?.toDouble();
      final lng = (project['longitude'] as num?)?.toDouble();
      // A API manda 0/0 quando o projeto não tem morada marcada. Sem este
      // salto, esses projetos apareciam ao largo de África.
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      if (!_passaNoFiltro(project)) continue;
      final status = project['status'] as String?;
      final color = _corPorStatus(status);
      final nome = project['name'] as String? ?? 'Projeto';
      final projectId = (project['id'] as num?)?.toInt();
      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 48,
          height: 48,
          // Mantém o pin sempre alinhado com o ecrã (não roda com o mapa).
          rotate: true,
          child: GestureDetector(
            onTap: () {
              final city      = project['city']    as String?;
              // A venda como o site mostra: so quem tem pagina propria.
              final forSale   = Portfolio.estaAVenda(project);
              final temPagina = Portfolio.temPagina(project);
              final mainImage = Portfolio.imagem(project);

              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (sheetContext) => Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  decoration: BoxDecoration(
                    color: COColors.brand700,
                    borderRadius: BorderRadius.circular(COTokens.radiusSm),
                    border: Border.all(
                      color: COColors.brand500,
                      width: COTokens.borderWidth,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image or colour header
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(COTokens.radiusSm),
                        ),
                        child: mainImage.isNotEmpty
                            ? CoImagem(
                                mainImage,
                                altura: 160,
                                largura: double.infinity,
                                erro: _noImageHeader(color),
                              )
                            : _noImageHeader(color),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(COTokens.space6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            Text(
                              nome,
                              style: const TextStyle(
                                color: COColors.white,
                                fontSize: 17,
                                fontWeight: COTokens.fwBold,
                              ),
                            ),
                            if (city != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                city,
                                // brand300 e nao neutral500: a folha e navy, e
                                // o neutral500 so chega a 3,4:1 sobre ela.
                                style: const TextStyle(color: COColors.brand300, fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 14),

                            // Info row
                            Row(
                              children: [
                                _infoChip(status, status ?? 'Desconhecido'),
                                if (forSale) ...[
                                  const SizedBox(width: 8),
                                  // "Concluído" é o que dá o teal da marca, e
                                  // este chip quer essa cor: é o único sobre o
                                  // qual há alguma coisa a fazer.
                                  _infoChip('Concluído', 'Frações à venda'),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Actions
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      // Era neutral500, que sobre o navy da
                                      // folha dava 3,4:1 — abaixo do minimo.
                                      foregroundColor: COColors.brand300,
                                      side: const BorderSide(color: COColors.brand300),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () => Navigator.pop(sheetContext),
                                    child: const Text('Voltar'),
                                  ),
                                ),
                                // Sem pagina nao se oferece o botao: a API
                                // responde 404 aos detalhes desses.
                                if (projectId != null && temPagina) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: COColors.brand900,
                                        foregroundColor: COColors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          side: const BorderSide(color: COColors.brand500),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(sheetContext);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProjectDetailsScreen(
                                              projectId: projectId,
                                              heroTag: 'map_project_$projectId',
                                              initialImageUrl: mainImage,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('Ver detalhes',
                                          style: TextStyle(fontWeight: COTokens.fwBold)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: _LogoPin(color: color),
          ),
        ),
      );
    }
    return markers;
  }

  /// Para cada projeto fora da área visível do mapa, desenha uma seta encostada
  /// à borda mais próxima, a apontar na direção do projeto. Tocar na seta
  /// centra o mapa nesse projeto.
  Widget _buildOffScreenIndicators() {
    if (!_mapReady) return const SizedBox.shrink();

    final camera = _mapController.camera;
    final size = camera.nonRotatedSize;
    if (size.width <= 0 || size.height <= 0) return const SizedBox.shrink();

    const margin = 26.0; // recuo da seta em relação à borda
    const indicatorSize = 36.0;
    final center = Offset(size.width / 2, size.height / 2);
    final indicadores = <Widget>[];

    for (final project in _projects) {
      final lat = (project['latitude'] as num?)?.toDouble();
      final lng = (project['longitude'] as num?)?.toDouble();
      // Mesmo critério dos marcadores: 0/0 é "sem morada", não é o Atlântico.
      if (lat == null || lng == null || (lat == 0 && lng == 0)) continue;
      // Uma seta para um pino escondido pelo filtro levava a um sítio vazio.
      if (!_passaNoFiltro(project)) continue;

      final ponto = LatLng(lat, lng);
      final pos = camera.latLngToScreenOffset(ponto);

      final visivel = pos.dx >= 0 && pos.dx <= size.width && pos.dy >= 0 && pos.dy <= size.height;
      if (visivel) continue;

      final dir = pos - center;
      if (dir.distance == 0) continue;

      // Interseção da semirreta (centro -> marcador) com o retângulo recuado.
      final halfW = size.width / 2 - margin;
      final halfH = size.height / 2 - margin;
      final scale = math.min(
        dir.dx == 0 ? double.infinity : halfW / dir.dx.abs(),
        dir.dy == 0 ? double.infinity : halfH / dir.dy.abs(),
      );
      final edge = center + dir * scale;
      final angle = math.atan2(dir.dy, dir.dx);
      final color = _corPorStatus(project['status'] as String?);

      indicadores.add(
        Positioned(
          left: edge.dx - indicatorSize / 2,
          top: edge.dy - indicatorSize / 2,
          child: GestureDetector(
            onTap: () => _mapController.move(ponto, camera.zoom),
            child: _EdgeIndicator(color: color, angle: angle, size: indicatorSize),
          ),
        ),
      );
    }

    return Stack(children: indicadores);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: COColors.brand900,
      appBar: AppBar(
        backgroundColor: COColors.brand900,
        foregroundColor: COColors.white,
        title: const Text('Mapa de projetos', style: COText.tituloEcra),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarProjetos,
          ),
        ],
      ),
      drawer: const CoDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: COColors.white))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, color: COColors.brand300, size: 48),
                      const SizedBox(height: COTokens.space4),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: COColors.brand300, fontSize: 13)),
                      const SizedBox(height: COTokens.space4),
                      TextButton(
                        onPressed: _carregarProjetos,
                        child: const Text('Tentar novamente', style: TextStyle(color: COColors.white)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildLegenda(),
                    Expanded(
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: const LatLng(41.13, -8.61),
                              initialZoom: 12.5,
                              minZoom: Mapa.zoomMinimo,
                              maxZoom: Mapa.zoomMaximo,
                              onMapReady: () => setState(() => _mapReady = true),
                              // Recalcula os indicadores de borda sempre que o mapa
                              // se move, faz zoom ou roda.
                              onPositionChanged: (_, _) => setState(() {}),
                            ),
                            children: [
                              Mapa.telas(context),
                              MarkerLayer(markers: _buildMarkers()),
                              Mapa.atribuicao(),
                            ],
                          ),
                          // Setas que apontam para projetos fora da área visível.
                          Positioned.fill(child: _buildOffScreenIndicators()),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _noImageHeader(Color color) {
    return Container(
      height: 160,
      width: double.infinity,
      color: color.withValues(alpha: 0.15),
      child: Icon(Icons.location_city_rounded, color: color, size: 48),
    );
  }

  /// Etiqueta de estado dentro da folha de informação.
  ///
  /// A cor vem da paleta de fundo ESCURO, e não da do mapa: a folha é navy, e
  /// as cores do mapa são escolhidas para se verem sobre as telas claras — o
  /// "Desenvolvimento" ficava navy sobre navy e não se lia.
  ///
  /// E mesmo com a paleta certa, o texto é branco: a 11px, o cinzento do
  /// estado em desenvolvimento ficava em 3,4:1 sobre a folha, abaixo do
  /// mínimo. A cor do estado continua a identificar-se, pelo fundo e pela
  /// borda.
  Widget _infoChip(String? status, String label) {
    final cor = UIHelpers.corDoGrupo(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: COColors.white,
          fontSize: 11,
          fontWeight: COTokens.fwBold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  /// A legenda das cores, que é também o filtro do mapa: tocar num estado
  /// mostra ou esconde os pinos desse estado.
  Widget _buildLegenda() {
    // Material e não Container com cor: com a cor num Container por cima, o
    // efeito do toque desenhava-se por baixo e não se via.
    return Material(
      color: COColors.brand900,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: COTokens.space2, vertical: 4),
        child: Row(
          children: [
            // Sem o "Em": "Em desenvolvimento" não cabia num terço do ecrã e
            // ficava cortado. São as palavras que a etiqueta dos cartões usa.
            for (final (grupo, estado) in const [
              ('desenvolvimento', 'Desenvolvimento'),
              ('ativo', 'Construção'),
              ('concluido', 'Concluído'),
            ])
              // Largura proporcional ao texto: em terços iguais, a moldura
              // de botão comia o espaço e "Desenvolvimento" ficava cortado.
              Expanded(
                flex: estado.length + 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _legendaItem(
                    grupo,
                    UIHelpers.corDoGrupo(estado, fundoClaro: true),
                    estado,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendaItem(String grupo, Color cor, String label) {
    final ligado = _gruposLigados.contains(grupo);
    return Semantics(
      button: true,
      toggled: ligado,
      label: '$label no mapa',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('filtro-$grupo'),
        borderRadius: BorderRadius.circular(COTokens.radiusSm),
        onTap: () => setState(() {
          _gruposLigados = Portfolio.alternarGrupo(_gruposLigados, grupo);
        }),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          // Desligado fica esbatido, mas ainda legível: continua a ser um
          // botão que se pode voltar a tocar.
          opacity: ligado ? 1 : 0.6,
          child: Container(
            // 44px de altura: o mínimo para se acertar com o dedo.
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(COTokens.radiusSm),
              border: Border.all(
                color: ligado ? COColors.brand300 : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  // A bolinha tem a cor exata do pino, e a dos projetos em
                  // construção é o navy da barra: sem a borda ficava
                  // invisível. Não muda quando se desliga (a de construção
                  // já parece vazia); o estado vê-se pela moldura e pelo
                  // esbatido.
                  decoration: BoxDecoration(
                    color: cor,
                    shape: BoxShape.circle,
                    border: Border.all(color: COColors.brand300, width: 1.5),
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(color: COColors.white, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoPin extends StatelessWidget {
  final Color color;
  const _LogoPin({required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              // Branco, para se ler nas três cores de estado. É um PNG gerado
              // do logótipo em vetor (loja/gerar.ps1): o .avif que estava
              // aqui não aparecia no browser e os pinos ficavam vazios.
              child: Image.asset(
                'assets/images/simbolo_mapa.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Seta circular encostada à borda do mapa, a apontar para um projeto que está
/// fora da área visível. [angle] está em radianos (0 = a apontar para a direita).
class _EdgeIndicator extends StatelessWidget {
  final Color color;
  final double angle;
  final double size;
  const _EdgeIndicator({required this.color, required this.angle, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Center(
        // Icons.play_arrow aponta para a direita (0 rad), por isso basta rodar
        // pelo ângulo da direção centro -> marcador.
        child: Transform.rotate(
          angle: angle,
          child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
