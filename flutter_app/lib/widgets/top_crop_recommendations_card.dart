import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';

class TopCropRecommendationModel {
  final int rank;
  final String crop;
  final String cropId;
  final String icon;
  final int score;
  final String suitabilityPercentage;
  final String netReturnFormatted;
  final String waterLevel;
  final String waterRequirementFormatted;
  final String recommendedSowing;

  TopCropRecommendationModel({
    required this.rank,
    required this.crop,
    required this.cropId,
    required this.icon,
    required this.score,
    required this.suitabilityPercentage,
    required this.netReturnFormatted,
    required this.waterLevel,
    required this.waterRequirementFormatted,
    required this.recommendedSowing,
  });

  factory TopCropRecommendationModel.fromJson(Map<String, dynamic> json) {
    final reqM3 = json['water_requirement'] ?? json['farm_water_requirement_m3'];
    final reqFormatted = json['water_requirement_formatted'] ??
        (reqM3 != null ? '$reqM3 m³' : (json['water_level'] ?? 'Medium'));

    return TopCropRecommendationModel(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      crop: json['crop'] ?? 'Soybean',
      cropId: json['crop_id'] ?? 'soybean',
      icon: json['icon'] ?? '🌱',
      score: (json['score'] as num?)?.toInt() ?? 91,
      suitabilityPercentage: json['suitability_percentage'] ?? '${json['score'] ?? 91}% Suitable',
      netReturnFormatted: json['net_return_formatted'] ?? 'Rs. 11,324/ha',
      waterLevel: json['water_level'] ?? 'Medium',
      waterRequirementFormatted: reqFormatted,
      recommendedSowing: json['recommended_sowing'] ?? 'June – July',
    );
  }
}

class TopCropRecommendationsCardWidget extends StatelessWidget {
  final List<TopCropRecommendationModel> recommendations;
  final Function(TopCropRecommendationModel)? onCropSelected;

  const TopCropRecommendationsCardWidget({
    super.key,
    required this.recommendations,
    this.onCropSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    final rank1 = recommendations.isNotEmpty ? recommendations[0] : null;
    final rank2 = recommendations.length > 1 ? recommendations[1] : null;
    final rank3 = recommendations.length > 2 ? recommendations[2] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Row(
          children: [
            const Text('⭐', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.topCropRecommendations,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Rank #1 Large Hero Card
        if (rank1 != null) ...[
          _buildRank1Card(context, l10n, rank1),
          const SizedBox(height: 14),
        ],

        // Rank #2 and #3 Side-by-Side Grid Row
        if (rank2 != null || rank3 != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rank2 != null)
                Expanded(child: _buildGridRankCard(context, l10n, rank2)),
              if (rank2 != null && rank3 != null)
                const SizedBox(width: 10),
              if (rank3 != null)
                Expanded(child: _buildGridRankCard(context, l10n, rank3)),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Personalization Footer Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('💡', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.personalizedRecsInfo,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.rankingFactors,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRank1Card(BuildContext context, AppLocalizations l10n, TopCropRecommendationModel item) {
    return GestureDetector(
      onTap: () => onCropSelected?.call(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF15803D).withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Row: Rank badge, Icon, Crop Name, Suitability Pill
            Row(
              children: [
                // Rank Circle
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF86EFAC),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${item.rank}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF14532D),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(item.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.crop,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                // Suitability Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${item.score}% ${l10n.suitable}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Inner Details Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // Net Return
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFF15803D),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('₹', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item.netReturnFormatted,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Text(
                                l10n.netReturn,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),
                  const SizedBox(width: 6),

                  // Water Req
                  Expanded(
                    child: Row(
                      children: [
                        const Text('💧', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item.waterRequirementFormatted,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Text(
                                l10n.waterReq,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 20, width: 1, color: const Color(0xFFE2E8F0)),
                  const SizedBox(width: 6),

                  // Sowing
                  Expanded(
                    child: Row(
                      children: [
                        const Text('📅', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item.recommendedSowing,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              Text(
                                l10n.recommendedSowing,
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  color: const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridRankCard(BuildContext context, AppLocalizations l10n, TopCropRecommendationModel item) {
    return GestureDetector(
      onTap: () => onCropSelected?.call(item),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Rank circle, Icon, Name
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${item.rank}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(item.icon, style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.crop,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${item.score}% ${l10n.suitable}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF15803D),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Details Container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.netReturnFormatted,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Text(
                              l10n.netReturn,
                              style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('💧', style: TextStyle(fontSize: 10)),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      item.waterRequirementFormatted,
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              l10n.waterReq,
                              style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('📅', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.recommendedSowing,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Text(
                              l10n.recommendedSowing,
                              style: GoogleFonts.inter(fontSize: 8, color: const Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
