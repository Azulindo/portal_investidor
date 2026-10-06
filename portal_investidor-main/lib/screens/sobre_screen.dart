import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/portfolio.dart';
import '../widgets/co_card.dart';
import '../widgets/co_drawer.dart';
import 'contactos_screen.dart';

/// Sobre a Cleveroption — o equivalente ao /sobre do site.
///
/// Os marcos, os números e os valores são texto que a empresa escreveu; estão
/// copiados do site palavra por palavra, porque é texto institucional e não é
/// nosso para reescrever. Se mudarem, mudam-se nos dois sítios.
///
/// O "historial completo" é a única parte que não é texto fixo: sai de
/// /project/portfolio, como no site.
class SobreScreen extends StatefulWidget {
  const SobreScreen({super.key});

  @override
  State<SobreScreen> createState() => _SobreScreenState();
}

class _SobreScreenState extends State<SobreScreen> {
  late Future<List<dynamic>> _portfolio;

  @override
  void initState() {
    super.initState();
    // Falha aqui não deve esvaziar a página: o resto é texto fixo e continua
    // a ler-se sem o historial.
    _portfolio = ApiService().buscarPortfolio().catchError((_) => <dynamic>[]);
  }

  static const List<({String ano, String titulo, String corpo})> _marcos = [
    (
      ano: '2010',
      titulo: 'Fundação',
      corpo: 'A Cleveroption inicia atividade como empresa de construção '
          'civil, focada em obras de reabilitação e construção nova na '
          'região do Porto.',
    ),
    (
      ano: '2016',
      titulo: 'Pivot para promoção imobiliária',
      corpo: 'Redirecionamento estratégico para a promoção imobiliária '
          'residencial, aproveitando o conhecimento construtivo para lançar '
          'os primeiros empreendimentos próprios.',
    ),
    (
      ano: '2018',
      titulo: 'Primeiras reabilitações de referência',
      corpo: 'Conclusão do Pinheiro 16 e Bonjardim 637 — projetos que '
          'consolidam a reputação da empresa em reabilitação urbana de '
          'qualidade.',
    ),
    (
      ano: '2022',
      titulo: 'Projetos de grande escala',
      corpo: 'Início do desenvolvimento de empreendimentos de maior '
          'dimensão, com o Clemente Menéres e a preparação da carteira '
          'ativa de 700+ frações.',
    ),
    (
      ano: '2024',
      titulo: 'Campinho concluído',
      corpo: 'Conclusão do Edifício Campinho na baixa do Porto — projeto '
          'Art Déco que se torna emblemático da capacidade da empresa em '
          'reabilitação de alto valor.',
    ),
    (
      ano: '2025',
      titulo: 'The Luxor em execução',
      corpo: 'Arranque das obras do The Luxor — The Stone Edition, o maior '
          'empreendimento da empresa com 184 frações em Vila Nova de Gaia.',
    ),
  ];

  static const List<({String valor, String legenda})> _numeros = [
    (valor: '+16 anos', legenda: 'de experiência no mercado'),
    (
      valor: '16',
      legenda: 'empreendimentos concluídos\n2016—2026 · +110 frações',
    ),
    (valor: '+590', legenda: 'frações desenvolvidas e em desenvolvimento'),
    (valor: '+€180M', legenda: 'valor de vendas e pipeline'),
    (valor: '10', legenda: 'empreendimentos em construção e projeto'),
  ];

  static const List<({String titulo, String corpo})> _valores = [
    (
      titulo: 'Localização',
      corpo: 'Selecionamos criteriosamente cada terreno, priorizando '
          'proximidade a transportes, serviços e áreas consolidadas com '
          'forte potencial de valorização. A localização é sempre um ativo '
          'estratégico.',
    ),
    (
      titulo: 'Qualidade',
      corpo: 'Cada projeto é desenvolvido com materiais de primeira linha e '
          'processos construtivos rigorosos. Os nossos acabamentos premium e '
          'atenção ao detalhe refletem um compromisso inabalável com a '
          'excelência.',
    ),
    (
      titulo: 'Valorização',
      // A última frase é um aviso legal e fica como está no site.
      corpo: 'O nosso historial de projetos concluídos dentro do prazo e do '
          'orçamento reflete o rigor com que trabalhamos. Procuramos criar '
          'valor sustentado para investidores e compradores. Esta informação '
          'tem caráter informativo e não constitui aconselhamento de '
          'investimento.',
    ),
  ];

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
          'SOBRE NÓS',
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
          const CoOverline('Sobre a empresa'),
          Text('Sobre a Cleveroption', style: COText.h1),
          const SizedBox(height: COTokens.space2),
          Text(
            'Transformamos ideias em resultados — desde 2010 a construir o '
            'Porto e Vila Nova de Gaia.',
            style: COText.body.copyWith(color: COColors.brand300),
          ),

          const SizedBox(height: COTokens.space12),
          const CoOverline('A nossa história'),
          Text(
            'Mais de uma década de experiência no setor',
            style: COText.h2,
          ),
          const SizedBox(height: COTokens.space6),
          for (var i = 0; i < _marcos.length; i++)
            _marco(_marcos[i], ultimo: i == _marcos.length - 1),

          const SizedBox(height: COTokens.space12),
          const CoOverline('Em números'),
          for (final n in _numeros) _numero(n),

          const SizedBox(height: COTokens.space12),
          const CoOverline('Os nossos valores'),
          Text('O que nos define', style: COText.h2),
          const SizedBox(height: COTokens.space4),
          for (var i = 0; i < _valores.length; i++) _valor(i, _valores[i]),

          const SizedBox(height: COTokens.space12),
          const CoOverline('Historial completo'),
          Text('Todos os empreendimentos', style: COText.h2),
          const SizedBox(height: COTokens.space4),
          _historial(),

          const SizedBox(height: COTokens.space12),
          _cta(),
        ],
      ),
    );
  }

  /// Uma linha da história: o ano à esquerda, ligado ao seguinte por um fio.
  Widget _marco(({String ano, String titulo, String corpo}) m,
      {required bool ultimo}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coluna do ano e do fio. O IntrinsicHeight acima é o que faz o fio
          // acompanhar a altura real do texto ao lado.
          SizedBox(
            width: 54,
            child: Column(
              children: [
                Text(
                  m.ano,
                  style: COText.small.copyWith(
                    color: COColors.brand300,
                    fontWeight: COTokens.fwBold,
                  ),
                ),
                const SizedBox(height: 4),
                if (!ultimo)
                  Expanded(
                    child: Container(width: 1, color: COColors.brand700),
                  ),
              ],
            ),
          ),
          const SizedBox(width: COTokens.space4),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: ultimo ? 0 : COTokens.space6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.titulo,
                    style: COText.body.copyWith(fontWeight: COTokens.fwBold),
                  ),
                  const SizedBox(height: 4),
                  Text(m.corpo, style: COText.small),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numero(({String valor, String legenda}) n) {
    return CoCard(
      margin: const EdgeInsets.only(bottom: COTokens.space2),
      padding: const EdgeInsets.all(COTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            n.valor,
            style: COText.h1.copyWith(fontSize: 26, color: COColors.white),
          ),
          const SizedBox(height: 2),
          Text(n.legenda, style: COText.small),
        ],
      ),
    );
  }

  Widget _valor(int indice, ({String titulo, String corpo}) v) {
    return CoCard(
      margin: const EdgeInsets.only(bottom: COTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '0${indice + 1}',
            style: COText.valor.copyWith(color: COColors.brand500),
          ),
          const SizedBox(height: 4),
          Text(
            v.titulo,
            style: COText.body.copyWith(fontWeight: COTokens.fwBold),
          ),
          const SizedBox(height: 4),
          Text(v.corpo, style: COText.small),
        ],
      ),
    );
  }

  /// Todos os empreendimentos com data de conclusão, por ano.
  ///
  /// O marco da fundação de 2016 é fixo: não é um projeto, por isso não vem
  /// da API — é o que o site faz também.
  Widget _historial() {
    return FutureBuilder<List<dynamic>>(
      future: _portfolio,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: COTokens.space6),
            child: Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: COColors.brand300,
                ),
              ),
            ),
          );
        }

        final projetos = (snap.data ?? []).whereType<Map>().where((p) {
          return Portfolio.anoFim(p) != null;
        }).toList();

        if (projetos.isEmpty) {
          return Text(
            'O historial não está disponível neste momento.',
            style: COText.small,
          );
        }

        // Por data de conclusão, do mais antigo para o mais recente.
        projetos.sort((a, b) => Portfolio.texto(a, 'endDate')
            .compareTo(Portfolio.texto(b, 'endDate')));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linhaHistorial(
              ano: '2016',
              nome: 'Fundação e pivot imobiliário',
              nota: 'Porto',
            ),
            for (final p in projetos)
              _linhaHistorial(
                ano: Portfolio.anoFim(p)!,
                nome: Portfolio.texto(p, 'name'),
                nota: _notaDoProjeto(p),
                // Os que ainda não acabaram vão marcados como previstos, para
                // não se ler o historial como se já estivesse todo feito.
                previsto: !Portfolio.estaConcluido(
                  Portfolio.texto(p, 'status'),
                ),
              ),
          ],
        );
      },
    );
  }

  String _notaDoProjeto(Map p) {
    final cidade = Portfolio.texto(p, 'city');
    final fracoes = Portfolio.inteiro(p, 'nFractions');
    if (fracoes == null) return cidade;
    return '$cidade · $fracoes ${fracoes == 1 ? 'fração' : 'frações'}';
  }

  Widget _linhaHistorial({
    required String ano,
    required String nome,
    required String nota,
    bool previsto = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: COColors.brand700,
            width: COTokens.borderWidth,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Text(
              ano,
              style: COText.small.copyWith(
                color: previsto ? COColors.neutral500 : COColors.brand300,
                fontWeight: COTokens.fwBold,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nome,
                        style: COText.small.copyWith(color: COColors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (previsto) ...[
                      const SizedBox(width: 6),
                      Text('previsto', style: COText.caption),
                    ],
                  ],
                ),
                if (nota.isNotEmpty) Text(nota, style: COText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cta() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vamos trabalhar juntos?', style: COText.h2),
        const SizedBox(height: COTokens.space2),
        Text(
          'A nossa equipa está disponível para responder a qualquer questão '
          'sobre os nossos empreendimentos e oportunidades de investimento.',
          style: COText.small,
        ),
        const SizedBox(height: COTokens.space4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactosScreen()),
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
            child: Text(
              'CONTACTE-NOS',
              style: COText.small.copyWith(
                color: COColors.white,
                fontWeight: COTokens.fwBold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
