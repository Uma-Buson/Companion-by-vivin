/// The phone-number-first login gate: mirrors the `UserMaster/{phone}`
/// Firestore document. Only ever carries non-secret fields - it tells the
/// app which screen to show next, nothing more. The actual credential
/// check (password verification, or OTP generation/verification) happens
/// either via Firebase Auth directly (password) or companionAPI
/// (OTP - see CompanionApiService), never via this document.
class UserMaster {
  final String phoneNumber;
  final String name;
  final String loginType; // "OTP" or "PASSWORD"

  const UserMaster({
    required this.phoneNumber,
    required this.name,
    required this.loginType,
  });

  bool get isOtpLogin => loginType.toUpperCase() == 'OTP';

  factory UserMaster.fromMap(String phoneNumber, Map<String, dynamic> map) {
    return UserMaster(
      phoneNumber: phoneNumber,
      name: map['name'] as String? ?? '',
      loginType: map['loginType'] as String? ?? 'PASSWORD',
    );
  }
}
