/// User model representing the authenticated Firebase session.
class UserModel {
  /// Firebase Authentication UID — the permanent technical identifier.
  final String id;

  /// User-visible mobile number in E.164 format (e.g. +919840012345).
  final String username;
  final String displayName;

  /// Firebase ID token for the current session. Short-lived; refresh
  /// via FirebaseAuth rather than persisting this value long-term.
  final String token;
  final DateTime loginTime;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.token,
    required this.loginTime,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      token: json['token'] as String? ?? '',
      loginTime: json['loginTime'] != null
          ? DateTime.parse(json['loginTime'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'displayName': displayName,
        'token': token,
        'loginTime': loginTime.toIso8601String(),
      };
}
