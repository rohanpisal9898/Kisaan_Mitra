import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../models/sown_dashboard_model.dart';

class RecommendationsCardWidget extends StatefulWidget {
  final List<RecommendationItemModel> recommendations;

  const RecommendationsCardWidget({
    super.key,
    required this.recommendations,
  });

  @override
  State<RecommendationsCardWidget> createState() => _RecommendationsCardWidgetState();
}

class _RecommendationsCardWidgetState extends State<RecommendationsCardWidget> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    if (!kIsWeb) {
      try {
        _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
        );
      } catch (e) {
        debugPrint('iOS Audio Category setup error: $e');
      }
    }

    try {
      _flutterTts.setCompletionHandler(() {
        debugPrint('TTS: Playback complete');
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts.setCancelHandler(() {
        debugPrint('TTS: Playback cancelled');
        if (mounted) setState(() => _isSpeaking = false);
      });
      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error Handler: $msg');
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (e) {
      debugPrint('TTS handlers setup error: $e');
    }
  }

  Future<void> _toggleSpeech(String langCode) async {
    if (_isSpeaking) {
      try {
        await _flutterTts.stop();
      } catch (_) {}
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }

    try {
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 50));

      List<String> candidates;
      if (langCode == 'mr') {
        // On Web, Chrome lacks a native mr-IN voice pack. Routing to hi-IN (Devanagari) allows Chrome's Google Hindi voice to speak Marathi Devanagari text perfectly!
        candidates = kIsWeb
            ? ['hi-IN', 'hi_IN', 'hi', 'mr-IN', 'mr']
            : ['mr-IN', 'mr_IN', 'mr', 'hi-IN', 'hi_IN', 'hi'];
      } else if (langCode == 'hi') {
        candidates = ['hi-IN', 'hi_IN', 'hi', 'en-IN'];
      } else {
        candidates = ['en-IN', 'en_IN', 'en-US', 'en'];
      }

      bool langSet = false;
      for (final lang in candidates) {
        try {
          var isAvail = await _flutterTts.isLanguageAvailable(lang);
          if (isAvail == true || isAvail == 1 || isAvail == '1') {
            var res = await _flutterTts.setLanguage(lang);
            debugPrint('TTS: setLanguage($lang) returned: $res');
            langSet = true;
            break;
          }
        } catch (e) {
          debugPrint('TTS: Language check failed for $lang: $e');
        }
      }

      if (!langSet) {
        for (final lang in candidates) {
          try {
            var res = await _flutterTts.setLanguage(lang);
            debugPrint('TTS: Fallback setLanguage($lang) returned: $res');
            langSet = true;
            break;
          } catch (e) {
            debugPrint('TTS: Fallback setLanguage failed for $lang: $e');
          }
        }
      }

      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      final titlesToRead = widget.recommendations
          .map((r) => r.title)
          .where((t) => t.isNotEmpty)
          .join('. ');

      if (titlesToRead.isNotEmpty) {
        if (mounted) setState(() => _isSpeaking = true);
        var res = await _flutterTts.speak(titlesToRead);
        debugPrint('TTS: speak() returned: $res');
      }
    } catch (e) {
      debugPrint('TTS Speak Error: $e');
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.recommendations.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final currentLang = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with Speaker Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.topRecommendations,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Speaker TTS Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _toggleSpeech(currentLang),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isSpeaking
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isSpeaking
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isSpeaking
                            ? Icons.volume_up_rounded
                            : Icons.volume_up_outlined,
                        size: 18,
                        color: _isSpeaking
                            ? const Color(0xFF15803D)
                            : const Color(0xFF64748B),
                      ),
                      if (_isSpeaking) ...[
                        const SizedBox(width: 4),
                        Text(
                          'Playing...',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Recommendation Items List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.recommendations.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = widget.recommendations[index];
            return _buildRecommendationTile(context, l10n, item);
          },
        ),
      ],
    );
  }

  Widget _buildRecommendationTile(
    BuildContext context,
    AppLocalizations l10n,
    RecommendationItemModel item,
  ) {
    final cat = (item.category.isNotEmpty ? item.category : item.type).toLowerCase();

    Color bgIconColor;
    Widget iconWidget;

    if (cat.contains('irrigation') || cat.contains('water')) {
      bgIconColor = const Color(0xFFEFF6FF); // Light blue
      iconWidget = const Icon(Icons.water_drop_outlined, color: Color(0xFF0284C7), size: 22);
    } else if (cat.contains('pest') || cat.contains('disease') || cat.contains('health')) {
      bgIconColor = const Color(0xFFFFF7ED); // Light orange/yellow
      iconWidget = const Icon(Icons.bug_report_outlined, color: Color(0xFFEA580C), size: 22);
    } else if (cat.contains('fert') || cat.contains('nutrit') || cat.contains('stage')) {
      bgIconColor = const Color(0xFFF0FDF4); // Light green
      iconWidget = const Icon(Icons.eco_outlined, color: Color(0xFF16A34A), size: 22);
    } else {
      bgIconColor = const Color(0xFFF0FDF4);
      iconWidget = const Icon(Icons.lightbulb_outline, color: Color(0xFF16A34A), size: 22);
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () => _showDetailBottomSheet(context, l10n, item, iconWidget),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Category-Specific Icon Container
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: bgIconColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: iconWidget),
              ),
              const SizedBox(width: 14),

              // Title and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Right arrow chevron
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailBottomSheet(
    BuildContext context,
    AppLocalizations l10n,
    RecommendationItemModel item,
    Widget iconWidget,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  iconWidget,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                l10n.whyRecommendation,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF334155),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.gotIt,
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
  }
}
