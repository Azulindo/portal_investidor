import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/utils/portfolio.dart';

// A legenda do mapa passou a ser um filtro (tocar num estado mostra ou
// esconde os pinos desse estado).
void main() {
  final todos = Portfolio.grupos.toSet();

  test('tocar num estado ligado esconde-o', () {
    expect(Portfolio.alternarGrupo(todos, 'concluido'), {'desenvolvimento', 'ativo'});
  });

  test('tocar num estado desligado volta a mostrá-lo', () {
    expect(Portfolio.alternarGrupo({'ativo'}, 'concluido'), {'ativo', 'concluido'});
  });

  test('desligar o último volta a mostrar todos, em vez de um mapa vazio', () {
    expect(Portfolio.alternarGrupo({'ativo'}, 'ativo'), todos);
  });

  test('não altera o conjunto que recebe', () {
    final ligados = {'ativo', 'concluido'};
    Portfolio.alternarGrupo(ligados, 'ativo');
    expect(ligados, {'ativo', 'concluido'});
  });

  // O símbolo dos pinos era um .avif, que no browser não aparecia.
  test('os assets de imagem declarados existem e não são .avif', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final imagens = RegExp(r'^\s*-\s*(assets/images/\S+)', multiLine: true)
        .allMatches(pubspec)
        .map((m) => m.group(1)!)
        .toList();
    expect(imagens, isNotEmpty);
    for (final caminho in imagens) {
      expect(File(caminho).existsSync(), isTrue, reason: '$caminho não existe');
      expect(caminho.endsWith('.avif'), isFalse, reason: caminho);
    }
  });
}
