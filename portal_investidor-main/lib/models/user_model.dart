class ConstructionStep {
  final int id;
  final int stepOrder;
  final String name;
  final String description;

  ConstructionStep({
    required this.id,
    required this.stepOrder,
    required this.name,
    required this.description,
  });

  factory ConstructionStep.fromJson(Map<String, dynamic> json) {
    return ConstructionStep(
      id: json['id'] ?? 0,
      stepOrder: json['stepOrder'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class ConstructionItem {
  final int id;
  final String title;
  final String location;
  final int currentStepId;
  final List<ConstructionStep> steps;
  final String imageUrl;
  final String? dataFim;

  ConstructionItem({
    required this.id,
    required this.title,
    required this.location,
    required this.currentStepId,
    required this.steps,
    required this.imageUrl,
    this.dataFim,
  });

  ConstructionStep? get currentStepObject {
    try {
      return steps.firstWhere((step) => step.id == currentStepId);
    } catch (_) {
      return null;
    }
  }

  int get currentStepIndex {
    final step = currentStepObject;
    if (step == null) return 0;
    return steps.indexWhere((s) => s.id == step.id);
  }

  bool isStepCompleted(int index) {
    final currentStep = currentStepObject;
    if (currentStep == null) return false;
    return steps[index].stepOrder < currentStep.stepOrder;
  }

  bool isCurrentStep(int index) {
    return steps[index].id == currentStepId;
  }

  factory ConstructionItem.fromJson(Map<String, dynamic> json) {
    final stepsList = json['steps'] as List? ?? [];
    final steps = stepsList.map((s) => ConstructionStep.fromJson(s as Map<String, dynamic>)).toList();

    return ConstructionItem(
      id: json['id'] ?? 0,
      title: json['name']?.toString() ?? 'Título não informado',
      location: json['city']?.toString() ?? 'Localização não informada',
      currentStepId: json['currentStepId'] ?? 0,
      steps: steps,
      imageUrl: json['mainImageUrl']?.toString() ?? '',
      dataFim: json['endDate']?.toString(),
    );
  }
}

class FaturaItem {
  final String title;
  final String status;
  final double valor;

  FaturaItem({required this.title, required this.status, required this.valor});
}

class UserModel {
  final String name;
  final double totalInvestido;
  final double roiEsperado;
  final List<ConstructionItem> obras;
  final List<FaturaItem> faturas;

  UserModel({
    required this.name,
    required this.totalInvestido,
    required this.roiEsperado,
    required this.obras,
    required this.faturas,
  });
}

// ============================================================
// Modelos para o endpoint GET /api/project/details?projectId=id
// ============================================================

/// Corresponde a uma linha de "projectInfo" devolvida pelo backend.
class ProjectInfo {
  final String name;
  final int? nFractions;
  final String address;
  final String city;
  final String status;
  final int? currentStepId;
  final String description;
  final String? startDate;
  final String? endDate;
  final String? mainImageUrl;

  ProjectInfo({
    required this.name,
    this.nFractions,
    required this.address,
    required this.city,
    required this.status,
    this.currentStepId,
    required this.description,
    this.startDate,
    this.endDate,
    this.mainImageUrl,
  });

  factory ProjectInfo.fromJson(Map<String, dynamic> json) {
    return ProjectInfo(
      name: json['name']?.toString() ?? 'Projeto sem título',
      nFractions: int.tryParse(json['nFractions']?.toString() ?? ''),
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Desconhecido',
      currentStepId: int.tryParse(json['currentStepId']?.toString() ?? ''),
      description: json['description']?.toString() ?? 'Nenhuma descrição disponível.',
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      mainImageUrl: json['mainImageUrl']?.toString(),
    );
  }
}

/// Corresponde a uma linha de "projectSteps" devolvida pelo backend.
/// Atenção: o backend usa a chave "stepId" (não "id") neste endpoint.
class ProjectStepDetail {
  final int stepId;
  final int stepOrder;
  final String name;
  final String description;
  final String? imageUrl;

  ProjectStepDetail({
    required this.stepId,
    required this.stepOrder,
    required this.name,
    required this.description,
    this.imageUrl,
  });

  factory ProjectStepDetail.fromJson(Map<String, dynamic> json) {
    return ProjectStepDetail(
      stepId: int.tryParse(json['stepId']?.toString() ?? '') ?? 0,
      stepOrder: int.tryParse(json['stepOrder']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

/// Corresponde a uma linha de "projectImages" devolvida pelo backend.
class ProjectImage {
  final int imageId;
  final String imageUrl;
  final String? imageDescription;

  ProjectImage({
    required this.imageId,
    required this.imageUrl,
    this.imageDescription,
  });

  factory ProjectImage.fromJson(Map<String, dynamic> json) {
    return ProjectImage(
      imageId: int.tryParse(json['imageId']?.toString() ?? '') ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      imageDescription: json['imageDescription']?.toString(),
    );
  }
}

/// Agrega a resposta completa de GET /api/project/details
class ProjectDetailModel {
  final ProjectInfo info;
  final List<ProjectStepDetail> steps;
  final List<ProjectImage> images;

  ProjectDetailModel({
    required this.info,
    required this.steps,
    required this.images,
  });

  factory ProjectDetailModel.fromJson(Map<String, dynamic> json) {
    // "data" -> { projectInfo: [...], projectSteps: [...], projectImages: [...] }
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    final projectInfoList = data['projectInfo'] is List ? data['projectInfo'] as List : [];
    final infoJson = projectInfoList.isNotEmpty && projectInfoList[0] is Map
        ? projectInfoList[0] as Map<String, dynamic>
        : <String, dynamic>{};

    final stepsList = data['projectSteps'] is List ? data['projectSteps'] as List : [];
    final imagesList = data['projectImages'] is List ? data['projectImages'] as List : [];

    return ProjectDetailModel(
      info: ProjectInfo.fromJson(infoJson),
      steps: stepsList
          .whereType<Map>()
          .map((s) => ProjectStepDetail.fromJson(s as Map<String, dynamic>))
          .toList(),
      images: imagesList
          .whereType<Map>()
          .map((i) => ProjectImage.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Lista de URLs de imagem da galeria (filtra entradas vazias)
  List<String> get galeria => images
      .map((i) => i.imageUrl)
      .where((url) => url.isNotEmpty)
      .toList();
}
