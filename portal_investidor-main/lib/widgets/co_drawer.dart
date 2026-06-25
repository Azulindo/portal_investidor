import 'package:flutter/material.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../screens/dashboard_screen.dart';
import '../screens/portfolio_screen.dart';
import '../screens/documents_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/map_screen.dart';

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
                const Text('PORTAL DO INVESTIDOR', style: TextStyle(color: COColors.brand300, fontSize: 10, fontWeight: COTokens.fwBold, letterSpacing: 1.5)),
              ],
            ),
          ),
          const Divider(color: COColors.brand700, height: 1),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined, color: COColors.white),
            title: const Text('DASHBOARD', style: TextStyle(color: COColors.white, fontWeight: COTokens.fwMedium, fontSize: 12, letterSpacing: 0.5)),
            onTap: () => _navegarSuave(context, const DashboardScreen()), // <--- CORREÇÃO AQUI
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: COColors.white),
            title: const Text('O NOSSO PORTFÓLIO', style: TextStyle(color: COColors.white, fontWeight: COTokens.fwMedium, fontSize: 12, letterSpacing: 0.5)),
            onTap: () => _navegarSuave(context, const PortfolioScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined, color: COColors.white),
            title: const Text('MAPA', style: TextStyle(color: COColors.white, fontWeight: COTokens.fwMedium, fontSize: 12, letterSpacing: 0.5)),
            onTap: () => _navegarSuave(context, const MapScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.folder_shared_outlined, color: COColors.white),
            title: const Text('FATURAS', style: TextStyle(color: COColors.white, fontWeight: COTokens.fwMedium, fontSize: 12, letterSpacing: 0.5)),
            onTap: () => _navegarSuave(context, const DocumentsScreen()),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: COColors.brand700, height: 32),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: COColors.white),
            title: const Text('O MEU PERFIL', style: TextStyle(color: COColors.white, fontWeight: COTokens.fwMedium, fontSize: 12, letterSpacing: 0.5)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
          ),
        ],
      ),
    );
  }
}