import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';
import 'co_card.dart';

/// As etapas da obra numa régua horizontal, em vez de uma lista vertical.
///
/// Antes cada etapa era uma linha da página inteira: bolinha, nome,
/// descrição e foto, uma debaixo da outra. Com cinco etapas isso são umas
/// 450px — o utilizador tinha de passar o dedo três ou quatro vezes só
/// para chegar ao fim das fases, e depois ainda lhe faltava o vídeo, as
/// frações e os acabamentos. E das cinco, quatro já não lhe interessavam:
/// o que ele quer saber é em que ponto está a obra dele.
///
/// Agora a régua ocupa uma linha e mostra por baixo só a etapa escolhida,
/// que começa na atual. As outras continuam todas lá, à distância de um
/// toque na bolinha. Dá à volta de 160px em vez de 450px.
class EtapasHorizontais extends StatefulWidget {
  const EtapasHorizontais({
    super.key,
    required this.etapas,
    required this.etapaAtual,
    this.aoTocarNaFoto,
  });

  /// Pela ordem em que vêm da API.
  final List<ProjectStepDetail> etapas;

  /// O `stepOrder` da etapa em curso. Pode não existir na lista — por
  /// exemplo numa obra que ainda não arrancou — e nesse caso não há
  /// nenhuma marcada como atual.
  final int etapaAtual;

  final void Function(String imagemUrl, String legenda)? aoTocarNaFoto;

  @override
  State<EtapasHorizontais> createState() => _EtapasHorizontaisState();
}

class _EtapasHorizontaisState extends State<EtapasHorizontais> {
  /// Qual a etapa a mostrar em baixo. Começa na atual.
  late int _escolhida = _indiceDaAtual;

  int get _indiceDaAtual {
    final i = widget.etapas
        .indexWhere((e) => e.stepOrder == widget.etapaAtual);
    // Sem etapa atual conhecida, mostra a primeira em vez de nada.
    return i == -1 ? 0 : i;
  }

  @override
  void didUpdateWidget(EtapasHorizontais anterior) {
    super.didUpdateWidget(anterior);
    // Se o ecrã recarregar com outra obra, a escolha do utilizador na obra
    // anterior deixa de fazer sentido.
    if (anterior.etapas != widget.etapas ||
        anterior.etapaAtual != widget.etapaAtual) {
      _escolhida = _indiceDaAtual;
    }
    if (_escolhida >= widget.etapas.length) _escolhida = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.etapas.isEmpty) return const SizedBox.shrink();

    final etapa = widget.etapas[_escolhida];
    final temFoto = etapa.imageUrl != null && etapa.imageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CoTitulo('Etapas do desenvolvimento'),
        _regua(),
        const SizedBox(height: COTokens.space4),
        Text(
          'Fase ${_escolhida + 1} de ${widget.etapas.length}',
          style: COText.caption,
        ),
        const SizedBox(height: 2),
        Text(
          etapa.name,
          style: const TextStyle(
            color: COColors.white,
            fontSize: 16,
            fontWeight: COTokens.fwBold,
          ),
        ),
        if (etapa.description.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            etapa.description,
            style: const TextStyle(color: COColors.brand300, fontSize: 14, height: 1.5),
          ),
        ],
        if (temFoto) ...[
          const SizedBox(height: COTokens.space4),
          GestureDetector(
            onTap: () => widget.aoTocarNaFoto?.call(etapa.imageUrl!, etapa.name),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(COTokens.radiusSm),
              child: Image.network(
                etapa.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  height: 160,
                  color: COColors.brand700,
                  child: const Icon(Icons.broken_image,
                      color: COColors.brand300, size: 24),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// A régua. Cada bolinha é um alvo de 44px de altura, que é o mínimo
  /// decente para um dedo, mesmo sendo o ponto desenhado só de 10px.
  Widget _regua() {
    return Row(
      children: List.generate(widget.etapas.length, (i) {
        final etapa = widget.etapas[i];
        final feita = etapa.stepOrder <= widget.etapaAtual;
        final atual = etapa.stepOrder == widget.etapaAtual;
        final escolhida = i == _escolhida;

        final cor = atual
            ? COColors.white
            : (feita ? COColors.brand300 : COColors.brand700);

        return Expanded(
          child: Semantics(
            label: 'Fase ${i + 1}: ${etapa.name}',
            selected: escolhida,
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _escolhida = i),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Expanded(child: _linha(visivel: i > 0, feita: feita)),
                    // O aro marca a que está a ser mostrada em baixo, que
                    // nem sempre é a atual — o utilizador pode ter tocado
                    // noutra.
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: escolhida
                            ? Border.all(color: COColors.brand300, width: 1)
                            : null,
                      ),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _linha(
                        visivel: i < widget.etapas.length - 1,
                        feita: etapa.stepOrder < widget.etapaAtual,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _linha({required bool visivel, required bool feita}) {
    if (!visivel) return const SizedBox();
    return Container(
      height: 1,
      color: feita ? COColors.brand300 : COColors.brand700,
    );
  }
}
