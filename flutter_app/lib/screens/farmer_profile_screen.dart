import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'add_farm_screen.dart';

/// Farmer Profile screen (Step 1 of 2).
/// Collects: Farmer Name, Phone Number (for login/account), Village.
class FarmerProfileScreen extends StatefulWidget {
  final String language;

  const FarmerProfileScreen({super.key, required this.language});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  late AppLocalizations _l10n;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _l10n = AppLocalizations(widget.language);
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

              const SizedBox(height: 24),

              // Avatar icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.chipBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person, color: AppColors.primary, size: 28),
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                _l10n.yourFarmerProfile,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _l10n.profileSubtitle,
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

                      // Village
                      _buildLabel(_l10n.village),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _villageController,
                        hint: _l10n.villageHint,
                        icon: Icons.home_outlined,
                        keyboardType: TextInputType.text,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Next button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canProceed()
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddFarmScreen(
                                language: widget.language,
                                farmerName: _nameController.text.trim(),
                                phoneNumber: _phoneController.text.trim(),
                                village: _villageController.text.trim(),
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
                        _l10n.nextAddFarm,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
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

  bool _canProceed() {
    return _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().length == 10;
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    super.dispose();
  }
}
