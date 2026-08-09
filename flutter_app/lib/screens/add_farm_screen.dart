import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../utils/location_helper.dart';
import 'analysis_screen.dart';

/// Add Your Farm screen (Step 2 of 2).
/// Location (State & District picker or GPS Auto-Detect), Crop Type, Farm Area, Sowing Date.
class AddFarmScreen extends StatefulWidget {
  final String language;
  final String farmerName;
  final String phoneNumber;
  final String village;

  const AddFarmScreen({
    super.key,
    required this.language,
    required this.farmerName,
    required this.phoneNumber,
    required this.village,
  });

  @override
  State<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  late AppLocalizations _l10n;

  // Crops (including 'Not Sown Yet')
  final List<String> _crops = [
    'Not Sown Yet',
    'Soyabean',
    'Groundnut',
    'Sunflower',
    'Sesamum',
    'Rapeseed &Mustard',
    'Linseed',
    'Castor seed',
    'Safflower',
    'Niger seed',
  ];

  String _selectedCrop = 'Not Sown Yet';
  final _areaController = TextEditingController(text: '0.0');
  String _areaUnit = 'Acres';
  DateTime _sowingDate = DateTime.now();

  // State / District selection from API
  List<String> _states = [];
  List<String> _districts = [];
  String? _selectedState;
  String? _selectedDistrict;
  bool _loadingStates = true;
  bool _loadingDistricts = false;
  String? _locationError;

  // GPS auto-detect
  double? _detectedLat;
  double? _detectedLon;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _l10n = AppLocalizations(widget.language);
    _fetchStates();
  }

  /// Fetch states from FastAPI → MongoDB
  Future<void> _fetchStates() async {
    try {
      final states = await ApiService.fetchStates();
      setState(() {
        _states = states;
        _loadingStates = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Could not load states. Is the backend running?';
        _loadingStates = false;
      });
    }
  }

  /// Fetch districts for selected state from FastAPI → MongoDB
  Future<void> _fetchDistricts(String state) async {
    setState(() {
      _loadingDistricts = true;
      _districts = [];
      _selectedDistrict = null;
    });

    try {
      final districts = await ApiService.fetchDistricts(state);
      setState(() {
        _districts = districts;
        _loadingDistricts = false;
      });
    } catch (e) {
      setState(() {
        _loadingDistricts = false;
      });
    }
  }

  /// Auto Detect Location using Browser GPS → nearest district API.
  Future<void> _autoDetectLocation() async {
    setState(() => _isDetecting = true);

    double lat = 20.0059;
    double lon = 73.7897;

    try {
      final coords = await getWebLocation();
      if (coords != null) {
        lat = coords['latitude']!;
        lon = coords['longitude']!;
      }

      final result = await ApiService.findNearestDistrict(lat, lon);

      final state = result['state'] as String?;
      final district = result['district'] as String?;

      if (state != null) {
        await _fetchDistricts(state);
      }

      setState(() {
        _detectedLat = lat;
        _detectedLon = lon;
        _selectedState = state;
        _selectedDistrict = district;
        _isDetecting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location detected: $district, $state',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      // Fallback if browser permission denied
      try {
        final result = await ApiService.findNearestDistrict(lat, lon);
        final state = result['state'] as String?;
        final district = result['district'] as String?;
        if (state != null) {
          await _fetchDistricts(state);
        }
        setState(() {
          _detectedLat = lat;
          _detectedLon = lon;
          _selectedState = state;
          _selectedDistrict = district;
          _isDetecting = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('GPS detected: $district, $state'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (err) {
        setState(() => _isDetecting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to detect location. Please select State & District below.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
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

              // Back + Step indicator
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.arrow_back_ios, size: 20),
                  ),
                  const SizedBox(width: 12),
                  _buildStepIndicator(),
                ],
              ),

              const SizedBox(height: 20),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 1.0,
                  backgroundColor: AppColors.border,
                  color: AppColors.primary,
                  minHeight: 4,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                _l10n.addYourFarm,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _l10n.farmSubtitle,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Auto Detect Location card
                      _buildAutoDetectCard(),

                      const SizedBox(height: 20),

                      // State picker
                      _buildLabel(_l10n.state),
                      const SizedBox(height: 8),
                      _buildStatePicker(),

                      const SizedBox(height: 16),

                      // District picker
                      _buildLabel(_l10n.district),
                      const SizedBox(height: 8),
                      _buildDistrictPicker(),

                      if (_locationError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _locationError!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Crop Type
                      _buildLabel(_l10n.cropType),
                      const SizedBox(height: 10),
                      _buildCropChips(),

                      const SizedBox(height: 24),

                      // Farm Area
                      _buildLabel(_l10n.farmArea),
                      const SizedBox(height: 10),
                      _buildFarmAreaRow(),

                      const SizedBox(height: 24),

                      // Sowing Date
                      _buildLabel(_l10n.sowingDate),
                      const SizedBox(height: 10),
                      _buildDatePicker(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Analyze button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canAnalyze()
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AnalysisScreen(
                                language: widget.language,
                                farmerName: widget.farmerName,
                                phoneNumber: widget.phoneNumber,
                                village: widget.village,
                                state: _selectedState!,
                                district: _selectedDistrict!,
                                latitude: _detectedLat,
                                longitude: _detectedLon,
                                crop: _selectedCrop,
                                farmArea:
                                    double.tryParse(_areaController.text) ?? 0.0,
                                farmAreaUnit: _areaUnit.toLowerCase(),
                                sowingDate: _sowingDate,
                                farmLocation: widget.village,
                              ),
                            ),
                          );
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _l10n.analyzeMyFarm,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.show_chart, size: 20),
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

  bool _canAnalyze() {
    return _selectedState != null && _selectedDistrict != null;
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _l10n.step2of2,
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

  /// Auto Detect Location card
  Widget _buildAutoDetectCard() {
    return GestureDetector(
      onTap: _isDetecting ? null : _autoDetectLocation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2D5A1E), Color(0xFF1A3A0F)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isDetecting
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _l10n.autoDetectLocation,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedState != null && _selectedDistrict != null
                        ? '$_selectedDistrict, $_selectedState'
                        : _l10n.autoDetectSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  /// Build state picker field that opens a scrollable search dialog
  Widget _buildStatePicker() {
    if (_loadingStates) {
      return _buildPickerLoading(_l10n.loading);
    }

    final isSelected = _selectedState != null;

    return InkWell(
      onTap: _states.isEmpty
          ? _fetchStates
          : () => _showSearchModal(
                title: _l10n.selectState,
                items: _states,
                selectedItem: _selectedState,
                onSelected: (value) {
                  setState(() {
                    _selectedState = value;
                  });
                  _fetchDistricts(value);
                },
              ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 54,
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
                _selectedState ?? _l10n.selectState,
                style: GoogleFonts.inter(
                  fontSize: 15,
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

  /// Build district picker field that opens a scrollable search dialog
  Widget _buildDistrictPicker() {
    if (_loadingDistricts) {
      return _buildPickerLoading(_l10n.loading);
    }

    if (_selectedState == null) {
      return _buildPickerDisabled(_l10n.selectDistrict);
    }

    final isSelected = _selectedDistrict != null;

    return InkWell(
      onTap: () => _showSearchModal(
        title: '${_l10n.selectDistrict} ($_selectedState)',
        items: _districts,
        selectedItem: _selectedDistrict,
        onSelected: (value) {
          setState(() {
            _selectedDistrict = value;
          });
        },
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 54,
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
                _selectedDistrict ?? _l10n.selectDistrict,
                style: GoogleFonts.inter(
                  fontSize: 15,
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
      builder: (ctx) {
        return _SearchModalContent(
          title: title,
          items: items,
          selectedItem: selectedItem,
          onSelected: onSelected,
        );
      },
    );
  }

  Widget _buildPickerLoading(String text) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerDisabled(String text) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.textSecondary.withValues(alpha: 0.4), size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Crop type chips (scrollable horizontal).
  Widget _buildCropChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _crops.map((crop) {
          final isSelected = _selectedCrop == crop;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCrop = crop),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.chipBg : AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.eco,
                          size: 16,
                          color: AppColors.chipText,
                        ),
                      ),
                    Text(
                      crop,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.chipText
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Farm area input + unit toggle.
  Widget _buildFarmAreaRow() {
    return Row(
      children: [
        // Area input (max 5 chars, numbers & decimal point only)
        Expanded(
          flex: 2,
          child: TextField(
            controller: _areaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              LengthLimitingTextInputFormatter(5),
            ],
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Unit toggle
        Expanded(
          flex: 2,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _buildUnitToggle('Acres', _l10n.acresLabel),
                _buildUnitToggle('Hectares', _l10n.hectaresLabel),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitToggle(String value, String label) {
    final isSelected = _areaUnit == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _areaUnit = value),
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.textPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  /// Sowing date picker.
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _sowingDate,
          firstDate: DateTime(2024),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: AppColors.primary),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() => _sowingDate = picked);
        }
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Text(
              DateFormat('d MMM yyyy').format(_sowingDate),
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }
}

/// Scrollable & searchable bottom sheet dialog for state/district selection
class _SearchModalContent extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String> onSelected;

  const _SearchModalContent({
    required this.title,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
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
    _filteredItems = widget.items;
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.65;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),

          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 16),

          // Header title + Close button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Scrollable items list
          Flexible(
            child: _filteredItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No results found',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: _filteredItems.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (ctx, index) {
                      final item = _filteredItems[index];
                      final isSelected = item == widget.selectedItem;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        title: Text(
                          item,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          widget.onSelected(item);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
