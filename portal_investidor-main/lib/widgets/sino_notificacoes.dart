import 'package:flutter/material.dart';

import '../screens/notificacoes_screen.dart';
import '../services/api_service.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';

/// O sininho do cabecalho, com a contagem de notificacoes por ler.
///
/// A contagem vem do `unreadCount` da API e nao de contar a lista: a API
/// conta sobre todas as visiveis e manda no maximo 30, por isso contar a
/// lista dava um numero preso nas 30 a quem tivesse mais do que isso por ler.
///
/// Se o pedido falhar nao aparece nada. Um sino sem numero nao mente a
/// ninguem; um erro no cabecalho do painel so estorvava.
class SinoNotificacoes extends StatefulWidget {
  const SinoNotificacoes({super.key});

  @override
  State<SinoNotificacoes> createState() => _SinoNotificacoesState();
}

class _SinoNotificacoesState extends State<SinoNotificacoes> {
  int _naoLidas = 0;

  @override
  void initState() {
    super.initState();
    _contar();
  }

  Future<void> _contar() async {
    try {
      final resposta = await ApiService().buscarNotificacoes();
      if (!mounted) return;
      setState(() => _naoLidas = resposta.naoLidas);
    } catch (_) {
      // De proposito em silencio: ver a conta acima.
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _naoLidas > 0
          ? '$_naoLidas por ler'
          : 'Notificações',
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificacoesScreen()),
        );
        // Ao voltar da lista a contagem mudou quase de certeza, porque quem
        // la entra costuma ler alguma coisa.
        _contar();
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 22,
            color: COColors.brand300,
          ),
          if (_naoLidas > 0)
            Positioned(
              right: -3,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints: const BoxConstraints(minWidth: 15),
                decoration: BoxDecoration(
                  color: COColors.accent,
                  borderRadius: BorderRadius.circular(8),
                  // O anel da cor do fundo separa o numero do icone por baixo,
                  // sem precisar de sombra.
                  border: Border.all(color: COColors.brand900, width: 1.5),
                ),
                child: Text(
                  // Acima de 9 fica "9+": tres digitos num circulo de 15px
                  // nao se leem, e o que interessa e que ha muitas.
                  _naoLidas > 9 ? '9+' : '$_naoLidas',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: COColors.brand900,
                    fontSize: 9,
                    fontWeight: COTokens.fwBold,
                    height: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
