// Notificacoes do utilizador — GET /notification.
//
// O formato e um CONTRATO com o site, que ja esta feito: o tipo Notificacao em
// website-cleveroption-1/lib/notificacoes.ts e o notification.dto.ts da API tem
// de continuar a corresponder a isto campo por campo. Se discordarem, o mesmo
// investidor ve coisas diferentes no site e na app.
//
// O contrato ao pormenor esta em website-cleveroption-1/docs/notificacoes-api.md.

/// O tipo decide a etiqueta e o icone.
enum TipoNotificacao {
  obra('obra', 'Obra'),
  documento('documento', 'Documento'),
  comercial('comercial', 'Comercial'),
  geral('geral', 'Geral');

  const TipoNotificacao(this.valorApi, this.etiqueta);

  /// Como a API o escreve.
  final String valorApi;

  /// Como aparece ao investidor.
  final String etiqueta;

  /// Um tipo que esta app ainda nao conhece conta como geral, em vez de
  /// deitar a lista toda abaixo. Se o backoffice ganhar um tipo novo, a app
  /// antiga continua a mostrar a notificacao — so sem a etiqueta certa.
  static TipoNotificacao dePalavra(String? bruto) {
    final chave = bruto?.trim().toLowerCase();
    for (final t in TipoNotificacao.values) {
      if (t.valorApi == chave) return t;
    }
    return TipoNotificacao.geral;
  }
}

class Notificacao {
  final int id;
  final TipoNotificacao tipo;

  /// Uma linha.
  final String titulo;

  /// Uma ou duas linhas. O detalhe fica no ecra para onde a notificacao aponta.
  final String corpo;

  /// Ja lida por esta pessoa. A API conta a leitura por utilizador, nao por
  /// notificacao: a mesma notificacao pode estar lida para um e por ler para
  /// outro.
  final bool lida;

  /// Quando foi escrita. A API manda ISO 8601 em UTC; aqui fica em UTC e so
  /// se converte para a hora local ao mostrar.
  final DateTime? criadaEm;

  /// O empreendimento a que diz respeito, quando ha um. E por aqui que a app
  /// sabe para onde levar quem toca na notificacao.
  final int? projectId;

  /// Para onde o clique leva **no site** (por exemplo
  /// "/empreendimento?projectId=1"). A app nao usa este caminho, porque as
  /// rotas dela nao sao as do site — usa o [projectId]. Fica guardado para
  /// nao se perder o que a API manda.
  final String? href;

  const Notificacao({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.corpo,
    this.lida = false,
    this.criadaEm,
    this.projectId,
    this.href,
  });

  /// A mesma notificacao, marcada como lida. O modelo e imutavel, por isso
  /// marcar devolve uma copia em vez de mexer nesta.
  Notificacao marcadaComoLida() => Notificacao(
        id: id,
        tipo: tipo,
        titulo: titulo,
        corpo: corpo,
        lida: true,
        criadaEm: criadaEm,
        projectId: projectId,
        href: href,
      );

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      tipo: TipoNotificacao.dePalavra(json['type']?.toString()),
      titulo: json['title']?.toString() ?? '',
      corpo: json['body']?.toString() ?? '',
      lida: json['read'] == true,
      criadaEm: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      projectId: int.tryParse(json['projectId']?.toString() ?? ''),
      href: json['href']?.toString(),
    );
  }
}

/// O que GET /notification devolve.
class NotificacoesResposta {
  /// Da mais recente para a mais antiga, no maximo 30.
  final List<Notificacao> notificacoes;

  /// Nao lidas em **todas** as visiveis, nao so nas que vieram na lista.
  ///
  /// E este o numero do sininho. Conta-lo a partir de [notificacoes] dava um
  /// numero preso nas 30 a quem tivesse mais do que isso por ler.
  final int naoLidas;

  const NotificacoesResposta({
    this.notificacoes = const [],
    this.naoLidas = 0,
  });

  factory NotificacoesResposta.fromJson(Map<String, dynamic> json) {
    return NotificacoesResposta(
      notificacoes: (json['notifications'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Notificacao.fromJson(e.cast<String, dynamic>()))
          .toList(),
      naoLidas: int.tryParse(json['unreadCount']?.toString() ?? '') ?? 0,
    );
  }
}
