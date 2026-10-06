import 'package:flutter/material.dart';

import '../screens/portfolio_screen.dart';
import '../screens/project_details_screen.dart';
import '../services/api_service.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/ui_helpers.dart';
import 'co_card.dart';

/// "Outros empreendimentos" no fim do detalhe — o equivalente ao
/// OutrosEmpreendimentos do site.
///
/// Mostra até três, e o resto fica no link para o portfólio. É a mesma
/// decisão do site: isto vive no fim de uma página já longa, e quem quiser
/// ver tudo tem o portfólio a um toque.
///
/// Busca o portfólio por sua conta e sem bloquear o ecrã: é conteúdo do
/// fundo da página, por isso enquanto não chega não se mostra nada, e se a
/// chamada falhar a secção desaparece em silêncio em vez de pôr um erro
/// debaixo do empreendimento que a pessoa está a ver.
class SecaoOutrosEmpreendimentos extends StatefulWidget {
  const SecaoOutrosEmpreendimentos({super.key, required this.projectIdAtual});

  final int projectIdAtual;

  @override
  State<SecaoOutrosEmpreendimentos> createState() =>
      _SecaoOutrosEmpreendimentosState();
}

class _SecaoOutrosEmpreendimentosState
    extends State<SecaoOutrosEmpreendimentos> {
  static const int _maximo = 3;

  late Future<List<dynamic>> _portfolio;

  @override
  void initState() {
    super.initState();
    _portfolio = ApiService().buscarPortfolio();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _portfolio,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final outros = snapshot.data!.where((p) {
          final id = int.tryParse(
            (p is Map ? p['id'] : null)?.toString() ?? '',
          );
          return id != null && id != widget.projectIdAtual;
        }).toList();

        if (outros.isEmpty) return const SizedBox.shrink();

        final aMostrar = outros.take(_maximo).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CoOverline('Portfólio'),
            Text('Outros empreendimentos', style: COText.h2),
            const SizedBox(height: COTokens.space4),

            for (final p in aMostrar) _cartao(p as Map),

            _linkPortfolio(outros.length),
          ],
        );
      },
    );
  }

  Widget _cartao(Map p) {
    final id = int.tryParse(p['id']?.toString() ?? '') ?? 0;
    final nome = p['name']?.toString() ?? 'Projeto sem título';
    final cidade = p['city']?.toString() ?? '';
    final estado = p['status']?.toString() ?? '';
    final imagem = p['mainImageUrl']?.toString() ?? '';

    // Tag única por cartão, com o id do empreendimento atual pelo meio: o
    // mesmo projeto pode aparecer nesta secção em vários detalhes, e duas
    // Hero com a mesma tag no mesmo ecrã dão erro.
    final heroTag = 'hero-outros-${widget.projectIdAtual}-$id';

    return CoCard(
      semPadding: true,
      margin: const EdgeInsets.only(bottom: COTokens.space4),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDetailsScreen(
            projectId: id,
            heroTag: heroTag,
            initialImageUrl: imagem,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 150,
                child: Hero(
                  tag: heroTag,
                  child: Material(
                    type: MaterialType.transparency,
                    child: imagem.isEmpty
                        ? _semImagem()
                        : Image.network(
                            imagem,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _semImagem(),
                          ),
                  ),
                ),
              ),
              if (estado.isNotEmpty)
                Positioned(
                  top: COTokens.space2,
                  left: COTokens.space2,
                  child: UIHelpers.buildStatusBadge(estado),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(COTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cidade.isNotEmpty) ...[
                  Text(cidade.toUpperCase(), style: COText.overline),
                  const SizedBox(height: 4),
                ],
                Text(
                  nome,
                  style: COText.body.copyWith(fontWeight: COTokens.fwBold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _semImagem() {
    return const ColoredBox(
      color: COColors.brand700,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: COColors.neutral500,
          size: 32,
        ),
      ),
    );
  }

  Widget _linkPortfolio(int total) {
    final texto = total > _maximo
        ? 'Ver portfólio completo ($total)'
        : 'Ver portfólio completo';

    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PortfolioScreen()),
        ),
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        child: Text(
          '$texto  →',
          style: COText.small.copyWith(
            color: COColors.brand300,
            fontWeight: COTokens.fwMedium,
          ),
        ),
      ),
    );
  }
}
