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
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: COColors.brand700,
                  title: Text(nome, style: const TextStyle(color: COColors.white, fontSize: 14, fontWeight: COTokens.fwBold)),
                  content: Text(
                    'Estado: ${status ?? 'Desconhecido'}',
                    style: const TextStyle(color: COColors.brand300, fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fechar', style: TextStyle(color: COColors.brand300)),
                    ),
                    if (projectId != null)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProjectDetailsScreen(
                                projectId: projectId,
                                heroTag: 'map_project_$projectId',
                                initialImageUrl: '',
                              ),
                            ),
                          );
                        },
                        child: const Text('Ver Detalhes', style: TextStyle(color: COColors.white, fontWeight: COTokens.fwBold)),
                      ),
                  ],
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

  Widget _buildLegenda() {
    return Container(
      color: COColors.brand900,
      padding: const EdgeInsets.symmetric(horizontal: COTokens.space4, vertical: COTokens.space2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendaItem(const Color(0xFF9E9E9E), 'Em Desenvolvimento'),
          const SizedBox(width: COTokens.space4),
          _legendaItem(const Color(0xFF42A5F5), 'Em Construção'),
          const SizedBox(width: COTokens.space4),
          _legendaItem(const Color(0xFF43A047), 'Concluído'),
        ],
      ),
    );
  }

  Widget _legendaItem(Color cor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: COColors.white, fontSize: 12)),
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
