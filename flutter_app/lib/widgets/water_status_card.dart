import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/sown_dashboard_model.dart';

class WaterStatusCardWidget extends StatelessWidget {
  final WaterStatusInfoModel water;

  const WaterStatusCardWidget({
    super.key,
    required this.water,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final neededText = _getLocalizedNeededText(context, water.irrigationMm);
    final statusText = _getLocalizedWaterStatus(context, water.statusDisplay, water.status);
    final descText = _getLocalizedWaterDescription(context, water.description);

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
              const Text('💧', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l10n.waterStatus,
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
                        statusText,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        neededText,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Water Drop Graphic
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '💧',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getLocalizedWaterStatus(BuildContext context, String rawStatus, String statusId) {
    final l10n = AppLocalizations.of(context);
    final sid = statusId.toLowerCase();
    final raw = rawStatus.toLowerCase();

    if (sid.contains('rain') || raw.contains('rain')) {
      if (l10n.languageCode == 'mr') return 'पाऊस गरज भागवू शकतो';
      if (l10n.languageCode == 'hi') return 'बारिश आवश्यकता पूरी कर सकती है';
      return 'Rain may cover need';
    } else if (sid.contains('need') || sid.contains('irrigation') || raw.contains('need')) {
      if (l10n.languageCode == 'mr') return 'सिंचनाची गरज आहे';
      if (l10n.languageCode == 'hi') return 'सिंचाई की आवश्यकता है';
      return 'Needs irrigation';
    } else if (sid.contains('good') || raw.contains('good')) {
      if (l10n.languageCode == 'mr') return 'पाण्याची स्थिती उत्तम';
      if (l10n.languageCode == 'hi') return 'जल स्थिति अच्छी है';
      return 'Good';
    }
    return rawStatus;
  }

  String _getLocalizedNeededText(BuildContext context, double irrigationMm) {
    final l10n = AppLocalizations.of(context);
    final val = irrigationMm.round();

    if (l10n.languageCode == 'mr') {
      return '~$val मिमी आवश्यक';
    } else if (l10n.languageCode == 'hi') {
      return '~$val मिमी आवश्यक';
    }
    return '~$val mm needed';
  }

  String _getLocalizedWaterDescription(BuildContext context, String rawDesc) {
    final l10n = AppLocalizations.of(context);
    final raw = rawDesc.toLowerCase();

    if (raw.contains('no irrigation') || raw.contains('sufficient')) {
      if (l10n.languageCode == 'mr') return 'आज सिंचनाची गरज नाही';
      if (l10n.languageCode == 'hi') return 'आज सिंचाई की आवश्यकता नहीं है';
      return 'No irrigation needed today';
    }
    return rawDesc;
  }
}
