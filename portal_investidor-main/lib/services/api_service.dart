import 'dart:convert';
import 'dart:async';
import '../models/user_model.dart';
import 'package:http/http.dart' as http;
import '../models/investidor_model.dart';
import '../models/sale_order.dart';
import '../models/notificacao.dart';
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
    // Entrar de novo reabre a porta: sem isto, depois de uma sessao
    // expirada o aviso nunca mais disparava nesta execucao da app.
    if (token != null) _jaAvisouQueExpirou = false;
  }

  /// O que fazer quando o servidor responde 401 a meio da sessao.
  ///
  /// Quem liga isto e o main.dart, que e quem tem o Navigator. O
  /// ApiService nao sabe nada de ecras e e assim que deve ficar.
  /// Respostas guardadas por uns minutos.
  ///
  /// O portfolio e pedido por sete sitios diferentes — o mapa, o
  /// portfolio, o "sobre nos", os outros empreendimentos — e as encomendas
  /// por dois, o painel e o detalhe. Cada ecra pedia por sua conta: abrir
  /// o painel, entrar num empreendimento e voltar atras fazia a mesma
  /// chamada tres vezes. Com dados a serio e rede movel isso sente-se, e
  /// e trafego pago pelo cliente.
  ///
  /// Nao e uma cache a serio: nao sabe se os dados mudaram no servidor.
  /// Por isso a validade e curta e qualquer "puxar para atualizar" a
  /// limpa primeiro — o utilizador que puxa quer dados novos, e tem de os
  /// receber.
  static final Map<String, _Guardado> _cache = {};

  static const Duration _validadeDaCache = Duration(minutes: 3);

  /// Deita fora o que esta guardado.
  ///
  /// Chamar sempre que o utilizador pede dados novos de proposito, e
  /// obrigatoriamente ao sair da sessao: dados de uma pessoa nunca podem
  /// aparecer a seguinte que entre neste telemovel.
  static void limparCache() => _cache.clear();

  Future<T> _comCache<T>(String chave, Future<T> Function() buscar) async {
    final guardado = _cache[chave];
    if (guardado != null &&
        DateTime.now().difference(guardado.quando) < _validadeDaCache) {
      return guardado.valor as T;
    }
    final valor = await buscar();
    _cache[chave] = _Guardado(valor, DateTime.now());
    return valor;
  }

  static void Function()? aoExpirarSessao;

  static bool _jaAvisouQueExpirou = false;

  /// Um 401 a meio da sessao quer dizer que o token morreu — expirou,
  /// foi revogado, ou a API reiniciou. Ate agora nada reagia: o ecra
  /// mostrava "erro" e o utilizador ficava ali, a carregar em "tentar
  /// novamente" contra um token que nunca mais ia servir.
  ///
  /// Dispara uma vez so. Se o painel fizer tres pedidos ao mesmo tempo e
  /// os tres levarem 401, o utilizador nao leva tres saltos para o login.
  static void _sessaoExpirou() {
    _token = null;
    idLogado = null;
    dadosLogado = null;
    // Sem isto, quem entrasse a seguir neste telemovel via os dados da
    // pessoa anterior ate a cache expirar.
    limparCache();
    if (_jaAvisouQueExpirou) return;
    _jaAvisouQueExpirou = true;
    aoExpirarSessao?.call();
  }

  /// Garante que o token está carregado em memória, lendo do armazenamento
  /// persistente se necessário (ex: após reiniciar a app).
  Future<String?> _obterTokenValido() async {
    _token ??= await AuthService.obterToken();
    return _token;
  }

  /// Levanta o erro certo para uma resposta que falhou.
  ///
  /// Existe para o 401 ser tratado num sitio so. Antes cada metodo
  /// lancava a sua ApiException e ninguem olhava para o statusCode.
  Never _falhou(http.Response response) {
    if (response.statusCode == 401) {
      ApiService._sessaoExpirou();
      throw ApiException(
        'A sua sessao expirou. Volte a entrar.',
        statusCode: 401,
      );
    }
    // O que o servidor escreve e para o programador, nao para o
    // investidor. Um erro interno do Odoo a frente de um cliente le-se
    // mal e pode dizer de mais sobre o que esta por tras.
    throw ApiException(
      _mensagemPara(response),
      statusCode: response.statusCode,
    );
  }

  /// A mensagem que o utilizador ve.
  String _mensagemPara(http.Response response) {
    final codigo = response.statusCode;
    if (codigo == 403) {
      return 'Não tem permissão para ver isto.';
    }
    if (codigo == 404) {
      return 'Não encontrámos o que procurava.';
    }
    if (codigo >= 500) {
      // Um 500 e sempre do lado de la: nada do que o servidor diga ajuda
      // quem esta a segurar o telemovel.
      return 'O servidor teve um problema. Tente daqui a pouco.';
    }
    // Nos outros 4xx a mensagem costuma ser de validacao e e util —
    // "email ja registado", por exemplo. Se vier vazia, uma generica.
    final doServidor = _extrairErro(response.body);
    return doServidor.isNotEmpty
        ? doServidor
        : 'Não foi possível completar o pedido.';
  }

  String _extrairErro(String responseBody) {
    try {
      final json = jsonDecode(responseBody);
      return json['message'] ??
          json['error'] ??
          'Erro desconhecido no servidor.';
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
  Future<(bool, String, int?, String?)> fazerLoginJson(
    String email,
    String password,
  ) async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(seconds: 1));
      return (true, 'Sucesso', 999, null);
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(ApiConfig.connectionTimeout);

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
          return (
            false,
            'ID do utilizador não encontrado na resposta',
            null,
            null,
          );
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

        dadosLogado = investidor;
        idLogado = investidor.id;
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

/// Uma resposta guardada e a hora a que o foi.
class _Guardado {
  final Object? valor;
  final DateTime quando;

  _Guardado(this.valor, this.quando);
}
