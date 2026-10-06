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
  // Número do "stepOrder" do passo atual deste projeto (NÃO é o id de um
  // step). Antes chamava-se "currentStepId" e era comparado a "step.id";
  // agora compara-se a "step.stepOrder".
  final int currentStep;
  final List<ConstructionStep> steps;
  final String imageUrl;
  final String? dataFim;
  final String status;
  final int? nFractions;
  /// Tem frações em comercialização.
  final bool forSale;
  /// Onde fica, para o mapa. Vem a 0 quando o projeto não tem morada marcada.
  final double? latitude;
  final double? longitude;
  final String? address;

  ConstructionItem({
    required this.id,
    required this.title,
    required this.location,
    required this.currentStep,
    required this.steps,
    required this.imageUrl,
    this.dataFim,
    this.status = '',
    this.nFractions,
    this.forSale = false,
    this.latitude,
    this.longitude,
    this.address,
  });

  /// Dá para marcar no mapa. A API manda 0/0 quando não há coordenadas.
  bool get temCoordenadas =>
      latitude != null &&
      longitude != null &&
      (latitude != 0 || longitude != 0);

  /// Ano de conclusão, que é como a data se mostra.
  String? get anoFim {
    if (dataFim == null) return null;
    final m = RegExp(r'\d{4}').firstMatch(dataFim!);
    return m?.group(0) ?? dataFim;
  }

  ConstructionStep? get currentStepObject {
    try {
      return steps.firstWhere((step) => step.stepOrder == currentStep);
    } catch (_) {
      return null;
    }
  }

  int get currentStepIndex {
    final index = steps.indexWhere((s) => s.stepOrder == currentStep);
    return index == -1 ? 0 : index;
  }

  bool isStepCompleted(int index) {
    return steps[index].stepOrder < currentStep;
  }

  bool isCurrentStep(int index) {
    return steps[index].stepOrder == currentStep;
  }

  factory ConstructionItem.fromJson(Map<String, dynamic> json) {
    final stepsList = json['steps'] as List? ?? [];
    final steps = stepsList.map((s) => ConstructionStep.fromJson(s as Map<String, dynamic>)).toList();

    return ConstructionItem(
      id: json['id'] ?? 0,
      title: json['name']?.toString() ?? 'Título não informado',
      location: json['city']?.toString() ?? 'Localização não informada',
      currentStep: json['currentStep'] ?? 0,
      steps: steps,
      imageUrl: json['mainImageUrl']?.toString() ?? '',
      dataFim: json['endDate']?.toString(),
      status: json['status']?.toString() ?? '',
      nFractions: int.tryParse(json['nFractions']?.toString() ?? ''),
      forSale: json['forSale'] == true,
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      address: json['address']?.toString(),
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
  // Número do "stepOrder" do passo atual deste projeto (NÃO é o id de um step).
  final int? currentStep;
  final String description;
  final String? startDate;
  final String? endDate;
  final String? mainImageUrl;
  final bool forSale;
  // Onde fica, para o mapa.
  final double? latitude;
  final double? longitude;
  // Imagem que acompanha o texto do conceito, separada da imagem de capa.
  final String? descriptionImageUrl;
  final String? videoUrl;
  // Secção "O lugar": a envolvente do empreendimento.
  final String? zoneTitle;
  final String? zoneDescription;
  /// Ex.: "Escolas", "Centro de saúde" — o que existe na zona.
  final List<String> zoneNearbyInfrastructures;
  /// Ex.: { name: "Porto (centro)", time: "25–30 min" }.
  final List<ZoneLocation> zoneNearbyLocations;

  ProjectInfo({
    required this.name,
    this.nFractions,
    required this.address,
    required this.city,
    required this.status,
    this.currentStep,
    required this.description,
    this.startDate,
    this.endDate,
    this.mainImageUrl,
    this.forSale = false,
    this.latitude,
    this.longitude,
    this.descriptionImageUrl,
    this.videoUrl,
    this.zoneTitle,
    this.zoneDescription,
    this.zoneNearbyInfrastructures = const [],
    this.zoneNearbyLocations = const [],
  });

  /// Ano de conclusão, que é como a data aparece em todo o lado.
  String? get anoFim {
    if (endDate == null) return null;
    final m = RegExp(r'\d{4}').firstMatch(endDate!);
    return m?.group(0) ?? endDate;
  }

  factory ProjectInfo.fromJson(Map<String, dynamic> json) {
    return ProjectInfo(
      name: json['name']?.toString() ?? 'Projeto sem título',
      nFractions: int.tryParse(json['nFractions']?.toString() ?? ''),
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Desconhecido',
      currentStep: int.tryParse(json['currentStep']?.toString() ?? ''),
      description: json['description']?.toString() ?? 'Nenhuma descrição disponível.',
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      mainImageUrl: json['mainImageUrl']?.toString(),
      forSale: json['forSale'] == true,
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      descriptionImageUrl: json['descriptionImageUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      zoneTitle: json['zoneTitle']?.toString(),
      zoneDescription: json['zoneDescription']?.toString(),
      zoneNearbyInfrastructures: (json['zoneNearbyInfrastructures'] as List? ?? [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      zoneNearbyLocations: (json['zoneNearbyLocations'] as List? ?? [])
          .whereType<Map>()
          .map((e) => ZoneLocation.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}

/// Um destino e o tempo que demora a chegar lá de carro.
class ZoneLocation {
  final String name;
  final String time;

  ZoneLocation({required this.name, required this.time});

  factory ZoneLocation.fromJson(Map<String, dynamic> json) => ZoneLocation(
        name: json['name']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
      );
}

/// Corresponde a uma linha de "projectSteps" devolvida pelo backend.
/// Standardizado em "id" (antes era "stepId"), para corresponder ao mesmo
/// formato usado em /user/:id e /project/portfolio.
class ProjectStepDetail {
  final int id;
  final int stepOrder;
  final String name;
  final String description;
  final String? imageUrl;

  ProjectStepDetail({
    required this.id,
    required this.stepOrder,
    required this.name,
    required this.description,
    this.imageUrl,
  });

  factory ProjectStepDetail.fromJson(Map<String, dynamic> json) {
    return ProjectStepDetail(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      stepOrder: int.tryParse(json['stepOrder']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

/// Corresponde a uma linha de "projectImages" devolvida pelo backend.
///
/// A categoria separa as três galerias: exterior, interior e obra. A de obra
/// é o acompanhamento da construção — antes as fotos da obra vinham dos passos
/// da timeline, mas passaram a ter categoria própria.
class ProjectImage {
  final int imageId;
  final String imageUrl;
  final String? imageDescription;
  /// "interior" | "exterior" | "obra". Sem valor, trata-se como exterior.
  final String category;
  /// Imagens inativas não devem ser apresentadas.
  final bool active;
  /// Ordem definida no backoffice.
  final int sortOrder;

  ProjectImage({
    required this.imageId,
    required this.imageUrl,
    this.imageDescription,
    this.category = 'exterior',
    this.active = true,
    this.sortOrder = 0,
  });

  bool get eDeObra => category == 'obra';

  factory ProjectImage.fromJson(Map<String, dynamic> json) {
    return ProjectImage(
      imageId: int.tryParse(json['imageId']?.toString() ?? '') ?? 0,
      imageUrl: json['imageUrl']?.toString() ?? '',
      imageDescription: json['imageDescription']?.toString(),
      category: json['category']?.toString() ?? 'exterior',
      // Ausente conta como ativa: só se esconde o que vier explicitamente a false.
      active: json['active'] != false,
      sortOrder: int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
    );
  }
}

/// Uma fração do empreendimento ("projectFractions").
class ProjectFraction {
  final int fractionId;
  final int projectId;
  final String fractionNumber;
  final String type;
  final double totalArea;
  final double? garageArea;
  final double? balconyArea;
  /// null num pedido anónimo — o preço só vem para quem tem sessão. Nesse caso
  /// mostra-se "Registe-se para ver" em vez de um valor.
  final double? price;
  /// "Disponível" | "Reservado" | "Vendido".
  final String status;
  /// Número do edifício; null quando o empreendimento só tem um.
  final int? block;
  /// Texto e não número: há pisos não numéricos (ex.: "Vale").
  final String? floor;
  final String? orientation;
  /// Planta da fração em PDF.
  final String? floorPlanUrl;

  ProjectFraction({
    required this.fractionId,
    required this.projectId,
    required this.fractionNumber,
    required this.type,
    required this.totalArea,
    this.garageArea,
    this.balconyArea,
    this.price,
    required this.status,
    this.block,
    this.floor,
    this.orientation,
    this.floorPlanUrl,
  });

  bool get disponivel => status.toLowerCase().startsWith('dispon');

  factory ProjectFraction.fromJson(Map<String, dynamic> json) {
    return ProjectFraction(
      fractionId: int.tryParse(json['fractionId']?.toString() ?? '') ?? 0,
      projectId: int.tryParse(json['projectId']?.toString() ?? '') ?? 0,
      fractionNumber: json['fractionNumber']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      totalArea: double.tryParse(json['totalArea']?.toString() ?? '') ?? 0,
      garageArea: double.tryParse(json['garageArea']?.toString() ?? ''),
      balconyArea: double.tryParse(json['balconyArea']?.toString() ?? ''),
      price: double.tryParse(json['price']?.toString() ?? ''),
      status: json['status']?.toString() ?? '',
      block: int.tryParse(json['block']?.toString() ?? ''),
      floor: json['floor']?.toString(),
      orientation: json['orientation']?.toString(),
      floorPlanUrl: json['floorPlanUrl']?.toString(),
    );
  }
}

/// Uma categoria do mapa de acabamentos (ex.: "Instalações sanitárias"), já
/// agrupada pela API.
class ProjectFinish {
  final int finishId;
  final int categoryId;
  final String categoryName;
  final String? imageUrl;
  final List<String> details;

  ProjectFinish({
    required this.finishId,
    required this.categoryId,
    required this.categoryName,
    this.imageUrl,
    this.details = const [],
  });

  factory ProjectFinish.fromJson(Map<String, dynamic> json) {
    return ProjectFinish(
      finishId: int.tryParse(json['finishId']?.toString() ?? '') ?? 0,
      categoryId: int.tryParse(json['categoryId']?.toString() ?? '') ?? 0,
      categoryName: json['categoryName']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      details: (json['details'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}

/// Agrega a resposta completa de GET /api/project/details
class ProjectDetailModel {
  final ProjectInfo info;
  final List<ProjectStepDetail> steps;
  final List<ProjectImage> images;
  final List<ProjectFraction> fractions;
  final List<ProjectFinish> finishes;

  ProjectDetailModel({
    required this.info,
    required this.steps,
    required this.images,
    this.fractions = const [],
    this.finishes = const [],
  });

  factory ProjectDetailModel.fromJson(Map<String, dynamic> json) {
    // "data" -> { projectInfo, projectSteps, projectImages, projectFractions,
    //             projectFinishes }
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;

    final projectInfoList = data['projectInfo'] is List ? data['projectInfo'] as List : [];
    final infoJson = projectInfoList.isNotEmpty && projectInfoList[0] is Map
        ? projectInfoList[0] as Map<String, dynamic>
        : <String, dynamic>{};

    List<T> lista<T>(String chave, T Function(Map<String, dynamic>) de) =>
        (data[chave] is List ? data[chave] as List : [])
            .whereType<Map>()
            .map((e) => de(e.cast<String, dynamic>()))
            .toList();

    return ProjectDetailModel(
      info: ProjectInfo.fromJson(infoJson),
      steps: lista('projectSteps', ProjectStepDetail.fromJson),
      images: lista('projectImages', ProjectImage.fromJson),
      fractions: lista('projectFractions', ProjectFraction.fromJson),
      finishes: lista('projectFinishes', ProjectFinish.fromJson),
    );
  }

  /// Imagens que se podem mostrar, pela ordem definida no backoffice.
  List<ProjectImage> get _visiveis {
    final ativas = images.where((i) => i.active && i.imageUrl.isNotEmpty).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ativas;
  }

  /// A galeria do empreendimento: interiores e exteriores, sem as fotos de obra.
  List<String> get galeria =>
      imagensDaGaleria.map((i) => i.imageUrl).toList();

  /// O acompanhamento da construção.
  List<String> get galeriaDeObra =>
      imagensDeObra.map((i) => i.imageUrl).toList();

  /// As mesmas imagens da [galeria], mas com a categoria e a descrição —
  /// para quem precisa de mostrar a que grupo pertence cada uma.
  List<ProjectImage> get imagensDaGaleria =>
      _visiveis.where((i) => !i.eDeObra).toList();

  List<ProjectImage> get imagensDeObra =>
      _visiveis.where((i) => i.eDeObra).toList();

  /// Só vale a pena identificar a categoria quando existem imagens dos dois
  /// tipos. Com só exteriores, dizer "exterior" em todas não informa nada.
  /// É a mesma decisão que o site toma (separarGaleria).
  bool get galeriaTemInteriorEExterior {
    final cats = imagensDaGaleria.map((i) => i.category).toSet();
    return cats.contains('interior') && cats.contains('exterior');
  }

  List<String> galeriaDe(String categoria) =>
      _visiveis.where((i) => i.category == categoria).map((i) => i.imageUrl).toList();

  /// Quantas frações estão por vender. Devolve null quando a API não trouxe
  /// frações nenhumas, para se distinguir de "nenhuma disponível".
  int? get fracoesDisponiveis =>
      fractions.isEmpty ? null : fractions.where((f) => f.disponivel).length;
}
