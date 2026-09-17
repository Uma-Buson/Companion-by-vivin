import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constant/app_colors.dart';
import '../constant/app_strings.dart';
import '../constant/app_text_styles.dart';
import '../controller/auth_controller.dart';
import '../service/permission_service.dart';
import 'tenant_selector_screen.dart';
import 'web_dashboard_screen.dart';

/// Screen 1: Login Screen with Red & White branding and Admin/1234 verification.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _authController.addListener(_onAuthStateChanged);

    // Prompt for notification & location permissions when the app launches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService().requestStartupPermissions();
    });
  }

  void _onAuthStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthStateChanged);
    _authController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final success = await _authController.login();
    if (!success || !mounted) return;

    final tenants = _authController.availableTenants;
    if (tenants.length == 1) {
      final tenant = tenants.first;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WebDashboardScreen(
            tenantUrl: tenant.tenantUrl,
            tenantName: tenant.tenantName,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TenantSelectorScreen(tenants: tenants),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 24.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Branding Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowColor,
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 76,
                        width: 76,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.group_rounded,
                              size: 64,
                              color: AppColors.primaryRed,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // App Title
                  Text(
                    AppStrings.appName,
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.primaryRed,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.appTagline,
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowColor,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.loginTitle,
                          style: AppTextStyles.heading2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.loginSubtitle,
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 24),

                        // Error Banner
                        if (_authController.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.redSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryRedLight.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.primaryRed,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _authController.errorMessage!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primaryRedDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Username Field
                        Text(
                          AppStrings.usernameLabel,
                          style: AppTextStyles.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _authController.usernameController,
                          onChanged: (_) => _authController.clearError(),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: InputDecoration(
                            hintText: AppStrings.usernameHint,
                            hintStyle: AppTextStyles.bodySmall,
                            prefixIcon: const Icon(
                              Icons.phone_outlined,
                              color: AppColors.textSecondary,
                            ),
                            filled: true,
                            fillColor: AppColors.scaffoldBackground,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.inputBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.primaryRed,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.inputBorder,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Password Field
                        Text(
                          AppStrings.passwordLabel,
                          style: AppTextStyles.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _authController.passwordController,
                          obscureText: _authController.obscurePassword,
                          onChanged: (_) => _authController.clearError(),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            hintText: AppStrings.passwordHint,
                            hintStyle: AppTextStyles.bodySmall,
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.textSecondary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _authController.obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                              ),
                              onPressed:
                                  _authController.togglePasswordVisibility,
                            ),
                            filled: true,
                            fillColor: AppColors.scaffoldBackground,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.inputBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.primaryRed,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppColors.inputBorder,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Button (Themed Red from Image 1)
                        ElevatedButton(
                          onPressed:
                              _authController.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child:
                              _authController.isLoading
                                  ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.textOnPrimary,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    AppStrings.loginButton,
                                    style: AppTextStyles.buttonLabel,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bottom Security Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        size: 16,
                        color: AppColors.primaryRed,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Secured with Screenshot & Recording Restrictions',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
