import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Centralized Secure Session & Lifecycle Authentication Manager.
/// Stores sensitive JWT tokens in platform Keystore/Keychain/DPAPI via FlutterSecureStorage.
class AuthSessionManager with WidgetsBindingObserver {
  static final AuthSessionManager _instance = AuthSessionManager._internal();
  factory AuthSessionManager() => _instance;
  AuthSessionManager._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    wOptions: WindowsOptions(useBackwardCompatibility: false),
  );

  static const String _kAccessToken = 'km_access_token_v2';
  static const String _kRefreshToken = 'km_refresh_token_v2';
  static const String _kUserPhone = 'user_phone';
  static const String _kCachedProfile = 'km_cached_profile_v2';

  Timer? _keepAliveTimer;
  bool _isObserverRegistered = false;

  /// Initialize lifecycle observer and periodic session validation.
  void initialize() {
    if (!_isObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverRegistered = true;
    }
    _startKeepAliveTimer();
  }

  /// Store session tokens and user data securely.
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    try {
      await _secureStorage.write(key: _kAccessToken, value: accessToken);
      await _secureStorage.write(key: _kRefreshToken, value: refreshToken);

      final String phone = user['phone_number']?.toString() ?? '';
      if (phone.isNotEmpty) {
        await _secureStorage.write(key: _kUserPhone, value: phone);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kUserPhone, phone);
      }

      await _secureStorage.write(key: _kCachedProfile, value: jsonEncode(user));
    } catch (e) {
      debugPrint('[AUTH SESSION SAVE ERROR] $e');
      // Graceful fallback to SharedPreferences if secure storage has platform exception
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAccessToken, accessToken);
      await prefs.setString(_kRefreshToken, refreshToken);
      await prefs.setString(_kCachedProfile, jsonEncode(user));
    }
  }

  /// Retrieve current access token.
  static Future<String?> getAccessToken() async {
    try {
      final token = await _secureStorage.read(key: _kAccessToken);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccessToken);
  }

  /// Retrieve current refresh token.
  static Future<String?> getRefreshToken() async {
    try {
      final token = await _secureStorage.read(key: _kRefreshToken);
      if (token != null && token.isNotEmpty) return token;
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefreshToken);
  }

  /// Retrieve authenticated user phone number.
  static Future<String?> getUserPhone() async {
    try {
      final phone = await _secureStorage.read(key: _kUserPhone);
      if (phone != null && phone.isNotEmpty) return phone;
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserPhone);
  }

  /// Retrieve locally cached user profile.
  static Future<Map<String, dynamic>?> getCachedUserProfile() async {
    try {
      String? jsonStr = await _secureStorage.read(key: _kCachedProfile);
      if (jsonStr == null || jsonStr.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        jsonStr = prefs.getString(_kCachedProfile);
      }
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[AUTH GET CACHED PROFILE ERROR] $e');
    }
    return null;
  }

  /// Completely clear all session credentials and tokens (on logout / delete account).
  static Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: _kAccessToken);
      await _secureStorage.delete(key: _kRefreshToken);
      await _secureStorage.delete(key: _kUserPhone);
      await _secureStorage.delete(key: _kCachedProfile);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAccessToken);
      await prefs.remove(_kRefreshToken);
      await prefs.remove(_kUserPhone);
      await prefs.remove(_kCachedProfile);

      final allKeys = prefs.getKeys();
      for (final k in allKeys) {
        if (k.startsWith('cached_dashboard_') || k.startsWith('pest_report_history_')) {
          await prefs.remove(k);
        }
      }
    } catch (_) {}

    _instance._stopKeepAliveTimer();
  }

  /// Periodically validate session while app is in the foreground (every 15 min).
  void _startKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      final token = await getAccessToken();
      if (token != null && token.isNotEmpty) {
        try {
          await ApiService.validateSession();
        } catch (e) {
          debugPrint('[KEEP ALIVE VALIDATION] $e');
        }
      }
    });
  }

  void _stopKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Validate session when app returns to foreground
      _startKeepAliveTimer();
      _validateForegroundSession();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Pause keep-alive timer when backgrounded (zero background battery drain)
      _stopKeepAliveTimer();
    }
  }

  Future<void> _validateForegroundSession() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      final user = await ApiService.validateSession();
      if (user != null) {
        final rToken = await getRefreshToken();
        if (rToken != null) {
          await saveSession(accessToken: token, refreshToken: rToken, user: user);
        }
      }
    } catch (e) {
      debugPrint('[RESUME SESSION VALIDATION] $e');
    }
  }

  void dispose() {
    if (_isObserverRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserverRegistered = false;
    }
    _stopKeepAliveTimer();
  }
}
