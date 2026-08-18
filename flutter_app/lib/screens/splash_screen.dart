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
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final imageCacheWidth =
        (mediaQuery.size.width * mediaQuery.devicePixelRatio).round();
    final imageCacheHeight =
        (screenHeight * mediaQuery.devicePixelRatio).round();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Keep the approved dark background visible below the hero image.
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

          // Full-screen farmer/farm photography. Cover preserves the photo's
          // aspect ratio while filling every mobile screen size.
          Positioned.fill(
            child: Image.asset(
              'assets/images/farmer_hero.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              cacheWidth: imageCacheWidth,
              cacheHeight: imageCacheHeight,
              filterQuality: FilterQuality.low,
            ),
          ),

          // Fade the photograph into the existing dark palette for readability.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      const Color(0xFF0D1F08).withValues(alpha: 0.72),
                      const Color(0xFF050B03).withValues(alpha: 0.98),
                    ],
                    stops: const [0.0, 0.36, 0.68, 1.0],
                  ),
                ),
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

                  // The reference-matched hero asset already carries the
                  // approved logo/name at this position.
                  const SizedBox(height: 40),

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
