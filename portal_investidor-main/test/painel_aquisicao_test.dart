import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/sale_order.dart';

Invoice _fatura(String estado, double total, {double residual = 0}) =>
    Invoice(
      id: 1,
      name: 'F',
      date: '2026-01-01',
      paymentState: estado,
      amountTotal: total,
      amountResidual: residual,
    );

void main() {
  group('percentagens da barra (como no site)', () {
    test('pago 10%, faturado até 25%', () {
      // O caso do "4.10(AH)" no portal: 19 950 pagos, 29 925 faturados por
      // pagar, de 199 500.
      final o = SaleOrder(id: 1, name: 'S1', amountTotal: 199500, invoices: [
        _fatura('paid', 19950),
        _fatura('not_paid', 29925),
      ]);
      expect(o.percentagemPaga, 10);
      expect(o.percentagemFaturada, 25);
      expect(o.porFaturar, 149625);
    });

    test('sem nada pago o primeiro marcador fica nos 0%', () {
      final o = SaleOrder(id: 1, name: 'S1', amountTotal: 240350, invoices: [
        _fatura('not_paid', 60088),
      ]);
      expect(o.percentagemPaga, 0);
      expect(o.percentagemFaturada, 25);
    });

    test('encomenda a zero não divide por zero', () {
      final o = SaleOrder(id: 1, name: 'S1');
      expect(o.percentagemPaga, 0);
      expect(o.percentagemFaturada, 0);
    });
  });

  test('frações por ordem natural e sem repetições', () {
    expect(
      SaleOrder.ordenarFracoes(['5.10(AS)', '5.9(AR)', '4.10(AH)', '5.1(AJ)',
          '5.9(AR)']),
      ['4.10(AH)', '5.1(AJ)', '5.9(AR)', '5.10(AS)'],
    );
  });

  test('lê o CPCV das frações, e uma API sem o campo dá lista vazia', () {
    final com = SaleOrder.fromJson({
      'id': 1,
      'name': 'S1',
      'cpcv': [
        {'fractionId': 77, 'fraction': '4.10(AH)'},
        {'fractionId': null, 'fraction': 'sem id'},
      ],
    });
    expect(com.cpcv, hasLength(1));
    expect(com.cpcv.first.fractionId, 77);
    expect(com.cpcv.first.fracao, '4.10(AH)');

    expect(SaleOrder.fromJson({'id': 2, 'name': 'S2'}).cpcv, isEmpty);
  });

  test('as linhas da fatura perdem o código de conta do Odoo', () {
    final f = Invoice(
      id: 1,
      name: 'F',
      date: '',
      description: ['[721] Contratos de empreitada Montanha', 'Sinal', '[9] '],
    );
    expect(f.linhas, ['Contratos de empreitada Montanha', 'Sinal']);
  });
}
