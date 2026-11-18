import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/user_model.dart';
import 'package:portal_investidor/utils/portfolio.dart';

/// Empreendimentos "só de historial" — os que a API marca com
/// `hasDetailPage: false`.
///
/// Entram nas listas e no mapa, mas não têm detalhes: o
/// `GET /project/details` responde 404 PROJECT_NOT_FOUND a quem os pedir
/// (project.controller.ts na API). Por isso a app não os deve deixar abrir,
/// nem anunciar que têm frações à venda — é a mesma regra que o site aplica
/// com `temPagina` e `aVendaNoSite` em lib/testApi.ts.
///
/// O campo é recente: uma API anterior a ele não o envia, e aí tudo tem
/// página, como antes.
void main() {
  Map proj({bool aVenda = false, bool? temPagina, int? fracoes, String? fim}) {
    return {
      'id': 1,
      'name': 'Projeto',
      'city': 'Porto',
      'status': 'Em construção',
      'forSale': aVenda,
      // Omitido de propósito quando é null: é o caso da API antiga, que não
      // manda o campo.
      'hasDetailPage': ?temPagina,
      'nFractions': fracoes,
      'endDate': fim,
    };
  }

  group('tem página', () {
    test('o campo ausente conta como tendo página', () {
      expect(Portfolio.temPagina(proj()), isTrue);
    });

    test('só false tira a página', () {
      expect(Portfolio.temPagina(proj(temPagina: false)), isFalse);
      expect(Portfolio.temPagina(proj(temPagina: true)), isTrue);
    });
  });

  group('em comercialização', () {
    test('à venda com página anuncia-se', () {
      expect(Portfolio.estaAVenda(proj(aVenda: true)), isTrue);
    });

    test('à venda sem página não se anuncia', () {
      // Acontece quando o backoffice marca o empreendimento à venda antes de
      // ligar a página. Anunciá-lo levava a pessoa a um ecrã que não existe.
      expect(
        Portfolio.estaAVenda(proj(aVenda: true, temPagina: false)),
        isFalse,
      );
    });
  });

  test('a ordem não põe à frente quem está à venda sem página', () {
    final lista = [
      proj(aVenda: false, fracoes: 2),
      proj(aVenda: true, temPagina: false, fracoes: 1),
    ];

    final ordenada = Portfolio.ordenarPorComercializacao(lista);

    // Fica à frente o maior, porque nenhum dos dois conta como à venda.
    expect(Portfolio.inteiro(ordenada.first, 'nFractions'), 2);
  });

  test('o filtro "só à venda" deixa de fora quem não tem página', () {
    final lista = [
      proj(aVenda: true),
      proj(aVenda: true, temPagina: false),
    ];

    expect(Portfolio.filtrar(lista, apenasAVenda: true).length, 1);
  });

  group('ConstructionItem', () {
    test('lê o campo e assume que há página quando ele falta', () {
      expect(ConstructionItem.fromJson({'id': 1}).temPagina, isTrue);
      expect(
        ConstructionItem.fromJson({'id': 1, 'hasDetailPage': false}).temPagina,
        isFalse,
      );
    });

    test('à venda sem página não está em comercialização', () {
      final obra = ConstructionItem.fromJson({
        'id': 1,
        'forSale': true,
        'hasDetailPage': false,
      });

      expect(obra.forSale, isTrue, reason: 'o campo cru não se mexe');
      expect(obra.estaAVenda, isFalse);
    });
  });

  group('subtítulo do empreendimento', () {
    test('vem quando a API o manda', () {
      final info = ProjectInfo.fromJson({
        'name': 'Aires',
        'subtitle': 'T1 a T3 com varanda',
      });

      expect(info.subtitle, 'T1 a T3 com varanda');
    });

    test('ausente ou vazio fica null, para não abrir uma linha vazia', () {
      expect(ProjectInfo.fromJson({'name': 'Aires'}).subtitle, isNull);
      expect(ProjectInfo.fromJson({'name': 'A', 'subtitle': ''}).subtitle,
          isNull);
      expect(ProjectInfo.fromJson({'name': 'A', 'subtitle': '   '}).subtitle,
          isNull);
    });
  });
}
