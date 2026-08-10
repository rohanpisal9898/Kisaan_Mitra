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
    required String sowingDate,
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
