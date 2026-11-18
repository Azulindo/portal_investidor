import '../config/empresa.dart';
import '../models/user_model.dart';
import 'fracoes.dart';
import 'id_publico.dart';

/// Em que estado está a fração, para a cor (verde, âmbar, vermelho).
enum EstadoFracao { disponivel, reservada, vendida }

/// As contas e os textos da ficha de uma fração — cópia do lib/fracao.ts e da
/// página app/empreendimento/fracao do site, para a app e o site dizerem o
/// mesmo da mesma fração. Fora do ecrã para poder ser testado.
class FichaFracao {
  FichaFracao._();

  /// O piso curto, para listas: "2.º", "R/C", "Vale".
  static String pisoCurto(String piso) {
    final t = piso.trim();
    if (Fracoes.pesoPiso(t) == 0) return 'R/C';
    if (RegExp(r'^\d+$').hasMatch(t)) return '$t.º';
    return t;
  }

  /// O piso por extenso: "Piso 2", "R/C", "Piso Vale", "Cave".
  static String pisoPorExtenso(String piso) {
    final t = piso.trim();
    if (Fracoes.pesoPiso(t) == 0) return 'R/C';
    if (RegExp(r'^cave$', caseSensitive: false).hasMatch(t)) return 'Cave';
    return RegExp(r'^piso\b', caseSensitive: false).hasMatch(t) ? t : 'Piso $t';
  }

  /// "Bloco 2" — sem repetir a palavra quando o Excel já a traz.
  static String blocoPorExtenso(String bloco) {
    final t = bloco.trim();
    return RegExp(r'^bloco\b', caseSensitive: false).hasMatch(t)
        ? t
        : 'Bloco $t';
  }

  /// "nascente/sul" → "Nascente · Sul".
  static String orientacaoPorExtenso(String orientacao) => orientacao
      .split('/')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .map((s) => s[0].toUpperCase() + s.substring(1))
      .join(' · ');

  /// O que não se reconhecer conta como reservada — nunca como disponível,
  /// para não se anunciar o que não está.
  static EstadoFracao estado(String status) {
    final t = status.trim().toLowerCase();
    if (t.startsWith('dispon')) return EstadoFracao.disponivel;
    if (t.startsWith('vend')) return EstadoFracao.vendida;
    return EstadoFracao.reservada;
  }

  static String lugares(int n) => '$n ${n == 1 ? 'lugar' : 'lugares'}';

  static String m2(double v) => '${Fracoes.numero(v)} m²';

  /// "2-M" (bloco 2, fração M), ou só "M" sem blocos. É o ?f= do site.
  static String slug(ProjectFraction f) {
    final bloco = f.block?.trim();
    final numero = f.fractionNumber.trim();
    return bloco != null && bloco.isNotEmpty ? '$bloco-$numero' : numero;
  }

  /// O link da ficha no site, para partilhar.
  static String url(int projectId, ProjectFraction f) =>
      '${Empresa.site}/empreendimento/fracao?p=${IdPublico.codificar(projectId)}'
      '&f=${Uri.encodeComponent(slug(f))}';

  /// "T2 · Fração M · Bloco 2 · Living Canedo".
  static String titulo(ProjectFraction f, String empreendimento) => [
        f.type,
        'Fração ${f.fractionNumber}',
        if (f.block != null) blocoPorExtenso(f.block!),
        empreendimento,
      ].where((s) => s.isNotEmpty).join(' · ');

  /// A mensagem pré-escrita do WhatsApp, a mesma do site.
  static String mensagemWhatsapp(
    ProjectFraction f,
    String empreendimento,
    String link,
  ) {
    final bloco = f.block != null ? ' do ${blocoPorExtenso(f.block!)}' : '';
    return 'Olá! Tenho interesse na fração ${f.fractionNumber}$bloco '
        '(${f.type}) do $empreendimento: $link';
  }

  /// Os números do topo: os que a fração tiver, até seis.
  static List<({String titulo, String valor, String? nota})> factos(
    ProjectFraction f,
  ) {
    final orientacao = f.orientation != null && f.orientation!.trim().isNotEmpty
        ? orientacaoPorExtenso(f.orientation!)
        : null;
    return [
      if (f.grossPrivateArea != null)
        (titulo: 'Área privativa', valor: m2(f.grossPrivateArea!), nota: null),
      if ((f.balconyArea ?? 0) > 0)
        (titulo: 'Exterior', valor: m2(f.balconyArea!), nota: 'varanda'),
      if (f.totalArea != null)
        (titulo: 'Área total', valor: m2(f.totalArea!), nota: null),
      if (f.usefulArea != null)
        (titulo: 'Área útil', valor: m2(f.usefulArea!), nota: null),
      if (f.floor != null && f.floor!.trim().isNotEmpty)
        (titulo: 'Piso', valor: pisoCurto(f.floor!), nota: null),
      if (orientacao != null)
        (titulo: 'Orientação', valor: orientacao, nota: null),
      if ((f.parkingSpaces ?? 0) > 0)
        (
          titulo: 'Garagem',
          valor: lugares(f.parkingSpaces!),
          nota: (f.garageArea ?? 0) > 0 ? m2(f.garageArea!) : null,
        ),
    ].take(6).toList();
  }

  /// A tabela "Sobre a fração", sem o preço (que depende do estado e se
  /// mostra à parte).
  static List<(String, String)> especificacoes(ProjectFraction f) {
    final bloco = f.block != null ? blocoPorExtenso(f.block!) : null;
    final piso = f.floor != null && f.floor!.trim().isNotEmpty
        ? pisoPorExtenso(f.floor!)
        : null;
    return [
      ('Tipologia', f.type),
      if (bloco != null || piso != null)
        ('Bloco · Piso', [?bloco, ?piso].join(' · ')),
      if (f.orientation != null && f.orientation!.trim().isNotEmpty)
        ('Orientação solar', orientacaoPorExtenso(f.orientation!)),
      if (f.grossPrivateArea != null)
        ('Área bruta privativa', m2(f.grossPrivateArea!)),
      if (f.usefulArea != null) ('Área útil', m2(f.usefulArea!)),
      if ((f.balconyArea ?? 0) > 0) ('Área exterior', m2(f.balconyArea!)),
      if (f.totalArea != null) ('Área bruta total', m2(f.totalArea!)),
      if ((f.garageArea ?? 0) > 0) ('Área de garagem', m2(f.garageArea!)),
      if ((f.parkingSpaces ?? 0) > 0)
        ('Estacionamento', lugares(f.parkingSpaces!)),
      ('Estado', f.status),
    ];
  }

  /// Outras frações da mesma tipologia (e do mesmo bloco, quando há blocos),
  /// pela ordem do prédio. Inclui a própria, como no site, para se ver onde
  /// está entre as outras.
  static List<ProjectFraction> outras(
    ProjectFraction f,
    List<ProjectFraction> todas,
  ) {
    final lista = todas
        .where((x) => x.type == f.type && (f.block == null || x.block == f.block))
        .toList()
      ..sort((a, b) {
        final porPiso = Fracoes.compararPisos(a.floor ?? '', b.floor ?? '');
        if (porPiso != 0) return porPiso;
        final na = int.tryParse(a.fractionNumber);
        final nb = int.tryParse(b.fractionNumber);
        if (na != null && nb != null) return na.compareTo(nb);
        return a.fractionNumber.compareTo(b.fractionNumber);
      });
    return lista;
  }
}
