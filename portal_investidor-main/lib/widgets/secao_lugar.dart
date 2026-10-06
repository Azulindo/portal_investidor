import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import 'co_card.dart';

/// "O lugar" — a envolvente do empreendimento: o que existe na zona e a que
/// distância ficam os sítios de referência.
///
/// Equivalente ao ZoneSection do site. Vem dos campos zone* de
/// GET /project/details → projectInfo, e não aparece enquanto o backoffice
/// não os preencher.
///
/// No site as duas listas ficam lado a lado; aqui ficam uma debaixo da outra,
/// que num telemóvel é o que acontece de qualquer maneira.
class SecaoLugar extends StatelessWidget {
  const SecaoLugar({super.key, required this.info});

  final ProjectInfo info;

  bool get _temConteudo =>
      (info.zoneTitle?.trim().isNotEmpty ?? false) ||
      (info.zoneDescription?.trim().isNotEmpty ?? false) ||
      info.zoneNearbyInfrastructures.isNotEmpty ||
      info.zoneNearbyLocations.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_temConteudo) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoOverline('O lugar'),
        if (info.zoneTitle?.trim().isNotEmpty ?? false) ...[
          Text(info.zoneTitle!, style: COText.h2),
          const SizedBox(height: COTokens.space2),
        ],
        if (info.zoneDescription?.trim().isNotEmpty ?? false)
          Text(
            info.zoneDescription!,
            style: COText.body.copyWith(color: COColors.brand300),
          ),

        if (info.zoneNearbyInfrastructures.isNotEmpty) ...[
          const SizedBox(height: COTokens.space6),
          _lista(
            titulo: 'Na zona',
            itens: [
              for (final nome in info.zoneNearbyInfrastructures)
                (nome: nome, meta: null),
            ],
          ),
        ],

        if (info.zoneNearbyLocations.isNotEmpty) ...[
          const SizedBox(height: COTokens.space6),
          _lista(
            titulo: 'De automóvel',
            itens: [
              for (final l in info.zoneNearbyLocations)
                (nome: l.name, meta: l.time),
            ],
            nota: 'Tempos indicativos de automóvel.',
          ),
        ],
      ],
    );
  }

  Widget _lista({
    required String titulo,
    required List<({String nome, String? meta})> itens,
    String? nota,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoOverline(titulo, espacoAbaixo: COTokens.space2),
        for (var i = 0; i < itens.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              // Risco entre linhas, menos no fim da lista.
              border: i == itens.length - 1
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: COColors.brand700,
                        width: COTokens.borderWidth,
                      ),
                    ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(itens[i].nome, style: COText.small)),
                if (itens[i].meta != null) ...[
                  const SizedBox(width: COTokens.space4),
                  Text(
                    itens[i].meta!,
                    style: COText.caption.copyWith(color: COColors.brand300),
                  ),
                ],
              ],
            ),
          ),
        if (nota != null) ...[
          const SizedBox(height: COTokens.space2),
          Text(nota, style: COText.caption),
        ],
      ],
    );
  }
}
