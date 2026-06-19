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
                      child: FlutterMap(
                        options: const MapOptions(
                          initialCenter: LatLng(41.13, -8.61),
                          initialZoom: 12.5,
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
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Center(
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset('assets/images/logo_simples_mapa.avif', fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
