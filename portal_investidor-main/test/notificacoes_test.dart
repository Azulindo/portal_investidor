import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/notificacao.dart';
import 'package:portal_investidor/utils/tempo.dart';

/// O formato das notificacoes e um contrato com o site e com a API.
///
/// Os exemplos de JSON daqui sao copiados do docs/notificacoes-api.md do site.
/// Se a API mudar o formato, e aqui que se da por isso.
void main() {
  group('Ler uma notificacao da API', () {
    test('le o exemplo do contrato campo por campo', () {
      final n = Notificacao.fromJson(const {
        'id': 12,
        'type': 'obra',
        'title': 'Living Canedo — estrutura do bloco 1 concluída',
        'body': 'A timeline do empreendimento já tem as fotos desta fase.',
        'createdAt': '2026-10-02T09:15:00.000Z',
        'read': false,
        'projectId': 1,
        'href': '/empreendimento?projectId=1',
      });

      expect(n.id, 12);
      expect(n.tipo, TipoNotificacao.obra);
      expect(n.titulo, 'Living Canedo — estrutura do bloco 1 concluída');
      expect(n.lida, isFalse);
      expect(n.projectId, 1);
      expect(n.criadaEm?.isUtc, isTrue);
      expect(n.criadaEm?.year, 2026);
    });

    test('projectId e href a null nao estragam nada', () {
      final n = Notificacao.fromJson(const {
        'id': 4,
        'type': 'geral',
        'title': 'Aviso',
        'body': '',
        'createdAt': '2026-10-02T09:15:00.000Z',
        'read': true,
        'projectId': null,
        'href': null,
      });

      expect(n.projectId, isNull);
      expect(n.href, isNull);
      expect(n.lida, isTrue);
    });

    test('um tipo que esta app ainda nao conhece conta como geral', () {
      // Se o backoffice ganhar um tipo novo, a app antiga tem de continuar a
      // mostrar a notificacao. Rebentar aqui deixava o sininho vazio.
      final n = Notificacao.fromJson(const {
        'id': 1,
        'type': 'juridico',
        'title': 'x',
        'body': '',
        'createdAt': '2026-10-02T09:15:00.000Z',
        'read': false,
      });
      expect(n.tipo, TipoNotificacao.geral);
    });

    test('os quatro tipos do contrato sao reconhecidos', () {
      expect(TipoNotificacao.dePalavra('obra'), TipoNotificacao.obra);
      expect(TipoNotificacao.dePalavra('documento'), TipoNotificacao.documento);
      expect(TipoNotificacao.dePalavra('comercial'), TipoNotificacao.comercial);
      expect(TipoNotificacao.dePalavra('geral'), TipoNotificacao.geral);
    });
  });

  group('A contagem do sininho', () {
    test('vem do unreadCount e nao de contar a lista', () {
      // O caso que obriga a esta regra: a API manda 30 no maximo, mas conta
      // as nao lidas sobre todas as visiveis. Contar a lista dava 1.
      final r = NotificacoesResposta.fromJson(const {
        'notifications': [
          {
            'id': 1,
            'type': 'obra',
            'title': 'a',
            'body': '',
            'createdAt': '2026-10-02T09:15:00.000Z',
            'read': false,
          },
        ],
        'unreadCount': 34,
      });

      expect(r.notificacoes.length, 1);
      expect(r.naoLidas, 34);
    });

    test('uma resposta vazia nao e um erro', () {
      final r = NotificacoesResposta.fromJson(const {});
      expect(r.notificacoes, isEmpty);
      expect(r.naoLidas, 0);
    });
  });

  group('Marcar como lida', () {
    test('devolve uma copia lida e nao mexe na original', () {
      const n = Notificacao(
        id: 1,
        tipo: TipoNotificacao.obra,
        titulo: 'a',
        corpo: 'b',
        projectId: 7,
      );
      final lida = n.marcadaComoLida();

      expect(n.lida, isFalse);
      expect(lida.lida, isTrue);
      // O resto tem de sobreviver, senao o cartao perdia o atalho para a obra.
      expect(lida.id, 1);
      expect(lida.projectId, 7);
      expect(lida.titulo, 'a');
    });
  });

  group('Ha quanto tempo foi', () {
    final agora = DateTime.utc(2026, 10, 22, 12, 0);

    test('conta minutos, horas e dias', () {
      String ha(Duration d) =>
          Tempo.haQuanto(agora.subtract(d), agora: agora);

      expect(ha(const Duration(seconds: 20)), 'agora');
      expect(ha(const Duration(minutes: 5)), 'há 5 min');
      expect(ha(const Duration(hours: 1)), 'há 1 hora');
      expect(ha(const Duration(hours: 5)), 'há 5 horas');
      expect(ha(const Duration(days: 1)), 'há 1 dia');
      expect(ha(const Duration(days: 3)), 'há 3 dias');
    });

    test('a partir de uma semana mostra a data', () {
      final r = Tempo.haQuanto(
        agora.subtract(const Duration(days: 20)),
        agora: agora,
      );
      expect(r, contains('/2026'));
      expect(r, isNot(contains('há')));
    });

    test('uma data no futuro nao vira "ha -3 minutos"', () {
      // Acontece quando o relogio do telemovel esta atrasado face ao servidor.
      final r = Tempo.haQuanto(
        agora.add(const Duration(minutes: 3)),
        agora: agora,
      );
      expect(r, 'agora');
    });

    test('sem data nao inventa nada', () {
      expect(Tempo.haQuanto(null), '');
    });
  });
}
