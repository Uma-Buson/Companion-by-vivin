import 'package:flutter/material.dart';
import '../constant/app_strings.dart';
import '../model/tenant_model.dart';
import '../model/user_model.dart';
import '../service/auth_service.dart';
import '../service/tenant_service.dart';
import '../utils/phone_utils.dart';

/// Controller managing login form validation, loading state, and user sessions.
class AuthController extends ChangeNotifier {
  final AuthService _authService;
  final TenantService _tenantService;

  AuthController({AuthService? authService, TenantService? tenantService})
      : _authService = authService ?? AuthService(),
        _tenantService = tenantService ?? TenantService();

  /// Every tenant the signed-in user currently has Active access to.
  /// Empty until [login] succeeds.
  List<TenantMaster> _availableTenants = [];
  List<TenantMaster> get availableTenants => _availableTenants;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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

  /// Perform authentication
  Future<bool> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty) {
      _errorMessage = AppStrings.emptyUsernameError;
      notifyListeners();
      return false;
    }

    if (PhoneUtils.toE164(username) == null) {
      _errorMessage = AppStrings.invalidUsernameError;
      notifyListeners();
      return false;
    }

    if (password.isEmpty) {
      _errorMessage = AppStrings.emptyPasswordError;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(username: username, password: password);

      final tenants = await _tenantService.getActiveTenantsForUser(user.id);
      if (tenants.isEmpty) {
        await _authService.logout();
        _isLoading = false;
        _errorMessage = AppStrings.tenantNotFoundError;
        notifyListeners();
        return false;
      }

      _availableTenants = tenants;
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

  /// Log out
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    passwordController.clear();
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
