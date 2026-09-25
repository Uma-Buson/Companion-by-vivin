import 'package:flutter/material.dart';
import '../constant/app_strings.dart';
import '../model/companion_session_model.dart';
import '../model/tenant_model.dart';
import '../model/user_model.dart';
import '../service/auth_service.dart';
import '../service/companion_api_service.dart';
import '../service/tenant_service.dart';
import '../service/user_master_service.dart';
import '../utils/phone_utils.dart';

enum LoginStep { phone, password, otp }

/// Controller managing the phone-number-first login flow: a phone number
/// is looked up in UserMaster to decide whether this user logs in with a
/// password or an OTP, then either path converges on the same
/// tenant-fetch + companion-session completion.
class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final TenantService _tenantService;
  final CompanionApiService _companionApiService;
  final UserMasterService _userMasterService;

  AuthController({
    AuthService? authService,
    TenantService? tenantService,
    CompanionApiService? companionApiService,
    UserMasterService? userMasterService,
  })  : _authService = authService ?? AuthService(),
        _tenantService = tenantService ?? TenantService(),
        _companionApiService = companionApiService ?? CompanionApiService(),
        _userMasterService = userMasterService ?? UserMasterService();

  /// Every tenant the signed-in user currently has Active access to.
  /// Empty until login succeeds.
  List<TenantMaster> _availableTenants = [];
  List<TenantMaster> get availableTenants => _availableTenants;

  /// The web dashboard session obtained via LoginWithFirebase, injected
  /// into each tenant's WebView so it skips its own login page. Empty
  /// until login succeeds.
  CompanionSession? _companionSession;
  CompanionSession? get companionSession => _companionSession;

  LoginStep _step = LoginStep.phone;
  LoginStep get step => _step;

  /// The phone number confirmed in step 1 - carried into the password/OTP
  /// step since UserMaster's answer decided which one to show.
  String? _pendingPhone;
  String? get pendingPhone => _pendingPhone;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  UserModel? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Step 1: look up the phone number and decide which screen comes next.
  Future<bool> checkPhoneNumber() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      _errorMessage = AppStrings.emptyUsernameError;
      notifyListeners();
      return false;
    }
    if (PhoneUtils.toE164(phone) == null) {
      _errorMessage = AppStrings.invalidUsernameError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userMaster = await _userMasterService.lookup(phone);
      if (userMaster == null) {
        _isLoading = false;
        _errorMessage = AppStrings.invalidCredentialsError;
        notifyListeners();
        return false;
      }

      _pendingPhone = phone;
      _isLoading = false;

      if (userMaster.isOtpLogin) {
        _step = LoginStep.otp;
        notifyListeners();
        return await requestOtp();
      }

      _step = LoginStep.password;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void backToPhoneStep() {
    _step = LoginStep.phone;
    _pendingPhone = null;
    passwordController.clear();
    otpController.clear();
    _errorMessage = null;
    notifyListeners();
  }

  /// Step 2a (password path): the existing mobile-number + password
  /// Firebase Auth sign-in, unchanged.
  Future<bool> loginWithPassword() async {
    final password = passwordController.text.trim();
    if (password.isEmpty) {
      _errorMessage = AppStrings.emptyPasswordError;
      notifyListeners();
      return false;
    }
    if (_pendingPhone == null) {
      _errorMessage = AppStrings.invalidUsernameError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(
        username: _pendingPhone!,
        password: password,
      );
      return await _completeLoginAfterFirebaseAuth(user);
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Step 2b (OTP path): (re)send a fresh code for the pending phone number.
  Future<bool> requestOtp() async {
    if (_pendingPhone == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _companionApiService.requestOtp(_pendingPhone!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Step 2b completion: verify the OTP server-side, sign in with the
  /// resulting custom token, then converge on the same completion as
  /// the password path.
  Future<bool> verifyOtp() async {
    final code = otpController.text.trim();
    if (code.isEmpty) {
      _errorMessage = AppStrings.otpEmptyError;
      notifyListeners();
      return false;
    }
    if (_pendingPhone == null) {
      _errorMessage = AppStrings.invalidUsernameError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final customToken = await _companionApiService.verifyOtpAndLogin(_pendingPhone!, code);
      final user = await _authService.loginWithCustomToken(customToken);
      return await _completeLoginAfterFirebaseAuth(user);
    } catch (e) {
      _isLoading = false;
      _errorMessage = AppStrings.otpInvalidError;
      notifyListeners();
      return false;
    }
  }

  /// Shared tail for both login paths: fetch the user's tenants and start
  /// their web dashboard session. Logs the Firebase session back out if
  /// either step fails, so a half-finished login never lingers.
  Future<bool> _completeLoginAfterFirebaseAuth(UserModel user) async {
    final tenants = await _tenantService.getActiveTenantsForUser(user.id);
    if (tenants.isEmpty) {
      await _authService.logout();
      _isLoading = false;
      _errorMessage = AppStrings.tenantNotFoundError;
      notifyListeners();
      return false;
    }

    try {
      _companionSession = await _companionApiService.loginWithFirebase(user.token);
    } catch (e) {
      await _authService.logout();
      _isLoading = false;
      _errorMessage = AppStrings.companionSessionError;
      notifyListeners();
      return false;
    }

    // Note: the location boundary (latlongActive/geoDistanceMeters on
    // CompanionSession) is enforced continuously on the dashboard itself
    // (WebDashboardScreen), not here - being outside it blurs the screen
    // rather than blocking login, so a user already out of range still
    // needs to reach the dashboard to see that state.
    _availableTenants = tenants;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Log out
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    passwordController.clear();
    otpController.clear();
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    otpController.dispose();
    super.dispose();
  }
}
