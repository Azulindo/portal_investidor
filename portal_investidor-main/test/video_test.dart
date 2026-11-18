import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/user_model.dart';
import 'package:portal_investidor/utils/video.dart';

/// O backoffice aceita o URL do YouTube em qualquer formato que as pessoas
/// copiem. Estes testes garantem que a app reconhece os mesmos formatos que o
/// site (youtubeEmbedUrl em lib/testApi.ts) — e que recusa os outros, em vez
/// de mandar a pessoa para um sítio arbitrário.
void main() {
  group('reconhece o id do vídeo', () {
    const id = 'dQw4w9WgXcQ';

    test('nos quatro formatos do YouTube', () {
      expect(Video.idDoYoutube('https://www.youtube.com/watch?v=$id'), id);
      expect(Video.idDoYoutube('https://youtu.be/$id'), id);
      expect(Video.idDoYoutube('https://www.youtube.com/embed/$id'), id);
      expect(Video.idDoYoutube('https://www.youtube.com/shorts/$id'), id);
    });

    test('com parâmetros antes do v=, como vem das playlists', () {
      expect(
        Video.idDoYoutube('https://www.youtube.com/watch?list=PL123&v=$id'),
        id,
      );
    });

    test('com parâmetros depois, como o &t= de quem copia a partir de um minuto', () {
      expect(Video.idDoYoutube('https://youtu.be/$id?t=42'), id);
      expect(Video.idDoYoutube('https://www.youtube.com/watch?v=$id&t=42s'), id);
    });

    test('com espaços à volta, que é como vem de um copiar-colar', () {
      expect(Video.idDoYoutube('  https://youtu.be/$id  '), id);
    });
  });

  group('recusa o que não reconhece', () {
    test('vazio, nulo e só espaços', () {
      expect(Video.idDoYoutube(null), isNull);
      expect(Video.idDoYoutube(''), isNull);
      expect(Video.idDoYoutube('   '), isNull);
    });

    test('outros sítios', () {
      expect(Video.idDoYoutube('https://vimeo.com/123456'), isNull);
      expect(Video.idDoYoutube('https://exemplo.pt/video.mp4'), isNull);
    });

    test('um id com o tamanho errado', () {
      // Os ids do YouTube têm sempre 11 caracteres; aceitar outros levava a
      // abrir um link que não existe.
      expect(Video.idDoYoutube('https://youtu.be/curto'), isNull);
    });
  });

  group('URLs que a app constrói', () {
    test('a miniatura e o link de abertura usam o id', () {
      expect(Video.miniatura('abcdefghijk'), contains('/abcdefghijk/'));
      // Watch e não embed: é o watch que o telemóvel entrega à app do
      // YouTube quando ela está instalada.
      expect(Video.paraAbrir('abcdefghijk'), 'https://www.youtube.com/watch?v=abcdefghijk');
    });
  });

  group('campos de "O lugar" na resposta da API', () {
    ProjectInfo info(Map<String, dynamic> extra) => ProjectInfo.fromJson({
          'projectId': 1,
          'name': 'Exemplo',
          'status': 'Em construção',
          ...extra,
        });

    test('lê o título, a descrição e as duas listas', () {
      final i = info({
        'zoneTitle': 'Entre o rio e o centro',
        'zoneDescription': 'A dois passos de tudo.',
        'zoneNearbyInfrastructures': ['Escola básica', 'Mercado'],
        'zoneNearbyLocations': [
          {'name': 'Aeroporto', 'time': '20 min'},
          {'name': 'Baixa do Porto', 'time': '12 min'},
        ],
      });

      expect(i.zoneTitle, 'Entre o rio e o centro');
      expect(i.zoneNearbyInfrastructures, ['Escola básica', 'Mercado']);
      expect(i.zoneNearbyLocations.length, 2);
      expect(i.zoneNearbyLocations.first.name, 'Aeroporto');
      expect(i.zoneNearbyLocations.first.time, '20 min');
    });

    test('sem os campos zone*, fica tudo vazio e a secção não aparece', () {
      final i = info({});
      expect(i.zoneTitle, isNull);
      expect(i.zoneDescription, isNull);
      expect(i.zoneNearbyInfrastructures, isEmpty);
      expect(i.zoneNearbyLocations, isEmpty);
    });
  });
}
