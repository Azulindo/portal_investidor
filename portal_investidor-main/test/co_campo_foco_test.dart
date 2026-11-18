import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/widgets/co_auth.dart';

void main() {
  testWidgets('o "Seguinte" do teclado passa ao campo de baixo, não ao olho',
      (tester) async {
    final a = TextEditingController();
    final b = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          CoCampo(controller: a, etiqueta: 'Atual', password: true),
          CoCampo(controller: b, etiqueta: 'Nova', password: true),
        ]),
      ),
    ));

    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    // O que se escreve a seguir tem de ir parar ao segundo campo.
    tester.testTextInput.enterText('x');
    await tester.pump();
    expect(b.text, 'x', reason: 'o foco devia estar no segundo campo');
    expect(a.text, isEmpty);
  });
}
