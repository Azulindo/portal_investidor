import 'dart:math' as math;

// Encomendas do cliente e respetivas faturas — GET /document/sale-orders.
//
// Vêm do Odoo (view_sale_order e account.move). É o que alimenta os totais do
// painel: o investimento total, o que já foi pago e o que falta.

/// Anexo de uma fatura.
///
/// O download já funciona: a API reativou as rotas em 2026-10-08. Ver
/// ApiConfig.downloadDeAnexosDisponivel.
class InvoiceAttachment {
  final int? id;
  final String? name;
  final String? mimetype;

  InvoiceAttachment({this.id, this.name, this.mimetype});

  factory InvoiceAttachment.fromJson(Map<String, dynamic> json) {
    return InvoiceAttachment(
      id: int.tryParse(json['id']?.toString() ?? ''),
      name: json['name']?.toString(),
      mimetype: json['mimetype']?.toString(),
    );
  }
}

/// Fatura associada a uma encomenda.
class Invoice {
  final int id;
  final String name;
  final String date;

  /// Estado de pagamento do Odoo (account.move.payment_state):
  /// paid | not_paid | partial | in_payment | reversed.
  final String? paymentState;

  final double amountTotal;

  /// O que ainda está em dívida. Numa fatura parcial é a parte por liquidar,
  /// e 0 quando está toda paga.
  final double amountResidual;

  final List<InvoiceAttachment> attachments;

  /// As linhas de artigo da fatura, que dizem de que ela é.
  ///
  /// Vem da account_move_line, uma entrada por linha — quase sempre uma só.
  /// Linhas sem descrição nao chegam cá: a API já as deixa de fora.
  final List<String> description;

  Invoice({
    required this.id,
    required this.name,
    required this.date,
    this.paymentState,
    this.amountTotal = 0,
    this.amountResidual = 0,
    this.attachments = const [],
    this.description = const [],
  });

  /// Quanto desta fatura já está liquidado.
  ///
  /// Só "paid" e "partial" têm residual de confiança. Nas outras (não pagas,
  /// por exemplo) umas trazem residual igual ao total e outras trazem 0, por
  /// isso conta-se 0 pago. É a mesma regra do site (invoicePaid), e é a razão
  /// de o total pago do painel bater certo.
  double get pago {
    if (paymentState == 'paid' || paymentState == 'partial') {
      return amountTotal - amountResidual;
    }
    return 0;
  }

  /// Quanto desta fatura já foi faturado ao cliente, esteja pago ou não.
  ///
  /// As estornadas valem 0: foram anuladas por nota de crédito, e notas de
  /// crédito a API não devolve (a consulta só traz move_type = 'out_invoice'),
  /// por isso contá-las mostrava uma dívida que já não existe. É a mesma regra
  /// do site (invoiceIssued).
  double get faturado => paymentState == 'reversed' ? 0 : amountTotal;

  /// As linhas de artigo numa linha só, ou vazio se a fatura não trouxer nenhuma.
  String get descricao => description.join('  ·  ');

  /// Etiqueta em português do estado de pagamento.
  String get estado {
    switch (paymentState) {
      case 'paid':
        return 'Paga';
      case 'not_paid':
        return 'Por pagar';
      case 'partial':
        return 'Parcial';
      case 'in_payment':
        return 'Em pagamento';
      case 'reversed':
        return 'Estornada';
      default:
        return 'Por pagar';
    }
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      paymentState: json['paymentState']?.toString(),
      // As colunas de dinheiro são "numeric" na base de dados, o que em JSON
      // chega como texto — daí o toString antes do parse.
      amountTotal: double.tryParse(json['amountTotal']?.toString() ?? '') ?? 0,
      amountResidual:
          double.tryParse(json['amountResidual']?.toString() ?? '') ?? 0,
      attachments: (json['attachments'] as List? ?? [])
          .whereType<Map>()
          .map((e) => InvoiceAttachment.fromJson(e.cast<String, dynamic>()))
          .toList(),
      description: (json['description'] as List? ?? [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }
}

/// Uma encomenda do cliente.
class SaleOrder {
  final int id;
  final String name;

  /// Nome do empreendimento. Vem do mesmo app_project.name que os cartões de
  /// obra, por isso dá para juntar as encomendas ao projeto certo pelo nome.
  final String projectName;

  /// Que frações é que esta encomenda inclui.
  final List<String> fractions;

  final double amountTotal;
  final String date;
  final List<Invoice> invoices;

  SaleOrder({
    required this.id,
    required this.name,
    this.projectName = '',
    this.fractions = const [],
    this.amountTotal = 0,
    this.date = '',
    this.invoices = const [],
  });

  /// Quanto já foi liquidado nesta encomenda.
  double get pago => invoices.fold(0.0, (soma, f) => soma + f.pago);

  double get porPagar => amountTotal - pago;

  /// O meio da barra: já faturado, ainda por pagar.
  ///
  /// Quase sempre é zero, porque está tudo pago. Vai limitado dos dois lados
  /// porque uma encomenda pode vir sobrefaturada, e a fatia não pode comer
  /// mais do que o que falta pagar nem ficar negativa.
  double get faturadoPorPagar {
    final faturado = invoices.fold(0.0, (soma, f) => soma + f.faturado);
    return math.min(
      math.max(faturado - pago, 0),
      math.max(amountTotal - pago, 0),
    );
  }

  /// O resto: o que ainda nem sequer foi faturado.
  double get porFaturar =>
      math.max(amountTotal - pago - faturadoPorPagar, 0);

  factory SaleOrder.fromJson(Map<String, dynamic> json) {
    return SaleOrder(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      projectName: json['projectName']?.toString() ?? '',
      fractions: (json['fractions'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      amountTotal: double.tryParse(json['amountTotal']?.toString() ?? '') ?? 0,
      date: json['date']?.toString() ?? '',
      invoices: (json['invoices'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Invoice.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}
