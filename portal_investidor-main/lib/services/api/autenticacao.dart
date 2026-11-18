part of '../api_service.dart';

// Login, registo, recuperar e redefinir a palavra-passe, confirmar o email.
//
// Parte do ApiService, separada em extensÃ£o para o ficheiro principal ficar
// sÃ³ com a sessÃ£o, a cache e os erros. Quem chama nÃ£o muda nada:
// ApiService().metodo() continua a funcionar, porque a extensÃ£o vem com o
// import de api_service.dart. Membros estÃ¡ticos do ApiService aqui dentro
// tÃªm de levar o prefixo (ApiService.idLogado), Ã© uma regra das extensÃµes.
extension ApiAutenticacao on ApiService {
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
        // O refresh token é o que mantém a sessão viva: o de acesso dura 15
        // minutos. Guarda-se aqui para quem chama não ter de saber que ele
        // existe — o ecrã de login continua a lidar só com o id e o token.
        await AuthService.guardarRefreshToken(
          parsed['data']?['refreshToken'] as String?,
        );
        int? id = parsed['data']?['user']?['id'];

        if (token != null) {
          ApiService._token = token;
          if (id == null) {
            final payload = _decodeJwt(token);
            id = int.tryParse(payload['id']?.toString() ?? '');
          }
        }

        if (id != null) {
          ApiService.idLogado = id;
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
  ///
  /// O campo chama-se `newPassword` e nao `password`: e o nome que o
  /// schemaResetPassword da API exige, e e o que o site manda. Estava
  /// `password` aqui, o que dava sempre erro de validacao — nunca se notou
  /// porque nenhum ecra chegava a chamar este metodo.
  Future<(bool, String)> redefinirPassword(String token, String password) {
    return _pedidoAuth(
      ApiConfig.resetPasswordEndpoint,
      {'token': token, 'newPassword': password},
      sucesso: 'Palavra-passe alterada.',
      erro: 'Não foi possível alterar a palavra-passe.',
    );
  }

  /// POST /auth/change-password, com sessão iniciada.
  ///
  /// A API termina as sessões noutros aparelhos e mantém esta, por isso não
  /// é preciso voltar a entrar. Um 401 aqui é a palavra-passe atual errada
  /// (o token já foi renovado pelo _authHeaders), e não sessão expirada.
  Future<(bool, String)> alterarPassword(String atual, String nova) async {
    if (ApiConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return (true, 'Palavra-passe alterada.');
    }
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.changePasswordEndpoint}',
    );
    try {
      final response = await http
          .post(
            url,
            headers: await _authHeaders(),
            body: jsonEncode({'currentPassword': atual, 'newPassword': nova}),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return (true, 'Palavra-passe alterada.');
      }
      if (response.statusCode == 401) {
        return (false, 'A palavra-passe atual não está correta.');
      }
      // 400 (regras da nova) e 429 (demasiadas tentativas) trazem uma
      // mensagem da API que serve tal como vem.
      return (false, _mensagemPara(response));
    } on TimeoutException catch (_) {
      return (false, 'O servidor demorou muito tempo a responder.');
    } catch (_) {
      return (false, 'Erro de ligação à rede.');
    }
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

  /// GET /auth/confirm-email?token=...
  ///
  /// E o unico destes que nao e POST: o link do email abre-se no browser, e
  /// por isso a API poe o token na query string. Da app chamamo-lo na mesma,
  /// para quem cola o link aqui nao ter de sair para o browser.
  Future<(bool, String)> confirmarEmail(String token) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.confirmEmailEndpoint(token)}',
    );
    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(ApiConfig.connectionTimeout);

      final corpo = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>?
          : null;
      final mensagem = corpo?['message']?.toString();

      if (response.statusCode == 200) {
        return (true, mensagem ?? 'Conta confirmada.');
      }
      // A API distingue "expirado" de "inválido" e explica-se melhor do que
      // nós conseguiriamos aqui, por isso passa-se o texto dela à frente.
      return (false, mensagem ?? 'Não foi possível confirmar a conta.');
    } on TimeoutException catch (_) {
      return (false, 'O servidor demorou muito tempo a responder.');
    } catch (_) {
      return (false, 'Erro de ligação à rede.');
    }
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

}
