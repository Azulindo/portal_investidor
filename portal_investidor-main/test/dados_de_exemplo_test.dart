import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/models/investidor_model.dart';
import 'package:portal_investidor/models/user_model.dart';
import 'package:portal_investidor/services/dados_de_exemplo.dart';
import 'package:portal_investidor/utils/carteira.dart';
import 'package:portal_investidor/utils/portfolio.dart';
import 'package:portal_investidor/utils/video.dart';

/// Os dados de exemplo tinham ficado para trás da app: um projeto só, sem
/// estado, sem frações, sem acabamentos. Com eles ligados não se via metade
/// do que a app mostra, e ninguém dava por isso até abrir.
///
/// Estes testes são o alarme: se alguém acrescentar um ecrã e se esquecer do
/// mock, ou se partir a ligação entre as listas, isto falha.
void main() {
  group('as listas batem certo umas com as outras', () {
    test('as encomendas são de empreendimentos que o investidor tem', () {
      // É o que faz a carteira do painel funcionar: as encomendas juntam-se
      // aos empreendimentos pelo nome. Um nome diferente dava carteira a
      // zero, sem erro nenhum à vista.
      final investidor = InvestidorModel.fromJson(DadosDeExemplo.investidor());
      final obras = investidor.obras.map((o) => o.title).toSet();

      for (final o in DadosDeExemplo.encomendas()) {
        expect(
          obras,
          contains(o.projectName),
          reason: 'a encomenda ${o.name} é de "${o.projectName}", que não '
              'está nas obras do investidor',
        );
      }
    });

    test('as obras do investidor existem no portfólio', () {
      final noPortfolio = DadosDeExemplo.portfolio()
          .map((p) => p['name'].toString())
          .toSet();
      final investidor = InvestidorModel.fromJson(DadosDeExemplo.investidor());

      for (final obra in investidor.obras) {
        expect(noPortfolio, contains(obra.title));
      }
    });

    test('a carteira do painel dá um valor verdadeiro', () {
      final investidor = InvestidorModel.fromJson(DadosDeExemplo.investidor());
      final encomendas = DadosDeExemplo.encomendas();
      final linhas = Carteira.porEmpreendimento(
        investidor.obras.map((o) => o.title).toList(),
        encomendas,
      );

      expect(Carteira.investimentoTotal(encomendas), greaterThan(0));
      expect(Carteira.totalPago(encomendas), greaterThan(0));
      expect(Carteira.totalFracoes(linhas), greaterThan(0));
      // A fração "B" está em duas encomendas do Aires Ornelas: três frações
      // distintas no total, não quatro.
      expect(Carteira.totalFracoes(linhas), 3);
    });
  });

  group('o portfólio cobre o que os ecrãs precisam', () {
    final lista = DadosDeExemplo.portfolio();

    test('tem os três estados, senão os filtros ficam por exercitar', () {
      for (final grupo in ['ativo', 'desenvolvimento', 'concluido']) {
        expect(
          Portfolio.quantosNoGrupo(lista, grupo),
          greaterThan(0),
          reason: 'não há nenhum projeto no grupo "$grupo"',
        );
      }
    });

    test('tem mais de uma cidade, senão o filtro de cidade não aparece', () {
      expect(Portfolio.cidades(lista).length, greaterThan(1));
    });

    test('tem projetos com e sem comercialização', () {
      expect(lista.any(Portfolio.estaAVenda), isTrue);
      expect(lista.any((p) => !Portfolio.estaAVenda(p)), isTrue);
    });

    test('tem um projeto sem coordenadas, para o mapa o saltar', () {
      final semCoordenadas = lista.where((p) {
        return p['latitude'] == 0 && p['longitude'] == 0;
      });
      expect(semCoordenadas, isNotEmpty);
    });

    test('todos têm fases e fase atual, para a barra de progresso aparecer', () {
      for (final p in lista) {
        expect(
          Portfolio.progresso(p),
          isNotNull,
          reason: '${p['name']} não dá progresso nenhum',
        );
      }
    });

    test('os contadores do cabeçalho não ficam a zero', () {
      expect(Portfolio.totalFracoes(lista), greaterThan(0));
    });
  });

  group('o detalhe completo mostra todas as secções', () {
    final d = ProjectDetailModel.fromJson(DadosDeExemplo.detalhes(1));

    test('frações, com os casos chatos lá dentro', () {
      expect(d.fractions, isNotEmpty);
      // Um piso não numérico, que por ordem alfabética ia para o sítio errado.
      expect(d.fractions.any((f) => f.floor == 'Cave'), isTrue);
      // Uma fração sem varanda nem garagem.
      expect(
        d.fractions.any((f) => (f.balconyArea ?? 0) == 0),
        isTrue,
      );
      // Os três estados.
      expect(
        d.fractions.map((f) => f.status).toSet(),
        containsAll(['Disponível', 'Reservado', 'Vendido']),
      );
      // Com sessão o preço vem sempre preenchido.
      expect(d.fractions.every((f) => f.price != null), isTrue);
    });

    test('acabamentos', () {
      expect(d.finishes.length, greaterThan(1));
      expect(d.finishes.first.details, isNotEmpty);
    });

    test('"O lugar" com as duas listas', () {
      expect(d.info.zoneTitle, isNotNull);
      expect(d.info.zoneNearbyInfrastructures, isNotEmpty);
      expect(d.info.zoneNearbyLocations, isNotEmpty);
    });

    test('vídeo com um URL que a app reconhece', () {
      expect(Video.idDoYoutube(d.info.videoUrl), isNotNull);
    });

    test('galeria e galeria de obra, separadas', () {
      expect(d.galeria, isNotEmpty);
      expect(d.galeriaDeObra, isNotEmpty);
      // Interiores e exteriores, para a etiqueta do carrossel aparecer.
      expect(d.galeriaTemInteriorEExterior, isTrue);
    });

    test('a imagem inativa não entra em galeria nenhuma', () {
      final total = (DadosDeExemplo.detalhes(1)['data']
          as Map)['projectImages'] as List;
      expect(
        d.galeria.length + d.galeriaDeObra.length,
        lessThan(total.length),
      );
    });

    test('tem coordenadas, para o mapa do empreendimento aparecer', () {
      expect(d.info.latitude, isNotNull);
      expect(d.info.longitude, isNotNull);
      expect(d.info.latitude != 0 || d.info.longitude != 0, isTrue);
    });
  });

  test('os outros projetos abrem sem as secções opcionais', () {
    // Nem todos os empreendimentos têm o backoffice todo preenchido, e o
    // detalhe tem de aguentar isso sem rebentar.
    final d = ProjectDetailModel.fromJson(DadosDeExemplo.detalhes(2));
    expect(d.info.name, isNotEmpty);
    expect(d.fractions, isEmpty);
    expect(d.finishes, isEmpty);
    expect(d.info.zoneTitle, isNull);
    expect(Video.idDoYoutube(d.info.videoUrl), isNull);
    expect(d.galeria, isNotEmpty);
  });

  test('um projectId que não existe devolve algo em vez de rebentar', () {
    final d = ProjectDetailModel.fromJson(DadosDeExemplo.detalhes(9999));
    expect(d.info.name, isNotEmpty);
  });
}
