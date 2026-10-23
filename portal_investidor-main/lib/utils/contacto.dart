/// O formulario de contacto do Odoo, com o que der para ja preencher.
///
/// Portado do `lib/contacto.ts` e do `components/FormularioOdoo.tsx` do site.
/// No site o formulario e um iframe; aqui abre-se no browser do telefone, mas
/// o endereco e o mesmo e os nomes dos campos tambem.
class Contacto {
  static const String _origem = 'https://odoo.cleveroption.pt/contactus';

  /// Os campos do Odoo que se conseguem pre-preencher, e o nome que lhes
  /// damos deste lado.
  ///
  /// O Odoo preenche, ao carregar a pagina, qualquer input ou textarea cujo
  /// `name` venha na query string. O campo "Empreendimento" fica de fora: e
  /// um <select>, e esses o Odoo nao toca — e por isso que o empreendimento
  /// vai tambem escrito na mensagem.
  static const Map<String, String> _campos = {
    'assunto': 'name',
    'nome': 'contact_name',
    'email': 'email_from',
    'mensagem': 'description',
  };

  /// O endereco do formulario, com o que houver para pre-preencher.
  static Uri url({
    String? assunto,
    String? nome,
    String? email,
    String? mensagem,
  }) {
    final valores = {
      'assunto': assunto,
      'nome': nome,
      'email': email,
      'mensagem': mensagem,
    };

    final query = <String, String>{};
    for (final entrada in _campos.entries) {
      final valor = valores[entrada.key]?.trim();
      if (valor != null && valor.isNotEmpty) query[entrada.value] = valor;
    }

    final base = Uri.parse(_origem);
    return query.isEmpty ? base : base.replace(queryParameters: query);
  }

  /// O assunto de um pedido de fatura:
  /// `Pedido de fatura <fatura>-<cliente>-<empreendimento>`.
  ///
  /// Sem o numero da fatura nao ha pedido que se identifique, e ai devolve-se
  /// vazio — o formulario abre como abria, em branco.
  static String assuntoDeFatura({
    String? fatura,
    String? cliente,
    String? empreendimento,
  }) {
    final numero = _limpar(fatura);
    if (numero.isEmpty) return '';

    final partes = [numero, _limpar(cliente), _limpar(empreendimento)]
        .where((p) => p.isNotEmpty);
    return 'Pedido de fatura ${partes.join('-')}';
  }

  /// A mensagem. Diz o que se pede e porque, e repete o empreendimento por
  /// escrito: como o campo "Empreendimento" e um <select> que o Odoo nao
  /// preenche, e esta frase que garante que a informacao chega na mesma.
  ///
  /// Nenhuma das partes e garantida — uma fatura pode vir sem nome do Odoo e
  /// o empreendimento pode faltar — por isso o que falta desaparece do texto
  /// em vez de deixar la um "null" ou um traco sozinho.
  static String mensagemDeFatura({
    String? fatura,
    String? empreendimento,
  }) {
    final numero = _limpar(fatura);
    if (numero.isEmpty) return '';

    final obra = _limpar(empreendimento);
    final onde = obra.isEmpty ? '' : ' (empreendimento $obra)';
    return 'Gostaria de requisitar o envio da fatura $numero$onde.\n'
        'O documento não está disponível para download na Área Reservada.';
  }

  /// O formulario pronto a abrir, para quem quer pedir uma fatura que nao
  /// esta disponivel para descarregar.
  ///
  /// Junta tudo o que se sabe: o numero da fatura e o empreendimento vem do
  /// ecra, o nome e o email de quem esta ligado. O que faltar fica de fora
  /// sem estragar o resto.
  static Uri pedidoDeFatura({
    String? fatura,
    String? empreendimento,
    String? cliente,
    String? email,
  }) {
    return url(
      assunto: assuntoDeFatura(
        fatura: fatura,
        cliente: cliente,
        empreendimento: empreendimento,
      ),
      nome: cliente,
      email: email,
      mensagem: mensagemDeFatura(
        fatura: fatura,
        empreendimento: empreendimento,
      ),
    );
  }

  static String _limpar(String? valor) => (valor ?? '').trim();
}
