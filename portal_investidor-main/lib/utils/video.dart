/// Leitura do campo videoUrl de GET /project/details → projectInfo.
///
/// O backoffice aceita o URL do YouTube em qualquer um dos formatos que as
/// pessoas copiam (watch, youtu.be, embed, shorts), por isso é preciso
/// extrair o id. É a mesma lista de formatos do site (youtubeEmbedUrl em
/// lib/testApi.ts), e, como lá, um URL que não se reconheça é tratado como
/// se não houvesse vídeo — não se arrisca mandar a pessoa para um sítio
/// arbitrário.
class Video {
  Video._();

  static final List<RegExp> _formatos = [
    RegExp(r'youtube\.com/watch\?(?:.*&)?v=([\w-]{11})'),
    RegExp(r'youtu\.be/([\w-]{11})'),
    RegExp(r'youtube\.com/embed/([\w-]{11})'),
    RegExp(r'youtube\.com/shorts/([\w-]{11})'),
  ];

  /// O id de 11 caracteres do vídeo, ou null se não se reconhecer o URL.
  static String? idDoYoutube(String? url) {
    final limpo = url?.trim() ?? '';
    if (limpo.isEmpty) return null;

    for (final formato in _formatos) {
      final id = formato.firstMatch(limpo)?.group(1);
      if (id != null) return id;
    }
    return null;
  }

  /// Miniatura do vídeo, para se mostrar sem abrir nada.
  static String miniatura(String id) =>
      'https://img.youtube.com/vi/$id/hqdefault.jpg';

  /// Para onde se manda a pessoa ao tocar. O URL de watch é o que o
  /// telemóvel entrega à app do YouTube quando ela está instalada; o embed
  /// ficaria preso no browser.
  static String paraAbrir(String id) => 'https://www.youtube.com/watch?v=$id';
}
