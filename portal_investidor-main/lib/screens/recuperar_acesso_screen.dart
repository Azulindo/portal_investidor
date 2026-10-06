import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/co_tokens.dart';
import '../utils/validacao_auth.dart';
import '../widgets/co_auth.dart';

/// Ecrã de um campo só (email) para pedir um email à API.
///
/// Serve a recuperação de palavra-passe e o reenvio do email de confirmação,
/// porque os dois são exatamente o mesmo formulário com outro texto e outro
/// endpoint. As fábricas abaixo (`RecuperarAcessoScreen` e
/// `ReenviarConfirmacaoScreen`) são o que os outros ecrãs usam.
class PedidoPorEmailScreen extends StatefulWidget {
  const PedidoPorEmailScreen({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.textoBotao,
    required this.mensagemSucesso,
    required this.enviar,
  });

  final String titulo;
  final String subtitulo;
  final String textoBotao;

  /// O que se mostra depois de a API aceitar o pedido.
  final String mensagemSucesso;

  final Future<(bool, String)> Function(String email) enviar;

  @override
  State<PedidoPorEmailScreen> createState() => _PedidoPorEmailScreenState();
}

class _PedidoPorEmailScreenState extends State<PedidoPorEmailScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  bool _aEnviar = false;
  bool _enviado = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submeter() async {
    setState(() => _erro = null);
    if (!(_form.currentState?.validate() ?? false)) return;

    setState(() => _aEnviar = true);
    final (sucesso, mensagem) = await widget.enviar(_email.text.trim());

    if (!mounted) return;
    setState(() {
      _aEnviar = false;
      if (sucesso) {
        _enviado = true;
      } else {
        _erro = mensagem;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_enviado) {
      return CoAuthScaffold(
        mostrarVoltar: true,
        titulo: 'Verifique o seu e-mail',
        filhos: [
          CoAviso(erro: false, texto: widget.mensagemSucesso),
          CoBotao(
            texto: 'Voltar ao início de sessão',
            // Volta ao login mesmo quando se chegou aqui a partir do registo,
            // que já tem um ecrã pelo meio.
            aoCarregar: () =>
                Navigator.of(context).popUntil((rota) => rota.isFirst),
          ),
        ],
      );
    }

    return CoAuthScaffold(
      mostrarVoltar: true,
      titulo: widget.titulo,
      subtitulo: widget.subtitulo,
      filhos: [
        if (_erro != null) CoAviso(texto: _erro!),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CoCampo(
                controller: _email,
                etiqueta: 'Endereço de e-mail',
                pista: 'ex. joao.silva@email.com',
                tipo: TextInputType.emailAddress,
                autofill: const [AutofillHints.email],
                proximo: TextInputAction.done,
                validador: ValidacaoAuth.email,
                aoSubmeter: (_) => _submeter(),
              ),
              const SizedBox(height: COTokens.space4),
              CoBotao(
                texto: widget.textoBotao,
                aCarregar: _aEnviar,
                aoCarregar: _submeter,
              ),
            ],
          ),
        ),
      ],
      rodape: [
        CoLinkAuth(
          pergunta: 'Já se lembrou?',
          acao: 'Inicie sessão',
          aoCarregar: () =>
              Navigator.of(context).popUntil((rota) => rota.isFirst),
        ),
      ],
    );
  }
}

/// "Esqueceu-se da palavra-passe?" → POST /auth/forgot-password.
///
/// A mensagem de sucesso é neutra de propósito: não diz se a conta existe,
/// para não se poder usar isto para descobrir quem está registado. É o mesmo
/// comportamento do site.
class RecuperarAcessoScreen extends StatelessWidget {
  const RecuperarAcessoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PedidoPorEmailScreen(
      titulo: 'Recuperar acesso',
      subtitulo:
          'Indique o e-mail da sua conta e enviamos-lhe um link para definir '
          'uma nova palavra-passe.',
      textoBotao: 'Enviar link',
      mensagemSucesso:
          'Se existir uma conta com esse e-mail, enviámos um link para '
          'definir uma nova palavra-passe. O link é válido por tempo '
          'limitado — verifique também a pasta de spam.',
      enviar: ApiService().recuperarAcesso,
    );
  }
}
