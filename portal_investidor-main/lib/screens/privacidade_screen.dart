import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../widgets/co_card.dart';
import '../widgets/co_drawer.dart';

/// Política de Privacidade — o /privacidade do site.
///
/// O texto está copiado palavra por palavra, incluindo a data da última
/// atualização e a nota final. É texto legal: não é para resumir nem para
/// reescrever com outras palavras, e se mudar no site tem de mudar aqui.
class PrivacidadeScreen extends StatelessWidget {
  const PrivacidadeScreen({super.key});

  static const String _email = 'geral@cleveroption.pt';

  /// Cada secção: o título e os parágrafos ou alíneas.
  static const List<({String titulo, List<String> paragrafos, List<String> alineas})>
      _secoes = [
    (
      titulo: '1. Responsável pelo tratamento',
      paragrafos: [
        'A Cleveroption — Investimentos Imobiliários é responsável pelo '
            'tratamento dos dados pessoais recolhidos através deste website '
            'e da aplicação móvel Cleveroption. Para qualquer questão '
            'relativa a proteção de dados, contacte $_email.',
      ],
      alineas: [],
    ),
    (
      titulo: '2. Dados recolhidos',
      paragrafos: [
        'Recolhemos os dados que nos fornece voluntariamente através dos '
            'formulários de contacto (nome, email, telefone e mensagem), bem '
            'como dados técnicos de navegação estritamente necessários ao '
            'funcionamento do site.',
        'Se criar conta na Área Reservada — no site ou na aplicação móvel —, '
            'tratamos também o seu nome, email, telefone e palavra-passe, e '
            'mostramos-lhe a informação das suas encomendas, frações e '
            'faturas, que provém do nosso sistema de gestão.',
        'Se usar a aplicação móvel e autorizar as notificações, guardamos '
            'também um identificador do seu telemóvel, gerado pelo serviço de '
            'notificações da Google (Firebase Cloud Messaging) e associado à '
            'sua sessão. Serve apenas para lhe enviarmos avisos sobre a sua '
            'obra, os seus documentos e os nossos empreendimentos. É apagado '
            'quando termina a sessão, deixa de ser usado se a sessão expirar, '
            'e pode desativar as notificações a qualquer momento nas '
            'definições do telemóvel.',
      ],
      alineas: [],
    ),
    (
      titulo: '3. Finalidades e base legal',
      paragrafos: [],
      alineas: [
        'Resposta a pedidos de informação e contacto comercial — base legal: '
            'diligências pré-contratuais e consentimento.',
        'Envio de comunicações de marketing — apenas mediante consentimento '
            'explícito (opt-in), revogável a qualquer momento.',
        'Notificações da aplicação móvel sobre a sua obra, documentos e '
            'empreendimentos — base legal: execução do contrato e a sua '
            'autorização no telemóvel, que pode retirar nas definições do '
            'telemóvel.',
        'Cumprimento de obrigações legais aplicáveis.',
      ],
    ),
    (
      titulo: '4. Conservação',
      paragrafos: [
        'Os dados são conservados apenas durante o período necessário às '
            'finalidades indicadas ou pelos prazos legais aplicáveis.',
      ],
      alineas: [],
    ),
    (
      titulo: '5. Partilha de dados',
      paragrafos: [
        'Os dados não são vendidos nem partilhados com terceiros para fins de '
            'marketing sem o seu consentimento. Poderão ser tratados por '
            'subcontratantes (ex.: alojamento, CRM) sob obrigações de '
            'confidencialidade e conformidade com o RGPD.',
        'As notificações da aplicação móvel são entregues através do Firebase '
            'Cloud Messaging, da Google (e, nos iPhone, do serviço equivalente '
            'da Apple), que recebe o identificador do telemóvel e o título e o '
            'texto de cada notificação. Os textos das notificações não incluem '
            'valores nem outros dados pessoais.',
      ],
      alineas: [],
    ),
    (
      titulo: '6. Os seus direitos',
      paragrafos: [
        'Nos termos do Regulamento (UE) 2016/679 (RGPD) e da Lei n.º 58/2019, '
            'tem direito de acesso, retificação, eliminação, limitação, '
            'portabilidade e oposição ao tratamento dos seus dados, bem como '
            'de retirar o consentimento. Para exercer estes direitos, contacte '
            '$_email. Tem ainda o direito de apresentar reclamação à Comissão '
            'Nacional de Proteção de Dados (CNPD).',
      ],
      alineas: [],
    ),
    // A secção 7 estava numa versão antiga, que dizia que podia haver
    // cookies de análise — o site diz há meses que não há. Fica o texto que
    // vai para o ar (o do ramo main), menos a última frase, que é um link
    // para as definições de cookies do site e aqui não tem para onde ir.
    (
      titulo: '7. Cookies e conteúdos de terceiros',
      paragrafos: [
        'Este website utiliza apenas dois cookies, ambos necessários ao seu '
            'funcionamento e que só existem depois de iniciar sessão na Área '
            'Reservada: um de curta duração, que identifica a sessão em cada '
            'pedido, e outro que a mantém iniciada durante até 30 dias sem '
            'utilização (o prazo recomeça sempre que volta a usar o site). '
            'Ambos são apagados quando termina a sessão. Não há cookies de '
            'análise, publicidade ou seguimento.',
        'A página de Contactos inclui um formulário fornecido por um serviço '
            'externo (Odoo). Esse formulário só é carregado depois de o '
            'autorizar: até lá, nenhum pedido é feito a esse serviço. Ao '
            'autorizá-lo, o seu endereço IP é-lhe comunicado e esse serviço '
            'pode guardar cookies no seu navegador. Pode mudar de ideias a '
            'qualquer momento em "Definições de cookies", no fundo de qualquer '
            'página.',
        'As páginas com mapa carregam a cartografia a partir dos servidores '
            'do CARTO e do OpenStreetMap, o que comunica o seu endereço IP a '
            'esses serviços. Sem isso não há mapa — por isso é tratado como '
            'parte da funcionalidade que pediu ao abrir a página, e não '
            'depende de consentimento.',
      ],
      alineas: [],
    ),
    (
      titulo: '8. Como apagar a sua conta',
      paragrafos: [
        'Pode pedir a qualquer momento que a sua conta da Área Reservada seja '
            'apagada, quer a tenha criado no site quer na aplicação móvel. '
            'Para isso, envie um email para $_email a partir do endereço '
            'associado à conta, com o assunto "Apagar conta".',
        'Ao apagar a conta, deixa de ter acesso à Área Reservada e são '
            'eliminados os dados da conta: nome, email, telefone e '
            'palavra-passe. Os documentos associados às suas encomendas, como '
            'faturas e contratos, são conservados pelos prazos que a lei '
            'impõe.',
      ],
      alineas: [],
    ),
  ];

  Future<void> _escrever(BuildContext context) async {
    bool ok;
    try {
      ok = await launchUrl(
        Uri.parse('mailto:$_email'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o email.'),
          backgroundColor: COColors.brand700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: COColors.brand900,
      drawer: const CoDrawer(),
      appBar: AppBar(
        backgroundColor: COColors.brand900,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: COColors.white),
        title: Text(
          'Privacidade',
          style: COText.small.copyWith(
            color: COColors.white,
            fontSize: 13,
            fontWeight: COTokens.fwBold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          COTokens.space6,
          COTokens.space2,
          COTokens.space6,
          COTokens.space12,
        ),
        children: [
          const CoTitulo('Informação legal'),
          Text('Política de Privacidade', style: COText.h1),
          const SizedBox(height: COTokens.space2),
          Text('Última atualização: novembro de 2026', style: COText.caption),

          const SizedBox(height: COTokens.space8),

          for (final s in _secoes) ...[
            Text(
              s.titulo,
              style: COText.body.copyWith(fontWeight: COTokens.fwBold),
            ),
            const SizedBox(height: 6),
            for (final p in s.paragrafos)
              Padding(
                padding: const EdgeInsets.only(bottom: COTokens.space2),
                child: Text(p, style: COText.small),
              ),
            for (final a in s.alineas)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('–', style: COText.small),
                    const SizedBox(width: 8),
                    Expanded(child: Text(a, style: COText.small)),
                  ],
                ),
              ),
            const SizedBox(height: COTokens.space6),
          ],

          // O email aparece no texto como texto, porque é lá que a lei o
          // quer. Este botão é só para não obrigar ninguém a copiá-lo à mão.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _escrever(context),
              icon: const Icon(Icons.mail_outline, size: 16),
              label: Text(
                'ESCREVER PARA $_email'.toUpperCase(),
                style: COText.caption.copyWith(
                  color: COColors.white,
                  fontWeight: COTokens.fwBold,
                  letterSpacing: 1,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: COColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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

          const SizedBox(height: COTokens.space8),
          // Esta nota está no site e fica: dizê-lo é mais honesto do que
          // apresentar o documento como definitivo.
          Text(
            'Este documento é um modelo de base e deve ser validado por '
            'assessoria jurídica antes da publicação definitiva.',
            style: COText.caption,
          ),
        ],
      ),
    );
  }
}
