import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

/// Government Schemes Screen for Kisaan Mitra.
/// Displays Central and State agricultural schemes fetched via Gemini integration.
class GovernmentSchemesScreen extends StatefulWidget {
  const GovernmentSchemesScreen({super.key});

  @override
  State<GovernmentSchemesScreen> createState() => _GovernmentSchemesScreenState();
}

class _GovernmentSchemesScreenState extends State<GovernmentSchemesScreen> {
  // Filter state: 'all', 'central', 'state'
  String _selectedFilter = 'all';

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _schemes = [];
  String _farmerState = 'Maharashtra';
  String? _currentLang;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activeLang = Localizations.localeOf(context).languageCode;
    if (_currentLang != activeLang) {
      _currentLang = activeLang;
      _loadSchemesData();
    }
  }

  Future<void> _loadSchemesData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone');
      final activeLang = _currentLang ?? 'en';

      String userState = 'Maharashtra';
      if (phone != null && phone.isNotEmpty) {
        final userData = await ApiService.getUser(phone);
        if (userData != null && userData['state'] != null && userData['state'].toString().isNotEmpty) {
          userState = userData['state'].toString();
        }
      }

      final response = await ApiService.fetchGovernmentSchemes(
        phoneNumber: phone,
        state: userState,
        language: activeLang,
      );

      final List<dynamic> schemeList = response['schemes'] ?? [];
      final List<Map<String, dynamic>> parsedSchemes =
          schemeList.map((e) => Map<String, dynamic>.from(e)).toList();

      if (!mounted) return;
      setState(() {
        _farmerState = userState;
        _schemes = parsedSchemes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load schemes right now.';
        _isLoading = false;
      });
    }
  }

  String _normalizeUrl(String rawUrl) {
    String trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }

  Future<void> _launchOfficialUrl(String? urlString) async {
    final l10n = AppLocalizations.of(context);
    if (urlString == null || urlString.trim().isEmpty) {
      _showUrlErrorSnackBar(l10n.officialLinkUnavailable);
      return;
    }

    final sanitizedUrl = _normalizeUrl(urlString);
    if (sanitizedUrl.isEmpty || !sanitizedUrl.contains('.')) {
      _showUrlErrorSnackBar(l10n.officialLinkUnavailable);
      return;
    }

    try {
      final Uri uri = Uri.parse(sanitizedUrl);
      bool launched = false;

      // 1. Force opening in system external browser (Chrome / Safari)
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {}

      // 2. Fallback to platform default external browser handler
      if (!launched) {
        try {
          launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        } catch (_) {}
      }

      if (!launched) {
        _showUrlErrorSnackBar(l10n.officialLinkUnavailable);
      }
    } catch (e) {
      _showUrlErrorSnackBar(l10n.officialLinkUnavailable);
    }
  }

  void _showUrlErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF10182F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredSchemes {
    if (_selectedFilter == 'central') {
      return _schemes
          .where((s) =>
              (s['governmentLevel'] ?? '').toString().toLowerCase() == 'central')
          .toList();
    } else if (_selectedFilter == 'state') {
      return _schemes
          .where((s) =>
              (s['governmentLevel'] ?? '').toString().toLowerCase() == 'state')
          .toList();
    }
    return _schemes;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 32 ? screenWidth - 32 : screenWidth;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F4),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSchemesData,
          color: const Color(0xFF16834A),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: contentWidth,
                maxWidth: contentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Header ─────────────────────────────────────────
                  Text(
                    l10n.govtSchemesTitle,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF10182F),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.govtSchemesSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ─── Filter Pills ───────────────────────────────────
                  SizedBox(
                    width: contentWidth,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterPill(
                            id: 'all',
                            label: l10n.filterAllSchemes,
                          ),
                          const SizedBox(width: 10),
                          _buildFilterPill(
                            id: 'central',
                            label: l10n.filterCentralGovt,
                          ),
                          const SizedBox(width: 10),
                          _buildFilterPill(
                            id: 'state',
                            label: '${l10n.filterStateGovt} ($_farmerState)',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                // ─── Body Content ───────────────────────────────────
                if (_isLoading)
                  _buildLoadingState(l10n)
                else if (_errorMessage != null)
                  _buildErrorState(l10n)
                else if (_filteredSchemes.isEmpty)
                  _buildEmptyState(l10n)
                else
                  ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredSchemes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final scheme = _filteredSchemes[index];
                        return _buildSchemeCard(scheme, l10n);
                      },
                    ),

                    const SizedBox(height: 28),

                    // ─── About These Schemes Section ────────────────
                    _buildAboutSection(l10n),

                    const SizedBox(height: 16),

                    // ─── View All Schemes Banner ────────────────────
                    if (_selectedFilter != 'all') _buildViewAllBanner(l10n),

                    const SizedBox(height: 24),
                  ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  // ─── Filter Pill Builder ─────────────────────────────────────────
  Widget _buildFilterPill({required String id, required String label}) {
    final isSelected = _selectedFilter == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB8F23D) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFFB8F23D) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFB8F23D).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? const Color(0xFF10182F) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ─── Scheme Card Builder ─────────────────────────────────────────
  Widget _buildSchemeCard(Map<String, dynamic> scheme, AppLocalizations l10n) {
    final String name = scheme['name'] ?? '';
    final String category = scheme['category'] ?? '';
    final String description = scheme['description'] ?? '';
    final String govLevel = (scheme['governmentLevel'] ?? 'Central').toString();
    final String status = scheme['status'] ?? l10n.statusActive;
    final String rawOfficialUrl = scheme['officialUrl'] ?? '';
    final String officialUrl = _normalizeUrl(rawOfficialUrl);
    final bool hasValidUrl = officialUrl.isNotEmpty && officialUrl.contains('.');

    final bool isState = govLevel.toLowerCase() == 'state';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon + Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isState ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isState
                      ? Icons.assured_workload_rounded
                      : Icons.account_balance_rounded,
                  color: isState ? const Color(0xFFD97706) : const Color(0xFF16834A),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10182F),
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Responsive Category & Govt Level Tags
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (category.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF166534),
                      ),
                    ),
                  ),
                ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isState
                        ? const Color(0xFFFFFBEB)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isState
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Text(
                    isState
                        ? l10n.filterStateGovt
                        : l10n.filterCentralGovt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isState
                          ? const Color(0xFFB45309)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Description
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Bottom Bar: Status Tag & Learn More Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Active Status Badge
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          status,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Learn More Button
              InkWell(
                onTap: hasValidUrl
                    ? () => _launchOfficialUrl(officialUrl)
                    : () => _showUrlErrorSnackBar(l10n.officialLinkUnavailable),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.learnMore,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: hasValidUrl
                              ? const Color(0xFF16834A)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: hasValidUrl
                            ? const Color(0xFF16834A)
                            : const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── About Section ───────────────────────────────────────────────
  Widget _buildAboutSection(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF16834A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.aboutTheseSchemes,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF10182F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.aboutSchemesDesc,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ─── View All Banner ─────────────────────────────────────────────
  Widget _buildViewAllBanner(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.cantFindLookingFor,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF10182F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.cantFindSubtitle,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'all';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16834A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.viewAllSchemes,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading State ───────────────────────────────────────────────
  Widget _buildLoadingState(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF16834A),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.loadingSchemes,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error State ─────────────────────────────────────────────────
  Widget _buildErrorState(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.unableToLoadSchemes,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10182F),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadSchemesData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16834A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty State ─────────────────────────────────────────────────
  Widget _buildEmptyState(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              'No schemes found for this filter.',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = 'all';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16834A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(l10n.viewAllSchemes),
            ),
          ],
        ),
      ),
    );
  }
}
