import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/user_model.dart';
import 'package:portal_investidor/widgets/secao_fracoes.dart';

/// A lista de frações abre por lotes.
///
/// Há empreendimentos com 130 frações. Abri-las todas de uma vez fazia uma
/// página sem fim: a pessoa arrastava e arrastava sem chegar ao que vem a
/// seguir. Mostram-se vinte, e o resto é a pedido.
List<ProjectFraction> fracoes(int quantas) => [
      for (var i = 1; i <= quantas; i++)
        ProjectFraction(
          fractionId: i,
          projectId: 1,
          fractionNumber: 'A$i',
          type: 'T1',
          status: 'Disponível',
          totalArea: 60,
        ),
    ];

void main() {
  Future<void> abrir(WidgetTester tester, int quantas) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SecaoFracoes(fracoes: fracoes(quantas)),
          ),
        ),
      ),
    );

    await tester.tap(find.textContaining('Ver todas'));
    await tester.pump();
  }

  testWidgets('com 130 frações mostra as primeiras vinte', (tester) async {
    await abrir(tester, 130);

    // 130 menos as 20 do primeiro lote.
    expect(find.text('Mostrar mais 20 — faltam 110'), findsOneWidget);
  });

  testWidgets('pedir mais traz o lote seguinte', (tester) async {
    await abrir(tester, 130);

    // O botão está no fim da lista, fora do ecrã do teste.
    await tester.ensureVisible(find.textContaining('Mostrar mais'));
    await tester.pump();
    await tester.tap(find.textContaining('Mostrar mais'));
    await tester.pump();

    expect(find.text('Mostrar mais 20 — faltam 90'), findsOneWidget);
  });

  testWidgets('o último lote diz quantas faltam, e não vinte', (tester) async {
    await abrir(tester, 25);

    expect(find.text('Mostrar mais 5 — faltam 5'), findsOneWidget);
  });

  testWidgets('com poucas frações não aparece botão nenhum', (tester) async {
    await abrir(tester, 8);

    expect(find.textContaining('Mostrar mais'), findsNothing);
  });
}
