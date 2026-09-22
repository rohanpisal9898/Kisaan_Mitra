import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../services/auth_session_manager.dart';
import 'farmer_profile_screen.dart';
import 'dashboard_screen.dart';

/// Clean mobile-first farmer profile page for Kisaan Mitra.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User profile data state
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;
  String? _userPhone;

  // Expansion state for Language card (only dropdown)
  bool _isLanguageExpanded = false;

  final List<Map<String, String>> _languages = const [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी'},
    {'code': 'mr', 'name': 'Marathi', 'native': 'मराठी'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _userPhone = await AuthSessionManager.getUserPhone();

      // First try validating session to get fresh profile data
      Map<String, dynamic>? data = await ApiService.validateSession();
      
      // Fallback to phone-based fetch or cached data if offline
      if (data == null && _userPhone != null && _userPhone!.isNotEmpty) {
        data = await ApiService.getUser(_userPhone!);
      }
      data ??= await AuthSessionManager.getCachedUserProfile();

      if (!mounted) return;

      if (data != null) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User profile data could not be found.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      String err = 'Unable to load profile. Please check network connection.';
      final errStr = e.toString();
      if (errStr.contains('SocketException') ||
          errStr.contains('Failed host lookup')) {
        err = 'Unable to connect to server. Please check your connection.';
      }
      setState(() {
        _isLoading = false;
        _errorMessage = err;
      });
    }
  }

  Future<void> _changeLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);

    if (!mounted) return;
    KisaanMitraApp.setLocale(context, Locale(langCode));

    setState(() {
      _isLanguageExpanded = false;
    });

    // Update language on backend asynchronously
    if (_userPhone != null && _userPhone!.isNotEmpty) {
      try {
        await ApiService.updateUser(_userPhone!, {'language': langCode});
      } catch (e) {
        debugPrint('Failed to update language on backend: $e');
      }
    }
  }

  String _formatSowingDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('d MMM yyyy').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  String _formatArea(dynamic area, String? unit) {
    if (area == null) return '-';
    final formattedUnit = (unit != null && unit.isNotEmpty)
        ? '${unit[0].toUpperCase()}${unit.substring(1)}'
        : 'Acres';
    return '$area $formattedUnit';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLangCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: _isLoading
          ? _buildLoadingState(l10n)
          : _errorMessage != null
              ? _buildErrorState(l10n)
              : _buildProfileContent(l10n, currentLangCode),
    );
  }

  // ─── LOADING STATE ──────────────────────────────────────────────────
  Widget _buildLoadingState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.loading,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ERROR STATE ────────────────────────────────────────────────────
  Widget _buildErrorState(AppLocalizations l10n) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? l10n.error,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchUserProfile,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── MAIN PROFILE CONTENT ───────────────────────────────────────────
  Widget _buildProfileContent(AppLocalizations l10n, String currentLangCode) {
    final farmerName = _userData?['farmer_name'] ?? '-';
    final currentCrop = _userData?['current_crop'] ?? '';
    final district = _userData?['district'] ?? '';
    final state = _userData?['state'] ?? '';
    final village = _userData?['village'] ?? '-';
    final phone = _userData?['phone_number'] ?? '-';
    final farmArea = _userData?['farm_area'];
    final farmAreaUnit = _userData?['farm_area_unit'];
    final sowingDate = _userData?['sowing_date'];

    final locationText = [district.toString(), state.toString()]
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
    final subtitleText = currentCrop.toString().isNotEmpty
        ? '$currentCrop ${l10n.farmerRole}'
        : l10n.farmerRole;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // ─── HEADER AREA ─────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D5A1E), // Dark green top
                  Color(0xFF1A3A0F), // Darker green bottom
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  children: [
                    // Top Row: Back Button & Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profileTitle,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: l10n.navHome,
                          icon: const Icon(Icons.home_outlined, color: Colors.white),
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => DashboardScreen(
                                    language: currentLangCode,
                                    phoneNumber: _userPhone,
                                  ),
                                ),
                              );
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Leaf Icon Container (No Photograph)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryLight,
                          width: 2.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.eco,
                          color: AppColors.primaryLight,
                          size: 42,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Farmer Name
                    Text(
                      farmerName,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Subtitle: Crop
                    Text(
                      subtitleText,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),

                    if (locationText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: AppColors.primaryLight,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              locationText,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ─── CARDS CONTAINER ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                // 1. FARMER DETAILS CARD (STATIC - NOT EXPANDABLE)
                _buildStaticCard(
                  icon: Icons.person_outline,
                  title: l10n.farmerDetails,
                  children: [
                    _buildDetailRow(l10n.nameLabel, farmerName),
                    _buildDivider(),
                    _buildDetailRow(l10n.phoneNumber, phone),
                    _buildDivider(),
                    _buildDetailRow(l10n.village, village.isNotEmpty ? village : '-'),
                  ],
                ),

                const SizedBox(height: 14),

                // 2. FARM INFORMATION CARD (STATIC - NOT EXPANDABLE)
                _buildStaticCard(
                  icon: Icons.agriculture,
                  iconBgColor: const Color(0xFFB8F23D),
                  iconColor: const Color(0xFF16834A),
                  title: l10n.farmInformation,
                  children: [
                    _buildDetailRow(l10n.state, state.isNotEmpty ? state : '-'),
                    _buildDivider(),
                    _buildDetailRow(l10n.district, district.isNotEmpty ? district : '-'),
                    _buildDivider(),
                    _buildDetailRow(l10n.cropType, currentCrop.isNotEmpty ? currentCrop : '-'),
                    _buildDivider(),
                    _buildDetailRow(l10n.farmArea, _formatArea(farmArea, farmAreaUnit)),
                    _buildDivider(),
                    _buildDetailRow(l10n.sowingDate, _formatSowingDate(sowingDate?.toString())),
                  ],
                ),

                const SizedBox(height: 14),

                // 3. LANGUAGE CARD (ONLY DROPDOWN)
                _buildLanguageCard(l10n, currentLangCode),

                const SizedBox(height: 14),

                // 4. SIGN OUT CARD
                _buildSignOutCard(l10n),

                const SizedBox(height: 14),

                // 5. DELETE ACCOUNT CARD
                _buildDeleteAccountCard(l10n),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATIC INFORMATION CARD (NO CHEVRON, NOT EXPANDABLE) ─────────
  Widget _buildStaticCard({
    required IconData icon,
    Color iconBgColor = const Color(0xFFDCFCE7),
    Color iconColor = const Color(0xFF15803D),
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // ─── 3. LANGUAGE CARD (ONLY DROPDOWN) ────────────────────────────
  Widget _buildLanguageCard(AppLocalizations l10n, String currentLangCode) {
    final currentLangMap = _languages.firstWhere(
      (l) => l['code'] == currentLangCode,
      orElse: () => _languages.first,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isLanguageExpanded = !_isLanguageExpanded;
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.language,
                      color: Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferred Language',
                          style: GoogleFonts.inter(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${currentLangMap['name']} (${currentLangMap['native']})',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isLanguageExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isLanguageExpanded) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: _languages.map((lang) {
                  final isSelected = lang['code'] == currentLangCode;
                  return InkWell(
                    onTap: () => _changeLanguage(lang['code']!),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.chipBg
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${lang['name']} (${lang['native']})',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.chipText
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check,
                              color: AppColors.primary,
                              size: 18,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 4. SIGN OUT CARD ────────────────────────────────────────────
  Widget _buildSignOutCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showSignOutConfirmationDialog(l10n),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Color(0xFFDC2626),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n.signOut,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 5. DELETE ACCOUNT CARD ──────────────────────────────────────
  Widget _buildDeleteAccountCard(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA), width: 1),
      ),
      child: InkWell(
        onTap: () => _showDeleteAccountConfirmationDialog(l10n),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_forever_outlined,
                  color: Color(0xFFDC2626),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Delete Account',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFDC2626),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutConfirmationDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            l10n.signOutConfirmTitle,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            l10n.signOutConfirmMessage,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                l10n.cancelBtn,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _handleSignOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.signOut,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountConfirmationDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Account?',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFDC2626),
            ),
          ),
          content: Text(
            'This action is permanent and will delete all your farm data, scan history, and account records. Are you sure?',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                l10n.cancelBtn,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _handleDeleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Delete Permanently',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSignOut() async {
    final currentLangCode = Localizations.localeOf(context).languageCode;
    await AuthSessionManager.clearSession();

    if (!mounted) return;

    // Navigate to Login screen and remove back stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => FarmerProfileScreen(
          language: currentLangCode,
          isSignInMode: true,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _handleDeleteAccount() async {
    final currentLangCode = Localizations.localeOf(context).languageCode;
    try {
      await ApiService.deleteAccount();
    } catch (e) {
      debugPrint('[DELETE ACCOUNT ERROR] $e');
    }
    await AuthSessionManager.clearSession();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your account and data have been permanently deleted.'),
        backgroundColor: Color(0xFFDC2626),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => FarmerProfileScreen(
          language: currentLangCode,
          isSignInMode: true,
        ),
      ),
      (route) => false,
    );
  }

  // ─── HELPER ROW WIDGETS ──────────────────────────────────────────
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              softWrap: true,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.divider,
    );
  }
}
