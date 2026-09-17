import 'package:flutter/foundation.dart';
import 'fcm_service.dart';
import 'location_service.dart';

/// Centralized service to manage and trigger runtime permissions upon app launch.
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final FcmService _fcmService = FcmService();
  final LocationService _locationService = LocationService();

  /// Prompt the user for both Notification and Location permissions sequentially on app launch.
  Future<void> requestStartupPermissions() async {
    debugPrint('[PermissionService] Requesting app launch permissions (Notification & Location)...');

    // 1. Prompt for Push Notification Permission (Android 13+ & iOS)
    try {
      final notifSettings = await _fcmService.requestPermission();
      debugPrint('[PermissionService] Notification permission status: ${notifSettings?.authorizationStatus}');
    } catch (e) {
      debugPrint('[PermissionService] Notification permission prompt error: $e');
    }

    // 2. Prompt for GPS Location Permission (Android & iOS)
    try {
      final locPermission = await _locationService.requestLocationPermission();
      debugPrint('[PermissionService] Location permission status: $locPermission');
    } catch (e) {
      debugPrint('[PermissionService] Location permission prompt error: $e');
    }
  }
}
