import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
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
import 'government_schemes_screen.dart';

class _SupportedCropItem {
  final String cropId;
  final String name;
  final String icon;
  final String sowingWindow;

  const _SupportedCropItem({
    required this.cropId,
    required this.name,
    required this.icon,
    required this.sowingWindow,
  });
}

const List<_SupportedCropItem> _allSupportedCrops = [
  _SupportedCropItem(cropId: 'groundnut', name: 'Groundnut', icon: '🌿', sowingWindow: 'June – July'),
  _SupportedCropItem(cropId: 'soybean', name: 'Soybean', icon: '🌱', sowingWindow: 'June – July'),
  _SupportedCropItem(cropId: 'castor', name: 'Castor seed', icon: '🌱', sowingWindow: 'July – August'),
  _SupportedCropItem(cropId: 'sunflower', name: 'Sunflower', icon: '🌻', sowingWindow: 'June – July'),
  _SupportedCropItem(cropId: 'sesame', name: 'Sesamum', icon: '🌿', sowingWindow: 'June – July'),
  _SupportedCropItem(cropId: 'rapeseed_mustard', name: 'Rapeseed &Mustard', icon: '🌾', sowingWindow: 'October – November'),
  _SupportedCropItem(cropId: 'linseed', name: 'Linseed', icon: '🌿', sowingWindow: 'October – November'),
  _SupportedCropItem(cropId: 'safflower', name: 'Safflower', icon: '🌼', sowingWindow: 'September – October'),
  _SupportedCropItem(cropId: 'niger', name: 'Niger seed', icon: '🌻', sowingWindow: 'June – July'),
];

String _normalizeCropId(String cropIdOrName) {
  final lower = cropIdOrName.toLowerCase().trim();
  if (lower == 'soyabean' || lower == 'soya bean') return 'soybean';
  if (lower == 'castor seed') return 'castor';
  if (lower == 'sesamum' || lower == 'til') return 'sesame';
  if (lower.contains('mustard') || lower.contains('rapeseed')) return 'rapeseed_mustard';
  if (lower == 'niger seed') return 'niger';
  return lower;
}

String _getLocalizedCropName(AppLocalizations l10n, String cropId) {
  final c = _normalizeCropId(cropId);
  final lang = l10n.languageCode;
  if (c == 'groundnut') return lang == 'hi' ? 'मूंगफली' : lang == 'mr' ? 'भुईमूग' : 'Groundnut';
  if (c == 'soybean') return lang == 'hi' ? 'सोयाबीन' : lang == 'mr' ? 'सोयाबीन' : 'Soybean';
  if (c == 'castor') return lang == 'hi' ? 'अरंडी' : lang == 'mr' ? 'एरंडी' : 'Castor seed';
  if (c == 'sunflower') return lang == 'hi' ? 'सूरजमुखी' : lang == 'mr' ? 'सूर्यफूल' : 'Sunflower';
  if (c == 'sesame') return lang == 'hi' ? 'तिल' : lang == 'mr' ? 'तीळ' : 'Sesamum';
  if (c == 'rapeseed_mustard') return lang == 'hi' ? 'सरसों / रायडा' : lang == 'mr' ? 'मोहरी' : 'Rapeseed & Mustard';
  if (c == 'linseed') return lang == 'hi' ? 'अलसी' : lang == 'mr' ? 'जवस' : 'Linseed';
  if (c == 'safflower') return lang == 'hi' ? 'कुसुम' : lang == 'mr' ? 'करडई' : 'Safflower';
  if (c == 'niger') return lang == 'hi' ? 'रामतिल' : lang == 'mr' ? 'कारळा' : 'Niger seed';
  return cropId;
}

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
  String? _activeLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLang = Localizations.localeOf(context).languageCode;
    if (_activeLanguage != currentLang) {
      _activeLanguage = currentLang;
      _loadDashboardData();
    }
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

      final activeLang = _activeLanguage ?? widget.language;
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_dashboard_${phone ?? "guest"}';

      // Load cached local data instantly if present for instant rendering
      final cachedJsonStr = prefs.getString(cacheKey);
      if (cachedJsonStr != null && cachedJsonStr.isNotEmpty && _overviewData == null) {
        try {
          final cachedMap = json.decode(cachedJsonStr);
          setState(() {
            _overviewData = DashboardOverviewModel.fromJson(cachedMap);
            _isLoading = false;
          });
        } catch (_) {}
      }

      final jsonResponse = await ApiService.fetchDashboardOverview(
        phoneNumber: phone,
        language: activeLang,
      );
      final model = DashboardOverviewModel.fromJson(jsonResponse);

      // Persist updated JSON response to local storage
      await prefs.setString(cacheKey, json.encode(jsonResponse));

      if (!mounted) return;
      setState(() {
        _overviewData = model;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_overviewData == null) {
          _errorMessage = 'Failed to load farm dashboard data.';
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _openProfileScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    if (mounted) {
      _loadDashboardData();
    }
  }

  void _showSowingDateSelectionModal(TopCropRecommendationModel item) {
    final l10n = AppLocalizations.of(context);
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      Expanded(
                        child: Text(
                          '${l10n.planCrop} ${item.crop}',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
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
                      '📅 ${l10n.recommendedSowing}: ${item.recommendedSowing}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.selectSowingDate,
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
                        final messenger = ScaffoldMessenger.of(context);
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
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('🌾 ${l10n.switchedCropSuccess} ${item.crop}!'),
                                  backgroundColor: const Color(0xFF15803D),
                                ),
                              );
                              _loadDashboardData();
                            }
                          } catch (e) {
                            if (mounted) {
                              messenger.showSnackBar(
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
                        l10n.confirmStartGrowing,
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

  void _showOtherCropSelectionModal(List<TopCropRecommendationModel> recommendations) {
    final l10n = AppLocalizations.of(context);
    final recIds = recommendations.map((r) => _normalizeCropId(r.cropId)).toSet();
    final availableCrops = _allSupportedCrops
        .where((c) => !recIds.contains(_normalizeCropId(c.cropId)))
        .toList();

    _SupportedCropItem? selectedCrop;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.selectCropTitle,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.selectCropSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (availableCrops.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        l10n.noOtherCrops,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ] else ...[
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: availableCrops.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = availableCrops[index];
                          final isSelected = selectedCrop?.cropId == item.cropId;
                          final localizedName = _getLocalizedCropName(l10n, item.cropId);

                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedCrop = item;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF15803D) : const Color(0xFFCBD5E1),
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(item.icon, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          localizedName,
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '📅 ${l10n.recommendedSowing}: ${item.sowingWindow}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF64748B),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    color: isSelected ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D),
                          disabledBackgroundColor: const Color(0xFFCBD5E1),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: selectedCrop == null
                            ? null
                            : () {
                                final chosen = selectedCrop!;
                                Navigator.pop(context);
                                final model = TopCropRecommendationModel(
                                  rank: 0,
                                  crop: chosen.name,
                                  cropId: chosen.cropId,
                                  icon: chosen.icon,
                                  score: 0,
                                  suitabilityPercentage: '',
                                  netReturnFormatted: '',
                                  waterLevel: '',
                                  waterRequirementFormatted: '',
                                  recommendedSowing: chosen.sowingWindow,
                                );
                                _showSowingDateSelectionModal(model);
                              },
                        icon: Icon(
                          Icons.arrow_forward_rounded,
                          color: selectedCrop == null ? const Color(0xFF94A3B8) : Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          l10n.continueBtn,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: selectedCrop == null ? const Color(0xFF94A3B8) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: const Color(0xFF15803D),
              child: _buildDashboardContent(l10n),
            ),
          ),
          const PestDetectionScreen(),
          FarmerWalletScreen(phoneNumber: widget.phoneNumber),
          const GovernmentSchemesScreen(),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
            selectedLabelStyle: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.1,
            ),
            unselectedLabelStyle: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              height: 1.1,
            ),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: l10n.navHome,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.bug_report_outlined),
                activeIcon: const Icon(Icons.bug_report),
                label: l10n.navPest,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                activeIcon: const Icon(Icons.account_balance_wallet),
                label: l10n.navWallet,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.account_balance_outlined),
                activeIcon: const Icon(Icons.account_balance),
                label: l10n.navSchemes,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(AppLocalizations l10n) {
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
                l10n.unableConnectBackend,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.checkNetworkBackend,
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
                  l10n.retry,
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
              onProfileTap: _openProfileScreen,
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
            onProfileTap: _openProfileScreen,
          ),
          const SizedBox(height: 20),

          // 2. Weather Card
          WeatherCardWidget(weather: overview.weather),
          const SizedBox(height: 16),

          // 3. No-Crop Banner Card or Maturity Transition Card
          PlanningDashboardCardWidget(
            dashboardState: overview.dashboardState,
            previousCropName: overview.previousCrop?.name,
            onPlanCropTap: _openProfileScreen,
          ),
          const SizedBox(height: 22),

          // 4. ⭐ Top Crop Recommendations
          TopCropRecommendationsCardWidget(
            recommendations: topRecs,
            onCropSelected: (selectedItem) => _showSowingDateSelectionModal(selectedItem),
            onOtherTap: () => _showOtherCropSelectionModal(topRecs),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
