import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
import '../widgets/planning_dashboard_card.dart';
import '../widgets/top_crop_recommendations_card.dart';

import 'profile_screen.dart';
import 'pest_detection_screen.dart';
import 'farmer_wallet_screen.dart';

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
  DashboardOverviewModel? _overviewData;

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

      final jsonResponse = await ApiService.fetchDashboardOverview(
        phoneNumber: phone,
        language: widget.language,
      );
      final model = DashboardOverviewModel.fromJson(jsonResponse);

      if (!mounted) return;
      setState(() {
        _overviewData = model;
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

  void _showSowingDateSelectionModal(TopCropRecommendationModel item) {
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        item.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Plan ${item.crop}',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '📅 Recommended Sowing: ${item.recommendedSowing}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Select Sowing Date',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 90)),
                        lastDate: DateTime.now().add(const Duration(days: 180)),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd MMMM yyyy').format(selectedDate),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF15803D)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);

                        String? phone = widget.phoneNumber;
                        if (phone == null || phone.isEmpty) {
                          final prefs = await SharedPreferences.getInstance();
                          phone = prefs.getString('user_phone');
                        }

                        if (phone != null && phone.isNotEmpty) {
                          try {
                            final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
                            await ApiService.updateUser(phone, {
                              'current_crop': item.crop,
                              'sowing_date': formattedDate,
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🌾 Switched active crop to ${item.crop}!'),
                                  backgroundColor: const Color(0xFF15803D),
                                ),
                              );
                              _loadDashboardData();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update crop: $e'),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      label: Text(
                        'Confirm & Start Growing',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _currentIndex == 1
          ? const PestDetectionScreen()
          : _currentIndex == 2
              ? FarmerWalletScreen(phoneNumber: widget.phoneNumber)
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

    if (_errorMessage != null || _overviewData == null) {
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

    final overview = _overviewData!;

    // 1. Growing State (Sown Dashboard)
    if (overview.dashboardState == 'growing' && overview.sownDashboard != null) {
      final data = overview.sownDashboard!;
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeaderWidget(
              farmer: data.farmer,
              crop: data.crop,
              onNotificationTap: () {},
              onProfileTap: () => setState(() => _currentIndex = 3),
            ),
            const SizedBox(height: 20),
            WeatherCardWidget(weather: data.weather),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: CropStageCardWidget(cropStage: data.cropStage)),
                const SizedBox(width: 14),
                Expanded(child: WaterStatusCardWidget(water: data.water)),
              ],
            ),
            const SizedBox(height: 16),
            CropHealthCardWidget(health: data.cropHealth),
            const SizedBox(height: 16),
            YieldPredictionCardWidget(yieldData: data.yieldPrediction),
            const SizedBox(height: 22),
            RecommendationsCardWidget(recommendations: data.recommendations),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    // 2. Planning State (No-Crop or Crop Matured)
    final topRecs = overview.topRecommendationsJson
        .map((j) => TopCropRecommendationModel.fromJson(j))
        .toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Greeting + Location + No-Crop / Crop Badge)
          DashboardHeaderWidget(
            farmer: overview.farmer,
            crop: overview.dashboardState == 'crop_matured' && overview.previousCrop != null
                ? CropInfoModel(id: '', name: overview.previousCrop!.name, sowingDate: overview.previousCrop!.sowingDate)
                : null,
            onNotificationTap: () {},
            onProfileTap: () => setState(() => _currentIndex = 3),
          ),
          const SizedBox(height: 20),

          // 2. Weather Card
          WeatherCardWidget(weather: overview.weather),
          const SizedBox(height: 16),

          // 3. No-Crop Banner Card or Maturity Transition Card
          PlanningDashboardCardWidget(
            dashboardState: overview.dashboardState,
            previousCropName: overview.previousCrop?.name,
            onPlanCropTap: () => setState(() => _currentIndex = 3),
          ),
          const SizedBox(height: 22),

          // 4. ⭐ Top Crop Recommendations
          TopCropRecommendationsCardWidget(
            recommendations: topRecs,
            onCropSelected: (selectedItem) => _showSowingDateSelectionModal(selectedItem),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
