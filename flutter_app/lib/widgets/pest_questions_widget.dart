import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';

/// Pest Detection Page 3 - Questions Screen.
/// Strictly matches the original reference image ("3. Questions (1/5)").
/// Displays dynamic Gemini-generated Yes/No follow-up questions one at a time (EXACTLY 5 questions),
/// with compact progress indicator, solid green plant icon, Yes/No cards, Back/Next navigation, and Skip option.
/// Balanced vertical spacing matching reference proportions without giant empty gaps.
class PestQuestionsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final VoidCallback onBack;
  final Function(Map<String, String> answers) onComplete;

  const PestQuestionsWidget({
    super.key,
    required this.questions,
    required this.onBack,
    required this.onComplete,
  });

  @override
  State<PestQuestionsWidget> createState() => _PestQuestionsWidgetState();
}

class _PestQuestionsWidgetState extends State<PestQuestionsWidget> {
  int _currentIndex = 0;
  final Map<String, String> _answers = {}; // question_id -> 'yes', 'no', 'skipped'

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalQuestions = widget.questions.length;

    if (totalQuestions == 0) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.questionsError,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                    ),
                    onPressed: widget.onBack,
                    child: Text(
                      l10n.previousBtn,
                      style: GoogleFonts.dmSans(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentQ = widget.questions[_currentIndex];
    final String qId = (currentQ['id'] ?? 'q${_currentIndex + 1}').toString();
    final String qText = (currentQ['question'] ?? '').toString();
    final String hText = (currentQ['helper_text'] ?? '').toString();
    final String? selectedAnswer = _answers[qId];

    final bool isYesSelected = selectedAnswer == 'yes';
    final bool isNoSelected = selectedAnswer == 'no';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP HEADER (Back Arrow + "Question X of 5")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 22),
                      onPressed: _handleTopBackTap,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  Text(
                    l10n.questionProgress(_currentIndex + 1, totalQuestions),
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 2. COMPACT 5-NODE PROGRESS INDICATOR
            _buildProgressDotsBar(totalQuestions),

            const SizedBox(height: 16),

            // MAIN CONTENT AREA (Naturally distributed vertical layout)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),

                    // 3. CENTERED SOLID GREEN PLANT ICON BADGE
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF65A30D), // Bright lime-green solid circle from reference
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.eco,
                          color: Colors.white, // Pure white plant icon
                          size: 36,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 4. MAIN QUESTION TEXT (Centered, Bold, Dark Navy)
                    Text(
                      qText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.35,
                        letterSpacing: -0.2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 5. HELPER TEXT
                    Text(
                      hText.isNotEmpty ? hText : l10n.thisHelpsUnderstand,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF475569),
                        height: 1.45,
                      ),
                    ),

                    // MODERATE GAP ONLY BEFORE YES/NO CARDS (Middle to Lower-Middle Placement)
                    const SizedBox(height: 40),

                    // 6. YES / NO ANSWER CARDS (Side by Side, Increased Size & Padding)
                    Row(
                      children: [
                        // YES CARD
                        Expanded(
                          child: _buildAnswerCard(
                            label: l10n.yesLabel,
                            isSelected: isYesSelected,
                            accentColor: const Color(0xFF65A30D),
                            fillColor: const Color(0xFFF7FEE7),
                            icon: Icons.check,
                            onTap: () {
                              setState(() {
                                _answers[qId] = 'yes';
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 16),

                        // NO CARD
                        Expanded(
                          child: _buildAnswerCard(
                            label: l10n.noLabel,
                            isSelected: isNoSelected,
                            accentColor: const Color(0xFFDC2626),
                            fillColor: const Color(0xFFFEF2F2),
                            icon: Icons.close,
                            onTap: () {
                              setState(() {
                                _answers[qId] = 'no';
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 7. BACK / NEXT BUTTONS ROW
                    Row(
                      children: [
                        // BACK BUTTON
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _handleTopBackTap,
                            icon: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF334155)),
                            label: Text(
                              l10n.previousBtn,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // NEXT BUTTON
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF15803D),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _handleNextTap,
                            label: Text(
                              _currentIndex == totalQuestions - 1
                                  ? (l10n.languageCode == 'hi'
                                      ? 'समाप्त करें'
                                      : l10n.languageCode == 'mr'
                                          ? 'पूर्ण करा'
                                          : 'Finish')
                                  : l10n.nextBtn,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // 8. NOT SURE? SKIP THIS QUESTION LINK (Increased font size)
                    Center(
                      child: InkWell(
                        onTap: _handleSkipTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.dmSans(
                                fontSize: 15.5,
                                color: const Color(0xFF4338CA), // Indigo/blue text matching reference
                              ),
                              children: [
                                TextSpan(
                                  text: '${l10n.notSure} ',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                TextSpan(
                                  text: l10n.skipQuestion,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles Back arrow tap.
  void _handleTopBackTap() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    } else {
      widget.onBack();
    }
  }

  /// Handles Next button tap.
  void _handleNextTap() {
    final l10n = AppLocalizations.of(context);
    final currentQ = widget.questions[_currentIndex];
    final String qId = (currentQ['id'] ?? 'q${_currentIndex + 1}').toString();

    if (!_answers.containsKey(qId) || _answers[qId] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectAnswer),
          backgroundColor: Colors.amber.shade900,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    _advanceOrComplete();
  }

  /// Handles "Skip this question" tap.
  void _handleSkipTap() {
    final currentQ = widget.questions[_currentIndex];
    final String qId = (currentQ['id'] ?? 'q${_currentIndex + 1}').toString();

    // Mark as skipped without overwriting yes/no
    _answers[qId] = 'skipped';
    _advanceOrComplete();
  }

  /// Moves to next question or completes the flow.
  void _advanceOrComplete() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      widget.onComplete(_answers);
    }
  }

  /// Renders individual Yes/No Answer Card matching reference proportions.
  Widget _buildAnswerCard({
    required String label,
    required bool isSelected,
    required Color accentColor,
    required Color fillColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? fillColor : Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: accentColor.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected ? accentColor.withOpacity(0.08) : Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? accentColor : (icon == Icons.check ? const Color(0xFF65A30D) : const Color(0xFFDC2626)),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the compact 5-node horizontal progress dots bar matching reference image.
  Widget _buildProgressDotsBar(int totalCount) {
    return SizedBox(
      width: 220, // Compact width centered on screen
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalCount * 2 - 1, (index) {
          if (index.isEven) {
            final itemIndex = index ~/ 2;
            final bool isCompleted = itemIndex < _currentIndex;
            final bool isCurrent = itemIndex == _currentIndex;

            return Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted || isCurrent
                    ? const Color(0xFF65A30D)
                    : const Color(0xFFCBD5E1),
              ),
              child: isCurrent
                  ? Center(
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            );
          } else {
            final lineSegmentIndex = index ~/ 2;
            final bool isPassed = lineSegmentIndex < _currentIndex;

            return Expanded(
              child: Container(
                height: 2.0,
                color: isPassed ? const Color(0xFF65A30D) : const Color(0xFFE2E8F0),
              ),
            );
          }
        }),
      ),
    );
  }
}
