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
  final DateTime? sowingDate;
  final String farmLocation;
  final bool isCropSwitch;

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
    this.sowingDate,
    required this.farmLocation,
    this.isCropSwitch = false,
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

    if (widget.isCropSwitch) {
      final cropName = widget.crop;
      final lang = widget.language;
      if (lang == 'hi') {
        _steps.addAll([
          {'label': '$cropName के लिए उपग्रह व मौसम विश्लेषण', 'icon': Icons.satellite_alt},
          {'label': 'फसल वृद्धि चरण व समयरेखा निर्धारण', 'icon': Icons.timeline_rounded},
          {'label': 'मिट्टी की नमी व जल आवश्यकता का आकलन', 'icon': Icons.water_drop_outlined},
          {'label': 'उपज पूर्वानुमान व वित्तीय योजना की तैयारी', 'icon': Icons.account_balance_wallet_outlined},
        ]);
      } else if (lang == 'mr') {
        _steps.addAll([
          {'label': '$cropName साठी उपग्रह व हवामान विश्लेषण', 'icon': Icons.satellite_alt},
          {'label': 'पीक वाढ टप्पा व वेळापत्रक निश्चिती', 'icon': Icons.timeline_rounded},
          {'label': 'मातीतील ओलावा व पाणी गरजेची तपासणी', 'icon': Icons.water_drop_outlined},
          {'label': 'उत्पादन अंदाज व आर्थिक नियोजनाची तयारी', 'icon': Icons.account_balance_wallet_outlined},
        ]);
      } else {
        _steps.addAll([
          {'label': 'Activating satellite & weather models for $cropName', 'icon': Icons.satellite_alt},
          {'label': 'Configuring crop growth stage timeline', 'icon': Icons.timeline_rounded},
          {'label': 'Analyzing soil moisture & water requirements', 'icon': Icons.water_drop_outlined},
          {'label': 'Calibrating yield forecast & financial wallet', 'icon': Icons.account_balance_wallet_outlined},
        ]);
      }
    } else {
      _steps.addAll([
        {'label': _l10n.fetchingWeather, 'icon': Icons.cloud_outlined},
        {'label': _l10n.analyzingSatellite, 'icon': Icons.satellite_alt},
        {'label': _l10n.readingSoil, 'icon': Icons.terrain},
        {'label': _l10n.predictingYield, 'icon': Icons.show_chart},
      ]);
    }

    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    // Run backend operations concurrently while smooth animation runs
    final Future<void> backendTask = _executeBackendTask();

    // Step-by-step progress animation (~2.4 seconds)
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;

      setState(() {
        _currentStep = i;
      });

      for (int j = 0; j < 15; j++) {
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 40));
        setState(() {
          _progress = ((i * 15) + j + 1) / (_steps.length * 15);
        });
      }
    }

    // Ensure backend completes
    await backendTask;

    if (!mounted) return;

    setState(() {
      _completed = true;
      _progress = 1.0;
    });

    // Auto-navigate to dashboard after completion
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          language: widget.language,
          phoneNumber: widget.phoneNumber,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _executeBackendTask() async {
    try {
      if (widget.isCropSwitch) {
        final formattedDate = widget.sowingDate != null
            ? DateFormat('yyyy-MM-dd').format(widget.sowingDate!)
            : DateFormat('yyyy-MM-dd').format(DateTime.now());

        await ApiService.updateUser(widget.phoneNumber, {
          'current_crop': widget.crop,
          'sowing_date': formattedDate,
        });

        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'cached_dashboard_${widget.phoneNumber}_${widget.language}';
        await prefs.remove(cacheKey);
        await prefs.remove('${cacheKey}_timestamp');
      } else {
        // Register user in background
        final isNotSown = widget.crop == 'Not Sown Yet' || widget.crop.trim().isEmpty;
        final cropParam = isNotSown ? '' : widget.crop;
        final sowingDateParam = (isNotSown || widget.sowingDate == null)
            ? null
            : DateFormat('yyyy-MM-dd').format(widget.sowingDate!);

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
          currentCrop: cropParam,
          farmArea: widget.farmArea,
          farmAreaUnit: widget.farmAreaUnit,
          sowingDate: sowingDateParam,
          farmLocation: widget.farmLocation,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_phone', widget.phoneNumber);
        await prefs.setString('language', widget.language);
      }
    } catch (e) {
      debugPrint('Analysis background execution error (non-blocking): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final imageCacheWidth =
        (mediaQuery.size.width * mediaQuery.devicePixelRatio).round();

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

          // Oilseed farm visual kept behind the existing analysis content.
          Positioned.fill(
            child: Opacity(
              opacity: 0.18,
              child: Image.asset(
                'assets/images/oilseed_field.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                cacheWidth: imageCacheWidth,
                filterQuality: FilterQuality.low,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 24),

                          // AI icon
                          Container(
                            width: 72,
                            height: 72,
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
                              size: 36,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Title
                          Text(
                            widget.isCropSwitch
                                ? (widget.language == 'hi'
                                    ? '${widget.crop} सक्रिय हो रहा है'
                                    : widget.language == 'mr'
                                        ? '${widget.crop} सक्रिय होत आहे'
                                        : 'Activating ${widget.crop}')
                                : _l10n.aiAnalyzing,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Subtitle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              widget.isCropSwitch
                                  ? (widget.language == 'hi'
                                      ? 'आपकी व्यक्तिगत कृषि बुद्धिमत्ता और विकास योजना तैयार की जा रही है'
                                      : widget.language == 'mr'
                                          ? 'तुमच्या शेतीसाठी वैयक्तिक सल्ला व नियोजन तयार केले जात आहे'
                                          : 'Setting up your personalized farm intelligence & growth plan')
                                  : _l10n.aiSubtitle,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                                height: 1.4,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Steps list
                          Container(
                            padding: const EdgeInsets.all(20),
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
                                    bottom: index < _steps.length - 1 ? 16 : 0,
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
                                            fontSize: 14,
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
                          const SizedBox(height: 16),

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

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
