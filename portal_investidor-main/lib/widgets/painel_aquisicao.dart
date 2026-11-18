import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/sale_order.dart';
import '../services/api_service.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/carteira.dart';
import 'secao_encomendas.dart' show PedirFatura;

/// Uma aquisição no cartão do empreendimento, como no portal do site
/// (PortalDashboard.tsx, "Aquisições"): o nome, o valor, as frações e a barra
/// pago / faturado / por faturar. Ao tocar abre as faturas.
class CartaoAquisicao extends StatefulWidget {
  const CartaoAquisicao({
    super.key,
    required this.encomenda,
    required this.empreendimento,
  });

  final SaleOrder encomenda;

  /// Para quando a encomenda vem sem projectName.
  final String empreendimento;

  @override
  State<CartaoAquisicao> createState() => _CartaoAquisicaoState();
}

class _CartaoAquisicaoState extends State<CartaoAquisicao> {
  bool _aberta = false;

  SaleOrder get _o => widget.encomenda;
  String get _nome =>
      _o.projectName.isNotEmpty ? _o.projectName : widget.empreendimento;

  @override
  Widget build(BuildContext context) {
    final fracoes = _o.fracoesOrdenadas;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: COColors.white,
        border: Border.all(color: COColors.bordaClara),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: COColors.neutral100,
            child: InkWell(
              onTap: () => setState(() => _aberta = !_aberta),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(_nome, style: Claro.titulo)),
                        const SizedBox(width: 8),
                        Text(Carteira.euros(_o.amountTotal),
                            style: Claro.valor),
                        AnimatedRotation(
                          turns: _aberta ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.expand_more,
                              size: 20, color: COColors.brand500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (fracoes.isEmpty)
                      Text('Sem frações indicadas', style: Claro.etiqueta)
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 10),
                            child: Text(
                              fracoes.length == 1 ? 'Fração' : 'Frações',
                              style: Claro.etiqueta,
                            ),
                          ),
                          Expanded(child: ChipsFracoes(fracoes)),
                        ],
                      ),
                    const SizedBox(height: 14),
                    BarraAquisicao(encomenda: _o),
                  ],
                ),
              ),
            ),
          ),
          if (_aberta) _faturas(),
        ],
      ),
    );
  }

  Widget _faturas() {
    if (_o.invoices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Text('Sem faturas associadas a esta aquisição.',
            style: Claro.etiqueta),
      );
    }
    return Column(
      children: [
        for (final f in _o.invoices) _LinhaFatura(fatura: f, empreendimento: _nome),
      ],
    );
  }
}

/// A barra de três fatias com os marcadores das percentagens por cima e, por
/// baixo, a legenda com os valores — a forma como o site a mostra no
/// telemóvel, onde as fatias são estreitas de mais para levar texto.
class BarraAquisicao extends StatelessWidget {
  const BarraAquisicao({super.key, required this.encomenda});

  final SaleOrder encomenda;

  static const Color _faturado = COColors.brand500;

  @override
  Widget build(BuildContext context) {
    final o = encomenda;
    final pct = o.percentagemPaga.clamp(0, 100);
    final fim = o.percentagemFaturada.clamp(pct, 100);
    final temFaturado = o.faturadoPorPagar > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          return SizedBox(
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // A barra, encostada ao fundo.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  height: 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        if (pct > 0)
                          Expanded(
                              flex: pct,
                              child: Container(color: COColors.brand900)),
                        if (temFaturado && fim > pct)
                          Expanded(
                              flex: fim - pct,
                              child: Container(color: _faturado)),
                        if (fim < 100)
                          Expanded(
                              flex: 100 - fim,
                              child: Container(color: COColors.white)),
                      ],
                    ),
                  ),
                ),
                _marcador(w, pct, '$pct%'),
                if (temFaturado)
                  // Com as duas fatias muito juntas os números
                  // sobrepunham-se; aí fica só o traço.
                  _marcador(w, fim, fim - pct >= 8 ? '$fim%' : null),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            _legenda(COColors.brand900, '${Carteira.euros(o.pago)} pago'),
            if (temFaturado)
              _legenda(_faturado,
                  '${Carteira.euros(o.faturadoPorPagar)} faturado'),
            _legenda(COColors.white,
                '${Carteira.euros(o.porFaturar)} por faturar',
                comBorda: true),
          ],
        ),
      ],
    );
  }

  /// Um traço que passa a barra de cima a baixo, com a percentagem por cima.
  Widget _marcador(double largura, int pct, String? texto) {
    final x = largura * pct / 100;
    const larguraTexto = 44.0;
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: (x - 1).clamp(0, largura - 2),
            bottom: 0,
            width: 2,
            height: 28,
            child: Container(color: COColors.brand900),
          ),
          if (texto != null)
            Positioned(
              left: (x - larguraTexto / 2).clamp(0, largura - larguraTexto),
              top: 0,
              width: larguraTexto,
              child: Text(
                texto,
                textAlign: x < larguraTexto / 2
                    ? TextAlign.left
                    : (x > largura - larguraTexto / 2
                        ? TextAlign.right
                        : TextAlign.center),
                style: const TextStyle(
                  color: COColors.brand900,
                  fontSize: 11,
                  fontWeight: COTokens.fwBold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _legenda(Color cor, String texto, {bool comBorda = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(2),
            border: comBorda ? Border.all(color: COColors.bordaClara) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(texto,
            style: const TextStyle(
                color: COColors.brand900,
                fontSize: 12,
                fontWeight: COTokens.fwBold)),
      ],
    );
  }
}

class _LinhaFatura extends StatelessWidget {
  const _LinhaFatura({required this.fatura, required this.empreendimento});

  final Invoice fatura;
  final String empreendimento;

  Future<void> _descarregar(BuildContext context) async {
    final anexo = fatura.attachments.first;
    try {
      final url = await ApiService().getAttachmentUrl(anexo.id ?? 0);
      if (!await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication)) {
        throw Exception('launchUrl');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e is ApiException
            ? e.message
            : 'Não foi possível abrir a fatura ${fatura.name}.'),
        backgroundColor: COColors.brand700,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = fatura;
    final paga = f.paymentState == 'paid';
    final temDocumento = f.attachments.any((a) => a.id != null);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: COColors.bordaClara)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: COColors.bordaClara),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text('FATURA', style: Claro.miniatura),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(f.name.isEmpty ? 'Fatura' : f.name,
                    style: Claro.titulo.copyWith(fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: paga ? COColors.brand900 : COColors.neutral100,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  f.estado.toUpperCase(),
                  style: Claro.miniatura.copyWith(
                    color: paga ? COColors.white : COColors.brand900,
                  ),
                ),
              ),
              if (temDocumento)
                IconButton(
                  onPressed: () => _descarregar(context),
                  tooltip: 'Descarregar fatura',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.download_outlined,
                      size: 18, color: COColors.brand900),
                )
              else
                PedirFatura(
                  fatura: f,
                  empreendimento: empreendimento,
                  cor: COColors.brand500,
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(Carteira.data(f.date), style: Claro.etiqueta),
          for (final linha in f.linhas)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(linha,
                  style: Claro.etiqueta.copyWith(color: COColors.brand900)),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              _valor('Valor total', f.amountTotal),
              _valor('Pago', f.pago),
              _valor('Em falta', f.amountTotal - f.pago),
            ],
          ),
        ],
      ),
    );
  }

  Widget _valor(String etiqueta, double v) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta.toUpperCase(), style: Claro.miniatura),
          const SizedBox(height: 2),
          Text(Carteira.euros(v), style: Claro.valor.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}

/// As frações em pequenas caixas, como os fraction-chip do site.
///
/// Com mais de [maximo] mostram-se só as primeiras e um "Mostrar mais": quem
/// tem nove frações num empreendimento tinha o cartão a crescer meio ecrã
/// antes de chegar à obra.
class ChipsFracoes extends StatefulWidget {
  const ChipsFracoes(this.fracoes, {super.key, this.maximo = 6});

  final List<String> fracoes;
  final int maximo;

  @override
  State<ChipsFracoes> createState() => _ChipsFracoesState();
}

class _ChipsFracoesState extends State<ChipsFracoes> {
  bool _todas = false;

  @override
  Widget build(BuildContext context) {
    final fracoes = widget.fracoes;
    final cortar = fracoes.length > widget.maximo;
    final visiveis =
        cortar && !_todas ? fracoes.take(widget.maximo) : fracoes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _caixas(visiveis),
        if (cortar)
          InkWell(
            onTap: () => setState(() => _todas = !_todas),
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _todas
                        ? 'Mostrar menos'
                        : 'Mostrar mais (+${fracoes.length - widget.maximo})',
                    style: const TextStyle(
                      color: COColors.brand900,
                      fontSize: 12,
                      fontWeight: COTokens.fwBold,
                    ),
                  ),
                  Icon(
                    _todas ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: COColors.brand900,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _caixas(Iterable<String> fracoes) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final f in fracoes)
          // Sem alignment nem altura fixa: com alignment o Container estica
          // até à largura toda, e cada fração ficava numa caixa da largura do
          // cartão, uma por linha. Assim fica do tamanho do texto.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: COColors.neutral100,
              border: Border.all(color: COColors.bordaClara),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(f,
                style: const TextStyle(
                    color: COColors.brand900,
                    fontSize: 11.5,
                    fontWeight: COTokens.fwBold)),
          ),
      ],
    );
  }
}

/// Os textos sobre fundo claro. Os COText são para o navy (brancos e cinzas
/// claros) e aqui ficavam ilegíveis.
class Claro {
  Claro._();

  static const TextStyle titulo = TextStyle(
    color: COColors.brand900,
    fontSize: 16,
    fontWeight: COTokens.fwBold,
  );

  static const TextStyle valor = TextStyle(
    color: COColors.brand900,
    fontSize: 15,
    fontWeight: COTokens.fwBold,
  );

  /// brand500 sobre branco dá 6:1, acima dos 4.5:1.
  static const TextStyle etiqueta = TextStyle(
    color: COColors.brand500,
    fontSize: 12,
  );

  static const TextStyle miniatura = TextStyle(
    color: COColors.brand500,
    fontSize: 10,
    fontWeight: COTokens.fwBold,
    letterSpacing: 0.6,
  );

  static const TextStyle seccao = TextStyle(
    color: COColors.brand900,
    fontSize: 13,
    fontWeight: COTokens.fwBold,
    letterSpacing: 0.5,
  );
}

/// As aquisições de um empreendimento: as primeiras [visiveis] e, se houver
/// mais, um botão para mostrar as outras. Quem tem nove frações em nove
/// encomendas tinha o cartão a ocupar vários ecrãs só de barras.
class ListaAquisicoes extends StatefulWidget {
  const ListaAquisicoes({
    super.key,
    required this.encomendas,
    required this.empreendimento,
    this.visiveis = 2,
  });

  final List<SaleOrder> encomendas;
  final String empreendimento;
  final int visiveis;

  @override
  State<ListaAquisicoes> createState() => _ListaAquisicoesState();
}

class _ListaAquisicoesState extends State<ListaAquisicoes> {
  bool _todas = false;

  @override
  Widget build(BuildContext context) {
    final todas = widget.encomendas;
    final escondidas = todas.length - widget.visiveis;
    final lista = _todas || escondidas <= 0
        ? todas
        : todas.take(widget.visiveis);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final o in lista)
          CartaoAquisicao(encomenda: o, empreendimento: widget.empreendimento),
        if (escondidas > 0)
          OutlinedButton.icon(
            onPressed: () => setState(() => _todas = !_todas),
            style: OutlinedButton.styleFrom(
              foregroundColor: COColors.brand900,
              side: const BorderSide(color: COColors.bordaClara),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: Icon(_todas ? Icons.expand_less : Icons.expand_more, size: 20),
            label: Text(
              _todas
                  ? 'Mostrar menos'
                  : 'Mostrar todas as aquisições (+$escondidas)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: COTokens.fwBold,
              ),
            ),
          ),
      ],
    );
  }
}
