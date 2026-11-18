/// Comparar números de versão ("1.2.10" > "1.2.9").
class Versao {
  Versao._();

  /// true quando [publicada] é mais recente do que [atual].
  ///
  /// Compara número a número, não como texto ("1.10" > "1.9"). Ignora o que
  /// vier depois de "+" ou "-" (build e pré-versões) e trata o que faltar
  /// como 0 ("1.1" == "1.1.0"). Uma versão que não se perceba nunca é mais
  /// recente: na dúvida não se avisa.
  static bool maisRecente(String publicada, String atual) {
    final a = _partes(publicada);
    final b = _partes(atual);
    if (a == null || b == null) return false;
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }

  static List<int>? _partes(String versao) {
    final limpa = versao.trim().split(RegExp(r'[+\-]')).first;
    final bocados = limpa.split('.');
    if (bocados.isEmpty || bocados.length > 3) return null;
    final numeros = <int>[];
    for (final b in bocados) {
      final n = int.tryParse(b);
      if (n == null || n < 0) return null;
      numeros.add(n);
    }
    while (numeros.length < 3) {
      numeros.add(0);
    }
    return numeros;
  }
}
