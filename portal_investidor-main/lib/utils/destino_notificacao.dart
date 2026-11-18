import 'package:flutter/widgets.dart';

import '../models/notificacao.dart';
import '../screens/documents_screen.dart';
import '../screens/portfolio_screen.dart';
import '../screens/project_details_screen.dart';

/// Para onde leva quem toca numa notificação — na lista do sininho e nas
/// notificações push, que têm de levar ao mesmo sítio.
///
///  - de um empreendimento: abre-o;
///  - de documentos (faturas): abre as faturas;
///  - comercial sem empreendimento: abre o que está em comercialização;
///  - o resto (geral): não há mais nada para ver além do texto, que o cartão
///    já mostra por inteiro. Devolve null.
Widget? destinoDaNotificacao({
  required TipoNotificacao tipo,
  int? projectId,
  int? notificationId,
}) {
  if (projectId != null) {
    return ProjectDetailsScreen(
      projectId: projectId,
      heroTag: 'notificacao-$notificationId-$projectId',
      initialImageUrl: '',
    );
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
