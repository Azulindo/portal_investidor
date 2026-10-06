import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'recuperar_acesso_screen.dart';

/// "Não recebeu o e-mail de ativação?" → POST /auth/resend-confirmation.
///
/// Mesmo formulário da recuperação de acesso (ver PedidoPorEmailScreen), só
/// muda o texto e o endpoint.
class ReenviarConfirmacaoScreen extends StatelessWidget {
  const ReenviarConfirmacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PedidoPorEmailScreen(
      titulo: 'Reenviar confirmação',
      subtitulo:
          'Indique o e-mail com que criou a conta e enviamos novamente o '
          'link de ativação.',
      textoBotao: 'Reenviar link',
      mensagemSucesso:
          'Se existir uma conta por ativar com esse e-mail, enviámos um novo '
          'link de ativação, válido por 24 horas. Verifique também a pasta '
          'de spam.',
      enviar: ApiService().reenviarConfirmacao,
    );
  }
}
