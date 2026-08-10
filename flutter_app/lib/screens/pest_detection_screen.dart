import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../widgets/symptom_illustrations.dart';

/// Pest Detection Screen - Page 1 (First-Time User / Empty State).
/// Strictly matches the visual layout, typography, and structure of the reference image.
class PestDetectionScreen extends StatefulWidget {
  const PestDetectionScreen({super.key});

  @override
  State<PestDetectionScreen> createState() => _PestDetectionScreenState();
}

class _PestDetectionScreenState extends State<PestDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _handleImageSelection(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      final String sourceName = source == ImageSource.camera ? 'camera' : 'gallery';

      // Send file to FastAPI backend -> saved in MongoDB pest_scans
      final response = await ApiService.uploadPestImage(
        imageFile: pickedFile,
        source: sourceName,
      );

      setState(() {
        _isUploading = false;
      });

      if (!mounted) return;

      final scanId = response['scan_id'] ?? 'Unknown';

      // Show success message with scan ID
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image uploaded! Scan ID: $scanId (Ready for Page 2)'),
          backgroundColor: const Color(0xFF0F6838),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            l10n.pestDetectionTitle,
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline, color: Color(0xFF1F2937), size: 24),
              onPressed: () {
                _showInfoDialog(context, l10n);
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. HERO SECTION
                  _buildHeroSection(l10n),

                  const SizedBox(height: 24),

                  // 2. PHOTO ACTION CARDS (Take Photo / Choose Photo)
                  _buildPhotoActionSection(l10n),

                  const SizedBox(height: 16),

                  // 3. SUPPORTING LINE: "Quick • Easy • Private"
                  _buildPrivacySupportingLine(l10n),

                  const SizedBox(height: 24),

                  // 4. "NOT SURE WHAT TO SCAN?" SECTION & 2x3 GRID
                  _buildSymptomGuideCard(l10n),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),

          // Uploading overlay indicator
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0F6838)),
                        SizedBox(height: 12),
                        Text(
                          'Uploading scan...',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 1. Hero Section Widget
  Widget _buildHeroSection(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Text Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.pestHeroTitle,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0A3C13), // Dark green
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.pestHeroSubtitle,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF4B5563), // Dark gray
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Right Plant Illustration (contained cleanly without top clipping)
        Padding(
          padding: const EdgeInsets.only(top: 4, right: 4),
          child: SymptomIllustrations.heroPlant(size: 95),
        ),
      ],
    );
  }

  /// 2. Photo Action Cards (Take Photo / Choose Photo) Side-by-Side
  Widget _buildPhotoActionSection(AppLocalizations l10n) {
    return Row(
      children: [
        // LEFT CARD: Take Photo (Pale Green)
        Expanded(
          child: _buildActionCard(
            bgColor: const Color(0xFFEAF5EA),
            iconData: Icons.camera_alt,
            title: l10n.takePhoto,
            subtitle: l10n.useCamera,
            onTap: () => _handleImageSelection(ImageSource.camera),
          ),
        ),

        const SizedBox(width: 14),

        // RIGHT CARD: Choose Photo (Pale Warm Yellow)
        Expanded(
          child: _buildActionCard(
            bgColor: const Color(0xFFFFF8E7),
            iconData: Icons.photo_library,
            title: l10n.choosePhoto,
            subtitle: l10n.fromGallery,
            onTap: () => _handleImageSelection(ImageSource.gallery),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required Color bgColor,
    required IconData iconData,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0xFF0F6838).withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dark green circular icon container
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F6838),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. Small Supporting Line: Shield icon + "Quick • Easy • Private"
  Widget _buildPrivacySupportingLine(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_user_outlined,
          size: 16,
          color: Color(0xFF4B5563),
        ),
        const SizedBox(width: 6),
        Text(
          l10n.quickEasyPrivate,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4B5563),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  /// 4. "Not sure what to scan?" Card containing the 2x3 Symptom Grid
  Widget _buildSymptomGuideCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.notSureWhatToScan,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            l10n.lookForSigns,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 18),

          // 2 Rows x 3 Columns Symptom Tiles Grid
          Column(
            children: [
              // Row 1: Symptoms 1, 2, 3
              Row(
                children: [
                  Expanded(
                    child: _buildSymptomTile(
                      illustration: SymptomIllustrations.holesEatenLeaves(),
                      label: l10n.symptomHoles,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSymptomTile(
                      illustration: SymptomIllustrations.insects(),
                      label: l10n.symptomInsects,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSymptomTile(
                      illustration: SymptomIllustrations.spotsDiscoloration(),
                      label: l10n.symptomSpots,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Row 2: Symptoms 4, 5, 6
              Row(
                children: [
                  Expanded(
                    child: _buildSymptomTile(
                      illustration: SymptomIllustrations.curlingDistortion(),
                      label: l10n.symptomCurling,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSymptomTile(
                      illustration: SymptomIllustrations.webbing(),
                      label: l10n.symptomWebbing,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSymptomTile(
                      illustration: SymptomIllustrations.suddenDamage(),
                      label: l10n.symptomSuddenDamage,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Single Symptom Tile inside the Grid
  Widget _buildSymptomTile({
    required Widget illustration,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      height: 115,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          illustration,
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.pestDetectionTitle),
        content: Text(l10n.pestHeroSubtitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
