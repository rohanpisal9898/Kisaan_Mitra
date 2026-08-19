import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n/app_localizations.dart';
import 'api_service.dart';

/// Professional PDF Generation Service for Pest Diagnosis Reports.
/// Strictly matches the visual layout, color scheme, typography, card structures,
/// vector SVG icons, and multilingual specifications of the approved design specification.
class PestPdfService {
  // Native Clean Vector SVG Icons (Guarantees zero missing glyph boxes ☒ in PDF)
  static const String checkSvg = '<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#15803D" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>';
  static const String leafSvg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#15803D" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z"></path><path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12"></path></svg>';
  static const String clipSvg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#15803D" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"></path><rect x="8" y="2" width="8" height="4" rx="1" ry="1"></rect></svg>';
  static const String zapSvg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#15803D" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon></svg>';
  static const String targetSvg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#15803D" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><circle cx="12" cy="12" r="6"></circle><circle cx="12" cy="12" r="2"></circle></svg>';
  static const String sproutSvg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#15803D" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 20h10"></path><path d="M12 20v-8"></path><path d="M12 12A5 5 0 0 1 7 7c0-2 2-3 5-3s5 1 5 3a5 5 0 0 1-5 5z"></path></svg>';
  static const String bagSvg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#15803D" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"></path><line x1="3" y1="6" x2="21" y2="6"></line><path d="M16 10a4 4 0 0 1-8 0"></path></svg>';
  static const String bulbSvg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#15803D" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18h6"></path><path d="M10 22h4"></path><path d="M15.09 14c.18-.98.65-1.74 1.41-2.5A4.65 4.65 0 0 0 18 8 6 6 0 0 0 6 8c0 1.55.59 2.92 1.5 3.92.77.8 1.25 1.55 1.42 2.58"></path></svg>';
  static const String sunSvg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#15803D" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>';
  static const String shieldSvg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#15803D" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path></svg>';
  static const String infoSvg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#B45309" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>';
  static const String recycleSvg = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#15803D" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="7 19 3 15 7 11"></polyline><path d="M3 15h12a5 5 0 0 0 0-10H9"></path></svg>';
  static const String heartSvg = '<svg width="12" height="12" viewBox="0 0 24 24" fill="#84CC16" stroke="none"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path></svg>';

  /// Generates the complete PDF report document and triggers download/share.
  static Future<Uint8List> generatePdfReport({
    required BuildContext context,
    required Map<String, dynamic>? diagnosisData,
    XFile? imageFile,
    String? imageUrl,
    String? scanId,
    DateTime? scanDate,
  }) async {
    final l10n = AppLocalizations.of(context);
    final String langCode = l10n.languageCode;

    // Load Unicode fonts supporting English, Hindi, and Marathi Devanagari script
    final bool isDevanagari = langCode == 'hi' || langCode == 'mr';
    final pw.Font mainFont = await _getFont(isBold: false, isDevanagari: isDevanagari);
    final pw.Font boldFont = await _getFont(isBold: true, isDevanagari: isDevanagari);

    // Load user crop photo bytes for PDF embedding
    Uint8List? imageBytes = await _loadCropImageBytes(imageFile: imageFile, imageUrl: imageUrl);

    final pdf = pw.Document();

    // Data extraction with localized fallbacks matching current scan data
    final String reportId = (scanId != null && scanId.isNotEmpty)
        ? scanId.toUpperCase().replaceAll('SCAN_', 'KM')
        : 'KM250501-0001';

    final DateTime date = scanDate ?? DateTime.now();
    final String formattedDate = DateFormat('MMM dd, yyyy · hh:mm a').format(date);

    final String defaultPestName = langCode == 'hi' ? 'गिर्डल बीटल' : langCode == 'mr' ? 'गर्डल बीटल' : 'GIRDLE BEETLE';
    final String pestName = (diagnosisData?['pest_name']?.toString() ?? defaultPestName).toUpperCase();
    final String scientificName = diagnosisData?['scientific_name']?.toString() ?? 'Obereopsis brevis';
    final String rawSeverity = diagnosisData?['severity']?.toString() ?? l10n.moderateConcern;

    // Severity pill color setup
    PdfColor severityBg = PdfColor.fromHex('FFF3E0'); // Amber
    PdfColor severityText = PdfColor.fromHex('C2410C'); // Orange
    if (rawSeverity.toLowerCase().contains('high') || rawSeverity.toLowerCase().contains('उच्च')) {
      severityBg = PdfColor.fromHex('FEE2E2');
      severityText = PdfColor.fromHex('DC2626');
    } else if (rawSeverity.toLowerCase().contains('low') || rawSeverity.toLowerCase().contains('कम') || rawSeverity.toLowerCase().contains('कमी')) {
      severityBg = PdfColor.fromHex('DCFCE7');
      severityText = PdfColor.fromHex('15803D');
    }

    final Map<String, dynamic> findings = (diagnosisData?['findings'] as Map<String, dynamic>?) ?? {};
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
        ? 'खेत की जांच करें और गंभीर रूप से क्षतिग्रस्त पत्तियों को हटा दें। हर 2-3 दिनों में खेत की निगरानी करें और यदि क्षति आर्थिक सीमा से अधिक हो तो अनुशंसित उपचार लागू करें।'
        : langCode == 'mr'
            ? 'शेताची पाहणी करा आणि जास्त नुकसान झालेली पाने काढून टाका. दर २-३ दिवसांनी पाहणी करा आणि नुकसान जास्त असल्यास उपाययोजना करा.'
            : 'Inspect the field and remove severely damaged leaves. Monitor the field every 2–3 days. Apply recommended treatment according to dosage instructions if damage exceeds economic threshold.';

    final String whatToDoNowText = diagnosisData?['what_to_do_now']?.toString() ?? defaultWhatToDoNow;

    // Recommended products list
    final Map<String, dynamic> treatment = (diagnosisData?['treatment_guide'] as Map<String, dynamic>?) ?? {};
    final List<Map<String, String>> defaultProducts = langCode == 'hi'
        ? [
            {'name': 'इमामेक्टिन बेंजोएट 5 SG', 'dosage': '0.4 ग्राम / लीटर पानी (छिड़काव)'},
            {'name': 'नीम का तेल 1500 PPM', 'dosage': '3 मिली / लीटर पानी (जैविक नियंत्रण)'},
          ]
        : langCode == 'mr'
            ? [
                {'name': 'इमामेक्टिन बेन्झोएट 5 SG', 'dosage': '०.४ ग्रॅम / लिटर पाणी (फवारणी)'},
                {'name': 'निंबोळी तेल १५०० PPM', 'dosage': '३ मि.ली. / लिटर पाणी (जैविक नियंत्रण)'},
              ]
            : [
                {'name': 'Emamectin Benzoate 5 SG', 'dosage': '0.4 g / liter of water (Foliar Spray)'},
                {'name': 'Neem Oil 1500 PPM', 'dosage': '3 ml / liter of water (Organic Control)'},
              ];

    final List<Map<String, String>> products = (treatment['recommended_products'] as List?)
            ?.map((e) => Map<String, String>.from(e as Map))
            .toList() ??
        defaultProducts;

    // Additional tips
    final List<String> defaultTips = langCode == 'hi'
        ? [
            'उत्तम परिणाम और वाष्पीकरण से बचने के लिए सुबह जल्दी या देर शाम को छिड़काव करें।',
            'पत्तियों के निचले हिस्से और तने पर अच्छी तरह से कवरेज सुनिश्चित करें।',
          ]
        : langCode == 'mr'
            ? [
                'उत्तम निकालासाठी सकाळी लवकर किंवा संध्याकाळी फवारणी करा.',
                'पानांच्या खालच्या बाजूला आणि खोडावर व्यवस्थित फवारणी होईल याची खात्री करा.',
              ]
            : [
                'Spray in the early morning or late evening for best absorption and minimal drift.',
                'Ensure thorough coverage of both upper and lower leaf surfaces.',
              ];

    final List<String> tips = (treatment['additional_tips'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        defaultTips;

    // Color Palette matching design spec
    final primaryGreen = PdfColor.fromHex('15803D');
    final darkNavy = PdfColor.fromHex('0F172A');
    final textGrey = PdfColor.fromHex('475569');
    final lightCardBg = PdfColor.fromHex('F8FAFC');
    final cardBorder = PdfColor.fromHex('E2E8F0');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. HEADER SECTION (Branding + Metadata badges)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Branding Left
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 16,
                            height: 16,
                            decoration: pw.BoxDecoration(
                              color: primaryGreen,
                              shape: pw.BoxShape.circle,
                            ),
                            child: pw.Center(
                              child: pw.SvgImage(svg: leafSvg, width: 10, height: 10),
                            ),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            'KISAAN MITRA',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 18,
                              color: primaryGreen,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        l10n.smartFarmingSlogan,
                        style: pw.TextStyle(
                          font: mainFont,
                          fontSize: 9.5,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),

                  // Metadata Badges Right
                  pw.Row(
                    children: [
                      _buildHeaderBadge(l10n.reportIdLabel, reportId, mainFont, boldFont),
                      pw.SizedBox(width: 8),
                      _buildHeaderBadge(l10n.dateTimeLabel, formattedDate, mainFont, boldFont),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 14),
              pw.Container(height: 1, color: cardBorder),
              pw.SizedBox(height: 14),

              // Title Bar: PEST DIAGNOSIS REPORT
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        l10n.pestDiagnosisReportHeader,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 20,
                          color: darkNavy,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        l10n.cropHealthAnalysis,
                        style: pw.TextStyle(
                          font: mainFont,
                          fontSize: 11.5,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    width: 34,
                    height: 34,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('DCFCE7'),
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.SvgImage(svg: leafSvg, width: 18, height: 18),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // 2. DIAGNOSIS SUMMARY CARD (Crop Photo + Pest details + What We Found)
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('FAFAFA'),
                  borderRadius: pw.BorderRadius.circular(14),
                  border: pw.Border.all(color: cardBorder, width: 1.2),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // LEFT SIDE: Crop Image Thumbnail
                    pw.Container(
                      width: 125,
                      height: 125,
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('DCFCE7'),
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(color: PdfColor.fromHex('84CC16'), width: 1),
                      ),
                      child: imageBytes != null
                          ? pw.ClipRRect(
                              horizontalRadius: 11,
                              verticalRadius: 11,
                              child: pw.Image(
                                pw.MemoryImage(imageBytes),
                                fit: pw.BoxFit.cover,
                              ),
                            )
                          : pw.Center(
                              child: pw.SvgImage(svg: leafSvg, width: 42, height: 42),
                            ),
                    ),

                    pw.SizedBox(width: 16),

                    // MIDDLE: Disease / Pest Name & Severity
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            pestName,
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 16,
                              color: primaryGreen,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            scientificName,
                            style: pw.TextStyle(
                              font: mainFont,
                              fontSize: 11,
                              fontStyle: pw.FontStyle.italic,
                              color: textGrey,
                            ),
                          ),
                          pw.SizedBox(height: 12),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: pw.BoxDecoration(
                              color: severityBg,
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Text(
                              rawSeverity,
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 10,
                                color: severityText,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(width: 12),

                    // RIGHT: WHAT WE FOUND CHECKLIST
                    pw.Expanded(
                      flex: 5,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            l10n.whatWeFound.toUpperCase(),
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 11,
                              color: primaryGreen,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          _buildPdfCheckItem(l10n.affectedPartLabel, affectedPart, mainFont, boldFont, textGrey, darkNavy),
                          _buildPdfCheckItem(l10n.observedDamageLabel, observedDamage, mainFont, boldFont, textGrey, darkNavy),
                          _buildPdfCheckItem(l10n.spreadLabel, spread, mainFont, boldFont, textGrey, darkNavy),
                          _buildPdfCheckItem(l10n.affectedAreaLabel, affectedArea, mainFont, boldFont, textGrey, darkNavy),
                          _buildPdfCheckItem(l10n.reportCropStage, cropStage, mainFont, boldFont, textGrey, darkNavy),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // 3. TWO-COLUMN ROW 1: "WHAT TO DO NOW" & "AFFECTED SEVERITY"
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left Card: WHAT TO DO NOW
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: lightCardBg,
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(color: cardBorder, width: 1.2),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.SvgImage(svg: clipSvg, width: 14, height: 14),
                              pw.SizedBox(width: 6),
                              pw.Text(
                                l10n.whatToDoNow.toUpperCase(),
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 11,
                                  color: primaryGreen,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            whatToDoNowText,
                            style: pw.TextStyle(
                              font: mainFont,
                              fontSize: 9.5,
                              color: darkNavy,
                              lineSpacing: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  pw.SizedBox(width: 14),

                  // Right Card: AFFECTED SEVERITY (3-column layout without confidence score)
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: lightCardBg,
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(color: cardBorder, width: 1.2),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.SvgImage(svg: zapSvg, width: 14, height: 14),
                              pw.SizedBox(width: 6),
                              pw.Text(
                                l10n.affectedSeverityTitle,
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 11,
                                  color: primaryGreen,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 12),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                            children: [
                              _buildSeverityColumn(leafSvg, affectedArea, l10n.plantsAffected, mainFont, boldFont, darkNavy, textGrey),
                              pw.Container(width: 1, height: 44, color: cardBorder),
                              _buildSeverityColumn(targetSvg, rawSeverity, l10n.severityLevel, mainFont, boldFont, darkNavy, textGrey),
                              pw.Container(width: 1, height: 44, color: cardBorder),
                              _buildSeverityColumn(sproutSvg, cropStage, l10n.reportCropStage, mainFont, boldFont, darkNavy, textGrey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // 4. TWO-COLUMN ROW 2: "RECOMMENDED PRODUCTS" & "ADDITIONAL TIPS"
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left: RECOMMENDED PRODUCTS
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: lightCardBg,
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(color: cardBorder, width: 1.2),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.SvgImage(svg: bagSvg, width: 14, height: 14),
                              pw.SizedBox(width: 6),
                              pw.Text(
                                l10n.recommendedProducts.toUpperCase(),
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 11,
                                  color: primaryGreen,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          if (products.isEmpty)
                            pw.Text(
                              l10n.noProductRecommendation,
                              style: pw.TextStyle(font: mainFont, fontSize: 9.5, color: textGrey),
                            )
                          else
                            ...products.map((p) => _buildPdfProductCard(p['name'] ?? '', p['dosage'] ?? '', mainFont, boldFont, darkNavy, textGrey, cardBorder)),
                        ],
                      ),
                    ),
                  ),

                  pw.SizedBox(width: 14),

                  // Right: ADDITIONAL TIPS
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: lightCardBg,
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(color: cardBorder, width: 1.2),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.SvgImage(svg: bulbSvg, width: 14, height: 14),
                              pw.SizedBox(width: 6),
                              pw.Text(
                                l10n.additionalTips.toUpperCase(),
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 11,
                                  color: primaryGreen,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          if (tips.isNotEmpty) _buildTipBox(sunSvg, tips[0], mainFont, darkNavy, cardBorder),
                          pw.SizedBox(height: 6),
                          if (tips.length > 1) _buildTipBox(leafSvg, tips[1], mainFont, darkNavy, cardBorder),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 14),

              // 5. TWO-COLUMN ROW 3: "ABOUT THIS REPORT" & "IMPORTANT NOTE"
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left: ABOUT THIS REPORT
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: lightCardBg,
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(color: cardBorder, width: 1.2),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.SvgImage(svg: shieldSvg, width: 14, height: 14),
                              pw.SizedBox(width: 6),
                              pw.Text(
                                l10n.aboutThisReportTitle,
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 10.5,
                                  color: primaryGreen,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            l10n.aboutThisReportBody,
                            style: pw.TextStyle(
                              font: mainFont,
                              fontSize: 8.5,
                              color: textGrey,
                              lineSpacing: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  pw.SizedBox(width: 14),

                  // Right: IMPORTANT NOTE
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('FFFBEB'), // Soft amber tint
                        borderRadius: pw.BorderRadius.circular(12),
                        border: pw.Border.all(color: PdfColor.fromHex('FDE68A'), width: 1.2),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            children: [
                              pw.SvgImage(svg: infoSvg, width: 14, height: 14),
                              pw.SizedBox(width: 6),
                              pw.Text(
                                l10n.importantNoteTitle,
                                style: pw.TextStyle(
                                  font: boldFont,
                                  fontSize: 10.5,
                                  color: PdfColor.fromHex('B45309'),
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            l10n.importantNoteBody,
                            style: pw.TextStyle(
                              font: mainFont,
                              fontSize: 8.5,
                              color: PdfColor.fromHex('78350F'),
                              lineSpacing: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // 6. BOTTOM BENEFITS GRID (4 horizontal items)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: cardBorder, width: 1)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildBenefitItem(shieldSvg, l10n.trustedAnalysisTitle, l10n.trustedAnalysisSub, mainFont, boldFont, darkNavy, textGrey),
                    _buildBenefitItem(leafSvg, l10n.betterDecisionsTitle, l10n.betterDecisionsSub, mainFont, boldFont, darkNavy, textGrey),
                    _buildBenefitItem(recycleSvg, l10n.sustainableFarmingTitle, l10n.sustainableFarmingSub, mainFont, boldFont, darkNavy, textGrey),
                    _buildBenefitItem(leafSvg, l10n.wereHereTitle, l10n.wereHereSub, mainFont, boldFont, darkNavy, textGrey),
                  ],
                ),
              ),

              pw.SizedBox(height: 8),

              // 7. FOOTER BANNER
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                decoration: pw.BoxDecoration(
                  color: primaryGreen,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        l10n.thankYouFooter.replaceAll('💚', '').trim(),
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 11,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(width: 6),
                      pw.SvgImage(svg: heartSvg, width: 12, height: 12),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Downloads/Saves and shares the generated PDF.
  static Future<void> downloadAndShareReport({
    required BuildContext context,
    required Map<String, dynamic>? diagnosisData,
    XFile? imageFile,
    String? imageUrl,
    String? scanId,
  }) async {
    final pdfBytes = await generatePdfReport(
      context: context,
      diagnosisData: diagnosisData,
      imageFile: imageFile,
      imageUrl: imageUrl,
      scanId: scanId,
    );

    final String reportName = scanId != null && scanId.isNotEmpty
        ? 'Kisaan_Mitra_Pest_Report_${scanId.replaceAll('scan_', '')}.pdf'
        : 'Kisaan_Mitra_Pest_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';

    try {
      if (!kIsWeb) {
        final outputDir = await getApplicationDocumentsDirectory();
        final file = File('${outputDir.path}/$reportName');
        await file.writeAsBytes(pdfBytes);
      }

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: reportName,
      );
    } catch (e) {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: reportName,
      );
    }
  }

  /// Loads image bytes from XFile, URL, or fallback.
  static Future<Uint8List?> _loadCropImageBytes({
    XFile? imageFile,
    String? imageUrl,
  }) async {
    if (imageFile != null) {
      try {
        return await imageFile.readAsBytes();
      } catch (_) {}
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final fullUrl = imageUrl.startsWith('http') ? imageUrl : '${ApiService.baseUrl}$imageUrl';
        final response = await http.get(Uri.parse(fullUrl));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
      } catch (_) {}
    }

    return null;
  }

  // PDF Widget Helpers
  static pw.Widget _buildHeaderBadge(String label, String value, pw.Font mainFont, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('F1F5F9'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('E2E8F0'), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(font: mainFont, fontSize: 7.5, color: PdfColor.fromHex('64748B'))),
          pw.SizedBox(height: 1),
          pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: PdfColor.fromHex('0F172A'), fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }


  static pw.Widget _buildPdfCheckItem(String label, String value, pw.Font mainFont, pw.Font boldFont, PdfColor labelColor, PdfColor valColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 14,
            height: 14,
            margin: const pw.EdgeInsets.only(right: 6, top: 1),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('DCFCE7'),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.SvgImage(svg: checkSvg, width: 8, height: 8),
            ),
          ),
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(text: '$label: ', style: pw.TextStyle(font: mainFont, fontSize: 8.5, color: labelColor)),
                  pw.TextSpan(text: value, style: pw.TextStyle(font: boldFont, fontSize: 8.5, color: valColor, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSeverityColumn(String svgIcon, String val, String sub, pw.Font mainFont, pw.Font boldFont, PdfColor darkNavy, PdfColor textGrey) {
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Container(
          width: 24,
          height: 24,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('DCFCE7'),
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(child: pw.SvgImage(svg: svgIcon, width: 12, height: 12)),
        ),
        pw.SizedBox(height: 4),
        pw.Text(val, style: pw.TextStyle(font: boldFont, fontSize: 9.5, color: darkNavy, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 1),
        pw.Text(sub, style: pw.TextStyle(font: mainFont, fontSize: 7.5, color: textGrey)),
      ],
    );
  }

  static pw.Widget _buildPdfProductCard(String name, String dosage, pw.Font mainFont, pw.Font boldFont, PdfColor darkNavy, PdfColor textGrey, PdfColor border) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('FAFAFA'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: border, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 22,
            height: 22,
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('DCFCE7'), shape: pw.BoxShape.circle),
            child: pw.Center(child: pw.SvgImage(svg: leafSvg, width: 12, height: 12)),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(name, style: pw.TextStyle(font: boldFont, fontSize: 9, color: darkNavy, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 1),
                pw.Text(dosage, style: pw.TextStyle(font: mainFont, fontSize: 8, color: textGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTipBox(String svgIcon, String tipText, pw.Font mainFont, PdfColor darkNavy, PdfColor border) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('FAFAFA'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: border, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 20,
            height: 20,
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('DCFCE7'), shape: pw.BoxShape.circle),
            child: pw.Center(child: pw.SvgImage(svg: svgIcon, width: 10, height: 10)),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(tipText, style: pw.TextStyle(font: mainFont, fontSize: 8.5, color: darkNavy, lineSpacing: 1.25)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildBenefitItem(String svgIcon, String title, String sub, pw.Font mainFont, pw.Font boldFont, PdfColor darkNavy, PdfColor textGrey) {
    return pw.Column(
      children: [
        pw.Container(
          width: 22,
          height: 22,
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('DCFCE7'), shape: pw.BoxShape.circle),
          child: pw.Center(child: pw.SvgImage(svg: svgIcon, width: 11, height: 11)),
        ),
        pw.SizedBox(height: 3),
        pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 8, color: darkNavy, fontWeight: pw.FontWeight.bold)),
        pw.Text(sub, style: pw.TextStyle(font: mainFont, fontSize: 7, color: textGrey)),
      ],
    );
  }

  /// Loads TTF font supporting full Unicode for English, Hindi, and Marathi Devanagari script.
  static Future<pw.Font> _getFont({required bool isBold, required bool isDevanagari}) async {
    try {
      if (isDevanagari) {
        return isBold
            ? await PdfGoogleFonts.notoSansDevanagariBold()
            : await PdfGoogleFonts.notoSansDevanagariRegular();
      } else {
        return isBold
            ? await PdfGoogleFonts.notoSansBold()
            : await PdfGoogleFonts.notoSansRegular();
      }
    } catch (_) {
      try {
        final url = isDevanagari
            ? (isBold
                ? 'https://cdn.jsdelivr.net/fontsource/fonts/noto-sans-devanagari@latest/700.ttf'
                : 'https://cdn.jsdelivr.net/fontsource/fonts/noto-sans-devanagari@latest/400.ttf')
            : (isBold
                ? 'https://cdn.jsdelivr.net/fontsource/fonts/noto-sans@latest/700.ttf'
                : 'https://cdn.jsdelivr.net/fontsource/fonts/noto-sans@latest/400.ttf');
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          return pw.Font.ttf(res.bodyBytes.buffer.asByteData());
        }
      } catch (_) {}
    }
    return isBold ? pw.Font.helveticaBold() : pw.Font.helvetica();
  }

}
