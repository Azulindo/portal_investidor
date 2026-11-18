import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/co_colors.dart';

/// Fotografia vinda da internet, guardada em disco depois da primeira vez.
///
/// Com [Image.network] a mesma fotografia era descarregada de novo sempre que
/// se voltava a um ecra: entrar num empreendimento, recuar e entrar outra vez
/// pagava tres vezes a mesma imagem. Para quem esta a ver a app na rua, pelos
/// dados moveis, e a diferenca entre esperar e nao esperar.
///
/// Substitui [Image.network] em toda a app. Os nomes seguem os do widget
/// original, so que [erro] e [aCarregar] recebem o widget ja feito em vez de
/// uma funcao.
class CoImagem extends StatelessWidget {
  const CoImagem(
    this.url, {
    super.key,
    this.largura,
    this.altura,
    this.fit = BoxFit.cover,
    this.erro,
    this.aCarregar,
  });

  final String url;
  final double? largura;
  final double? altura;
  final BoxFit fit;

  /// O que aparece quando a imagem nao carrega. Sem nada, fica um fundo liso.
  final Widget? erro;

  /// O que aparece enquanto a imagem desce. Sem nada, fica o mesmo fundo liso,
  /// que ja marca o espaco e evita o salto quando a fotografia entra.
  final Widget? aCarregar;

  Widget _fundo() =>
      Container(width: largura, height: altura, color: COColors.brand700);

  @override
  Widget build(BuildContext context) {
    // Uma morada vazia nunca chega a ser um pedido: vale o mesmo que falhar.
    if (url.isEmpty) return erro ?? _fundo();

    return CachedNetworkImage(
      imageUrl: url,
      width: largura,
      height: altura,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => aCarregar ?? _fundo(),
      errorWidget: (_, _, _) => erro ?? _fundo(),
    );
  }
}
