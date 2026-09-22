import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_session_manager.dart';

/// Service to communicate with the FastAPI backend.
/// Flutter NEVER reads the CSV directly — all data comes through these API calls.
class ApiService {
  /// Dynamic base URL: local backend for development, Render for production
  static String get baseUrl {
    if (kDebugMode) {
      if (kIsWeb) return 'http://localhost:8000';
      if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8000';
      return 'http://127.0.0.1:8000';
    }
    return 'https://kisaan-mitra-y65q.onrender.com';
  }

  static final Map<String, Future<dynamic>> _inFlightRequests = {};
  static List<String>? _cachedStates;
  static final Map<String, List<String>> _cachedDistricts = {};

  /// Deduplicate in-flight requests to avoid redundant simultaneous network calls
  static Future<T> _deduplicate<T>(String key, Future<T> Function() action) {
    if (_inFlightRequests.containsKey(key)) {
      return _inFlightRequests[key] as Future<T>;
    }
    final future = action().whenComplete(() {
      _inFlightRequests.remove(key);
    });
    _inFlightRequests[key] = future;
    return future;
  }

  /// Helper to get JSON headers with Bearer token if available
  static Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = await AuthSessionManager.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ─── Location APIs ─────────────────────────────────────

  /// Fetch all states with in-memory caching and request deduplication.
  /// GET /api/v1/locations/states
  static Future<List<String>> fetchStates() async {
    if (_cachedStates != null && _cachedStates!.isNotEmpty) {
      return _cachedStates!;
    }
    return _deduplicate('locations_states', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/locations/states'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedStates = List<String>.from(data['states']);
        return _cachedStates!;
      } else {
        throw Exception('Failed to load states');
      }
    });
  }

  /// Fetch districts for a given state with in-memory caching.
  /// GET /api/v1/locations/districts/{state}
  static Future<List<String>> fetchDistricts(String state) async {
    final stateKey = state.trim().toLowerCase();
    if (_cachedDistricts.containsKey(stateKey)) {
      return _cachedDistricts[stateKey]!;
    }
    return _deduplicate('districts_$stateKey', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/locations/districts/${Uri.encodeComponent(state)}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = List<String>.from(data['districts']);
        _cachedDistricts[stateKey] = list;
        return list;
      } else {
        throw Exception('Failed to load districts for $state');
      }
    });
  }

  /// Find nearest district from GPS coordinates.
  /// GET /api/v1/locations/nearest-district?latitude=&longitude=
  static Future<Map<String, dynamic>> findNearestDistrict(
    double latitude,
    double longitude,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/v1/locations/nearest-district?latitude=$latitude&longitude=$longitude',
      ),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to find nearest district');
    }
  }

  // ─── User & Session APIs ───────────────────────────────

  /// Log in an existing user with phone_number & password.
  /// POST /api/v1/users/login
  static Future<Map<String, dynamic>> loginUser({
    required String phoneNumber,
    required String password,
  }) async {
    final body = {
      'phone_number': phoneNumber,
      'password': password,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/users/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final accessToken = data['access_token']?.toString() ?? '';
      final refreshToken = data['refresh_token']?.toString() ?? '';
      final user = (data['user'] as Map<String, dynamic>?) ?? data;
      if (accessToken.isNotEmpty) {
        await AuthSessionManager.saveSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
        );
      }
      return user;
    } else if (response.statusCode == 404) {
      throw Exception('ACCOUNT_NOT_FOUND');
    } else if (response.statusCode == 401) {
      throw Exception('INVALID_PASSWORD');
    } else {
      try {
        final errorData = json.decode(response.body);
        throw Exception(errorData['detail'] ?? 'Login failed');
      } catch (e) {
        if (e is Exception && !e.toString().contains('FormatException')) {
          rethrow;
        }
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  }

  /// Register a new user (onboarding complete).
  /// POST /api/v1/users/register
  static Future<Map<String, dynamic>> registerUser({
    required String phoneNumber,
    String password = '123456',
    required String farmerName,
    required String village,
    required String language,
    required String state,
    required String district,
    double? latitude,
    double? longitude,
    required String currentCrop,
    required double farmArea,
    required String farmAreaUnit,
    String? sowingDate,
    String farmLocation = '',
  }) async {
    final body = {
      'phone_number': phoneNumber,
      'password': password,
      'farmer_name': farmerName,
      'village': village,
      'language': language,
      'state': state,
      'district': district,
      'latitude': latitude,
      'longitude': longitude,
      'current_crop': currentCrop,
      'farm_area': farmArea,
      'farm_area_unit': farmAreaUnit,
      'sowing_date': sowingDate,
      'farm_location': farmLocation,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final accessToken = data['access_token']?.toString() ?? '';
      final refreshToken = data['refresh_token']?.toString() ?? '';
      final user = (data['user'] as Map<String, dynamic>?) ?? data;
      if (accessToken.isNotEmpty) {
        await AuthSessionManager.saveSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
        );
      }
      return user;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  /// Validate current session with backend.
  /// GET /api/v1/users/me
  static Future<Map<String, dynamic>?> validateSession() async {
    final token = await AuthSessionManager.getAccessToken();
    if (token == null || token.isEmpty) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      // Attempt token refresh
      final refreshed = await refreshTokens();
      if (refreshed) {
        final newToken = await AuthSessionManager.getAccessToken();
        if (newToken != null && newToken.isNotEmpty) {
          final retryRes = await http.get(
            Uri.parse('$baseUrl/api/v1/users/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken',
            },
          );
          if (retryRes.statusCode == 200) {
            return json.decode(retryRes.body) as Map<String, dynamic>;
          }
        }
      }
      await AuthSessionManager.clearSession();
      return null;
    }
    return null;
  }

  /// Exchange refresh token for a fresh access token.
  /// POST /api/v1/users/refresh
  static Future<bool> refreshTokens() async {
    try {
      final refreshToken = await AuthSessionManager.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/users/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccess = data['access_token']?.toString() ?? '';
        final newRefresh = data['refresh_token']?.toString() ?? '';
        final user = await AuthSessionManager.getCachedUserProfile() ?? {};
        if (newAccess.isNotEmpty) {
          await AuthSessionManager.saveSession(
            accessToken: newAccess,
            refreshToken: newRefresh.isNotEmpty ? newRefresh : refreshToken,
            user: user,
          );
          return true;
        }
      }
    } catch (e) {
      debugPrint('[REFRESH TOKEN ERROR] $e');
    }
    return false;
  }

  /// Permanently delete user account and invalidate session.
  /// DELETE /api/v1/users/me
  static Future<bool> deleteAccount() async {
    final token = await AuthSessionManager.getAccessToken();
    if (token == null || token.isEmpty) return false;

    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      await AuthSessionManager.clearSession();
      return true;
    }
    return false;
  }

  /// Get user by phone number (backward compatible).
  /// GET /api/v1/users/{phone_number}
  static Future<Map<String, dynamic>?> getUser(String phoneNumber) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/users/${Uri.encodeComponent(phoneNumber)}'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to get user');
    }
  }

  /// Update user details.
  /// PUT /api/v1/users/{phone_number} or PUT /api/v1/users/me
  static Future<Map<String, dynamic>?> updateUser(
    String phoneNumber,
    Map<String, dynamic> updateData,
  ) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/api/v1/users/${Uri.encodeComponent(phoneNumber)}'),
      headers: headers,
      body: json.encode(updateData),
    );

    if (response.statusCode == 200) {
      final updated = json.decode(response.body) as Map<String, dynamic>;
      final aToken = await AuthSessionManager.getAccessToken();
      final rToken = await AuthSessionManager.getRefreshToken();
      if (aToken != null && rToken != null) {
        await AuthSessionManager.saveSession(accessToken: aToken, refreshToken: rToken, user: updated);
      }
      return updated;
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  // ─── Pest Detection APIs ─────────────────────────────────

  /// Validate whether uploaded image is relevant for crop pest diagnosis.
  /// POST /api/v1/pest-detection/validate
  static Future<Map<String, dynamic>> validatePestImage({
    required dynamic imageFile,
    String? language,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/pest-detection/validate');
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final body = {
        'image_base64': base64Image,
        'language': language ?? 'English',
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return (decoded['validation'] as Map<String, dynamic>?) ?? {
          'is_valid_for_pest_detection': true,
          'category': 'crop_plant',
          'reason': 'Default validation pass',
        };
      }
    } catch (e) {
      print('[VALIDATE IMAGE ERROR] $e');
    }
    // Return fallback pass on error so temporary API issues don't block legitimate users
    return {
      'is_valid_for_pest_detection': true,
      'category': 'crop_plant',
      'reason': 'Validation fallback due to error',
      'is_error': true,
    };
  }

  /// Upload pest scan image (camera or gallery) to FastAPI backend & MongoDB.
  /// POST /api/v1/pest-detection/scan
  static Future<Map<String, dynamic>> uploadPestImage({
    required dynamic imageFile, // XFile from image_picker
    required String source,     // "camera" or "gallery"
    String? userId,
    String? language,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/pest-detection/scan');
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final filename = imageFile.name ?? 'pest_scan.jpg';

    final body = {
      'image_base64': base64Image,
      'source': source,
      'filename': filename,
      'language': language ?? 'English',
    };

    final headers = await _getHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to upload scan image: ${response.body}');
    }
  }

  /// Fetch dynamic AI Diagnosis Report based on scan image and 5 Yes/No answers.
  /// POST /api/v1/pest-detection/diagnosis
  static Future<Map<String, dynamic>> fetchPestDiagnosis({
    String? scanId,
    String? imageBase64,
    Map<String, String>? answers,
    String language = 'English',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/pest-detection/diagnosis');
      final body = {
        'scan_id': scanId,
        'image_base64': imageBase64,
        'answers': answers,
        'language': language,
      };

      final headers = await _getHeaders();

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return (decoded['diagnosis'] as Map<String, dynamic>?) ?? {};
      }
    } catch (e) {
      print('[API SERVICE DIAGNOSIS ERROR] $e');
    }

    return {};
  }

  /// Fetch list of saved pest scan reports for the authenticated user.
  /// GET /api/v1/pest-detection/history
  static Future<List<Map<String, dynamic>>> fetchPestHistory({
    String? userId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/pest-detection/history');
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = decoded['reports'] as List? ?? [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      print('[API SERVICE PEST HISTORY ERROR] $e');
    }
    return [];
  }

  /// Fetch single pest scan report details by scan ID.
  /// GET /api/v1/pest-detection/scans/{scanId}
  static Future<Map<String, dynamic>?> fetchPestReportById(String scanId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/pest-detection/scans/${Uri.encodeComponent(scanId)}');
      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return (decoded['scan'] as Map<String, dynamic>?) ?? {};
      }
    } catch (e) {
      print('[API SERVICE PEST REPORT BY ID ERROR] $e');
    }
    return null;
  }

  /// Fetch multi-state Dashboard Overview (no_crop, growing, crop_matured) with request deduplication.
  /// GET /api/v1/dashboard/overview?phone_number={phoneNumber}&language={language}
  static Future<Map<String, dynamic>> fetchDashboardOverview({
    String? phoneNumber,
    String language = 'English',
  }) async {
    String query = 'language=${Uri.encodeComponent(language)}';
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      query += '&phone_number=${Uri.encodeComponent(phoneNumber)}';
    }

    final key = 'dashboard_overview_${phoneNumber ?? "guest"}_$language';
    return _deduplicate(key, () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/dashboard/overview?$query'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch dashboard overview data');
      }
    });
  }

  /// Fetch Sown Dashboard data with request deduplication.
  /// GET /api/v1/dashboard/sown?phone_number={phoneNumber}&language={language}
  static Future<Map<String, dynamic>> fetchSownDashboard({
    String? phoneNumber,
    String language = 'English',
  }) async {
    String query = 'language=${Uri.encodeComponent(language)}';
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      query += '&phone_number=${Uri.encodeComponent(phoneNumber)}';
    }

    final key = 'dashboard_sown_${phoneNumber ?? "guest"}_$language';
    return _deduplicate(key, () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/dashboard/sown?$query'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch sown dashboard data');
      }
    });
  }

  // ─── Wallet APIs ───────────────────────────────────────

  /// Fetch Farmer Wallet & Financial Shield summary.
  /// GET /api/v1/wallet/overview?phone_number={phoneNumber}&language={language}
  static Future<Map<String, dynamic>> fetchWalletOverview({
    String? phoneNumber,
    String language = 'English',
  }) async {
    String query = 'language=${Uri.encodeComponent(language)}';
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      query += '&phone_number=${Uri.encodeComponent(phoneNumber)}';
    }

    final key = 'wallet_overview_${phoneNumber ?? "guest"}_$language';
    return _deduplicate(key, () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/wallet/overview?$query'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch wallet overview');
      }
    });
  }

  /// Add a new custom expense.
  /// POST /api/v1/wallet/expenses?phone_number={phoneNumber}
  static Future<Map<String, dynamic>> addExpense({
    String? phoneNumber,
    required String category,
    required String label,
    required double amount,
  }) async {
    String query = '';
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      query = '?phone_number=${Uri.encodeComponent(phoneNumber)}';
    }

    final body = {
      'category': category,
      'label': label,
      'amount': amount,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/wallet/expenses$query'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to add expense');
    }
  }

  /// Save/update full list of expenses for the user.
  /// POST /api/v1/wallet/expenses/save?phone_number={phoneNumber}
  static Future<Map<String, dynamic>> saveExpenses({
    String? phoneNumber,
    required List<Map<String, dynamic>> expenses,
  }) async {
    String query = '';
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      query = '?phone_number=${Uri.encodeComponent(phoneNumber)}';
    }

    final body = {
      'expenses': expenses,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/wallet/expenses/save$query'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to save expenses');
    }
  }


  /// Update an existing expense amount.
  /// PUT /api/v1/wallet/expenses/{expenseId}?phone_number={phoneNumber}
  static Future<Map<String, dynamic>> updateExpense({
    String? phoneNumber,
    required String expenseId,
    required double amount,
  }) async {
    String query = '';
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      query = '?phone_number=${Uri.encodeComponent(phoneNumber)}';
    }

    final body = {
      'amount': amount,
    };

    final response = await http.put(
      Uri.parse('$baseUrl/api/v1/wallet/expenses/$expenseId$query'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update expense');
    }
  }

  /// Delete an expense item.
  /// DELETE /api/v1/wallet/expenses/{expenseId}?phone_number={phoneNumber}
  static Future<Map<String, dynamic>> deleteExpense({
    String? phoneNumber,
    required String expenseId,
  }) async {
    String query = '';
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      query = '?phone_number=${Uri.encodeComponent(phoneNumber)}';
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/wallet/expenses/$expenseId$query'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to delete expense');
    }
  }

  /// Manually request a fresh Gemini market insight refresh respecting 5-min cooldown.
  /// POST /api/v1/wallet/insight/refresh?phone_number={phoneNumber}&language={language}
  static Future<Map<String, dynamic>> refreshInsight({
    String? phoneNumber,
    String language = 'English',
  }) async {
    String query = 'language=${Uri.encodeComponent(language)}';
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      query += '&phone_number=${Uri.encodeComponent(phoneNumber)}';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/wallet/insight/refresh?$query'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to refresh market insight');
    }
  }

  // ─── Government Schemes API ────────────────────────────

  /// Fetch Government Schemes (Central & State) using Gemini backend.
  /// GET /api/v1/schemes?phone_number=&state=&language=
  static Future<Map<String, dynamic>> fetchGovernmentSchemes({
    String? phoneNumber,
    String? state,
    String language = 'English',
  }) async {
    try {
      List<String> queryParams = [];
      queryParams.add('language=${Uri.encodeComponent(language)}');
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        queryParams.add('phone_number=${Uri.encodeComponent(phoneNumber)}');
      }
      if (state != null && state.isNotEmpty) {
        queryParams.add('state=${Uri.encodeComponent(state)}');
      }

      final url = '$baseUrl/api/v1/schemes?${queryParams.join('&')}';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching government schemes from backend: $e');
    }

    // Client-side fallback if backend is unreachable or timed out
    return {
      'success': true,
      'source': 'client_fallback',
      'state': state ?? 'Maharashtra',
      'schemes': _getOfflineFallbackSchemes(state ?? 'Maharashtra', language),
    };
  }

  static List<Map<String, dynamic>> _getOfflineFallbackSchemes(String farmerState, String language) {
    final langLower = language.toLowerCase();
    final isHi = langLower.contains('hi') || langLower.contains('hindi');
    final isMr = langLower.contains('mr') || langLower.contains('marathi');

    if (isHi) {
      return [
        {
          'id': 'scheme_1',
          'name': 'पीएम किसान सम्मान निधि',
          'category': 'आय सहायता',
          'description': 'पात्र किसान परिवारों को प्रति वर्ष ₹6,000 की सीधी वित्तीय सहायता। तीन किश्तों में हस्तांतरित।',
          'governmentLevel': 'Central',
          'state': 'All',
          'status': 'सक्रिय',
          'officialUrl': 'https://pmkisan.gov.in/',
        },
        {
          'id': 'scheme_2',
          'name': 'प्रधानमंत्री फसल बीमा योजना (PMFBY)',
          'category': 'फसल बीमा',
          'description': 'प्राकृतिक आपदाओं, कीटों और बीमारियों के कारण होने वाले फसल नुकसान से वित्तीय सुरक्षा प्रदान करता है।',
          'governmentLevel': 'Central',
          'state': 'All',
          'status': 'सक्रिय',
          'officialUrl': 'https://pmfby.gov.in/',
        },
        {
          'id': 'scheme_3',
          'name': 'किसान क्रेडिट कार्ड (KCC)',
          'category': 'कृषि ऋण',
          'description': 'खेती, इनपुट खरीद और फसल के बाद के खर्चों के लिए रियायती ब्याज दर पर ऋण सुविधा।',
          'governmentLevel': 'Central',
          'state': 'All',
          'status': 'सक्रिय',
          'officialUrl': 'https://myscheme.gov.in/schemes/kcc',
        },
        {
          'id': 'scheme_4',
          'name': 'नमो शेतकरी महासन्मान निधि योजना ($farmerState)',
          'category': 'राज्य आय सहायता',
          'description': '$farmerState के किसानों के लिए अतिरिक्त ₹6,000 वार्षिक सहायता जो पीएम-किसान योजना को पूरक बनाती है।',
          'governmentLevel': 'State',
          'state': farmerState,
          'status': 'सक्रिय',
          'officialUrl': 'https://krishi.maharashtra.gov.in/',
        },
        {
          'id': 'scheme_5',
          'name': 'मागेल त्याला शेततळे ($farmerState)',
          'category': 'जल संरक्षण',
          'description': '$farmerState में व्यक्तिगत किसानों को खेत तालाब निर्माण के लिए वित्तीय सब्सिडी प्रदान की जाती है।',
          'governmentLevel': 'State',
          'state': farmerState,
          'status': 'सक्रिय',
          'officialUrl': 'https://krishi.maharashtra.gov.in/',
        },
        {
          'id': 'scheme_6',
          'name': 'मुख्यमंत्री कृषि पंप योजना ($farmerState)',
          'category': 'सौर ऊर्जा एवं सिंचाई',
          'description': '$farmerState के किसानों को दिन के समय सिंचाई सुविधा हेतु रियायती दरों पर सोलर पंप।',
          'governmentLevel': 'State',
          'state': farmerState,
          'status': 'सक्रिय',
          'officialUrl': 'https://krishi.maharashtra.gov.in/',
        },
      ];
    } else if (isMr) {
      return [
        {
          'id': 'scheme_1',
          'name': 'पीएम किसान सन्मान निधी',
          'category': 'उत्पन्न मदत',
          'description': 'पात्र शेतकरी कुटुंबांना दरवर्षी ₹६,००० ची थेट आर्थिक मदत. तीन समान हप्त्यांमध्ये दिली जाते.',
          'governmentLevel': 'Central',
          'state': 'All',
          'status': 'सक्रिय',
          'officialUrl': 'https://pmkisan.gov.in/',
        },
        {
          'id': 'scheme_2',
          'name': 'पंतप्रधान पीक विमा योजना (PMFBY)',
          'category': 'पीक विमा',
          'description': 'नैसर्गिक आपत्ती, कीड व रोगांमुळे होणाऱ्या पिकांच्या नुकसानीस सर्वसमावेशक विमा संरक्षण.',
          'governmentLevel': 'Central',
          'state': 'All',
          'status': 'सक्रिय',
          'officialUrl': 'https://pmfby.gov.in/',
        },
        {
          'id': 'scheme_3',
          'name': 'किसान क्रेडिट कार्ड (KCC)',
          'category': 'शेती कर्ज',
          'description': 'शेती खर्च, बियाणे, खते खरेदीसाठी सवलतीच्या व्याजदरात अल्पमुदतीचे कर्ज.',
          'governmentLevel': 'Central',
          'state': 'All',
          'status': 'सक्रिय',
          'officialUrl': 'https://myscheme.gov.in/schemes/kcc',
        },
        {
          'id': 'scheme_4',
          'name': 'नमो शेतकरी महासन्मान निधी योजना ($farmerState)',
          'category': 'राज्य उत्पन्न मदत',
          'description': '$farmerState मधील शेतकऱ्यांसाठी अतिरिक्त वार्षिक ₹६,००० अर्थसहाय्य.',
          'governmentLevel': 'State',
          'state': farmerState,
          'status': 'सक्रिय',
          'officialUrl': 'https://krishi.maharashtra.gov.in/',
        },
        {
          'id': 'scheme_5',
          'name': 'मागेल त्याला शेततळे योजना ($farmerState)',
          'category': 'जलसंधारण',
          'description': '$farmerState मधील शेतकऱ्यांना सिंचनासाठी शेततळे उभारण्यास शासकीय अनुदान.',
          'governmentLevel': 'State',
          'state': farmerState,
          'status': 'सक्रिय',
          'officialUrl': 'https://krishi.maharashtra.gov.in/',
        },
        {
          'id': 'scheme_6',
          'name': 'मुख्यमंत्री सौर कृषि पंप योजना ($farmerState)',
          'category': 'सौर ऊर्जा व सिंचन',
          'description': '$farmerState मधील शेतकऱ्यांना दिवसा सिंचन उपलब्ध होण्यासाठी सवलतीवर सोलर पंप संच.',
          'governmentLevel': 'State',
          'state': farmerState,
          'status': 'सक्रिय',
          'officialUrl': 'https://krishi.maharashtra.gov.in/',
        },
      ];
    } else {
      return [
        {
          'id': 'scheme_1',
          'name': 'PM Kisan Samman Nidhi',
          'category': 'Income Support',
          'description': 'Direct financial benefit of ₹6,000 per year to eligible farmer families across India in 3 equal installments.',
          'governmentLevel': 'Central',
          'state': 'All',
          'status': 'Active',
          'officialUrl': 'https://pmkisan.gov.in/',
        },
        {
          'id': 'scheme_2',
          'name': 'Pradhan Mantri Fasal Bima Yojana (PMFBY)',
          'category': 'Crop Insurance',
          'description': 'Comprehensive insurance coverage for crop loss due to non-preventable natural risks, pests & diseases.',
          'governmentLevel': 'Central',
          'state': 'All',
          'status': 'Active',
          'officialUrl': 'https://pmfby.gov.in/',
        },
        {
          'id': 'scheme_3',
          'name': 'Kisan Credit Card (KCC)',
          'category': 'Agricultural Credit',
          'description': 'Timely access to short-term credit at subsidized interest rates for crop cultivation and farm maintenance.',
          'governmentLevel': 'Central',
          'state': 'All',
          'status': 'Active',
          'officialUrl': 'https://myscheme.gov.in/schemes/kcc',
        },
        {
          'id': 'scheme_4',
          'name': 'Namo Shetkari MahaSanman Nidhi ($farmerState)',
          'category': 'State Income Support',
          'description': 'Additional annual income support of ₹6,000 provided by the $farmerState Government to local farmers.',
          'governmentLevel': 'State',
          'state': farmerState,
          'status': 'Active',
          'officialUrl': 'https://krishi.maharashtra.gov.in/',
        },
        {
          'id': 'scheme_5',
          'name': 'Magel Tyala Shettale (Farm Pond Scheme - $farmerState)',
          'category': 'Water Conservation',
          'description': 'Financial subsidy for constructing individual farm ponds for sustainable irrigation in $farmerState.',
          'governmentLevel': 'State',
          'state': farmerState,
          'status': 'Active',
          'officialUrl': 'https://krishi.maharashtra.gov.in/',
        },
        {
          'id': 'scheme_6',
          'name': 'Chief Minister Solar Agriculture Pump Scheme ($farmerState)',
          'category': 'Solar Energy & Irrigation',
          'description': 'Subsidized off-grid solar agricultural pumps for daytime irrigation security for farmers in $farmerState.',
          'governmentLevel': 'State',
          'state': farmerState,
          'status': 'Active',
          'officialUrl': 'https://krishi.maharashtra.gov.in/',
        },
      ];
    }
  }

  // ─── Health Check ──────────────────────────────────────

  /// Check if backend is running.
  static Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}


