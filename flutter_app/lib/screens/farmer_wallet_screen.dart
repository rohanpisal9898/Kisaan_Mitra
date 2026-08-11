import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Live Recalculation Helpers
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

  Future<void> _adjustExpense(ExpenseItemModel item, double delta) async {
    final newAmount = (item.amount + delta).clamp(0.0, 10000000.0);
    if (newAmount == item.amount) return;

    setState(() {
      item.amount = newAmount;
      _recalculateProfit();
    });

    try {
      await ApiService.updateExpense(
        phoneNumber: _userPhone,
        expenseId: item.id,
        amount: newAmount,
      );
    } catch (e) {
      debugPrint('Failed saving expense update: $e');
    }
  }

  Future<void> _deleteExpense(ExpenseItemModel item) async {
    setState(() {
      _walletData?.expenses.removeWhere((e) => e.id == item.id);
      _recalculateProfit();
    });

    try {
      await ApiService.deleteExpense(
        phoneNumber: _userPhone,
        expenseId: item.id,
      );
    } catch (e) {
      debugPrint('Failed deleting expense: $e');
    }
  }

  void _showAddExpenseModal() {
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
                      Text(
                        'Add Expense',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
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
                    'Category',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
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
                              child: Text(c, style: GoogleFonts.inter(fontSize: 14)),
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
                      'Custom Category Name',
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
                    'Amount (₹)',
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
                        'Save Expense',
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
              'Unable to load Financial Shield',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D)),
              onPressed: _loadWalletData,
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final data = _walletData!;
    final ps = data.profitSummary;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          Text(
            'Farmer Wallet',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Financial overview for your farm',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),

          // Fallback Alerts if Farm Area, Crop or Yield Missing
          if (!data.hasFarmArea) ...[
            _buildWarningBanner('Add your farm area to view your financial outlook.'),
            const SizedBox(height: 14),
          ],
          if (!data.hasCrop) ...[
            _buildWarningBanner('Select a crop to view your financial outlook.'),
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
          _buildExpectedProfitCard(ps, data),

          const SizedBox(height: 16),

          // 3. FINANCIAL OUTLOOK CARD
          _buildFinancialOutlookCard(ps),

          const SizedBox(height: 20),

          // 4. YOUR FARM COSTS SECTION
          _buildFarmCostsSection(data),

          const SizedBox(height: 24),

          // 5. OILSEED MARKET TODAY SECTION
          _buildMarketTodaySection(data),

          const SizedBox(height: 16),

          // 6. GEMINI MARKET INSIGHT
          if (data.marketInsight != null && data.marketInsight!.available) ...[
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

  Widget _buildExpectedProfitCard(ProfitSummaryModel ps, WalletOverviewModel data) {
    final cardBg = ps.isLoss
        ? const LinearGradient(colors: [Color(0xFF991B1B), Color(0xFF7F1D1D)])
        : const LinearGradient(colors: [Color(0xFF16834A), Color(0xFF14532D)]);

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
            ps.displayTitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ps.formattedExpectedProfit,
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProfitCol('MINIMUM', ps.formattedMinProfit),
                Container(height: 24, width: 1, color: Colors.white.withOpacity(0.25)),
                _buildProfitCol('EXPECTED', ps.formattedExpectedProfit),
                Container(height: 24, width: 1, color: Colors.white.withOpacity(0.25)),
                _buildProfitCol('MAXIMUM', ps.formattedMaxProfit),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Based on predicted yield • 90% confidence range',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Estimated financial outlook — actual returns may vary.',
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
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.75),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialOutlookCard(ProfitSummaryModel ps) {
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
              Text(
                'Your Financial Outlook',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expected Profit',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              ),
              Text(
                ps.formattedExpectedProfit,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ps.isLoss ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Safe Planning Range',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
              ),
              Text(
                '${ps.formattedMinProfit} – ${ps.formattedExpectedProfit}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
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
              '💡 Plan your expenses around the lower estimate to reduce financial risk.',
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

  Widget _buildFarmCostsSection(WalletOverviewModel data) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF15803D), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Your Farm Costs',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                data.historicalCostBenchmarkNote,
                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8)),
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
              return _buildExpenseRow(item);
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
              'Add Expense',
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Cost',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                _formatIndianCurrency(data.profitSummary.totalCost),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(ExpenseItemModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(_getCategoryIcon(item.category), size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            _formatIndianCurrency(item.amount),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
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

          // Delete Button
          IconButton(
            onPressed: () => _deleteExpense(item),
            icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFF94A3B8)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketTodaySection(WalletOverviewModel data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Color(0xFF15803D), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Oilseed Market Data',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            Text(
              '${data.state} • Benchmark dataset',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
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
            return _buildMarketCard(item);
          },
        ),
      ],
    );
  }

  Widget _buildMarketCard(MarketItemModel item) {
    final isStrong = item.marketStatus.toLowerCase().contains('strong');
    final isModerate = item.marketStatus.toLowerCase().contains('moderate');
    final badgeColor = isStrong
        ? const Color(0xFF15803D)
        : isModerate
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isFarmerCrop ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
          width: item.isFarmerCrop ? 1.5 : 1.0,
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
                  item.cropName.substring(0, 1).toUpperCase(),
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
                    Text(
                      item.cropName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
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
                          'Your Crop',
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

              // Status Badge
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
                      item.marketStatus,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Market Price',
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
                if (item.mspPrice != null && item.mspPrice! > 0) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Govt MSP',
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
                  if (item.marketVsMspLabel != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Difference',
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    insight.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF166534),
                    ),
                  ),
                ],
              ),

              // Manual Refresh Icon Button (Respects 5-min Cooldown)
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF15803D)),
                onPressed: () async {
                  try {
                    final jsonRes = await ApiService.refreshInsight(phoneNumber: _userPhone);
                    final updatedModel = WalletOverviewModel.fromJson(jsonRes);
                    setState(() {
                      _walletData = updatedModel;
                    });
                  } catch (e) {
                    debugPrint('Insight refresh error: $e');
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Source: ${insight.dataSource}',
                style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF166534).withOpacity(0.7)),
              ),
              Text(
                'Insight generated: $genTimeStr',
                style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF166534).withOpacity(0.7)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
