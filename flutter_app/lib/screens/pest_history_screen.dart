import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/pest_history_service.dart';
import '../services/pest_pdf_service.dart';
import '../widgets/pest_diagnosis_report_widget.dart';
import '../widgets/pest_treatment_guide_widget.dart';

/// Pest Report History Screen.
/// Displays past diagnosis reports saved locally and on the backend.
/// Farmers can view, redownload, or share any previous report.
class PestHistoryScreen extends StatefulWidget {
  const PestHistoryScreen({super.key});

  @override
  State<PestHistoryScreen> createState() => _PestHistoryScreenState();
}

class _PestHistoryScreenState extends State<PestHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });
    final reports = await PestHistoryService.getReports();
    if (mounted) {
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    }
  }

  void _openReportDetails(Map<String, dynamic> item) {
    final Map<String, dynamic>? diagnosis = (item['diagnosis'] as Map<String, dynamic>?) ?? item;
    final String? imageUrl = item['image_url']?.toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          body: PestDiagnosisReportWidget(
            imageUrl: imageUrl,
            diagnosisData: diagnosis,
            onBack: () => Navigator.pop(ctx),
            onViewTreatmentGuide: () {
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (guideCtx) => Scaffold(
                    body: PestTreatmentGuideWidget(
                      diagnosisData: diagnosis,
                      onBack: () => Navigator.pop(guideCtx),
                      onSaveAndDone: () => Navigator.pop(guideCtx),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _downloadReportPdf(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context);
    final Map<String, dynamic>? diagnosis = (item['diagnosis'] as Map<String, dynamic>?) ?? item;
    final String? imageUrl = item['image_url']?.toString();
    final String? scanId = item['scan_id']?.toString();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.preparingReport),
        backgroundColor: const Color(0xFF15803D),
        duration: const Duration(seconds: 2),
      ),
    );

    await PestPdfService.downloadAndShareReport(
      context: context,
      diagnosisData: diagnosis,
      imageUrl: imageUrl,
      scanId: scanId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.reportHistoryTitle,
          style: GoogleFonts.dmSans(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF15803D)),
            )
          : _reports.isEmpty
              ? _buildEmptyState(l10n)
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: const Color(0xFF15803D),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final item = _reports[index];
                      return _buildHistoryCard(item, l10n);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF0FDF4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Color(0xFF15803D),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noReportsFound,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed pest scan diagnosis reports will be listed here.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, AppLocalizations l10n) {
    final Map<String, dynamic>? diagnosis = (item['diagnosis'] as Map<String, dynamic>?) ?? item;
    final String pestName = diagnosis?['pest_name']?.toString() ?? 'Girdle Beetle';
    final String scientificName = diagnosis?['scientific_name']?.toString() ?? 'Obereopsis brevis';
    final String severity = diagnosis?['severity']?.toString() ?? l10n.moderateConcern;
    final String? imageUrl = item['image_url']?.toString();

    String formattedDate = '';
    if (item['created_at'] != null) {
      try {
        final dt = DateTime.parse(item['created_at'].toString());
        formattedDate = DateFormat('MMM dd, yyyy · hh:mm a').format(dt);
      } catch (_) {
        formattedDate = item['created_at'].toString();
      }
    } else {
      formattedDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
    }

    Color severityBg = const Color(0xFFFFEDD5);
    Color severityText = const Color(0xFFC2410C);
    if (severity.toLowerCase().contains('high') || severity.toLowerCase().contains('उच्च')) {
      severityBg = const Color(0xFFFEE2E2);
      severityText = const Color(0xFFDC2626);
    } else if (severity.toLowerCase().contains('low') || severity.toLowerCase().contains('कम') || severity.toLowerCase().contains('कमी')) {
      severityBg = const Color(0xFFDCFCE7);
      severityText = const Color(0xFF15803D);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crop Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 68,
                    height: 68,
                    color: const Color(0xFFDCFCE7),
                    child: _buildThumbnail(imageUrl),
                  ),
                ),
                const SizedBox(width: 12),
                // Diagnosis info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pestName,
                        style: GoogleFonts.dmSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scientificName,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: severityBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              severity,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: severityText,
                              ),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      side: const BorderSide(color: Color(0xFF15803D), width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _openReportDetails(item),
                    icon: const Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF15803D)),
                    label: Text(
                      'View Details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _downloadReportPdf(item),
                    icon: const Icon(Icons.file_download_outlined, size: 16, color: Colors.white),
                    label: Text(
                      l10n.downloadReport,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(String? url) {
    if (url != null && url.isNotEmpty) {
      final fullUrl = url.startsWith('http') ? url : '${ApiService.baseUrl}$url';
      return Image.network(
        fullUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: Color(0xFF15803D), size: 32),
      );
    }
    return const Icon(Icons.eco, color: Color(0xFF15803D), size: 32);
  }
}
