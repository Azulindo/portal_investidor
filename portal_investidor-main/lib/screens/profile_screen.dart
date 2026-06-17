import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../widgets/co_drawer.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Método auxiliar para abrir URLs (telefone, email, etc.)
  Future<void> _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o link.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _fazerLogout() async {
    await AuthService.limparSessao();
    ApiService.idLogado = null;
    ApiService.dadosLogado = null;
    ApiService.definirToken(null);
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (c, a1, a2) => const LoginScreen(),
          transitionsBuilder: (c, anim, a2, child) => FadeTransition(opacity: anim, child: child),
        ),
        (route) => false,
      );
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _mostrarSuporte() {
    showModalBottomSheet(
      context: context,
      backgroundColor: COColors.brand900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(COTokens.radiusSm)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(COTokens.space6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: COColors.brand700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: COTokens.space6),
              const Icon(Icons.support_agent_rounded, size: 50, color: COColors.brand300),
              const SizedBox(height: COTokens.space4),
              const Text(
                'Precisas de ajuda?',
                style: TextStyle(color: COColors.white, fontSize: 18, fontWeight: COTokens.fwBold),
              ),
              const SizedBox(height: COTokens.space2),
              const Text(
                'A nossa equipa está disponível para te ajudar com os teus investimentos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: COColors.neutral500, fontSize: 14),
              ),
              const SizedBox(height: COTokens.space8),

              // Telefone
              ListTile(
                leading: const Icon(Icons.phone_outlined, color: COColors.brand300),
                title: const Text('+351 912 923 952', style: TextStyle(color: COColors.white)),
                tileColor: COColors.brand700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(COTokens.radiusSm)),
                onTap: () => _launchUrl(Uri(scheme: 'tel', path: '+351912923952')),
              ),
              const SizedBox(height: COTokens.space2),

              // Email
              ListTile(
                leading: const Icon(Icons.email_outlined, color: COColors.brand300),
                title: const Text('geral@cleveroption.pt', style: TextStyle(color: COColors.white)),
                tileColor: COColors.brand700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(COTokens.radiusSm)),
                onTap: () => _launchUrl(Uri(scheme: 'mailto', path: 'geral@cleveroption.pt')),
              ),
              const SizedBox(height: COTokens.space2),

              // Morada (apenas visual, sem acção)
              ListTile(
                leading: const Icon(Icons.location_on_outlined, color: COColors.brand300),
                title: const Text(
                  'Via Eng. Edgar Cardoso 23, 5.º D, Vila Nova de Gaia',
                  style: TextStyle(color: COColors.white, fontSize: 13),
                ),
                tileColor: COColors.brand700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(COTokens.radiusSm)),
              ),
              const SizedBox(height: COTokens.space6),
            ],
          ),
        );
      },
    );
  }

  void _mostrarBiometria() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: COColors.brand900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(COTokens.radiusSm),
            side: const BorderSide(color: COColors.brand700),
          ),
          title: const Row(
            children: [
              Icon(Icons.fingerprint, color: COColors.brand300),
              SizedBox(width: 10),
              Text('Segurança', style: TextStyle(color: COColors.white, fontSize: 16, fontWeight: COTokens.fwBold)),
            ],
          ),
          content: const Text(
            'A autenticação biométrica (Face ID / Impressão Digital) está ativa para o teu dispositivo. Os teus dados estão protegidos.',
            style: TextStyle(color: COColors.neutral500, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('FECHAR', style: TextStyle(color: COColors.brand300, fontWeight: COTokens.fwBold, letterSpacing: 1)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: COTokens.space4),
      decoration: BoxDecoration(
        color: COColors.brand700,
        borderRadius: BorderRadius.circular(COTokens.radiusSm),
      ),
      child: ListTile(
        leading: Icon(icon, color: COColors.brand300, size: 24),
        title: Text(title, style: const TextStyle(color: COColors.white, fontSize: 14, fontWeight: COTokens.fwMedium)),
        trailing: const Icon(Icons.chevron_right, color: COColors.brand500, size: 20),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = ApiService.dadosLogado?.name ?? 'Investidor';
    final email = ApiService.dadosLogado?.email ?? 'Sem email associado';
    final totalInvestido = ApiService.dadosLogado?.totalInvested ?? 0.0;
    final roiEsperado = ApiService.dadosLogado?.roiEsperado ?? 0.0;

    return Scaffold(
      backgroundColor: COColors.brand900,
      drawer: const CoDrawer(),
      appBar: AppBar(
        title: const Text('PERFIL',
            style: TextStyle(letterSpacing: 1.5, fontSize: 13, fontWeight: COTokens.fwBold, color: COColors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: COColors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(COTokens.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: COColors.brand700,
                    child: Text(
                      _getInitials(name),
                      style: const TextStyle(color: COColors.white, fontSize: 24, fontWeight: COTokens.fwBold),
                    ),
                  ),
                  const SizedBox(height: COTokens.space4),
                  Text(name, style: const TextStyle(color: COColors.white, fontSize: 24, fontWeight: COTokens.fwBold)),
                  const SizedBox(height: COTokens.space2),
                  Text(email, style: const TextStyle(color: COColors.neutral500, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: COTokens.space8),

            // KPIs
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(COTokens.space6),
                    decoration: BoxDecoration(
                      color: COColors.brand700,
                      borderRadius: BorderRadius.circular(COTokens.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL INVESTIDO',
                            style: TextStyle(
                                color: COColors.neutral500, fontSize: 11, fontWeight: COTokens.fwMedium, letterSpacing: 1)),
                        const SizedBox(height: COTokens.space2),
                        Text('${totalInvestido.toStringAsFixed(2)} €',
                            style: const TextStyle(color: COColors.brand300, fontSize: 20, fontWeight: COTokens.fwBold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: COTokens.space4),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(COTokens.space6),
                    decoration: BoxDecoration(
                      color: COColors.brand700,
                      borderRadius: BorderRadius.circular(COTokens.radiusSm),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ROI ESPERADO',
                            style: TextStyle(
                                color: COColors.neutral500, fontSize: 11, fontWeight: COTokens.fwMedium, letterSpacing: 1)),
                        const SizedBox(height: COTokens.space2),
                        Text('${roiEsperado.toStringAsFixed(1)}%',
                            style: const TextStyle(color: COColors.brand300, fontSize: 20, fontWeight: COTokens.fwBold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: COTokens.space8),

            const Text('OPÇÕES',
                style: TextStyle(color: COColors.neutral500, fontSize: 11, fontWeight: COTokens.fwBold, letterSpacing: 1.5)),
            const SizedBox(height: COTokens.space4),

            _buildMenuItem(Icons.person, 'Os Meus Dados', () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edição de perfil disponível em breve!'), backgroundColor: COColors.brand500),
              );
            }),
            _buildMenuItem(Icons.fingerprint, 'Segurança e Biometria', _mostrarBiometria),
            _buildMenuItem(Icons.help_outline, 'Suporte', _mostrarSuporte),

            const SizedBox(height: COTokens.space8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _fazerLogout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: COColors.brand500, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: COTokens.space6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(COTokens.radiusSm)),
                ),
                child: const Text('TERMINAR SESSÃO',
                    style: TextStyle(color: COColors.brand500, letterSpacing: 1.5, fontWeight: COTokens.fwBold, fontSize: 13)),
              ),
            ),
            const SizedBox(height: COTokens.space6),
          ],
        ),
      ),
    );
  }
}
