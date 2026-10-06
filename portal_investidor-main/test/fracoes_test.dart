import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/user_model.dart';
import 'package:portal_investidor/utils/fracoes.dart';

/// As contas sobre frações têm de dar o mesmo que no site
/// (components/dev/FractionsTable.tsx). Se divergirem, a app e o site passam
/// a mostrar números diferentes para o mesmo empreendimento.
ProjectFraction f({
  int id = 1,
  String numero = 'A',
  String tipo = 'T2',
  double area = 80,
  double? garagem,
  double? varanda,
  double? preco = 200000,
  String estado = 'Disponível',
  int? bloco,
  String? piso,
}) {
  return ProjectFraction(
    fractionId: id,
    projectId: 1,
    fractionNumber: numero,
    type: tipo,
    totalArea: area,
    garageArea: garagem,
    balconyArea: varanda,
    price: preco,
    status: estado,
    block: bloco,
    floor: piso,
  );
}

void main() {
  group('ordem dos pisos', () {
    test('é a ordem do prédio e não a alfabética', () {
      final pisos = Fracoes.pisos([
        f(id: 1, piso: '7'),
        f(id: 2, piso: 'R/C'),
        f(id: 3, piso: '10'),
        f(id: 4, piso: 'Cave'),
        f(id: 5, piso: '2'),
      ]);
      // Por ordem alfabética, "R/C" vinha depois do 7 e o 10 antes do 2.
      expect(pisos, ['Cave', 'R/C', '2', '7', '10']);
    });

    test('o que não se reconhece vai para o fim', () {
      final pisos = Fracoes.pisos([
        f(id: 1, piso: 'Vale'),
        f(id: 2, piso: '1'),
        f(id: 3, piso: 'Cave'),
      ]);
      expect(pisos, ['Cave', '1', 'Vale']);
    });

    test('rés-do-chão escrito de várias formas conta sempre como piso 0', () {
      for (final escrita in ['R/C', 'RC', 'r.c.', 'Rés-do-chão', 'res do chao']) {
        expect(Fracoes.pesoPiso(escrita), 0, reason: 'falhou em "$escrita"');
      }
    });
  });

  group('filtros', () {
    final lista = [
      f(id: 1, numero: 'A2', tipo: 'T2', piso: '1', estado: 'Disponível'),
      f(id: 2, numero: 'A1', tipo: 'T2', piso: '1', estado: 'Vendido'),
      f(id: 3, numero: 'B1', tipo: 'T10', piso: '2', estado: 'Disponível'),
      f(id: 4, numero: 'C1', tipo: 'T3', piso: '2', estado: 'Reservado'),
    ];

    test('sem filtros devolve tudo, por tipologia e número de fração', () {
      final r = Fracoes.filtrar(lista);
      expect(r.map((x) => x.fractionNumber), ['A1', 'A2', 'C1', 'B1']);
      // T10 depois de T3: os números leem-se como números, não como texto.
      expect(r.map((x) => x.type), ['T2', 'T2', 'T3', 'T10']);
    });

    test('filtra por tipologia, estado e piso', () {
      expect(Fracoes.filtrar(lista, tipologia: 'T2').length, 2);
      expect(Fracoes.filtrar(lista, estado: 'Disponível').length, 2);
      expect(Fracoes.filtrar(lista, piso: '2').length, 2);
    });

    test('os filtros acumulam', () {
      final r = Fracoes.filtrar(lista, tipologia: 'T2', estado: 'Disponível');
      expect(r.map((x) => x.fractionNumber), ['A2']);
    });

    test('combinação sem resultados devolve lista vazia, não rebenta', () {
      expect(Fracoes.filtrar(lista, tipologia: 'T2', piso: '2'), isEmpty);
    });
  });

  group('intervalos de área', () {
    test('um valor só não vira intervalo', () {
      expect(Fracoes.intervaloArea([80.0]), '80 m²');
    });

    test('vários valores dão mínimo e máximo', () {
      expect(Fracoes.intervaloArea([46.6, 40.3, 42.0]), '40,3–46,6 m²');
    });

    test('zeros e nulos são ignorados', () {
      // A API manda 0 para frações sem varanda; "0–12 m²" não diz nada.
      expect(Fracoes.intervaloArea([0.0, null, 12.0]), '12 m²');
      expect(Fracoes.intervaloArea([0.0, null]), isNull);
    });
  });

  group('resumo por tipologia', () {
    test('conta, mede e diz quantas estão por vender', () {
      final r = Fracoes.resumo([
        f(id: 1, tipo: 'T2', area: 80, varanda: 10, estado: 'Disponível'),
        f(id: 2, tipo: 'T2', area: 85, varanda: 12, estado: 'Vendido'),
        f(id: 3, tipo: 'T1', area: 50, estado: 'Disponível'),
      ]);

      expect(r.map((x) => x.tipologia), ['T1', 'T2']);

      final t2 = r.firstWhere((x) => x.tipologia == 'T2');
      expect(t2.quantidade, 2);
      expect(t2.area, '80–85 m²');
      expect(t2.exterior, '10–12 m²');
      expect(t2.garagem, '—');
      expect(t2.disponiveis, 1);
    });

    test('exterior em só algumas frações aparece como "até X"', () {
      final r = Fracoes.resumo([
        f(id: 1, tipo: 'T2', varanda: 10),
        f(id: 2, tipo: 'T2', varanda: null),
      ]);
      expect(r.single.exterior, 'até 10 m²');
    });
  });

  group('formatação', () {
    test('números à portuguesa, sem decimais a mais', () {
      expect(Fracoes.numero(80), '80');
      expect(Fracoes.numero(40.3), '40,3');
      expect(Fracoes.numero(40.30), '40,3');
    });

    test('preços com separador de milhares e sem cêntimos', () {
      expect(Fracoes.euros(185000), '185 000 €');
      expect(Fracoes.euros(1250000.49), '1 250 000 €');
      expect(Fracoes.euros(950), '950 €');
    });

    test('singular e plural de fração', () {
      expect(Fracoes.contagem(1), '1 fração');
      expect(Fracoes.contagem(12), '12 frações');
    });
  });
}
