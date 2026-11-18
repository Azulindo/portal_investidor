import 'package:flutter_test/flutter_test.dart';
import 'package:portal_investidor/utils/contacto.dart';

/// Os textos do pedido de fatura e o endereco do formulario do Odoo.
///
/// Portado do lib/contacto.ts e do FormularioOdoo.tsx do site. Os nomes dos
/// campos (name, contact_name, email_from, description) sao do Odoo: se
/// mudarem la, o formulario abre em branco e ninguem repara — daí estarem
/// fixados aqui.
void main() {
  group('Assunto', () {
    test('junta fatura, cliente e empreendimento por tracos', () {
      expect(
        Contacto.assuntoDeFatura(
          fatura: 'INV/2026/0002',
          cliente: 'Guilherme Gonçalves',
          empreendimento: 'Aires Ornelas',
        ),
        'Pedido de fatura INV/2026/0002-Guilherme Gonçalves-Aires Ornelas',
      );
    });

    test('o que falta desaparece, em vez de deixar tracos soltos', () {
      expect(
        Contacto.assuntoDeFatura(fatura: 'INV/1', empreendimento: '  '),
        'Pedido de fatura INV/1',
      );
      expect(
        Contacto.assuntoDeFatura(fatura: 'INV/1', cliente: 'Ana'),
        'Pedido de fatura INV/1-Ana',
      );
    });

    test('sem fatura nao ha assunto', () {
      // Sem o numero nao ha pedido que se identifique: o formulario abre
      // como abria, em branco.
      expect(Contacto.assuntoDeFatura(cliente: 'Ana'), '');
      expect(Contacto.assuntoDeFatura(fatura: '   '), '');
    });
  });

  group('Mensagem', () {
    test('diz o que se pede e repete o empreendimento por escrito', () {
      // Por escrito porque o campo "Empreendimento" do Odoo e um <select> e
      // esses o Odoo nao pre-preenche.
      final m = Contacto.mensagemDeFatura(
        fatura: 'INV/2026/0002',
        empreendimento: 'Aires Ornelas',
      );
      expect(m, contains('INV/2026/0002'));
      expect(m, contains('(empreendimento Aires Ornelas)'));
      expect(m, contains('não está disponível para download'));
    });

    test('sem empreendimento nao deixa parenteses vazios', () {
      final m = Contacto.mensagemDeFatura(fatura: 'INV/1');
      expect(m, contains('fatura INV/1.'));
      expect(m, isNot(contains('(')));
    });

    test('sem fatura nao ha mensagem', () {
      expect(Contacto.mensagemDeFatura(empreendimento: 'X'), '');
    });
  });

  group('O endereco do formulario', () {
    test('sem nada para preencher, e o endereco pelado', () {
      final u = Contacto.url();
      expect(u.toString(), 'https://odoo.cleveroption.pt/contactus');
      expect(u.queryParameters, isEmpty);
    });

    test('usa os nomes dos campos do Odoo', () {
      final u = Contacto.url(
        assunto: 'Assunto',
        nome: 'Ana',
        email: 'ana@exemplo.pt',
        mensagem: 'Olá',
      );
      expect(u.queryParameters['name'], 'Assunto');
      expect(u.queryParameters['contact_name'], 'Ana');
      expect(u.queryParameters['email_from'], 'ana@exemplo.pt');
      expect(u.queryParameters['description'], 'Olá');
    });

    test('campos vazios nao viajam no endereco', () {
      final u = Contacto.url(assunto: 'A', nome: '   ', email: '');
      expect(u.queryParameters.keys, ['name']);
    });

    test('o pedido de fatura junta tudo o que se sabe', () {
      final u = Contacto.pedidoDeFatura(
        fatura: 'INV/1',
        empreendimento: 'Aires Ornelas',
        cliente: 'Ana',
        email: 'ana@exemplo.pt',
      );
      expect(u.queryParameters['name'], 'Pedido de fatura INV/1-Ana-Aires Ornelas');
      expect(u.queryParameters['contact_name'], 'Ana');
      expect(u.queryParameters['email_from'], 'ana@exemplo.pt');
      expect(u.queryParameters['description'], contains('INV/1'));
    });

    test('sem fatura, o pedido ainda leva quem esta ligado', () {
      // O assunto e a mensagem ficam vazios e nao viajam; o nome e o email
      // vao na mesma, para a pessoa nao ter de os escrever outra vez.
      final u = Contacto.pedidoDeFatura(cliente: 'Ana', email: 'a@b.pt');
      expect(u.queryParameters.containsKey('name'), isFalse);
      expect(u.queryParameters['contact_name'], 'Ana');
    });
  });
}
