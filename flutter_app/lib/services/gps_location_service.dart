import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

/// Result object containing location coordinates, resolved State/District, and error states.
class GpsLocationResult {
  final bool success;
  final double? latitude;
  final double? longitude;
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
    required String state,
    required String district,
  }) {
    return GpsLocationResult(
      success: true,
      latitude: latitude,
      longitude: longitude,
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
/// Handles Android 12+ precise/approximate permissions, location service toggles,
/// timeouts, and State/District resolution through the existing backend endpoint.
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

      // 3. Obtain current coordinates (with timeout & fallback to last known position)
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } on TimeoutException {
        debugPrint('[GPS Service] getCurrentPosition timed out, attempting getLastKnownPosition fallback');
        position = await Geolocator.getLastKnownPosition();
      } catch (e) {
        debugPrint('[GPS Service] getCurrentPosition error: $e, attempting getLastKnownPosition');
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return GpsLocationResult.failure(
          errorMessage: 'Unable to acquire GPS signal. Please check your connection or select manually.',
        );
      }

      final lat = position.latitude;
      final lon = position.longitude;

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
