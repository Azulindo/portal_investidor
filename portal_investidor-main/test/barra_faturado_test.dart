import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/sale_order.dart';
import 'package:portal_investidor/theme/co_colors.dart';
import 'package:portal_investidor/widgets/secao_encomendas.dart';

/// A barra das encomendas tem de aparecer mesmo.
///
/// Este teste existe por causa de um erro concreto: a barra estava dentro de
/// um SizedBox sem largura, numa Column alinhada a esquerda. Um Row que so
/// tem Expanded nao tem largura propria, por isso a barra encolhia para zero
/// e desaparecia — sem erro nenhum, sem aviso, e com a legenda ao lado a
/// dizer que la estava. Analyze e os testes de calculo passavam todos.
void main() {
  Future<void> mostrar(WidgetTester tester, SaleOrder encomenda) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: COColors.brand900,
          body: SingleChildScrollView(
            child: SecaoEncomendas(encomendas: [encomenda]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// As fatias da barra, pela cor com que sao pintadas.
  Iterable<Size> fatias(WidgetTester tester, Color cor) => tester
      .widgetList<ColoredBox>(find.byType(ColoredBox))
      .where((c) => c.color == cor)
      .map((c) => tester.getSize(find.byWidget(c)));

  SaleOrder encomenda(double total, List<Invoice> faturas) => SaleOrder(
        id: 1,
        name: 'SO0001',
        amountTotal: total,
        date: '2026-01-15',
        invoices: faturas,
      );

  Invoice fatura(String estado, double total, {double residual = 0}) => Invoice(
        id: 1,
        name: 'INV',
        date: '2026-01-20',
        paymentState: estado,
        amountTotal: total,
        amountResidual: residual,
      );

  testWidgets('a fatia do pago tem largura', (tester) async {
    await mostrar(tester, encomenda(1000, [fatura('paid', 1000)]));

    final pagas = fatias(tester, COColors.accent).toList();
    expect(pagas, isNotEmpty, reason: 'a barra nao chegou a ser pintada');
    expect(pagas.first.width, greaterThan(0), reason: 'a barra encolheu');
    expect(pagas.first.height, 4);
  });

  testWidgets('tudo pago nao deixa fatias das outras cores', (tester) async {
    await mostrar(tester, encomenda(1000, [fatura('paid', 1000)]));

    expect(fatias(tester, COColors.brand300), isEmpty);
    expect(fatias(tester, COColors.brand700), isEmpty);
  });

  testWidgets('metade paga divide a barra em duas', (tester) async {
    // 1000 de encomenda, 500 faturados e pagos: metade accent, metade por
    // faturar. As duas juntas tem de dar a largura toda.
    await mostrar(tester, encomenda(1000, [fatura('paid', 500)]));

    final pago = fatias(tester, COColors.accent).single;
    final porFaturar = fatias(tester, COColors.brand700).single;

    expect(pago.width, greaterThan(0));
    expect(porFaturar.width, greaterThan(0));
    expect((pago.width - porFaturar.width).abs(), lessThan(1));
  });

  testWidgets('faturado e por pagar mostra a fatia do meio e a legenda',
      (tester) async {
    await mostrar(tester, encomenda(1000, [fatura('not_paid', 400)]));

    expect(fatias(tester, COColors.brand300).single.width, greaterThan(0));
    expect(fatias(tester, COColors.accent), isEmpty);
    expect(find.textContaining('faturado, por pagar'), findsOneWidget);
  });

  testWidgets('sem a fatia do meio nao ha legenda a explicá-la',
      (tester) async {
    await mostrar(tester, encomenda(1000, [fatura('paid', 1000)]));
    expect(find.textContaining('faturado, por pagar'), findsNothing);
  });
}
