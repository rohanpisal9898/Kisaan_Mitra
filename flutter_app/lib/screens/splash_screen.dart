import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'language_screen.dart';

/// Splash / Welcome screen.
/// Shows hero image with "Farm Smarter. Harvest Better." and Get Started button.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient (simulating the plant/crop image)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D5A1E),  // Deep green top
                  Color(0xFF1A3A0F),  // Darker green
                  Color(0xFF0D1F08),  // Very dark bottom
                ],
              ),
            ),
          ),

          // Overlay pattern for depth
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.withValues(alpha: 0.15),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // App logo/name
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Kisaan Mitra',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Main heading
                  Text(
                    'Farm Smarter.\nHarvest Better.',
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'AI-powered tools for smarter farming',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Get Started button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LanguageScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Get Started',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
