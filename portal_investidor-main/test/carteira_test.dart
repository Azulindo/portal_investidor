import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/sale_order.dart';
import 'package:portal_investidor/utils/carteira.dart';

/// Estes testes são os mais importantes da app: é aqui que se decide o
/// dinheiro que a pessoa vê. As contas têm de dar exatamente o mesmo que o
/// portal do site (components/PortalDashboard.tsx) — se divergirem, a app e o
/// site mostram valores diferentes à mesma pessoa.
Invoice fatura({
  int id = 1,
  String? estado = 'paid',
  double total = 1000,
  double residual = 0,
}) {
  return Invoice(
    id: id,
    name: 'INV/$id',
    date: '2026-01-01',
    paymentState: estado,
    amountTotal: total,
    amountResidual: residual,
  );
}

SaleOrder encomenda({
  int id = 1,
  String projeto = 'Projeto A',
  List<String> fracoes = const ['A'],
  double total = 1000,
  List<Invoice> faturas = const [],
}) {
  return SaleOrder(
    id: id,
    name: 'SO$id',
    projectName: projeto,
    fractions: fracoes,
    amountTotal: total,
    date: '2026-01-01',
    invoices: faturas,
  );
}

void main() {
  group('o que conta como pago numa fatura', () {
    test('uma fatura paga conta o total', () {
      expect(fatura(estado: 'paid', total: 1000, residual: 0).pago, 1000);
    });

    test('uma parcial conta a parte liquidada', () {
      expect(fatura(estado: 'partial', total: 1000, residual: 400).pago, 600);
    });

    test('nas outras conta zero, mesmo com residual zero', () {
      // É esta a razão de ser da regra: no Odoo umas faturas não pagas trazem
      // residual = total e outras trazem residual = 0. Se se usasse
      // "total - residual" em todas, estas ultimas apareciam como pagas.
      expect(fatura(estado: 'not_paid', total: 1000, residual: 0).pago, 0);
      expect(fatura(estado: 'not_paid', total: 1000, residual: 1000).pago, 0);
      expect(fatura(estado: 'in_payment', total: 1000, residual: 0).pago, 0);
      expect(fatura(estado: 'reversed', total: 1000, residual: 0).pago, 0);
      expect(fatura(estado: null, total: 1000, residual: 0).pago, 0);
    });

    test('a etiqueta do estado em português', () {
      expect(fatura(estado: 'paid').estado, 'Paga');
      expect(fatura(estado: 'partial').estado, 'Parcial');
      expect(fatura(estado: 'in_payment').estado, 'Em pagamento');
      expect(fatura(estado: 'reversed').estado, 'Estornada');
      // Sem estado trata-se como por pagar, que é o lado seguro.
      expect(fatura(estado: null).estado, 'Por pagar');
    });
  });

  group('totais', () {
    final encomendas = [
      encomenda(
        id: 1,
        total: 100000,
        faturas: [
          fatura(id: 1, estado: 'paid', total: 50000, residual: 0),
          fatura(id: 2, estado: 'partial', total: 50000, residual: 20000),
        ],
      ),
      encomenda(
        id: 2,
        total: 40000,
        faturas: [fatura(id: 3, estado: 'not_paid', total: 40000, residual: 40000)],
      ),
    ];

    test('investimento total é a soma das encomendas', () {
      expect(Carteira.investimentoTotal(encomendas), 140000);
    });

    test('pago soma só o que está liquidado', () {
      // 50000 da paga + 30000 da parcial. A não paga não conta.
      expect(Carteira.totalPago(encomendas), 80000);
    });

    test('por pagar é o que falta, e reconcilia com os outros dois', () {
      expect(Carteira.totalPorPagar(encomendas), 60000);
      expect(
        Carteira.totalPago(encomendas) + Carteira.totalPorPagar(encomendas),
        Carteira.investimentoTotal(encomendas),
      );
    });

    test('percentagem arredondada', () {
      expect(Carteira.percentagemPaga(encomendas), 57); // 80000/140000
    });

    test('sem encomendas dá zeros e não uma divisão por zero', () {
      expect(Carteira.investimentoTotal([]), 0);
      expect(Carteira.percentagemPaga([]), 0);
    });

    test('encomendas a zero também não rebentam a percentagem', () {
      expect(Carteira.percentagemPaga([encomenda(total: 0)]), 0);
    });

    test('uma encomenda sem faturas conta como nada pago', () {
      final so = [encomenda(total: 240000, faturas: const [])];
      expect(Carteira.investimentoTotal(so), 240000);
      expect(Carteira.totalPago(so), 0);
      expect(Carteira.percentagemPaga(so), 0);
    });
  });

  group('carteira por empreendimento', () {
    test('conta as frações de cada um', () {
      final linhas = Carteira.porEmpreendimento(
        ['Projeto A', 'Projeto B'],
        [
          encomenda(id: 1, projeto: 'Projeto A', fracoes: ['A', 'B']),
          encomenda(id: 2, projeto: 'Projeto B', fracoes: ['1.ºD']),
        ],
      );

      expect(linhas.map((l) => l.empreendimento), ['Projeto A', 'Projeto B']);
      expect(linhas.map((l) => l.fracoes), [2, 1]);
      expect(Carteira.totalFracoes(linhas), 3);
    });

    test('a mesma fração em duas encomendas conta uma vez', () {
      // Acontece com reforços e alterações ao contrato. Contá-la duas vezes
      // dava uma carteira maior do que a verdadeira.
      final linhas = Carteira.porEmpreendimento(
        ['Projeto A'],
        [
          encomenda(id: 1, projeto: 'Projeto A', fracoes: ['A', 'B']),
          encomenda(id: 2, projeto: 'Projeto A', fracoes: ['B']),
        ],
      );
      expect(linhas.single.fracoes, 2);
    });

    test('um empreendimento sem encomendas aparece com zero frações', () {
      final linhas = Carteira.porEmpreendimento(['Projeto C'], []);
      expect(linhas.single.fracoes, 0);
    });

    test('encomendas de um projeto que não está na lista não desaparecem dos totais', () {
      // A carteira mostra os projetos do cliente, mas o investimento total sai
      // das encomendas todas — senão os números deixavam de bater.
      final encomendas = [encomenda(projeto: 'Projeto Z', total: 5000)];
      expect(Carteira.porEmpreendimento(['Projeto A'], encomendas).single.fracoes, 0);
      expect(Carteira.investimentoTotal(encomendas), 5000);
    });
  });

  group('formatação', () {
    test('euros com separador de milhares e sem cêntimos', () {
      expect(Carteira.euros(185000), '185 000 €');
      expect(Carteira.euros(950), '950 €');
      expect(Carteira.euros(1250000.49), '1 250 000 €');
    });

    test('um valor negativo mantém o sinal', () {
      // Não devia acontecer, mas se a API mandar um pago maior que o total,
      // é melhor ver "-500 €" do que "500 €".
      expect(Carteira.euros(-500), '-500 €');
    });

    test('singular e plural', () {
      expect(Carteira.contagem(1, 'fração', 'frações'), '1 fração');
      expect(Carteira.contagem(3, 'empreendimento', 'empreendimentos'),
          '3 empreendimentos');
    });

    test('datas do Odoo', () {
      expect(Carteira.data('2026-03-14'), '14/03/2026');
      expect(Carteira.data('2026-03-14T10:30:00Z'), '14/03/2026');
      expect(Carteira.data(''), '—');
      // Ilegível devolve-se como veio: pelo menos diz alguma coisa.
      expect(Carteira.data('qualquer coisa'), 'qualquer coisa');
    });
  });

  group('leitura da resposta da API', () {
    test('os valores em texto que a API manda viram números', () {
      // As colunas de dinheiro são "numeric" na base de dados, o que em JSON
      // chega como texto.
      final o = SaleOrder.fromJson({
        'id': '7',
        'name': 'SO0007',
        'projectName': 'Projeto A',
        'fractions': ['A', 'B'],
        'amountTotal': '185000.00',
        'date': '2026-01-15',
        'invoices': [
          {
            'id': '70',
            'name': 'INV/1',
            'date': '2026-01-20',
            'paymentState': 'partial',
            'amountTotal': '92500.00',
            'amountResidual': '42500.00',
            'attachments': [
              {'id': '5', 'name': 'f.pdf', 'mimetype': 'application/pdf'},
            ],
          },
        ],
      });

      expect(o.id, 7);
      expect(o.amountTotal, 185000);
      expect(o.fractions, ['A', 'B']);
      expect(o.invoices.single.amountResidual, 42500);
      expect(o.invoices.single.pago, 50000);
      expect(o.invoices.single.attachments.single.name, 'f.pdf');
      expect(o.pago, 50000);
      expect(o.porPagar, 135000);
    });

    test('uma resposta sem listas não rebenta', () {
      final o = SaleOrder.fromJson({'id': 1, 'name': 'SO1'});
      expect(o.fractions, isEmpty);
      expect(o.invoices, isEmpty);
      expect(o.amountTotal, 0);
      expect(o.pago, 0);
    });
  });
}
