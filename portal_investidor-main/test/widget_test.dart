import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/main.dart';

void main() {
  testWidgets('Teste de arranque da app Cleveroption', (
    WidgetTester tester,
  ) async {
    // Inicia a aplicação
    await tester.pumpWidget(const CleverOptionApp());

    // Verifica se a app arranca sem crashar
    expect(find.byType(CleverOptionApp), findsOneWidget);
  });
}
