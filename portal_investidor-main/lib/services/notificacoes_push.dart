import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/api_config.dart';
import '../models/notificacao.dart';
import '../screens/notificacoes_screen.dart';
import '../utils/destino_notificacao.dart';
import 'api_service.dart';

/// Notificações push, pelo Firebase Cloud Messaging.
///
/// Do Firebase só se usa a entrega das notificações: os dados e o login
/// continuam a ser da API. O caminho todo:
///
///  1. [iniciar], no arranque: liga o Firebase e cria o canal "avisos". Sem
///     google-services.json (que não está no git), na web ou com dados de
///     exemplo, fica desligado e a app funciona como antes — as notificações
///     continuam no sininho.
///  2. [ativarParaSessao], no painel (depois do login ou ao arrancar com
///     sessão): pede autorização e regista o telemóvel na API
///     (POST /notification/device). O token fica ligado à sessão e o
///     /auth/logout apaga-o do lado da API.
///  3. Tocar numa notificação leva ao mesmo sítio que tocar nela no sininho
///     (lib/utils/destino_notificacao.dart) e marca-a como lida.
///
/// Com a app fechada ou em segundo plano, quem mostra a notificação é o
/// Android, no canal "avisos" (ver o AndroidManifest). Com a app aberta o
/// Android não mostra nada sozinho, por isso mostra-se aqui uma notificação
/// local igual. O contrato está na secção 7 do API_CONTRACT.md.
class NotificacoesPush {
  NotificacoesPush._();

  /// Importância alta: toca o som e aparece o cartão no topo do ecrã. O canal
  /// por omissão do Firebase ("Diversos") chegava calado e sem cartão.
  ///
  /// Um canal, depois de criado, já não muda de importância no telemóvel de
  /// quem o tem — quem quiser outro comportamento tem de usar outro id.
  static const _canal = AndroidNotificationChannel(
    'avisos',
    'Avisos da Cleveroption',
    description: 'Novidades da obra, documentos e empreendimentos.',
    importance: Importance.high,
  );

  static final _locais = FlutterLocalNotificationsPlugin();
  static bool _firebaseLigado = false;
  static bool _sessaoAtiva = false;
  static StreamSubscription<String>? _novosTokens;
  static GlobalKey<NavigatorState>? _navegador;

  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> iniciar({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    _navegador = navigatorKey;
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

    try {
      await _locais.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notificacao'),
          // A autorização pede-se no painel, pelo Firebase, e não ao abrir.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (resposta) {
          final dados = resposta.payload;
          if (dados == null) return;
          _abrir((jsonDecode(dados) as Map).cast<String, dynamic>());
        },
      );
      await _locais
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_canal);
    } catch (e) {
      debugPrint('Notificações locais indisponíveis: $e');
    }

    // No iPhone o sistema sabe mostrar a notificação com a app aberta, se
    // lhe disserem; no Android faz-se à mão em [_comAppAberta].
    if (_ios) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    FirebaseMessaging.onMessageOpenedApp.listen((m) => _abrir(m.data));
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
      if (inicial != null) _abrir(inicial.data);
    } catch (e) {
      debugPrint('Não foi possível ativar as notificações push: $e');
    }
  }

  /// Ao sair da conta. A API já apaga o token com o logout; aqui só se deixa
  /// de o registar até alguém voltar a entrar.
  static void terminarSessao() => _sessaoAtiva = false;

  static Future<void> _registar(String token) async {
    if (!_sessaoAtiva) return;
    try {
      await ApiService().registarDispositivo(
        token: token,
        plataforma: _ios ? 'ios' : 'android',
      );
    } on ApiException catch (e) {
      // Falhar o registo não pode estragar nada: fica sem push até à próxima
      // vez que o painel abrir.
      debugPrint('Registo do telemóvel para push falhou: ${e.message}');
    }
  }

  static Future<void> _abrir(Map<String, dynamic> dados) async {
    // Sem sessão fica no login: depois de entrar, o sininho tem-na.
    if (ApiService.idLogado == null) return;
    final push = NotificacaoPush.deDados(dados);

    final id = push.notificationId;
    if (id != null) {
      ApiService().marcarNotificacaoLida(id).catchError((_) {});
    }

    // O data do push não traz o href, e as notificações para uma pessoa ou
    // para todos só dizem de que empreendimento são no href. Sem projectId,
    // vai-se buscar a notificação ao GET /notification, que o tem.
    String? href;
    if (push.projectId == null && id != null) {
      try {
        final lista = await ApiService().buscarNotificacoes();
        for (final n in lista.notificacoes) {
          if (n.id == id) href = n.href;
        }
      } catch (_) {
        // Sem rede abre-se a lista; não se perde nada.
      }
    }

    // O mesmo destino que no sininho; sem destino próprio, abre a lista,
    // para a pessoa ver de que era.
    final destino = destinoDaNotificacao(
          tipo: push.tipo,
          projectId: push.projectId,
          notificationId: id,
          href: href,
        ) ??
        const NotificacoesScreen();
    _navegador?.currentState?.push(MaterialPageRoute(builder: (_) => destino));
  }

  /// Com a app aberta o Android não mostra a notificação: mostra-se aqui uma
  /// local, no mesmo canal, com som e cartão.
  static Future<void> _comAppAberta(RemoteMessage mensagem) async {
    if (_ios) return; // tratado pelas presentation options
    final n = mensagem.notification;
    if (n == null) return;
    final id =
        int.tryParse(mensagem.data['notificationId']?.toString() ?? '') ??
            mensagem.hashCode;
    try {
      await _locais.show(
        id: id,
        title: n.title,
        body: n.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _canal.id,
            _canal.name,
            channelDescription: _canal.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notificacao',
            color: const Color(0xFF002847),
          ),
        ),
        payload: jsonEncode(mensagem.data),
      );
    } catch (e) {
      debugPrint('Não foi possível mostrar a notificação: $e');
    }
  }
}
