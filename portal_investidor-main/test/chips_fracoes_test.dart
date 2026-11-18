import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/sale_order.dart';
import 'package:portal_investidor/widgets/painel_aquisicao.dart';

void main() {
  testWidgets('as frações ficam lado a lado, do tamanho do texto',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          child: ChipsFracoes(['4.10(AH)', '5.1(AJ)', '5.4(AM)']),
        ),
      ),
    ));

    final a = tester.getRect(find.text('4.10(AH)'));
    final b = tester.getRect(find.text('5.1(AJ)'));
    // Na mesma linha: cada caixa esticava até à largura toda e ficavam uma
    // por linha.
    expect(b.top, a.top);
    final caixa = tester.getSize(find
        .ancestor(of: find.text('4.10(AH)'), matching: find.byType(Container))
        .first);
    // (Nos testes as letras são todas da largura do tamanho da letra, por
    // isso a caixa é mais larga do que no telemóvel; o que conta é não
    // ocupar a linha toda.)
    expect(caixa.width, lessThan(150));
  });

  testWidgets('com muitas, mostra as primeiras e um "Mostrar mais"',
      (tester) async {
    final nove = [for (var i = 1; i <= 9; i++) '5.$i'];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ChipsFracoes(nove)),
    ));

    expect(find.text('5.6'), findsOneWidget);
    expect(find.text('5.7'), findsNothing);
    expect(find.text('Mostrar mais (+3)'), findsOneWidget);

    await tester.tap(find.text('Mostrar mais (+3)'));
    await tester.pump();
    expect(find.text('5.9'), findsOneWidget);
    expect(find.text('Mostrar menos'), findsOneWidget);
  });

  testWidgets('com poucas, não há "Mostrar mais"', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: ChipsFracoes(['4.10(AH)'])),
    ));
    expect(find.textContaining('Mostrar'), findsNothing);
  });

  testWidgets('aquisições: mostra duas e um botão para as outras',
      (tester) async {
    final encomendas = [
      for (var i = 1; i <= 5; i++)
        SaleOrder(
          id: i,
          name: 'S$i',
          projectName: 'Obra',
          fractions: ['F$i'],
          amountTotal: 1000,
        ),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ListaAquisicoes(encomendas: encomendas, empreendimento: 'Obra'),
        ),
      ),
    ));

    expect(find.byType(CartaoAquisicao), findsNWidgets(2));
    await tester.tap(find.text('Mostrar todas as aquisições (+3)'));
    await tester.pump();
    expect(find.byType(CartaoAquisicao), findsNWidgets(5));
    expect(find.text('Mostrar menos'), findsOneWidget);
  });
}
