import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

/// Result object containing location coordinates, resolved State/District, accuracy, and error states.
class GpsLocationResult {
  final bool success;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String? state;
  final String? district;
  final String? errorMessage;
  final bool isLocationServiceDisabled;
  final bool isPermissionDenied;
  final bool isPermissionDeniedForever;

  const GpsLocationResult({
    required this.success,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.state,
    this.district,
    this.errorMessage,
    this.isLocationServiceDisabled = false,
    this.isPermissionDenied = false,
    this.isPermissionDeniedForever = false,
  });

  factory GpsLocationResult.success({
    required double latitude,
    required double longitude,
    double? accuracy,
    required String state,
    required String district,
  }) {
    return GpsLocationResult(
      success: true,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      state: state,
      district: district,
    );
  }

  factory GpsLocationResult.failure({
    required String errorMessage,
    bool isLocationServiceDisabled = false,
    bool isPermissionDenied = false,
    bool isPermissionDeniedForever = false,
  }) {
    return GpsLocationResult(
      success: false,
      errorMessage: errorMessage,
      isLocationServiceDisabled: isLocationServiceDisabled,
      isPermissionDenied: isPermissionDenied,
      isPermissionDeniedForever: isPermissionDeniedForever,
    );
  }
}

/// Robust GPS Location Service for Android (Release/Debug), iOS, and Web.
/// Implements 3-tier fallback architecture:
/// Tier 1: Fused High-Accuracy Position (Fast)
/// Tier 2: Android Native LocationManager (forceLocationManager: true)
/// Tier 3: Last Known Position (Instant Cached OS Location)
class GpsLocationService {
  /// Request GPS position and resolve State & District via backend.
  static Future<GpsLocationResult> detectLocation() async {
    try {
      // 1. Check if device location services are enabled
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return GpsLocationResult.failure(
          errorMessage: 'Location services are turned off. Please enable location to automatically detect your State and District.',
          isLocationServiceDisabled: true,
        );
      }

      // 2. Check runtime permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return GpsLocationResult.failure(
            errorMessage: 'Location permission was denied. You can select your State and District manually.',
            isPermissionDenied: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return GpsLocationResult.failure(
          errorMessage: 'Location permission is permanently denied. Please enable it in Settings or select State and District manually.',
          isPermissionDeniedForever: true,
        );
      }

      // 3. Obtain coordinates using Multi-Tier Fallback Strategy
      Position? position;

      // Tier 1: Try high-accuracy Fused Location Provider (5-second timeout)
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        debugPrint('[GPS Service] Tier 1 (Fused) failed or timed out: $e');
      }

      // Tier 2: If Tier 1 failed, fallback to native LocationManager (forceAndroidLocationManager: true)
      if (position == null && defaultTargetPlatform == TargetPlatform.android) {
        try {
          debugPrint('[GPS Service] Attempting Tier 2: Android Native LocationManager fallback');
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            forceAndroidLocationManager: true,
            timeLimit: const Duration(seconds: 4),
          );
        } catch (e) {
          debugPrint('[GPS Service] Tier 2 (Native LocationManager) failed: $e');
        }
      }

      // Tier 3: Fallback to last known position (cached OS location)
      if (position == null) {
        try {
          debugPrint('[GPS Service] Attempting Tier 3: getLastKnownPosition fallback');
          position = await Geolocator.getLastKnownPosition();
        } catch (e) {
          debugPrint('[GPS Service] Tier 3 (LastKnown) failed: $e');
        }
      }

      if (position == null) {
        return GpsLocationResult.failure(
          errorMessage: 'Unable to acquire location signal. Please ensure location is enabled or select manually.',
        );
      }

      final lat = position.latitude;
      final lon = position.longitude;
      final accuracy = position.accuracy;

      // 4. Resolve State and District using backend location API
      final Map<String, dynamic> result = await ApiService.findNearestDistrict(lat, lon);
      final state = result['state'] as String?;
      final district = result['district'] as String?;

      if (state == null || district == null) {
        return GpsLocationResult.failure(
          errorMessage: 'Could not resolve State and District from coordinates.',
        );
      }

      return GpsLocationResult.success(
        latitude: lat,
        longitude: lon,
        accuracy: accuracy,
        state: state,
        district: district,
      );
    } on PlatformException catch (e) {
      debugPrint('[GPS Service] PlatformException: ${e.message}');
      return GpsLocationResult.failure(
        errorMessage: 'Location service error (${e.message}). You can select State and District manually.',
      );
    } catch (e) {
      debugPrint('[GPS Service] Unexpected error: $e');
      return GpsLocationResult.failure(
        errorMessage: 'Unable to automatically detect your location. You can select State and District manually.',
      );
    }
  }

  /// Open device Location Settings
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open App Settings (for permanently denied permissions)
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
