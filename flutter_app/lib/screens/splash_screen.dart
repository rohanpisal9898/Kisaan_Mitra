import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/auth_session_manager.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'language_screen.dart';
import 'dashboard_screen.dart';

/// Splash / Welcome screen.
/// Automatically restores active authenticated sessions instantly on startup.
/// Shows hero image with "Farm Smarter. Harvest Better." and Get Started button for new users.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    AuthSessionManager().initialize();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    try {
      final token = await AuthSessionManager.getAccessToken();
      final cachedUser = await AuthSessionManager.getCachedUserProfile();

      // If credentials exist locally, enter the app immediately using the cached profile
      if (token != null && token.isNotEmpty && cachedUser != null) {
        final lang = cachedUser['language']?.toString() ?? 'en';
        final phone = cachedUser['phone_number']?.toString();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language', lang);
        if (phone != null) {
          await prefs.setString('user_phone', phone);
        }

        // Fire asynchronous background session validation without delaying UI
        unawaited(_validateSessionInBackground());

        if (mounted) {
          KisaanMitraApp.setLocale(context, Locale(lang));
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DashboardScreen(
                language: lang,
                phoneNumber: phone,
              ),
            ),
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('[SPLASH SESSION RESTORATION ERROR] $e');
    }

    if (mounted) {
      setState(() {
        _isCheckingSession = false;
      });
    }
  }

  Future<void> _validateSessionInBackground() async {
    try {
      final freshUser = await ApiService.validateSession();
      if (freshUser != null) {
        final token = await AuthSessionManager.getAccessToken();
        final rToken = await AuthSessionManager.getRefreshToken();
        if (token != null && rToken != null) {
          await AuthSessionManager.saveSession(
            accessToken: token,
            refreshToken: rToken,
            user: freshUser,
          );
        }
      }
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('401') || errStr.contains('unauthorized') || errStr.contains('user_not_found')) {
        debugPrint('[BACKGROUND SESSION VALIDATION] Revoked session. Clearing credentials.');
        await AuthSessionManager.clearSession();
      }
      // Temporary network error / offline: do not log user out
    }
  }

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

          // Full-screen farmer/farm photography.
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

                  // Get Started button or Loading Spinner
                  if (_isCheckingSession)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                    )
                  else
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
