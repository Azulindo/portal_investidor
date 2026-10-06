/// Contas sobre a lista de GET /project/portfolio: grupos de estado, ordem de
/// apresentação, progresso da obra e contagens.
///
/// São as mesmas do site (statusGroup, ordenarPorComercializacao e
/// progressoObra em lib/testApi.ts). Estão fora do ecrã para poderem ser
/// testadas, e porque a mesma ordem é usada em mais do que um sítio.
///
/// Trabalha-se aqui com os Map tal como vêm da API, que é como o ecrã do
/// portfólio já os tinha — fazer um modelo agora obrigava a mexer em código
/// que funciona.
class Portfolio {
  Portfolio._();

  // ── Estado ────────────────────────────────────────────────

  /// Em que dos três grupos cai um estado.
  ///
  /// Compara por pedaços de texto e não por igualdade, porque a API escreve
  /// "Concluído", "Em construção", "Construção" e "Em desenvolvimento" em
  /// sítios diferentes.
  static String grupoDeEstado(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('conclu')) return 'concluido';
    if (s.contains('desenvolvimento')) return 'desenvolvimento';
    return 'ativo';
  }

  static bool estaConcluido(String? status) =>
      grupoDeEstado(status) == 'concluido';

  // ── Leitura dos campos ────────────────────────────────────

  static String texto(Map p, String chave) => p[chave]?.toString() ?? '';

  static int? inteiro(Map p, String chave) =>
      int.tryParse(p[chave]?.toString() ?? '');

  static bool estaAVenda(Map p) => p['forSale'] == true;

  /// Só o ano da data de conclusão. A API manda a data inteira
  /// ("2028-12-31"), mas é por ano que a conclusão se lê em todo o lado.
  static String? anoFim(Map p) =>
      RegExp(r'\d{4}').firstMatch(texto(p, 'endDate'))?.group(0);

  // ── Ordem ─────────────────────────────────────────────────

  /// À frente o que ainda há para vender. É a ordem do site, para a lista ser
  /// a mesma nos dois.
  ///
  /// O /project/portfolio não diz quantas frações estão disponíveis — só se o
  /// empreendimento está em comercialização e quantas frações tem no total —
  /// por isso o "quanto há para vender" é aproximado pelo tamanho. Se a API
  /// passar a devolver as disponíveis, troca-se o critério aqui.
  static List<Map> ordenarPorComercializacao(List<Map> lista) {
    final ordenada = [...lista];
    ordenada.sort((a, b) {
      // 1.º quem está em comercialização
      final porVenda = (estaAVenda(b) ? 1 : 0) - (estaAVenda(a) ? 1 : 0);
      if (porVenda != 0) return porVenda;

      // 2.º os maiores — mais frações, mais provável haver escolha
      final porTamanho =
          (inteiro(b, 'nFractions') ?? 0) - (inteiro(a, 'nFractions') ?? 0);
      if (porTamanho != 0) return porTamanho;

      // 3.º conclusão mais próxima
      final porAno = (anoFim(a) ?? '9999').compareTo(anoFim(b) ?? '9999');
      if (porAno != 0) return porAno;

      return texto(a, 'name').toLowerCase().compareTo(
            texto(b, 'name').toLowerCase(),
          );
    });
    return ordenada;
  }

  // ── Filtros ───────────────────────────────────────────────

  /// Cidades distintas, por ordem alfabética, para alimentar o filtro.
  static List<String> cidades(List<Map> lista) {
    final set = <String>{};
    for (final p in lista) {
      final c = texto(p, 'city').trim();
      if (c.isNotEmpty) set.add(c);
    }
    final ordenadas = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ordenadas;
  }

  /// Aplica os filtros. Cada um a null é "todos".
  static List<Map> filtrar(
    List<Map> lista, {
    String? grupo,
    String? cidade,
    bool apenasAVenda = false,
  }) {
    return lista.where((p) {
      if (grupo != null && grupoDeEstado(texto(p, 'status')) != grupo) {
        return false;
      }
      if (cidade != null && texto(p, 'city') != cidade) return false;
      if (apenasAVenda && !estaAVenda(p)) return false;
      return true;
    }).toList();
  }

  // ── Contagens ─────────────────────────────────────────────

  static int quantosNoGrupo(List<Map> lista, String grupo) =>
      lista.where((p) => grupoDeEstado(texto(p, 'status')) == grupo).length;

  /// Total de frações de todos os empreendimentos.
  static int totalFracoes(List<Map> lista) =>
      lista.fold(0, (soma, p) => soma + (inteiro(p, 'nFractions') ?? 0));

  // ── Progresso da obra ─────────────────────────────────────

  /// Em que fase da obra está o empreendimento.
  ///
  /// As fases e o currentStep já vêm dentro de /project/portfolio, por isso
  /// isto não custa um pedido extra. Devolve null quando não há timeline, ou
  /// quando a API não diz em que fase está — nesse caso não se mostra nada,
  /// em vez de se inventar uma fase.
  static ProgressoObra? progresso(Map p) {
    final currentStep = inteiro(p, 'currentStep');
    final steps = (p['steps'] as List? ?? []).whereType<Map>().toList();
    if (steps.isEmpty || currentStep == null) return null;

    steps.sort(
      (a, b) => (inteiro(a, 'stepOrder') ?? 0) - (inteiro(b, 'stepOrder') ?? 0),
    );

    // Se a API mandar um stepOrder que não corresponde a nenhuma fase,
    // conta-se quantas já ficaram para trás em vez de desistir.
    final indice =
        steps.indexWhere((s) => inteiro(s, 'stepOrder') == currentStep);
    final bruto = indice >= 0
        ? indice + 1
        : steps.where((s) => (inteiro(s, 'stepOrder') ?? 0) <= currentStep).length;
    final posicao = bruto.clamp(1, steps.length);

    return ProgressoObra(
      total: steps.length,
      feitos: posicao - 1,
      posicao: posicao,
      nome: texto(steps[posicao - 1], 'name'),
      // Que a obra acabou diz-o o estado do projeto, e não o currentStep: um
      // projeto com uma só fase e currentStep 1 está nessa fase, não
      // terminado.
      concluida: estaConcluido(texto(p, 'status')),
    );
  }
}

/// Em que fase está uma obra.
class ProgressoObra {
  final int total;

  /// Fases já passadas.
  final int feitos;

  /// Fase atual, de 1 a [total].
  final int posicao;

  /// Nome da fase atual.
  final String nome;

  final bool concluida;

  const ProgressoObra({
    required this.total,
    required this.feitos,
    required this.posicao,
    required this.nome,
    this.concluida = false,
  });

  /// "Obra concluída" ou "Fase 2 de 4 · Estrutura".
  String get descricao =>
      concluida ? 'Obra concluída' : 'Fase $posicao de $total · $nome';
}
