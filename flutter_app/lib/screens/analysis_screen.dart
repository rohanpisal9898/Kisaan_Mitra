import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

/// AI Analysis loading screen.
/// Shows animated progress: Fetching Weather → Satellite → Soil → Predicting Yield.
/// Registers the user in the background.
class AnalysisScreen extends StatefulWidget {
  final String language;
  final String farmerName;
  final String phoneNumber;
  final String password;
  final String village;
  final String state;
  final String district;
  final double? latitude;
  final double? longitude;
  final String crop;
  final double farmArea;
  final String farmAreaUnit;
  final DateTime sowingDate;
  final String farmLocation;

  const AnalysisScreen({
    super.key,
    required this.language,
    required this.farmerName,
    required this.phoneNumber,
    this.password = '123456',
    required this.village,
    required this.state,
    required this.district,
    this.latitude,
    this.longitude,
    required this.crop,
    required this.farmArea,
    required this.farmAreaUnit,
    required this.sowingDate,
    required this.farmLocation,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with TickerProviderStateMixin {
  late AppLocalizations _l10n;

  int _currentStep = 0;
  double _progress = 0.0;
  bool _completed = false;

  final List<Map<String, dynamic>> _steps = [];

  @override
  void initState() {
    super.initState();
    _l10n = AppLocalizations(widget.language);

    _steps.addAll([
      {'label': _l10n.fetchingWeather, 'icon': Icons.cloud_outlined},
      {'label': _l10n.analyzingSatellite, 'icon': Icons.satellite_alt},
      {'label': _l10n.readingSoil, 'icon': Icons.terrain},
      {'label': _l10n.predictingYield, 'icon': Icons.show_chart},
    ]);

    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    // Simulate analysis steps with progress
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;

      setState(() {
        _currentStep = i;
      });

      // Animate progress for this step
      for (int j = 0; j < 20; j++) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 80));
        setState(() {
          _progress = ((i * 20) + j + 1) / (_steps.length * 20);
        });
      }
    }

    // Register user in background
    try {
      await ApiService.registerUser(
        phoneNumber: widget.phoneNumber,
        password: widget.password,
        farmerName: widget.farmerName,
        village: widget.village,
        language: widget.language,
        state: widget.state,
        district: widget.district,
        latitude: widget.latitude,
        longitude: widget.longitude,
        currentCrop: widget.crop,
        farmArea: widget.farmArea,
        farmAreaUnit: widget.farmAreaUnit,
        sowingDate: DateFormat('yyyy-MM-dd').format(widget.sowingDate),
        farmLocation: widget.farmLocation,
      );
    } catch (e) {
      // Registration failure is non-blocking for the UI
      debugPrint('Registration error (non-blocking): $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', widget.phoneNumber);
      await prefs.setString('language', widget.language);
    } catch (e) {
      debugPrint('Error saving prefs: $e');
    }

    if (!mounted) return;

    setState(() {
      _completed = true;
    });

    // Auto-navigate to dashboard after completion
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(language: widget.language),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dark gradient background (simulating farm image)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A3A0F),
                  Color(0xFF0D1F08),
                  Color(0xFF060F04),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // AI icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    _l10n.aiAnalyzing,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _l10n.aiSubtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.65),
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Steps list
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: List.generate(_steps.length, (index) {
                        final step = _steps[index];
                        final isActive = index == _currentStep;
                        final isDone = index < _currentStep || _completed;

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < _steps.length - 1 ? 20 : 0,
                          ),
                          child: Row(
                            children: [
                              // Step icon
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? AppColors.primary.withOpacity(0.2)
                                      : isActive
                                          ? AppColors.primary.withOpacity(0.15)
                                          : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: isDone
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.primary,
                                        size: 18,
                                      )
                                    : Icon(
                                        step['icon'] as IconData,
                                        color: isActive
                                            ? AppColors.primary
                                            : Colors.white.withOpacity(0.3),
                                        size: 18,
                                      ),
                              ),
                              const SizedBox(width: 14),

                              // Step label
                              Expanded(
                                child: Text(
                                  step['label'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: isActive || isDone
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isDone
                                        ? Colors.white
                                        : isActive
                                            ? AppColors.primary
                                            : Colors.white.withOpacity(0.4),
                                  ),
                                ),
                              ),

                              // Active indicator
                              if (isActive && !_completed)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),

                  const Spacer(),

                  // Progress bar
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          color: AppColors.primary,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${(_progress * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
