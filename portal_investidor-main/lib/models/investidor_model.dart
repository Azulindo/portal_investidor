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
    this.roiEsperado,          // <-- opcional
    required this.createdAt,
    required this.obras,
    required this.faturas,
  });

  factory InvestidorModel.fromJson(Map<String, dynamic> json) {
  // A resposta vem com "data" -> "userData" (array) e "projects" (array)
  final data = json['data'] ?? json; // se a raiz já for data
  final userData = (data['userData'] as List?)?.first ?? {};
  final projects = data['projects'] as List? ?? [];

  return InvestidorModel(
    id: userData['id'] ?? 0,
    name: '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim(),
    email: userData['email'] ?? '',
    totalInvested: 0.0,   // se não vier, podes definir 0 ou calcular a partir dos projetos? Por agora 0
    roiEsperado: null,    // se não vier
    createdAt: DateTime.now(),
    obras: projects.map((p) => ConstructionItem.fromJson(p)).toList(),
    faturas: [],          // se não vierem ainda
  );
}
}