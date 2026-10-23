/// Tira o token de um link que veio num email.
///
/// Os emails da Clever Option levam a pessoa para o site
/// (`.../redefinir-password?token=...` ou `.../confirmar-email?token=...`),
/// porque o site e que estava feito primeiro. Num telemovel isso significa
/// sair da app, abrir o browser e, no fim, voltar a entrar.
///
/// Enquanto nao houver deep links — que precisam de ficheiros no dominio, e
/// isso nao se faz deste lado — a app aceita o link colado. Quem copia o
/// endereco do email e cola aqui resolve tudo sem sair.
class TokenDeEmail {
  /// Aceita o link inteiro, so a query string, ou o token sozinho.
  ///
  /// Devolve null quando nao da para tirar nada — e ai quem chama e que
  /// decide o que dizer, porque a frase muda conforme o ecra.
  static String? extrair(String? bruto) {
    final texto = bruto?.trim();
    if (texto == null || texto.isEmpty) return null;

    // Um link pode vir partido em varias linhas pelo cliente de email.
    final limpo = texto.replaceAll(RegExp(r'\s+'), '');

    final doUrl = _doQueryString(limpo);
    if (doUrl != null) return doUrl;

    // Nao tem "token=" nenhum: ou e o token sozinho, ou e lixo. Um token da
    // API e um JWT, que tem sempre dois pontos a separar tres partes — e isso
    // que distingue um token colado de uma frase colada por engano.
    if (_pareceJwt(limpo)) return limpo;

    return null;
  }

  /// Procura `token=` em qualquer sitio do texto, seja um URL completo, uma
  /// query string solta ou um link com fragmento (#).
  static String? _doQueryString(String texto) {
    final encontrado = RegExp(
      r'[?&#]token=([^&#\s]+)',
      caseSensitive: false,
    ).firstMatch(texto);

    if (encontrado == null) return null;

    final valor = encontrado.group(1);
    if (valor == null || valor.isEmpty) return null;

    // O token pode vir codificado no URL, sobretudo se passou por um
    // redirecionador de email.
    try {
      return Uri.decodeComponent(valor);
    } catch (_) {
      return valor;
    }
  }

  static bool _pareceJwt(String texto) {
    final partes = texto.split('.');
    return partes.length == 3 && partes.every((p) => p.isNotEmpty);
  }
}
