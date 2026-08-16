import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/wallet_model.dart';
import '../services/api_service.dart';

class FarmerWalletScreen extends StatefulWidget {
  final String? phoneNumber;

  const FarmerWalletScreen({
    super.key,
    this.phoneNumber,
  });

  @override
  State<FarmerWalletScreen> createState() => _FarmerWalletScreenState();
}

class _FarmerWalletScreenState extends State<FarmerWalletScreen> {
  bool _isLoading = true;
  bool _isSavingExpenses = false;
  String? _errorMessage;
  WalletOverviewModel? _walletData;
  String? _userPhone;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
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
      _userPhone = phone;

      final jsonResponse = await ApiService.fetchWalletOverview(phoneNumber: phone);
      final model = WalletOverviewModel.fromJson(jsonResponse);

      if (!mounted) return;
      setState(() {
        _walletData = model;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load farmer wallet data.';
        _isLoading = false;
      });
    }
  }

  // Live Recalculation Helpers for local draft changes
  void _recalculateProfit() {
    if (_walletData == null) return;
    final w = _walletData!;
    final totalCost = w.expenses.fold<double>(0.0, (sum, item) => sum + item.amount);

    final revExp = w.profitSummary.revenueExpected;
    final revMin = w.profitSummary.revenueMin;
    final revMax = w.profitSummary.revenueMax;

    final expProfit = revExp - totalCost;
    final minProfit = revMin - totalCost;
    final maxProfit = revMax - totalCost;

    final isLoss = expProfit < 0;

    setState(() {
      _walletData = WalletOverviewModel(
        farmerName: w.farmerName,
        village: w.village,
        district: w.district,
        state: w.state,
        currentCrop: w.currentCrop,
        farmArea: w.farmArea,
        farmAreaUnit: w.farmAreaUnit,
        hasFarmArea: w.hasFarmArea,
        hasCrop: w.hasCrop,
        hasYieldPrediction: w.hasYieldPrediction,
        yieldPrediction: w.yieldPrediction,
        sellingPrice: w.sellingPrice,
        profitSummary: ProfitSummaryModel(
          expectedProfit: expProfit,
          minProfit: minProfit,
          maxProfit: maxProfit,
          safePlanningMin: minProfit,
          safePlanningMax: expProfit,
          totalCost: totalCost,
          revenueExpected: revExp,
          revenueMin: revMin,
          revenueMax: revMax,
          sellingPricePerQuintal: w.profitSummary.sellingPricePerQuintal,
          sellingPricePerTonne: w.profitSummary.sellingPricePerTonne,
          farmAreaHa: w.profitSummary.farmAreaHa,
          totalYieldTonnes: w.profitSummary.totalYieldTonnes,
          isLoss: isLoss,
          displayTitle: isLoss ? 'Estimated Loss' : 'Expected Profit',
          formattedExpectedProfit: _formatIndianCurrency(expProfit),
          formattedMinProfit: _formatIndianCurrency(minProfit),
          formattedMaxProfit: _formatIndianCurrency(maxProfit),
        ),
        expenses: w.expenses,
        marketItems: w.marketItems,
        marketInsight: w.marketInsight,
      );
    });
  }

  String _formatIndianCurrency(double val) {
    final absVal = val.abs();
    final sign = val < 0 ? '-' : '';
    if (absVal >= 100000) {
      final lakhs = absVal / 100000.0;
      return '$sign₹${lakhs.toStringAsFixed(2)} L';
    } else {
      final intVal = val.round().abs();
      final s = intVal.toString();
      if (s.length > 3) {
        final last3 = s.substring(s.length - 3);
        var other = s.substring(0, s.length - 3);
        var res = '';
        while (other.length > 2) {
          res = ',${other.substring(other.length - 2)}$res';
          other = other.substring(0, other.length - 2);
        }
        return '$sign₹$other$res,$last3';
      } else {
        return '$sign₹$s';
      }
    }
  }

  void _adjustExpense(ExpenseItemModel item, double delta) {
    final newAmount = (item.amount + delta).clamp(0.0, 10000000.0);
    if (newAmount == item.amount) return;

    setState(() {
      item.amount = newAmount;
      _recalculateProfit();
    });
  }

  void _deleteExpense(ExpenseItemModel item) {
    setState(() {
      _walletData?.expenses.removeWhere((e) => e.id == item.id);
      _recalculateProfit();
    });
  }

  Future<void> _saveExpenses() async {
    if (_walletData == null) return;
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isSavingExpenses = true;
    });

    try {
      final expensesList = _walletData!.expenses.map((e) => e.toJson()).toList();
      final jsonResponse = await ApiService.saveExpenses(
        phoneNumber: _userPhone,
        expenses: expensesList,
      );
      final updatedModel = WalletOverviewModel.fromJson(jsonResponse);

      if (!mounted) return;
      setState(() {
        _walletData = updatedModel;
        _isSavingExpenses = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.saveSuccess,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF15803D),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSavingExpenses = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save expenses. Please try again.',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showAddExpenseModal() {
    final l10n = AppLocalizations.of(context);
    final categories = [
      'Seeds',
      'Fertilizer',
      'Labour',
      'Machinery',
      'Irrigation',
      'Pest Control',
      'Other',
    ];

    String selectedCategory = categories[0];
    final customNameController = TextEditingController();
    final amountController = TextEditingController();

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
            final isOther = selectedCategory == 'Other';

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.addExpense,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.category,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                _getCategoryDisplayName(l10n, c),
                                style: GoogleFonts.inter(fontSize: 14),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedCategory = val);
                      }
                    },
                  ),
                  if (isOther) ...[
                    const SizedBox(height: 14),
                    Text(
                      l10n.customCategoryName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: customNameController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Transport / Storage',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    l10n.amount,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      hintText: '0',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                        final label = isOther && customNameController.text.trim().isNotEmpty
                            ? customNameController.text.trim()
                            : selectedCategory;

                        Navigator.pop(context);

                        try {
                          final jsonRes = await ApiService.addExpense(
                            phoneNumber: _userPhone,
                            category: selectedCategory.toLowerCase(),
                            label: label,
                            amount: amt,
                          );
                          final updatedModel = WalletOverviewModel.fromJson(jsonRes);
                          setState(() {
                            _walletData = updatedModel;
                          });
                        } catch (e) {
                          debugPrint('Failed adding expense: $e');
                        }
                      },
                      child: Text(
                        l10n.saveExpense,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
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

  String _getCategoryDisplayName(AppLocalizations l10n, String categoryName) {
    final c = categoryName.toLowerCase().trim();
    if (c.contains('seed')) return l10n.seeds;
    if (c.contains('fert')) return l10n.fertilizer;
    if (c.contains('labour') || c.contains('labor')) return l10n.labour;
    if (c.contains('machin')) return l10n.machinery;
    if (c.contains('irrig')) return l10n.irrigation;
    if (c.contains('pest') || c.contains('insect')) return l10n.pestControl;
    if (c == 'other') return l10n.other;
    return categoryName;
  }

  String _getLocalizedExpenseLabel(AppLocalizations l10n, ExpenseItemModel item) {
    final cat = item.category.toLowerCase().trim();
    final lbl = item.label.toLowerCase().trim();

    if (cat.contains('seed') || lbl.contains('seed')) return l10n.seeds;
    if (cat.contains('fert') || lbl.contains('fert')) return l10n.fertilizer;
    if (cat.contains('labour') || cat.contains('labor') || lbl.contains('labour') || lbl.contains('labor')) return l10n.labour;
    if (cat.contains('machin') || lbl.contains('machin')) return l10n.machinery;
    if (cat.contains('irrig') || lbl.contains('irrig')) return l10n.irrigation;
    if (cat.contains('pest') || cat.contains('insect') || lbl.contains('pest') || lbl.contains('insect')) return l10n.pestControl;
    if ((cat == 'other' || cat.isEmpty) && (lbl == 'other' || lbl.isEmpty || item.label == 'Other')) return l10n.other;

    return item.label;
  }

  String _getLocalizedCropName(AppLocalizations l10n, String cropName) {
    final c = cropName.toLowerCase();
    final lang = l10n.languageCode;
    if (c.contains('groundnut') || c.contains('moongphali')) {
      return lang == 'hi' ? 'मूंगफली' : lang == 'mr' ? 'भुईमूग' : 'Groundnut';
    }
    if (c.contains('soybean') || c.contains('soyabean')) {
      return lang == 'hi' ? 'सोयाबीन' : lang == 'mr' ? 'सोयाबीन' : 'Soybean';
    }
    if (c.contains('mustard') || c.contains('rapeseed')) {
      return lang == 'hi' ? 'सरसों / रायडा' : lang == 'mr' ? 'मोहरी' : 'Mustard / Rapeseed';
    }
    if (c.contains('sunflower') || c.contains('surajmukhi')) {
      return lang == 'hi' ? 'सूरजमुखी' : lang == 'mr' ? 'सूर्यफूल' : 'Sunflower';
    }
    if (c.contains('sesame') || c.contains('til') || c.contains('sesamum')) {
      return lang == 'hi' ? 'तिल' : lang == 'mr' ? 'तीळ' : 'Sesame Seed (Til)';
    }
    if (c.contains('castor')) {
      return lang == 'hi' ? 'अरंडी' : lang == 'mr' ? 'एरंडी' : 'Castor Seed';
    }
    if (c.contains('linseed') || c.contains('alsi')) {
      return lang == 'hi' ? 'अलसी' : lang == 'mr' ? 'जवस' : 'Linseed';
    }
    if (c.contains('safflower') || c.contains('kusum')) {
      return lang == 'hi' ? 'कुसुम' : lang == 'mr' ? 'करडई' : 'Safflower';
    }
    if (c.contains('niger')) {
      return lang == 'hi' ? 'रामतिल' : lang == 'mr' ? 'कारळा' : 'Niger Seed';
    }
    return cropName;
  }

  IconData _getCategoryIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('seed')) return Icons.grass;
    if (c.contains('fert')) return Icons.inventory_2_outlined;
    if (c.contains('labour') || c.contains('labor')) return Icons.engineering;
    if (c.contains('machin')) return Icons.agriculture;
    if (c.contains('irrig')) return Icons.water_drop_outlined;
    if (c.contains('pest') || c.contains('insect')) return Icons.bug_report_outlined;
    return Icons.more_horiz;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadWalletData,
          color: const Color(0xFF15803D),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF15803D)),
      );
    }

    if (_errorMessage != null || _walletData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 52, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              'Unable to load Farmer Wallet',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D)),
              onPressed: _loadWalletData,
              child: Text(l10n.retry, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final data = _walletData!;
    final ps = data.profitSummary;

    final bool isPlanningMode = !data.hasCrop ||
        data.currentCrop == null ||
        data.currentCrop!.trim().isEmpty ||
        data.currentCrop!.trim().toLowerCase() == 'not sown yet' ||
        data.currentCrop!.trim().toLowerCase() == 'none';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          Text(
            l10n.wallet,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isPlanningMode
                ? l10n.planningModeSubtitle
                : l10n.financialOverviewSubtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          if (!isPlanningMode) ...[
            if (!data.hasFarmArea) ...[
              _buildWarningBanner('Add your farm area to view your financial outlook.'),
              const SizedBox(height: 14),
            ],
            if (!data.hasYieldPrediction) ...[
              _buildWarningBanner('Generate your yield prediction to see your financial outlook.'),
              const SizedBox(height: 14),
            ],
            if (!data.sellingPrice.available) ...[
              _buildWarningBanner('Market price unavailable for current location/crop.'),
              const SizedBox(height: 14),
            ],

            // 2. HERO EXPECTED PROFIT CARD
            _buildExpectedProfitCard(ps, data, l10n),
            const SizedBox(height: 16),

            // 3. FINANCIAL OUTLOOK CARD
            _buildFinancialOutlookCard(ps, l10n),
            const SizedBox(height: 20),

            // 4. YOUR FARM COSTS SECTION
            _buildFarmCostsSection(data, l10n),
            const SizedBox(height: 24),
          ],

          // 5. OILSEED MARKET TODAY SECTION
          _buildMarketTodaySection(data, l10n),
          const SizedBox(height: 16),

          // 6. GEMINI MARKET INSIGHT (Active Crop Only)
          if (!isPlanningMode && data.marketInsight != null && data.marketInsight!.available) ...[
            _buildMarketInsightCard(data.marketInsight!),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningBanner(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedProfitCard(ProfitSummaryModel ps, WalletOverviewModel data, AppLocalizations l10n) {
    final cardBg = ps.isLoss
        ? const LinearGradient(colors: [Color(0xFF991B1B), Color(0xFF7F1D1D)])
        : const LinearGradient(colors: [Color(0xFF16834A), Color(0xFF14532D)]);

    final headerTitle = ps.isLoss ? l10n.estimatedLoss : l10n.expectedProfitTitle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (ps.isLoss ? Colors.red : Colors.green).withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            headerTitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              ps.formattedExpectedProfit,
              style: GoogleFonts.inter(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildProfitCol(l10n.minimumExpected.toUpperCase(), ps.formattedMinProfit),
                ),
                Container(height: 24, width: 1, color: Colors.white.withOpacity(0.25)),
                Expanded(
                  child: _buildProfitCol(l10n.maximumExpected.toUpperCase(), ps.formattedMaxProfit),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.confidenceNote,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.disclaimerNote,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCol(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.75),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialOutlookCard(ProfitSummaryModel ps, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF15803D), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.financialOutlook,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.expectedProfitTitle,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  ps.formattedExpectedProfit,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ps.isLoss ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.safePlanningRange,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '${ps.formattedMinProfit} – ${ps.formattedExpectedProfit}',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.planExpensesAdvice,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmCostsSection(WalletOverviewModel data, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF15803D), size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.farmCosts,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  data.historicalCostBenchmarkNote,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // List of expenses
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.expenses.length,
            separatorBuilder: (_, __) => const Divider(height: 12, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final item = data.expenses[index];
              return _buildExpenseRow(item, l10n);
            },
          ),

          const SizedBox(height: 14),

          // Add Expense Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              side: const BorderSide(color: Color(0xFF15803D), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showAddExpenseModal,
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF15803D), size: 18),
            label: Text(
              l10n.addExpense,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF15803D),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(thickness: 1.2, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),

          // Total Cost Row
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.totalCost,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatIndianCurrency(data.profitSummary.totalCost),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Clear Submit / Save Changes Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSavingExpenses ? null : _saveExpenses,
              icon: _isSavingExpenses
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              label: Text(
                l10n.submit,
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
  }

  Widget _buildExpenseRow(ExpenseItemModel item, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(_getCategoryIcon(item.category), size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _getLocalizedExpenseLabel(l10n, item),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 72),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatIndianCurrency(item.amount),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Decrement Button (-)
              InkWell(
                onTap: () => _adjustExpense(item, -500.0),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.remove, size: 18, color: Color(0xFF15803D)),
                ),
              ),
              const SizedBox(width: 6),

              // Increment Button (+)
              InkWell(
                onTap: () => _adjustExpense(item, 500.0),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, size: 18, color: Color(0xFF15803D)),
                ),
              ),
              const SizedBox(width: 4),

              // Delete Button (RED ICON)
              IconButton(
                onPressed: () => _deleteExpense(item),
                icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTodaySection(WalletOverviewModel data, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Color(0xFF15803D), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.oilseedMarketData,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${data.state} • Benchmark dataset',
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.marketItems.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = data.marketItems[index];
            return _buildMarketCard(item, l10n);
          },
        ),
      ],
    );
  }

  Widget _buildMarketCard(MarketItemModel item, AppLocalizations l10n) {
    final isHigh = item.marketStatus.toLowerCase().contains('high') || item.marketStatus.toLowerCase().contains('strong');
    final isLow = item.marketStatus.toLowerCase().contains('low') || item.marketStatus.toLowerCase().contains('weak') || item.marketStatus.toLowerCase().contains('subdued');

    final badgeColor = isHigh
        ? const Color(0xFF15803D)
        : isLow
            ? const Color(0xFFDC2626)
            : const Color(0xFFD97706);

    final statusText = isHigh
        ? l10n.highMarket
        : isLow
            ? l10n.lowMarket
            : l10n.moderateMarket;

    final localizedCropName = _getLocalizedCropName(l10n, item.cropName);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF1F5F9),
                child: Text(
                  localizedCropName.substring(0, 1).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        localizedCropName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    if (item.isFarmerCrop) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.yourCrop,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Status Badge (Dynamic: Low Market / Moderate Market / High Market)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Price & MSP Comparison Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.marketPrice,
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                      ),
                      Text(
                        '₹${item.unitPrice.round()} / quintal',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.mspPrice != null && item.mspPrice! > 0) ...[
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.govtMsp,
                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                        ),
                        Text(
                          '₹${item.mspPrice!.round()} / quintal',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.marketVsMspLabel != null)
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l10n.difference,
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)),
                          ),
                          Text(
                            item.marketVsMspLabel!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: (item.marketVsMsp ?? 0) >= 0
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketInsightCard(MarketInsightModel insight) {
    final genTimeStr = insight.generatedAt != null && insight.generatedAt!.length >= 16
        ? insight.generatedAt!.substring(0, 16).replaceAll('T', ' ')
        : 'Generated on Login';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('🌱', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        insight.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            insight.content,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF15803D),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Source: ${insight.dataSource}',
                  style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF166534).withOpacity(0.7)),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Insight generated: $genTimeStr',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF166534).withOpacity(0.7)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
