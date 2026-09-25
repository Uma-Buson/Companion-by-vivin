import 'package:firebase_auth/firebase_auth.dart';

import '../constant/app_strings.dart';
import '../model/user_model.dart';
import '../utils/phone_utils.dart';

/// Authentication service backed by Firebase Authentication.
///
/// Implements the mobile-number + password login model from Section 4.1
/// of the Companion App Flutter + Firebase implementation guide: the
/// user-visible username is the mobile number, but Firebase Auth (which
/// has no native username/password provider) is driven through a hidden,
/// deterministic email alias derived from the normalized E.164 number
/// (`<digits>@auth.companyapp.internal`). The user never sees or enters
/// this alias — only their mobile number and password.
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Resolved lazily (rather than at construction) so this singleton can be
  // safely instantiated before Firebase.initializeApp() has run — e.g. in
  // widget tests that build screens without a Firebase test double.
  FirebaseAuth get _firebaseAuth => FirebaseAuth.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Rehydrates [currentUser] from any Firebase session already active on
  /// this device (e.g. app restart). Call once at startup before relying
  /// on [isAuthenticated].
  Future<UserModel?> tryRestoreSession() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      await firebaseUser.reload();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-disabled' || e.code == 'user-not-found') {
        await _firebaseAuth.signOut();
        return null;
      }
    }

    final refreshedUser = _firebaseAuth.currentUser;
    if (refreshedUser == null) return null;

    _currentUser = await _buildUserModel(refreshedUser);
    return _currentUser;
  }

  /// Authenticate with mobile number + password via Firebase Authentication.
  ///
  /// [username] is the mobile number as typed by the user in any common
  /// format; it is normalized to E.164 before being mapped to the hidden
  /// auth alias.
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final trimmedPass = password.trim();

    if (username.trim().isEmpty) {
      throw Exception(AppStrings.emptyUsernameError);
    }
    if (trimmedPass.isEmpty) {
      throw Exception(AppStrings.emptyPasswordError);
    }

    final e164Mobile = PhoneUtils.toE164(username);
    if (e164Mobile == null) {
      throw Exception(AppStrings.invalidUsernameError);
    }

    final authAlias = PhoneUtils.toAuthAlias(e164Mobile);

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: authAlias,
        password: trimmedPass,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception(AppStrings.invalidCredentialsError);
      }

      _currentUser = await _buildUserModel(firebaseUser);
      return _currentUser!;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  /// Completes the OTP login path: signs in with a custom token minted
  /// server-side by companionAPI after it verified the OTP, rather than a
  /// password - the account's real password is never involved here.
  Future<UserModel> loginWithCustomToken(String customToken) async {
    try {
      final credential = await _firebaseAuth.signInWithCustomToken(customToken);

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception(AppStrings.invalidCredentialsError);
      }

      _currentUser = await _buildUserModel(firebaseUser);
      return _currentUser!;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseError(e));
    }
  }

  /// Terminate the active session
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
  }

  Future<UserModel> _buildUserModel(User firebaseUser) async {
    final idToken = await firebaseUser.getIdToken() ?? '';
    final mobile = _mobileFromEmailAlias(firebaseUser.email);

    return UserModel(
      id: firebaseUser.uid,
      username: mobile,
      displayName:
          (firebaseUser.displayName != null &&
                  firebaseUser.displayName!.trim().isNotEmpty)
              ? firebaseUser.displayName!
              : mobile,
      token: idToken,
      loginTime: DateTime.now(),
    );
  }

  /// Recovers the display-safe mobile number (E.164) from the hidden
  /// auth alias email, so the UI never shows the internal alias.
  String _mobileFromEmailAlias(String? aliasEmail) {
    if (aliasEmail == null || !aliasEmail.contains('@')) return '';
    final digits = aliasEmail.split('@').first;
    return '+$digits';
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return AppStrings.invalidCredentialsError;
      case 'user-disabled':
        return AppStrings.userDisabledError;
      case 'too-many-requests':
        return AppStrings.tooManyRequestsError;
      case 'network-request-failed':
        return AppStrings.networkError;
      default:
        return e.message ?? AppStrings.invalidCredentialsError;
    }
  }
}
