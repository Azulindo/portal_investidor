import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/co_tokens.dart';
import '../utils/token_de_email.dart';
import '../utils/validacao_auth.dart';
import '../widgets/co_auth.dart';

/// Define a nova palavra-passe a partir do link que veio no email.
///
/// A app pedia o email de recuperacao e ficava por ali: o
/// ApiService.redefinirPassword existia e nunca era chamado por ninguem, por
/// isso quem estava no telemovel tinha de ir ao browser acabar o que tinha
/// comecado aqui.
///
/// Enquanto nao houver deep links, cola-se o link do email. Ver
/// [TokenDeEmail].
class RedefinirPasswordScreen extends StatefulWidget {
  const RedefinirPasswordScreen({super.key});

  @override
  State<RedefinirPasswordScreen> createState() =>
      _RedefinirPasswordScreenState();
}

class _RedefinirPasswordScreenState extends State<RedefinirPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _link = TextEditingController();
  final _password = TextEditingController();
  final _confirmacao = TextEditingController();

  bool _aEnviar = false;
  bool _pronto = false;
  String? _erro;

  @override
  void dispose() {
    _link.dispose();
    _password.dispose();
    _confirmacao.dispose();
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
    final (sucesso, mensagem) =
        await ApiService().redefinirPassword(token, _password.text);

    if (!mounted) return;
    setState(() {
      _aEnviar = false;
      if (sucesso) {
        _pronto = true;
      } else {
        // A API diz se o link expirou ou se e invalido, e explica-se melhor
        // do que um texto nosso conseguiria.
        _erro = mensagem;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pronto) {
      return CoAuthScaffold(
        mostrarVoltar: true,
        titulo: 'Palavra-passe alterada',
        filhos: [
          const CoAviso(
            erro: false,
            texto: 'Já pode iniciar sessão com a nova palavra-passe.',
          ),
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
      titulo: 'Nova palavra-passe',
      subtitulo:
          'Abra o e-mail que lhe enviámos, copie o endereço do link e cole-o '
          'aqui. Depois escolha a nova palavra-passe.',
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
                validador: (v) => ValidacaoAuth.obrigatorio(
                  v,
                  'Cole o link que recebeu por e-mail.',
                ),
              ),
              const SizedBox(height: COTokens.space4),
              CoCampo(
                controller: _password,
                etiqueta: 'Nova palavra-passe',
                pista: ValidacaoAuth.dicaPassword,
                password: true,
                autofill: const [AutofillHints.newPassword],
                validador: ValidacaoAuth.password,
              ),
              const SizedBox(height: COTokens.space4),
              CoCampo(
                controller: _confirmacao,
                etiqueta: 'Repita a palavra-passe',
                password: true,
                autofill: const [AutofillHints.newPassword],
                proximo: TextInputAction.done,
                validador: (v) =>
                    ValidacaoAuth.confirmacao(v, _password.text),
                aoSubmeter: (_) => _submeter(),
              ),
              const SizedBox(height: COTokens.space4),
              CoBotao(
                texto: 'Guardar palavra-passe',
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
