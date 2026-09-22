import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/gps_location_service.dart';
import '../main.dart';
import 'add_farm_screen.dart';
import 'dashboard_screen.dart';

/// Account Details / Sign In screen (Step 1 of 2).
/// Collects: Farmer Name, Phone Number, Password, Village (for registration)
/// or Phone + Password + GPS-detected State & District (for Sign In).
class FarmerProfileScreen extends StatefulWidget {
  final String language;
  final bool isSignInMode;

  const FarmerProfileScreen({
    super.key,
    required this.language,
    this.isSignInMode = false,
  });

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  late AppLocalizations _l10n;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _villageController = TextEditingController();

  bool _isSignInMode = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // ─── Sign-In GPS Location State ──────────────────────────────
  String? _signInState;
  String? _signInDistrict;
  double? _detectedLat;
  double? _detectedLon;
  double? _detectedAccuracy;
  List<String> _states = [];
  List<String> _districts = [];
  bool _loadingStates = false;
  bool _loadingDistricts = false;
  bool _isDetectingLocation = false;
  String? _locationStatusMessage;
  bool _locationDetectedSuccess = false;
  bool _isLocationServiceDisabled = false;
  bool _isPermissionDeniedForever = false;

  @override
  void initState() {
    super.initState();
    _l10n = AppLocalizations(widget.language);
    _isSignInMode = widget.isSignInMode;

    if (_isSignInMode) {
      _fetchStates();
      _detectGpsLocation();
    }
  }

  /// Fetch all available states from FastAPI backend for manual fallback
  Future<void> _fetchStates() async {
    setState(() => _loadingStates = true);
    try {
      final states = await ApiService.fetchStates();
      if (mounted) {
        setState(() {
          _states = states;
          _loadingStates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingStates = false);
      }
    }
  }

  /// Fetch districts for a selected state
  Future<void> _fetchDistricts(String state) async {
    setState(() {
      _loadingDistricts = true;
      _districts = [];
    });

    try {
      final districts = await ApiService.fetchDistricts(state);
      if (mounted) {
        setState(() {
          _districts = districts;
          _loadingDistricts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingDistricts = false);
      }
    }
  }

  /// Exact Sign-In GPS Auto-Detection Flow:
  /// Location Services Check → Runtime Permission → Coordinates → State/District Resolution → Form Population
  Future<void> _detectGpsLocation() async {
    if (_isDetectingLocation) return;

    setState(() {
      _isDetectingLocation = true;
      _locationStatusMessage = null;
      _locationDetectedSuccess = false;
      _isLocationServiceDisabled = false;
      _isPermissionDeniedForever = false;
    });

    final res = await GpsLocationService.detectLocation();

    if (!mounted) return;

    if (res.success && res.state != null && res.district != null) {
      setState(() {
        _signInState = res.state;
        _signInDistrict = res.district;
        _detectedLat = res.latitude;
        _detectedLon = res.longitude;
        _detectedAccuracy = res.accuracy;
        _locationDetectedSuccess = true;
        _isDetectingLocation = false;
        _locationStatusMessage = 'Location detected ✓';
        _isLocationServiceDisabled = false;
        _isPermissionDeniedForever = false;
      });

      // Populate district options for the resolved state
      _fetchDistricts(res.state!);
    } else {
      setState(() {
        _locationDetectedSuccess = false;
        _isDetectingLocation = false;
        _locationStatusMessage = res.errorMessage ?? 'Unable to detect location automatically.';
        _isLocationServiceDisabled = res.isLocationServiceDisabled;
        _isPermissionDeniedForever = res.isPermissionDeniedForever;
      });
    }
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final user = await ApiService.loginUser(
        phoneNumber: phone,
        password: password,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', phone);
      if (user['language'] != null && user['language'].toString().isNotEmpty) {
        await prefs.setString('language', user['language']);
        if (mounted) {
          KisaanMitraApp.setLocale(context, Locale(user['language']));
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, ${user['farmer_name'] ?? 'Farmer'}!'),
          backgroundColor: AppColors.primary,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            language: user['language'] ?? widget.language,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      String errorMsg = 'Could not sign in. Please try again.';
      final errStr = e.toString();

      if (errStr.contains('ACCOUNT_NOT_FOUND')) {
        errorMsg = 'No account found with this phone number. Please create an account first.';
      } else if (errStr.contains('INVALID_PASSWORD')) {
        errorMsg = 'Incorrect password. Please check your password and try again.';
      } else if (errStr.contains('SocketException') || errStr.contains('Failed host lookup') || errStr.contains('ClientException')) {
        errorMsg = 'Unable to connect to server. Please check your network or backend server.';
      } else {
        errorMsg = errStr.replaceAll('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleNextAddFarm() async {
    setState(() {
      _isLoading = true;
    });

    final phone = _phoneController.text.trim();

    try {
      final existingUser = await ApiService.getUser(phone);
      if (existingUser != null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An account with this phone number already exists. Please sign in instead.',
            ),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    } catch (e) {
      // If network error occurs during lookup, proceed and let final registration handle it
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddFarmScreen(
          language: widget.language,
          farmerName: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text.trim(),
          village: _villageController.text.trim(),
        ),
      ),
    );
  }

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

              // Back + Step indicator (only in Register mode)
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_ios, size: 20),
                  ),
                  if (!_isSignInMode) ...[
                    const SizedBox(width: 12),
                    _buildStepIndicator(),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Avatar icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.chipBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _isSignInMode ? Icons.lock_outline : Icons.person,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),

              const SizedBox(height: 16),

              // Title & Subtitle
              Text(
                _isSignInMode ? _l10n.signIn : _l10n.accountDetails,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isSignInMode
                    ? 'Welcome back! Sign in to access your farm dashboard.'
                    : _l10n.profileSubtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // Form fields inside SingleChildScrollView
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isSignInMode) ...[
                        // Farmer Name
                        _buildLabel(_l10n.farmerName),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameController,
                          hint: _l10n.farmerNameHint,
                          icon: Icons.person_outline,
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Phone Number (10 digits only)
                      _buildLabel(_l10n.phoneNumber),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _phoneController,
                        hint: _l10n.phoneHint,
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Password Field
                      _buildLabel(_l10n.password),
                      const SizedBox(height: 8),
                      _buildPasswordField(),

                      if (!_isSignInMode) ...[
                        const SizedBox(height: 20),
                        // Village
                        _buildLabel(_l10n.village),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _villageController,
                          hint: _l10n.villageHint,
                          icon: Icons.home_outlined,
                          keyboardType: TextInputType.text,
                        ),
                      ],

                      // ─── Sign-In GPS Location Detection & State/District Fields ───
                      if (_isSignInMode) ...[
                        const SizedBox(height: 20),
                        _buildSignInGpsLocationSection(),
                        const SizedBox(height: 16),
                        _buildLabel(_l10n.state),
                        const SizedBox(height: 8),
                        _buildSignInStatePicker(),
                        const SizedBox(height: 16),
                        _buildLabel(_l10n.district),
                        const SizedBox(height: 8),
                        _buildSignInDistrictPicker(),
                      ],

                      const SizedBox(height: 24),

                      // Toggle between Sign In & Create Account
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isSignInMode = !_isSignInMode;
                              if (_isSignInMode && _states.isEmpty) {
                                _fetchStates();
                                _detectGpsLocation();
                              }
                            });
                          },
                          child: Text(
                            _isSignInMode
                                ? _l10n.dontHaveAccount
                                : _l10n.alreadyHaveAccount,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Action Button (Next: Add Farm or Sign In)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canProceed() && !_isLoading
                      ? () {
                          if (_isSignInMode) {
                            _handleSignIn();
                          } else {
                            _handleNextAddFarm();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignInMode ? _l10n.signIn : _l10n.nextAddFarm,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _isSignInMode ? Icons.login : Icons.arrow_forward,
                              size: 18,
                            ),
                          ],
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

  // ─── Sign-In GPS Location UI Section ─────────────────────────────

  Widget _buildSignInGpsLocationSection() {
    if (_isDetectingLocation) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Color(0xFF15803D),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Detecting your location via GPS...',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF166534),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_locationDetectedSuccess && _signInState != null && _signInDistrict != null) {
      final accuracyStr = _detectedAccuracy != null ? ' (±${_detectedAccuracy!.toStringAsFixed(0)}m)' : '';
      final coordsTooltip = (_detectedLat != null && _detectedLon != null)
          ? 'GPS: ${_detectedLat!.toStringAsFixed(4)}, ${_detectedLon!.toStringAsFixed(4)}$accuracyStr'
          : 'GPS Location Active';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Row(
          children: [
            Tooltip(
              message: coordsTooltip,
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location detected ✓$accuracyStr',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'State: $_signInState  •  District: $_signInDistrict',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF15803D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: _detectGpsLocation,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.refresh_rounded, color: Color(0xFF15803D), size: 18),
              ),
            ),
          ],
        ),
      );
    }

    // Failure / Error state or not detected yet
    if (_locationStatusMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFFB45309), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locationStatusMessage!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF92400E),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isLocationServiceDisabled)
                  TextButton.icon(
                    onPressed: () async {
                      await GpsLocationService.openLocationSettings();
                    },
                    icon: const Icon(Icons.settings_outlined, size: 15, color: Color(0xFFB45309)),
                    label: Text(
                      'Settings',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                    ),
                  ),
                if (_isPermissionDeniedForever)
                  TextButton.icon(
                    onPressed: () async {
                      await GpsLocationService.openAppSettings();
                    },
                    icon: const Icon(Icons.settings_outlined, size: 15, color: Color(0xFFB45309)),
                    label: Text(
                      'App Settings',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                    ),
                  ),
                TextButton.icon(
                  onPressed: _detectGpsLocation,
                  icon: const Icon(Icons.my_location_rounded, size: 15, color: Color(0xFF15803D)),
                  label: Text(
                    'Retry GPS',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Default trigger button if not yet detected
    return InkWell(
      onTap: _detectGpsLocation,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.my_location_rounded, color: Color(0xFF15803D), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Auto-detect State & District via GPS',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B), size: 20),
          ],
        ),
      ),
    );
  }

  /// State Picker Field for Sign-In
  Widget _buildSignInStatePicker() {
    if (_loadingStates) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text(_l10n.loading, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final isSelected = _signInState != null && _signInState!.isNotEmpty;

    return InkWell(
      onTap: _states.isEmpty
          ? _fetchStates
          : () => _showSearchModal(
                title: _l10n.selectState,
                items: _states,
                selectedItem: _signInState,
                onSelected: (value) {
                  setState(() {
                    _signInState = value;
                    _signInDistrict = null;
                  });
                  _fetchDistricts(value);
                },
              ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.public,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _signInState ?? _l10n.selectState,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  /// District Picker Field for Sign-In
  Widget _buildSignInDistrictPicker() {
    if (_loadingDistricts) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text(_l10n.loading, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (_signInState == null || _signInState!.isEmpty) {
      return Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: AppColors.textSecondary.withValues(alpha: 0.4), size: 20),
            const SizedBox(width: 12),
            Text(
              _l10n.selectDistrict,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    final isSelected = _signInDistrict != null && _signInDistrict!.isNotEmpty;

    return InkWell(
      onTap: () => _showSearchModal(
        title: '${_l10n.selectDistrict} ($_signInState)',
        items: _districts,
        selectedItem: _signInDistrict,
        onSelected: (value) {
          setState(() {
            _signInDistrict = value;
          });
        },
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _signInDistrict ?? _l10n.selectDistrict,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchModal({
    required String title,
    required List<String> items,
    required String? selectedItem,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchModalContent(
        title: title,
        items: items,
        selectedItem: selectedItem,
        onSelected: onSelected,
        hintText: 'Search...',
      ),
    );
  }

  bool _canProceed() {
    if (_isSignInMode) {
      return _phoneController.text.trim().length == 10 &&
          _passwordController.text.trim().isNotEmpty;
    }
    return _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().length == 10 &&
        _passwordController.text.trim().isNotEmpty;
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _l10n.step1of2,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.chipText,
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: _l10n.passwordHint,
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: AppColors.textSecondary,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _villageController.dispose();
    super.dispose();
  }
}

/// Case-insensitive search bottom sheet modal for State/District selection
class _SearchModalContent extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String> onSelected;
  final String hintText;

  const _SearchModalContent({
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
    required this.hintText,
  });

  @override
  State<_SearchModalContent> createState() => _SearchModalContentState();
}

class _SearchModalContentState extends State<_SearchModalContent> {
  final _searchController = TextEditingController();
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final totalHeight = MediaQuery.of(context).size.height * 0.70;

    return Container(
      height: totalHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Search Input Field
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    autofocus: false,
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Items List
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No matching records found',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF8FAFC)),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = item == widget.selectedItem;

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                          title: Text(
                            item,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF15803D) : const Color(0xFF1E293B),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Color(0xFF15803D), size: 20)
                              : null,
                          onTap: () {
                            widget.onSelected(item);
                            Navigator.of(context).pop();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
