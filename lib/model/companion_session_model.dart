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

  /// Optional geofence: when latlongActive is true, login is only allowed
  /// within geoDistance meters of (latitude, longitude). Not part of the
  /// web dashboard's own localStorage session - purely a native-side gate
  /// checked once at login (see AuthController).
  final bool latlongActive;
  final double? latitude;
  final double? longitude;
  final double? geoDistanceMeters;

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
    this.latitude,
    this.longitude,
    this.geoDistanceMeters,
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
      latitude: double.tryParse(json['latitute']?.toString() ?? ''),
      longitude: double.tryParse(json['longtitude']?.toString() ?? ''),
      geoDistanceMeters: double.tryParse(json['geoDistance']?.toString() ?? ''),
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
