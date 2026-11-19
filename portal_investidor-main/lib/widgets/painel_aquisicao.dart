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

  /// O que está lá dentro, para o "Ver documentos – 2 faturas e CPCV".
  String get _documentos {
    final n = _o.invoices.length;
    return [
      if (n > 0) '$n ${n == 1 ? 'fatura' : 'faturas'}',
      if (_o.cpcv.isNotEmpty) 'CPCV',
    ].join(' e ');
  }

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
                    // Como o site desde 19/11: o título é a fração (o
                    // empreendimento já está no cartão de fora), e por
                    // baixo da barra diz o que há para ver.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            fracoes.isEmpty
                                ? 'Sem frações indicadas'
                                : '${fracoes.length == 1 ? 'Fração' : 'Frações'} '
                                      '${fracoes.join(', ')}',
                            style: Claro.titulo.copyWith(fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Carteira.euros(_o.amountTotal),
                          style: Claro.valor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    BarraAquisicao(encomenda: _o),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _aberta
                                ? 'Esconder documentos'
                                : 'Ver documentos${_documentos.isEmpty ? '' : ' – $_documentos'}',
                            style: const TextStyle(
                              color: COColors.brand900,
                              fontSize: 13,
                              fontWeight: COTokens.fwBold,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _aberta ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.expand_more,
                            size: 18,
                            color: COColors.brand900,
                          ),
                        ),
                      ],
                    ),
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

  /// Os documentos da aquisição em duas secções, como no site: primeiro o
  /// CPCV das frações, num fundo azul claro, e por baixo as faturas.
  Widget _faturas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_o.cpcv.isNotEmpty)
          Container(
            color: const Color(0xFFEAF2F8),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CPCV', style: Claro.seccao),
                const SizedBox(height: 4),
                for (final c in _o.cpcv) _BotaoCpcv(cpcv: c),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Text('FATURAS', style: Claro.seccao),
        ),
        if (_o.invoices.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: Text(
              'Sem faturas associadas a esta aquisição.',
              style: Claro.etiqueta,
            ),
          )
        else
          for (final f in _o.invoices)
            _LinhaFatura(fatura: f, empreendimento: _nome),
      ],
    );
  }
}

/// "Descarregar CPCV" de uma fração. Diz que está a obter enquanto pede o
/// token, e se correr mal diz porquê (o site faz o mesmo).
class _BotaoCpcv extends StatefulWidget {
  const _BotaoCpcv({required this.cpcv});

  final CpcvFracao cpcv;

  @override
  State<_BotaoCpcv> createState() => _BotaoCpcvState();
}

class _BotaoCpcvState extends State<_BotaoCpcv> {
  bool _aObter = false;

  Future<void> _descarregar() async {
    setState(() => _aObter = true);
    try {
      final url = await ApiService().getCpcvUrl(widget.cpcv.fractionId);
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('launchUrl');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Não foi possível abrir o CPCV.',
            ),
            backgroundColor: COColors.brand700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _aObter = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fracao = widget.cpcv.fracao;
    return TextButton.icon(
      onPressed: _aObter ? null : _descarregar,
      style: TextButton.styleFrom(
        foregroundColor: COColors.brand900,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
      icon: const Icon(Icons.download_outlined, size: 18),
      label: Text(
        _aObter
            ? 'A obter…'
            : 'Descarregar CPCV${fracao.isEmpty ? '' : ' · $fracao'}',
        style: const TextStyle(fontWeight: COTokens.fwBold, fontSize: 13),
      ),
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
        LayoutBuilder(
          builder: (context, c) {
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
                              child: Container(color: COColors.brand900),
                            ),
                          if (temFaturado && fim > pct)
                            Expanded(
                              flex: fim - pct,
                              child: Container(color: _faturado),
                            ),
                          if (fim < 100)
                            Expanded(
                              flex: 100 - fim,
                              child: Container(color: COColors.white),
                            ),
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
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            _legenda(COColors.brand900, '${Carteira.euros(o.pago)} liquidado'),
            if (temFaturado)
              _legenda(
                _faturado,
                '${Carteira.euros(o.faturadoPorPagar)} faturado',
              ),
            _legenda(
              COColors.white,
              '${Carteira.euros(o.porFaturar)} por faturar',
              comBorda: true,
            ),
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
        Text(
          texto,
          style: const TextStyle(
            color: COColors.brand900,
            fontSize: 12,
            fontWeight: COTokens.fwBold,
          ),
        ),
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
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('launchUrl');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException
                ? e.message
                : 'Não foi possível abrir a fatura ${fatura.name}.',
          ),
          backgroundColor: COColors.brand700,
        ),
      );
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
              // Sem a etiqueta "FATURA" à frente: a secção já se chama assim.
              Expanded(
                child: Text(
                  f.name.isEmpty ? 'Fatura' : f.name,
                  style: Claro.titulo.copyWith(fontSize: 14),
                ),
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
                  icon: const Icon(
                    Icons.download_outlined,
                    size: 18,
                    color: COColors.brand900,
                  ),
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
              child: Text(
                linha,
                style: Claro.etiqueta.copyWith(color: COColors.brand900),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              _valor('Valor total', f.amountTotal),
              _valor('Liquidado', f.pago),
              _valor('Por liquidar', f.amountTotal - f.pago),
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
    final visiveis = cortar && !_todas ? fracoes.take(widget.maximo) : fracoes;
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
            child: Text(
              f,
              style: const TextStyle(
                color: COColors.brand900,
                fontSize: 11.5,
                fontWeight: COTokens.fwBold,
              ),
            ),
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

/// As aquisições de um empreendimento, fechadas atrás de "Ver frações (N)",
/// como no site desde 19/11: o cartão mostra primeiro o empreendimento e o
/// total, e as frações abrem-se aqui.
class ListaAquisicoes extends StatefulWidget {
  const ListaAquisicoes({
    super.key,
    required this.encomendas,
    required this.empreendimento,
  });

  final List<SaleOrder> encomendas;
  final String empreendimento;

  @override
  State<ListaAquisicoes> createState() => _ListaAquisicoesState();
}

class _ListaAquisicoesState extends State<ListaAquisicoes> {
  bool _aberta = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.encomendas.length;
    final rotulo = _aberta
        ? 'Esconder ${n == 1 ? 'fração' : 'frações'}'
        : (n == 1 ? 'Ver fração' : 'Ver frações ($n)');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton(
          onPressed: () => setState(() => _aberta = !_aberta),
          style: OutlinedButton.styleFrom(
            foregroundColor: COColors.brand900,
            side: const BorderSide(color: COColors.bordaClara),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                rotulo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: COTokens.fwBold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(_aberta ? Icons.expand_less : Icons.expand_more, size: 20),
            ],
          ),
        ),
        if (_aberta) ...[
          const SizedBox(height: 10),
          for (final o in widget.encomendas)
            CartaoAquisicao(
              encomenda: o,
              empreendimento: widget.empreendimento,
            ),
        ],
      ],
    );
  }
}

/// O total de um empreendimento e a barra a duas cores — o liquidado e o que
/// falta, "por liquidar" —, sem percentagens. É o card-valores do site,
/// debaixo do estado da obra.
class ValoresEmpreendimento extends StatelessWidget {
  const ValoresEmpreendimento({super.key, required this.encomendas});

  final List<SaleOrder> encomendas;

  @override
  Widget build(BuildContext context) {
    final total = Carteira.investimentoTotal(encomendas);
    final liquidado = Carteira.totalPago(encomendas);
    final porLiquidar = Carteira.totalPorPagar(encomendas);
    final pct = Carteira.percentagemPaga(encomendas).clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(Carteira.euros(total), style: Claro.titulo.copyWith(fontSize: 20)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              border: Border.all(color: COColors.bordaClara),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                if (pct > 0)
                  Expanded(
                    flex: pct,
                    child: Container(color: COColors.brand900),
                  ),
                if (pct < 100)
                  Expanded(
                    flex: 100 - pct,
                    child: Container(color: COColors.white),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            _legenda(
              COColors.brand900,
              '${Carteira.euros(liquidado)} liquidado',
            ),
            _legenda(
              COColors.white,
              '${Carteira.euros(porLiquidar)} por liquidar',
              comBorda: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _legenda(Color cor, String texto, {bool comBorda = false}) => Row(
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
      Text(
        texto,
        style: const TextStyle(
          color: COColors.brand900,
          fontSize: 12,
          fontWeight: COTokens.fwBold,
        ),
      ),
    ],
  );
}
