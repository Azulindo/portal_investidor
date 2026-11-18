import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/sale_order.dart';

/// As três fatias da barra de uma encomenda.
///
/// A regra vem do site (invoicePaid e invoiceIssued em PortalDashboard.tsx) e
/// tem de continuar igual à de lá: se as duas discordarem, o mesmo investidor
/// vê números diferentes no site e na app.
void main() {
  Invoice fatura(
    String estado, {
    double total = 1000,
    double residual = 0,
    List<String> linhas = const [],
  }) =>
      Invoice(
        id: 1,
        name: 'INV',
        date: '2026-01-01',
        paymentState: estado,
        amountTotal: total,
        amountResidual: residual,
        description: linhas,
      );

  SaleOrder encomenda(double total, List<Invoice> faturas) =>
      SaleOrder(id: 1, name: 'SO', amountTotal: total, invoices: faturas);

  group('Quanto foi faturado', () {
    test('uma fatura estornada nao conta como faturada', () {
      // Foi anulada por nota de credito, e as notas de credito a API nao
      // devolve. Conta-la mostrava uma divida que ja nao existe.
      expect(fatura('reversed').faturado, 0);
      expect(fatura('not_paid').faturado, 1000);
      expect(fatura('paid').faturado, 1000);
    });
  });

  group('As tres fatias da barra', () {
    test('tudo pago deixa a barra so com a primeira fatia', () {
      final o = encomenda(1000, [fatura('paid', total: 1000)]);
      expect(o.pago, 1000);
      expect(o.faturadoPorPagar, 0);
      expect(o.porFaturar, 0);
    });

    test('faturado e por pagar enche o meio', () {
      final o = encomenda(1000, [fatura('not_paid', total: 400)]);
      expect(o.pago, 0);
      expect(o.faturadoPorPagar, 400);
      expect(o.porFaturar, 600);
    });

    test('uma encomenda sem faturas e toda por faturar', () {
      final o = encomenda(1000, []);
      expect(o.pago, 0);
      expect(o.faturadoPorPagar, 0);
      expect(o.porFaturar, 1000);
    });

    test('uma fatura parcial divide-se entre as duas primeiras fatias', () {
      final o = encomenda(
        1000,
        [fatura('partial', total: 600, residual: 250)],
      );
      expect(o.pago, 350);
      expect(o.faturadoPorPagar, 250);
      expect(o.porFaturar, 400);
    });

    test('sobrefaturada, a barra nao passa dos 100%', () {
      // Uma encomenda de 1000 com 1500 faturados existe, e sem o limite a
      // fatia do meio empurrava a barra para fora do ecra.
      final o = encomenda(1000, [fatura('not_paid', total: 1500)]);
      expect(o.faturadoPorPagar, 1000);
      expect(o.porFaturar, 0);
      expect(o.pago + o.faturadoPorPagar + o.porFaturar, 1000);
    });

    test('as tres fatias somam sempre o total da encomenda', () {
      final casos = [
        encomenda(1000, [fatura('paid', total: 1000)]),
        encomenda(1000, [fatura('not_paid', total: 400)]),
        encomenda(1000, [fatura('partial', total: 600, residual: 250)]),
        encomenda(1000, [fatura('reversed', total: 1000)]),
        encomenda(1000, []),
      ];
      for (final o in casos) {
        expect(o.pago + o.faturadoPorPagar + o.porFaturar, 1000);
      }
    });
  });

  group('Descricao da fatura', () {
    test('junta as linhas de artigo numa linha so', () {
      final f = fatura('paid', linhas: const ['1.ª tranche', 'Extras']);
      expect(f.descricao, '1.ª tranche  ·  Extras');
    });

    test('uma fatura sem linhas nao deixa separadores soltos', () {
      expect(fatura('paid').descricao, '');
    });

    test('linhas vazias da API nao chegam ao ecra', () {
      final f = Invoice.fromJson(const {
        'id': 1,
        'name': 'INV',
        'date': '2026-01-01',
        'description': ['  ', 'Tranche única', ''],
      });
      expect(f.description, ['Tranche única']);
    });
  });
}
