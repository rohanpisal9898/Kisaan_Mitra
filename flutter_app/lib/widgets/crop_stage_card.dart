import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sown_dashboard_model.dart';

class CropStageCardWidget extends StatelessWidget {
  final CropStageInfoModel cropStage;

  const CropStageCardWidget({
    super.key,
    required this.cropStage,
  });

  @override
  Widget build(BuildContext context) {
    // 4 farmer-facing stages
    final stages = [
      {'key': 'initial', 'label': 'Sowing'},
      {'key': 'development', 'label': 'Veg.'},
      {'key': 'mid_season', 'label': 'Flowering'},
      {'key': 'late_season', 'label': 'Maturity'},
    ];

    int activeIndex = cropStage.stageIndex;
    if (activeIndex < 0) activeIndex = 0;
    if (activeIndex >= stages.length) activeIndex = stages.length - 1;

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Crop Stage',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cropStage.stageDisplay,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF15803D), // Green text for stage name
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'On track',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

              // Flower illustration / Stage icon
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
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Horizontal 4-Stage Progress Bar
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background progress line
                      Container(
                        height: 3,
                        width: double.infinity,
                        color: const Color(0xFFE2E8F0),
                      ),

                      // Filled progress line up to active stage
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: activeIndex / (stages.length - 1),
                        child: Container(
                          height: 3,
                          color: const Color(0xFF16A34A),
                        ),
                      ),

                      // 4 Nodes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(stages.length, (index) {
                          bool isCompleted = index <= activeIndex;
                          bool isCurrent = index == activeIndex;

                          return Container(
                            width: isCurrent ? 14 : 10,
                            height: isCurrent ? 14 : 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFCBD5E1),
                              border: isCurrent
                                  ? Border.all(
                                      color: const Color(0xFFDCFCE7),
                                      width: 3,
                                    )
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stage labels under nodes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(stages.length, (index) {
                      bool isCurrent = index == activeIndex;
                      return Text(
                        stages[index]['label']!,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent
                              ? const Color(0xFF15803D)
                              : const Color(0xFF94A3B8),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
