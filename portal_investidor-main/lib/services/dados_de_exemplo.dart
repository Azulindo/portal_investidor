import '../models/sale_order.dart';

/// Os dados que a app mostra com `--dart-define=USE_MOCK=true`.
///
/// Estavam espalhados pelo ApiService e tinham ficado para trás: um projeto
/// só, sem estado, sem cidade, sem frações, sem acabamentos e sem zona. Com
/// eles ligados não se via nada do que a app passou a mostrar — nem os
/// filtros do portfólio, nem o mapa, nem metade do detalhe.
///
/// Duas regras ao mexer aqui:
///
///  1. Os NOMES têm de bater certo entre os três sítios. As encomendas
///     juntam-se aos empreendimentos pelo nome (é o que a API faz), por isso
///     um nome diferente numa lista dá uma carteira a zero.
///  2. Vale a pena manter os casos chatos: um projeto sem coordenadas, uma
///     fração sem varanda, uma fatura não paga, um piso não numérico. São
///     esses que apanham erros antes de a API os mostrar.
class DadosDeExemplo {
  DadosDeExemplo._();

  // Os nomes, num sítio só, para não haver maneira de divergirem.
  static const String aires = 'Aires Ornelas';
  static const String laranjeiras = 'Quinta das Laranjeiras';
  static const String campinho = 'Edifício Campinho';
  static const String luxor = 'The Luxor';
  static const String bonjardim = 'Bonjardim 637';

  static const String _foto1 =
      'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800';
  static const String _foto2 =
      'https://images.unsplash.com/photo-1541881430816-17b8f95c37eb?w=800';
  static const String _foto3 =
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800';

  static List<Map<String, dynamic>> _passos(int quantos) {
    const nomes = [
      ('Projeto e licenciamento', 'Aprovado pela câmara'),
      ('Fundações', 'Executadas'),
      ('Estrutura', 'Em curso'),
      ('Acabamentos', 'Previsto'),
      ('Entrega', 'Previsto'),
    ];
    return [
      for (var i = 0; i < quantos; i++)
        {
          'id': i + 1,
          'stepOrder': i + 1,
          'name': nomes[i].$1,
          'description': nomes[i].$2,
          if (i == 1) 'imageUrl': _foto3,
        },
    ];
  }

  /// GET /project/portfolio
  ///
  /// Cobre os três estados, duas cidades, com e sem comercialização, e um
  /// projeto sem coordenadas (que não deve aparecer no mapa).
  static List<Map<String, dynamic>> portfolio() => [
        {
          'id': 1,
          'name': aires,
          'address': 'Rua Aires de Ornelas 120',
          'city': 'Porto',
          'latitude': 41.1621,
          'longitude': -8.6035,
          'status': 'Em construção',
          'endDate': '2027-09-30',
          'currentStep': 3,
          'mainImageUrl': _foto1,
          'forSale': true,
          'nFractions': 24,
          'steps': _passos(5),
        },
        {
          'id': 2,
          'name': laranjeiras,
          'address': 'Rua das Laranjeiras 8',
          'city': 'Vila Nova de Gaia',
          'latitude': 41.1265,
          'longitude': -8.6113,
          'status': 'Em desenvolvimento',
          'endDate': '2029-06-30',
          'currentStep': 1,
          'mainImageUrl': _foto2,
          'forSale': false,
          'nFractions': 12,
          'steps': _passos(4),
        },
        {
          'id': 3,
          'name': luxor,
          'address': 'Avenida da República 1200',
          'city': 'Vila Nova de Gaia',
          'latitude': 41.1340,
          'longitude': -8.6180,
          'status': 'Em construção',
          'endDate': '2028-12-31',
          'currentStep': 2,
          'mainImageUrl': _foto3,
          'forSale': true,
          'nFractions': 184,
          'steps': _passos(5),
        },
        {
          'id': 4,
          'name': campinho,
          'address': 'Rua do Campinho 40',
          'city': 'Porto',
          'latitude': 41.1456,
          'longitude': -8.6102,
          'status': 'Concluído',
          'endDate': '2024-11-30',
          'currentStep': 5,
          'mainImageUrl': _foto1,
          'forSale': false,
          'nFractions': 8,
          'steps': _passos(5),
        },
        {
          // Sem morada marcada: a API manda 0/0 e isto não deve aparecer no
          // mapa nem rebentar nada.
          'id': 5,
          'name': bonjardim,
          'address': '',
          'city': 'Porto',
          'latitude': 0,
          'longitude': 0,
          'status': 'Concluído',
          'endDate': '2018-05-31',
          'currentStep': 5,
          'mainImageUrl': null,
          'forSale': false,
          'nFractions': 6,
          'steps': _passos(5),
        },
      ];

  /// GET /user/:id — o investidor e as obras em que tem posição.
  ///
  /// O formato é o da resposta verdadeira: data → userData (array de um) e
  /// projects. O mock antigo usava um formato achatado com "obras", que o
  /// código nunca leu — com ele ligado o painel vinha sem nome, sem email e
  /// sem obras nenhumas, e parecia uma conta vazia.
  ///
  /// As obras são as mesmas em que há encomendas, senão a carteira do painel
  /// dava zero frações.
  static Map<String, dynamic> investidor() => {
        'data': {
          'userData': [
            {
              'id': 999,
              'firstName': 'Guilherme',
              'lastName': 'Gonçalves',
              'email': 'guilherme@cleveroption.pt',
            }
          ],
          'totalInvested': '437000.0',
          'projects': [
          {
            'id': 1,
            'name': aires,
            'city': 'Porto',
            'address': 'Rua Aires de Ornelas 120',
            'status': 'Em construção',
            'endDate': '2027-09-30',
            'currentStep': 3,
            'mainImageUrl': _foto1,
            'forSale': true,
            'nFractions': 24,
            'latitude': 41.1621,
            'longitude': -8.6035,
            'steps': _passos(5),
          },
          {
            'id': 2,
            'name': laranjeiras,
            'city': 'Vila Nova de Gaia',
            'address': 'Rua das Laranjeiras 8',
            'status': 'Em desenvolvimento',
            'endDate': '2029-06-30',
            'currentStep': 1,
            'mainImageUrl': _foto2,
            'forSale': false,
            'nFractions': 12,
            'latitude': 41.1265,
            'longitude': -8.6113,
            'steps': _passos(4),
          },
          ],
        },
      };

  /// GET /document/sale-orders
  ///
  /// Uma fatura paga, uma parcial e uma por pagar; duas encomendas no mesmo
  /// empreendimento com a fração "B" repetida, para se confirmar que a
  /// carteira não a conta duas vezes; e uma encomenda ainda sem faturas.
  static List<SaleOrder> encomendas() => [
        SaleOrder(
          id: 1,
          name: 'SO0001',
          projectName: aires,
          fractions: const ['A', 'B'],
          amountTotal: 185000,
          date: '2026-01-15',
          invoices: [
            Invoice(
              id: 11,
              name: 'INV/2026/0001',
              date: '2026-01-20',
              paymentState: 'paid',
              amountTotal: 92500,
              amountResidual: 0,
              attachments: [
                InvoiceAttachment(
                  id: 5,
                  name: 'fatura_0001.pdf',
                  mimetype: 'application/pdf',
                ),
              ],
            ),
            Invoice(
              id: 12,
              name: 'INV/2026/0002',
              date: '2026-04-20',
              paymentState: 'partial',
              amountTotal: 92500,
              amountResidual: 42500,
            ),
          ],
        ),
        SaleOrder(
          id: 2,
          name: 'SO0002',
          projectName: aires,
          fractions: const ['B'],
          amountTotal: 12000,
          date: '2026-02-02',
          invoices: [
            Invoice(
              id: 21,
              name: 'INV/2026/0003',
              date: '2026-02-10',
              paymentState: 'not_paid',
              amountTotal: 12000,
              // Não paga com residual a zero: é o caso que obriga a regra do
              // Invoice.pago a existir.
              amountResidual: 0,
            ),
          ],
        ),
        SaleOrder(
          id: 3,
          name: 'SO0003',
          projectName: laranjeiras,
          fractions: const ['1.ºD'],
          amountTotal: 240000,
          date: '2026-03-01',
          invoices: const [],
        ),
      ];

  /// GET /document/list — as faturas soltas do ecrã "Faturas".
  static List<Map<String, dynamic>> documentos() => [
        {
          'id': 11,
          'name': 'INV/2026/0001',
          'date': '2026-01-20',
          'paymentState': 'paid',
          'amountTotal': '92500.00',
          'attachments': [
            {'id': 5, 'name': 'fatura_0001.pdf', 'mimetype': 'application/pdf'},
          ],
        },
        {
          'id': 12,
          'name': 'INV/2026/0002',
          'date': '2026-04-20',
          'paymentState': 'partial',
          'amountTotal': '92500.00',
          'attachments': [],
        },
        {
          'id': 21,
          'name': 'INV/2026/0003',
          'date': '2026-02-10',
          'paymentState': 'not_paid',
          'amountTotal': '12000.00',
          'attachments': [],
        },
      ];

  /// GET /project/details?projectId=
  ///
  /// O projeto 1 vem completo, para se poder ver todas as secções do detalhe
  /// sem a API. Os outros vêm com o essencial, que também é realista: nem
  /// todos os empreendimentos têm o backoffice todo preenchido.
  static Map<String, dynamic> detalhes(int projectId) {
    final doPortfolio = portfolio().firstWhere(
      (p) => p['id'] == projectId,
      orElse: () => portfolio().first,
    );

    final completo = projectId == 1;

    return {
      'data': {
        'projectInfo': [
          {
            'projectId': doPortfolio['id'],
            'name': doPortfolio['name'],
            'address': doPortfolio['address'],
            'city': doPortfolio['city'],
            'status': doPortfolio['status'],
            'endDate': doPortfolio['endDate'],
            'currentStep': doPortfolio['currentStep'],
            'description':
                'Empreendimento residencial com acabamentos de gama alta, '
                    'a poucos minutos do centro. Tipologias T1 a T3, todas '
                    'com varanda ou terraço, e lugar de garagem incluído.',
            'mainImageUrl': doPortfolio['mainImageUrl'],
            'descriptionImageUrl': _foto2,
            'latitude': doPortfolio['latitude'],
            'longitude': doPortfolio['longitude'],
            'forSale': doPortfolio['forSale'],
            'nFractions': doPortfolio['nFractions'],
            if (completo) ...{
              'videoUrl': 'https://www.youtube.com/watch?v=aqz-KE-bpKQ',
              'zoneTitle': 'Entre o Bonfim e a Baixa',
              'zoneDescription':
                  'Uma zona consolidada, com comércio de rua, escolas e '
                      'transportes a poucos minutos a pé, e com a Baixa do '
                      'Porto a um quarto de hora.',
              'zoneNearbyInfrastructures': [
                'Escola básica e secundária',
                'Mercado do Bolhão',
                'Metro — estação Campo 24 de Agosto',
                'Hospital de Santo António',
                'Parque da Cidade',
              ],
              'zoneNearbyLocations': [
                {'name': 'Baixa do Porto', 'time': '8 min'},
                {'name': 'Aeroporto Francisco Sá Carneiro', 'time': '22 min'},
                {'name': 'Praia de Matosinhos', 'time': '18 min'},
                {'name': 'A1 — acesso', 'time': '6 min'},
              ],
            },
          }
        ],
        'projectSteps': doPortfolio['steps'],
        'projectImages': [
          {
            'imageId': 1,
            'imageUrl': _foto1,
            'imageDescription': 'Fachada principal',
            'category': 'exterior',
            'active': true,
            'sortOrder': 1,
          },
          {
            'imageId': 2,
            'imageUrl': _foto2,
            'imageDescription': 'Sala comum',
            'category': 'interior',
            'active': true,
            'sortOrder': 2,
          },
          {
            'imageId': 3,
            'imageUrl': _foto3,
            'imageDescription': 'Vista do logradouro',
            'category': 'exterior',
            'active': true,
            'sortOrder': 3,
          },
          {
            // Inativa: não deve aparecer em lado nenhum.
            'imageId': 4,
            'imageUrl': _foto1,
            'imageDescription': 'Versão antiga da fachada',
            'category': 'exterior',
            'active': false,
            'sortOrder': 4,
          },
          if (completo) ...[
            {
              'imageId': 5,
              'imageUrl': _foto3,
              'imageDescription': 'Betonagem do 2.º piso',
              'category': 'obra',
              'active': true,
              'sortOrder': 1,
            },
            {
              'imageId': 6,
              'imageUrl': _foto1,
              'imageDescription': 'Montagem da cobertura',
              'category': 'obra',
              'active': true,
              'sortOrder': 2,
            },
          ],
        ],
        'projectFractions': completo ? _fracoes() : [],
        'projectFinishes': completo ? _acabamentos() : [],
      }
    };
  }

  /// Frações com os casos que interessam: pisos numéricos e não numéricos,
  /// uma sem varanda e sem garagem, uma vendida, uma reservada, e uma com
  /// planta em PDF.
  static List<Map<String, dynamic>> _fracoes() => [
        {
          'fractionId': 1,
          'projectId': 1,
          'fractionNumber': 'A',
          'type': 'T1',
          'totalArea': '52.40',
          'garageArea': '14.00',
          'balconyArea': '7.20',
          'price': '185000.00',
          'status': 'Disponível',
          'block': 1,
          'floor': 'R/C',
          'orientation': 'Nascente',
          'floorPlanUrl': 'https://exemplo.pt/plantas/a.pdf',
        },
        {
          'fractionId': 2,
          'projectId': 1,
          'fractionNumber': 'B',
          'type': 'T2',
          'totalArea': '78.10',
          'garageArea': '14.00',
          // Sem varanda: a API manda 0 e o intervalo de áreas tem de o
          // ignorar em vez de mostrar "0–12 m²".
          'balconyArea': '0',
          'price': '245000.00',
          'status': 'Reservado',
          'block': 1,
          'floor': '1',
          'orientation': 'Poente',
        },
        {
          'fractionId': 3,
          'projectId': 1,
          'fractionNumber': 'C',
          'type': 'T2',
          'totalArea': '81.60',
          'garageArea': '14.00',
          'balconyArea': '11.40',
          'price': '262000.00',
          'status': 'Vendido',
          'block': 1,
          'floor': '2',
          'orientation': 'Nascente',
        },
        {
          'fractionId': 4,
          'projectId': 1,
          'fractionNumber': 'D',
          'type': 'T3',
          'totalArea': '112.30',
          'garageArea': '28.00',
          'balconyArea': '22.60',
          'price': '395000.00',
          'status': 'Disponível',
          'block': 2,
          'floor': '3',
          'orientation': 'Sul',
          'floorPlanUrl': 'https://exemplo.pt/plantas/d.pdf',
        },
        {
          // Piso não numérico: por ordem alfabética ia parar ao sítio errado.
          'fractionId': 5,
          'projectId': 1,
          'fractionNumber': 'E',
          'type': 'T1',
          'totalArea': '48.90',
          'garageArea': null,
          'balconyArea': null,
          'price': '162000.00',
          'status': 'Disponível',
          'block': 2,
          'floor': 'Cave',
        },
      ];

  static List<Map<String, dynamic>> _acabamentos() => [
        {
          'finishId': 1,
          'categoryId': 1,
          'categoryName': 'Pavimentos e revestimentos',
          'imageUrl': _foto2,
          'details': [
            'Soalho flutuante de carvalho nas áreas sociais e quartos',
            'Cerâmico retificado de grande formato nas instalações sanitárias',
            'Rodapé lacado a branco com 10 cm',
          ],
        },
        {
          'finishId': 2,
          'categoryId': 2,
          'categoryName': 'Cozinha',
          'details': [
            'Móveis em termolaminado mate com puxador embutido',
            'Bancada em quartzo compacto',
            'Eletrodomésticos encastrados de classe energética A ou superior',
            'Placa de indução e exaustor de teto',
          ],
        },
        {
          'finishId': 3,
          'categoryId': 3,
          'categoryName': 'Instalações sanitárias',
          'details': [
            'Louças suspensas',
            'Torneiras monocomando com arejador',
            'Base de duche extraplana em resina',
          ],
        },
        {
          'finishId': 4,
          'categoryId': 4,
          'categoryName': 'Climatização e energia',
          'details': [
            'Pré-instalação de ar condicionado por condutas',
            'Bomba de calor para águas quentes sanitárias',
            'Painéis solares nas zonas comuns',
          ],
        },
      ];
}
