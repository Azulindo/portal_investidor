import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/validacao_auth.dart';
import '../widgets/co_auth.dart';
import 'dashboard_screen.dart';
import 'recuperar_acesso_screen.dart';
import 'registo_screen.dart';

/// Início de sessão.
///
/// Tem os mesmos caminhos que o /login do site: entrar, criar conta e
/// recuperar acesso. O botão da biometria saiu daqui — só mostrava
/// "em manutenção", e um botão que não faz nada é pior do que não existir.
/// O código do AuthService para isso continua lá, para quando se acabar.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _aEntrar = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    setState(() => _erro = null);
    if (!(_form.currentState?.validate() ?? false)) return;

    setState(() => _aEntrar = true);

    final (sucesso, mensagem, userId, token) = await ApiService()
        .fazerLoginJson(_email.text.trim(), _password.text.trim());

    if (!mounted) return;

    if (!sucesso || userId == null) {
      setState(() {
        _aEntrar = false;
        _erro = mensagem;
      });
      return;
    }

    await AuthService.guardarSessao(userId, token);
    ApiService.idLogado = userId;
    ApiService.definirToken(token);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (c, a1, a2) => const DashboardScreen(),
        transitionsBuilder: (c, anim, a2, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _abrir(Widget ecra) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ecra));
  }

  @override
  Widget build(BuildContext context) {
    return CoAuthScaffold(
      titulo: 'Portal do Investidor',
      subtitulo: 'Acompanhe os seus investimentos imobiliários.',
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
                tipo: TextInputType.emailAddress,
                autofill: const [AutofillHints.email],
                validador: ValidacaoAuth.email,
              ),
              CoCampo(
                controller: _password,
                etiqueta: 'Palavra-passe',
                password: true,
                autofill: const [AutofillHints.password],
                proximo: TextInputAction.done,
                aoSubmeter: (_) => _entrar(),
                // No login não se valida a força: a palavra-passe já existe,
                // as regras aplicam-se a quem a cria.
                validador: (v) => ValidacaoAuth.obrigatorio(
                  v,
                  'Introduza a sua palavra-passe.',
                ),
              ),
              CoBotao(
                texto: 'Entrar',
                aCarregar: _aEntrar,
                aoCarregar: _entrar,
              ),
            ],
          ),
        ),
      ],
      rodape: [
        CoLinkAuth(
          pergunta: 'Esqueceu-se da palavra-passe?',
          acao: 'Recuperar acesso',
          aoCarregar: () => _abrir(const RecuperarAcessoScreen()),
        ),
        CoLinkAuth(
          pergunta: 'Ainda não tem conta?',
          acao: 'Criar conta',
          aoCarregar: () => _abrir(const RegistoScreen()),
        ),
      ],
    );
  }
}
