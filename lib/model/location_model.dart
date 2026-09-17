enum LocationStatus {
  initial,
  loading,
  success,
  permissionDenied,
  serviceDisabled,
  error,
}

/// Model encapsulating live geographic coordinates and status.
class LocationModel {
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final DateTime? timestamp;
  final LocationStatus status;
  final String? errorMessage;

  const LocationModel({
    this.latitude,
    this.longitude,
    this.accuracy,
    this.timestamp,
    required this.status,
    this.errorMessage,
  });

  factory LocationModel.initial() {
    return const LocationModel(
      status: LocationStatus.initial,
    );
  }

  factory LocationModel.loading() {
    return const LocationModel(
      status: LocationStatus.loading,
    );
  }

  factory LocationModel.success({
    required double latitude,
    required double longitude,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return LocationModel(
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: timestamp ?? DateTime.now(),
      status: LocationStatus.success,
    );
  }

  factory LocationModel.error(String message, {LocationStatus status = LocationStatus.error}) {
    return LocationModel(
      status: status,
      errorMessage: message,
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;

  String get formattedLatitude =>
      latitude != null ? latitude!.toStringAsFixed(6) : 'N/A';

  String get formattedLongitude =>
      longitude != null ? longitude!.toStringAsFixed(6) : 'N/A';
}
