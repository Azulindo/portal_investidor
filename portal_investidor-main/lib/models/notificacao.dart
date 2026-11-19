// Notificacoes do utilizador — GET /notification.
//
// O formato e um CONTRATO com o site, que ja esta feito: o tipo Notificacao em
// website-cleveroption-1/lib/notificacoes.ts e o notification.dto.ts da API tem
// de continuar a corresponder a isto campo por campo. Se discordarem, o mesmo
// investidor ve coisas diferentes no site e na app.
//
// O contrato ao pormenor esta em website-cleveroption-1/docs/notificacoes-api.md.

import '../config/api_config.dart';

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

  /// É um anúncio: além do sininho, aparece em destaque no topo do painel
  /// (GET /notification/announcements), como no topo da Área Reservada do
  /// site.
  final bool anuncio;

  /// Até quando o anúncio aparece em destaque. null é sem prazo.
  final DateTime? terminaEm;

  /// A imagem do anúncio, já com o domínio. Só vem nos anúncios, e é
  /// decorativa: o título e o corpo têm a informação toda.
  final String? imagemUrl;

  const Notificacao({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.corpo,
    this.lida = false,
    this.criadaEm,
    this.projectId,
    this.href,
    this.anuncio = false,
    this.terminaEm,
    this.imagemUrl,
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
        anuncio: anuncio,
        terminaEm: terminaEm,
        imagemUrl: imagemUrl,
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
      anuncio: json['announcement'] == true,
      terminaEm: DateTime.tryParse(json['endsAt']?.toString() ?? ''),
      // Um caminho do site (/media/anuncios/x.webp) ou um https:// completo;
      // monta-se como as outras imagens.
      imagemUrl: ApiConfig.urlDeFicheiro(json['imageUrl']?.toString()),
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

/// Para onde leva quem toca: ver lib/utils/destino_notificacao.dart, que e o
/// mesmo para a lista do sininho e para as notificacoes push.

/// O que vem no `data` de uma notificacao push (ver a seccao 7 do
/// API_CONTRACT.md). O FCM obriga a que tudo venha em texto, por isso os
/// numeros chegam como "12" e convertem-se aqui.
///
/// O titulo e o corpo nao estao aqui: vem no `notification` e quem os mostra
/// e o proprio sistema do telemovel.
class NotificacaoPush {
  /// O mesmo id do GET /notification, para a marcar como lida.
  final int? notificationId;
  final TipoNotificacao tipo;
  final int? projectId;

  const NotificacaoPush({
    this.notificationId,
    this.tipo = TipoNotificacao.geral,
    this.projectId,
  });

  factory NotificacaoPush.deDados(Map<String, dynamic> data) {
    int? inteiro(String chave) => int.tryParse(data[chave]?.toString() ?? '');
    return NotificacaoPush(
      notificationId: inteiro('notificationId'),
      tipo: TipoNotificacao.dePalavra(data['type']?.toString()),
      projectId: inteiro('projectId'),
    );
  }
}
