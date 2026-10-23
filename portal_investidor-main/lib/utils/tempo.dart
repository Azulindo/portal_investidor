/// Ha quanto tempo foi, em portugues.
///
/// Numa lista de notificacoes a data exata nao diz nada — "12/10/2026" obriga
/// a pessoa a fazer a conta de cabeca. O que interessa e se foi hoje ou ha
/// duas semanas, e por isso e que o site tambem mostra assim.
class Tempo {
  /// Acima deste tempo deixa de compensar contar e passa-se a mostrar a data.
  static const Duration _ateQuandoContar = Duration(days: 7);

  /// [quando] vem em UTC da API. [agora] existe para os testes poderem fixar
  /// o relogio; fora deles fica a hora da maquina.
  static String haQuanto(DateTime? quando, {DateTime? agora}) {
    if (quando == null) return '';

    final referencia = agora ?? DateTime.now();
    final decorrido = referencia.difference(quando);

    // Relogio do telemovel atrasado em relacao ao servidor: a notificacao fica
    // com data no futuro. Dizer "ha -3 minutos" seria pior do que "agora".
    if (decorrido.isNegative) return 'agora';

    if (decorrido.inMinutes < 1) return 'agora';
    if (decorrido.inMinutes < 60) return 'há ${decorrido.inMinutes} min';
    if (decorrido.inHours < 24) {
      return 'há ${decorrido.inHours} ${decorrido.inHours == 1 ? 'hora' : 'horas'}';
    }
    if (decorrido < _ateQuandoContar) {
      return 'há ${decorrido.inDays} ${decorrido.inDays == 1 ? 'dia' : 'dias'}';
    }

    return _data(quando.toLocal());
  }

  static String _data(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}
