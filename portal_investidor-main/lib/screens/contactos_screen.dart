import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../widgets/co_card.dart';
import '../widgets/co_drawer.dart';

/// Contactos — o equivalente ao /contactos do site.
///
/// Os dados são os mesmos do site (app/contactos/page.tsx). Estão escritos
/// aqui porque no site também estão escritos na página: não há endpoint na
/// API que os devolva. Se mudarem, mudam-se nos dois sítios.
///
/// O formulário de mensagem do site é uma iframe do Odoo
/// (odoo.cleveroption.pt/contactus) — não há endpoint para o submeter, por
/// isso não dá para fazer um formulário nativo que vá a algum lado. Em vez
/// de meter uma página do Odoo dentro de uma webview (que ia ficar com outro
/// aspeto no meio da app, e obrigava a mais uma dependência), abre-se no
/// browser do telefone. As três formas diretas de falar — telefone, email e
/// morada — ficam nativas e a um toque, que no telemóvel é o que se usa.
class ContactosScreen extends StatefulWidget {
  const ContactosScreen({super.key});

  @override
  State<ContactosScreen> createState() => _ContactosScreenState();
}

class _ContactosScreenState extends State<ContactosScreen> {
  static const String _telefone = '+351912923952';
  static const String _telefoneVisivel = '+351 912 923 952';
  static const String _email = 'geral@cleveroption.pt';
  static const String _morada =
      'Via Eng. Edgar Cardoso 23, 5.º D, Vila Nova de Gaia';
  static const String _formulario = 'https://odoo.cleveroption.pt/contactus';

  /// Link para a Política de Privacidade do site.
  ///
  /// Está vazio porque o domínio público do site ainda não está em lado
  /// nenhum do repositório (não há metadataBase nem SITE_URL), e um link
  /// inventado era pior do que não haver link. Quando se souber o domínio, é
  /// só pôr aqui o URL de /privacidade e o link aparece.
  static const String _privacidade = '';

  static const List<({String nome, String url})> _redes = [
    (nome: 'Instagram', url: 'https://www.instagram.com/cleveroption.pt/'),
    (nome: 'LinkedIn', url: 'https://www.linkedin.com/company/cleveroption/'),
    (nome: 'Facebook', url: 'https://www.facebook.com/cleveroptionconstrucao'),
  ];

  Future<void> _abrir(Uri uri, String seFalhar) async {
    // Sem app capaz de abrir o esquema (um tablet sem telefone, por
    // exemplo), launchUrl devolve false em vez de rebentar — daí a mensagem.
    bool ok;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(seFalhar), backgroundColor: COColors.brand700),
      );
    }
  }

  void _copiarMorada() {
    _abrir(
      Uri.parse(
        'https://www.google.com/maps/search/?api=1'
        '&query=${Uri.encodeQueryComponent(_morada)}',
      ),
      'Não foi possível abrir o mapa.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: COColors.brand900,
      appBar: AppBar(
        backgroundColor: COColors.brand900,
        title: Text(
          'CONTACTOS',
          style: COText.small.copyWith(
            color: COColors.white,
            fontSize: 13,
            fontWeight: COTokens.fwBold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: COColors.white),
        elevation: 0,
      ),
      drawer: const CoDrawer(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          COTokens.space6,
          COTokens.space2,
          COTokens.space6,
          COTokens.space12,
        ),
        children: [
          const CoOverline('Fale connosco'),
          Text('Estamos disponíveis para si', style: COText.h1),
          const SizedBox(height: COTokens.space8),

          _linhaContacto(
            icone: Icons.phone_outlined,
            etiqueta: 'Telemóvel',
            valor: _telefoneVisivel,
            aoCarregar: () => _abrir(
              Uri.parse('tel:$_telefone'),
              'Não foi possível abrir o telefone.',
            ),
          ),
          _linhaContacto(
            icone: Icons.mail_outline,
            etiqueta: 'Email',
            valor: _email,
            aoCarregar: () => _abrir(
              Uri.parse('mailto:$_email'),
              'Não foi possível abrir o email.',
            ),
          ),
          _linhaContacto(
            icone: Icons.place_outlined,
            etiqueta: 'Morada',
            valor: _morada,
            aoCarregar: _copiarMorada,
          ),

          const SizedBox(height: COTokens.space4),
          CoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CoOverline('Enviar uma mensagem'),
                Text(
                  'O formulário de contacto abre no browser do telefone.',
                  style: COText.small,
                ),
                const SizedBox(height: COTokens.space4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _abrir(
                      Uri.parse(_formulario),
                      'Não foi possível abrir o formulário.',
                    ),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(
                      'ABRIR FORMULÁRIO',
                      style: COText.small.copyWith(
                        fontWeight: COTokens.fwBold,
                        letterSpacing: 1.5,
                        color: COColors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: COColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: const BorderSide(
                        color: COColors.brand300,
                        width: COTokens.borderWidth,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.all(Radius.circular(COTokens.radiusNone)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          CoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CoOverline('Redes sociais'),
                Wrap(
                  spacing: COTokens.space6,
                  runSpacing: COTokens.space2,
                  children: [
                    for (final rede in _redes)
                      InkWell(
                        onTap: () => _abrir(
                          Uri.parse(rede.url),
                          'Não foi possível abrir o ${rede.nome}.',
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            rede.nome,
                            style: COText.small.copyWith(
                              color: COColors.white,
                              fontWeight: COTokens.fwMedium,
                              decoration: TextDecoration.underline,
                              decorationColor: COColors.brand300,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Nota do RGPD, igual à do site mas resumida ao que importa aqui:
          // no site acompanha o formulário, e aqui o formulário é um link.
          Text(
            'Ao enviar o formulário, autoriza o tratamento dos seus dados pela '
            'Cleveroption para resposta ao seu pedido, nos termos do RGPD. Os '
            'dados não são partilhados com terceiros para fins de marketing '
            'sem o seu consentimento. Pode exercer os direitos de acesso, '
            'retificação e eliminação através de $_email.',
            style: COText.caption,
          ),
          if (_privacidade.isNotEmpty) ...[
            const SizedBox(height: COTokens.space2),
            InkWell(
              onTap: () => _abrir(
                Uri.parse(_privacidade),
                'Não foi possível abrir a Política de Privacidade.',
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Política de Privacidade',
                  style: COText.caption.copyWith(
                    color: COColors.brand300,
                    decoration: TextDecoration.underline,
                    decorationColor: COColors.brand300,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Cartão de um contacto: etiqueta pequena, valor grande, tudo clicável.
  Widget _linhaContacto({
    required IconData icone,
    required String etiqueta,
    required String valor,
    required VoidCallback aoCarregar,
  }) {
    return CoCard(
      onTap: aoCarregar,
      margin: const EdgeInsets.only(bottom: COTokens.space4),
      child: Row(
        children: [
          Icon(icone, color: COColors.brand300, size: 20),
          const SizedBox(width: COTokens.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etiqueta.toUpperCase(), style: COText.overline),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: COText.body.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: COColors.neutral500,
            size: 18,
          ),
        ],
      ),
    );
  }
}
