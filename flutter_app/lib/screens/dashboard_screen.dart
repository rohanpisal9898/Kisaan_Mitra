import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sown_dashboard_model.dart';
import '../services/api_service.dart';

import '../widgets/dashboard_header.dart';
import '../widgets/weather_card.dart';
import '../widgets/crop_stage_card.dart';
import '../widgets/water_status_card.dart';
import '../widgets/crop_health_card.dart';
import '../widgets/yield_prediction_card.dart';
import '../widgets/recommendations_card.dart';

import 'profile_screen.dart';
import 'pest_detection_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String language;
  final String? phoneNumber;

  const DashboardScreen({
    super.key,
    required this.language,
    this.phoneNumber,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  bool _isLoading = true;
  String? _errorMessage;
  SownDashboardModel? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? phone = widget.phoneNumber;
      if (phone == null || phone.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        phone = prefs.getString('user_phone');
      }

      final jsonResponse = await ApiService.fetchSownDashboard(
        phoneNumber: phone,
        language: widget.language,
      );
      final model = SownDashboardModel.fromJson(jsonResponse);

      if (!mounted) return;
      setState(() {
        _dashboardData = model;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load farm dashboard data.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _currentIndex == 1
          ? const PestDetectionScreen()
          : _currentIndex == 3
              ? const ProfileScreen()
              : SafeArea(
                  child: RefreshIndicator(
                    onRefresh: _loadDashboardData,
                    color: const Color(0xFF15803D),
                    child: _buildDashboardContent(),
                  ),
                ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
          onTap: (index) {
            setState(() => _currentIndex = index);
            if (index == 0) {
              // Reload dashboard data when tapping Home tab
              _loadDashboardData();
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF15803D),
          unselectedItemColor: const Color(0xFF94A3B8),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bug_report_outlined),
              activeIcon: Icon(Icons.bug_report),
              label: 'Pest',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF15803D),
        ),
      );
    }

    if (_errorMessage != null || _dashboardData == null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to connect to backend',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your network or backend server and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loadDashboardData,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  'Retry',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final data = _dashboardData!;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Greeting + Location)
          DashboardHeaderWidget(
            farmer: data.farmer,
            onNotificationTap: () {},
            onProfileTap: () => setState(() => _currentIndex = 3),
          ),
          const SizedBox(height: 20),

          // 2. Weather Card
          WeatherCardWidget(weather: data.weather),
          const SizedBox(height: 16),

          // 3. Grid Row: Crop Stage Card & Water Status Card
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CropStageCardWidget(cropStage: data.cropStage),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: WaterStatusCardWidget(water: data.water),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. Crop Health Card
          CropHealthCardWidget(health: data.cropHealth),
          const SizedBox(height: 16),

          // 5. Expected Yield Prediction Card (CatBoost)
          YieldPredictionCardWidget(yieldData: data.yieldPrediction),
          const SizedBox(height: 22),

          // 6. Top Recommendations (Gemini AI / Fallback)
          RecommendationsCardWidget(recommendations: data.recommendations),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
