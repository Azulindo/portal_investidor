part of '../api_service.dart';

// Encomendas, faturas e o download de anexos.
//
// Parte do ApiService, separada em extensÃ£o para o ficheiro principal ficar
// sÃ³ com a sessÃ£o, a cache e os erros. Quem chama nÃ£o muda nada:
// ApiService().metodo() continua a funcionar, porque a extensÃ£o vem com o
// import de api_service.dart. Membros estÃ¡ticos do ApiService aqui dentro
// tÃªm de levar o prefixo (ApiService.idLogado), Ã© uma regra das extensÃµes.
extension ApiDocumentos on ApiService {
  // ============================================================
  // DOCUMENTOS
  // ============================================================

  /// GET /api/document/list
  /// As encomendas do cliente, cada uma com as suas faturas.
  ///
  /// É daqui que saem os totais do painel (investido, pago, por pagar) — ver
  /// utils/carteira.dart. O endpoint já estava declarado no ApiConfig mas não
  /// havia nada a chamá-lo.
  Future<List<SaleOrder>> buscarOrdensDeCompra() =>
      _comCache('encomendas', _buscarOrdensDeCompra);

  Future<List<SaleOrder>> _buscarOrdensDeCompra() async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return DadosDeExemplo.encomendas();
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.saleOrdersEndpoint}',
    );
    try {
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed['data'];
        if (data is List) {
          return data
              .whereType<Map>()
              .map((e) => SaleOrder.fromJson(e.cast<String, dynamic>()))
              .toList();
        }
        return [];
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

  /// Devolve a lista de documentos (faturas) com anexos do utilizador autenticado.

  Future<List<Map<String, dynamic>>> buscarDocumentos() async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return DadosDeExemplo.documentos();
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.documentListEndpoint}',
    );
    try {
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final parsed = jsonDecode(response.body);
        final data = parsed['data'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        _falhou(response);
      }
    } on TimeoutException catch (_) {
      throw ApiException('O servidor demorou muito tempo a responder.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Erro de ligação à rede.');
    }
  }


  // ============================================================
  // DOWNLOAD DE ANEXO
  // ============================================================

  /// GET /api/document/attachment/:id/token
  /// Pede ao servidor um URL de download de curta duração (token na query string).
  ///
  /// As rotas voltaram a estar ligadas na API desde 2026-10-08, por isso a
  /// ApiConfig.downloadDeAnexosDisponivel já está a true. O token dura 5
  /// minutos e viaja na query string, porque quem abre o ficheiro é o browser
  /// ou o webview, numa navegação normal que não leva o header Authorization.
  Future<String> getAttachmentUrl(int attachmentId) async {
    if (!ApiConfig.downloadDeAnexosDisponivel) {
      throw ApiException(
        'O download de documentos ainda não está disponível no servidor.',
        statusCode: 501,
      );
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.attachmentTokenEndpoint(attachmentId)}',
    );
    final response = await http
        .get(url, headers: await _authHeaders())
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode != 200) {
      throw ApiException(
        'Erro ao obter URL do anexo (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    final parsed = jsonDecode(response.body);
    final token = parsed['data']?['token'] as String?;
    if (token == null) {
      throw ApiException('Token de download não encontrado na resposta');
    }
    return ApiConfig.attachmentDownloadUrl(attachmentId, token);
  }

}
