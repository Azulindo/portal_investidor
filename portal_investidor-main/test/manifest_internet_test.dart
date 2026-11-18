import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// A versão debug tem internet porque o manifest de debug acrescenta a
// permissão. A release (a que vai para a loja) só tem a do manifest principal.
// Sem ela a app instalada dá "erro de ligação à rede" em tudo.
void main() {
  test('o manifest principal pede acesso à internet', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android.permission.INTERNET'));
  });
}
