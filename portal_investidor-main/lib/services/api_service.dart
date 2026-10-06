import 'dart:convert';
import 'dart:async';
import '../models/user_model.dart';
import 'package:http/http.dart' as http;
import '../models/investidor_model.dart';
import '../models/sale_order.dart';
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
    while (payload.length % 4 != 0) {
      payload += '=';
    }
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

  /// Cria a conta. A API cria-a INATIVA e envia um email com o link de
  /// ativação, por isso o sucesso aqui não quer dizer que já se pode entrar.
  ///
  /// Os nomes dos campos são os que a API espera (firstName/lastName/...), e
  /// não os nomes portugueses que estavam aqui antes — com os antigos o
  /// registo falhava sempre na validação do servidor.
  Future<(bool, String)> registarJson({
    required String primeiroNome,
    required String ultimoNome,
    required String telemovel,
    required String email,
    required String password,
    required bool aceitouTermos,
  }) {
    return _pedidoAuth(
      ApiConfig.registerEndpoint,
      {
        'firstName': primeiroNome,
        'lastName': ultimoNome,
        'phone': telemovel,
        'email': email,
        'password': password,
        'acceptedTerms': aceitouTermos,
      },
      sucesso: 'Conta criada.',
      erro: 'Não foi possível criar a conta.',
    );
  }

  /// Pede o email de recuperação de palavra-passe.
  ///
  /// A resposta é sempre igual, exista ou não a conta — é de propósito, para
  /// não se poder descobrir quem está registado.
  Future<(bool, String)> recuperarAcesso(String email) {
    return _pedidoAuth(
      ApiConfig.forgotPasswordEndpoint,
      {'email': email},
      sucesso: 'Email enviado.',
      erro: 'Não foi possível enviar o email de recuperação.',
    );
  }

  /// Define a nova palavra-passe a partir do token que veio no email.
  Future<(bool, String)> redefinirPassword(String token, String password) {
    return _pedidoAuth(
      ApiConfig.resetPasswordEndpoint,
      {'token': token, 'password': password},
      sucesso: 'Palavra-passe alterada.',
      erro: 'Não foi possível alterar a palavra-passe.',
    );
  }

  /// Reenvia o email de confirmação de conta.
  Future<(bool, String)> reenviarConfirmacao(String email) {
    return _pedidoAuth(
      ApiConfig.resendConfirmationEndpoint,
      {'email': email},
      sucesso: 'Email reenviado.',
      erro: 'Não foi possível reenviar o email de confirmação.',
    );
  }

  /// POST comum a todos os pedidos de autenticação sem sessão.
  ///
  /// Devolve (sucesso, mensagem). Quando a API explica o que está mal
  /// (email já registado, token expirado), é essa mensagem que passa — só se
  /// usa o texto genérico quando a resposta não traz nenhuma.
  Future<(bool, String)> _pedidoAuth(
    String endpoint,
    Map<String, dynamic> corpo, {
    required String sucesso,
    required String erro,
  }) async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return (true, sucesso);
    }

    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(corpo),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (true, sucesso);
      }
      final doServidor = _extrairErro(response.body);
      return (false, doServidor.isNotEmpty ? doServidor : erro);
    } on TimeoutException catch (_) {
      return (false, 'O servidor demorou muito tempo a responder.');
    } catch (_) {
      return (false, 'Não foi possível ligar ao servidor.');
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
          // Soma dos totais de todas as encomendas do cliente. Estava fixo a
          // 0.0 e por isso o painel mostrava sempre zero, apesar de a API
          // mandar o valor.
          totalInvested: double.tryParse(data['totalInvested']?.toString() ?? '') ?? 0.0,
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
  // DOCUMENTOS
  // ============================================================

  /// GET /api/document/list
  /// As encomendas do cliente, cada uma com as suas faturas.
  ///
  /// É daqui que saem os totais do painel (investido, pago, por pagar) — ver
  /// utils/carteira.dart. O endpoint já estava declarado no ApiConfig mas não
  /// havia nada a chamá-lo.
  Future<List<SaleOrder>> buscarOrdensDeCompra() async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return _ordensSimuladas();
    }

    final url =
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.saleOrdersEndpoint}');
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
      throw ApiException(
        _extrairErro(response.body),
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (_) {
      throw ApiException('O servidor demorou muito tempo a responder.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Erro de ligação à rede.');
    }
  }

  /// Encomendas de exemplo, com os casos que interessam: uma toda paga, uma
  /// parcial e uma por pagar, e duas encomendas no mesmo empreendimento com
  /// uma fração repetida (para se ver que a carteira não a conta duas vezes).
  List<SaleOrder> _ordensSimuladas() {
    return [
      SaleOrder(
        id: 1,
        name: 'SO0001',
        projectName: 'Aires Ornelas',
        fractions: const ['A', 'B'],
        amountTotal: 185000,
        date: '2026-01-15',
        invoices: [
          Invoice(
            id: 11,
            name: 'INV/2026/0001',
            date: '2026-01-20',
            paymentState: 'paid',
            amountTotal: 92500,
            amountResidual: 0,
          ),
          Invoice(
            id: 12,
            name: 'INV/2026/0002',
            date: '2026-04-20',
            paymentState: 'partial',
            amountTotal: 92500,
            amountResidual: 42500,
          ),
        ],
      ),
      SaleOrder(
        id: 2,
        name: 'SO0002',
        projectName: 'Aires Ornelas',
        fractions: const ['B'],
        amountTotal: 12000,
        date: '2026-02-02',
        invoices: [
          Invoice(
            id: 21,
            name: 'INV/2026/0003',
            date: '2026-02-10',
            paymentState: 'not_paid',
            amountTotal: 12000,
            amountResidual: 12000,
          ),
        ],
      ),
      SaleOrder(
        id: 3,
        name: 'SO0003',
        projectName: 'Quinta das Laranjeiras',
        fractions: const ['1.ºD'],
        amountTotal: 240000,
        date: '2026-03-01',
        invoices: const [],
      ),
    ];
  }

  /// Devolve a lista de documentos (faturas) com anexos do utilizador autenticado.
  Future<List<Map<String, dynamic>>> buscarDocumentos() async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return [
        {
          'id': 1,
          'name': 'INV/2026/0001',
          'paymentState': 'paid',
          'amountTotal': 50000.0,
          'attachments': [
            {'id': 5, 'name': 'factura_001.pdf', 'mimetype': 'application/pdf'},
          ],
        },
        {
          'id': 2,
          'name': 'INV/2026/0002',
          'paymentState': 'not_paid',
          'amountTotal': 15000.0,
          'attachments': [],
        },
      ];
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.documentListEndpoint}');
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
  // DOWNLOAD DE ANEXO
  // ============================================================

  /// GET /api/document/attachment/:id/token
  /// Pede ao servidor um URL de download de curta duração (token na query string).
  ///
  /// ATENÇÃO: estas rotas estão comentadas na API neste momento ("desativado
  /// temporariamente — TODO: desenvolver esta parte mais tarde"), por isso
  /// chamá-las dá 404. O código fica feito; quando voltarem, é só pôr
  /// ApiConfig.downloadDeAnexosDisponivel a true.
  Future<String> getAttachmentUrl(int attachmentId) async {
    if (!ApiConfig.downloadDeAnexosDisponivel) {
      throw ApiException(
        'O download de documentos ainda não está disponível no servidor.',
        statusCode: 501,
      );
    }

    final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.attachmentTokenEndpoint(attachmentId)}');
    final response = await http
        .get(url, headers: await _authHeaders())
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode != 200) {
      throw ApiException('Erro ao obter URL do anexo (${response.statusCode})', statusCode: response.statusCode);
    }

    final parsed = jsonDecode(response.body);
    final token = parsed['data']?['token'] as String?;
    if (token == null) throw ApiException('Token de download não encontrado na resposta');
    return ApiConfig.attachmentDownloadUrl(attachmentId, token);
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
