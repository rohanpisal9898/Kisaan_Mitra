import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'profile_screen.dart';

/// Dashboard screen - main app screen after onboarding.
/// Placeholder for now, will be expanded with weather, yield, tasks, etc.
class DashboardScreen extends StatefulWidget {
  final String language;

  const DashboardScreen({super.key, required this.language});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late AppLocalizations _l10n;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _l10n = AppLocalizations(widget.language);
  }

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: _currentIndex == 3
          ? const ProfileScreen()
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Top bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _l10n.appName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.chipBg,
                        child: Icon(
                          Icons.person,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Welcome card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D5A1E), Color(0xFF1A3A0F)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌾 ${_l10n.get("welcome")}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your AI farming assistant is ready.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick actions grid
              Text(
                'Quick Actions',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildQuickAction(
                      Icons.wb_sunny_outlined,
                      'Weather',
                      'Today\'s forecast',
                      const Color(0xFFFFF7ED),
                      AppColors.warning,
                    ),
                    _buildQuickAction(
                      Icons.eco_outlined,
                      'Soil Health',
                      'NPK analysis',
                      const Color(0xFFECFCCB),
                      AppColors.primary,
                    ),
                    _buildQuickAction(
                      Icons.show_chart,
                      'Yield',
                      'Prediction',
                      const Color(0xFFEFF6FF),
                      AppColors.info,
                    ),
                    _buildQuickAction(
                      Icons.task_alt,
                      'Tasks',
                      'Today\'s tasks',
                      const Color(0xFFF0FDF4),
                      AppColors.accent,
                    ),
                    _buildQuickAction(
                      Icons.bug_report_outlined,
                      'Pest Alert',
                      'Risk status',
                      const Color(0xFFFEF2F2),
                      AppColors.error,
                    ),
                    _buildQuickAction(
                      Icons.attach_money,
                      'Market',
                      'Mandi prices',
                      const Color(0xFFFAF5FF),
                      const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: _l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bug_report_outlined),
              activeIcon: const Icon(Icons.bug_report),
              label: _l10n.navPest,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              activeIcon: const Icon(Icons.account_balance_wallet),
              label: _l10n.navWallet,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: _l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String title,
    String subtitle,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
