import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/user_model.dart';
import 'package:portal_investidor/utils/ficha_fracao.dart';

// A ficha da fração tem de dizer o mesmo que a do site
// (website-cleveroption-1/lib/fracao.ts e app/empreendimento/fracao).
ProjectFraction _f({
  String numero = 'M',
  String tipo = 'T2',
  String status = 'Disponível',
  String? bloco,
  String? piso,
  String? orientacao,
  double? privativa,
  double? varanda,
  int? lugares,
  double? garagem,
  int id = 1,
}) =>
    ProjectFraction(
      fractionId: id,
      projectId: 7,
      fractionNumber: numero,
      type: tipo,
      status: status,
      block: bloco,
      floor: piso,
      orientation: orientacao,
      grossPrivateArea: privativa,
      balconyArea: varanda,
      parkingSpaces: lugares,
      garageArea: garagem,
    );

void main() {
  test('pisos e blocos como no site', () {
    expect(FichaFracao.pisoCurto('2'), '2.º');
    expect(FichaFracao.pisoCurto('r/c'), 'R/C');
    expect(FichaFracao.pisoCurto('Vale'), 'Vale');
    expect(FichaFracao.pisoPorExtenso('2'), 'Piso 2');
    expect(FichaFracao.pisoPorExtenso('Cave'), 'Cave');
    expect(FichaFracao.pisoPorExtenso('Piso 3'), 'Piso 3');
    expect(FichaFracao.blocoPorExtenso('2'), 'Bloco 2');
    expect(FichaFracao.blocoPorExtenso('Bloco Norte'), 'Bloco Norte');
    expect(FichaFracao.orientacaoPorExtenso('nascente/sul'), 'Nascente · Sul');
  });

  test('estado desconhecido nunca conta como disponível', () {
    expect(FichaFracao.estado('Disponível'), EstadoFracao.disponivel);
    expect(FichaFracao.estado('Vendido'), EstadoFracao.vendida);
    expect(FichaFracao.estado('Reservado'), EstadoFracao.reservada);
    expect(FichaFracao.estado('Em negociação'), EstadoFracao.reservada);
  });

  test('o link é o do site, com o id ofuscado e a fração "bloco-número"', () {
    expect(
      FichaFracao.url(7, _f(bloco: '2', numero: 'M')),
      'https://www.cleveroption.pt/empreendimento/fracao?p=ykfxXF&f=2-M',
    );
    expect(FichaFracao.slug(_f(numero: 'M')), 'M');
  });

  test('título e mensagem do WhatsApp', () {
    final f = _f(bloco: '2');
    expect(FichaFracao.titulo(f, 'Living Canedo'),
        'T2 · Fração M · Bloco 2 · Living Canedo');
    expect(
      FichaFracao.mensagemWhatsapp(f, 'Living Canedo', 'L'),
      'Olá! Tenho interesse na fração M do Bloco 2 (T2) do Living Canedo: L',
    );
  });

  test('os factos só levam o que a fração tem', () {
    final factos = FichaFracao.factos(
      _f(privativa: 60.94, varanda: 7.2, piso: '2', lugares: 1, garagem: 14),
    );
    expect(factos.map((x) => '${x.titulo}=${x.valor}'), [
      'Área privativa=60,94 m²',
      'Exterior=7,2 m²',
      'Piso=2.º',
      'Garagem=1 lugar',
    ]);
    expect(factos.last.nota, '14 m²');
    expect(FichaFracao.factos(_f()), isEmpty);
  });

  test('outras frações: mesma tipologia e bloco, pela ordem do prédio', () {
    final todas = [
      _f(id: 1, numero: '10', piso: '2', bloco: 'A'),
      _f(id: 2, numero: '3', piso: 'R/C', bloco: 'A'),
      _f(id: 3, numero: '5', piso: '1', bloco: 'B'),
      _f(id: 4, numero: '4', piso: '1', bloco: 'A', tipo: 'T3'),
      _f(id: 5, numero: '2', piso: '2', bloco: 'A'),
    ];
    final outras = FichaFracao.outras(todas.first, todas);
    expect(outras.map((x) => x.fractionNumber), ['3', '2', '10']);
  });

  test('lê os campos novos da API', () {
    final f = ProjectFraction.fromJson({
      'fractionId': 1,
      'projectId': 7,
      'fractionNumber': 'M',
      'type': 'T2',
      'status': 'Disponível',
      'parkingSpaces': 2,
      'floorPlanImageUrl': '/media/planta.png',
      'floorLocationImageUrl': null,
    });
    expect(f.parkingSpaces, 2);
    expect(f.floorPlanImageUrl, endsWith('/media/planta.png'));
    expect(f.floorPlanImageUrl, startsWith('http'));
    expect(f.floorLocationImageUrl, isNull);
  });
}
