import 'dart:convert';
import 'dart:async';
import '../models/user_model.dart';
import 'package:http/http.dart' as http;
import '../models/investidor_model.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

/// Exceção customizada para erros "de negócio" da API (resposta válida mas
/// com erro), para se distinguir de erros de rede/timeout.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static int? idLogado;
  static InvestidorModel? dadosLogado;
  static String? _token;

  /// Define o token JWT manualmente (ex: após login) e mantém em memória
  /// para chamadas seguintes durante esta sessão.
  static void definirToken(String? token) {
    _token = token;
  }

  /// Garante que o token está carregado em memória, lendo do armazenamento
  /// persistente se necessário (ex: após reiniciar a app).
  Future<String?> _obterTokenValido() async {
    _token ??= await AuthService.obterToken();
    return _token;
  }

  String _extrairErro(String responseBody) {
    try {
      final json = jsonDecode(responseBody);
      return json['message'] ?? json['error'] ?? 'Erro desconhecido no servidor.';
    } catch (_) {
      return 'O servidor devolveu uma resposta inválida.';
    }
  }

  InvestidorModel _gerarDadosSimulados() {
    return InvestidorModel.fromJson({
      'id': 999,
      'name': 'Guilherme Gonçalves',
      'email': 'guilherme@cleveroption.pt',
      'totalInvested': '125500.0',
      'roiEsperado': '8.5',
      'createdAt': '2026-06-09T10:00:00Z',
      'obras': [
        {
          'id': 101,
          'name': 'Empreendimento Central',
          'city': 'São João da Madeira, Portugal',
          // ALTERADO: antes 'currentStepId' (id do step). Agora 'currentStep'
          // (número de "stepOrder" do passo atual).
          'currentStep': 2,
          'mainImageUrl': 'https://images.unsplash.com/photo-1541881430816-17b8f95c37eb?w=800',
          'steps': [
            {'id': 1, 'stepOrder': 1, 'name': 'Projeto', 'description': 'Aprovado'},
            {'id': 2, 'stepOrder': 2, 'name': 'Fundações', 'description': 'Executadas'},
            {'id': 3, 'stepOrder': 3, 'name': 'Estrutura', 'description': 'Em curso'},
          ]
        }
      ],
      'faturas': [
        {'title': 'Adjudicação Terreno', 'status': 'Pago', 'valor': '50000.0', 'data': '10 Maio 2026'},
        {'title': 'Materiais Estrutura', 'status': 'Pendente', 'valor': '15000.0', 'data': '01 Junho 2026'},
      ]
    });
  }

  Map<String, dynamic> _decodeJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    String payload = parts[1];
    payload = payload.replaceAll('-', '+').replaceAll('_', '/');
    while (payload.length % 4 != 0) payload += '=';
    final decoded = utf8.decode(base64.decode(payload));
    return jsonDecode(decoded);
  }

  /// Headers comuns para chamadas autenticadas
  Future<Map<String, String>> _authHeaders() async {
    final token = await _obterTokenValido();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // AUTENTICAÇÃO
  // ============================================================

  /// Faz login. Devolve (sucesso, mensagem, userId, token)
  Future<(bool, String, int?, String?)> fazerLoginJson(String email, String password) async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(seconds: 1));
      return (true, 'Sucesso', 999, null);
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> parsed = jsonDecode(response.body);
        final token = parsed['data']?['token'] as String?;
        int? id = parsed['data']?['user']?['id'];

        if (token != null) {
          _token = token;
          if (id == null) {
            final payload = _decodeJwt(token);
            id = int.tryParse(payload['id']?.toString() ?? '');
          }
        }

        if (id != null) {
          idLogado = id;
          return (true, 'Sucesso', id, token);
        } else {
          return (false, 'ID do utilizador não encontrado na resposta', null, null);
        }
      } else {
        return (false, _extrairErro(response.body), null, null);
      }
    } on TimeoutException catch (_) {
      return (false, 'O servidor demorou muito tempo a responder.', null, null);
    } catch (e) {
      return (false, 'Erro de ligação à rede.', null, null);
    }
  }

  Future<(bool, String)> registarJson(String primeiroNome, String ultimoNome, String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.registerEndpoint}');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'primeiroNome': primeiroNome, 'ultimoNome': ultimoNome, 'email': email, 'password': password}),
      ).timeout(ApiConfig.connectionTimeout);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return (true, 'Conta criada com sucesso!');
      } else {
        return (false, _extrairErro(response.body));
      }
    } on TimeoutException catch (_) {
      return (false, 'O servidor demorou muito tempo a responder no registo.');
    } catch (e) {
      return (false, 'Erro de ligação à rede.');
    }
  }

  // ============================================================
  // UTILIZADOR
  // ============================================================

  Future<InvestidorModel?> buscarDadosDoInvestidor(int idAtual) async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      InvestidorModel investidor = _gerarDadosSimulados();
      dadosLogado = investidor;
      idLogado = investidor.id;
      return investidor;
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userEndpoint(idAtual)}');
    try {
      final response = await http
          .get(url, headers: await _authHeaders())
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200) {
        final fullResponse = jsonDecode(response.body);
        final data = fullResponse['data'] as Map<String, dynamic>? ?? {};
        final userDataList = data['userData'] as List? ?? [];
        final userData = userDataList.isNotEmpty ? userDataList[0] as Map<String, dynamic> : <String, dynamic>{};
        final projects = data['projects'] as List? ?? [];

        List<ConstructionItem> obrasConvertidas = [];
        for (var proj in projects) {
          try {
            obrasConvertidas.add(ConstructionItem.fromJson(proj as Map<String, dynamic>));
          } catch (_) {
            // ignora projeto malformado
          }
        }

        final investidor = InvestidorModel(
          id: idAtual,
          name: '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim(),
          email: userData['email']?.toString() ?? '',
          totalInvested: 0.0,
          roiEsperado: null,
          createdAt: DateTime.now(),
          obras: obrasConvertidas,
          faturas: [],
        );

        dadosLogado = investidor;
        idLogado = investidor.id;
        return investidor;
      } else {
        throw ApiException(_extrairErro(response.body), statusCode: response.statusCode);
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
  Future<List<dynamic>> buscarPortfolio() async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return [
        {
          'id': 1,
          'name': 'Torre Comercial SJM',
          'city': 'São João da Madeira',
          'mainImageUrl': 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800',
          // ALTERADO: antes 'currentStepId' (id do step). Agora 'currentStep'
          // (número de "stepOrder" do passo atual).
          'currentStep': 1,
          'steps': [
            {'id': 1, 'stepOrder': 1, 'name': 'Projeto', 'description': 'Em aprovação'},
            {'id': 2, 'stepOrder': 2, 'name': 'Fundações', 'description': 'Previsto'},
          ]
        }
      ];
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
        throw ApiException(_extrairErro(response.body), statusCode: response.statusCode);
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
      return ProjectDetailModel.fromJson({
        'data': {
          'projectInfo': [
            {
              'name': 'Torre Comercial SJM',
              'address': 'Rua Exemplo, 123',
              'city': 'São João da Madeira',
              'status': 'Em Curso',
              // ALTERADO: antes 'currentStepId' (id do step). Agora
              // 'currentStep' (número de "stepOrder" do passo atual).
              'currentStep': 1,
              'description': 'Descrição de exemplo do projeto em modo mock.',
              'mainImageUrl': 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800',
            }
          ],
          'projectSteps': [
            // ALTERADO: antes 'stepId', agora 'id' (mesmo formato dos outros
            // endpoints - ver ProjectStepDetail em user_model.dart).
            {'id': 1, 'stepOrder': 1, 'name': 'Projeto', 'description': 'Em aprovação'},
            {'id': 2, 'stepOrder': 2, 'name': 'Fundações', 'description': 'Previsto'},
          ],
          'projectImages': [
            {'imageId': 1, 'imageUrl': 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800', 'imageDescription': 'Capa'},
          ],
        }
      });
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.projectDetailsEndpoint(projectId)}');
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
        throw ApiException(_extrairErro(response.body), statusCode: response.statusCode);
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
