import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/widgets/co_auth.dart';

/// "Área Reservada" não se escreve duas vezes seguidas no ecrã de entrada.
///
/// A moldura dos ecrãs de autenticação põe uma sobrelinha a dizer onde a
/// pessoa está, que faz falta quando o título fala de outra coisa ("Criar
/// conta", "Recuperar acesso"). No ecrã de entrada o título já é esse, e
/// aparecia a mesma palavra duas vezes, uma pequena e outra grande.
int quantasVezes(WidgetTester tester, String procurado) {
  final alvo = procurado.toLowerCase();
  return tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => (t.data ?? '').toLowerCase() == alvo)
      .length;
}

void main() {
  Widget moldura(String titulo) => MaterialApp(
        home: CoAuthScaffold(titulo: titulo, filhos: const []),
      );

  testWidgets('no ecrã de entrada aparece uma vez só', (tester) async {
    await tester.pumpWidget(moldura('Área Reservada'));

    expect(quantasVezes(tester, 'Área reservada'), 1);
  });

  testWidgets('nos outros ecrãs a sobrelinha fica, porque situa a pessoa',
      (tester) async {
    await tester.pumpWidget(moldura('Criar conta'));

    expect(quantasVezes(tester, 'Área reservada'), 1);
    expect(find.text('Criar conta'), findsOneWidget);
  });
}
