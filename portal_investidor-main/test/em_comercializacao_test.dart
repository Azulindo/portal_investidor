import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/utils/portfolio.dart';

// A página Em Comercialização do site (PR #15 do Miguel): frações livres e
// de que tipologias, a partir do availableFractions e availableByType do
// /project/portfolio.
void main() {
  final aires = {
    'name': 'Aires',
    'city': 'Porto',
    'availableFractions': 4,
    'availableByType': [
      {'type': 'T2', 'count': 3},
      {'type': 'T3', 'count': 1},
    ],
  };
  final luxor = {
    'name': 'Luxor',
    'city': 'Vila Nova de Gaia',
    'availableFractions': 1,
    'availableByType': [
      {'type': 'T1', 'count': 1},
    ],
  };
  final semFracoes = {'name': 'Novo', 'city': 'Porto'};

  test('lê as livres e as tipologias', () {
    expect(Portfolio.disponiveis(aires), 4);
    expect(
      Portfolio.disponiveisPorTipologia(
        aires,
      ).map((t) => '${t.quantas} ${t.tipologia}'),
      ['3 T2', '1 T3'],
    );
  });

  test('sem frações carregadas não inventa um zero', () {
    expect(Portfolio.disponiveis(semFracoes), isNull);
    expect(Portfolio.disponiveisPorTipologia(semFracoes), isEmpty);
  });

  test('tipologias sem nome ou a zero ficam de fora', () {
    expect(
      Portfolio.disponiveisPorTipologia({
        'availableByType': [
          {'type': '', 'count': 2},
          {'type': 'T2', 'count': 0},
          {'type': 'T4', 'count': 2},
        ],
      }).map((t) => t.tipologia),
      ['T4'],
    );
  });

  group('cabeçalho', () {
    test('frações livres, empreendimentos e cidades, como no site', () {
      expect(
        Portfolio.resumoEmComercializacao([aires, luxor]),
        '5 frações disponíveis em 2 empreendimentos · Porto · Vila Nova de Gaia',
      );
    });

    test('singular', () {
      expect(
        Portfolio.resumoEmComercializacao([luxor]),
        '1 fração disponível em 1 empreendimento · Vila Nova de Gaia',
      );
    });

    test('nenhum com frações carregadas: só os empreendimentos', () {
      expect(
        Portfolio.resumoEmComercializacao([semFracoes]),
        '1 empreendimento · Porto',
      );
    });

    test('lista vazia', () {
      expect(
        Portfolio.resumoEmComercializacao([]),
        'De momento não há empreendimentos em comercialização.',
      );
    });
  });
}
