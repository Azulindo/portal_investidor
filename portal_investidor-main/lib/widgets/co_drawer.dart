import 'package:flutter/material.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../screens/contactos_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/portfolio_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/privacidade_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/map_screen.dart';
import '../screens/sobre_screen.dart';

/// O estilo dos itens do menu.
///
/// Estava escrito a mao nove vezes, igual nas nove — bastava alguem mexer
/// num para o menu ficar desalinhado consigo proprio. Os rotulos tambem
/// estavam em MAIUSCULAS, que era a ultima superficie da app ainda a
/// gritar depois de os titulos das seccoes terem passado a caixa de frase.
/// A 14px tambem se le melhor do que a 12px, e o alvo do dedo cresce.
const TextStyle _estiloItem = TextStyle(
  color: COColors.white,
  fontWeight: COTokens.fwMedium,
  fontSize: 14,
);

class CoDrawer extends StatelessWidget {
  const CoDrawer({super.key});

  void _navegarSuave(BuildContext context, Widget destino) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destino,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: COColors.brand900,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: COColors.brand900,
              border: Border(bottom: BorderSide(color: COColors.brand700, width: 1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset('assets/images/logo.png', height: 55),
                const SizedBox(height: COTokens.space2),
                const Text('Portal do investidor', style: TextStyle(color: COColors.brand300, fontSize: 12)),
              ],
            ),
          ),
          const Divider(color: COColors.brand700, height: 1),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined, color: COColors.white),
            title: const Text('Dashboard', style: _estiloItem),
            onTap: () => _navegarSuave(context, const DashboardScreen()), // <--- CORREÇÃO AQUI
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: COColors.white),
            title: const Text('O nosso portfólio', style: _estiloItem),
            onTap: () => _navegarSuave(context, const PortfolioScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.sell_outlined, color: COColors.white),
            title: const Text('Em comercialização', style: _estiloItem),
            // No site é uma página à parte, mas a lista é a mesma do
            // portfólio com o filtro ligado — abre-se já filtrado em vez de
            // se duplicar o ecrã.
            onTap: () => _navegarSuave(
              context,
              const PortfolioScreen(apenasAVendaInicial: true),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined, color: COColors.white),
            title: const Text('Mapa', style: _estiloItem),
            onTap: () => _navegarSuave(context, const MapScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.folder_shared_outlined, color: COColors.white),
            title: const Text('Faturas', style: _estiloItem),
            onTap: () => _navegarSuave(context, const DocumentsScreen()),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: COColors.brand700, height: 32),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: COColors.white),
            title: const Text('O meu perfil', style: _estiloItem),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: COColors.white),
            title: const Text('Sobre nós', style: _estiloItem),
            onTap: () => _navegarSuave(context, const SobreScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.alternate_email_outlined, color: COColors.white),
            title: const Text('Contactos', style: _estiloItem),
            onTap: () => _navegarSuave(context, const ContactosScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: COColors.white),
            title: const Text('Privacidade', style: _estiloItem),
            onTap: () => _navegarSuave(context, const PrivacidadeScreen()),
          ),
        ],
      ),
    );
  }
}