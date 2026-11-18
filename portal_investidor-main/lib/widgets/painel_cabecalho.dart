import 'package:flutter/material.dart';

import '../models/sale_order.dart';
import '../models/user_model.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/carteira.dart';
import 'painel_esqueleto.dart';

/// O topo do painel, a faixa navy do portal do site (PortalDashboard.tsx,
/// dashboard-hero): quem está a ver, "Os Seus Imóveis" e o quadro com a
/// carteira, o valor total, o pago, o por pagar e o progresso.
///
/// As contas são as do site, todas a partir das encomendas (ver [Carteira]),
/// para os números baterem certo nos dois sítios.
class CabecalhoPainel extends StatelessWidget {
  const CabecalhoPainel({
    super.key,
    required this.nome,
    required this.email,
    required this.obras,
    required this.encomendas,
    required this.aCarregar,
    this.aoTocarEmpreendimento,
  });

  final String nome;
  final String email;
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
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: COColors.brand700,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_outline,
              color: COColors.white, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nome.trim().isEmpty ? 'Cliente' : nome.trim(),
                style: COText.body.copyWith(
                  fontWeight: COTokens.fwBold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: COText.caption.copyWith(color: COColors.brand300),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

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

  Widget _valores() {
    final total = Carteira.investimentoTotal(encomendas);
    final pago = Carteira.totalPago(encomendas);
    final porPagar = Carteira.totalPorPagar(encomendas);
    final pct = Carteira.percentagemPaga(encomendas).clamp(0, 100);

    Widget valor(String etiqueta, double v, {double tamanho = 22}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _etiqueta(etiqueta),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Carteira.euros(v),
                style: TextStyle(
                  color: COColors.white,
                  fontSize: tamanho,
                  fontWeight: COTokens.fwBold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        valor('Valor total', total, tamanho: 28),
        const SizedBox(height: COTokens.space4),
        Row(
          children: [
            Expanded(child: valor('Pago', pago)),
            const SizedBox(width: COTokens.space4),
            Expanded(child: valor('Por pagar', porPagar)),
          ],
        ),
        const SizedBox(height: COTokens.space4),
        const Divider(height: 1, color: COColors.brand700),
        const SizedBox(height: COTokens.space4),
        Row(
          children: [
            Expanded(child: _etiqueta('Progresso')),
            Text(
              '$pct%',
              style: const TextStyle(
                color: COColors.white,
                fontSize: 15,
                fontWeight: COTokens.fwBold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Semantics(
          label: '$pct por cento pago',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
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
      ],
    );
  }
}
