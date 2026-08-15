import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/sown_dashboard_model.dart';

class CropHealthCardWidget extends StatelessWidget {
  final CropHealthInfoModel health;

  const CropHealthCardWidget({
    super.key,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final statusText = _getLocalizedHealthStatus(context, health.statusDisplay, health.status);
    final descText = _getLocalizedHealthDescription(context, health.description);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.cropHealth,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _getStatusColor(health.status),
                    ),
                  ),
                ),
                const SizedBox(height: 3),

                Text(
                  descText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Leaf graphic background
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                '🍃',
                style: TextStyle(fontSize: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedHealthStatus(BuildContext context, String rawStatus, String statusId) {
    final l10n = AppLocalizations.of(context);
    final sid = statusId.toLowerCase();
    final raw = rawStatus.toLowerCase();

    if (sid.contains('good') || raw.contains('good')) {
      if (l10n.languageCode == 'mr') return 'उत्तम';
      if (l10n.languageCode == 'hi') return 'उत्कृष्ट';
      return 'Good';
    } else if (sid.contains('monitor') || raw.contains('monitor')) {
      if (l10n.languageCode == 'mr') return 'लक्ष ठेवा';
      if (l10n.languageCode == 'hi') return 'निगरानी रखें';
      return 'Monitor';
    } else if (sid.contains('attention') || raw.contains('attention')) {
      if (l10n.languageCode == 'mr') return 'लक्ष देणे गरजेचे';
      if (l10n.languageCode == 'hi') return 'ध्यान दें';
      return 'Needs Attention';
    } else if (sid.contains('poor') || raw.contains('poor')) {
      if (l10n.languageCode == 'mr') return 'कमकुवत';
      if (l10n.languageCode == 'hi') return 'खराब';
      return 'Poor';
    } else if (sid.contains('unavail') || raw.contains('unavail')) {
      if (l10n.languageCode == 'mr') return 'उपलब्ध नाही';
      if (l10n.languageCode == 'hi') return 'अनुपलब्ध';
      return 'Unavailable';
    }
    return rawStatus;
  }

  String _getLocalizedHealthDescription(BuildContext context, String rawDesc) {
    final l10n = AppLocalizations.of(context);
    final raw = rawDesc.toLowerCase();

    if (raw.contains('growing normally') || raw.contains('normal') || raw.contains('good')) {
      if (l10n.languageCode == 'mr') return 'तुमचे पीक उत्तम प्रकारे वाढत आहे';
      if (l10n.languageCode == 'hi') return 'आपकी फसल सामान्य रूप से बढ़ रही है';
      return 'Your crop is growing normally';
    } else if (raw.contains('moderate') || raw.contains('monitor')) {
      if (l10n.languageCode == 'mr') return 'उपग्रह चित्र मध्यम वाढ दर्शवते';
      if (l10n.languageCode == 'hi') return 'उपग्रह इमेजरी मध्यम विकास दर्शाती है';
      return 'Satellite imagery indicates moderate growth';
    } else if (raw.contains('low') || raw.contains('poor')) {
      if (l10n.languageCode == 'mr') return 'उपग्रह चित्र कमी वाढ दर्शवते';
      if (l10n.languageCode == 'hi') return 'उपग्रह इमेजरी कम विकास दर्शाती है';
      return 'Satellite imagery indicates low biomass';
    } else if (raw.contains('no recent') || raw.contains('unavail')) {
      if (l10n.languageCode == 'mr') return 'नवीन उपग्रह चित्र उपलब्ध नाही';
      if (l10n.languageCode == 'hi') return 'कोई नवीन उपग्रह चित्र उपलब्ध नहीं है';
      return 'No recent clear satellite imagery available';
    }
    return rawDesc;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'good':
        return const Color(0xFF15803D); // Green
      case 'monitor':
        return const Color(0xFFD97706); // Amber
      case 'needs_attention':
        return const Color(0xFFC2410C); // Orange
      case 'poor':
        return const Color(0xFFDC2626); // Red
      default:
        return const Color(0xFF64748B); // Slate
    }
  }
}
