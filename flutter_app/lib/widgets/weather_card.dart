import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/sown_dashboard_model.dart';

class WeatherCardWidget extends StatelessWidget {
  final WeatherInfoModel weather;

  const WeatherCardWidget({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final conditionText = _getLocalizedCondition(context, weather.condition);
    final rainDescText = _getLocalizedRainDescription(context, weather.rainNext24hMm, weather.rainDescription);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5FF), // Light blue background matching reference UI
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Weather icon & Temperature & Condition
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const Text(
                  '☀️',
                  style: TextStyle(fontSize: 34),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${weather.temperature.round()}°',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Text(
                        conditionText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${l10n.feelsLike} ${weather.feelsLike.round()}°',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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

          // Vertical Divider
          Container(
            height: 44,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: const Color(0xFFCBD5E1),
          ),

          // Middle: Rain forecast
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('💧', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${weather.rainNext24hMm.round()} mm',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  rainDescText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Vertical Divider
          Container(
            height: 44,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: const Color(0xFFCBD5E1),
          ),

          // Right: Wind speed
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('💨', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${weather.windKmh.round()} km/h',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.wind,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
    );
  }

  String _getLocalizedCondition(BuildContext context, String rawCondition) {
    final l10n = AppLocalizations.of(context);
    final raw = rawCondition.toLowerCase();

    if (raw.contains('light rain')) {
      if (l10n.languageCode == 'mr') return 'हलका पाऊस';
      if (l10n.languageCode == 'hi') return 'हल्की बारिश';
      return 'Light Rain';
    } else if (raw.contains('partly cloudy')) {
      if (l10n.languageCode == 'mr') return 'अंशतः ढगाळ';
      if (l10n.languageCode == 'hi') return 'आंशिक रूप से बादल';
      return 'Partly Cloudy';
    } else if (raw.contains('overcast') || raw.contains('cloudy')) {
      if (l10n.languageCode == 'mr') return 'ढगाळ हवामान';
      if (l10n.languageCode == 'hi') return 'बादल छाए हैं';
      return 'Cloudy';
    } else if (raw.contains('clear') || raw.contains('sunny')) {
      if (l10n.languageCode == 'mr') return 'निरभ्र हवामान';
      if (l10n.languageCode == 'hi') return 'साफ मौसम';
      return 'Clear';
    } else if (raw.contains('rain')) {
      if (l10n.languageCode == 'mr') return 'पाऊस';
      if (l10n.languageCode == 'hi') return 'बारिश';
      return 'Rain';
    }
    return rawCondition;
  }

  String _getLocalizedRainDescription(BuildContext context, double rainMm, String rawDesc) {
    final l10n = AppLocalizations.of(context);
    final val = rainMm.round();

    if (val <= 0) {
      if (l10n.languageCode == 'mr') return 'पावसाची शक्यता नाही';
      if (l10n.languageCode == 'hi') return 'बारिश की संभावना नहीं';
      return 'No rain expected';
    }

    if (l10n.languageCode == 'mr') {
      return '$val मिमी पावसाची शक्यता';
    } else if (l10n.languageCode == 'hi') {
      return '$val मिमी बारिश की संभावना';
    }
    return '$val mm rain expected';
  }
}
