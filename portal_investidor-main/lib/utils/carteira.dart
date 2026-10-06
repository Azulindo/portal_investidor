import '../models/sale_order.dart';

/// Os totais do investidor, calculados a partir das encomendas.
///
/// Todos saem das mesmas encomendas, de propósito: assim o investimento
/// total, o pago e o por pagar reconciliam sempre entre si. São as mesmas
/// contas do portal do site (components/PortalDashboard.tsx) — se divergirem,
/// a app e o site mostram dinheiro diferente à mesma pessoa, que é o pior
/// erro que esta app pode ter.
class Carteira {
  Carteira._();

  /// Soma do valor de todas as encomendas.
  static double investimentoTotal(List<SaleOrder> encomendas) =>
      encomendas.fold(0.0, (soma, o) => soma + o.amountTotal);

  /// Parte já liquidada, somando fatura a fatura.
  ///
  /// A regra de o que conta como pago está em Invoice.pago: só as faturas
  /// "paid" e "partial" têm residual de confiança.
  static double totalPago(List<SaleOrder> encomendas) =>
      encomendas.fold(0.0, (soma, o) => soma + o.pago);

  static double totalPorPagar(List<SaleOrder> encomendas) =>
      investimentoTotal(encomendas) - totalPago(encomendas);

  /// Percentagem paga, de 0 a 100, arredondada.
  ///
  /// Sem investimento nenhum dá 0 e não uma divisão por zero.
  static int percentagemPaga(List<SaleOrder> encomendas) {
    final total = investimentoTotal(encomendas);
    if (total <= 0) return 0;
    return (totalPago(encomendas) / total * 100).round();
  }

  /// O que a pessoa tem, empreendimento a empreendimento.
  ///
  /// As frações contam-se sem repetições: a mesma fração pode aparecer em
  /// mais do que uma encomenda (um reforço, uma alteração), e contá-la duas
  /// vezes dava uma carteira maior do que a verdadeira.
  ///
  /// [nomesDosProjetos] são os empreendimentos do cliente, pela ordem em que
  /// se querem mostrar; a junção às encomendas é pelo nome, que é o mesmo
  /// app_project.name dos dois lados.
  static List<LinhaCarteira> porEmpreendimento(
    List<String> nomesDosProjetos,
    List<SaleOrder> encomendas,
  ) {
    return [
      for (final nome in nomesDosProjetos)
        LinhaCarteira(
          empreendimento: nome,
          fracoes: encomendas
              .where((o) => o.projectName == nome)
              .expand((o) => o.fractions)
              .toSet()
              .length,
        ),
    ];
  }

  /// Encomendas de um empreendimento.
  static List<SaleOrder> doEmpreendimento(
    String nome,
    List<SaleOrder> encomendas,
  ) =>
      encomendas.where((o) => o.projectName == nome).toList();

  /// Total de frações da carteira, sem repetições dentro de cada
  /// empreendimento.
  static int totalFracoes(List<LinhaCarteira> carteira) =>
      carteira.fold(0, (soma, c) => soma + c.fracoes);

  /// Dinheiro à portuguesa, sem cêntimos — como no painel do site.
  static String euros(double v) {
    final negativo = v < 0;
    final inteiro = v.abs().round().toString();
    final partes = <String>[];
    for (var i = inteiro.length; i > 0; i -= 3) {
      partes.insert(0, inteiro.substring(i - 3 < 0 ? 0 : i - 3, i));
    }
    return '${negativo ? '-' : ''}${partes.join(' ')} €';
  }

  /// "1 fração" / "3 frações", "1 empreendimento" / "2 empreendimentos".
  static String contagem(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';

  /// Data do Odoo ("2026-03-14" ou ISO completo) em "14/03/2026".
  ///
  /// Datas que não se consigam ler devolvem-se como vieram, em vez de se
  /// mostrar um traço: o valor original pelo menos diz alguma coisa.
  static String data(String bruta) {
    if (bruta.isEmpty) return '—';
    final d = DateTime.tryParse(bruta);
    if (d == null) return bruta;
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }
}

/// Uma linha da carteira: o empreendimento e quantas frações a pessoa lá tem.
class LinhaCarteira {
  final String empreendimento;
  final int fracoes;

  const LinhaCarteira({required this.empreendimento, required this.fracoes});
}
