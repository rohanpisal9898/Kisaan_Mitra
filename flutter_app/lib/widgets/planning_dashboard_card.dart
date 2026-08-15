import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';

class PlanningDashboardCardWidget extends StatelessWidget {
  final String dashboardState; // "no_crop" or "crop_matured"
  final String? previousCropName;
  final VoidCallback? onPlanCropTap;

  const PlanningDashboardCardWidget({
    super.key,
    required this.dashboardState,
    this.previousCropName,
    this.onPlanCropTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMatured = dashboardState == "crop_matured";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFEFCE8), Color(0xFFF0FDF4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFEF08A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15803D).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    isMatured ? '🌾' : '🌱',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMatured ? l10n.cropCycleComplete : l10n.noCropSownYet,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: const Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 3,
                      width: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            isMatured
                ? '${previousCropName ?? l10n.farmerRole}: ${l10n.planNextSeason}'
                : l10n.planNextSeason,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),

          Text(
            l10n.planningDescription,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
