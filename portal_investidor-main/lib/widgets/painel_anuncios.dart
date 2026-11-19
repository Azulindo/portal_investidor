import 'package:flutter/material.dart';

import '../models/notificacao.dart';
import '../services/api_service.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/destino_notificacao.dart';
import 'co_imagem.dart';
import 'efeitos.dart';
import 'painel_aquisicao.dart' show Claro;

/// Os anúncios no topo do painel, como os do topo da Área Reservada do site
/// (components/PortalAnuncios.tsx): notificações marcadas como anúncio no
/// backoffice, com a imagem quando a têm.
///
/// Duas formas de tirar um da frente, com efeitos diferentes, iguais às do
/// site:
/// - o ✕ só o esconde até a app voltar a abrir: não o marca como lido;
/// - "Não mostrar mais", depois de confirmado, marca-o como lido — o mesmo que
///   abri-lo no sininho: a API deixa de o devolver.
/// Seguir a ligação do anúncio também não o marca como lido.
class PainelAnuncios extends StatefulWidget {
  const PainelAnuncios({super.key});

  @override
  State<PainelAnuncios> createState() => _PainelAnunciosState();
}

class _PainelAnunciosState extends State<PainelAnuncios> {
  /// Os fechados no ✕ desde que a app abriu — a "visita" do site. Estático
  /// para sobreviver a sair e voltar ao painel; uma app nova volta a mostrá-los.
  static final Set<int> _fechadosNestaSessao = {};

  late final Future<List<Notificacao>> _anuncios = ApiService().buscarAnuncios();
  final Set<int> _escondidos = {};

  void _fechar(int id) {
    _fechadosNestaSessao.add(id);
    setState(() => _escondidos.add(id));
  }

  Future<void> _naoMostrarMais(Notificacao a) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text(
          'Deixar de mostrar este anúncio? Continua disponível nas notificações.',
        ),
        actions: [
          // O "Cancelar" primeiro e com o foco: um toque a mais não pode
          // confirmar sem querer.
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, não mostrar mais'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    setState(() => _escondidos.add(a.id));
    // Se falhar, volta a aparecer da próxima vez — não vale a pena prender o
    // ecrã por isso (o site faz o mesmo).
    ApiService().marcarNotificacaoLida(a.id).catchError((_) {});
  }

  void _abrir(Notificacao a, Widget destino) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => destino));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Notificacao>>(
      future: _anuncios,
      builder: (context, snap) {
        final visiveis = (snap.data ?? const <Notificacao>[])
            .where((a) =>
                !_escondidos.contains(a.id) &&
                !_fechadosNestaSessao.contains(a.id))
            .toList();
        if (visiveis.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [for (final a in visiveis) _cartao(a)],
        );
      },
    );
  }

  Widget _cartao(Notificacao a) {
    final destino = destinoDaNotificacao(
      tipo: a.tipo,
      projectId: a.projectId,
      notificationId: a.id,
      href: a.href,
    );
    final vaiAoEmpreendimento = a.projectId != null ||
        (a.href ?? '').startsWith('/empreendimento');
    final imagem = a.imagemUrl;

    return Revelar(
      child: Container(
        margin: const EdgeInsets.only(bottom: COTokens.space6),
        decoration: BoxDecoration(
          color: COColors.white,
          borderRadius: BorderRadius.circular(4),
          border: const Border(
            left: BorderSide(color: COColors.accent, width: 3),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F002847),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (imagem != null)
                  // Uma imagem que não carrega desaparece: o anúncio fica
                  // como se não a tivesse.
                  CoImagem(
                    imagem,
                    altura: 150,
                    largura: double.infinity,
                    erro: const SizedBox.shrink(),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 40, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ANÚNCIO', style: Claro.miniatura),
                      const SizedBox(height: 4),
                      Text(a.titulo, style: Claro.titulo),
                      if (a.corpo.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          a.corpo,
                          style: Claro.etiqueta.copyWith(
                            fontSize: 14,
                            color: COColors.brand700,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                  child: Row(
                    children: [
                      if (destino != null)
                        TextButton(
                          onPressed: () => _abrir(a, destino),
                          style: TextButton.styleFrom(
                            foregroundColor: COColors.brand900,
                          ),
                          child: Text(
                            vaiAoEmpreendimento
                                ? 'Ver empreendimento →'
                                : 'Saber mais →',
                            style: const TextStyle(
                              fontWeight: COTokens.fwBold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _naoMostrarMais(a),
                        style: TextButton.styleFrom(
                          foregroundColor: COColors.brand500,
                        ),
                        child: const Text(
                          'Não mostrar mais',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                // Sobre a imagem, o ✕ precisa de fundo para se ver.
                color: imagem != null
                    ? const Color(0xCCFFFFFF)
                    : Colors.transparent,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => _fechar(a.id),
                  tooltip: 'Fechar (volta a aparecer da próxima vez)',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: COColors.brand900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
