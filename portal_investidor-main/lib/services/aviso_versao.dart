import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../config/empresa.dart';
import '../config/versao_app.dart';
import '../utils/versao.dart';

/// Avisa quando há uma versão nova da app no site.
///
/// Só para Android instalado a partir do site (/app): esse APK não se
/// atualiza sozinho. Pergunta ao site (GET /api/app-versao) uma vez por
/// arranque; o site só responde com versão enquanto o Android for o APK — com
/// a Play Store configurada vem sem versão e aqui não se mostra nada.
///
/// Tudo o que falhar (sem rede, site em baixo, resposta estranha) fica em
/// silêncio: é um aviso, não pode estorvar quem abre a app.
class AvisoVersao {
  AvisoVersao._();

  static bool _jaVerificado = false;

  static Future<void> verificar(BuildContext context) async {
    if (_jaVerificado) return;
    _jaVerificado = true;
    if (kIsWeb || ApiConfig.useMock) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final publicada = await _versaoPublicada();
    if (publicada == null || !Versao.maisRecente(publicada, versaoApp)) return;
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Há uma versão nova da app ($publicada).'),
        duration: const Duration(seconds: 12),
        action: SnackBarAction(
          label: 'Atualizar',
          onPressed: () => launchUrl(
            Uri.parse('${Empresa.site}/app'),
            mode: LaunchMode.externalApplication,
          ),
        ),
      ),
    );
  }

  static Future<String?> _versaoPublicada() async {
    try {
      final resposta = await http
          .get(Uri.parse('${Empresa.site}/api/app-versao'))
          .timeout(const Duration(seconds: 6));
      if (resposta.statusCode != 200) return null;
      final json = jsonDecode(resposta.body);
      final android = json is Map ? json['android'] : null;
      final versao = android is Map ? android['versao'] : null;
      return versao is String ? versao : null;
    } catch (_) {
      return null;
    }
  }
}
