import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'theme/co_colors.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/privacy_service.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';

/// Chave global do Navigator, para permitir navegação a partir de locais
/// sem BuildContext próprio (ex: o ErrorWidget global abaixo).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Para conseguir mostrar um aviso depois de trocar de ecra, altura em que
/// o context do ecra antigo ja nao serve.
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🛡️ Tratamento global de erros de UI (evita tela vermelha e o "preso" no erro)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: COColors.brand900,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 64, color: COColors.brand300),
                const SizedBox(height: 16),
                Text(
                  'Ops! Algo correu mal.',
                  style: TextStyle(color: COColors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tente novamente mais tarde.',
                  style: TextStyle(color: COColors.brand300, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  // Em vez de re-lançar o erro (o que mantinha o utilizador
                  // preso neste ecrã), navega de volta para o Dashboard,
                  // que é sempre um destino seguro/conhecido.
                  onPressed: () {
                    navigatorKey.currentState?.pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: COColors.white,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: Text('VOLTAR AO INÍCIO',
                      style: TextStyle(color: COColors.brand900, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // CORRIGIDO: antes isto só decidia qual o ecrã inicial, mas nunca repunha
  // o estado em memória (ApiService.idLogado / token), por isso a app
  // arrancava sempre com idLogado == null e caía no fallback "?? 0".
  // "obterSessaoValida" também limpa a sessão guardada se o token (JWT) já
  // tiver expirado, em vez de mostrar a Dashboard e só falhar no 1º pedido.
  var userId = await AuthService.obterSessaoValida();
  if (userId != null) {
    ApiService.idLogado = userId;
    ApiService.definirToken(await AuthService.obterToken());
  }

  // Arranque direto no painel, para trabalhar nos ecrãs de dentro sem ter de
  // passar pelo login a cada recarregamento:
  //
  //   flutter run --dart-define=USE_MOCK=true --dart-define=SKIP_LOGIN=true
  //
  // Só funciona com USE_MOCK ligado — e com ele ligado a app não fala com a
  // API nenhuma, por isso isto não é uma porta para dados reais. Sem
  // USE_MOCK é ignorado.
  if (ApiConfig.useMock &&
      const bool.fromEnvironment('SKIP_LOGIN') &&
      userId == null) {
    userId = 999;
    ApiService.idLogado = userId;
  }

  // Se a sessao acabar com a app aberta, limpa-se o que esta guardado e
  // volta-se ao login com um aviso a dizer porque.
  //
  // Sao dois casos. O token morreu (401) — expirou, foi revogado, ou a API
  // reiniciou — e resolve-se a entrar outra vez. Ou a conta foi bloqueada
  // no backoffice (403), e aí entrar outra vez nao resolve nada: a
  // mensagem tem de dizer com quem falar. Antes nenhum deles reagia, e o
  // segundo nem sequer saía do ecrã.
  //
  // O aviso fica mais tempo no caso da conta bloqueada: tem um endereço de
  // email para a pessoa reter, e o tempo normal de um SnackBar não chega
  // para o ler.
  ApiService.aoExpirarSessao = (motivo) async {
    await AuthService.limparSessao();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(motivo.mensagem),
        backgroundColor: COColors.brand500,
        duration: motivo == FimDeSessao.bloqueada
            ? const Duration(seconds: 10)
            : const Duration(seconds: 4),
      ),
    );
  };

  runApp(
    ChangeNotifierProvider(
      create: (_) => PrivacyService(),
      child: CleverOptionApp(userIdInicial: userId),
    ),
  );
}

class CleverOptionApp extends StatelessWidget {
  final int? userIdInicial;

  const CleverOptionApp({super.key, this.userIdInicial});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Clever Option',
      theme: ThemeData(
        fontFamily: 'MonaSans',
        scaffoldBackgroundColor: COColors.brand900,
        appBarTheme: const AppBarTheme(
          backgroundColor: COColors.brand900,
          foregroundColor: COColors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      builder: (context, child) {
        // O tamanho de letra que a pessoa escolheu no telemóvel, limitado
        // entre 1x e 1,3x.
        //
        // Antes isto era TextScaler.linear(1.1), fixo. Dois problemas:
        //
        //  - deitava fora a definição de acessibilidade do sistema. Quem
        //    tem o telemóvel com letra grande porque precisa recebia na
        //    mesma 1,1x, e quem a tem pequena também. A app era a única a
        //    não obedecer.
        //  - multiplicava a escala do design system por 1,1, por isso os
        //    24/20/16/14/12 nunca eram os tamanhos verdadeiros.
        //
        // Com o clamp, o 1x é a escala do design system tal como está
        // escrita, e o máximo de 1,3x é o que os ecrãs aguentam sem partir
        // linhas — acima disso os cartões começam a cortar texto.
        final escala = MediaQuery.textScalerOf(context).clamp(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.3,
        );
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: escala),
          child: child!,
        );
      },
      home: userIdInicial != null ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
