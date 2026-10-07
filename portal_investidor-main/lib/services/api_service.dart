import 'dart:convert';
import 'dart:async';
import '../models/user_model.dart';
import 'package:http/http.dart' as http;
import '../models/investidor_model.dart';
import '../models/sale_order.dart';
import '../config/api_config.dart';
import 'auth_service.dart';
import 'dados_de_exemplo.dart';

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

  InvestidorModel _gerarDadosSimulados() =>
      InvestidorModel.fromJson(DadosDeExemplo.investidor());

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
        final investidor = InvestidorModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
          idDeRecurso: idAtual,
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
      return DadosDeExemplo.encomendas();
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

  /// Devolve a lista de documentos (faturas) com anexos do utilizador autenticado.

  Future<List<Map<String, dynamic>>> buscarDocumentos() async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return DadosDeExemplo.documentos();
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
      return ProjectDetailModel.fromJson(DadosDeExemplo.detalhes(projectId));
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
