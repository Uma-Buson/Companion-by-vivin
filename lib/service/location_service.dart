import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../constant/app_strings.dart';
import '../model/location_model.dart';

/// Service responsible for permission handling and fetching GPS coordinates.
class LocationService {
  Future<LocationModel> getCurrentLocation() async {
    try {
      // 1. Verify device location service (GPS) is switched on
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Prompt the user to enable GPS via system settings
        await Geolocator.openLocationSettings();
        // Wait briefly for the user to toggle GPS on
        await Future.delayed(const Duration(seconds: 2));
        // Re-check after the user returns from settings
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return LocationModel.error(
            'Location services are still off. Please enable GPS and try again.',
            status: LocationStatus.serviceDisabled,
          );
        }
      }

      // 2. Check and request location permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationModel.error(
            AppStrings.locationPermissionDenied,
            status: LocationStatus.permissionDenied,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationModel.error(
          'Location permissions are permanently denied. Please enable them in App Settings.',
          status: LocationStatus.permissionDenied,
        );
      }

      // 3. Obtain current geographic coordinates
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      return LocationModel.success(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      debugPrint('Location fetching error: $e');
      return LocationModel.error('Failed to get coordinates: $e');
    }
  }

  /// Explicitly request location permission on app launch or user prompt
  Future<LocationPermission> requestLocationPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission;
    } catch (e) {
      debugPrint('[LocationService] Permission request error: $e');
      return LocationPermission.denied;
    }
  }

  /// Open device app settings if permissions were permanently denied
  Future<bool> openSettings() async {
    return await Geolocator.openAppSettings();
  }
}

