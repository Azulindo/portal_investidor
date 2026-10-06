import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/utils/portfolio.dart';

/// As mesmas contas do portfólio do site (statusGroup,
/// ordenarPorComercializacao e progressoObra em lib/testApi.ts). Se
/// divergirem, a app e o site mostram os empreendimentos por ordens
/// diferentes e com contagens diferentes.
Map proj({
  int id = 1,
  String nome = 'Projeto',
  String cidade = 'Porto',
  String estado = 'Em construção',
  bool aVenda = false,
  int? fracoes,
  String? fim,
  int? passoAtual,
  List<Map> passos = const [],
}) {
  return {
    'id': id,
    'name': nome,
    'city': cidade,
    'status': estado,
    'forSale': aVenda,
    'nFractions': fracoes,
    'endDate': fim,
    'currentStep': passoAtual,
    'steps': passos,
  };
}

List<Map> passos(int quantos) => [
      for (var i = 1; i <= quantos; i++)
        {'id': i, 'stepOrder': i, 'name': 'Fase $i'},
    ];

void main() {
  group('grupo de estado', () {
    test('reconhece as várias escritas que a API usa', () {
      expect(Portfolio.grupoDeEstado('Concluído'), 'concluido');
      expect(Portfolio.grupoDeEstado('concluido'), 'concluido');
      expect(Portfolio.grupoDeEstado('Em desenvolvimento'), 'desenvolvimento');
      expect(Portfolio.grupoDeEstado('Desenvolvimento'), 'desenvolvimento');
      // Tudo o que não é um dos outros dois conta como obra a andar.
      expect(Portfolio.grupoDeEstado('Em construção'), 'ativo');
      expect(Portfolio.grupoDeEstado('Construção'), 'ativo');
      expect(Portfolio.grupoDeEstado('Em comercialização'), 'ativo');
      expect(Portfolio.grupoDeEstado(null), 'ativo');
      expect(Portfolio.grupoDeEstado(''), 'ativo');
    });
  });

  group('ordem de apresentação', () {
    test('quem está em comercialização vem primeiro', () {
      final r = Portfolio.ordenarPorComercializacao([
        proj(id: 1, nome: 'Sem venda', aVenda: false, fracoes: 100),
        proj(id: 2, nome: 'Com venda', aVenda: true, fracoes: 2),
      ]);
      expect(r.first['name'], 'Com venda');
    });

    test('a seguir os maiores', () {
      final r = Portfolio.ordenarPorComercializacao([
        proj(id: 1, nome: 'Pequeno', aVenda: true, fracoes: 4),
        proj(id: 2, nome: 'Grande', aVenda: true, fracoes: 40),
      ]);
      expect(r.map((p) => p['name']), ['Grande', 'Pequeno']);
    });

    test('depois a conclusão mais próxima', () {
      final r = Portfolio.ordenarPorComercializacao([
        proj(id: 1, nome: 'Tarde', aVenda: true, fracoes: 10, fim: '2030-12-31'),
        proj(id: 2, nome: 'Cedo', aVenda: true, fracoes: 10, fim: '2026-06-30'),
      ]);
      expect(r.map((p) => p['name']), ['Cedo', 'Tarde']);
    });

    test('sem data de fim vai para o fim, e não para a frente', () {
      final r = Portfolio.ordenarPorComercializacao([
        proj(id: 1, nome: 'Sem data', aVenda: true, fracoes: 10),
        proj(id: 2, nome: 'Com data', aVenda: true, fracoes: 10, fim: '2030-01-01'),
      ]);
      expect(r.map((p) => p['name']), ['Com data', 'Sem data']);
    });

    test('em último o nome, para a ordem não mudar entre carregamentos', () {
      final r = Portfolio.ordenarPorComercializacao([
        proj(id: 1, nome: 'Zebra', aVenda: true, fracoes: 10, fim: '2027-01-01'),
        proj(id: 2, nome: 'Arco', aVenda: true, fracoes: 10, fim: '2027-01-01'),
      ]);
      expect(r.map((p) => p['name']), ['Arco', 'Zebra']);
    });

    test('não mexe na lista original', () {
      final original = [proj(id: 1, nome: 'A'), proj(id: 2, nome: 'B', aVenda: true)];
      Portfolio.ordenarPorComercializacao(original);
      expect(original.first['name'], 'A');
    });
  });

  group('filtros e contagens', () {
    final lista = [
      proj(id: 1, cidade: 'Porto', estado: 'Em construção', aVenda: true, fracoes: 10),
      proj(id: 2, cidade: 'Vila Nova de Gaia', estado: 'Concluído', fracoes: 20),
      proj(id: 3, cidade: 'Porto', estado: 'Em desenvolvimento', fracoes: 5),
      proj(id: 4, cidade: 'Porto', estado: 'Em construção', aVenda: true, fracoes: 7),
    ];

    test('cidades distintas por ordem', () {
      expect(Portfolio.cidades(lista), ['Porto', 'Vila Nova de Gaia']);
    });

    test('filtra por grupo, cidade e comercialização', () {
      expect(Portfolio.filtrar(lista, grupo: 'ativo').length, 2);
      expect(Portfolio.filtrar(lista, cidade: 'Porto').length, 3);
      expect(Portfolio.filtrar(lista, apenasAVenda: true).length, 2);
    });

    test('os filtros acumulam', () {
      final r = Portfolio.filtrar(lista, cidade: 'Porto', apenasAVenda: true);
      expect(r.map((p) => p['id']), [1, 4]);
    });

    test('contagens por grupo e total de frações', () {
      expect(Portfolio.quantosNoGrupo(lista, 'ativo'), 2);
      expect(Portfolio.quantosNoGrupo(lista, 'concluido'), 1);
      expect(Portfolio.quantosNoGrupo(lista, 'desenvolvimento'), 1);
      expect(Portfolio.totalFracoes(lista), 42);
    });

    test('empreendimentos sem nFractions não estragam o total', () {
      expect(Portfolio.totalFracoes([proj(fracoes: null), proj(fracoes: 5)]), 5);
    });
  });

  group('progresso da obra', () {
    test('diz a fase, o nome e quantas já passaram', () {
      final p = Portfolio.progresso(proj(passos: passos(4), passoAtual: 2))!;
      expect(p.total, 4);
      expect(p.posicao, 2);
      expect(p.feitos, 1);
      expect(p.nome, 'Fase 2');
      expect(p.descricao, 'Fase 2 de 4 · Fase 2');
    });

    test('sem timeline ou sem fase atual não mostra nada', () {
      expect(Portfolio.progresso(proj(passos: const [], passoAtual: 2)), isNull);
      expect(Portfolio.progresso(proj(passos: passos(3))), isNull);
    });

    test('um stepOrder que não existe conta as que ficaram para trás', () {
      // Em vez de desistir: com fases 1,2,3 e currentStep 7, já passaram as 3.
      final p = Portfolio.progresso(proj(passos: passos(3), passoAtual: 7))!;
      expect(p.posicao, 3);
    });

    test('um currentStep abaixo da primeira fase fica na primeira', () {
      final p = Portfolio.progresso(proj(passos: passos(3), passoAtual: 0))!;
      expect(p.posicao, 1);
    });

    test('as fases ordenam-se por stepOrder, não pela ordem da resposta', () {
      final p = Portfolio.progresso(proj(
        passoAtual: 2,
        passos: [
          {'id': 3, 'stepOrder': 3, 'name': 'Acabamentos'},
          {'id': 1, 'stepOrder': 1, 'name': 'Licenciamento'},
          {'id': 2, 'stepOrder': 2, 'name': 'Estrutura'},
        ],
      ))!;
      expect(p.nome, 'Estrutura');
    });

    test('concluída vem do estado do projeto e não do currentStep', () {
      // Um projeto com uma só fase e currentStep 1 está nessa fase, não
      // terminado — é por isso que não se olha para o currentStep.
      final aAndar = Portfolio.progresso(
        proj(estado: 'Em construção', passos: passos(1), passoAtual: 1),
      )!;
      expect(aAndar.concluida, isFalse);
      expect(aAndar.descricao, 'Fase 1 de 1 · Fase 1');

      final acabada = Portfolio.progresso(
        proj(estado: 'Concluído', passos: passos(4), passoAtual: 2),
      )!;
      expect(acabada.concluida, isTrue);
      expect(acabada.descricao, 'Obra concluída');
    });
  });

  group('leitura dos campos', () {
    test('só o ano da data de conclusão', () {
      expect(Portfolio.anoFim(proj(fim: '2028-12-31')), '2028');
      expect(Portfolio.anoFim(proj(fim: null)), isNull);
    });

    test('valores em texto, como a API às vezes manda', () {
      expect(Portfolio.inteiro({'nFractions': '12'}, 'nFractions'), 12);
      expect(Portfolio.inteiro({'nFractions': null}, 'nFractions'), isNull);
    });
  });
}
