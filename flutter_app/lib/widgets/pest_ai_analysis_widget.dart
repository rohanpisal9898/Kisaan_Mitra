import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Pest Detection Page 2 - AI Analysis Screen.
/// Strictly matches the 2nd phone screen in the reference image ("2. AI Analysis").
/// Uses the actual captured/selected crop photo as dark full-screen background,
/// displays a real percentage circular ring progress indicator, step progress card,
/// and privacy footer while communicating with FastAPI backend.
class PestAiAnalysisWidget extends StatefulWidget {
  final XFile imageFile;
  final String source;
  final VoidCallback onBack;
  final Function(Map<String, dynamic> scanResult)? onComplete;

  const PestAiAnalysisWidget({
    super.key,
    required this.imageFile,
    required this.source,
    required this.onBack,
    this.onComplete,
  });

  @override
  State<PestAiAnalysisWidget> createState() => _PestAiAnalysisWidgetState();
}

class _PestAiAnalysisWidgetState extends State<PestAiAnalysisWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  double _currentProgress = 0.05;
  bool _isUploading = true;
  bool _hasError = false;
  String? _errorMessage;
  Map<String, dynamic>? _scanResult;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _progressAnimation = Tween<double>(begin: 0.05, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic),
    )..addListener(() {
        setState(() {
          _currentProgress = _progressAnimation.value;
        });
      });

    // Schedule API call after frame rendering so context & inherited localizations are available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAnalysisAndUpload();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  /// Runs real API upload/analysis call while animating smooth progress state.
  Future<void> _startAnalysisAndUpload() async {
    if (!mounted) return;
    final String currentLang = AppLocalizations.of(context).localeName;

    setState(() {
      _hasError = false;
      _errorMessage = null;
      _isUploading = true;
    });

    _progressController.reset();
    _progressController.forward();

    try {
      final result = await ApiService.uploadPestImage(
        imageFile: widget.imageFile,
        source: widget.source,
        language: currentLang,
      );

      _scanResult = result;

      // Ensure progress finishes to 100% smoothly
      await _progressController.forward();

      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });

      if (widget.onComplete != null && _scanResult != null) {
        widget.onComplete!(_scanResult!);
      }
    } catch (e) {
      if (!mounted) return;
      _progressController.stop();
      setState(() {
        _isUploading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final int percentInt = (_currentProgress * 100).toInt().clamp(0, 100);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. FULL SCREEN USER CROP PHOTO BACKGROUND
          Positioned.fill(
            child: kIsWeb
                ? Image.network(
                    widget.imageFile.path,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF14532D),
                    ),
                  )
                : Image.file(
                    File(widget.imageFile.path),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF14532D),
                    ),
                  ),
          ),

          // 2. DARK GRADIENT OVERLAY FOR READABILITY & CONTRAST
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.65),
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          // 3. MAIN CONTENT LAYOUT
          SafeArea(
            child: Column(
              children: [
                // Top Bar: Back Arrow directly over dark background
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                        onPressed: widget.onBack,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),

                        // Main Heading: "AI is analyzing your photo"
                        Text(
                          l10n.aiAnalyzingPhoto,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.22,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Subtitle: "This usually takes a few seconds."
                        Text(
                          l10n.takesFewSeconds,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.75),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Large Circular Analysis Progress Ring matching reference
                        _buildCircularProgressRing(percentInt),

                        const SizedBox(height: 32),

                        // Floating White Analysis Steps Card
                        _buildAnalysisStepsCard(l10n),

                        const SizedBox(height: 24),

                        // Privacy Footer: "Your data is safe and private"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.dataSafePrivate,
                              style: GoogleFonts.dmSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Error / Retry Banner if upload fails
          if (_hasError)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Card(
                color: const Color(0xFF7F1D1D),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage ?? 'Analysis failed',
                          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: _startAnalysisAndUpload,
                        child: Text(
                          l10n.retry,
                          style: GoogleFonts.dmSans(
                            color: Colors.amber,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the large circular progress ring with center percentage text matching reference.
  Widget _buildCircularProgressRing(int percentInt) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular custom painter for ring track + bright green progress arc
          CustomPaint(
            size: const Size(140, 140),
            painter: _CircularRingPainter(progress: _currentProgress),
          ),

          // Center Percentage Display
          Text(
            '$percentInt%',
            style: GoogleFonts.dmSans(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the floating light card listing the 5 analysis steps with status icons.
  Widget _buildAnalysisStepsCard(AppLocalizations l10n) {
    final steps = [
      {
        'title': l10n.stepImageQuality,
        'icon': Icons.crop_original_outlined,
        'threshold': 0.20,
      },
      {
        'title': l10n.stepDetectingPatterns,
        'icon': Icons.grid_view_outlined,
        'threshold': 0.40,
      },
      {
        'title': l10n.stepIdentifyingIssues,
        'icon': Icons.bug_report_outlined,
        'threshold': 0.60,
      },
      {
        'title': l10n.stepPreparingQuestions,
        'icon': Icons.person_outline,
        'threshold': 0.80,
      },
      {
        'title': l10n.stepGeneratingInsights,
        'icon': Icons.headset_mic_outlined,
        'threshold': 1.00,
      },
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final double threshold = step['threshold'] as double;
          final double prevThreshold = index == 0 ? 0.0 : (steps[index - 1]['threshold'] as double);

          final bool isCompleted = _currentProgress >= threshold;
          final bool isProcessing = _currentProgress >= prevThreshold && _currentProgress < threshold;

          return Padding(
            padding: EdgeInsets.only(bottom: index < steps.length - 1 ? 18 : 0),
            child: Row(
              children: [
                // STEP ICON
                Icon(
                  step['icon'] as IconData,
                  size: 20,
                  color: const Color(0xFF334155),
                ),
                const SizedBox(width: 14),

                // STEP TITLE
                Expanded(
                  child: Text(
                    step['title'] as String,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),

                // STATUS INDICATOR
                if (isCompleted)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF15803D), // Green checkmark
                    size: 22,
                  )
                else if (isProcessing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF15803D),
                    ),
                  )
                else
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Custom painter to render the circular ring track + bright green progress arc matching reference.
class _CircularRingPainter extends CustomPainter {
  final double progress;

  _CircularRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    // 1. Dark Background Ring Track
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Active Progress Arc
    final progressPaint = Paint()
      ..color = const Color(0xFF84CC16) // Vibrant agricultural lime green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2; // Top center
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
