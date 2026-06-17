import 'package:flutter/material.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../widgets/co_drawer.dart';
import '../services/api_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  Future<void> _refreshDocuments() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    List faturas = ApiService.dadosLogado?.faturas ?? [];

    double totalPago = 0.0;
    double totalPendente = 0.0;

    for (var f in faturas) {
      var valorBruto = f['valor'] ?? f['Valor'];
      double valor = double.tryParse(valorBruto?.toString().replaceAll(',', '.') ?? '0') ?? 0.0;
      if (f['status'] == 'Pago') {
        totalPago += valor;
      } else {
        totalPendente += valor;
      }
    }

    return Scaffold(
      backgroundColor: COColors.brand900,
      appBar: AppBar(
        backgroundColor: COColors.brand900,
        title: const Text('PORTAL DE DOCUMENTOS',
            style: TextStyle(color: COColors.white, fontSize: 13, fontWeight: COTokens.fwBold, letterSpacing: 2)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: COColors.white),
        elevation: 0,
      ),
      drawer: const CoDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshDocuments,
        color: COColors.white,
        backgroundColor: COColors.brand900,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(COTokens.space6),
              child: Container(
                padding: const EdgeInsets.all(COTokens.space6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(COTokens.radiusSm),
                  border: Border.all(color: COColors.brand700, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOTAL PAGO',
                              style: TextStyle(color: COColors.neutral500, fontSize: 11, fontWeight: COTokens.fwMedium, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text('${totalPago.toStringAsFixed(2)} €',
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: COTokens.fwBold)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: COColors.brand700),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EM VALIDAÇÃO',
                              style: TextStyle(color: COColors.neutral500, fontSize: 11, fontWeight: COTokens.fwMedium, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text('${totalPendente.toStringAsFixed(2)} €',
                              style: const TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: COTokens.fwBold)),
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
                child: Text('HISTÓRICO DE FATURAÇÃO',
                    style: TextStyle(color: COColors.brand300, fontSize: 11, fontWeight: COTokens.fwBold, letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: faturas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(opacity: 0.2, child: Image.asset('assets/images/logo.png', height: 80)),
                          const SizedBox(height: COTokens.space6),
                          const Text('Ainda não existem registos associados ao seu perfil.',
                              style: TextStyle(color: COColors.neutral500, fontSize: 14), textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(left: COTokens.space6, right: COTokens.space6, bottom: COTokens.space6),
                      itemCount: faturas.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        var fatura = faturas[index];
                        bool isPago = fatura['status'] == 'Pago';
                        var valorFaturaBruto = fatura['valor'] ?? fatura['Valor'];
                        double valorFatura = double.tryParse(valorFaturaBruto?.toString().replaceAll(',', '.') ?? '0') ?? 0.0;
                        String? linkDaImagem = fatura['imageUrl'];

                        return Container(
                          padding: const EdgeInsets.all(COTokens.space6),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(COTokens.radiusSm),
                              border: Border.all(color: COColors.brand700, width: 1)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (linkDaImagem != null && linkDaImagem.isNotEmpty) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              backgroundColor: Colors.transparent,
                                              insetPadding: const EdgeInsets.all(10),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  InteractiveViewer(
                                                    panEnabled: true,
                                                    minScale: 0.5,
                                                    maxScale: 4,
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(COTokens.radiusSm),
                                                      child: Image.network(linkDaImagem, fit: BoxFit.contain),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: IconButton(
                                                      icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
                                                      onPressed: () => Navigator.of(context).pop(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                            color: COColors.brand900,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: COColors.brand700)),
                                        clipBehavior: Clip.hardEdge,
                                        child: linkDaImagem != null && linkDaImagem.isNotEmpty
                                            ? Image.network(
                                                linkDaImagem,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, progress) {
                                                  if (progress == null) return child;
                                                  return const Padding(
                                                    padding: EdgeInsets.all(12.0),
                                                    child: CircularProgressIndicator(color: COColors.brand300, strokeWidth: 2),
                                                  );
                                                },
                                                errorBuilder: (context, error, stack) => Icon(
                                                    isPago ? Icons.receipt_long_rounded : Icons.history_toggle_off_rounded,
                                                    color: isPago ? Colors.greenAccent : Colors.orangeAccent,
                                                    size: 24),
                                              )
                                            : Icon(
                                                isPago ? Icons.receipt_long_rounded : Icons.history_toggle_off_rounded,
                                                color: isPago ? Colors.greenAccent : Colors.orangeAccent,
                                                size: 24),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fatura['title'] ?? 'Documento Comercial',
                                            style: const TextStyle(color: COColors.white, fontWeight: COTokens.fwMedium, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(fatura['data'] ?? 'Data não registada',
                                              style: const TextStyle(color: COColors.neutral500, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${valorFatura.toStringAsFixed(2)} €',
                                      style: const TextStyle(color: COColors.white, fontWeight: COTokens.fwBold, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                    (fatura['status'] ?? 'Pendente').toUpperCase(),
                                    style: TextStyle(
                                        color: isPago ? Colors.greenAccent : Colors.orangeAccent,
                                        fontWeight: COTokens.fwBold,
                                        fontSize: 10,
                                        letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}