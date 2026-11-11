/// The web dashboard session returned by `POST /Login/LoginWithFirebase`.
///
/// Mirrors exactly the fields the web app's own login flow writes to
/// localStorage after a normal password login (see companionapp's
/// app/auth/login/page.tsx handleLogin) - the mobile app injects the same
/// keys into the WebView so the web app's existing auth gate (which only
/// checks localStorage, nothing Firebase-aware) treats this as an
/// already-authenticated session.
class CompanionSession {
  final String token;
  final String userName;
  final dynamic userId;
  final dynamic userTypeId;
  final String whsCode;
  final String whsName;
  final String slpCode;
  final dynamic priceView;
  final String types;
  final String sZone;
  final String region;
  final String stateCode;
  final String stateName;

  /// Optional geofence: when latlongActive is true, the dashboard is only
  /// usable while within an allowed zone. A user can be assigned several
  /// stores, so the API returns latitute/longtitude/geoDistance as
  /// comma-separated lists, one entry per store - being inside ANY zone is
  /// enough. Not part of the web dashboard's own localStorage session -
  /// purely a native-side gate (see WebDashboardScreen).
  final bool latlongActive;
  final List<GeoFenceZone> geofences;

  const CompanionSession({
    required this.token,
    required this.userName,
    required this.userId,
    required this.userTypeId,
    required this.whsCode,
    required this.whsName,
    required this.slpCode,
    required this.priceView,
    required this.types,
    required this.sZone,
    required this.region,
    required this.stateCode,
    required this.stateName,
    this.latlongActive = false,
    this.geofences = const [],
  });

  factory CompanionSession.fromJson(Map<String, dynamic> json) {
    return CompanionSession(
      token: json['token'] as String? ?? '',
      userName: json['u_Name'] as String? ?? '',
      userId: json['id'],
      userTypeId: json['userTypeId'],
      whsCode: json['whsCode'] as String? ?? '',
      whsName: json['whsName'] as String? ?? '',
      slpCode: json['slpCode'] as String? ?? '',
      priceView: json['priceView'],
      types: json['types'] as String? ?? '',
      sZone: json['sZone'] as String? ?? '',
      region: json['region'] as String? ?? '',
      stateCode: json['stateCode'] as String? ?? '',
      stateName: json['stateName'] as String? ?? '',
      latlongActive: json['latlongActive'] as bool? ?? false,
      geofences: GeoFenceZone.parseList(
        latitudes: json['latitute']?.toString(),
        longitudes: json['longtitude']?.toString(),
        distances: json['geoDistance']?.toString(),
      ),
    );
  }

  /// The exact key/value pairs the web app writes to localStorage on a
  /// normal login - reused here so injection and that login path can't
  /// drift apart silently.
  Map<String, dynamic> toLocalStorageEntries() => {
        'token': token,
        'userName': userName,
        'whsCode': whsCode,
        'whsName': whsName,
        'userId': userId,
        'userTypeId': userTypeId,
        'slpCode': slpCode,
        'priceView': priceView,
        'types': types,
        'sZone': sZone,
        'region': region,
        'stateCode': stateCode,
        'stateName': stateName,
      };
}

/// One allowed circle: a store's coordinates and its radius in meters.
class GeoFenceZone {
  final double latitude;
  final double longitude;
  final double radiusMeters;

  const GeoFenceZone({
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  /// Mirrors the web app's checkGeoFence parsing so both enforce the same
  /// zones: each field is a comma-separated list, entries are paired up by
  /// position, and any entry with a missing or non-numeric part is dropped.
  static List<GeoFenceZone> parseList({
    String? latitudes,
    String? longitudes,
    String? distances,
  }) {
    List<double?> parse(String? raw) => (raw ?? '')
        .split(',')
        .map((s) => double.tryParse(s.trim()))
        .toList();

    final lats = parse(latitudes);
    final lngs = parse(longitudes);
    final dists = parse(distances);

    final zones = <GeoFenceZone>[];
    for (var i = 0; i < lats.length; i++) {
      final lat = lats[i];
      final lng = i < lngs.length ? lngs[i] : null;
      final max = i < dists.length ? dists[i] : null;
      if (lat == null || lng == null || max == null) continue;
      zones.add(GeoFenceZone(latitude: lat, longitude: lng, radiusMeters: max));
    }
    return zones;
  }
}
