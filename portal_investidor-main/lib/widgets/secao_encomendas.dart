import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/sale_order.dart';
import '../services/api_service.dart';
import '../utils/contacto.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/carteira.dart';
import 'co_card.dart';

/// As encomendas do cliente, cada uma a abrir as suas faturas.
///
/// Lista, não cartões: cada encomenda é uma linha separada da seguinte por um
/// risco fino. Antes eram três caixas com borda seguidas das caixas dos
/// totais e da obra, e o ecrã lia-se como uma grelha de molduras.
class SecaoEncomendas extends StatefulWidget {
  const SecaoEncomendas({super.key, required this.encomendas});

  final List<SaleOrder> encomendas;

  @override
  State<SecaoEncomendas> createState() => _SecaoEncomendasState();
}

class _SecaoEncomendasState extends State<SecaoEncomendas> {
  /// Encomendas abertas, pelo id.
  final Set<int> _abertas = {};

  @override
  Widget build(BuildContext context) {
    if (widget.encomendas.isEmpty) return const SizedBox.shrink();

    // Agrupadas pelo nome do empreendimento, mantendo a ordem de chegada.
    final porProjeto = <String, List<SaleOrder>>{};
    for (final o in widget.encomendas) {
      porProjeto.putIfAbsent(o.projectName, () => []).add(o);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoTitulo('As suas aquisições'),
        for (final grupo in porProjeto.entries) ...[
          if (grupo.key.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: COTokens.space2, bottom: 2),
              child: Text(grupo.key, style: COText.caption),
            ),
          for (final o in grupo.value) _linha(o),
        ],
      ],
    );
  }

  Widget _linha(SaleOrder o) {
    final aberta = _abertas.contains(o.id);
    final temFaturas = o.invoices.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: COColors.brand700, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            // Sem faturas não há nada para abrir, por isso nem fica clicável.
            onTap: !temFaturas
                ? null
                : () => setState(() {
                      aberta ? _abertas.remove(o.id) : _abertas.add(o.id);
                    }),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: COTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.name,
                          style: COText.small.copyWith(color: COColors.white),
                        ),
                      ),
                      Text(
                        Carteira.euros(o.amountTotal),
                        style: COText.body.copyWith(
                          color: COColors.white,
                          fontWeight: COTokens.fwMedium,
                        ),
                      ),
                      if (temFaturas) ...[
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: aberta ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.expand_more,
                            size: 16,
                            color: COColors.neutral500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      Carteira.data(o.date),
                      if (o.fractions.isNotEmpty)
                        'frações ${o.fractions.join(', ')}',
                      if (!temFaturas)
                        'sem faturas'
                      else
                        '${Carteira.euros(o.pago)} pagos',
                    ].join('  ·  '),
                    style: COText.caption,
                  ),
                  if (temFaturas) ...[
                    const SizedBox(height: 8),
                    _BarraDeProgresso(o),
                  ],
                ],
              ),
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child:
                aberta ? _faturas(o) : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _faturas(SaleOrder o) {
    return Padding(
      // Encostadas à direita da linha da encomenda, para se perceber que
      // pertencem àquela e não à seguinte.
      padding: const EdgeInsets.only(
        left: COTokens.space4,
        bottom: COTokens.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final f in o.invoices)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.name, style: COText.caption),
                        // De que é a fatura. Sem isto o investidor via só o
                        // numero e o valor, e tinha de abrir o PDF para saber.
                        if (f.descricao.isNotEmpty)
                          Text(
                            f.descricao,
                            style: COText.caption.copyWith(
                              color: COColors.brand300,
                            ),
                          ),
                        Text(
                          '${Carteira.data(f.date)}  ·  ${f.estado.toLowerCase()}',
                          style: COText.caption.copyWith(
                            color: f.paymentState == 'paid'
                                ? COColors.brand300
                                : COColors.neutral500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: COTokens.space2),
                  Text(
                    Carteira.euros(f.amountTotal),
                    style: COText.caption.copyWith(color: COColors.white),
                  ),
                  // A fatura existe mas nao tem documento. Daqui sabe-se o
                  // empreendimento, por isso o pedido sai mais completo do
                  // que o do ecra das faturas.
                  if (f.attachments.isEmpty)
                    _PedirFatura(fatura: f, empreendimento: o.projectName),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Pedir uma fatura que não tem documento para descarregar.
///
/// Abre o formulário de contacto do Odoo já com o assunto e a mensagem
/// escritos, como o site faz no DescarregarFatura. Um ícone só, para não
/// competir com o valor da fatura ao lado.
class _PedirFatura extends StatelessWidget {
  const _PedirFatura({required this.fatura, required this.empreendimento});

  final Invoice fatura;
  final String empreendimento;

  Future<void> _abrir(BuildContext context) async {
    final investidor = ApiService.dadosLogado;
    final abriu = await launchUrl(
      Contacto.pedidoDeFatura(
        fatura: fatura.name,
        empreendimento: empreendimento,
        cliente: investidor?.name,
        email: investidor?.email,
      ),
      mode: LaunchMode.externalApplication,
    );
    if (!abriu && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o formulário de contacto.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => _abrir(context),
      tooltip: 'Pedir esta fatura',
      visualDensity: VisualDensity.compact,
      icon: const Icon(
        Icons.mail_outline,
        size: 16,
        color: COColors.brand300,
      ),
    );
  }
}

/// A barra de uma encomenda, em três fatias: pago, faturado por pagar, e o que
/// ainda nem sequer foi faturado.
///
/// É a mesma barra do site. A do meio quase sempre não existe — está tudo pago
/// — e nesse caso nem aparece. Serve para distinguir "ainda não me pediram" de
/// "pediram e eu não paguei", que para quem investe não é a mesma coisa.
class _BarraDeProgresso extends StatelessWidget {
  const _BarraDeProgresso(this.encomenda);

  final SaleOrder encomenda;

  @override
  Widget build(BuildContext context) {
    final total = encomenda.amountTotal;
    if (total <= 0) return const SizedBox.shrink();

    final pago = encomenda.pago;
    final faturado = encomenda.faturadoPorPagar;
    final restante = encomenda.porFaturar;

    // Peso em milesimos do total, e nao o valor em euros: um flex de
    // 142 500 000 e um numero sem razao de ser dentro de uma barra de 4px.
    // O minimo de 1 e para uma fatia muito pequena nao arredondar para zero e
    // sumir: fica um risco fino, que e a verdade, em vez de nada.
    int peso(double v) => math.max(1, ((v / total) * 1000).round());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            // A largura tem de ser dita. Dentro de uma Column alinhada a
            // esquerda os filhos ficam com largura solta, e um Row que so
            // tem Expanded nao tem largura propria nenhuma: a barra
            // encolhia para zero e desaparecia, legenda a parte.
            width: double.infinity,
            height: 4,
            child: Row(
              // Esticar, senao os filhos ficam centrados e um ColoredBox sem
              // filho nao tem altura nenhuma: a barra tinha largura e zero de
              // altura, que da no mesmo que nao estar la.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (pago > 0)
                  Expanded(
                    flex: peso(pago),
                    child: const ColoredBox(color: COColors.accent),
                  ),
                if (faturado > 0)
                  Expanded(
                    flex: peso(faturado),
                    child: const ColoredBox(color: COColors.brand300),
                  ),
                if (restante > 0)
                  Expanded(
                    flex: peso(restante),
                    child: const ColoredBox(color: COColors.brand700),
                  ),
              ],
            ),
          ),
        ),
        // A legenda só aparece quando há a fatia do meio. Sem ela a barra tem
        // duas cores e a linha de cima ja diz quanto foi pago.
        if (faturado > 0) ...[
          const SizedBox(height: 4),
          Text(
            '${Carteira.euros(faturado)} faturado, por pagar',
            style: COText.caption.copyWith(color: COColors.brand300),
          ),
        ],
      ],
    );
  }
}
