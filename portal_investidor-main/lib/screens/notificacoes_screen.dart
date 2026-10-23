import 'package:flutter/material.dart';

import '../models/notificacao.dart';
import '../services/api_service.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import '../utils/tempo.dart';
import '../utils/ui_helpers.dart';
import '../widgets/co_card.dart';
import 'project_details_screen.dart';

/// A lista de notificacoes — o que o sininho abre.
///
/// Espelha o painel do sininho do site. Tocar numa marca-a como lida e, se
/// disser respeito a um empreendimento, leva la.
class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  final ApiService _api = ApiService();

  List<Notificacao> _lista = const [];
  int _naoLidas = 0;
  bool _aCarregar = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _aCarregar = true;
      _erro = null;
    });
    try {
      final resposta = await _api.buscarNotificacoes();
      if (!mounted) return;
      setState(() {
        _lista = resposta.notificacoes;
        _naoLidas = resposta.naoLidas;
        _aCarregar = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.message;
        _aCarregar = false;
      });
    }
  }

  /// Marca no ecra primeiro e so depois avisa o servidor.
  ///
  /// Quem toca quer ver a notificacao, nao esperar por um pedido de rede. Se
  /// o pedido falhar, desfaz-se: mais vale o ponto voltar do que a pessoa
  /// julgar que leu uma coisa que o servidor continua a dar por ler.
  Future<void> _marcarLida(Notificacao n) async {
    if (n.lida) return;

    final antes = _lista;
    final naoLidasAntes = _naoLidas;
    setState(() {
      _lista = [
        for (final x in _lista) x.id == n.id ? x.marcadaComoLida() : x,
      ];
      _naoLidas = (_naoLidas - 1).clamp(0, 9999);
    });

    try {
      await _api.marcarNotificacaoLida(n.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _lista = antes;
        _naoLidas = naoLidasAntes;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _marcarTodas() async {
    final antes = _lista;
    final naoLidasAntes = _naoLidas;
    setState(() {
      _lista = [for (final x in _lista) x.marcadaComoLida()];
      _naoLidas = 0;
    });

    try {
      await _api.marcarTodasAsNotificacoesLidas();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _lista = antes;
        _naoLidas = naoLidasAntes;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _abrir(Notificacao n) {
    _marcarLida(n);

    // O href da API e um caminho do site ("/empreendimento?projectId=1") e as
    // rotas da app nao sao essas. O que serve e o projectId.
    final id = n.projectId;
    if (id == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailsScreen(
          projectId: id,
          heroTag: 'notificacao-${n.id}',
          initialImageUrl: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: COColors.brand900,
      appBar: AppBar(
        title: const Text('Notificações', style: COText.tituloEcra),
        backgroundColor: COColors.brand900,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: COColors.white),
        actions: [
          if (_naoLidas > 0)
            TextButton(
              onPressed: _marcarTodas,
              child: Text(
                'Marcar todas',
                style: COText.small.copyWith(color: COColors.brand300),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        color: COColors.brand300,
        backgroundColor: COColors.brand700,
        child: _corpo(),
      ),
    );
  }

  Widget _corpo() {
    if (_aCarregar) {
      return const Center(
        child: CircularProgressIndicator(color: COColors.brand300),
      );
    }

    if (_erro != null) {
      return UIHelpers.buildErrorState(message: _erro!, onRetry: _carregar);
    }

    if (_lista.isEmpty) {
      // Uma lista vazia aqui e boa noticia, nao um erro: nao ha nada novo.
      // Tem de poder deslizar na mesma, senao o puxar para atualizar nao
      // funciona exatamente no ecra em que e mais provavel usarem-no.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              COTokens.space6,
              80,
              COTokens.space6,
              COTokens.space6,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.notifications_none,
                  size: 40,
                  color: COColors.neutral500,
                ),
                const SizedBox(height: COTokens.space4),
                Text(
                  'Sem notificações',
                  style: COText.body.copyWith(color: COColors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Avisamos aqui quando houver novidades nas suas obras ou nos seus documentos.',
                  style: COText.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(COTokens.space4),
      itemCount: _lista.length,
      itemBuilder: (_, i) => _Cartao(
        notificacao: _lista[i],
        aoTocar: () => _abrir(_lista[i]),
      ),
    );
  }
}

class _Cartao extends StatelessWidget {
  const _Cartao({required this.notificacao, required this.aoTocar});

  final Notificacao notificacao;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final n = notificacao;

    return CoCard(
      margin: const EdgeInsets.only(bottom: COTokens.space2),
      onTap: aoTocar,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // O ponto por ler. Ocupa o lugar mesmo quando esta lida, para o
          // texto das duas ficar alinhado e a lista nao ficar aos degraus.
          Padding(
            padding: const EdgeInsets.only(top: 5, right: COTokens.space2),
            child: SizedBox(
              width: 7,
              height: 7,
              child: n.lida
                  ? null
                  : const DecoratedBox(
                      decoration: BoxDecoration(
                        color: COColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      n.tipo.etiqueta.toUpperCase(),
                      style: COText.caption.copyWith(
                        color: COColors.neutral500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Tempo.haQuanto(n.criadaEm),
                      style: COText.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  n.titulo,
                  style: COText.body.copyWith(
                    color: COColors.white,
                    fontWeight: n.lida ? COTokens.fwMedium : COTokens.fwBold,
                  ),
                ),
                if (n.corpo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(n.corpo, style: COText.caption),
                ],
              ],
            ),
          ),
          if (n.projectId != null)
            const Padding(
              padding: EdgeInsets.only(left: COTokens.space2, top: 2),
              child: Icon(
                Icons.chevron_right,
                size: 18,
                color: COColors.neutral500,
              ),
            ),
        ],
      ),
    );
  }
}
