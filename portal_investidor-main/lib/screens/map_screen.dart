import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../widgets/co_drawer.dart';
import 'project_details_screen.dart';

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

  Color _corPorStatus(String? status) {
    switch (status) {
      case 'Concluído':
        return const Color(0xFF43A047); // bright green
      case 'Construção':
        return const Color(0xFF42A5F5); // light blue
      case 'Desenvolvimento':
        return const Color(0xFF9E9E9E); // neutral grey
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    for (final project in _projects) {
      final lat = (project['latitude'] as num?)?.toDouble();
      final lng = (project['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
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
              final forSale   = project['forSale'] as bool? ?? false;
              final mainImage = project['mainImageUrl'] as String?;

              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (sheetContext) => Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  decoration: BoxDecoration(
                    color: COColors.brand700,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: COColors.brand500, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image or colour header
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                        child: mainImage != null && mainImage.isNotEmpty
                            ? Image.network(
                                mainImage,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _noImageHeader(color),
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
                                style: const TextStyle(color: COColors.neutral500, fontSize: 13),
                              ),
                            ],
                            const SizedBox(height: 14),

                            // Info row
                            Row(
                              children: [
                                _infoChip(color, status ?? 'Desconhecido'),
                                const SizedBox(width: 8),
                                if (forSale) ...[
                                  const SizedBox(width: 8),
                                  _infoChip(const Color(0xFF5BBFBF), 'Frações à venda'),
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
                                      foregroundColor: COColors.neutral500,
                                      side: const BorderSide(color: COColors.neutral500),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onPressed: () => Navigator.pop(sheetContext),
                                    child: const Text('Voltar'),
                                  ),
                                ),
                                if (projectId != null) ...[
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
                                              initialImageUrl: mainImage ?? '',
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text('Ver Detalhes',
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
      if (lat == null || lng == null) continue;

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
        title: const Text(
          'MAPA DE PROJETOS',
          style: TextStyle(fontSize: 13, fontWeight: COTokens.fwBold, letterSpacing: 1.5),
        ),
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
                              onMapReady: () => setState(() => _mapReady = true),
                              // Recalcula os indicadores de borda sempre que o mapa
                              // se move, faz zoom ou roda.
                              onPositionChanged: (_, _) => setState(() {}),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c', 'd'],
                                userAgentPackageName: 'com.cleveroption.portalinvestidor',
                              ),
                              MarkerLayer(markers: _buildMarkers()),
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

  Widget _infoChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: COTokens.fwBold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildLegenda() {
    return Container(
      color: COColors.brand900,
      padding: const EdgeInsets.symmetric(horizontal: COTokens.space4, vertical: COTokens.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Flexible(child: _legendaItem(const Color(0xFF9E9E9E), 'Em Desenvolvimento')),
          Flexible(child: _legendaItem(const Color(0xFF42A5F5), 'Em Construção')),
          Flexible(child: _legendaItem(const Color(0xFF43A047), 'Concluído')),
        ],
      ),
    );
  }

  Widget _legendaItem(Color cor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
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
              child: Image.asset('assets/images/logo_simples_mapa.avif', fit: BoxFit.contain),
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
