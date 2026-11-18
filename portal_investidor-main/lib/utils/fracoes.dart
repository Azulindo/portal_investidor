import '../models/user_model.dart';

/// Contas sobre as frações de um empreendimento: resumo por tipologia,
/// filtragem e ordenação.
///
/// Está fora do ecrã para poder ser testado, e porque é a mesma lógica do
/// site (components/dev/FractionsTable.tsx) — se as duas divergirem, a app e
/// o site passam a mostrar números diferentes para o mesmo empreendimento.
class Fracoes {
  Fracoes._();

  /// Valor usado para ordenar pisos pela ordem do prédio.
  ///
  /// Por ordem alfabética o "R/C" ia parar depois do 7.º. Cave é -1,
  /// rés-do-chão é 0, os numerados são o seu número, e o que não se
  /// reconhecer (ex.: "Vale") vai para o fim.
  static int pesoPiso(String piso) {
    final t = piso.trim().toLowerCase();
    if (RegExp(r'^(cave|-1)$').hasMatch(t)) return -1;
    if (RegExp(r'^(r/?c|r\.c\.|rés[- ]do[- ]chão|res[- ]do[- ]chao)$')
        .hasMatch(t)) {
      return 0;
    }
    final n = num.tryParse(t.replaceAll(RegExp(r'[ºª]|piso'), '').trim());
    return n?.toInt() ?? 1000;
  }

  static int compararPisos(String a, String b) {
    final porPeso = pesoPiso(a) - pesoPiso(b);
    return porPeso != 0 ? porPeso : _texto(a, b);
  }

  /// Comparação de texto em português, com os números lidos como números
  /// ("T10" depois de "T9", e não antes).
  static int _texto(String a, String b) {
    final na = RegExp(r'\d+').firstMatch(a)?.group(0);
    final nb = RegExp(r'\d+').firstMatch(b)?.group(0);
    if (na != null && nb != null) {
      final prefA = a.substring(0, a.indexOf(na));
      final prefB = b.substring(0, b.indexOf(nb));
      if (prefA == prefB) {
        final porNumero = int.parse(na).compareTo(int.parse(nb));
        if (porNumero != 0) return porNumero;
      }
    }
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  /// Tipologias distintas, por ordem.
  static List<String> tipologias(List<ProjectFraction> fracoes) =>
      _distintos(fracoes.map((f) => f.type));

  /// Estados distintos ("Disponível", "Reservado", "Vendido").
  static List<String> estados(List<ProjectFraction> fracoes) =>
      _distintos(fracoes.map((f) => f.status));

  /// Pisos distintos, pela ordem do prédio.
  static List<String> pisos(List<ProjectFraction> fracoes) {
    final lista = _distintos(fracoes.map((f) => f.floor));
    lista.sort(compararPisos);
    return lista;
  }

  static List<String> _distintos(Iterable<String?> valores) {
    final set = <String>{};
    for (final v in valores) {
      if (v != null && v.trim().isNotEmpty) set.add(v);
    }
    final lista = set.toList()..sort(_texto);
    return lista;
  }

  /// Aplica os filtros e devolve a lista pela ordem fixa: tipologia e, dentro
  /// dela, o número da fração — a ordem por que se lê uma planta.
  ///
  /// Um filtro a null é "todas".
  static List<ProjectFraction> filtrar(
    List<ProjectFraction> fracoes, {
    String? tipologia,
    String? estado,
    String? piso,
  }) {
    final lista = fracoes.where((f) {
      if (tipologia != null && f.type != tipologia) return false;
      if (estado != null && f.status != estado) return false;
      if (piso != null && f.floor != piso) return false;
      return true;
    }).toList();

    lista.sort((a, b) {
      final porTipo = _texto(a.type, b.type);
      if (porTipo != 0) return porTipo;
      return _texto(a.fractionNumber, b.fractionNumber);
    });
    return lista;
  }

  /// Uma linha do quadro resumo das tipologias.
  static List<ResumoTipologia> resumo(List<ProjectFraction> fracoes) {
    final porTipo = <String, List<ProjectFraction>>{};
    for (final f in fracoes) {
      porTipo.putIfAbsent(f.type, () => []).add(f);
    }

    final tipos = porTipo.keys.toList()..sort(_texto);
    return [
      for (final tipo in tipos)
        () {
          final lista = porTipo[tipo]!;
          final exterior = intervaloArea(lista.map((f) => f.balconyArea));
          return ResumoTipologia(
            tipologia: tipo,
            quantidade: lista.length,
            area: intervaloArea(lista.map((f) => f.totalArea)) ?? '—',
            // "até X m²" quando só algumas frações da tipologia têm exterior.
            exterior: exterior == null
                ? '—'
                : lista.any((f) => f.balconyArea == null ||
                        f.balconyArea == 0)
                    ? 'até ${exterior.split('–').last}'
                    : exterior,
            garagem: intervaloArea(lista.map((f) => f.garageArea)) ?? '—',
            disponiveis: lista.where((f) => f.disponivel).length,
          );
        }(),
    ];
  }

  /// "40,3 m²" ou "40,3–46,6 m²". null quando não há valores úteis.
  ///
  /// Zeros e nulos são ignorados: a API manda 0 para frações sem varanda nem
  /// garagem, e um intervalo "0–12 m²" não diz nada a ninguém.
  static String? intervaloArea(Iterable<double?> valores) {
    final uteis = valores
        .whereType<double>()
        .where((v) => v.isFinite && v > 0)
        .toList();
    if (uteis.isEmpty) return null;

    final min = uteis.reduce((a, b) => a < b ? a : b);
    final max = uteis.reduce((a, b) => a > b ? a : b);
    return min == max
        ? '${numero(min)} m²'
        : '${numero(min)}–${numero(max)} m²';
  }

  /// Número à portuguesa: vírgula decimal, sem decimais quando é inteiro.
  static String numero(double v, {int maxDecimais = 2}) {
    if (v == v.roundToDouble()) return v.round().toString();
    var s = v.toStringAsFixed(maxDecimais);
    // Corta zeros à direita ("40,30" → "40,3").
    s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    return s.replaceAll('.', ',');
  }

  /// Preço em euros, com separador de milhares e sem cêntimos — como no site.
  static String euros(double v) {
    final inteiro = v.round().toString();
    final partes = <String>[];
    for (var i = inteiro.length; i > 0; i -= 3) {
      partes.insert(0, inteiro.substring(i - 3 < 0 ? 0 : i - 3, i));
    }
    return '${partes.join(' ')} €';
  }

  /// "1 fração" / "12 frações".
  static String contagem(int n) => n == 1 ? '1 fração' : '$n frações';
}

/// Uma linha do quadro de tipologias.
class ResumoTipologia {
  final String tipologia;
  final int quantidade;
  final String area;
  final String exterior;
  final String garagem;
  final int disponiveis;

  const ResumoTipologia({
    required this.tipologia,
    required this.quantidade,
    required this.area,
    required this.exterior,
    required this.garagem,
    required this.disponiveis,
  });
}
