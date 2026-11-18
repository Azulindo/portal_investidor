import 'package:flutter/widgets.dart';

import '../models/notificacao.dart';
import '../screens/documents_screen.dart';
import '../screens/portfolio_screen.dart';
import '../screens/project_details_screen.dart';
import 'id_publico.dart';

/// Para onde leva quem toca numa notificação — na lista do sininho e nas
/// notificações push, que têm de levar ao mesmo sítio.
///
/// O empreendimento vem do `projectId` ou, quando não há, do `href`. A API só
/// deixa pôr `projectId` nas notificações para todos os clientes de um
/// empreendimento (audience "project"); as que vão para uma pessoa ou para
/// toda a gente (a "está em comercialização", por exemplo) dizem de que
/// empreendimento são só no `href`, que é o caminho do site.
///
///  - com empreendimento: abre-o;
///  - href para /em-comercializacao ou /portfolio: abre essa lista;
///  - documento (faturas): abre as faturas;
///  - comercial sem empreendimento: abre o que está em comercialização;
///  - o resto: não há mais nada para ver além do texto, que o cartão já
///    mostra por inteiro. Devolve null.
Widget? destinoDaNotificacao({
  required TipoNotificacao tipo,
  int? projectId,
  int? notificationId,
  String? href,
}) {
  final projeto = projectId ?? projetoDoHref(href);
  if (projeto != null) {
    return ProjectDetailsScreen(
      projectId: projeto,
      heroTag: 'notificacao-$notificationId-$projeto',
      initialImageUrl: '',
    );
  }

  switch (Uri.tryParse(href ?? '')?.path) {
    case '/em-comercializacao':
      return const PortfolioScreen(apenasAVendaInicial: true);
    case '/portfolio':
      return const PortfolioScreen();
  }

  switch (tipo) {
    case TipoNotificacao.documento:
      return const DocumentsScreen();
    case TipoNotificacao.comercial:
      return const PortfolioScreen(apenasAVendaInicial: true);
    case TipoNotificacao.obra:
    case TipoNotificacao.geral:
      return null;
  }
}

/// O empreendimento de um caminho do site. Aceita as três formas que existem:
/// `/empreendimento?projectId=1` (a que a API escreve), `/empreendimento?p=peP0Pc`
/// (a do site, com o id ofuscado) e a ficha da fração,
/// `/empreendimento/fracao?p=...`, que na app abre o empreendimento.
int? projetoDoHref(String? href) {
  if (href == null || href.isEmpty) return null;
  final uri = Uri.tryParse(href);
  if (uri == null || !uri.path.startsWith('/empreendimento')) return null;
  final numero = int.tryParse(uri.queryParameters['projectId'] ?? '');
  if (numero != null && numero > 0) return numero;
  return IdPublico.descodificar(uri.queryParameters['p']);
}
