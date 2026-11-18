part of '../api_service.dart';

// Os dados do investidor, o portfÃ³lio e o detalhe de um empreendimento.
//
// Parte do ApiService, separada em extensÃ£o para o ficheiro principal ficar
// sÃ³ com a sessÃ£o, a cache e os erros. Quem chama nÃ£o muda nada:
// ApiService().metodo() continua a funcionar, porque a extensÃ£o vem com o
// import de api_service.dart. Membros estÃ¡ticos do ApiService aqui dentro
// tÃªm de levar o prefixo (ApiService.idLogado), Ã© uma regra das extensÃµes.
extension ApiProjetos on ApiService {
  // ============================================================
  // UTILIZADOR
  // ============================================================

  Future<InvestidorModel?> buscarDadosDoInvestidor(int idAtual) async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      InvestidorModel investidor = _gerarDadosSimulados();
      ApiService.dadosLogado = investidor;
      ApiService.idLogado = investidor.id;
      return investidor;
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.userEndpoint(idAtual)}',
    );
    try {
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final investidor = InvestidorModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
          idDeRecurso: idAtual,
        );

        ApiService.dadosLogado = investidor;
        ApiService.idLogado = investidor.id;
        return investidor;
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
  // PORTFÓLIO
  // ============================================================

  /// GET /api/project/portfolio
  /// Devolve a lista resumida de projetos para o ecrã "Portfólio".
  Future<List<dynamic>> buscarPortfolio() =>
      _comCache('portfolio', _buscarPortfolio);

  Future<List<dynamic>> _buscarPortfolio() async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return DadosDeExemplo.portfolio();
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.portfolioEndpoint}');
    try {
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> parsed = jsonDecode(response.body);
        final data = parsed['data'];
        if (data is Map<String, dynamic> && data['projects'] is List) {
          return data['projects'] as List<dynamic>;
        }
        if (data is List) {
          return data;
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
  // DETALHES DO PROJETO
  // ============================================================

  /// GET /api/project/details?projectId=id
  /// Devolve as informações detalhadas, etapas e galeria de um projeto.
  Future<ProjectDetailModel> buscarDetalhesProjeto(int projectId) async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return ProjectDetailModel.fromJson(DadosDeExemplo.detalhes(projectId));
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.projectDetailsEndpoint(projectId)}',
    );
    try {
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> parsed = jsonDecode(response.body);
        return ProjectDetailModel.fromJson(parsed);
      } else if (response.statusCode == 404) {
        throw ApiException('Projeto não encontrado.', statusCode: 404);
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
}
