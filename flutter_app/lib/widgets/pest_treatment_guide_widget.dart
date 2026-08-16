import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';

/// Pest Detection Page 5 - Treatment Guide Screen.
/// Strictly matches the 5th phone screen in the reference image ("5. Treatment Guide").
/// Displays "What to do (For Field)", "Recommended Products", "Additional Tips",
/// and the "Save & Done" action button with the exact typography and card layout.
class PestTreatmentGuideWidget extends StatelessWidget {
  final Map<String, dynamic>? diagnosisData;
  final VoidCallback onBack;
  final VoidCallback onSaveAndDone;

  const PestTreatmentGuideWidget({
    super.key,
    this.diagnosisData,
    required this.onBack,
    required this.onSaveAndDone,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String langCode = l10n.languageCode;

    // Extract dynamic treatment guide structure or localized fallbacks
    final Map<String, dynamic> treatment =
        (diagnosisData?['treatment_guide'] as Map<String, dynamic>?) ?? {};

    final List<String> defaultFieldActions = langCode == 'hi'
        ? [
            'क्षतिग्रस्त पत्तियों को हटाकर नष्ट कर दें।',
            'हर 2-3 दिनों में खेत की निगरानी करें।',
            'आर्थिक क्षति सीमा से अधिक होने पर उपाय करें।',
          ]
        : langCode == 'mr'
            ? [
                'कीडग्रस्त पाने काढून नष्ट करा.',
                'दर २-३ दिवसांनी शेताची पाहणी करा.',
                'आर्थिक नुकसान पातळी ओलांडल्यास उपाययोजना करा.',
              ]
            : [
                'Remove and destroy severely damaged leaves.',
                'Monitor the field every 2–3 days.',
                'Take action if damage exceeds economic threshold.',
              ];

    final List<Map<String, String>> defaultProducts = langCode == 'hi'
        ? [
            {'name': 'इमामेक्टिन बेंजोएट 5 SG', 'dosage': '0.4 ग्राम / लीटर पानी'},
            {'name': 'नीम का तेल 1500 PPM', 'dosage': '3 मिली / लीटर पानी'},
          ]
        : langCode == 'mr'
            ? [
                {'name': 'इमामेक्टिन बेन्झोएट 5 SG', 'dosage': '०.४ ग्रॅम / लिटर पाणी'},
                {'name': 'निंबोळी तेल १५०० PPM', 'dosage': '३ मि.ली. / लिटर पाणी'},
              ]
            : [
                {'name': 'Emamectin Benzoate 5 SG', 'dosage': '0.4 g / liter of water'},
                {'name': 'Neem Oil 1500 PPM', 'dosage': '3 ml / liter of water'},
              ];

    final List<String> defaultTips = langCode == 'hi'
        ? [
            'उत्तम परिणाम के लिए सुबह जल्दी या देर शाम को छिड़काव करें।',
            'पत्तियों के निचले हिस्से पर अच्छी तरह से छिड़काव सुनिश्चित करें।',
          ]
        : langCode == 'mr'
            ? [
                'उत्तम निकालासाठी सकाळी लवकर किंवा संध्याकाळी फवारणी करा.',
                'पानांच्या खालच्या बाजूला व्यवस्थित फवारणी होईल याची खात्री करा.',
              ]
            : [
                'Spray in the early morning or late evening for best results.',
                'Ensure good coverage of underside of leaves.',
              ];

    final List<String> fieldActions = (treatment['what_to_do_field'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        defaultFieldActions;

    final List<Map<String, String>> products = (treatment['recommended_products'] as List?)
            ?.map((e) => Map<String, String>.from(e as Map))
            .toList() ??
        defaultProducts;

    final List<String> tips = (treatment['additional_tips'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        defaultTips;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP PAGE HEADER (Back Arrow + Centered "Treatment Guide" Title)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 22),
                    onPressed: onBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Text(
                      l10n.treatmentGuideTitle,
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
                  const SizedBox(width: 32), // Spacer to balance back arrow
                ],
              ),
            ),

            const SizedBox(height: 8),

            // MAIN SCROLLABLE BODY
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),

                    // SECTION 1 — WHAT TO DO (FOR FIELD) CARD
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
                            l10n.whatToDoForField,
                            style: GoogleFonts.dmSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              height: 1.25,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...fieldActions.map((action) => _buildCheckActionRow(action)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // SECTION 2 — RECOMMENDED PRODUCTS HEADING
                    Text(
                      l10n.recommendedProducts,
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.25,
                        color: const Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // RECOMMENDED PRODUCT ROWS
                    ...products.map((p) => _buildProductCard(p['name'] ?? '', p['dosage'] ?? '')),

                    const SizedBox(height: 20),

                    // SECTION 3 — ADDITIONAL TIPS CARD
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
                            l10n.additionalTips,
                            style: GoogleFonts.dmSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              height: 1.25,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (tips.isNotEmpty)
                            _buildTipRow(Icons.wb_sunny_outlined, tips[0]),
                          if (tips.length > 1)
                            _buildTipRow(Icons.eco_outlined, tips[1]),
                          for (int i = 2; i < tips.length; i++)
                            _buildTipRow(Icons.info_outline, tips[i]),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // BOTTOM PRIMARY BUTTON — "SAVE & DONE"
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D), // Deep agricultural green
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: onSaveAndDone,
                        child: Text(
                          l10n.saveAndDone,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a check action item row for "What to do (For Field)"
  Widget _buildCheckActionRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
            child: Text(
              text,
              style: GoogleFonts.dmSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.1,
                height: 1.45,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a product recommendation card row
  Widget _buildProductCard(String name, String dosage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        ),
        child: Row(
          children: [
            // PALE GREEN ICON CONTAINER
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.eco,
                color: Color(0xFF15803D),
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            // PRODUCT NAME & DOSAGE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.dmSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dosage,
                    style: GoogleFonts.dmSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.1,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an outline icon + text row for "Additional Tips"
  Widget _buildTipRow(IconData icon, String tipText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF15803D),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tipText,
              style: GoogleFonts.dmSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.1,
                height: 1.45,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
