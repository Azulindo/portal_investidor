import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import 'co_card.dart';

/// Mapa de acabamentos — o equivalente ao FinishesSection do site.
///
/// Acordeão: uma categoria aberta de cada vez, a primeira já aberta, como no
/// site. A nota do fim é a mesma, palavra por palavra — é texto que a empresa
/// escolheu e tem valor legal.
class SecaoAcabamentos extends StatefulWidget {
  const SecaoAcabamentos({super.key, required this.acabamentos});

  final List<ProjectFinish> acabamentos;

  @override
  State<SecaoAcabamentos> createState() => _SecaoAcabamentosState();
}

class _SecaoAcabamentosState extends State<SecaoAcabamentos> {
  int? _aberta = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.acabamentos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoOverline('Acabamentos'),
        Text('Mapa de acabamentos e serviços', style: COText.h2),
        const SizedBox(height: COTokens.space4),

        for (var i = 0; i < widget.acabamentos.length; i++)
          _categoria(i, widget.acabamentos[i]),

        const SizedBox(height: COTokens.space4),
        Text(
          'A listagem apresentada tem natureza indicativa, podendo sofrer '
          'alterações decorrentes do projeto, da execução da obra ou da '
          'disponibilidade dos fornecedores. As substituições, a acontecerem, '
          'respeitam os padrões de qualidade estabelecidos.',
          style: COText.caption,
        ),
      ],
    );
  }

  Widget _categoria(int indice, ProjectFinish cat) {
    final aberta = _aberta == indice;

    return CoCard(
      margin: const EdgeInsets.only(bottom: COTokens.space2),
      semPadding: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _aberta = aberta ? null : indice),
            child: Padding(
              padding: const EdgeInsets.all(COTokens.space4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      cat.categoryName,
                      style: COText.body.copyWith(
                        fontWeight: COTokens.fwMedium,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: aberta ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more,
                      size: 18,
                      color: COColors.brand300,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // AnimatedSize mede o conteúdo sozinho — no site isto obrigou a
          // medir a altura à mão com um ref.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: aberta ? _conteudo(cat) : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _conteudo(ProjectFinish cat) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        COTokens.space4,
        0,
        COTokens.space4,
        COTokens.space4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: COColors.brand700, height: COTokens.space4),
          for (final item in cat.details)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('–', style: COText.small),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: COText.small)),
                ],
              ),
            ),
          if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: COTokens.space2),
            ClipRRect(
              borderRadius: BorderRadius.circular(COTokens.radiusSm),
              child: Image.network(
                cat.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                // Imagem em falta não deve deixar um erro vermelho no meio da
                // lista: desaparece e os acabamentos continuam a ler-se.
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
