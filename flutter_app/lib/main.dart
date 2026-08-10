import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const KisaanMitraApp());
}

class KisaanMitraApp extends StatefulWidget {
  const KisaanMitraApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _KisaanMitraAppState? state =
        context.findAncestorStateOfType<_KisaanMitraAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<KisaanMitraApp> createState() => _KisaanMitraAppState();
}

class _KisaanMitraAppState extends State<KisaanMitraApp> {
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'en';
    setState(() {
      _locale = Locale(langCode);
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kisaan Mitra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: _locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('hi', ''),
        Locale('mr', ''),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
