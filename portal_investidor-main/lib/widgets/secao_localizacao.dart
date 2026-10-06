import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_model.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import 'co_card.dart';

/// "Onde fica" — o mapa deste empreendimento, com um marcador só.
///
/// Equivalente ao EmpreendimentoMap do site. As mesmas tiles e o mesmo
/// userAgent do ecrã do mapa, para a app não andar a buscar dois mapas
/// diferentes.
///
/// Não aparece sem coordenadas: a API manda 0/0 quando o projeto ainda não
/// tem morada marcada, e sem este cuidado o mapa abria ao largo de África. É
/// a mesma verificação que o site faz, e a mesma que o ecrã do mapa já fazia
/// para os marcadores.
class SecaoLocalizacao extends StatelessWidget {
  const SecaoLocalizacao({super.key, required this.info});

  final ProjectInfo info;

  /// null quando não há onde pôr o marcador.
  LatLng? get _ponto {
    final lat = info.latitude;
    final lng = info.longitude;
    if (lat == null || lng == null) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    if (lat == 0 && lng == 0) return null;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final ponto = _ponto;
    if (ponto == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoOverline('Localização'),
        Text('Onde fica', style: COText.h2),
        const SizedBox(height: COTokens.space4),

        CoCard(
          semPadding: true,
          margin: EdgeInsets.zero,
          child: SizedBox(
            height: 240,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: ponto,
                initialZoom: 15,
                // Sem rotação: o mapa está dentro de uma página que se rola,
                // e um gesto de rodar aqui era sempre por acidente.
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.cleveroption.portalinvestidor',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: ponto,
                      width: 34,
                      height: 34,
                      child: const _Marcador(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: COTokens.space2),
        _linhaMorada(context, ponto),
      ],
    );
  }

  Widget _linhaMorada(BuildContext context, LatLng ponto) {
    final morada = [info.address, info.city]
        .where((s) => s.trim().isNotEmpty)
        .join(', ');

    return InkWell(
      onTap: () => _abrirNoMapa(context, ponto, morada),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            const Icon(
              Icons.directions_outlined,
              size: 14,
              color: COColors.brand300,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                morada.isEmpty ? 'Abrir direções' : morada,
                style: COText.small.copyWith(
                  color: COColors.brand300,
                  fontWeight: COTokens.fwMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Abre a app de mapas do telefone nas coordenadas.
  ///
  /// Manda as coordenadas e não a morada em texto: a morada pode estar
  /// escrita de maneira que o motor de busca do mapa não encontre, e as
  /// coordenadas são as que o backoffice marcou.
  Future<void> _abrirNoMapa(
    BuildContext context,
    LatLng ponto,
    String morada,
  ) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${ponto.latitude},${ponto.longitude}',
    );

    bool ok;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o mapa.'),
          backgroundColor: COColors.brand700,
        ),
      );
    }
  }
}

/// Pino do empreendimento. Navy com anel branco, para se ver tanto sobre as
/// ruas claras como sobre os parques do mapa.
class _Marcador extends StatelessWidget {
  const _Marcador();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: COColors.brand900,
          shape: BoxShape.circle,
          border: Border.all(color: COColors.white, width: 3),
        ),
      ),
    );
  }
}
