import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/utils/ui_helpers.dart';

/// A etiqueta de estado comparava os valores por igualdade exata
/// ('Construção', 'Concluído'), mas a API manda "Em construção" e
/// "Em desenvolvimento" — caía sempre no ramo de recurso. Estes testes
/// garantem que as escritas verdadeiras da API são reconhecidas.
Future<void> mostrar(WidgetTester tester, String estado) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: UIHelpers.buildStatusBadge(estado))),
    ),
  );
}

void main() {
  testWidgets('mostra o estado tal como a API o escreve', (tester) async {
    for (final estado in [
      'Em construção',
      'Em desenvolvimento',
      'Concluído',
      'Em comercialização',
    ]) {
      await mostrar(tester, estado);
      expect(
        find.text(estado.toUpperCase()),
        findsOneWidget,
        reason: 'não mostrou "$estado"',
      );
    }
  });

  testWidgets('cada grupo de estado tem o seu ponto de cor', (tester) async {
    final cores = <String, Color>{};

    for (final estado in ['Em construção', 'Em desenvolvimento', 'Concluído']) {
      await mostrar(tester, estado);
      final ponto = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Row),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoracao = ponto.decoration as BoxDecoration;
      cores[estado] = decoracao.color!;
    }

    // Se os três caírem no mesmo ramo (o bug antigo), as cores repetem-se.
    expect(cores.values.toSet().length, 3);
  });

  testWidgets('um estado vazio não deixa uma etiqueta vazia no cartão',
      (tester) async {
    await mostrar(tester, '');
    expect(find.byType(Row), findsNothing);
  });
}
