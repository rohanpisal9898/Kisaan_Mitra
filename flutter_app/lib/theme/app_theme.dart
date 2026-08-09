import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kisaan Mitra color palette - fresh agricultural greens with premium feel.
class AppColors {
  // Primary greens
  static const Color primary = Color(0xFF7CB518);       // Bright lime green (CTA buttons)
  static const Color primaryDark = Color(0xFF5A8A0F);   // Darker green
  static const Color primaryLight = Color(0xFFB5E655);  // Light lime

  // Backgrounds
  static const Color bgLight = Color(0xFFF7F7F2);       // Off-white warm background
  static const Color bgCard = Color(0xFFFFFFFF);         // Card white
  static const Color bgDark = Color(0xFF1A1A1A);         // Dark mode bg

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);    // Near black
  static const Color textSecondary = Color(0xFF6B7280);  // Gray-500
  static const Color textLight = Color(0xFFFFFFFF);      // White text

  // Accents
  static const Color accent = Color(0xFF22C55E);         // Green accent
  static const Color warning = Color(0xFFF59E0B);        // Amber warning
  static const Color error = Color(0xFFEF4444);          // Red error
  static const Color info = Color(0xFF3B82F6);           // Blue info

  // Borders & dividers
  static const Color border = Color(0xFFE5E7EB);        // Light gray border
  static const Color divider = Color(0xFFF3F4F6);       // Subtle divider

  // Chip/tag backgrounds
  static const Color chipBg = Color(0xFFECFCCB);        // Light lime chip bg
  static const Color chipText = Color(0xFF3F6212);       // Dark green chip text
}

/// App-wide theme data.
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.bgLight,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
