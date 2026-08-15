import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/sown_dashboard_model.dart';

class CropStageCardWidget extends StatelessWidget {
  final CropStageInfoModel cropStage;

  const CropStageCardWidget({
    super.key,
    required this.cropStage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 4 farmer-facing stages
    final stages = [
      {'key': 'initial', 'label': l10n.stageSowing},
      {'key': 'development', 'label': l10n.stageVeg},
      {'key': 'mid_season', 'label': l10n.stageFlowering},
      {'key': 'late_season', 'label': l10n.stageMaturity},
    ];

    int activeIndex = cropStage.stageIndex;
    if (activeIndex < 0) activeIndex = 0;
    if (activeIndex >= stages.length) activeIndex = stages.length - 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.cropStage,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _getLocalizedStageDisplay(context, cropStage.stageDisplay, cropStage.stageId),
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.onTrack,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Stage icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    cropStage.stageIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Horizontal 4-Stage Progress Bar
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Background progress line
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Filled progress line up to active stage
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: activeIndex / (stages.length - 1),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // 4 Nodes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(stages.length, (index) {
                      bool isCompleted = index <= activeIndex;
                      bool isCurrent = index == activeIndex;

                      return Container(
                        width: isCurrent ? 12 : 9,
                        height: isCurrent ? 12 : 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFCBD5E1),
                          border: isCurrent
                              ? Border.all(
                                  color: const Color(0xFFDCFCE7),
                                  width: 2.5,
                                )
                              : null,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Stage labels under nodes
              Row(
                children: List.generate(stages.length, (index) {
                  bool isCurrent = index == activeIndex;
                  return Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.0),
                        child: Text(
                          stages[index]['label']!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w600,
                            color: isCurrent
                                ? const Color(0xFF15803D)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLocalizedStageDisplay(BuildContext context, String rawDisplay, String stageId) {
    final l10n = AppLocalizations.of(context);
    final id = stageId.toLowerCase();
    final raw = rawDisplay.toLowerCase();

    if (id.contains('initial') || id.contains('sow') || raw.contains('sow') || raw.contains('initial')) {
      return l10n.stageSowing;
    } else if (id.contains('early') || id.contains('dev') || id.contains('veg') || raw.contains('growth') || raw.contains('early') || raw.contains('veg')) {
      if (l10n.languageCode == 'mr') return 'प्रारंभिक वाढ';
      if (l10n.languageCode == 'hi') return 'प्रारंभिक विकास';
      return 'Early Growth';
    } else if (id.contains('mid') || id.contains('flower') || raw.contains('flower') || raw.contains('bloom')) {
      return l10n.stageFlowering;
    }
    return rawDisplay;
  }
}
