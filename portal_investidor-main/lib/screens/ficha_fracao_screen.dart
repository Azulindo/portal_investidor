import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/empresa.dart';
import '../models/user_model.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/ficha_fracao.dart';
import '../utils/fracoes.dart';
import '../widgets/co_card.dart';
import '../widgets/co_imagem.dart';
import '../widgets/secao_video.dart';
import '../widgets/visualizador_imagens.dart';

/// A ficha de uma fração — o /empreendimento/fracao do site, adaptado ao
/// telemóvel: o topo com o tipo, o estado, o preço e os contactos; os números
/// principais; e quatro separadores (Planta, Filme, Imagens, Sobre).
///
/// Não faz pedidos: recebe o empreendimento que o ecrã de detalhe já
/// carregou, que traz as frações todas, as imagens e o filme — é o mesmo
/// GET /project/details que o site usa para a ficha. As contas e os textos
/// estão em utils/ficha_fracao.dart, iguais aos do site.
class FichaFracaoScreen extends StatefulWidget {
  const FichaFracaoScreen({
    super.key,
    required this.projeto,
    required this.fracao,
  });

  final ProjectDetailModel projeto;
  final ProjectFraction fracao;

  @override
  State<FichaFracaoScreen> createState() => _FichaFracaoScreenState();
}

enum _Aba { planta, filme, imagens, sobre }

class _FichaFracaoScreenState extends State<FichaFracaoScreen> {
  _Aba _aba = _Aba.planta;

  ProjectFraction get f => widget.fracao;
  ProjectInfo get info => widget.projeto.info;

  String get _link => FichaFracao.url(f.projectId, f);

  /// Interiores primeiro (é a casa que se vende), depois os exteriores. As
  /// fotografias da obra ficam de fora, como no site.
  List<ProjectImage> get _imagens {
    final todas = widget.projeto.imagensDaGaleria;
    return [
      ...todas.where((i) => i.category == 'interior'),
      ...todas.where((i) => i.category != 'interior'),
    ];
  }

  bool get _temFilme => (info.videoUrl ?? '').trim().isNotEmpty;

  Future<void> _abrir(String url) async {
    bool ok;
    try {
      ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir.')),
      );
    }
  }

  void _whatsapp() => _abrir(
        '${Empresa.whatsapp}?text=${Uri.encodeComponent(FichaFracao.mensagemWhatsapp(f, info.name, _link))}',
      );

  void _ligar() => _abrir('tel:${Empresa.telefone}');

  void _email() {
    final assunto = [
      info.name,
      'Fração ${f.fractionNumber}',
      if (f.block != null) FichaFracao.blocoPorExtenso(f.block!),
    ].join(' · ');
    _abrir('mailto:${Empresa.email}?subject=${Uri.encodeComponent(assunto)}');
  }

  Future<void> _copiarLink() async {
    await Clipboard.setData(ClipboardData(text: _link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link da fração copiado.')),
    );
  }

  void _verOutra(ProjectFraction outra) {
    if (outra.fractionId == f.fractionId) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FichaFracaoScreen(projeto: widget.projeto, fracao: outra),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final abas = [
      _Aba.planta,
      if (_temFilme) _Aba.filme,
      if (_imagens.isNotEmpty) _Aba.imagens,
      _Aba.sobre,
    ];

    return Scaffold(
      backgroundColor: COColors.brand900,
      appBar: AppBar(
        backgroundColor: COColors.brand900,
        foregroundColor: COColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(info.name, style: COText.tituloEcra),
        actions: [
          IconButton(
            tooltip: 'Copiar o link da fração',
            icon: const Icon(Icons.link),
            onPressed: _copiarLink,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          COTokens.space6,
          COTokens.space2,
          COTokens.space6,
          COTokens.space12,
        ),
        children: [
          _topo(),
          const SizedBox(height: COTokens.space6),
          _factos(),
          const SizedBox(height: COTokens.space8),
          _separadores(abas),
          const SizedBox(height: COTokens.space6),
          switch (_aba) {
            _Aba.planta => _planta(),
            _Aba.filme => SecaoVideo(videoUrl: info.videoUrl),
            _Aba.imagens => _galeria(),
            _Aba.sobre => _sobre(),
          },
          const SizedBox(height: COTokens.space8),
          Text(
            'A presente comunicação tem caráter meramente informativo e '
            'promocional e não constitui qualquer oferta ou recomendação de '
            'compra. As condições, preços, áreas e prazos podem ser alterados '
            'sem aviso prévio. As imagens 3D são ilustrativas e não '
            'vinculativas; o produto final pode diferir. A classe energética '
            'de cada fração está disponível mediante solicitação.',
            style: COText.caption.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Topo ──────────────────────────────────────────────────

  Widget _topo() {
    final bloco =
        f.block != null ? FichaFracao.blocoPorExtenso(f.block!) : null;
    final piso = (f.floor ?? '').trim().isNotEmpty
        ? FichaFracao.pisoPorExtenso(f.floor!)
        : null;
    final orientacao = (f.orientation ?? '').trim().isNotEmpty
        ? FichaFracao.orientacaoPorExtenso(f.orientation!)
        : null;
    final disponivel =
        FichaFracao.estado(f.status) == EstadoFracao.disponivel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoEtiqueta([info.name, ?bloco, ?piso].join(' · ')),
        Text(f.type, style: COText.h1),
        const SizedBox(height: 4),
        Text(
          ['Fração ${f.fractionNumber}', ?orientacao].join(' · '),
          style: COText.body.copyWith(color: COColors.brand300),
        ),
        const SizedBox(height: COTokens.space4),
        Row(
          children: [
            _estado(f.status),
            const Spacer(),
            // Preço só nas disponíveis, como no site: numa reservada ou
            // vendida já não interessa. Na app há sempre sessão, por isso
            // sem preço é "Sob consulta" e não "Registe-se".
            if (disponivel)
              Text(
                f.price != null ? Fracoes.euros(f.price!) : 'Sob consulta',
                style: COText.valor.copyWith(color: COColors.white),
              ),
          ],
        ),
        const SizedBox(height: COTokens.space6),
        // Sem ícone no WhatsApp: com ele a palavra partia em duas linhas
        // num ecrã de 375 px.
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _whatsapp,
                style: FilledButton.styleFrom(
                  backgroundColor: COColors.accent,
                  foregroundColor: COColors.brand900,
                  minimumSize: const Size.fromHeight(46),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('WhatsApp', maxLines: 1),
              ),
            ),
            const SizedBox(width: COTokens.space2),
            Expanded(child: _botaoContorno('Ligar', _ligar)),
            const SizedBox(width: COTokens.space2),
            Expanded(child: _botaoContorno('Email', _email)),
          ],
        ),
      ],
    );
  }

  Widget _botaoContorno(String texto, VoidCallback aoCarregar) {
    return OutlinedButton(
      onPressed: aoCarregar,
      style: OutlinedButton.styleFrom(
        foregroundColor: COColors.white,
        minimumSize: const Size.fromHeight(46),
        side: const BorderSide(color: COColors.brand300),
      ),
      child: Text(texto),
    );
  }

  /// O estado em etiqueta. Disponível no teal da marca (é a que se pode
  /// comprar); as outras discretas.
  Widget _estado(String status) {
    final cor = switch (FichaFracao.estado(status)) {
      EstadoFracao.disponivel => COColors.accent,
      EstadoFracao.reservada => COColors.brand300,
      EstadoFracao.vendida => COColors.neutral500,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(COTokens.radiusSm),
        border: Border.all(color: cor),
      ),
      child: Text(
        status.toUpperCase(),
        style: COText.caption.copyWith(
          color: COColors.white,
          fontWeight: COTokens.fwBold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ── Números principais ────────────────────────────────────

  Widget _factos() {
    final factos = FichaFracao.factos(f);
    if (factos.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, c) {
        final largura = (c.maxWidth - COTokens.space2) / 2;
        return Wrap(
          spacing: COTokens.space2,
          runSpacing: COTokens.space2,
          children: [
            for (final x in factos)
              SizedBox(
                width: largura,
                child: CoCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(COTokens.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(x.titulo.toUpperCase(), style: COText.overline),
                      const SizedBox(height: 4),
                      Text(
                        x.valor,
                        style: COText.body.copyWith(
                          color: COColors.white,
                          fontWeight: COTokens.fwBold,
                        ),
                      ),
                      // Uma linha sempre, com nota ou sem ela: senão os
                      // cartões com nota ficavam mais altos e a grelha
                      // desalinhava.
                      Text(x.nota ?? ' ', style: COText.caption),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Separadores ───────────────────────────────────────────

  static const _nomes = {
    _Aba.planta: 'Planta',
    _Aba.filme: 'Filme',
    _Aba.imagens: 'Imagens',
    _Aba.sobre: 'Sobre',
  };

  Widget _separadores(List<_Aba> abas) {
    return Row(
      children: [
        for (final a in abas)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Semantics(
                button: true,
                selected: _aba == a,
                child: InkWell(
                  borderRadius: BorderRadius.circular(COTokens.radiusSm),
                  onTap: () => setState(() => _aba = a),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _aba == a ? COColors.white : COColors.brand700,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      _nomes[a]!,
                      style: COText.small.copyWith(
                        color: _aba == a ? COColors.white : COColors.brand300,
                        fontWeight:
                            _aba == a ? COTokens.fwBold : COTokens.fwMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Planta ────────────────────────────────────────────────

  Widget _planta() {
    final temImagens =
        f.floorPlanImageUrl != null || f.floorLocationImageUrl != null;
    final imagens = [?f.floorPlanImageUrl, ?f.floorLocationImageUrl];
    final legendas = [
      if (f.floorPlanImageUrl != null) 'Planta da fração ${f.fractionNumber}',
      if (f.floorLocationImageUrl != null)
        'Localização no piso · Fração ${f.fractionNumber}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoTitulo('Planta da fração ${f.fractionNumber}'),
        Text(
          [
            f.type,
            if (f.grossPrivateArea != null)
              '${FichaFracao.m2(f.grossPrivateArea!)} de área bruta privativa',
          ].join(' · ') +
              (temImagens ? '. Toque na planta para ampliar.' : '.'),
          style: COText.small,
        ),
        const SizedBox(height: COTokens.space4),
        if (f.floorPlanImageUrl != null)
          _imagemAmpliavel(f.floorPlanImageUrl!, imagens, legendas, 0),
        if (f.floorLocationImageUrl != null) ...[
          const SizedBox(height: COTokens.space4),
          Text('LOCALIZAÇÃO NO PISO', style: COText.overline),
          const SizedBox(height: COTokens.space2),
          _imagemAmpliavel(
            f.floorLocationImageUrl!,
            imagens,
            legendas,
            imagens.length - 1,
          ),
        ],
        if (!temImagens && f.floorPlanUrl != null)
          _botaoContorno('Abrir a planta (PDF)', () => _abrir(f.floorPlanUrl!)),
        if (!temImagens && f.floorPlanUrl == null)
          Text.rich(
            TextSpan(
              style: COText.small,
              children: [
                const TextSpan(
                  text: 'A planta desta fração está a ser preparada. ',
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: GestureDetector(
                    onTap: _email,
                    child: Text(
                      'Peça-a por email',
                      style: COText.small.copyWith(
                        color: COColors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: COColors.white,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: ' e enviamos-lha.'),
              ],
            ),
          ),
        if (temImagens && f.floorPlanUrl != null) ...[
          const SizedBox(height: COTokens.space4),
          _botaoContorno('Descarregar PDF', () => _abrir(f.floorPlanUrl!)),
        ],
        const SizedBox(height: COTokens.space4),
        Text(
          'Áreas conforme projeto de arquitetura. Planta ilustrativa, sujeita '
          'a alterações decorrentes da execução da obra.',
          style: COText.caption,
        ),
      ],
    );
  }

  Widget _imagemAmpliavel(
    String url,
    List<String> todas,
    List<String> legendas,
    int indice,
  ) {
    return GestureDetector(
      onTap: () => VisualizadorImagens.abrir(
        context,
        imagens: todas,
        legendas: legendas,
        inicial: indice,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(COTokens.radiusSm),
        child: ColoredBox(
          // As plantas vêm em fundo branco: sobre o navy liam-se mal.
          color: COColors.white,
          child: CoImagem(
            url,
            fit: BoxFit.contain,
            // Sem isto, uma planta que não carrega desaparecia sem deixar
            // espaço nenhum.
            erro: const SizedBox(
              height: 160,
              child: Center(
                child: Icon(Icons.broken_image, color: COColors.brand500),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Imagens ───────────────────────────────────────────────

  Widget _galeria() {
    final imagens = _imagens;
    final urls = imagens.map((i) => i.imageUrl).toList();
    final legendas = imagens
        .map((i) => (i.imageDescription ?? '').trim().isEmpty
            ? info.name
            : i.imageDescription!.trim())
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoTitulo('Imagens'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: COTokens.space2,
          crossAxisSpacing: COTokens.space2,
          children: [
            for (var i = 0; i < urls.length; i++)
              GestureDetector(
                onTap: () => VisualizadorImagens.abrir(
                  context,
                  imagens: urls,
                  legendas: legendas,
                  inicial: i,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(COTokens.radiusSm),
                  child: CoImagem(urls[i]),
                ),
              ),
          ],
        ),
        const SizedBox(height: COTokens.space4),
        Text(
          'Imagens 3D ilustrativas e não vinculativas. O produto final pode '
          'diferir.',
          style: COText.caption,
        ),
      ],
    );
  }

  // ── Sobre ─────────────────────────────────────────────────

  Widget _sobre() {
    final disponivel =
        FichaFracao.estado(f.status) == EstadoFracao.disponivel;
    final linhas = [...FichaFracao.especificacoes(f)];
    // O preço entra antes do estado, como na tabela do site.
    linhas.insert(
      linhas.length - 1,
      (
        'Preço',
        !disponivel
            ? '—'
            : f.price != null
                ? Fracoes.euros(f.price!)
                : 'Sob consulta',
      ),
    );
    final outras = FichaFracao.outras(f, widget.projeto.fractions);
    final bloco =
        f.block != null ? ' · ${FichaFracao.blocoPorExtenso(f.block!)}' : '';
    final descricao = info.description.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoTitulo('Sobre a fração ${f.fractionNumber}'),
        for (final (titulo, valor) in linhas)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: COColors.brand700)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(titulo, style: COText.small)),
                const SizedBox(width: COTokens.space4),
                Flexible(
                  child: Text(
                    valor,
                    textAlign: TextAlign.right,
                    style: COText.small.copyWith(
                      color: COColors.white,
                      fontWeight: COTokens.fwMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (outras.length > 1) ...[
          const SizedBox(height: COTokens.space6),
          Text('OUTRAS FRAÇÕES ${f.type}$bloco'.toUpperCase(),
              style: COText.overline),
          const SizedBox(height: COTokens.space2),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final x in outras) _outra(x)],
          ),
        ],
        const SizedBox(height: COTokens.space6),
        Text('O EMPREENDIMENTO', style: COText.overline),
        const SizedBox(height: COTokens.space2),
        if (descricao.isNotEmpty)
          Text(
            descricao.length > 320
                ? '${descricao.substring(0, 320).trimRight()}…'
                : descricao,
            style: COText.small,
          ),
        if (info.latitude != null && info.longitude != null) ...[
          const SizedBox(height: COTokens.space4),
          _botaoContorno(
            'Abrir no Google Maps',
            () => _abrir(
              'https://www.google.com/maps/search/?api=1&query=${info.latitude},${info.longitude}',
            ),
          ),
        ],
      ],
    );
  }

  /// Uma das outras frações. A atual fica marcada; as que já não estão à
  /// venda ficam esbatidas.
  Widget _outra(ProjectFraction x) {
    final atual = x.fractionId == f.fractionId;
    final estado = FichaFracao.estado(x.status);
    final piso = (x.floor ?? '').trim().isNotEmpty
        ? ' · ${FichaFracao.pisoCurto(x.floor!)}'
        : '';
    return Semantics(
      button: !atual,
      selected: atual,
      label: 'Fração ${x.fractionNumber}$piso, ${x.status}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(COTokens.radiusSm),
        onTap: atual ? null : () => _verOutra(x),
        child: Opacity(
          opacity: estado == EstadoFracao.disponivel || atual ? 1 : 0.55,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: atual ? COColors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(COTokens.radiusSm),
              border: Border.all(
                color: estado == EstadoFracao.disponivel
                    ? COColors.accent
                    : COColors.brand500,
              ),
            ),
            child: Text(
              '${x.fractionNumber}$piso',
              style: COText.small.copyWith(
                color: atual ? COColors.brand900 : COColors.white,
                fontWeight: COTokens.fwBold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
