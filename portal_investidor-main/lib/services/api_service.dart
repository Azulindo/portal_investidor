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
import 'notificacoes_push.dart';

// Os pedidos de cada área estão em extensões nestes ficheiros. Aqui fica o
// que é comum a todos: a sessão (token, renovação, fim de sessão), a cache,
// os cabeçalhos e o tratamento de erros.
part 'api/autenticacao.dart';
part 'api/documentos.dart';
part 'api/notificacoes.dart';
part 'api/projetos.dart';

/// Porque e que a sessao acabou a meio.
///
/// Os dois motivos sao os mesmos do site (lib/fimSessao.ts): da-se o mesmo
/// nome e diz-se a mesma coisa, para quem for bloqueado ler a mesma frase
/// no telemovel e no computador.
///
/// A diferenca importa: "expirou" sugere voltar a entrar e resolve-se
/// sozinho; "bloqueada" nao se resolve a entrar outra vez e tem de dizer
/// com quem falar.
enum FimDeSessao {
  expirada('A sua sessão terminou. Inicie sessão novamente.'),
  bloqueada(
    'A sua conta está bloqueada. Para mais informações contacte '
    'geral@cleveroption.pt.',
  );

  const FimDeSessao(this.mensagem);

  final String mensagem;

  /// O motivo para uma resposta que falhou, ou null se a sessao continua
  /// de pe e o erro e outra coisa qualquer.
  ///
  /// Equivale ao motivoFimSessao do site. Olha para o `code` e nao para a
  /// mensagem: o texto muda com o tempo, o codigo nao.
  static FimDeSessao? motivoPara(int estado, String corpo) {
    if (estado == 401) return FimDeSessao.expirada;

    // 403 e nao 401 porque o token e valido — o que deixou de valer foi a
    // conta. Os outros 403 (falta de permissao) nao terminam a sessao.
    if (estado == 403 && _codigoDe(corpo) == 'AUTH_ACCOUNT_BLOCKED') {
      return FimDeSessao.bloqueada;
    }

    return null;
  }

  static String _codigoDe(String corpo) {
    try {
      final json = jsonDecode(corpo);
      return json is Map ? (json['code']?.toString() ?? '') : '';
    } catch (_) {
      return '';
    }
  }
}

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

  static void Function(FimDeSessao motivo)? aoExpirarSessao;

  static bool _jaAvisouQueExpirou = false;

  /// Sair da conta por vontade da pessoa.
  ///
  /// Num sítio só porque estava em dois — o perfil e, agora, o menu lateral —
  /// e o segundo esquecer-se de uma linha era fácil. A que não pode faltar é
  /// a cache: sem a limpar, quem entrasse a seguir no mesmo telemóvel via os
  /// dados da pessoa anterior até ela expirar.
  ///
  /// Vive aqui e não no AuthService porque precisa dos dois, e é este que já
  /// conhece o outro. Ao contrário do [_sessaoExpirou], não chama o
  /// [aoExpirarSessao]: ninguém tem de ser avisado de que saiu, foi a pessoa
  /// que carregou no botão.
  ///
  /// Não navega. Quem chama decide para onde ir, porque o menu e o perfil
  /// saem de sítios diferentes da pilha de ecrãs.
  static Future<void> sair() async {
    // Revoga o refresh token no servidor antes de o apagar daqui — depois de
    // limparSessao já não há com que o fazer, e um refresh token vivo que
    // ninguém usa é um que fica a valer até expirar.
    //
    // Se a rede falhar, sai-se de qualquer maneira: o que não pode acontecer
    // é a pessoa ficar presa na conta por o servidor não responder.
    final refresh = await AuthService.obterRefreshToken();
    if (refresh != null && !ApiConfig.useMock) {
      try {
        await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logoutEndpoint}'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({'refreshToken': refresh}),
            )
            .timeout(ApiConfig.connectionTimeout);
      } catch (_) {
        // Fica para o servidor limpar quando expirar.
      }
    }

    await AuthService.limparSessao();
    _token = null;
    idLogado = null;
    dadosLogado = null;
    limparCache();
    // Para o próximo 401 voltar a avisar: este contador é por sessão.
    _jaAvisouQueExpirou = false;
    // O token do telemóvel a API apaga-o sozinha com o logout; aqui só se
    // deixa de o registar até a próxima pessoa entrar.
    NotificacoesPush.terminarSessao();
  }

  /// A sessao acabou sem ser por vontade da pessoa: o token morreu (401) ou
  /// a conta foi bloqueada (403). Ate haver isto nada reagia — o ecra
  /// mostrava "erro" e o utilizador ficava ali, a carregar em "tentar
  /// novamente" contra um token que nunca mais ia servir.
  ///
  /// Dispara uma vez so. Se o painel fizer tres pedidos ao mesmo tempo e
  /// os tres levarem 401, o utilizador nao leva tres saltos para o login.
  static void _sessaoExpirou(FimDeSessao motivo) {
    _token = null;
    idLogado = null;
    dadosLogado = null;
    // Sem isto, quem entrasse a seguir neste telemovel via os dados da
    // pessoa anterior ate a cache expirar.
    limparCache();
    if (_jaAvisouQueExpirou) return;
    _jaAvisouQueExpirou = true;
    aoExpirarSessao?.call(motivo);
  }

  /// Uma renovação de cada vez. Ver [_obterTokenValido].
  static Future<void>? _aRenovar;

  /// Garante que há em memória um token de acesso que ainda serve, lendo-o do
  /// armazenamento se for preciso (depois de reiniciar a app) e renovando-o
  /// quando está a acabar.
  ///
  /// O token de acesso dura 15 minutos e é o refresh token que mantém a
  /// sessão. Sem esta renovação a pessoa era deitada fora do portal a cada
  /// quarto de hora de uso.
  Future<String?> _obterTokenValido() async {
    _token ??= await AuthService.obterToken();
    if (!AuthService.precisaDeRenovar(_token)) return _token;

    final refresh = await AuthService.obterRefreshToken();
    if (refresh == null) return _token;

    // Uma renovação de cada vez. O painel faz vários pedidos ao mesmo tempo,
    // e a API troca o refresh token a cada renovação: dois pedidos em
    // paralelo com o mesmo refresh token pareciam-lhe uma cópia roubada, e a
    // resposta a isso é terminar a sessão.
    await (_aRenovar ??= _renovarSessao(refresh).whenComplete(() {
      _aRenovar = null;
    }));

    return _token;
  }

  /// Troca o refresh token por um token de acesso novo, em
  /// `POST /auth/refresh`.
  Future<void> _renovarSessao(String refreshToken) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refreshEndpoint}');
    try {
      final resposta = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(ApiConfig.connectionTimeout);

      if (resposta.statusCode == 200) {
        final tokens = tokensDeRenovacao(resposta.body);
        // Resposta com 200 e sem token é coisa que não devia acontecer. Fica
        // o token velho, e quem o usar leva o 401 que trata disto.
        if (tokens == null) return;

        _token = tokens.$1;
        await AuthService.guardarToken(tokens.$1);
        await AuthService.guardarRefreshToken(tokens.$2);
        return;
      }

      // A API responde com os mesmos códigos dos pedidos autenticados, e de
      // propósito: um refresh recusado é uma sessão que acabou.
      final motivo = FimDeSessao.motivoPara(
        resposta.statusCode,
        resposta.body,
      );
      if (motivo != null) {
        await AuthService.limparSessao();
        _sessaoExpirou(motivo);
      }
    } catch (_) {
      // Falha de rede não termina sessão nenhuma: fica o token velho e o
      // pedido a seguir falha com erro de rede, que é o que se passou.
    }
  }

  /// Lê os tokens da resposta de `/auth/refresh`.
  ///
  /// O `refreshToken` pode vir a null, e isso quer dizer "mantém o que
  /// tens": aconteceu outro pedido em paralelo e foi esse que levou o novo.
  ///
  /// Fora da chamada para poder ser testada — o ApiService cria o cliente
  /// http por dentro, por isso a resposta não se pode simular.
  static (String, String?)? tokensDeRenovacao(String corpo) {
    try {
      final data = (jsonDecode(corpo) as Map)['data'];
      if (data is! Map) return null;

      final token = data['token'];
      if (token is! String || token.isEmpty) return null;

      final refresh = data['refreshToken'];
      return (token, refresh is String && refresh.isNotEmpty ? refresh : null);
    } catch (_) {
      return null;
    }
  }

  /// Levanta o erro certo para uma resposta que falhou.
  ///
  /// Existe para o 401 ser tratado num sitio so. Antes cada metodo
  /// lancava a sua ApiException e ninguem olhava para o statusCode.
  Never _falhou(http.Response response) {
    // Dois casos acabam com a sessao: o token morreu (401) ou a conta foi
    // bloqueada no backoffice (403 com AUTH_ACCOUNT_BLOCKED, desde
    // 2026-10-22). Antes so o primeiro era tratado — no segundo a app
    // mostrava "nao tem permissao para ver isto" e deixava a pessoa la
    // dentro, num ecra que nunca carregava.
    final motivo = FimDeSessao.motivoPara(
      response.statusCode,
      response.body,
    );
    if (motivo != null) {
      ApiService._sessaoExpirou(motivo);
      throw ApiException(motivo.mensagem, statusCode: response.statusCode);
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

}

/// Uma resposta guardada e a hora a que o foi.
class _Guardado {
  final Object? valor;
  final DateTime quando;

  _Guardado(this.valor, this.quando);
}
