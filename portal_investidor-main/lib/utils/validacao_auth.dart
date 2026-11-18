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
    // Símbolo = qualquer caracter que não seja letra, algarismo nem espaço,
    // como no passwordSchema da API e no lib/password.ts do site. Antes era a
    // lista fechada @$!%*?&#, que a API entretanto largou: "Teste_123" era
    // recusada aqui e aceite no site.
    if (!_simbolo.hasMatch(p)) {
      return 'Deve conter pelo menos um símbolo (ex.: _ - . @ #).';
    }
    return null;
  }

  static final RegExp _simbolo = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);

  static String? confirmacao(String? valor, String password) {
    if ((valor ?? '').isEmpty) return 'Confirme a sua palavra-passe.';
    if (valor != password) return 'As palavras-passe não coincidem.';
    return null;
  }

  /// Ao alterar: a nova não pode ser igual à atual. A API aceitava, mas era
  /// uma "alteração" que não mudava nada e terminava as outras sessões.
  static String? novaDiferente(String? nova, String atual) {
    if ((nova ?? '').isNotEmpty && nova == atual) {
      return 'A nova palavra-passe tem de ser diferente da atual.';
    }
    return null;
  }

  /// Texto da dica que acompanha o campo da palavra-passe.
  static const String dicaPassword =
      'Mín. 8 caracteres, com maiúscula, minúscula, número e um símbolo '
      '(ex.: _ - . @ #).';

  /// Campo obrigatório simples, para o login (que não valida força nenhuma —
  /// a palavra-passe já existe, as regras aplicam-se a quem a cria).
  static String? obrigatorio(String? valor, String mensagem) {
    if ((valor ?? '').trim().isEmpty) return mensagem;
    return null;
  }
}
