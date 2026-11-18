import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/notificacao.dart';
import '../screens/notificacoes_screen.dart';
import '../screens/project_details_screen.dart';
import 'api_service.dart';

/// Notificações push, pelo Firebase Cloud Messaging.
///
/// Do Firebase só se usa a entrega das notificações: os dados e o login
/// continuam a ser da API. O caminho todo:
///
///  1. [iniciar], no arranque: liga o Firebase. Sem google-services.json (que
///     não está no git), na web ou com dados de exemplo, fica desligado e a
///     app funciona como antes — as notificações continuam no sininho.
///  2. [ativarParaSessao], no painel (depois do login ou ao arrancar com
///     sessão): pede autorização e regista o telemóvel na API
///     (POST /notification/device). O token fica ligado à sessão e o
///     /auth/logout apaga-o do lado da API.
///  3. Tocar numa notificação abre o empreendimento, ou a lista quando não
///     é de nenhum, e marca-a como lida. Com a app aberta, aparece um aviso
///     em baixo com "Ver".
///
/// Com a app fechada ou em segundo plano quem mostra a notificação é o
/// próprio Android, a partir do título e do texto que a API manda. O contrato
/// está na secção 7 do API_CONTRACT.md.
class NotificacoesPush {
  NotificacoesPush._();

  static bool _firebaseLigado = false;
  static bool _sessaoAtiva = false;
  static StreamSubscription<String>? _novosTokens;
  static GlobalKey<NavigatorState>? _navegador;
  static GlobalKey<ScaffoldMessengerState>? _avisos;

  static Future<void> iniciar({
    required GlobalKey<NavigatorState> navigatorKey,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) async {
    _navegador = navigatorKey;
    _avisos = messengerKey;
    if (kIsWeb || ApiConfig.useMock) return;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // Sem google-services.json o Firebase não arranca. Não é erro: é uma
      // build sem push.
      debugPrint('Notificações push desligadas: $e');
      return;
    }
    _firebaseLigado = true;
    FirebaseMessaging.onMessageOpenedApp.listen(_abrir);
    FirebaseMessaging.onMessage.listen(_comAppAberta);
  }

  static Future<void> ativarParaSessao() async {
    if (!_firebaseLigado || _sessaoAtiva) return;
    _sessaoAtiva = true;
    try {
      final mensageiro = FirebaseMessaging.instance;
      // No Android 13+ e no iPhone aparece o pedido do sistema. Recusado
      // uma vez, o sistema não volta a perguntar; a pessoa liga-o nas
      // definições do telemóvel.
      final autorizacao = await mensageiro.requestPermission();
      if (autorizacao.authorizationStatus == AuthorizationStatus.denied) return;

      // getToken e onTokenRefresh estão marcados como obsoletos no
      // firebase_messaging 17, a favor do register()/onRegistered. Ficam de
      // propósito: o onRegistered dá o Firebase Installation ID (envio
      // direto, outro tipo de destino), e a API do Miguel envia com o
      // sendEachForMulticast, que quer o token de registo clássico. Mudar
      // um obriga a mudar o outro, ao mesmo tempo.
      // ignore: deprecated_member_use
      final token = await mensageiro.getToken();
      if (token != null) await _registar(token);
      // ignore: deprecated_member_use
      _novosTokens ??= mensageiro.onTokenRefresh.listen(_registar);

      // A app foi aberta a tocar numa notificação, estando fechada.
      final inicial = await mensageiro.getInitialMessage();
      if (inicial != null) _abrir(inicial);
    } catch (e) {
      debugPrint('Não foi possível ativar as notificações push: $e');
    }
  }

  /// Ao sair da conta. A API já apaga o token com o logout; aqui só se deixa
  /// de o registar até alguém voltar a entrar.
  static void terminarSessao() => _sessaoAtiva = false;

  static String get _plataforma =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  static Future<void> _registar(String token) async {
    if (!_sessaoAtiva) return;
    try {
      await ApiService().registarDispositivo(
        token: token,
        plataforma: _plataforma,
      );
    } on ApiException catch (e) {
      // Falhar o registo não pode estragar nada: fica sem push até à próxima
      // vez que o painel abrir.
      debugPrint('Registo do telemóvel para push falhou: ${e.message}');
    }
  }

  static void _abrir(RemoteMessage mensagem) {
    // Sem sessão fica no login: depois de entrar, o sininho tem-na.
    if (ApiService.idLogado == null) return;
    final push = NotificacaoPush.deDados(mensagem.data);

    final id = push.notificationId;
    if (id != null) {
      ApiService().marcarNotificacaoLida(id).catchError((_) {});
    }

    final projeto = push.projectId;
    _navegador?.currentState?.push(
      MaterialPageRoute(
        builder: (_) => projeto != null
            ? ProjectDetailsScreen(
                projectId: projeto,
                heroTag: 'push-$id-$projeto',
                initialImageUrl: '',
              )
            : const NotificacoesScreen(),
      ),
    );
  }

  /// Com a app aberta o Android não mostra a notificação na barra: avisa-se
  /// cá dentro.
  static void _comAppAberta(RemoteMessage mensagem) {
    final titulo = mensagem.notification?.title;
    if (titulo == null || titulo.isEmpty) return;
    _avisos?.currentState?.showSnackBar(
      SnackBar(
        content: Text(titulo),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () => _abrir(mensagem),
        ),
      ),
    );
  }
}
