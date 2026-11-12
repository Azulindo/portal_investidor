import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/config/api_config.dart';
import 'package:portal_investidor/models/user_model.dart';
import 'package:portal_investidor/utils/portfolio.dart';

/// Endereços dos ficheiros que a API devolve.
///
/// Desde que os ficheiros passaram a ser servidos pela própria API, as
/// respostas trazem **caminhos relativos**:
///
///     "mainImageUrl": "/media/aires-de-ornelas/gallery/exterior/hero.webp"
///
/// O site resolve-os com um proxy no próprio domínio
/// (`app/media/[...path]/route.ts`). A app não tem onde, e o
/// CachedNetworkImage não abre um caminho sem host — sem isto a app não
/// mostrava uma única fotografia contra o servidor a sério.
void main() {
  // Nos testes não há --dart-define, por isso a base é a do ambiente de
  // desenvolvimento. O que importa é a regra, não o host.
  final base = ApiConfig.baseUrl;

  group('endereço de um ficheiro', () {
    test('um caminho relativo passa a levar a base da API', () {
      expect(
        ApiConfig.urlDeFicheiro('/media/aires/hero.webp'),
        '$base/media/aires/hero.webp',
      );
    });

    test('um caminho sem a barra inicial também', () {
      expect(
        ApiConfig.urlDeFicheiro('media/aires/hero.webp'),
        '$base/media/aires/hero.webp',
      );
    });

    test('um endereço já completo fica como está', () {
      // Há imagens antigas apontadas para fora, e essas não se mexem.
      const fora = 'https://images.unsplash.com/photo-1541881430816.jpg';
      expect(ApiConfig.urlDeFicheiro(fora), fora);
      expect(
        ApiConfig.urlDeFicheiro('http://exemplo.pt/a.png'),
        'http://exemplo.pt/a.png',
      );
    });

    test('vazio, só espaços ou ausente dá null', () {
      expect(ApiConfig.urlDeFicheiro(null), isNull);
      expect(ApiConfig.urlDeFicheiro(''), isNull);
      expect(ApiConfig.urlDeFicheiro('   '), isNull);
    });

    test('a base nunca fica com duas barras', () {
      // O API_BASE_URL pode ser colado com a barra do fim
      // ("https://api.cleveroption.pt/api/"), e aí os endpoints, que já
      // começam por "/", davam "//".
      expect(ApiConfig.baseUrl.endsWith('/'), isFalse);
      expect(ApiConfig.urlDeFicheiro('/media/a.webp'), isNot(contains('//media')));
    });
  });

  group('os modelos já devolvem endereços que se podem abrir', () {
    test('a obra do painel', () {
      final obra = ConstructionItem.fromJson({
        'id': 7,
        'mainImageUrl': '/media/aires/hero.webp',
      });

      expect(obra.imageUrl, '$base/media/aires/hero.webp');
    });

    test('o empreendimento e as imagens da galeria', () {
      final detalhe = ProjectDetailModel.fromJson({
        'data': {
          'projectInfo': [
            {
              'name': 'Aires de Ornelas',
              'mainImageUrl': '/media/aires/hero.webp',
              'descriptionImageUrl': '/media/aires/gallery-1.webp',
            }
          ],
          'projectImages': [
            {'imageId': 37, 'imageUrl': '/media/aires/hero.webp'},
          ],
          'projectFractions': [
            {'fractionId': 1, 'floorPlanUrl': '/media/aires/planta-a.pdf'},
          ],
        },
      });

      expect(detalhe.info.mainImageUrl, '$base/media/aires/hero.webp');
      expect(
        detalhe.info.descriptionImageUrl,
        '$base/media/aires/gallery-1.webp',
      );
      expect(detalhe.galeria.single, '$base/media/aires/hero.webp');
      // A planta é um PDF que se abre fora da app, e precisa do endereço
      // completo tal como as imagens.
      expect(
        detalhe.fractions.single.floorPlanUrl,
        '$base/media/aires/planta-a.pdf',
      );
    });

    test('o cartão do portfólio, que lê o Map como vem da API', () {
      expect(
        Portfolio.imagem({'mainImageUrl': '/media/aires/hero.webp'}),
        '$base/media/aires/hero.webp',
      );
      // Sem imagem devolve vazio, que é o que os cartões já tratam.
      expect(Portfolio.imagem({'mainImageUrl': null}), '');
      expect(Portfolio.imagem({}), '');
    });
  });
}
