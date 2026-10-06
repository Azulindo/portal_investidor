import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_model.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/fracoes.dart';
import 'co_card.dart';

/// Frações do empreendimento — o equivalente ao FractionsTable do site.
///
/// No site é uma tabela larga com onze colunas. Num telemóvel isso não se lê,
/// por isso aqui são duas camadas, como o site faz em ecrã pequeno:
///
///   1. o quadro das tipologias, sempre visível, uma linha por tipologia;
///   2. a lista das frações, cada uma num cartão, aberta a pedido e com os
///      três filtros (Tipologia, Disponibilidade, Piso).
///
/// Carregar numa tipologia do quadro abre a lista já filtrada a essa
/// tipologia, como no site.
///
/// O preço aparece sempre: na app há sempre sessão, e a API só esconde o
/// preço a pedidos anónimos.
class SecaoFracoes extends StatefulWidget {
  const SecaoFracoes({super.key, required this.fracoes});

  final List<ProjectFraction> fracoes;

  @override
  State<SecaoFracoes> createState() => _SecaoFracoesState();
}

class _SecaoFracoesState extends State<SecaoFracoes> {
  bool _aberta = false;

  // null em qualquer um destes é "todas".
  String? _tipologia;
  String? _estado;
  String? _piso;

  bool get _temFiltro =>
      _tipologia != null || _estado != null || _piso != null;

  void _limpar() => setState(() {
        _tipologia = null;
        _estado = null;
        _piso = null;
      });

  void _verTipologia(String tipologia) => setState(() {
        _estado = null;
        _piso = null;
        _tipologia = tipologia;
        _aberta = true;
      });

  Future<void> _abrirPlanta(String url) async {
    bool ok;
    try {
      ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a planta.'),
          backgroundColor: COColors.brand700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Empreendimentos ainda em desenvolvimento não têm frações na API — a
    // secção simplesmente não aparece, como no site.
    if (widget.fracoes.isEmpty) return const SizedBox.shrink();

    final resumo = Fracoes.resumo(widget.fracoes);
    final estados = Fracoes.estados(widget.fracoes);
    final pisos = Fracoes.pisos(widget.fracoes);
    final visiveis = Fracoes.filtrar(
      widget.fracoes,
      tipologia: _tipologia,
      estado: _estado,
      piso: _piso,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoOverline('Tipologias'),
        Text('Frações e características', style: COText.h2),
        const SizedBox(height: COTokens.space2),
        Text(
          'Toque numa tipologia para ver só essas frações.',
          style: COText.caption,
        ),
        const SizedBox(height: COTokens.space4),

        for (final linha in resumo) _linhaResumo(linha),

        const SizedBox(height: COTokens.space2),
        _botaoVerMais(),

        if (_aberta) ...[
          const SizedBox(height: COTokens.space6),
          _filtros(resumo, estados, pisos),
          const SizedBox(height: COTokens.space4),
          _contador(visiveis.length),
          const SizedBox(height: COTokens.space4),
          if (visiveis.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: COTokens.space6),
              child: Text(
                'Nenhuma fração corresponde a estes filtros.',
                style: COText.small,
              ),
            )
          else
            for (final f in visiveis) _cartaoFracao(f, pisos.isNotEmpty),
        ],
      ],
    );
  }

  Widget _linhaResumo(ResumoTipologia linha) {
    return CoCard(
      onTap: () => _verTipologia(linha.tipologia),
      margin: const EdgeInsets.only(bottom: COTokens.space2),
      padding: const EdgeInsets.all(COTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  linha.tipologia,
                  style: COText.body.copyWith(fontWeight: COTokens.fwBold),
                ),
              ),
              Text(
                Fracoes.contagem(linha.quantidade),
                style: COText.small,
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                color: COColors.neutral500,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: COTokens.space2),
          Wrap(
            spacing: COTokens.space4,
            runSpacing: 4,
            children: [
              _parzinho('Área', linha.area),
              if (linha.exterior != '—') _parzinho('Exterior', linha.exterior),
              if (linha.garagem != '—') _parzinho('Garagem', linha.garagem),
            ],
          ),
          if (linha.disponiveis > 0) ...[
            const SizedBox(height: COTokens.space2),
            _selo('${linha.disponiveis} por vender'),
          ],
        ],
      ),
    );
  }

  /// Etiqueta pequena com o valor ao lado, para as áreas do quadro resumo.
  Widget _parzinho(String etiqueta, String valor) {
    return RichText(
      text: TextSpan(
        style: COText.caption,
        children: [
          TextSpan(text: '${etiqueta.toUpperCase()}  '),
          TextSpan(
            text: valor,
            style: COText.small.copyWith(color: COColors.white),
          ),
        ],
      ),
    );
  }

  Widget _selo(String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: COColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: COColors.brand300.withValues(alpha: 0.5)),
      ),
      child: Text(
        texto.toUpperCase(),
        style: COText.caption.copyWith(
          color: COColors.white,
          fontSize: 10,
          fontWeight: COTokens.fwBold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _botaoVerMais() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => setState(() => _aberta = !_aberta),
        icon: Icon(
          _aberta ? Icons.expand_less : Icons.expand_more,
          size: 18,
          color: COColors.brand300,
        ),
        label: Text(
          _aberta
              ? 'Esconder frações'
              : 'Ver todas — ${Fracoes.contagem(widget.fracoes.length)}',
          style: COText.small.copyWith(
            color: COColors.brand300,
            fontWeight: COTokens.fwMedium,
          ),
        ),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
      ),
    );
  }

  Widget _filtros(
    List<ResumoTipologia> resumo,
    List<String> estados,
    List<String> pisos,
  ) {
    return Wrap(
      spacing: COTokens.space4,
      runSpacing: COTokens.space4,
      children: [
        _filtro<String>(
          etiqueta: 'Tipologia',
          valor: _tipologia,
          textoDeTodas: 'Todas',
          opcoes: [
            for (final r in resumo)
              (valor: r.tipologia, texto: '${r.tipologia} (${r.quantidade})'),
          ],
          aoMudar: (v) => setState(() => _tipologia = v),
        ),
        // Os filtros de estado e de piso só aparecem quando há mais de um
        // valor — com um só, o filtro não filtra nada. É o que o site faz.
        if (estados.length > 1)
          _filtro<String>(
            etiqueta: 'Disponibilidade',
            valor: _estado,
            textoDeTodas: 'Todas',
            opcoes: [for (final e in estados) (valor: e, texto: e)],
            aoMudar: (v) => setState(() => _estado = v),
          ),
        if (pisos.length > 1)
          _filtro<String>(
            etiqueta: 'Piso',
            valor: _piso,
            textoDeTodas: 'Todos',
            opcoes: [for (final p in pisos) (valor: p, texto: p)],
            aoMudar: (v) => setState(() => _piso = v),
          ),
      ],
    );
  }

  Widget _filtro<T extends Object>({
    required String etiqueta,
    required T? valor,
    required String textoDeTodas,
    required List<({T valor, String texto})> opcoes,
    required void Function(T?) aoMudar,
  }) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta.toUpperCase(), style: COText.overline),
          const SizedBox(height: 6),
          DropdownButtonFormField<T?>(
            initialValue: valor,
            isExpanded: true,
            dropdownColor: COColors.brand700,
            iconEnabledColor: COColors.brand300,
            style: COText.small.copyWith(color: COColors.white),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: COColors.brand700,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(COTokens.radiusSm),
                borderSide: const BorderSide(color: COColors.brand500),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(COTokens.radiusSm),
                borderSide: const BorderSide(color: COColors.brand500),
              ),
            ),
            items: [
              DropdownMenuItem<T?>(
                value: null,
                child: Text(textoDeTodas, style: COText.small),
              ),
              for (final o in opcoes)
                DropdownMenuItem<T?>(
                  value: o.valor,
                  child: Text(
                    o.texto,
                    style: COText.small.copyWith(color: COColors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: aoMudar,
          ),
        ],
      ),
    );
  }

  Widget _contador(int visiveis) {
    return Row(
      children: [
        Text(
          '$visiveis de ${Fracoes.contagem(widget.fracoes.length)}',
          style: COText.caption,
        ),
        if (_temFiltro) ...[
          const SizedBox(width: COTokens.space4),
          InkWell(
            onTap: _limpar,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'limpar filtros',
                style: COText.caption.copyWith(
                  color: COColors.brand300,
                  fontWeight: COTokens.fwMedium,
                  decoration: TextDecoration.underline,
                  decorationColor: COColors.brand300,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _cartaoFracao(ProjectFraction f, bool mostrarPiso) {
    return CoCard(
      margin: const EdgeInsets.only(bottom: COTokens.space2),
      padding: const EdgeInsets.all(COTokens.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.fractionNumber,
                      style: COText.body.copyWith(fontWeight: COTokens.fwBold),
                    ),
                    Text(f.type, style: COText.small),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    f.price != null ? Fracoes.euros(f.price!) : 'Sob consulta',
                    style: COText.valor.copyWith(
                      color: COColors.white,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _selo(f.status),
                ],
              ),
            ],
          ),
          const SizedBox(height: COTokens.space2),
          Wrap(
            spacing: COTokens.space4,
            runSpacing: 4,
            children: [
              if (f.block != null) _parzinho('Bloco', '${f.block}'),
              if (mostrarPiso && f.floor != null)
                _parzinho('Piso', f.floor!),
              if (f.orientation != null)
                _parzinho('Orientação', f.orientation!),
              if (f.totalArea > 0)
                _parzinho('Área bruta', '${Fracoes.numero(f.totalArea)} m²'),
              if ((f.garageArea ?? 0) > 0)
                _parzinho('Garagem', '${Fracoes.numero(f.garageArea!)} m²'),
              if ((f.balconyArea ?? 0) > 0)
                _parzinho('Varanda', '${Fracoes.numero(f.balconyArea!)} m²'),
            ],
          ),
          if (f.floorPlanUrl != null && f.floorPlanUrl!.isNotEmpty) ...[
            const SizedBox(height: COTokens.space2),
            InkWell(
              onTap: () => _abrirPlanta(f.floorPlanUrl!),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 14,
                      color: COColors.brand300,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ver planta',
                      style: COText.small.copyWith(
                        color: COColors.brand300,
                        fontWeight: COTokens.fwMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
