import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/pest_pdf_service.dart';

/// Pest Detection Page 4 - Diagnosis Report Screen.
/// Displays the actual user-captured/uploaded image thumbnail, primary name, scientific name, severity badge,
/// "What we found" checklist, "What to do now" card, and Download PDF functionality.
class PestDiagnosisReportWidget extends StatefulWidget {
  final XFile? imageFile;
  final String? imageUrl;
  final Map<String, dynamic>? diagnosisData;
  final VoidCallback onBack;
  final VoidCallback onViewTreatmentGuide;

  const PestDiagnosisReportWidget({
    super.key,
    this.imageFile,
    this.imageUrl,
    this.diagnosisData,
    required this.onBack,
    required this.onViewTreatmentGuide,
  });

  @override
  State<PestDiagnosisReportWidget> createState() => _PestDiagnosisReportWidgetState();
}

class _PestDiagnosisReportWidgetState extends State<PestDiagnosisReportWidget> {
  bool _isGeneratingPdf = false;

  Future<void> _handleDownloadPdf() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      await PestPdfService.downloadAndShareReport(
        context: context,
        diagnosisData: widget.diagnosisData,
        imageFile: widget.imageFile,
        imageUrl: widget.imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.reportSavedSuccess),
            backgroundColor: const Color(0xFF15803D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String langCode = l10n.languageCode;

    // Extract dynamic AI diagnosis details with localized fallbacks matching reference design
    final String defaultPestName = langCode == 'hi' ? 'गिर्डल बीटल' : langCode == 'mr' ? 'गर्डल बीटल' : 'Girdle Beetle';
    final String pestName = widget.diagnosisData?['pest_name']?.toString() ?? defaultPestName;
    final String scientificName = widget.diagnosisData?['scientific_name']?.toString() ?? 'Obereopsis brevis';
    final String severity = widget.diagnosisData?['severity']?.toString() ?? l10n.moderateConcern;

    final Map<String, dynamic> findings = (widget.diagnosisData?['findings'] as Map<String, dynamic>?) ?? {};
    final String affectedPart = findings['affected_part']?.toString() ??
        (langCode == 'hi' ? 'पत्ती' : langCode == 'mr' ? 'पान' : 'Leaf');
    final String observedDamage = findings['observed_damage']?.toString() ??
        (langCode == 'hi' ? 'पत्ती पर अनियमित छिद्र' : langCode == 'mr' ? 'पानावर अनियमित छिद्रे' : 'Irregular holes on leaf');
    final String spread = findings['spread']?.toString() ??
        (langCode == 'hi' ? 'मध्यम' : langCode == 'mr' ? 'मध्यम' : 'Moderate');
    final String affectedArea = findings['affected_area']?.toString() ??
        (langCode == 'hi' ? '10-25% पौधे' : langCode == 'mr' ? '१०-२५% झाडे' : '10–25% of plants');
    final String cropStage = findings['crop_stage']?.toString() ??
        (langCode == 'hi' ? 'बढ़वार' : langCode == 'mr' ? 'वाढ' : 'Vegetative');

    final String defaultWhatToDoNow = langCode == 'hi'
        ? 'खेत की जांच करें और गंभीर रूप से क्षतिग्रस्त पत्तियों को हटा दें। हर 2-3 दिनों में निगरानी करें।'
        : langCode == 'mr'
            ? 'शेताची पाहणी करा आणि जास्त नुकसान झालेली पाने काढून टाका. दर २-३ दिवसांनी पाहणी करा.'
            : 'Inspect field and remove severely damaged leaves. Monitor the field every 2–3 days. Take action if damage exceeds economic threshold.';

    final String whatToDoNowText = widget.diagnosisData?['what_to_do_now']?.toString() ?? defaultWhatToDoNow;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 1. TOP PAGE HEADER (Back arrow + "Diagnosis Report" title + Download Icon)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 22),
                        onPressed: widget.onBack,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Expanded(
                        child: Text(
                          l10n.diagnosisReportTitle,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            height: 1.2,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_download_outlined, color: Color(0xFF15803D), size: 26),
                        onPressed: _handleDownloadPdf,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: l10n.downloadReport,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // MAIN SCROLLABLE REPORT BODY
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        // 2. TOP DIAGNOSIS CARD (User Photo Thumbnail + Pest Name + Scientific Name + Severity)
                        Container(
                          height: 140,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBF5), // Warm pale peach tint
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFED7AA).withOpacity(0.7), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // USER PHOTO THUMBNAIL (Fills 116px x 116px container with BoxFit.cover)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  width: 116,
                                  height: 116,
                                  child: _buildUserThumbnailImage(),
                                ),
                              ),

                              const SizedBox(width: 14),

                              // DIAGNOSIS DETAILS
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      pestName,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                        height: 1.2,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      scientificName,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13.5,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: -0.1,
                                        height: 1.2,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEDD5), // Warm orange pill background
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        severity,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.1,
                                          color: const Color(0xFFC2410C), // Orange text
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 3. WHAT WE FOUND SECTION (Inside structured card)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.whatWeFound,
                                style: GoogleFonts.dmSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  height: 1.25,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // FINDINGS CHECKLIST (With "Your crop stage" label)
                              _buildCheckItem(l10n.affectedPartLabel, affectedPart),
                              _buildCheckItem(l10n.observedDamageLabel, observedDamage),
                              _buildCheckItem(l10n.spreadLabel, spread),
                              _buildCheckItem(l10n.affectedAreaLabel, affectedArea),
                              _buildCheckItem(l10n.cropStageLabel, cropStage),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 4. WHAT TO DO NOW CARD (Short, concise field actions)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.whatToDoNow,
                                style: GoogleFonts.dmSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                  height: 1.25,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                whatToDoNowText,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.1,
                                  height: 1.45,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // 5. DOWNLOAD REPORT PRIMARY BUTTON & VIEW TREATMENT GUIDE BUTTON
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: Color(0xFF15803D), width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: _handleDownloadPdf,
                                icon: const Icon(Icons.file_download_outlined, color: Color(0xFF15803D)),
                                label: Text(
                                  l10n.downloadReport,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF15803D),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: widget.onViewTreatmentGuide,
                                child: Text(
                                  l10n.viewTreatmentGuide,
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

                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Loading overlay during PDF compilation
            if (_isGeneratingPdf)
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
                            l10n.preparingReport,
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
          ],
        ),
      ),
    );
  }

  /// Displays the actual user-captured/uploaded photo thumbnail using BoxFit.cover.
  Widget _buildUserThumbnailImage() {
    if (widget.imageFile != null && widget.imageFile!.path.isNotEmpty) {
      if (kIsWeb || widget.imageFile!.path.startsWith('blob:') || widget.imageFile!.path.startsWith('http')) {
        return Image.network(
          widget.imageFile!.path,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildNetworkOrAssetFallback(),
        );
      }
      try {
        return Image.file(
          File(widget.imageFile!.path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildNetworkOrAssetFallback(),
        );
      } catch (_) {
        return _buildNetworkOrAssetFallback();
      }
    }
    return _buildNetworkOrAssetFallback();
  }

  Widget _buildNetworkOrAssetFallback() {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      final fullUrl = widget.imageUrl!.startsWith('http') ? widget.imageUrl! : '${ApiService.baseUrl}${widget.imageUrl}';
      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildAssetFallback(),
      );
    }
    return _buildAssetFallback();
  }

  Widget _buildAssetFallback() {
    return Image.network(
      'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?q=80&w=1000&auto=format&fit=crop',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFDCFCE7),
        child: const Icon(Icons.eco, color: Color(0xFF15803D), size: 36),
      ),
    );
  }

  Widget _buildCheckItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check,
            color: Color(0xFF15803D),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.dmSans(
                  fontSize: 14.5,
                  letterSpacing: -0.1,
                  height: 1.4,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
