import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/notificacao.dart';

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
    expect(p.destino, DestinoPush.empreendimento);
  });

  test('sem projectId abre a lista de notificacoes', () {
    final p = NotificacaoPush.deDados({'notificationId': '3', 'type': 'documento'});
    expect(p.projectId, isNull);
    expect(p.destino, DestinoPush.notificacoes);
  });

  test('um tipo desconhecido conta como geral, e lixo nao rebenta', () {
    final p = NotificacaoPush.deDados({'type': 'novidade', 'projectId': 'abc'});
    expect(p.tipo, TipoNotificacao.geral);
    expect(p.projectId, isNull);
    expect(p.notificationId, isNull);
  });
}
