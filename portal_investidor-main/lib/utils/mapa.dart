import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';

/// As telas do mapa e a atribuicao, num sitio so.
///
/// Havia dois mapas na app — o ecra do mapa e o "Onde fica" do detalhe — cada
/// um com o seu URL escrito a mao. Quando o CARTO passou a exigir chave, os
/// dois partiram-se ao mesmo tempo e era preciso corrigir nos dois sitios.
class Mapa {
  /// A chave do CARTO, passada no build:
  /// `--dart-define=CARTO_KEY=...`
  ///
  /// E a mesma do site, que a tem em NEXT_PUBLIC_CARTO_KEY. Nao fica escrita
  /// no codigo de proposito: este repositorio e publico, e ja la esta uma
  /// chave do Google Maps a mais.
  ///
  /// Numa app a chave acaba sempre por ir dentro do pacote e quem quiser
  /// consegue le-la — como no site, quem a protege e a restricao no painel do
  /// CARTO, nao o sitio onde esta guardada. O que o dart-define evita e que
  /// ela fique no histórico do git, que e outra coisa.
  static const String _chave = String.fromEnvironment('CARTO_KEY');

  static bool get temChave => _chave.isNotEmpty;

  /// O voyager do CARTO, que e o mesmo estilo que o site usa.
  ///
  /// O {r} vira "@2x" nos ecras de alta densidade, que sao todos os
  /// telemoveis. Sem ele as telas chegam na resolucao de um ecra antigo e o
  /// mapa fica com um ar esborratado ao lado do resto.
  static const String _urlCarto =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png?key=$_chave';

  /// Sem chave, o CARTO devolve as telas com "API KEY REQUIRED" escrito por
  /// cima — foi o que aconteceu em outubro de 2026 e o que partiu os dois
  /// mapas da app. O OpenStreetMap nao precisa de chave nenhuma, por isso uma
  /// compilacao sem a CARTO_KEY fica com um mapa mais simples em vez de um
  /// mapa carimbado.
  static const String _urlOsm = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static TileLayer telas(BuildContext context) {
    return TileLayer(
      urlTemplate: temChave ? _urlCarto : _urlOsm,
      // O OpenStreetMap ja nao usa subdominios; o CARTO usa.
      subdomains: temChave ? const ['a', 'b', 'c', 'd'] : const [],
      retinaMode: temChave && RetinaMode.isHighDensity(context),
      maxZoom: 19,
      userAgentPackageName: 'com.cleveroption.portalinvestidor',
    );
  }

  /// A atribuicao nao e enfeite: as duas licencas obrigam a ela, e a app nao
  /// a tinha em nenhum dos mapas. O site tem-na nos quatro estilos.
  ///
  /// Fica recolhida atras de um "i" no canto, que e o que a propria biblioteca
  /// faz, para nao comer um mapa de 240px dentro de um cartao.
  static Widget atribuicao() {
    return RichAttributionWidget(
      alignment: AttributionAlignment.bottomRight,
      popupBackgroundColor: COColors.brand700,
      popupBorderRadius: BorderRadius.circular(COTokens.radiusSm),
      attributions: [
        const TextSourceAttribution('OpenStreetMap'),
        if (temChave) const TextSourceAttribution('CARTO'),
      ],
    );
  }
}
