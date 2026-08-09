import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'farmer_profile_screen.dart';

/// Language selection screen.
/// 3 languages only: English, Hindi, Marathi.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selectedLanguage = 'en';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'native': 'English', 'flag': '🇬🇧'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी', 'flag': '🇮🇳'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back_ios, size: 20),
              ),

              const SizedBox(height: 24),

              // Header
              Text(
                'Choose Language',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick your preferred language',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // Language cards grid
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: _languages.map((lang) {
                      final isSelected = _selectedLanguage == lang['code'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedLanguage = lang['code']!;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Flag
                                      Text(
                                        lang['flag']!,
                                        style: const TextStyle(fontSize: 26),
                                      ),
                                      const SizedBox(height: 6),

                                      // Native name
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          lang['native']!,
                                          style: GoogleFonts.inter(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),

                                      // English name
                                      Text(
                                        lang['name']!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: isSelected
                                              ? Colors.white.withValues(alpha: 0.85)
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Selected checkmark at top right
                              if (isSelected)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    // Save language preference
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('language', _selectedLanguage);

                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FarmerProfileScreen(
                          language: _selectedLanguage,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
