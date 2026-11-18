import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/utils/portfolio.dart';

/// O ano de conclusão diz-se de maneira diferente conforme a obra já acabou.
///
/// Os empreendimentos concluídos apareciam com "Conclusão prevista: 2018" —
/// prédios entregues há anos, a ler-se como um atraso. Visto num teste no
/// telemóvel, contra o servidor a sério.
void main() {
  test('nos concluídos o ano já não é uma previsão', () {
    expect(Portfolio.conclusao('Concluído', '2018'), 'Concluído em 2018');
  });

  test('nos outros continua a ser', () {
    expect(Portfolio.conclusao('Construção', '2028'),
        'Conclusão prevista em 2028');
    expect(Portfolio.conclusao('Em desenvolvimento', '2029'),
        'Conclusão prevista em 2029');
  });

  test('sem estado conta como obra a andar, e o ano é previsão', () {
    expect(Portfolio.conclusao(null, '2027'), 'Conclusão prevista em 2027');
  });
}
