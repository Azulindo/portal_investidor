/// Regras de validação dos formulários de autenticação.
///
/// Estão aqui, fora dos ecrãs, por duas razões: para serem iguais no registo
/// e na redefinição de palavra-passe, e para poderem ser testadas sem abrir
/// a app.
///
/// São as mesmas regras do site (components/RegistoForm.tsx), que por sua vez
/// espelham o schemaRegisto (Zod) da API. Se a API mudar as regras, muda-se
/// aqui — não em cada ecrã.
///
/// Cada função devolve a mensagem de erro, ou null quando está bem.
class ValidacaoAuth {
  ValidacaoAuth._();

  static final RegExp _email = RegExp(
    r'^[\w.+\-]+@[\w\-]+\.[a-z]{2,}$',
    caseSensitive: false,
  );

  static String? nome(String? valor, {required String campo}) {
    if ((valor ?? '').trim().length < 2) return 'Introduza o seu $campo.';
    return null;
  }

  static String? email(String? valor) {
    if (!_email.hasMatch((valor ?? '').trim())) {
      return 'Introduza um endereço de e-mail válido.';
    }
    return null;
  }

  /// Aceita espaços, hífens e indicativo; conta só os dígitos.
  static String? telemovel(String? valor) {
    final limpo = (valor ?? '').replaceAll(RegExp(r'[\s\-+]'), '');
    if (limpo.length < 9) return 'Introduza um número de telemóvel válido.';
    return null;
  }

  /// 8+ caracteres, com minúscula, maiúscula, número e símbolo.
  ///
  /// A ordem das verificações é a do site, para a pessoa ver sempre a mesma
  /// mensagem nos dois sítios.
  static String? password(String? valor) {
    final p = valor ?? '';
    if (p.length < 8) return 'A palavra-passe deve ter pelo menos 8 caracteres.';
    if (!RegExp(r'[a-z]').hasMatch(p)) {
      return 'Deve conter pelo menos uma letra minúscula.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(p)) {
      return 'Deve conter pelo menos uma letra maiúscula.';
    }
    if (!RegExp(r'[0-9]').hasMatch(p)) {
      return 'Deve conter pelo menos um número.';
    }
    if (!RegExp(r'[@$!%*?&#]').hasMatch(p)) {
      return 'Deve conter pelo menos um caracter especial (@\$!%*?&#).';
    }
    return null;
  }

  static String? confirmacao(String? valor, String password) {
    if ((valor ?? '').isEmpty) return 'Confirme a sua palavra-passe.';
    if (valor != password) return 'As palavras-passe não coincidem.';
    return null;
  }

  /// Texto da dica que acompanha o campo da palavra-passe.
  static const String dicaPassword =
      'Mín. 8 caracteres, com maiúscula, minúscula, número e caracter '
      'especial (@\$!%*?&#).';

  /// Campo obrigatório simples, para o login (que não valida força nenhuma —
  /// a palavra-passe já existe, as regras aplicam-se a quem a cria).
  static String? obrigatorio(String? valor, String mensagem) {
    if ((valor ?? '').trim().isEmpty) return mensagem;
    return null;
  }
}
