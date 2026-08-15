class FarmerInfoModel {
  final String name;
  final String village;
  final String district;
  final String state;

  FarmerInfoModel({
    required this.name,
    required this.village,
    required this.district,
    required this.state,
  });

  factory FarmerInfoModel.fromJson(Map<String, dynamic> json) {
    return FarmerInfoModel(
      name: json['name'] ?? 'Ramesh',
      village: json['village'] ?? 'Sonepur',
      district: json['district'] ?? 'Nashik',
      state: json['state'] ?? 'Maharashtra',
    );
  }
}

class CropInfoModel {
  final String id;
  final String name;
  final String sowingDate;

  CropInfoModel({
    required this.id,
    required this.name,
    required this.sowingDate,
  });

  factory CropInfoModel.fromJson(Map<String, dynamic> json) {
    return CropInfoModel(
      id: json['id'] ?? 'soybean',
      name: json['name'] ?? 'Soyabean',
      sowingDate: json['sowing_date'] ?? '',
    );
  }
}

class WeatherInfoModel {
  final double temperature;
  final double feelsLike;
  final String condition;
  final double rainNext24hMm;
  final String rainDescription;
  final double windKmh;
  final bool available;

  WeatherInfoModel({
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.rainNext24hMm,
    required this.rainDescription,
    required this.windKmh,
    required this.available,
  });

  factory WeatherInfoModel.fromJson(Map<String, dynamic> json) {
    return WeatherInfoModel(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 26.0,
      feelsLike: (json['feels_like'] as num?)?.toDouble() ?? 28.0,
      condition: json['condition'] ?? 'Partly Cloudy',
      rainNext24hMm: (json['rain_next_24h_mm'] as num?)?.toDouble() ?? 18.0,
      rainDescription: json['rain_description'] ?? '18 mm rain expected',
      windKmh: (json['wind_kmh'] as num?)?.toDouble() ?? 5.0,
      available: json['available'] ?? true,
    );
  }
}

class CropStageInfoModel {
  final String stageId;
  final String stageName;
  final String stageDisplay;
  final String stageIcon;
  final int stageIndex;
  final String status;
  final int daysAfterSowing;
  final int totalDuration;
  final double progressFraction;

  CropStageInfoModel({
    required this.stageId,
    required this.stageName,
    required this.stageDisplay,
    required this.stageIcon,
    required this.stageIndex,
    required this.status,
    required this.daysAfterSowing,
    required this.totalDuration,
    required this.progressFraction,
  });

  factory CropStageInfoModel.fromJson(Map<String, dynamic> json) {
    return CropStageInfoModel(
      stageId: json['stage_id'] ?? 'flowering',
      stageName: json['stage_name'] ?? json['stage_display'] ?? 'Flowering',
      stageDisplay: json['stage_display'] ?? json['stage_name'] ?? 'Flowering',
      stageIcon: json['stage_icon'] ?? '🌼',
      stageIndex: (json['stage_index'] as num?)?.toInt() ?? 2,
      status: json['status'] ?? 'on_track',
      daysAfterSowing: (json['days_after_sowing'] as num?)?.toInt() ?? 60,
      totalDuration: (json['total_duration'] as num?)?.toInt() ?? 104,
      progressFraction: (json['progress_fraction'] as num?)?.toDouble() ?? 0.57,
    );
  }
}

class WaterStatusInfoModel {
  final String status;
  final String statusDisplay;
  final double irrigationMm;
  final String description;
  final String color;
  final String kcStatus;

  WaterStatusInfoModel({
    required this.status,
    required this.statusDisplay,
    required this.irrigationMm,
    required this.description,
    required this.color,
    required this.kcStatus,
  });

  factory WaterStatusInfoModel.fromJson(Map<String, dynamic> json) {
    return WaterStatusInfoModel(
      status: json['status'] ?? 'rain_sufficient',
      statusDisplay: json['status_display'] ?? 'Rain may cover need',
      irrigationMm: (json['irrigation_mm'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? 'No irrigation needed today',
      color: json['color'] ?? 'blue',
      kcStatus: json['kc_status'] ?? 'established',
    );
  }
}

class CropHealthInfoModel {
  final String status;
  final String statusDisplay;
  final double? score;
  final String description;
  final bool satelliteAvailable;
  final String? satelliteDate;
  final int? satelliteDaysOld;
  final String? cropId;
  final String? stageId;
  final List<String> availableIndices;
  final List<String> missingIndices;
  final Map<String, double> indexScores;

  CropHealthInfoModel({
    required this.status,
    required this.statusDisplay,
    this.score,
    required this.description,
    required this.satelliteAvailable,
    this.satelliteDate,
    this.satelliteDaysOld,
    this.cropId,
    this.stageId,
    this.availableIndices = const [],
    this.missingIndices = const [],
    this.indexScores = const {},
  });

  factory CropHealthInfoModel.fromJson(Map<String, dynamic> json) {
    return CropHealthInfoModel(
      status: json['status'] ?? 'good',
      statusDisplay: json['status_display'] ?? 'Good',
      score: (json['score'] as num?)?.toDouble(),
      description: json['description'] ?? 'Your crop is growing normally',
      satelliteAvailable: json['satellite_available'] ?? true,
      satelliteDate: json['satellite_date'],
      satelliteDaysOld: (json['satellite_days_old'] as num?)?.toInt(),
      cropId: json['crop_id'],
      stageId: json['stage_id'],
      availableIndices: (json['available_indices'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      missingIndices: (json['missing_indices'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      indexScores: (json['index_scores'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ) ??
          const {},
    );
  }
}

class YieldPredictionInfoModel {
  final double predicted;
  final double lower;
  final double upper;
  final String unit;
  final String modelUsed;
  final String confidenceLabel;

  YieldPredictionInfoModel({
    required this.predicted,
    required this.lower,
    required this.upper,
    required this.unit,
    required this.modelUsed,
    required this.confidenceLabel,
  });

  factory YieldPredictionInfoModel.fromJson(Map<String, dynamic> json) {
    return YieldPredictionInfoModel(
      predicted: (json['predicted'] as num?)?.toDouble() ?? 3.4,
      lower: (json['lower'] as num?)?.toDouble() ?? 3.1,
      upper: (json['upper'] as num?)?.toDouble() ?? 3.7,
      unit: json['unit'] ?? 'tonnes_per_hectare',
      modelUsed: json['model_used'] ?? 'satellite',
      confidenceLabel: json['confidence_label'] ?? '90% Confidence Range',
    );
  }
}

class RecommendationItemModel {
  final int priority;
  final String category;
  final String type;
  final String title;
  final String description;
  final String severity;
  final String icon;

  RecommendationItemModel({
    required this.priority,
    required this.category,
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    required this.icon,
  });

  factory RecommendationItemModel.fromJson(Map<String, dynamic> json) {
    return RecommendationItemModel(
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      category: json['category'] ?? json['type'] ?? 'general',
      type: json['type'] ?? 'general',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'medium',
      icon: json['icon'] ?? '💡',
    );
  }
}

class SownDashboardModel {
  final String state;
  final FarmerInfoModel farmer;
  final CropInfoModel crop;
  final WeatherInfoModel weather;
  final CropStageInfoModel cropStage;
  final WaterStatusInfoModel water;
  final CropHealthInfoModel cropHealth;
  final YieldPredictionInfoModel yieldPrediction;
  final List<RecommendationItemModel> recommendations;

  SownDashboardModel({
    required this.state,
    required this.farmer,
    required this.crop,
    required this.weather,
    required this.cropStage,
    required this.water,
    required this.cropHealth,
    required this.yieldPrediction,
    required this.recommendations,
  });

  factory SownDashboardModel.fromJson(Map<String, dynamic> json) {
    var recsJson = json['recommendations'] as List? ?? [];
    List<RecommendationItemModel> recsList =
        recsJson.map((r) => RecommendationItemModel.fromJson(r)).toList();

    return SownDashboardModel(
      state: json['state'] ?? 'sown',
      farmer: FarmerInfoModel.fromJson(json['farmer'] ?? {}),
      crop: CropInfoModel.fromJson(json['crop'] ?? {}),
      weather: WeatherInfoModel.fromJson(json['weather'] ?? {}),
      cropStage: CropStageInfoModel.fromJson(json['crop_stage'] ?? {}),
      water: WaterStatusInfoModel.fromJson(json['water'] ?? {}),
      cropHealth: CropHealthInfoModel.fromJson(json['crop_health'] ?? {}),
      yieldPrediction: YieldPredictionInfoModel.fromJson(json['yield_prediction'] ?? {}),
      recommendations: recsList,
    );
  }
}

class PreviousCropInfoModel {
  final String name;
  final String sowingDate;
  final String status;

  PreviousCropInfoModel({
    required this.name,
    required this.sowingDate,
    required this.status,
  });

  factory PreviousCropInfoModel.fromJson(Map<String, dynamic> json) {
    return PreviousCropInfoModel(
      name: json['name'] ?? '',
      sowingDate: json['sowing_date'] ?? '',
      status: json['status'] ?? 'mature',
    );
  }
}

class DashboardOverviewModel {
  final String dashboardState; // "no_crop", "crop_matured", "growing"
  final FarmerInfoModel farmer;
  final WeatherInfoModel weather;
  final PreviousCropInfoModel? previousCrop;
  final SownDashboardModel? sownDashboard;
  final List<dynamic> topRecommendationsJson;

  DashboardOverviewModel({
    required this.dashboardState,
    required this.farmer,
    required this.weather,
    this.previousCrop,
    this.sownDashboard,
    required this.topRecommendationsJson,
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    final dState = json['dashboard_state'] ?? (json['state'] == 'sown' ? 'growing' : 'no_crop');

    SownDashboardModel? sown;
    if (dState == 'growing' || json.containsKey('crop_stage')) {
      sown = SownDashboardModel.fromJson(json);
    }

    PreviousCropInfoModel? prev;
    if (json['previous_crop'] != null) {
      prev = PreviousCropInfoModel.fromJson(json['previous_crop']);
    }

    return DashboardOverviewModel(
      dashboardState: dState,
      farmer: FarmerInfoModel.fromJson(json['farmer'] ?? {}),
      weather: WeatherInfoModel.fromJson(json['weather'] ?? {}),
      previousCrop: prev,
      sownDashboard: sown,
      topRecommendationsJson: json['top_recommendations'] as List? ?? [],
    );
  }
}
