import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../constant/app_colors.dart';
import '../constant/app_strings.dart';
import '../constant/app_text_styles.dart';
import '../controller/auth_controller.dart';
import 'web_dashboard_screen.dart';

/// Screen 2b: OTP entry, shown when UserMaster says this phone number logs
/// in with an OTP instead of a password. Same branding/typography as the
/// rest of the login flow.
class OtpScreen extends StatefulWidget {
  final AuthController authController;

  const OtpScreen({super.key, required this.authController});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _resendCooldown = 60;

  Timer? _timer;
  int _secondsRemaining = _resendCooldown;

  @override
  void initState() {
    super.initState();
    widget.authController.addListener(_onAuthStateChanged);
    _startCountdown();
  }

  void _onAuthStateChanged() {
    if (mounted) setState(() {});
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsRemaining = _resendCooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  Future<void> _handleResend() async {
    FocusScope.of(context).unfocus();
    widget.authController.otpController.clear();
    final success = await widget.authController.requestOtp();
    if (!mounted) return;
    if (success) {
      Fluttertoast.showToast(
        msg: AppStrings.otpResendSentToast,
        backgroundColor: AppColors.success,
        textColor: AppColors.textOnPrimary,
        toastLength: Toast.LENGTH_SHORT,
      );
      _startCountdown();
    }
  }

  Future<void> _handleVerify() async {
    FocusScope.of(context).unfocus();
    final success = await widget.authController.verifyOtp();
    if (!success || !mounted) return;

    Fluttertoast.showToast(
      msg: 'Login successful!',
      backgroundColor: AppColors.success,
      textColor: AppColors.textOnPrimary,
      toastLength: Toast.LENGTH_SHORT,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => WebDashboardScreen(
          tenants: widget.authController.availableTenants,
          session: widget.authController.companionSession!,
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.authController.removeListener(_onAuthStateChanged);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.authController;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                      child: const Icon(
                        Icons.sms_outlined,
                        size: 48,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

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
                        Text(AppStrings.otpTitle, style: AppTextStyles.heading2),
                        const SizedBox(height: 4),
                        Text(
                          '${AppStrings.otpSubtitle} ${controller.pendingPhone ?? ''}',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 24),

                        if (controller.errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.redSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryRedLight.withValues(alpha: 0.5),
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
                                    controller.errorMessage!,
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

                        TextField(
                          controller: controller.otpController,
                          onChanged: (_) => controller.clearError(),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleVerify(),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          style: AppTextStyles.heading2.copyWith(letterSpacing: 8),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: '000000',
                            hintStyle: AppTextStyles.heading2.copyWith(
                              letterSpacing: 8,
                              color: AppColors.textSecondary.withValues(alpha: 0.4),
                            ),
                            filled: true,
                            fillColor: AppColors.scaffoldBackground,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.inputBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primaryRed, width: 2),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.inputBorder),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: controller.isLoading ? null : _handleVerify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: controller.isLoading
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
                              : const Text(AppStrings.otpButton, style: AppTextStyles.buttonLabel),
                        ),
                        const SizedBox(height: 16),

                        Center(
                          child: _secondsRemaining > 0
                              ? Text(
                                  '${AppStrings.otpResendPrompt} 00:${_secondsRemaining.toString().padLeft(2, '0')}',
                                  style: AppTextStyles.bodySmall,
                                )
                              : TextButton(
                                  onPressed: controller.isLoading ? null : _handleResend,
                                  child: Text(
                                    AppStrings.otpResendButton,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primaryRed,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 4),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              controller.backToPhoneStep();
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              AppStrings.changeNumberButton,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
