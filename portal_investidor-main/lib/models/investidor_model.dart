import 'user_model.dart'; // Importa as Faturas e Obras

class InvestidorModel {
  final int id;
  final String name;
  final String email;
  final double totalInvested;
  final double? roiEsperado;
  final DateTime createdAt;
  final List<ConstructionItem> obras;
  final List<dynamic> faturas;

  InvestidorModel({
    required this.id,
    required this.name,
    required this.email,
    required this.totalInvested,
    this.roiEsperado,
    required this.createdAt,
    required this.obras,
    required this.faturas,
  });

  /// Lê a resposta de GET /user/:id — data → userData (array de um) e
  /// projects.
  ///
  /// Esta é a ÚNICA leitura desta resposta: o ApiService chamava-a para os
  /// dados de exemplo e fazia a sua própria para a API, e as duas tinham
  /// divergido. O resultado era que em modo mock o painel vinha sem nome,
  /// sem email e sem obras, e parecia uma conta vazia.
  ///
  /// [idDeRecurso] é o id a usar quando a resposta não traz nenhum — na
  /// prática o id com que se fez o pedido.
  factory InvestidorModel.fromJson(
    Map<String, dynamic> json, {
    int idDeRecurso = 0,
  }) {
    // Aceita tanto o envelope completo como já só o "data".
    final data = (json['data'] as Map<String, dynamic>?) ?? json;

    final userDataList = data['userData'] as List? ?? [];
    final userData = userDataList.isNotEmpty
        ? (userDataList.first as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    final obras = <ConstructionItem>[];
    for (final p in (data['projects'] as List? ?? [])) {
      try {
        obras.add(ConstructionItem.fromJson((p as Map).cast<String, dynamic>()));
      } catch (_) {
        // Um projeto malformado não deve levar o painel inteiro atrás.
      }
    }

    return InvestidorModel(
      id: int.tryParse(userData['id']?.toString() ?? '') ?? idDeRecurso,
      name: '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim(),
      email: userData['email']?.toString() ?? '',
      // Soma dos totais das encomendas do cliente. Estava fixo a 0.0 e por
      // isso o painel mostrava sempre zero, apesar de a API mandar o valor.
      totalInvested:
          double.tryParse(data['totalInvested']?.toString() ?? '') ?? 0.0,
      roiEsperado: null,
      createdAt: DateTime.now(),
      obras: obras,
      faturas: const [],
    );
  }
}
