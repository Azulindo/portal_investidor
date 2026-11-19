part of '../api_service.dart';

// O sininho (listar e marcar como lidas) e o registo do telemÃ³vel para push.
//
// Parte do ApiService, separada em extensÃ£o para o ficheiro principal ficar
// sÃ³ com a sessÃ£o, a cache e os erros. Quem chama nÃ£o muda nada:
// ApiService().metodo() continua a funcionar, porque a extensÃ£o vem com o
// import de api_service.dart. Membros estÃ¡ticos do ApiService aqui dentro
// tÃªm de levar o prefixo (ApiService.idLogado), Ã© uma regra das extensÃµes.
extension ApiNotificacoes on ApiService {
  // ============================================================
  // NOTIFICACOES
  // ============================================================

  /// GET /api/notification
  ///
  /// Devolve as visiveis para quem esta ligado, da mais recente para a mais
  /// antiga, no maximo 30, mais a contagem de nao lidas.
  ///
  /// Nao passa pela cache de 3 minutos das outras chamadas: o sininho existe
  /// para avisar que ha coisas novas, e um aviso com tres minutos de atraso
  /// perde metade da graca. E uma chamada pequena.
  Future<NotificacoesResposta> buscarNotificacoes() async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return DadosDeExemplo.notificacoes();
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.notificationsEndpoint}',
    );
    try {
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed['data'];
        if (data is Map) {
          return NotificacoesResposta.fromJson(data.cast<String, dynamic>());
        }
        return const NotificacoesResposta();
      }
      _falhou(response);
    } on TimeoutException catch (_) {
      throw ApiException('O servidor demorou muito tempo a responder.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Erro de ligação à rede.');
    }
  }

  /// GET /api/notification/announcements
  ///
  /// Os anúncios em destaque: por ler e dentro do prazo. São um destaque, não
  /// informação que falte noutro sítio (estão também no sininho), por isso
  /// uma falha dá uma lista vazia em vez de um erro no painel.
  Future<List<Notificacao>> buscarAnuncios() async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return DadosDeExemplo.anuncios();
    }
    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.announcementsEndpoint}'),
            headers: await _authHeaders(),
          )
          .timeout(ApiConfig.connectionTimeout);
      if (response.statusCode != 200) return const [];
      final data = jsonDecode(response.body)['data'];
      final lista = data is Map ? data['announcements'] : null;
      if (lista is! List) return const [];
      return lista
          .whereType<Map>()
          .map((e) => Notificacao.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// PUT /api/notification/:id/read
  ///
  /// Idempotente: marcar duas vezes e o mesmo que marcar uma, por isso a app
  /// pode repetir o pedido sem estragar nada.
  ///
  /// Uma notificacao que nao existe e uma que existe mas nao e para esta
  /// pessoa devolvem as duas 404 — de proposito, para nao se descobrir que
  /// notificacoes existem a tentar ids a sorte.
  Future<void> marcarNotificacaoLida(int id) async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return;
    }
    await _marcarLidas(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.markNotificationReadEndpoint(id)}',
      ),
    );
  }

  /// PUT /api/notification/read-all
  Future<void> marcarTodasAsNotificacoesLidas() async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return;
    }
    await _marcarLidas(
      Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.markAllNotificationsReadEndpoint}',
      ),
    );
  }

  /// POST /api/notification/device
  ///
  /// Regista este telemovel para receber notificacoes push. Chama-se depois
  /// do login e sempre que o Firebase der um token novo. O token fica ligado
  /// a sessao: o /auth/logout apaga-o sozinho.
  ///
  /// [plataforma] e 'android' ou 'ios'.
  Future<void> registarDispositivo({
    required String token,
    required String plataforma,
  }) async {
    if (ApiConfig.useMock) return;
    await _pedidoDispositivo(
      'POST',
      jsonEncode({'token': token, 'platform': plataforma}),
    );
  }

  /// DELETE /api/notification/device
  ///
  /// Deixa de receber push neste telemovel. Nao e preciso antes do logout
  /// (a API ja o faz); serve para um "desativar notificacoes".
  Future<void> removerDispositivo(String token) async {
    if (ApiConfig.useMock) return;
    await _pedidoDispositivo('DELETE', jsonEncode({'token': token}));
  }

  Future<void> _pedidoDispositivo(String metodo, String corpo) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.notificationDeviceEndpoint}',
    );
    try {
      final pedido = http.Request(metodo, url)
        ..headers.addAll(await _authHeaders())
        ..headers['Content-Type'] = 'application/json'
        ..body = corpo;
      final response = await http.Response.fromStream(
        await pedido.send().timeout(ApiConfig.connectionTimeout),
      );
      if (response.statusCode == 200 || response.statusCode == 204) return;
      _falhou(response);
    } on TimeoutException catch (_) {
      throw ApiException('O servidor demorou muito tempo a responder.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Erro de ligação à rede.');
    }
  }

  Future<void> _marcarLidas(Uri url) async {
    try {
      final response = await http
          .put(url, headers: await _authHeaders())
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200 || response.statusCode == 204) return;
      _falhou(response);
    } on TimeoutException catch (_) {
      throw ApiException('O servidor demorou muito tempo a responder.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Erro de ligação à rede.');
    }
  }

}
