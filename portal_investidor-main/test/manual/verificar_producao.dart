import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:portal_investidor/config/api_config.dart';
import 'package:portal_investidor/models/user_model.dart';
import 'package:portal_investidor/utils/portfolio.dart';

/// Passa as respostas verdadeiras da API pelos modelos da app.
///
/// NÃO corre com os outros testes: está fora da pasta `test/` normal e o nome
/// não acaba em `_test.dart`, por isso o `flutter test` não lhe pega. Precisa
/// de rede e do servidor no ar, e um teste que depende dos dois falha por
/// razões que não são do código.
///
/// Corre-se à mão, quando se quer confirmar que a app aguenta o que o
/// servidor está mesmo a mandar:
///
///     flutter test test/manual/verificar_producao.dart \
///       --dart-define=API_BASE_URL=https://api.cleveroption.pt/api
///
/// Só mexe nos endpoints públicos — portfólio e detalhes. O que precisa de
/// sessão (carteira, faturas, notificações) tem de ser testado na app, com
/// uma conta a sério.
void main() {
  final problemas = <String>[];

  void anotar(String problema) {
    problemas.add(problema);
    // ignore: avoid_print
    print('  ! $problema');
  }

  test('a app lê o que o servidor manda', () async {
    final base = ApiConfig.baseUrl;
    // ignore: avoid_print
    print('\nServidor: $base\n');

    final respostaPortfolio = await http
        .get(Uri.parse('$base${ApiConfig.portfolioEndpoint}'))
        .timeout(const Duration(seconds: 30));

    expect(respostaPortfolio.statusCode, 200,
        reason: 'o portfólio não respondeu');

    final corpo = jsonDecode(respostaPortfolio.body) as Map<String, dynamic>;
    final projetos =
        ((corpo['data'] as Map)['projects'] as List).cast<Map<String, dynamic>>();

    // ignore: avoid_print
    print('${projetos.length} empreendimentos no portfólio\n');

    var semPagina = 0;

    for (final p in projetos) {
      final id = Portfolio.inteiro(p, 'id');
      final nome = Portfolio.texto(p, 'name');

      // 1. O modelo do painel lê a linha do portfólio sem rebentar.
      final ConstructionItem obra;
      try {
        obra = ConstructionItem.fromJson(p);
      } catch (e) {
        anotar('[$id] $nome: o modelo não leu a linha do portfólio — $e');
        continue;
      }

      // 2. A fotografia tem de ficar com endereço completo. A API manda
      //    caminhos relativos ("/media/..."), e o widget das imagens não os
      //    sabe abrir.
      if (obra.imageUrl.isNotEmpty && !obra.imageUrl.startsWith('http')) {
        anotar('[$id] $nome: a imagem ficou sem servidor — ${obra.imageUrl}');
      }

      // 3. Quem não tem página não deve ser aberto: a API responde 404.
      if (!obra.temPagina) {
        semPagina++;
        final recusa = await http
            .get(Uri.parse('$base${ApiConfig.projectDetailsEndpoint(id ?? 0)}'))
            .timeout(const Duration(seconds: 30));

        if (recusa.statusCode != 404) {
          anotar('[$id] $nome: sem página, mas os detalhes '
              'responderam ${recusa.statusCode} em vez de 404');
        }
        continue;
      }

      // 4. Os detalhes dos que têm página têm de passar pelo modelo inteiro.
      final resposta = await http
          .get(Uri.parse('$base${ApiConfig.projectDetailsEndpoint(id ?? 0)}'))
          .timeout(const Duration(seconds: 30));

      if (resposta.statusCode != 200) {
        anotar('[$id] $nome: os detalhes responderam ${resposta.statusCode}');
        continue;
      }

      final ProjectDetailModel detalhe;
      try {
        detalhe = ProjectDetailModel.fromJson(
          jsonDecode(resposta.body) as Map<String, dynamic>,
        );
      } catch (e) {
        anotar('[$id] $nome: o modelo não leu os detalhes — $e');
        continue;
      }

      for (final imagem in detalhe.galeria) {
        if (!imagem.startsWith('http')) {
          anotar('[$id] $nome: imagem da galeria sem servidor — $imagem');
          break;
        }
      }

      for (final f in detalhe.fractions) {
        final planta = f.floorPlanUrl;
        if (planta != null && !planta.startsWith('http')) {
          anotar('[$id] $nome: planta sem servidor — $planta');
          break;
        }
      }

      // ignore: avoid_print
      print('  [$id] $nome — ${detalhe.fractions.length} frações, '
          '${detalhe.galeria.length} imagens, '
          '${detalhe.steps.length} fases'
          '${detalhe.info.subtitle != null ? ', com subtítulo' : ''}');
    }

    // ignore: avoid_print
    print('\n$semPagina só de historial (não abrem, como no site)');
    // ignore: avoid_print
    print(problemas.isEmpty
        ? '\nNada a apontar.\n'
        : '\n${problemas.length} coisas a ver.\n');

    expect(problemas, isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
