import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/validacao_auth.dart';
import '../widgets/co_auth.dart';
import 'reenviar_confirmacao_screen.dart';

/// Criar conta.
///
/// Espelha o formulário do site (components/RegistoForm.tsx): os mesmos
/// campos, as mesmas regras e as mesmas mensagens. A conta é criada INATIVA e
/// a API envia um email de ativação, por isso no fim mostra-se o ecrã
/// "confirme o seu email" em vez de entrar logo.
class RegistoScreen extends StatefulWidget {
  const RegistoScreen({super.key});

  @override
  State<RegistoScreen> createState() => _RegistoScreenState();
}

class _RegistoScreenState extends State<RegistoScreen> {
  final _form = GlobalKey<FormState>();
  final _primeiroNome = TextEditingController();
  final _ultimoNome = TextEditingController();
  final _telemovel = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();

  bool _gdpr = false;
  bool _erroGdpr = false;
  bool _aEnviar = false;
  String? _erroServidor;

  /// Email para onde foi o link, quando o registo correu bem.
  String? _criadaPara;

  @override
  void dispose() {
    for (final c in [
      _primeiroNome,
      _ultimoNome,
      _telemovel,
      _email,
      _password,
      _confirmar,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submeter() async {
    setState(() {
      _erroServidor = null;
      _erroGdpr = !_gdpr;
    });

    final camposOk = _form.currentState?.validate() ?? false;
    if (!camposOk || !_gdpr) return;

    setState(() => _aEnviar = true);

    final (sucesso, mensagem) = await ApiService().registarJson(
      primeiroNome: _primeiroNome.text.trim(),
      ultimoNome: _ultimoNome.text.trim(),
      telemovel: _telemovel.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      aceitouTermos: true,
    );

    if (!mounted) return;
    setState(() {
      _aEnviar = false;
      if (sucesso) {
        _criadaPara = _email.text.trim();
      } else {
        _erroServidor = mensagem;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_criadaPara != null) return _ecraDeSucesso();

    return CoAuthScaffold(
      mostrarVoltar: true,
      titulo: 'Criar Conta',
      subtitulo:
          'Acesso exclusivo ao acompanhamento dos seus investimentos imobiliários.',
      filhos: [
        if (_erroServidor != null) CoAviso(texto: _erroServidor!),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CoCampo(
                controller: _primeiroNome,
                etiqueta: 'Primeiro nome',
                pista: 'ex. João',
                maiusculas: TextCapitalization.words,
                autofill: const [AutofillHints.givenName],
                validador: (v) => ValidacaoAuth.nome(v, campo: 'primeiro nome'),
              ),
              CoCampo(
                controller: _ultimoNome,
                etiqueta: 'Último nome',
                pista: 'ex. Silva',
                maiusculas: TextCapitalization.words,
                autofill: const [AutofillHints.familyName],
                validador: (v) => ValidacaoAuth.nome(v, campo: 'último nome'),
              ),
              CoCampo(
                controller: _email,
                etiqueta: 'Endereço de e-mail',
                pista: 'ex. joao.silva@email.com',
                tipo: TextInputType.emailAddress,
                autofill: const [AutofillHints.email],
                validador: ValidacaoAuth.email,
              ),
              CoCampo(
                controller: _telemovel,
                etiqueta: 'Número de telemóvel',
                pista: 'ex. +351 912 000 000',
                tipo: TextInputType.phone,
                maxLength: 20,
                autofill: const [AutofillHints.telephoneNumber],
                validador: ValidacaoAuth.telemovel,
              ),
              CoCampo(
                controller: _password,
                etiqueta: 'Palavra-passe',
                password: true,
                autofill: const [AutofillHints.newPassword],
                validador: ValidacaoAuth.password,
              ),
              CoCampo(
                controller: _confirmar,
                etiqueta: 'Confirmar palavra-passe',
                password: true,
                proximo: TextInputAction.done,
                validador: (v) =>
                    ValidacaoAuth.confirmacao(v, _password.text),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: COTokens.space6),
                child: Text(ValidacaoAuth.dicaPassword, style: COText.caption),
              ),
              _caixaGdpr(),
              const SizedBox(height: COTokens.space6),
              CoBotao(
                texto: 'Criar conta',
                aCarregar: _aEnviar,
                aoCarregar: _submeter,
              ),
            ],
          ),
        ),
      ],
      rodape: [
        CoLinkAuth(
          pergunta: 'Já tem uma conta?',
          acao: 'Inicie sessão',
          aoCarregar: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _caixaGdpr() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _gdpr,
                onChanged: (v) => setState(() {
                  _gdpr = v ?? false;
                  if (_gdpr) _erroGdpr = false;
                }),
                side: const BorderSide(color: COColors.brand300),
                checkColor: COColors.brand900,
                activeColor: COColors.white,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: COTokens.space2),
            Expanded(
              child: Text(
                'Li e aceito a Política de Privacidade e autorizo o tratamento '
                'dos meus dados pela Cleveroption para fins de acesso ao '
                'portal de investidores.',
                style: COText.small,
              ),
            ),
          ],
        ),
        if (_erroGdpr)
          Padding(
            padding: const EdgeInsets.only(top: COTokens.space2),
            child: Text(
              'É necessário aceitar a Política de Privacidade para continuar.',
              style: COText.caption.copyWith(color: const Color(0xFFFFB4A9)),
            ),
          ),
      ],
    );
  }

  Widget _ecraDeSucesso() {
    return CoAuthScaffold(
      titulo: 'Confirme o seu e-mail',
      subtitulo: 'A sua conta foi criada.',
      filhos: [
        CoAviso(
          erro: false,
          texto:
              'Enviámos um e-mail para $_criadaPara com um link de ativação. '
              'Clique nesse link para ativar a conta e poder iniciar sessão. '
              'O link é válido por 24 horas — verifique também a pasta de spam.',
        ),
        CoBotao(
          texto: 'Voltar ao início de sessão',
          aoCarregar: () => Navigator.pop(context),
        ),
      ],
      rodape: [
        CoLinkAuth(
          pergunta: 'Não recebeu o e-mail?',
          acao: 'Reenviar link',
          aoCarregar: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ReenviarConfirmacaoScreen(),
            ),
          ),
        ),
      ],
    );
  }
}
