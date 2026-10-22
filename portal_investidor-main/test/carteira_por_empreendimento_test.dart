import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/sale_order.dart';
import 'package:portal_investidor/utils/carteira.dart';

/// O painel passou a mostrar o investido e o por pagar dentro do cartao de
/// cada empreendimento, alem do total la em cima. Sao duas contas a partir
/// da mesma lista de encomendas, e se nao fecharem a app mostra dinheiro
/// que nao bate certo consigo proprio — o pior erro que esta app pode ter.
///
/// Os numeros sao os dos dados de exemplo: Aires Ornelas com duas
/// encomendas (185 000 com 142 500 pagos, e 12 000 sem nada pago) e Quinta
/// das Laranjeiras com uma de 240 000 sem faturas.
SaleOrder _encomenda({
  required int id,
  required String projeto,
  required double total,
  required List<String> fracoes,
  List<Invoice> faturas = const [],
}) {
  return SaleOrder(
    id: id,
    name: 'SO000$id',
    projectName: projeto,
    fractions: fracoes,
    amountTotal: total,
    date: '2026-01-15',
    invoices: faturas,
  );
}

Invoice _fatura({required double total, required double residual}) {
  return Invoice(
    id: 1,
    name: 'FT 2026/1',
    date: '2026-01-20',
    paymentState: 'partial',
    amountTotal: total,
    amountResidual: residual,
    attachments: const [],
  );
}

void main() {
  final aires1 = _encomenda(
    id: 1,
    projeto: 'Aires Ornelas',
    total: 185000,
    fracoes: ['A', 'B'],
    faturas: [_fatura(total: 185000, residual: 42500)],
  );
  final aires2 = _encomenda(
    id: 2,
    projeto: 'Aires Ornelas',
    total: 12000,
    fracoes: ['B'],
  );
  final quinta = _encomenda(
    id: 3,
    projeto: 'Quinta das Laranjeiras',
    total: 240000,
    fracoes: ['1.ºD'],
  );
  final todas = [aires1, aires2, quinta];

  group('contas por empreendimento', () {
    test('doEmpreendimento apanha as encomendas certas', () {
      expect(Carteira.doEmpreendimento('Aires Ornelas', todas).length, 2);
      expect(
        Carteira.doEmpreendimento('Quinta das Laranjeiras', todas).length,
        1,
      );
    });

    test('a soma dos empreendimentos da o total da carteira', () {
      final aires =
          Carteira.investimentoTotal(Carteira.doEmpreendimento('Aires Ornelas', todas));
      final q = Carteira.investimentoTotal(
          Carteira.doEmpreendimento('Quinta das Laranjeiras', todas));

      expect(aires, 197000);
      expect(q, 240000);
      // E isto que nao pode partir: o cartao mais o cartao tem de dar o
      // numero grande do cabecalho.
      expect(aires + q, Carteira.investimentoTotal(todas));
    });

    test('o por pagar tambem fecha, cartao a cartao', () {
      final aires =
          Carteira.totalPorPagar(Carteira.doEmpreendimento('Aires Ornelas', todas));
      final q = Carteira.totalPorPagar(
          Carteira.doEmpreendimento('Quinta das Laranjeiras', todas));

      expect(aires, 54500);
      expect(q, 240000);
      expect(aires + q, Carteira.totalPorPagar(todas));
      expect(aires + q, 294500);
    });

    test('a mesma fracao em duas encomendas conta uma vez', () {
      // A fracao B aparece nas duas encomendas do Aires Ornelas. Sao tres
      // fracoes no total e nao quatro.
      final doAires = Carteira.doEmpreendimento('Aires Ornelas', todas);
      final fracoes = doAires.expand((o) => o.fractions).toSet();
      expect(fracoes.length, 2);
      expect(
        todas.expand((o) => o.fractions).toSet().length,
        3,
      );
    });

    test('o nome junta-se mesmo vindo escrito de maneira diferente', () {
      // O nome chega por dois caminhos: o app_project.name do /user/:id e o
      // projectName do /document/sale-orders. Nada garante que venham
      // iguais ao caracter. Se esta juncao falhar, o cartao aparece sem
      // dinheiro nenhum e a soma dos cartoes deixa de dar o cabecalho —
      // que e o erro que os outros testes deste ficheiro guardam.
      for (final variante in [
        'Aires Ornelas ',
        ' Aires Ornelas',
        'aires ornelas',
        'AIRES ORNELAS',
        'Aires  Ornelas',
      ]) {
        expect(
          Carteira.doEmpreendimento(variante, todas).length,
          2,
          reason: 'nao juntou "$variante"',
        );
      }
    });

    test('nomes diferentes continuam diferentes', () {
      // O acento nao se ignora: sao nomes diferentes e devem falhar a
      // vista, em vez de se juntarem em silencio.
      expect(Carteira.mesmoProjeto('Aires Ornelas', 'Aires Ornélas'), isFalse);
      expect(Carteira.mesmoProjeto('Aires Ornelas', 'Quinta das Laranjeiras'),
          isFalse);
    });

    test('um empreendimento sem encomendas da zero e nao rebenta', () {
      final nenhuma = Carteira.doEmpreendimento('Projeto Que Nao Existe', todas);
      expect(nenhuma, isEmpty);
      expect(Carteira.investimentoTotal(nenhuma), 0);
      expect(Carteira.totalPorPagar(nenhuma), 0);
      expect(Carteira.percentagemPaga(nenhuma), 0);
    });
  });
}
