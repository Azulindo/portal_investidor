import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../widgets/co_card.dart';
import '../widgets/co_drawer.dart';
import '../services/api_service.dart';
import '../utils/carteira.dart';
import 'alterar_password_screen.dart';
import 'login_screen.dart';

/// Um número com a sua etiqueta, nos dois cartões do topo do perfil.
///
/// Os dois textos encolhem em vez de mudarem de linha. Num cartão com metade
/// da largura do ecrã, "Empreendimentos" partia o "s" para a linha de baixo e
/// um total de sete dígitos ocupava três linhas — e os dois cartões, lado a
/// lado, ficavam com alturas diferentes.
class _Kpi extends StatelessWidget {
  const _Kpi({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return CoCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _numaLinha(Text(etiqueta, style: COText.small)),
          const SizedBox(height: 2),
          _numaLinha(Text(valor, style: COText.valor)),
        ],
      ),
    );
  }

  /// Encolhe o texto até caber, em vez de o deixar partir.
  Widget _numaLinha(Text texto) => SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: texto,
        ),
      );
}

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
    await ApiService.sair();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (c, a1, a2) => const LoginScreen(),
          transitionsBuilder: (c, anim, a2, child) =>
              FadeTransition(opacity: anim, child: child),
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(COTokens.radiusSm),
        ),
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
              const Icon(
                Icons.support_agent_rounded,
                size: 50,
                color: COColors.brand300,
              ),
              const SizedBox(height: COTokens.space4),
              const Text(
                'Precisas de ajuda?',
                style: TextStyle(
                  color: COColors.white,
                  fontSize: 18,
                  fontWeight: COTokens.fwBold,
                ),
              ),
              const SizedBox(height: COTokens.space2),
              const Text(
                'A nossa equipa está disponível para te ajudar com o teu imóvel.',
                textAlign: TextAlign.center,
                style: TextStyle(color: COColors.neutral500, fontSize: 14),
              ),
              const SizedBox(height: COTokens.space8),

              // Telefone
              ListTile(
                leading: const Icon(
                  Icons.phone_outlined,
                  color: COColors.brand300,
                ),
                title: const Text(
                  '+351 912 923 952',
                  style: TextStyle(color: COColors.white),
                ),
                tileColor: COColors.brand700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(COTokens.radiusSm),
                ),
                onTap: () =>
                    _launchUrl(Uri(scheme: 'tel', path: '+351912923952')),
              ),
              const SizedBox(height: COTokens.space2),

              // Email
              ListTile(
                leading: const Icon(
                  Icons.email_outlined,
                  color: COColors.brand300,
                ),
                title: const Text(
                  'geral@cleveroption.pt',
                  style: TextStyle(color: COColors.white),
                ),
                tileColor: COColors.brand700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(COTokens.radiusSm),
                ),
                onTap: () => _launchUrl(
                  Uri(scheme: 'mailto', path: 'geral@cleveroption.pt'),
                ),
              ),
              const SizedBox(height: COTokens.space2),

              // Morada (apenas visual, sem acção)
              ListTile(
                leading: const Icon(
                  Icons.location_on_outlined,
                  color: COColors.brand300,
                ),
                title: const Text(
                  'Via Eng. Edgar Cardoso 23, 5.º D, Vila Nova de Gaia',
                  style: TextStyle(color: COColors.white, fontSize: 13),
                ),
                tileColor: COColors.brand700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(COTokens.radiusSm),
                ),
              ),
              const SizedBox(height: COTokens.space6),
            ],
          ),
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
        title: Text(
          title,
          style: const TextStyle(
            color: COColors.white,
            fontSize: 14,
            fontWeight: COTokens.fwMedium,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: COColors.brand500,
          size: 20,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = ApiService.dadosLogado?.name ?? 'Cliente';
    final email = ApiService.dadosLogado?.email ?? 'Sem email associado';
    final totalInvestido = ApiService.dadosLogado?.totalInvested ?? 0.0;
    // O ROI saiu: a API não tem campo nenhum para isso, por isso aparecia
    // sempre "0,0%" a toda a gente. No lugar fica o número de empreendimentos,
    // que vem mesmo de /user/:id.
    final nEmpreendimentos = ApiService.dadosLogado?.obras.length ?? 0;

    return Scaffold(
      backgroundColor: COColors.brand900,
      drawer: const CoDrawer(),
      appBar: AppBar(
        title: const Text('Perfil', style: COText.tituloEcra),
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
                      style: const TextStyle(
                        color: COColors.white,
                        fontSize: 24,
                        fontWeight: COTokens.fwBold,
                      ),
                    ),
                  ),
                  const SizedBox(height: COTokens.space4),
                  Text(
                    name,
                    style: const TextStyle(
                      color: COColors.white,
                      fontSize: 24,
                      fontWeight: COTokens.fwBold,
                    ),
                  ),
                  const SizedBox(height: COTokens.space2),
                  Text(
                    email,
                    style: const TextStyle(
                      color: COColors.neutral500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: COTokens.space8),

            // KPIs
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Kpi(
                      etiqueta: 'Valor total',
                      // Carteira.euros e nao toStringAsFixed: assim le-se
                      // "3 374 950 €" e nao "3374950.00 €", que alem de feio
                      // era tao comprido que partia em tres linhas.
                      valor: Carteira.euros(totalInvestido),
                    ),
                  ),
                  const SizedBox(width: COTokens.space4),
                  Expanded(
                    child: _Kpi(
                      etiqueta: 'Empreendimentos',
                      valor: '$nEmpreendimentos',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: COTokens.space9),

            const CoTitulo('Opções'),

            // Havia mais duas opções aqui, e saíram as duas. "Os Meus Dados"
            // só respondia "disponível em breve". "Segurança e Biometria"
            // dizia que a autenticação biométrica estava ativa — e a
            // biometria nunca foi feita, foi adiada. Uma afirmação falsa sobre
            // segurança é pior do que não ter a opção, e as lojas recusam
            // apps com funcionalidades que não fazem nada. Voltam quando
            // existirem.
            _buildMenuItem(
              Icons.lock_outline,
              'Alterar palavra-passe',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AlterarPasswordScreen(),
                ),
              ),
            ),
            _buildMenuItem(Icons.help_outline, 'Suporte', _mostrarSuporte),

            const SizedBox(height: COTokens.space8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _fazerLogout,
                style: OutlinedButton.styleFrom(
                  // brand300 e não brand500: o brand500 é cor de bordas, e
                  // como texto sobre o navy fica abaixo do contraste mínimo
                  // (há um teste que o diz). O botão mal se via.
                  side: const BorderSide(color: COColors.brand300, width: 1),
                  padding: const EdgeInsets.symmetric(
                    vertical: COTokens.space6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(COTokens.radiusSm),
                  ),
                ),
                child: const Text(
                  'Terminar sessão',
                  style: TextStyle(
                    color: COColors.brand300,
                    letterSpacing: 1.5,
                    fontWeight: COTokens.fwBold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: COTokens.space6),
          ],
        ),
      ),
    );
  }
}
