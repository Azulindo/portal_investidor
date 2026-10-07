import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/theme/co_colors.dart';
import 'package:portal_investidor/utils/ui_helpers.dart';

/// A correspondência "estado da API → cor" já tinha sido escrita três vezes
/// em sítios diferentes — nos filtros do portfólio, na etiqueta dos cartões
/// e no mapa — e das três comparou o estado por igualdade exacta. Como a API
/// escreve "Em construção" e "Em desenvolvimento", e não "Construção" e
/// "Desenvolvimento", nenhuma das três acertava: os pinos do mapa saíam
/// todos cinzentos e a etiqueta caía sempre no valor por omissão.
///
/// Agora é uma função só. Estes testes existem para que, se alguém voltar a
/// trocá-la por um switch de igualdade, isto parta aqui e não no telemóvel
/// de um investidor.
void main() {
  group('UIHelpers.corDoGrupo', () {
    test('aceita o estado como a API o escreve, não só a palavra solta', () {
      // Os dois pares têm de dar a mesma cor.
      expect(UIHelpers.corDoGrupo('Em construção'),
          UIHelpers.corDoGrupo('Construção'));
      expect(UIHelpers.corDoGrupo('Em desenvolvimento'),
          UIHelpers.corDoGrupo('Desenvolvimento'));
    });

    test('cada grupo tem a sua cor, e são três cores diferentes', () {
      final cores = {
        UIHelpers.corDoGrupo('Concluído'),
        UIHelpers.corDoGrupo('Em construção'),
        UIHelpers.corDoGrupo('Em desenvolvimento'),
      };
      expect(cores.length, 3);
    });

    test('não usa verdes nem azuis do Material', () {
      for (final estado in ['Concluído', 'Em construção', 'Em desenvolvimento']) {
        for (final claro in [true, false]) {
          final cor = UIHelpers.corDoGrupo(estado, fundoClaro: claro);
          expect(cor, isNot(Colors.green));
          expect(cor, isNot(Colors.greenAccent));
          expect(cor, isNot(Colors.blue));
          // As antigas, à mão, que andavam pelo mapa.
          expect(cor, isNot(const Color(0xFF43A047)));
          expect(cor, isNot(const Color(0xFF42A5F5)));
          expect(cor, isNot(const Color(0xFF9E9E9E)));
        }
      }
    });

    test('sobre o mapa, que é branco, o estado a decorrer usa o navy', () {
      expect(UIHelpers.corDoGrupo('Em construção', fundoClaro: true),
          COColors.brand900);
      expect(UIHelpers.corDoGrupo('Em construção'), COColors.brand300);
    });

    test('um estado desconhecido ou vazio não rebenta', () {
      expect(() => UIHelpers.corDoGrupo(null), returnsNormally);
      expect(() => UIHelpers.corDoGrupo(''), returnsNormally);
      expect(() => UIHelpers.corDoGrupo('qualquer coisa'), returnsNormally);
    });
  });
}
