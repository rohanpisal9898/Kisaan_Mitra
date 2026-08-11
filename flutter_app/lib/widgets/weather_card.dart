import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sown_dashboard_model.dart';

class WeatherCardWidget extends StatelessWidget {
  final WeatherInfoModel weather;

  const WeatherCardWidget({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5FF), // Light blue background matching reference UI
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Weather icon & Temperature & Condition
          Row(
            children: [
              const Text(
                '☀️',
                style: TextStyle(fontSize: 36),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${weather.temperature.round()}°',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    weather.condition,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  Text(
                    'Feels like ${weather.feelsLike.round()}°',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Divider
          Container(
            height: 48,
            width: 1,
            color: const Color(0xFFCBD5E1),
          ),

          // Middle: Rain forecast
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💧', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '${weather.rainNext24hMm.round()}mm',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                weather.rainDescription,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          // Divider
          Container(
            height: 48,
            width: 1,
            color: const Color(0xFFCBD5E1),
          ),

          // Right: Wind speed
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💨', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '${weather.windKmh.round()} km/h',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Wind',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
