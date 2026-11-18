import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/config/versao_app.dart';
import 'package:portal_investidor/utils/versao.dart';

void main() {
  group('Versao.maisRecente', () {
    test('compara número a número, não como texto', () {
      expect(Versao.maisRecente('1.0.1', '1.0.0'), isTrue);
      expect(Versao.maisRecente('1.10.0', '1.9.0'), isTrue);
      expect(Versao.maisRecente('2.0.0', '1.99.99'), isTrue);
    });

    test('igual ou mais antiga não é nova', () {
      expect(Versao.maisRecente('1.0.0', '1.0.0'), isFalse);
      expect(Versao.maisRecente('1.0.0', '1.0.1'), isFalse);
      expect(Versao.maisRecente('1.1', '1.1.0'), isFalse);
    });

    test('ignora o build e as pré-versões', () {
      expect(Versao.maisRecente('1.0.0+7', '1.0.0'), isFalse);
      expect(Versao.maisRecente('1.0.1-beta', '1.0.0'), isTrue);
    });

    test('na dúvida não avisa', () {
      expect(Versao.maisRecente('', '1.0.0'), isFalse);
      expect(Versao.maisRecente('versão nova', '1.0.0'), isFalse);
      expect(Versao.maisRecente('1.0.0.0', '0.9.0'), isFalse);
    });
  });

  test('versaoApp é a mesma do pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final linha = RegExp(r'^version:\s*(\S+)', multiLine: true)
        .firstMatch(pubspec)!
        .group(1)!;
    expect(versaoApp, linha.split('+').first,
        reason: 'mude lib/config/versao_app.dart junto com o pubspec');
  });
}
