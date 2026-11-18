import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/co_tokens.dart';
import '../utils/validacao_auth.dart';
import '../widgets/co_auth.dart';

/// Muda a palavra-passe de quem já tem sessão iniciada (Perfil → Alterar
/// palavra-passe). É o POST /auth/change-password, o mesmo do site.
///
/// Diferente do RedefinirPasswordScreen, que é para quem se esqueceu dela e
/// vem do link do email. Aqui pede-se a atual, e a sessão continua: a API só
/// termina as sessões noutros aparelhos.
class AlterarPasswordScreen extends StatefulWidget {
  const AlterarPasswordScreen({super.key});

  @override
  State<AlterarPasswordScreen> createState() => _AlterarPasswordScreenState();
}

class _AlterarPasswordScreenState extends State<AlterarPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _confirmacao = TextEditingController();

  bool _aEnviar = false;
  bool _pronto = false;
  String? _erro;

  @override
  void dispose() {
    _atual.dispose();
    _nova.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  Future<void> _submeter() async {
    setState(() => _erro = null);
    if (!(_form.currentState?.validate() ?? false)) return;

    setState(() => _aEnviar = true);
    final (sucesso, mensagem) =
        await ApiService().alterarPassword(_atual.text, _nova.text);

    if (!mounted) return;
    setState(() {
      _aEnviar = false;
      if (sucesso) {
        _pronto = true;
      } else {
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
            texto: 'A partir de agora entra com a nova palavra-passe. Se tinha '
                'sessão iniciada noutros aparelhos, lá vai ter de entrar outra '
                'vez.',
          ),
          CoBotao(
            texto: 'Voltar ao perfil',
            aoCarregar: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }

    return CoAuthScaffold(
      mostrarVoltar: true,
      titulo: 'Alterar palavra-passe',
      subtitulo: 'Confirme a palavra-passe atual e escolha a nova.',
      filhos: [
        if (_erro != null) CoAviso(texto: _erro!),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CoCampo(
                  controller: _atual,
                  etiqueta: 'Palavra-passe atual',
                  password: true,
                  autofill: const [AutofillHints.password],
                  validador: (v) => ValidacaoAuth.obrigatorio(
                    v,
                    'Introduza a palavra-passe atual.',
                  ),
                ),
                const SizedBox(height: COTokens.space4),
                CoCampo(
                  controller: _nova,
                  etiqueta: 'Nova palavra-passe',
                  pista: ValidacaoAuth.dicaPassword,
                  password: true,
                  autofill: const [AutofillHints.newPassword],
                  validador: (v) =>
                      ValidacaoAuth.novaDiferente(v, _atual.text) ??
                      ValidacaoAuth.password(v),
                ),
                const SizedBox(height: COTokens.space4),
                CoCampo(
                  controller: _confirmacao,
                  etiqueta: 'Repita a nova palavra-passe',
                  password: true,
                  autofill: const [AutofillHints.newPassword],
                  proximo: TextInputAction.done,
                  validador: (v) => ValidacaoAuth.confirmacao(v, _nova.text),
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
        ),
      ],
    );
  }
}
