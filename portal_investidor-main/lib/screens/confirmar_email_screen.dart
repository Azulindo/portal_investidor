import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/co_tokens.dart';
import '../utils/token_de_email.dart';
import '../utils/validacao_auth.dart';
import '../widgets/co_auth.dart';

/// Confirma a conta a partir do link que veio no email de registo.
///
/// O ApiConfig.confirmEmailEndpoint estava declarado e nunca era usado: quem
/// se registava na app tinha de ir ao browser confirmar e so depois voltar.
class ConfirmarEmailScreen extends StatefulWidget {
  const ConfirmarEmailScreen({super.key});

  @override
  State<ConfirmarEmailScreen> createState() => _ConfirmarEmailScreenState();
}

class _ConfirmarEmailScreenState extends State<ConfirmarEmailScreen> {
  final _form = GlobalKey<FormState>();
  final _link = TextEditingController();

  bool _aEnviar = false;
  bool _confirmado = false;
  String? _erro;
  String _mensagemBoa = 'Conta confirmada.';

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _submeter() async {
    setState(() => _erro = null);
    if (!(_form.currentState?.validate() ?? false)) return;

    final token = TokenDeEmail.extrair(_link.text);
    if (token == null) {
      setState(() => _erro =
          'Não encontrámos o código nesse texto. Copie o endereço completo '
          'do link que recebeu por e-mail.');
      return;
    }

    setState(() => _aEnviar = true);
    final (sucesso, mensagem) = await ApiService().confirmarEmail(token);

    if (!mounted) return;
    setState(() {
      _aEnviar = false;
      if (sucesso) {
        _confirmado = true;
        _mensagemBoa = mensagem;
      } else {
        _erro = mensagem;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_confirmado) {
      return CoAuthScaffold(
        mostrarVoltar: true,
        titulo: 'Conta confirmada',
        filhos: [
          CoAviso(erro: false, texto: _mensagemBoa),
          CoBotao(
            texto: 'Iniciar sessão',
            aoCarregar: () =>
                Navigator.of(context).popUntil((rota) => rota.isFirst),
          ),
        ],
      );
    }

    return CoAuthScaffold(
      mostrarVoltar: true,
      titulo: 'Confirmar a conta',
      subtitulo:
          'Abra o e-mail de confirmação, copie o endereço do link e cole-o '
          'aqui.',
      filhos: [
        if (_erro != null) CoAviso(texto: _erro!),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CoCampo(
                controller: _link,
                etiqueta: 'Link do e-mail',
                pista: 'cole aqui o endereço do link',
                tipo: TextInputType.url,
                proximo: TextInputAction.done,
                validador: (v) => ValidacaoAuth.obrigatorio(
                  v,
                  'Cole o link que recebeu por e-mail.',
                ),
                aoSubmeter: (_) => _submeter(),
              ),
              const SizedBox(height: COTokens.space4),
              CoBotao(
                texto: 'Confirmar',
                aCarregar: _aEnviar,
                aoCarregar: _submeter,
              ),
            ],
          ),
        ),
      ],
      rodape: [
        CoLinkAuth(
          pergunta: 'Já confirmou?',
          acao: 'Inicie sessão',
          aoCarregar: () =>
              Navigator.of(context).popUntil((rota) => rota.isFirst),
        ),
      ],
    );
  }
}
