import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/notificacao.dart';

void main() {
  test('lê os campos dos anúncios (o exemplo do Miguel)', () {
    final n = Notificacao.fromJson({
      'id': 42,
      'type': 'comercial',
      'title': 'Pré-venda: A Fábrica',
      'body': 'Veja as frações antes da abertura ao público.',
      'createdAt': '2026-11-19T10:00:00.000Z',
      'read': false,
      'projectId': null,
      'href': '/empreendimento?p=abc123',
      'announcement': true,
      'endsAt': null,
      'imageUrl': '/media/anuncios/pre-venda.webp',
    });
    expect(n.anuncio, isTrue);
    expect(n.terminaEm, isNull);
    // O caminho do site ganha o domínio, como as outras imagens.
    expect(n.imagemUrl, startsWith('http'));
    expect(n.imagemUrl, endsWith('/media/anuncios/pre-venda.webp'));
  });

  test('uma notificação normal não é anúncio nem tem imagem', () {
    final n = Notificacao.fromJson({'id': 1, 'type': 'obra', 'title': 'x'});
    expect(n.anuncio, isFalse);
    expect(n.imagemUrl, isNull);
  });

  test('marcar como lida não perde os campos do anúncio', () {
    final n = Notificacao.fromJson({
      'id': 2,
      'announcement': true,
      'endsAt': '2026-12-01T00:00:00Z',
      'imageUrl': 'https://exemplo.pt/a.webp',
    }).marcadaComoLida();
    expect(n.lida, isTrue);
    expect(n.anuncio, isTrue);
    expect(n.terminaEm, DateTime.utc(2026, 12, 1));
    expect(n.imagemUrl, 'https://exemplo.pt/a.webp');
  });
}
