import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/notificacao.dart';
import 'package:portal_investidor/screens/documents_screen.dart';
import 'package:portal_investidor/screens/portfolio_screen.dart';
import 'package:portal_investidor/screens/project_details_screen.dart';
import 'package:portal_investidor/utils/destino_notificacao.dart';

// O formato do `data` das notificacoes push, como o Miguel o descreveu
// (API_CONTRACT.md, seccao 7): tudo em texto, projectId so as vezes.
void main() {
  test('le os campos que vem em texto', () {
    final p = NotificacaoPush.deDados({
      'notificationId': '42',
      'type': 'obra',
      'projectId': '7',
    });
    expect(p.notificationId, 42);
    expect(p.tipo, TipoNotificacao.obra);
    expect(p.projectId, 7);
  });

  test('um tipo desconhecido conta como geral, e lixo nao rebenta', () {
    final p = NotificacaoPush.deDados({'type': 'novidade', 'projectId': 'abc'});
    expect(p.tipo, TipoNotificacao.geral);
    expect(p.projectId, isNull);
    expect(p.notificationId, isNull);
  });

  group('para onde leva tocar', () {
    test('com empreendimento, abre-o, seja qual for o tipo', () {
      for (final t in TipoNotificacao.values) {
        expect(
          destinoDaNotificacao(tipo: t, projectId: 7),
          isA<ProjectDetailsScreen>(),
        );
      }
    });

    test('documento sem empreendimento abre as faturas', () {
      expect(
        destinoDaNotificacao(tipo: TipoNotificacao.documento),
        isA<DocumentsScreen>(),
      );
    });

    test('comercial sem empreendimento abre o que esta a venda', () {
      expect(
        destinoDaNotificacao(tipo: TipoNotificacao.comercial),
        isA<PortfolioScreen>(),
      );
    });

    test('geral sem empreendimento nao tem para onde ir', () {
      expect(destinoDaNotificacao(tipo: TipoNotificacao.geral), isNull);
    });
  });
}
