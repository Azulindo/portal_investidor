import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/screens/portfolio_screen.dart';
import 'package:portal_investidor/screens/project_details_screen.dart';
import 'package:portal_investidor/models/notificacao.dart';
import 'package:portal_investidor/utils/destino_notificacao.dart';
import 'package:portal_investidor/utils/id_publico.dart';

void main() {
  // Códigos tirados do site (lib/idPublico.ts, com o pacote sqids do npm).
  // Se isto falhar, o alfabeto ou o tamanho mínimo mudaram num dos lados.
  const doSite = {1: 'peP0Pc', 2: 'TzgvMB', 3: 'RvW0kx', 7: 'ykfxXF', 16: '0rtWXf', 123: 'cCsA9C'};

  test('os códigos são iguais aos do site', () {
    doSite.forEach((id, codigo) {
      expect(IdPublico.codificar(id), codigo);
      expect(IdPublico.descodificar(codigo), id);
    });
  });

  test('código inválido dá null', () {
    expect(IdPublico.descodificar(''), isNull);
    expect(IdPublico.descodificar(null), isNull);
    expect(IdPublico.descodificar('!!!'), isNull);
  });

  group('empreendimento do href', () {
    test('as três formas', () {
      expect(projetoDoHref('/empreendimento?projectId=7'), 7);
      expect(projetoDoHref('/empreendimento?p=ykfxXF'), 7);
      expect(projetoDoHref('/empreendimento/fracao?p=ykfxXF&f=2-M'), 7);
    });

    test('outros caminhos não são empreendimentos', () {
      expect(projetoDoHref('/portal'), isNull);
      expect(projetoDoHref('/em-comercializacao'), isNull);
      expect(projetoDoHref(null), isNull);
    });
  });

  // O caso que falhou no telemóvel: notificação de obra para uma pessoa, sem
  // projectId (a API não o deixa pôr), com o empreendimento só no href.
  test('notificação de obra só com href abre o empreendimento', () {
    expect(
      destinoDaNotificacao(
        tipo: TipoNotificacao.obra,
        href: '/empreendimento?projectId=3',
      ),
      isA<ProjectDetailsScreen>(),
    );
  });

  test('a "está em comercialização" abre o empreendimento, não a lista', () {
    expect(
      destinoDaNotificacao(
        tipo: TipoNotificacao.comercial,
        href: '/empreendimento?projectId=3',
      ),
      isA<ProjectDetailsScreen>(),
    );
    expect(
      destinoDaNotificacao(tipo: TipoNotificacao.geral, href: '/em-comercializacao'),
      isA<PortfolioScreen>(),
    );
  });
}
