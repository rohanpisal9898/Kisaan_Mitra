class ExpenseItemModel {
  final String id;
  final String category;
  final String label;
  double amount;
  final bool isCustom;

  ExpenseItemModel({
    required this.id,
    required this.category,
    required this.label,
    required this.amount,
    this.isCustom = false,
  });

  factory ExpenseItemModel.fromJson(Map<String, dynamic> json) {
    return ExpenseItemModel(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      label: json['label'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isCustom: json['is_custom'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'label': label,
      'amount': amount,
      'is_custom': isCustom,
    };
  }
}

class MspInfoModel {
  final String crop;
  final String commodity;
  final String season;
  final String marketingYear;
  final double mspPrice;
  final String unit;
  final String source;
  final String? effectiveFrom;
  final String? effectiveTo;
  final bool available;
  final String? message;

  MspInfoModel({
    required this.crop,
    required this.commodity,
    required this.season,
    required this.marketingYear,
    required this.mspPrice,
    required this.unit,
    required this.source,
    this.effectiveFrom,
    this.effectiveTo,
    required this.available,
    this.message,
  });

  factory MspInfoModel.fromJson(Map<String, dynamic> json) {
    return MspInfoModel(
      crop: json['crop'] ?? '',
      commodity: json['commodity'] ?? '',
      season: json['season'] ?? 'Kharif',
      marketingYear: json['marketing_year'] ?? '2024-25',
      mspPrice: (json['msp_price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'Rs/Quintal',
      source: json['source'] ?? 'Government of India (CACP / DES)',
      effectiveFrom: json['effective_from'],
      effectiveTo: json['effective_to'],
      available: json['available'] ?? true,
      message: json['message'],
    );
  }
}

class MarketItemModel {
  final String? cropId;
  final String cropName;
  final double unitPrice;
  final double minPrice;
  final double maxPrice;
  final String unit;
  final String marketStatus;
  final String marketName;
  final bool isFarmerCrop;
  final double? mspPrice;
  final double? marketVsMsp;
  final String? marketVsMspLabel;

  MarketItemModel({
    this.cropId,
    required this.cropName,
    required this.unitPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.unit,
    required this.marketStatus,
    required this.marketName,
    this.isFarmerCrop = false,
    this.mspPrice,
    this.marketVsMsp,
    this.marketVsMspLabel,
  });

  factory MarketItemModel.fromJson(Map<String, dynamic> json) {
    return MarketItemModel(
      cropId: json['crop_id'],
      cropName: json['crop_name'] ?? '',
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      minPrice: (json['min_price'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (json['max_price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'Rs/Quintal',
      marketStatus: json['market_status'] ?? 'Moderate Market',
      marketName: json['market_name'] ?? 'Local Mandi',
      isFarmerCrop: json['is_farmer_crop'] ?? false,
      mspPrice: (json['msp_price'] as num?)?.toDouble(),
      marketVsMsp: (json['market_vs_msp'] as num?)?.toDouble(),
      marketVsMspLabel: json['market_vs_msp_label'],
    );
  }
}

class MarketInsightModel {
  final String title;
  final String content;
  final bool available;
  final String? generatedAt;
  final String dataSource;
  final bool isUpdating;
  final int cooldownSecondsRemaining;

  MarketInsightModel({
    required this.title,
    required this.content,
    this.available = true,
    this.generatedAt,
    this.dataSource = 'MongoDB Atlas & Gemini Intelligence',
    this.isUpdating = false,
    this.cooldownSecondsRemaining = 0,
  });

  factory MarketInsightModel.fromJson(Map<String, dynamic> json) {
    return MarketInsightModel(
      title: json['title'] ?? '🌱 Market Insight',
      content: json['content'] ?? '',
      available: json['available'] ?? true,
      generatedAt: json['generated_at'],
      dataSource: json['data_source'] ?? 'MongoDB Atlas & Gemini Intelligence',
      isUpdating: json['is_updating'] ?? false,
      cooldownSecondsRemaining: (json['cooldown_seconds_remaining'] as num?)?.toInt() ?? 0,
    );
  }
}

class SellingPriceInfoModel {
  final double modalPrice;
  final double floorPrice;
  final double ceilingPrice;
  final String unit;
  final String marketName;
  final bool available;
  final String? message;
  final String dataSource;

  SellingPriceInfoModel({
    required this.modalPrice,
    required this.floorPrice,
    required this.ceilingPrice,
    required this.unit,
    required this.marketName,
    required this.available,
    this.message,
    this.dataSource = 'MongoDB Atlas mandi_prices',
  });

  factory SellingPriceInfoModel.fromJson(Map<String, dynamic> json) {
    return SellingPriceInfoModel(
      modalPrice: (json['modal_price'] as num?)?.toDouble() ?? 0.0,
      floorPrice: (json['floor_price'] as num?)?.toDouble() ?? 0.0,
      ceilingPrice: (json['ceiling_price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'Rs/Quintal',
      marketName: json['market_name'] ?? 'Local Mandi',
      available: json['available'] ?? true,
      message: json['message'],
      dataSource: json['data_source'] ?? 'MongoDB Atlas mandi_prices',
    );
  }
}

class YieldSummaryModel {
  final double predicted;
  final double lower;
  final double upper;
  final String unit;
  final String modelUsed;
  final String confidenceLabel;
  final bool available;

  YieldSummaryModel({
    required this.predicted,
    required this.lower,
    required this.upper,
    required this.unit,
    required this.modelUsed,
    required this.confidenceLabel,
    required this.available,
  });

  factory YieldSummaryModel.fromJson(Map<String, dynamic> json) {
    return YieldSummaryModel(
      predicted: (json['predicted'] as num?)?.toDouble() ?? 0.0,
      lower: (json['lower'] as num?)?.toDouble() ?? 0.0,
      upper: (json['upper'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'tonnes_per_hectare',
      modelUsed: json['model_used'] ?? 'nosat',
      confidenceLabel: json['confidence_label'] ?? '90% Confidence Range',
      available: json['available'] ?? true,
    );
  }
}

class ProfitSummaryModel {
  final double expectedProfit;
  final double minProfit;
  final double maxProfit;
  final double safePlanningMin;
  final double safePlanningMax;
  final double totalCost;
  final double revenueExpected;
  final double revenueMin;
  final double revenueMax;
  final double sellingPricePerQuintal;
  final double sellingPricePerTonne;
  final double farmAreaHa;
  final double totalYieldTonnes;
  final bool isLoss;
  final String displayTitle;
  final String formattedExpectedProfit;
  final String formattedMinProfit;
  final String formattedMaxProfit;

  ProfitSummaryModel({
    required this.expectedProfit,
    required this.minProfit,
    required this.maxProfit,
    required this.safePlanningMin,
    required this.safePlanningMax,
    required this.totalCost,
    required this.revenueExpected,
    required this.revenueMin,
    required this.revenueMax,
    required this.sellingPricePerQuintal,
    required this.sellingPricePerTonne,
    required this.farmAreaHa,
    required this.totalYieldTonnes,
    required this.isLoss,
    required this.displayTitle,
    required this.formattedExpectedProfit,
    required this.formattedMinProfit,
    required this.formattedMaxProfit,
  });

  factory ProfitSummaryModel.fromJson(Map<String, dynamic> json) {
    return ProfitSummaryModel(
      expectedProfit: (json['expected_profit'] as num?)?.toDouble() ?? 0.0,
      minProfit: (json['min_profit'] as num?)?.toDouble() ?? 0.0,
      maxProfit: (json['max_profit'] as num?)?.toDouble() ?? 0.0,
      safePlanningMin: (json['safe_planning_min'] as num?)?.toDouble() ?? 0.0,
      safePlanningMax: (json['safe_planning_max'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      revenueExpected: (json['revenue_expected'] as num?)?.toDouble() ?? 0.0,
      revenueMin: (json['revenue_min'] as num?)?.toDouble() ?? 0.0,
      revenueMax: (json['revenue_max'] as num?)?.toDouble() ?? 0.0,
      sellingPricePerQuintal: (json['selling_price_per_quintal'] as num?)?.toDouble() ?? 0.0,
      sellingPricePerTonne: (json['selling_price_per_tonne'] as num?)?.toDouble() ?? 0.0,
      farmAreaHa: (json['farm_area_ha'] as num?)?.toDouble() ?? 0.0,
      totalYieldTonnes: (json['total_yield_tonnes'] as num?)?.toDouble() ?? 0.0,
      isLoss: json['is_loss'] ?? false,
      displayTitle: json['display_title'] ?? 'Expected Profit',
      formattedExpectedProfit: json['formatted_expected_profit'] ?? '₹0',
      formattedMinProfit: json['formatted_min_profit'] ?? '₹0',
      formattedMaxProfit: json['formatted_max_profit'] ?? '₹0',
    );
  }
}

class WalletOverviewModel {
  final String farmerName;
  final String village;
  final String district;
  final String state;
  final String? currentCrop;
  final String? currentCropId;
  final double farmArea;
  final String farmAreaUnit;
  final bool hasFarmArea;
  final bool hasCrop;
  final bool hasYieldPrediction;
  final YieldSummaryModel yieldPrediction;
  final SellingPriceInfoModel sellingPrice;
  final MspInfoModel? msp;
  final ProfitSummaryModel profitSummary;
  final List<ExpenseItemModel> expenses;
  final List<MarketItemModel> marketItems;
  final MarketInsightModel? marketInsight;
  final String historicalCostBenchmarkNote;
  final String dataFreshnessNote;

  WalletOverviewModel({
    required this.farmerName,
    required this.village,
    required this.district,
    required this.state,
    this.currentCrop,
    this.currentCropId,
    required this.farmArea,
    required this.farmAreaUnit,
    required this.hasFarmArea,
    required this.hasCrop,
    required this.hasYieldPrediction,
    required this.yieldPrediction,
    required this.sellingPrice,
    this.msp,
    required this.profitSummary,
    required this.expenses,
    required this.marketItems,
    this.marketInsight,
    this.historicalCostBenchmarkNote = 'Historical/estimated cost benchmark from MongoDB crop_costs',
    this.dataFreshnessNote = 'Market & Cost Data: MongoDB Atlas (2024 Benchmark)',
  });

  factory WalletOverviewModel.fromJson(Map<String, dynamic> json) {
    return WalletOverviewModel(
      farmerName: json['farmer_name'] ?? 'Farmer',
      village: json['village'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      currentCrop: json['current_crop'],
      currentCropId: json['current_crop_id'],
      farmArea: (json['farm_area'] as num?)?.toDouble() ?? 0.0,
      farmAreaUnit: json['farm_area_unit'] ?? 'acres',
      hasFarmArea: json['has_farm_area'] ?? true,
      hasCrop: json['has_crop'] ?? true,
      hasYieldPrediction: json['has_yield_prediction'] ?? true,
      yieldPrediction: YieldSummaryModel.fromJson(json['yield_prediction'] ?? {}),
      sellingPrice: SellingPriceInfoModel.fromJson(json['selling_price'] ?? {}),
      msp: json['msp'] != null ? MspInfoModel.fromJson(json['msp']) : null,
      profitSummary: ProfitSummaryModel.fromJson(json['profit_summary'] ?? {}),
      expenses: (json['expenses'] as List<dynamic>?)
              ?.map((e) => ExpenseItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      marketItems: (json['market_items'] as List<dynamic>?)
              ?.map((e) => MarketItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      marketInsight: json['market_insight'] != null
          ? MarketInsightModel.fromJson(json['market_insight'])
          : null,
      historicalCostBenchmarkNote: json['historical_cost_benchmark_note'] ??
          'Historical/estimated cost benchmark from MongoDB crop_costs',
      dataFreshnessNote: json['data_freshness_note'] ??
          'Market & Cost Data: MongoDB Atlas (2024 Benchmark)',
    );
  }
}
