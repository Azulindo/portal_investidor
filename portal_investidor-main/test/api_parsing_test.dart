import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/user_model.dart';

/// Resposta de /project/details tal como a API a devolve hoje, com os campos
/// que a app não lia: categoria das imagens, frações, acabamentos e a zona.
/// Serve para o parsing ficar preso a um exemplo real em vez de ao que
/// julgamos que a API manda.
const respostaDetalhes = '''
{
  "status": 200,
  "message": "Detalhes Projeto",
  "code": "PROJECT_DETAILS_SUCCESS",
  "data": {
    "projectInfo": [
      {
        "name": "Living Canedo",
        "nFractions": 47,
        "address": "Rua do Mocelo",
        "city": "Canedo, Santa Maria da Feira",
        "status": "Construção",
        "currentStep": 2,
        "description": "Nasce em Canedo...",
        "startDate": "2025-01-01",
        "endDate": "2028-12-31",
        "mainImageUrl": "https://exemplo.pt/capa.jpg",
        "descriptionImageUrl": "https://exemplo.pt/conceito.jpg",
        "forSale": true,
        "latitude": 40.9876,
        "longitude": -8.4321,
        "videoUrl": "https://www.youtube.com/watch?v=abcdefghijk",
        "zoneTitle": "Entre o verde e a cidade",
        "zoneDescription": "Canedo é uma vila...",
        "zoneNearbyInfrastructures": ["Escolas", "Centro de saúde"],
        "zoneNearbyLocations": [
          { "name": "Porto (centro)", "time": "25–30 min" }
        ]
      }
    ],
    "projectSteps": [
      { "id": 1, "stepOrder": 1, "name": "Início de Obra", "description": "Escavação.", "imageUrl": null },
      { "id": 2, "stepOrder": 2, "name": "Estrutura", "description": "Bloco 1.", "imageUrl": "https://exemplo.pt/e.jpg" }
    ],
    "projectImages": [
      { "imageId": 3, "imageUrl": "https://exemplo.pt/int.jpg", "imageDescription": "Sala", "category": "interior", "active": true, "sortOrder": 2 },
      { "imageId": 1, "imageUrl": "https://exemplo.pt/ext.jpg", "imageDescription": "Fachada", "category": "exterior", "active": true, "sortOrder": 1 },
      { "imageId": 4, "imageUrl": "https://exemplo.pt/obra.jpg", "imageDescription": "Fundações", "category": "obra", "active": true, "sortOrder": 3 },
      { "imageId": 5, "imageUrl": "https://exemplo.pt/escondida.jpg", "imageDescription": null, "category": "exterior", "active": false, "sortOrder": 0 }
    ],
    "projectFractions": [
      { "fractionId": 1, "projectId": 1, "fractionNumber": "G", "type": "T1", "totalArea": 45.11, "garageArea": 12, "balconyArea": 1.73, "price": null, "status": "Disponível", "block": 1, "floor": "1", "orientation": "norte", "floorPlanUrl": "https://exemplo.pt/g.pdf" },
      { "fractionId": 2, "projectId": 1, "fractionNumber": "C", "type": "T1+1", "totalArea": 62.41, "garageArea": 12, "balconyArea": 6.15, "price": 204750, "status": "Vendido", "block": null, "floor": "Vale", "orientation": "sul", "floorPlanUrl": null }
    ],
    "projectFinishes": [
      { "finishId": 1, "categoryId": 3, "categoryName": "Instalações sanitárias", "imageUrl": null, "details": ["Pavimento: ...", "Paredes: ..."] }
    ]
  }
}
''';

/// Um projeto de /project/portfolio (ou de /user/:id → projects).
const respostaPortfolio = '''
{
  "id": 1,
  "name": "Living Canedo",
  "address": "Rua do Mocelo",
  "city": "Canedo, Santa Maria da Feira",
  "latitude": 40.9876,
  "longitude": -8.4321,
  "status": "Construção",
  "endDate": "2028-12-31",
  "currentStep": 2,
  "mainImageUrl": "https://exemplo.pt/capa.jpg",
  "forSale": true,
  "nFractions": 47,
  "steps": [
    { "id": 1, "stepOrder": 1, "name": "Início de Obra", "description": "Escavação." },
    { "id": 2, "stepOrder": 2, "name": "Estrutura", "description": "Bloco 1." }
  ]
}
''';

void main() {
  group('GET /project/details', () {
    final d = ProjectDetailModel.fromJson(
        jsonDecode(respostaDetalhes) as Map<String, dynamic>);

    test('lê a informação do projeto, incluindo a zona', () {
      expect(d.info.name, 'Living Canedo');
      expect(d.info.forSale, isTrue);
      expect(d.info.latitude, closeTo(40.9876, 0.0001));
      expect(d.info.anoFim, '2028');
      expect(d.info.videoUrl, contains('youtube'));
      expect(d.info.zoneNearbyInfrastructures, contains('Escolas'));
      expect(d.info.zoneNearbyLocations.single.name, 'Porto (centro)');
      expect(d.info.zoneNearbyLocations.single.time, '25–30 min');
    });

    test('separa a galeria da obra e respeita ordem e imagens inativas', () {
      // A inativa não entra em galeria nenhuma.
      expect(d.galeria.length, 2);
      expect(d.galeria.any((u) => u.contains('escondida')), isFalse);
      // Ordenadas por sortOrder: exterior (1) antes de interior (2).
      expect(d.galeria.first, contains('ext.jpg'));
      expect(d.galeria.last, contains('int.jpg'));
      // A de obra fica à parte.
      expect(d.galeriaDeObra, ['https://exemplo.pt/obra.jpg']);
      expect(d.galeriaDe('interior'), ['https://exemplo.pt/int.jpg']);
    });

    test('lê as frações, com preço escondido e piso em texto', () {
      expect(d.fractions.length, 2);
      final g = d.fractions.first;
      // Preço null é o preço escondido de quem não tem sessão, não zero.
      expect(g.price, isNull);
      expect(g.disponivel, isTrue);
      expect(g.floor, '1');
      // Piso não numérico tem de sobreviver.
      expect(d.fractions.last.floor, 'Vale');
      expect(d.fractions.last.block, isNull);
      expect(d.fractions.last.price, 204750);
      expect(d.fracoesDisponiveis, 1);
    });

    test('lê os acabamentos já agrupados', () {
      expect(d.finishes.single.categoryName, 'Instalações sanitárias');
      expect(d.finishes.single.details.length, 2);
    });

    test('os passos usam "id" e currentStep é um stepOrder', () {
      expect(d.steps.first.id, 1);
      expect(d.info.currentStep, 2);
      expect(d.steps.firstWhere((s) => s.stepOrder == d.info.currentStep).name,
          'Estrutura');
    });
  });

  group('projeto do portfólio', () {
    final p = ConstructionItem.fromJson(
        jsonDecode(respostaPortfolio) as Map<String, dynamic>);

    test('lê comercialização, coordenadas e ano', () {
      expect(p.forSale, isTrue);
      expect(p.temCoordenadas, isTrue);
      expect(p.nFractions, 47);
      expect(p.anoFim, '2028');
      expect(p.currentStepObject?.name, 'Estrutura');
      expect(p.isStepCompleted(0), isTrue);
      expect(p.isCurrentStep(1), isTrue);
    });

    test('sem coordenadas quando a API manda 0/0', () {
      final semMorada = ConstructionItem.fromJson({
        'id': 2,
        'name': 'Sem morada',
        'city': 'Porto',
        'currentStep': 1,
        'latitude': 0,
        'longitude': 0,
        'steps': [],
      });
      expect(semMorada.temCoordenadas, isFalse);
    });
  });

  group('respostas incompletas', () {
    test('details sem as listas novas não rebenta', () {
      final d = ProjectDetailModel.fromJson(jsonDecode('''
        { "data": { "projectInfo": [ { "name": "Antigo" } ] } }
      ''') as Map<String, dynamic>);
      expect(d.info.name, 'Antigo');
      expect(d.fractions, isEmpty);
      expect(d.finishes, isEmpty);
      expect(d.galeria, isEmpty);
      // Sem frações nenhumas devolve null, para se distinguir de "zero disponíveis".
      expect(d.fracoesDisponiveis, isNull);
    });

    test('imagem sem categoria conta como exterior e ativa', () {
      final i = ProjectImage.fromJson({'imageId': 9, 'imageUrl': 'https://x.pt/a.jpg'});
      expect(i.category, 'exterior');
      expect(i.active, isTrue);
      expect(i.eDeObra, isFalse);
    });
  });
}
