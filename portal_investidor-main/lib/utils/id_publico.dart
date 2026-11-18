import 'package:sqids/sqids.dart';

/// Os ids que o site põe nos endereços (`/empreendimento?p=peP0Pc`), em vez
/// dos números.
///
/// É uma cópia do website-cleveroption-1/lib/idPublico.ts: o mesmo alfabeto e
/// o mesmo tamanho mínimo, senão os códigos não batem certo. A app precisa
/// disto para os links das notificações, que a API escreve como caminhos do
/// site. Se o site mudar o alfabeto, muda aqui também (o teste
/// id_publico_test.dart tem códigos tirados do site para o apanhar).
class IdPublico {
  IdPublico._();

  static final _sqids = Sqids(
    alphabet: '9ybWlZAUCn1O7E2hk8TNxzISjK4fHvJ6gowic0BpePMdV3DrmaQsLYqG5uFXtR',
    minLength: 6,
  );

  static String codificar(int id) => _sqids.encode([id]);

  /// O id de um código, ou null se não for um código válido. Recodificar e
  /// comparar garante um só código por id, como no site.
  static int? descodificar(String? codigo) {
    if (codigo == null || codigo.isEmpty) return null;
    try {
      final numeros = _sqids.decode(codigo);
      if (numeros.length != 1 || numeros.first <= 0) return null;
      return codificar(numeros.first) == codigo ? numeros.first : null;
    } catch (_) {
      return null;
    }
  }
}
