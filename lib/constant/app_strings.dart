/// Centralized UI strings for Companion By Vivin.
class AppStrings {
  AppStrings._();

  // App Identity
  static const String appName = 'Companion By Vivin';
  static const String appTagline = 'Smart Device & Companion Assistant';
  static const String appPackage = 'com.companion.vivin';

  // Authentication
  static const String loginTitle = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to access your companion dashboard';
  static const String usernameLabel = 'Mobile Number';
  static const String usernameHint = 'Enter mobile number (e.g. 9840012345)';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'Enter password';
  static const String loginButton = 'Sign In';
  static const String nextButton = 'Next';
  static const String loggingIn = 'Signing in...';
  static const String invalidCredentialsError =
      'Invalid mobile number or password.';
  static const String emptyUsernameError = 'Mobile number cannot be empty';
  static const String invalidUsernameError = 'Enter a valid mobile number';
  static const String emptyPasswordError = 'Password cannot be empty';
  static const String userDisabledError =
      'This account has been disabled. Contact your administrator.';
  static const String tooManyRequestsError =
      'Too many attempts. Please try again later.';
  static const String networkError =
      'Network error. Check your connection and try again.';
  static const String tenantInactiveError =
      'Your company access has been deactivated. Contact your administrator.';
  static const String tenantNotFoundError =
      'Company is not configured. Contact your administrator.';
  static const String companionSessionError =
      'Could not start your dashboard session. Please try again.';

  // OTP step
  static const String otpTitle = 'Verify OTP';
  static const String otpSubtitle = 'Enter the 6-digit code sent to';
  static const String otpButton = 'Verify';
  static const String otpVerifying = 'Verifying...';
  static const String otpResendPrompt = "Didn't receive the code?";
  static const String otpResendButton = 'Resend OTP';
  static const String otpResendSentToast = 'OTP resent';
  static const String otpEmptyError = 'Enter the OTP sent to your mobile number';
  static const String otpInvalidError = 'Invalid or expired OTP. Please try again.';
  static const String changeNumberButton = 'Change Number';

  // Geofence
  static const String outOfBoundaryTitle = 'Out of Boundary Location';
  static const String outOfBoundaryMessage =
      'You are outside the allowed location for this account. Please move within range and try again.';
  static const String outOfBoundaryLogoutButton = 'Logout';

  static const String logoutConfirmTitle = 'Sign Out';
  static const String logoutConfirmMessage =
      'Are you sure you want to log out of Companion By Vivin?';
  static const String logoutButton = 'Sign Out';
  static const String cancelButton = 'Cancel';

  // Dashboard
  static const String dashboardTitle = 'Companion Dashboard';
  static const String deviceInfoSection = 'Device Information';
  static const String deviceCodeLabel = 'Device Build / Code';
  static const String deviceNameLabel = 'Device Model & Name';
  static const String manufacturerLabel = 'Manufacturer';
  static const String osVersionLabel = 'Operating System';

  static const String locationSection = 'Live GPS Coordinates';
  static const String latitudeLabel = 'Latitude';
  static const String longitudeLabel = 'Longitude';
  static const String locationAccuracyLabel = 'Accuracy';
  static const String locationRefresh = 'Refresh Coordinates';
  static const String locationPermissionDenied =
      'Location permission was denied. Tap refresh to request.';
  static const String locationServiceDisabled =
      'Location service is disabled on this device.';

  static const String qrSection = 'QR Scanner';
  static const String qrPrompt = 'Scan any QR code or barcode';
  static const String scanQrButton = 'Open QR Scanner';
  static const String scannedDataLabel = 'Last Scanned QR Content';
  static const String noQrScannedYet = 'No QR code scanned yet';
  static const String copyToClipboard = 'Copy to Clipboard';
  static const String copiedToClipboard = 'Copied to clipboard!';
  static const String scanAgainButton = 'Scan Another Code';

  // Scanner Screen
  static const String scannerTitle = 'Scan QR Code';
  static const String scannerHint = 'Point your camera at a QR code to scan';
  static const String torchOn = 'Torch On';
  static const String torchOff = 'Torch Off';
  static const String cameraSwitch = 'Switch Camera';
  static const String permissionCameraDenied =
      'Camera permission is required to scan QR codes.';
  static const String grantPermission = 'Grant Permission';

  // Security
  static const String securityNotice =
      'Protected View: Screenshots and screen recording are restricted for data safety.';
}
