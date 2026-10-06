import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/user_model.dart';

/// Como a API separa as galerias: a categoria de cada imagem ("interior",
/// "exterior", "obra"), a ordem do backoffice (sortOrder) e as inativas.
/// É a mesma separação que a página de empreendimento do site faz.
Map<String, dynamic> img(
  int id, {
  String categoria = 'exterior',
  bool ativa = true,
  int ordem = 0,
  String? url,
  String? descricao,
}) {
  return {
    'imageId': id,
    'imageUrl': url ?? 'https://exemplo.pt/$id.jpg',
    'imageDescription': descricao,
    'category': categoria,
    'active': ativa,
    'sortOrder': ordem,
  };
}

ProjectDetailModel detalhe(List<Map<String, dynamic>> imagens) {
  return ProjectDetailModel.fromJson({
    'data': {
      'projectInfo': [
        {'projectId': 1, 'name': 'Exemplo', 'status': 'Em construção'},
      ],
      'projectSteps': [],
      'projectImages': imagens,
    },
  });
}

void main() {
  test('a galeria do empreendimento deixa de fora as fotos de obra', () {
    final d = detalhe([
      img(1, categoria: 'exterior'),
      img(2, categoria: 'obra'),
      img(3, categoria: 'interior'),
    ]);

    expect(d.galeria.length, 2);
    expect(d.galeriaDeObra.length, 1);
    expect(d.galeriaDeObra.single, contains('/2.jpg'));
  });

  test('as duas galerias respeitam a ordem do backoffice', () {
    final d = detalhe([
      img(1, ordem: 3),
      img(2, ordem: 1),
      img(3, ordem: 2),
      img(4, categoria: 'obra', ordem: 2),
      img(5, categoria: 'obra', ordem: 1),
    ]);

    expect(d.galeria, [
      'https://exemplo.pt/2.jpg',
      'https://exemplo.pt/3.jpg',
      'https://exemplo.pt/1.jpg',
    ]);
    expect(d.galeriaDeObra, [
      'https://exemplo.pt/5.jpg',
      'https://exemplo.pt/4.jpg',
    ]);
  });

  test('imagens inativas e sem URL não aparecem em galeria nenhuma', () {
    final d = detalhe([
      img(1),
      img(2, ativa: false),
      img(3, url: ''),
      img(4, categoria: 'obra', ativa: false),
    ]);

    expect(d.galeria.length, 1);
    expect(d.galeriaDeObra, isEmpty);
  });

  group('identificar a categoria no carrossel', () {
    test('sim quando há interiores e exteriores', () {
      final d = detalhe([
        img(1, categoria: 'exterior'),
        img(2, categoria: 'interior'),
      ]);
      expect(d.galeriaTemInteriorEExterior, isTrue);
    });

    test('não quando só há um dos tipos', () {
      // Dizer "exterior" em todas não informa nada — é a mesma decisão que
      // o site toma em separarGaleria.
      expect(
        detalhe([img(1), img(2)]).galeriaTemInteriorEExterior,
        isFalse,
      );
      expect(
        detalhe([
          img(1, categoria: 'interior'),
          img(2, categoria: 'interior'),
        ]).galeriaTemInteriorEExterior,
        isFalse,
      );
    });

    test('as fotos de obra não contam para essa decisão', () {
      final d = detalhe([
        img(1, categoria: 'exterior'),
        img(2, categoria: 'obra'),
      ]);
      expect(d.galeriaTemInteriorEExterior, isFalse);
    });
  });

  test('as categorias saem pela mesma ordem das imagens do carrossel', () {
    final d = detalhe([
      img(1, categoria: 'interior', ordem: 2),
      img(2, categoria: 'exterior', ordem: 1),
      img(3, categoria: 'obra', ordem: 0),
    ]);

    // A etiqueta do carrossel usa o índice da página nesta lista, por isso a
    // ordem tem de ser exatamente a da galeria.
    expect(d.imagensDaGaleria.map((i) => i.category), ['exterior', 'interior']);
    expect(d.imagensDaGaleria.map((i) => i.imageUrl), d.galeria);
  });

  test('a legenda da imagem passa para o visualizador', () {
    final d = detalhe([
      img(1, categoria: 'obra', descricao: 'Betonagem do 2.º piso'),
      img(2, categoria: 'obra'),
    ]);

    expect(d.imagensDeObra.first.imageDescription, 'Betonagem do 2.º piso');
    expect(d.imagensDeObra.last.imageDescription, isNull);
  });

  test('sem categoria na resposta, a imagem conta como exterior e ativa', () {
    final d = ProjectDetailModel.fromJson({
      'data': {
        'projectInfo': [
          {'projectId': 1, 'name': 'Exemplo', 'status': 'Em construção'},
        ],
        'projectImages': [
          {'imageId': 1, 'imageUrl': 'https://exemplo.pt/1.jpg'},
        ],
      },
    });

    expect(d.galeria.length, 1);
    expect(d.imagensDaGaleria.single.category, 'exterior');
  });
}
