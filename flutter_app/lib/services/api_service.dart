import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to communicate with the FastAPI backend.
/// Flutter NEVER reads the CSV directly — all data comes through these API calls.
class ApiService {
  /// Dynamic base URL: localhost for Web/Windows, 10.0.2.2 for Android emulator
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000';
    }
  }

  // ─── Location APIs ─────────────────────────────────────

  /// Fetch all states from MongoDB via FastAPI.
  /// GET /api/v1/locations/states
  static Future<List<String>> fetchStates() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/locations/states'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['states']);
    } else {
      throw Exception('Failed to load states');
    }
  }

  /// Fetch districts for a given state from MongoDB via FastAPI.
  /// GET /api/v1/locations/districts/{state}
  static Future<List<String>> fetchDistricts(String state) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/locations/districts/${Uri.encodeComponent(state)}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['districts']);
    } else {
      throw Exception('Failed to load districts for $state');
    }
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

  // ─── User APIs ─────────────────────────────────────────

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
      return json.decode(response.body);
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
      return json.decode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  /// Get user by phone number.
  /// GET /api/v1/users/{phone_number}
  static Future<Map<String, dynamic>?> getUser(String phoneNumber) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/users/${Uri.encodeComponent(phoneNumber)}'),
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
  /// PUT /api/v1/users/{phone_number}
  static Future<Map<String, dynamic>?> updateUser(
    String phoneNumber,
    Map<String, dynamic> updateData,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/v1/users/${Uri.encodeComponent(phoneNumber)}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updateData),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update user: ${response.body}');
    }
  }

  // ─── Pest Detection APIs ─────────────────────────────────

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
      'user_id': userId ?? 'guest',
      'filename': filename,
      'language': language ?? 'English',
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
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

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
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

  /// Fetch multi-state Dashboard Overview (no_crop, growing, crop_matured) from FastAPI.
  /// GET /api/v1/dashboard/overview?phone_number={phoneNumber}&language={language}
  static Future<Map<String, dynamic>> fetchDashboardOverview({
    String? phoneNumber,
    String language = 'English',
  }) async {
    String query = 'language=${Uri.encodeComponent(language)}';
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      query += '&phone_number=${Uri.encodeComponent(phoneNumber)}';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/dashboard/overview?$query'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch dashboard overview data');
    }
  }

  /// Fetch Sown Dashboard data from FastAPI backend.
  /// GET /api/v1/dashboard/sown?phone_number={phoneNumber}&language={language}
  static Future<Map<String, dynamic>> fetchSownDashboard({
    String? phoneNumber,
    String language = 'English',
  }) async {
    String query = 'language=${Uri.encodeComponent(language)}';
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      query += '&phone_number=${Uri.encodeComponent(phoneNumber)}';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/dashboard/sown?$query'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch sown dashboard data');
    }
  }

  // ─── Wallet APIs ───────────────────────────────────────

  /// Fetch Farmer Wallet & Financial Shield summary.
  /// GET /api/v1/wallet/overview?phone_number={phoneNumber}
  static Future<Map<String, dynamic>> fetchWalletOverview({
    String? phoneNumber,
  }) async {
    String query = '';
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      query = '?phone_number=${Uri.encodeComponent(phoneNumber)}';
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/wallet/overview$query'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch wallet overview');
    }
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
  /// POST /api/v1/wallet/insight/refresh?phone_number={phoneNumber}
  static Future<Map<String, dynamic>> refreshInsight({
    String? phoneNumber,
  }) async {
    String query = '';
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      query = '?phone_number=${Uri.encodeComponent(phoneNumber)}';
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/wallet/insight/refresh$query'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to refresh market insight');
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


