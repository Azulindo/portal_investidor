import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../widgets/co_drawer.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  late Future<List<Map<String, dynamic>>> _documentsFuture;

  @override
  void initState() {
    super.initState();
    _documentsFuture = ApiService().buscarDocumentos();
  }

  void _refresh() {
    setState(() {
      _documentsFuture = ApiService().buscarDocumentos();
    });
  }

  // Formats 18450.0 → "18.450,00 €"
  String _formatAmount(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]}.',
    );
    return '$intPart,${parts[1]} €';
  }

  // Converts "2025-07-01" → "1 Jul 2025"
  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  String _paymentStateLabel(String? state) {
    switch (state) {
      case 'paid':        return 'PAGO';
      case 'in_payment':  return 'EM PAGAMENTO';
      case 'partial':     return 'PARCIAL';
      default:            return 'NÃO PAGO';
    }
  }

  // Accents chosen to complement navy: teal, coral, gold
  static const Color _accentTeal   = Color(0xFF5BBFBF); // muted teal — positive/paid
  static const Color _accentCoral  = Color(0xFFD4826A); // warm coral — pending/unpaid
  static const Color _accentGold   = Color(0xFFCFA962); // soft gold — PDF / interactive

  // Returns bg/text color pair for the state chip
  ({Color bg, Color text}) _paymentStateChipColors(String? state) {
    switch (state) {
      case 'paid':
        return (bg: _accentTeal.withValues(alpha: 0.15), text: _accentTeal);
      case 'in_payment':
        return (bg: _accentGold.withValues(alpha: 0.15), text: _accentGold);
      case 'partial':
        return (bg: _accentCoral.withValues(alpha: 0.15), text: _accentGold);
      default:
        return (bg: _accentCoral.withValues(alpha: 0.12), text: _accentCoral);
    }
  }

  Future<void> _downloadAttachment(int attachmentId, String name) async {
    final url = Uri.parse(ApiConfig.attachmentDownloadUrl(attachmentId));
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível abrir "$name"'),
            backgroundColor: COColors.brand700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: COColors.brand900,
      appBar: AppBar(
        backgroundColor: COColors.brand900,
        title: const Text(
          'OS SEUS DOCUMENTOS',
          style: TextStyle(
            color: COColors.white,
            fontSize: 13,
            fontWeight: COTokens.fwBold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: COColors.white),
        elevation: 0,
      ),
      drawer: const CoDrawer(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: COColors.brand300),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(COTokens.space6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: COColors.neutral500, size: 48),
                    const SizedBox(height: COTokens.space6),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: COColors.neutral500, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: COTokens.space6),
                    TextButton(
                      onPressed: _refresh,
                      child: const Text('Tentar novamente', style: TextStyle(color: COColors.brand300)),
                    ),
                  ],
                ),
              ),
            );
          }

          final documents = snapshot.data ?? [];

          double totalPago = 0.0;
          double totalPendente = 0.0;
          for (final doc in documents) {
            final amount = double.tryParse(doc['amountTotal']?.toString() ?? '0') ?? 0.0;
            if (doc['paymentState'] == 'paid') {
              totalPago += amount;
            } else {
              totalPendente += amount;
            }
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: COColors.brand300,
            backgroundColor: COColors.brand700,
            child: Column(
              children: [
                // Summary row
                Padding(
                  padding: const EdgeInsets.all(COTokens.space6),
                  child: Container(
                    padding: const EdgeInsets.all(COTokens.space6),
                    decoration: BoxDecoration(
                      color: COColors.brand700.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(COTokens.radiusSm),
                      border: Border.all(color: COColors.brand700, width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL PAGO',
                                style: TextStyle(
                                  color: COColors.neutral500,
                                  fontSize: 11,
                                  fontWeight: COTokens.fwMedium,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatAmount(totalPago),
                                style: const TextStyle(
                                  color: _accentTeal,
                                  fontSize: 16,
                                  fontWeight: COTokens.fwBold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: COColors.brand700),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EM FALTA',
                                style: TextStyle(
                                  color: COColors.neutral500,
                                  fontSize: 11,
                                  fontWeight: COTokens.fwMedium,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatAmount(totalPendente),
                                style: const TextStyle(
                                  color: _accentCoral,
                                  fontSize: 16,
                                  fontWeight: COTokens.fwBold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: COTokens.space6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'LISTA DE FATURAS',
                      style: TextStyle(
                        color: COColors.neutral500,
                        fontSize: 11,
                        fontWeight: COTokens.fwBold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: documents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Opacity(
                                opacity: 0.2,
                                child: Image.asset('assets/images/logo.png', height: 80),
                              ),
                              const SizedBox(height: COTokens.space6),
                              const Text(
                                'Ainda não existem registos associados ao seu perfil.',
                                style: TextStyle(color: COColors.neutral500, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(
                            left: COTokens.space6,
                            right: COTokens.space6,
                            bottom: COTokens.space6,
                          ),
                          itemCount: documents.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final doc = documents[index];
                            final String? paymentState = doc['paymentState'];
                            final double amount =
                                double.tryParse(doc['amountTotal']?.toString() ?? '0') ?? 0.0;
                            final List attachments = (doc['attachments'] as List?) ?? [];
                            final String displayName = attachments.isNotEmpty
                                ? (attachments[0] as Map<String, dynamic>)['name'] ?? doc['name'] ?? 'Documento'
                                : doc['name'] ?? 'Documento';
                            final String? rawDate = doc['date'];
                            final String formattedDate = rawDate != null
                                ? _formatDate(rawDate)
                                : 'Data não registada';
                            final chipColors = _paymentStateChipColors(paymentState);

                            return Container(
                              padding: const EdgeInsets.all(COTokens.space6),
                              decoration: BoxDecoration(
                                color: COColors.brand700.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(COTokens.radiusSm),
                                border: Border.all(color: COColors.brand700, width: 1),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Text content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            color: COColors.white,
                                            fontWeight: COTokens.fwMedium,
                                            fontSize: 15,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          formattedDate,
                                          style: const TextStyle(
                                            color: COColors.neutral500,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _formatAmount(amount),
                                          style: const TextStyle(
                                            color: COColors.white,
                                            fontWeight: COTokens.fwBold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: chipColors.bg,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _paymentStateLabel(paymentState),
                                            style: TextStyle(
                                              color: chipColors.text,
                                              fontWeight: COTokens.fwBold,
                                              fontSize: 11,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // PDF button — right, vertically centred
                                  if (attachments.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: () {
                                        final attachment =
                                            attachments[0] as Map<String, dynamic>;
                                        final int? attachmentId =
                                            attachment['id'] as int?;
                                        final String attachmentName =
                                            attachment['name'] ?? 'documento.pdf';
                                        if (attachmentId != null) {
                                          _downloadAttachment(
                                              attachmentId, attachmentName);
                                        }
                                      },
                                      child: Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          color: _accentGold.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                              color: _accentGold.withValues(alpha: 0.35),
                                              width: 1),
                                        ),
                                        child: const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.article_outlined,
                                                color: _accentGold, size: 24),
                                            SizedBox(height: 4),
                                            Text(
                                              'PDF',
                                              style: TextStyle(
                                                color: _accentGold,
                                                fontSize: 11,
                                                fontWeight: COTokens.fwBold,
                                                letterSpacing: 0.5,
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
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
