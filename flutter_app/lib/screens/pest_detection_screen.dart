import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/pest_history_service.dart';
import '../screens/pest_history_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/pest_ai_analysis_widget.dart';
import '../widgets/pest_questions_widget.dart';
import '../widgets/pest_diagnosis_report_widget.dart';
import '../widgets/pest_treatment_guide_widget.dart';

/// Pest Detection Screen - Page 1 (Upload Photo), Page 2 (AI Analysis), Page 3 (Questions), Page 4 (Diagnosis Report), & Page 5 (Treatment Guide).
/// Strictly matches the visual layout, dark green crop background, floating action panel,
/// camera permission handling, and typography of the reference image.
class PestDetectionScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const PestDetectionScreen({
    super.key,
    this.onBackToHome,
  });

  @override
  State<PestDetectionScreen> createState() => _PestDetectionScreenState();
}

class _PestDetectionScreenState extends State<PestDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  int _currentPage = 0; // 0 = Page 1, 1 = Page 2, 2 = Page 3, 3 = Page 4, 4 = Page 5 (Treatment Guide)
  XFile? _selectedImage;
  String _selectedSource = 'camera';
  Map<String, dynamic>? _scanResult;
  List<Map<String, dynamic>> _questions = [];
  // ignore: unused_field
  Map<String, String> _userAnswers = {};
  Map<String, dynamic>? _diagnosisData;
  bool _isUploading = false;
  bool _isValidating = false;

  /// Fetches AI Diagnosis Report based on scan result, user image, and 5 Yes/No answers.
  Future<void> _fetchAndShowDiagnosisReport(Map<String, String> answers) async {
    final l10n = AppLocalizations.of(context);
    final String scanId = _scanResult?['scan_id'] ?? 'scan_demo';

    String? imageBase64;
    if (_selectedImage != null) {
      try {
        final bytes = await _selectedImage!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      } catch (e) {
        print('[BASE64 ENCODE ERROR] $e');
      }
    }

    final report = await ApiService.fetchPestDiagnosis(
      scanId: scanId,
      imageBase64: imageBase64,
      answers: answers,
      language: l10n.localeName,
    );

    // Save report locally & remotely to history
    await PestHistoryService.saveReport({
      'scan_id': scanId,
      'image_url': _scanResult?['image_url'],
      'diagnosis': report,
      'created_at': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      setState(() {
        _diagnosisData = report;
        _currentPage = 3; // Navigate to Page 4 (Diagnosis Report)
      });
    }
  }

  /// Handles tapping the camera button with native permission verification.
  Future<void> _handleCameraTap() async {
    if (kIsWeb) {
      await _pickAndUploadImage(ImageSource.camera);
      return;
    }

    PermissionStatus status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (status.isGranted || status.isLimited) {
      await _pickAndUploadImage(ImageSource.camera);
    } else if (status.isPermanentlyDenied) {
      if (!mounted) return;
      _showPermissionDeniedDialog();
    } else {
      await _pickAndUploadImage(ImageSource.camera);
    }
  }

  /// Handles gallery image selection.
  Future<void> _handleGalleryTap() async {
    await _pickAndUploadImage(ImageSource.gallery);
  }

  /// Picks image from [source], validates crop/plant relevance, and transitions to Page 2 (AI Analysis).
  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final l10n = AppLocalizations.of(context);

      setState(() {
        _isValidating = true;
      });

      // Lightweight Gemini Vision relevance validation
      final validation = await ApiService.validatePestImage(
        imageFile: pickedFile,
        language: l10n.localeName,
      );

      if (!mounted) return;
      setState(() {
        _isValidating = false;
      });

      final bool isValid = validation['is_valid_for_pest_detection'] == true;
      final String category = (validation['category'] ?? 'crop_plant').toString().toLowerCase();

      if (isValid) {
        // VALID: Continue to existing AI Analysis flow
        setState(() {
          _selectedImage = pickedFile;
          _selectedSource = source == ImageSource.camera ? 'camera' : 'gallery';
          _currentPage = 1; // Transition to Page 2 (AI Analysis)
        });
      } else {
        // INVALID: Do NOT continue to Gemini pest diagnosis; show farmer-friendly localized bottom sheet
        _showInvalidImageBottomSheet(category);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isValidating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select image: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Shows farmer-friendly, localized modal bottom sheet when an uploaded photo is invalid/unrelated.
  void _showInvalidImageBottomSheet(String category) {
    final l10n = AppLocalizations.of(context);

    String title = l10n.pleaseUploadCropPhoto;
    String description = l10n.uploadCropPhotoDesc;
    String buttonText = l10n.tryAnotherPhoto;

    if (category == 'person' || category == 'selfie') {
      title = l10n.photoNotACrop;
      description = l10n.photoNotACropDesc;
      buttonText = l10n.tryAnotherPhoto;
    } else if (category == 'unclear_photo') {
      title = l10n.photoNotClear;
      description = l10n.photoNotClearDesc;
      buttonText = l10n.takeAnotherPhoto;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Circular icon badge
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.no_photography_outlined,
                    color: Color(0xFFDC2626),
                    size: 30,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 10),

              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF475569),
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 20),

              // Tips Box (✓ Leaf or plant, ✓ Visible crop damage, ✓ Pest on a crop)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.validExamplesTitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF14532D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.tipLeafOrPlant,
                      style: GoogleFonts.dmSans(fontSize: 12.5, color: const Color(0xFF166534)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.tipVisibleDamage,
                      style: GoogleFonts.dmSans(fontSize: 12.5, color: const Color(0xFF166534)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.tipPestOnCrop,
                      style: GoogleFonts.dmSans(fontSize: 12.5, color: const Color(0xFF166534)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Button: "Try Another Photo"
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    buttonText,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Shows clear farmer-friendly dialog if camera permission is permanently denied.

  void _showPermissionDeniedDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.camera_alt_outlined, color: Color(0xFF15803D)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.cameraPermTitle,
                style: GoogleFonts.dmSans(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.cameraPermDeniedBody,
          style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.cancelBtn,
              style: GoogleFonts.dmSans(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text(
              l10n.openSettings,
              style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPage == 1 && _selectedImage != null) {
      return PestAiAnalysisWidget(
        imageFile: _selectedImage!,
        source: _selectedSource,
        onBack: () {
          setState(() {
            _currentPage = 0; // Return to Page 1
          });
        },
        onComplete: (result) {
          setState(() {
            _scanResult = result;
            final rawList = result['questions'] as List? ?? [];
            _questions = List<Map<String, dynamic>>.from(rawList);
            _currentPage = 2; // Transition to Page 3 (Questions)
          });
        },
        onInvalidImage: (category) {
          setState(() {
            _currentPage = 0; // Return to Page 1
          });
          _showInvalidImageBottomSheet(category);
        },
      );
    }


    if (_currentPage == 2) {
      return PestQuestionsWidget(
        questions: _questions,
        onBack: () {
          setState(() {
            _currentPage = 1; // Return to Page 2
          });
        },
        onComplete: (answers) {
          setState(() {
            _userAnswers = answers;
          });
          _fetchAndShowDiagnosisReport(answers);
        },
      );
    }

    if (_currentPage == 3) {
      return PestDiagnosisReportWidget(
        imageFile: _selectedImage,
        imageUrl: _scanResult?['image_url']?.toString(),
        diagnosisData: _diagnosisData,
        onBack: () {
          setState(() {
            _currentPage = 2; // Return to Page 3 Questions
          });
        },
        onViewTreatmentGuide: () {
          setState(() {
            _currentPage = 4; // Navigate to Page 5 (Treatment Guide)
          });
        },
      );
    }

    if (_currentPage == 4) {
      return PestTreatmentGuideWidget(
        diagnosisData: _diagnosisData,
        onBack: () {
          setState(() {
            _currentPage = 3; // Return to Page 4 Diagnosis Report
          });
        },
        onSaveAndDone: () {
          setState(() {
            _currentPage = 0; // Return to Page 1 Upload Photo
            _selectedImage = null;
            _scanResult = null;
            _questions = [];
            _userAnswers = {};
            _diagnosisData = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pest scan complete and saved successfully!'),
              backgroundColor: Color(0xFF15803D),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        },
      );
    }

    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: _currentPage == 0 && widget.onBackToHome == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentPage > 0) {
          setState(() {
            _currentPage -= 1;
          });
        } else if (widget.onBackToHome != null) {
          widget.onBackToHome!();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Main Scrollable Area with Dark Photographic Background Top + White Upload Panel
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // TOP HERO SECTION (Full Photographic Dark Leaf Background)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 380),
                    child: Stack(
                      children: [
                        // 1. Photographic Dark Green Leaf Background Image
                        Positioned.fill(
                          child: Image.network(
                            'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?q=80&w=1000&auto=format&fit=crop',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFF14532D),
                            ),
                          ),
                        ),

                        // 2. Dark Overlay for readability
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.55),
                                  Colors.black.withOpacity(0.40),
                                  Colors.black.withOpacity(0.65),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 3. Top Navigation & Hero Text Content
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Bar: Back Arrow + "Pest Detection"
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(
                                            Icons.arrow_back,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          onPressed: () {
                                            if (_currentPage > 0) {
                                              setState(() => _currentPage -= 1);
                                            } else if (widget.onBackToHome != null) {
                                              widget.onBackToHome!();
                                            } else if (Navigator.canPop(context)) {
                                              Navigator.pop(context);
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          l10n.pestDetectionTitle,
                                          style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.history, color: Colors.white, size: 24),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (ctx) => const PestHistoryScreen()),
                                      );
                                    },
                                    tooltip: l10n.reportHistoryTitle,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 36),

                              // Main Hero Heading: "Identify what's affecting your crop"
                              Text(
                                l10n.pestHeroTitle,
                                style: GoogleFonts.dmSans(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.18,
                                  letterSpacing: -0.3,
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Hero Subtitle: "Take a clear photo of the affected plant or leaf..."
                              Text(
                                l10n.pestHeroSubtitle,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withOpacity(0.92),
                                  height: 1.45,
                                  letterSpacing: 0.1,
                                ),
                              ),

                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // FLOATING UPLOAD ACTION PANEL (Rounded Top Corners overlapping Hero Background)
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                    child: Column(
                      children: [
                        // FIRST PRIMARY ACTION CARD: Take Photo (Large Centered Camera Action)
                        Material(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(20),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _handleCameraTap,
                            borderRadius: BorderRadius.circular(20),
                            splashColor: const Color(0xFF15803D).withOpacity(0.12),
                            highlightColor: const Color(0xFF15803D).withOpacity(0.06),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Circular outlined camera icon treatment matching reference
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFF84CC16), // Light green ring border
                                        width: 2.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF84CC16).withOpacity(0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.camera_alt_outlined,
                                        color: Color(0xFF15803D), // Dark green camera icon
                                        size: 32,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // "Take Photo" Title
                                  Text(
                                    l10n.takePhoto,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  // "Use camera" Subtitle
                                  Text(
                                    l10n.useCamera,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // DIVIDER WITH "or"
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade200,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: Text(
                                l10n.orDivider,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Colors.grey.shade200,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // SECONDARY ACTION: Upload from Gallery Button Card
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _handleGalleryTap,
                            borderRadius: BorderRadius.circular(16),
                            splashColor: const Color(0xFF15803D).withOpacity(0.08),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.photo_library_outlined,
                                    color: Color(0xFF0F172A),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    l10n.uploadFromGallery,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // TIPS SECTION (Compact Pale Green Agricultural Card)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4), // Pale green
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFDCFCE7), width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.tipsTitle,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF14532D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.tipsText,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF166534),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Validating overlay indicator
          if (_isValidating)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF15803D)),
                        const SizedBox(height: 14),
                        Text(
                          l10n.validatingPhoto,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Uploading overlay indicator
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: Center(
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Color(0xFF15803D)),
                        const SizedBox(height: 14),
                        Text(
                          'Uploading photo...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
}

