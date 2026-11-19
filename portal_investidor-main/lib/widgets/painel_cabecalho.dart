import 'package:flutter/material.dart';

import '../models/sale_order.dart';
import '../models/user_model.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/carteira.dart';
import 'painel_esqueleto.dart';

/// O topo do painel, a faixa navy do portal do site (PortalDashboard.tsx,
/// dashboard-hero): o "Olá", "Os Seus Imóveis" e o quadro com a
/// carteira, o valor total, o pago, o por pagar e o progresso.
///
/// As contas são as do site, todas a partir das encomendas (ver [Carteira]),
/// para os números baterem certo nos dois sítios.
class CabecalhoPainel extends StatelessWidget {
  const CabecalhoPainel({
    super.key,
    required this.nome,
    required this.obras,
    required this.encomendas,
    required this.aCarregar,
    this.aoTocarEmpreendimento,
  });

  final String nome;
  final List<ConstructionItem> obras;
  final List<SaleOrder> encomendas;
  final bool aCarregar;

  /// Tocar num empreendimento da carteira desce até ao cartão dele, como as
  /// âncoras do site.
  final void Function(ConstructionItem obra)? aoTocarEmpreendimento;

  static const Color _quadro = Color(0xFF0B3454);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _utilizador(),
        const SizedBox(height: COTokens.space6),
        Text(
          'Os Seus Imóveis',
          textAlign: TextAlign.center,
          style: COText.h1.copyWith(fontSize: 26, letterSpacing: -0.4),
        ),
        const SizedBox(height: COTokens.space6),
        Container(
          padding: const EdgeInsets.all(COTokens.space4 + 4),
          decoration: BoxDecoration(
            color: _quadro,
            border: Border.all(color: COColors.brand700),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _carteira(),
              if (aCarregar || encomendas.isNotEmpty) ...[
                const SizedBox(height: COTokens.space4),
                const Divider(height: 1, color: COColors.brand700),
                const SizedBox(height: COTokens.space4),
                if (aCarregar && encomendas.isEmpty)
                  const OssoEsqueleto(largura: 200, altura: 32)
                else
                  _valores(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _utilizador() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _primeiroNome.isEmpty ? 'Olá' : 'Olá, $_primeiroNome',
            style: COText.h1.copyWith(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Só o primeiro nome: "Olá, Guilherme Gonçalves" partia em duas linhas em
  /// muitos telemóveis e não dizia mais do que "Olá, Guilherme".
  String get _primeiroNome => nome.trim().split(RegExp(r'\s+')).first;

  Widget _etiqueta(String texto) => Text(
        texto.toUpperCase(),
        style: const TextStyle(
          color: COColors.brand300,
          fontSize: 11,
          fontWeight: COTokens.fwBold,
          letterSpacing: 1.4,
        ),
      );

  Widget _separador() => Container(
        width: 1,
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        color: COColors.brand500,
      );

  Widget _carteira() {
    final linhas = Carteira.porEmpreendimento(
      [for (final o in obras) o.title],
      encomendas,
    );
    final totalFracoes = Carteira.totalFracoes(linhas);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiqueta('Em carteira'),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              Carteira.contagem(
                  obras.length, 'empreendimento', 'empreendimentos'),
              style: _forte,
            ),
            if (encomendas.isNotEmpty) ...[
              _separador(),
              Text(Carteira.contagem(totalFracoes, 'fração', 'frações'),
                  style: _forte),
            ],
          ],
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < obras.length; i++)
          InkWell(
            onTap: aoTocarEmpreendimento == null
                ? null
                : () => aoTocarEmpreendimento!(obras[i]),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      obras[i].title,
                      style: const TextStyle(
                        color: COColors.white,
                        fontSize: 14,
                        fontWeight: COTokens.fwBold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (encomendas.isNotEmpty) ...[
                    _separador(),
                    Text(
                      Carteira.contagem(linhas[i].fracoes, 'fração', 'frações'),
                      style: const TextStyle(
                          color: COColors.brand300, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  static const TextStyle _forte = TextStyle(
    color: COColors.white,
    fontSize: 18,
    fontWeight: COTokens.fwBold,
  );

  /// O dinheiro, como o topo do portal do site desde 19/11/2026: o valor total
  /// e a barra a duas cores — o liquidado de todas as encomendas e o que
  /// falta, "por liquidar" — sem percentagens (a BarraPagamento "escura" do
  /// PortalDashboard.tsx). Antes eram o pago, o por pagar e o progresso.
  Widget _valores() {
    final total = Carteira.investimentoTotal(encomendas);
    final liquidado = Carteira.totalPago(encomendas);
    final porLiquidar = Carteira.totalPorPagar(encomendas);
    final pct = Carteira.percentagemPaga(encomendas).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiqueta('Valor total do investimento'),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            Carteira.euros(total),
            style: const TextStyle(
              color: COColors.white,
              fontSize: 28,
              fontWeight: COTokens.fwBold,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: COTokens.space4),
        Semantics(
          label: '${Carteira.euros(liquidado)} liquidado, '
              '${Carteira.euros(porLiquidar)} por liquidar',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (pct > 0)
                    Expanded(
                        flex: pct, child: Container(color: COColors.white)),
                  if (pct < 100)
                    Expanded(
                      flex: 100 - pct,
                      child: Container(color: COColors.brand700),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _legenda(COColors.white, '${Carteira.euros(liquidado)} liquidado'),
            _legenda(
                COColors.brand700, '${Carteira.euros(porLiquidar)} por liquidar'),
          ],
        ),
      ],
    );
  }

  Widget _legenda(Color cor, String texto) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: COColors.brand500),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: COColors.white,
              fontSize: 13,
              fontWeight: COTokens.fwBold,
            ),
          ),
        ],
      );
}
