import 'package:flutter/material.dart';
import '../constant/app_colors.dart';
import '../constant/app_strings.dart';
import '../constant/app_text_styles.dart';
import '../controller/dashboard_controller.dart';
import '../model/location_model.dart';
import 'login_screen.dart';
import 'qr_scanner_screen.dart';

/// Screen 2: Dashboard displaying Device Code/Name, GPS Coordinates, and QR Scanner.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _controller.addListener(_onStateChanged);
    _controller.initDashboard();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openQrScanner() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );

    if (result != null && result['rawValue'] != null) {
      _controller.setScannedQr(
        rawValue: result['rawValue'] as String,
        format: result['format'] as String? ?? 'QR_CODE',
      );
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(AppStrings.logoutConfirmTitle),
        content: const Text(AppStrings.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              AppStrings.cancelButton,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text(AppStrings.logoutButton),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: AppColors.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 34,
              width: 34,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.group_rounded, color: AppColors.primaryRed),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                AppStrings.appName,
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Security Indicator Icon
          Tooltip(
            message: 'Screenshot & Screen Recording Protection Active',
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.redSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryRedLight.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.shield_rounded,
                    size: 14,
                    color: AppColors.primaryRed,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'SECURED',
                    style: TextStyle(
                      color: AppColors.primaryRedDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Sign Out',
            onPressed: _confirmLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryRed,
        backgroundColor: Colors.white,
        onRefresh: () => _controller.initDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Device Info Card (Showing Device Code & Device Name)
              _buildDeviceInfoCard(),
              const SizedBox(height: 20),

              // 2. GPS Location Card (Showing Latitude & Longitude)
              _buildLocationCard(),
              const SizedBox(height: 20),

              // 3. QR Scanner & Scanned Result Card
              _buildQrScannerCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 1. Card for Device Code (e.g. TP1A.220624.014) and Device Name
  Widget _buildDeviceInfoCard() {
    final dev = _controller.deviceInfo;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.redSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  color: AppColors.primaryRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      AppStrings.deviceInfoSection,
                      style: AppTextStyles.sectionTitle,
                    ),
                    Text(
                      'Hardware & build identifiers',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              if (_controller.isLoadingDevice)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Refresh Device Info',
                  onPressed: _controller.fetchDeviceInfo,
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 18),

          // Current Device Code (Required: like "TP1A.220624.014")
          Text(
            AppStrings.deviceCodeLabel,
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.redSurface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryRedLight.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.qr_code_2_rounded,
                  size: 20,
                  color: AppColors.primaryRed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    dev.deviceCode,
                    style: AppTextStyles.codeBadge.copyWith(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Current Device Name
          Text(
            AppStrings.deviceNameLabel,
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.devices_other_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dev.deviceName,
                  style: AppTextStyles.valueBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // OS and Manufacturer sub-details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.manufacturerLabel,
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dev.manufacturer,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.osVersionLabel,
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dev.osVersion,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 2. Card for GPS Coordinates (Latitude & Longitude)
  Widget _buildLocationCard() {
    final loc = _controller.location;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.redSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primaryRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      AppStrings.locationSection,
                      style: AppTextStyles.sectionTitle,
                    ),
                    Text(
                      'Real-time geolocation status',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              if (_controller.isLoadingLocation)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(
                    Icons.my_location_rounded,
                    size: 20,
                    color: AppColors.primaryRed,
                  ),
                  tooltip: AppStrings.locationRefresh,
                  onPressed: _controller.fetchLocation,
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 18),

          // Coordinates Layout
          if (loc.status == LocationStatus.loading) ...[
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Acquiring high-accuracy GPS coordinates...',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ] else if (loc.hasCoordinates) ...[
            Row(
              children: [
                // Latitude Tile
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.explore_outlined,
                              size: 14,
                              color: AppColors.primaryRed,
                            ),
                            SizedBox(width: 4),
                            Text(
                              AppStrings.latitudeLabel,
                              style: AppTextStyles.labelMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          loc.formattedLatitude,
                          style: AppTextStyles.valueBold.copyWith(
                            fontSize: 16,
                            color: AppColors.primaryRedDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Longitude Tile
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.scaffoldBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.explore_outlined,
                              size: 14,
                              color: AppColors.primaryRed,
                            ),
                            SizedBox(width: 4),
                            Text(
                              AppStrings.longitudeLabel,
                              style: AppTextStyles.labelMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          loc.formattedLongitude,
                          style: AppTextStyles.valueBold.copyWith(
                            fontSize: 16,
                            color: AppColors.primaryRedDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Accuracy and timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (loc.accuracy != null)
                  Text(
                    'Accuracy: ±${loc.accuracy!.toStringAsFixed(1)} m',
                    style: AppTextStyles.bodySmall,
                  ),
                if (loc.timestamp != null)
                  Text(
                    'Updated: ${loc.timestamp!.hour.toString().padLeft(2, '0')}:${loc.timestamp!.minute.toString().padLeft(2, '0')}:${loc.timestamp!.second.toString().padLeft(2, '0')}',
                    style: AppTextStyles.bodySmall,
                  ),
              ],
            ),
          ] else ...[
            // Error or permission prompt
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.redSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryRedLight.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.primaryRed,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          loc.errorMessage ?? 'Coordinates unavailable',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primaryRedDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _controller.fetchLocation,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: AppColors.primaryRed,
                      ),
                      label: const Text(
                        AppStrings.locationRefresh,
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 3. Card for Firebase Cloud Messaging (FCM) Status & Token
  Widget _buildFcmCard() {
    final token = _controller.fcmToken;
    final hasToken = _controller.hasFcmToken;
    final notifTitle = _controller.latestNotificationTitle;
    final notifBody = _controller.latestNotificationBody;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.redSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: AppColors.primaryRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Push Notifications (FCM)',
                      style: AppTextStyles.sectionTitle,
                    ),
                    Text(
                      'Firebase Cloud Messaging Status',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasToken
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasToken ? 'ONLINE' : 'CONNECTING',
                  style: TextStyle(
                    color: hasToken ? AppColors.success : AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 18),

          // FCM Token Container
          const Text(
            'FCM Device Registration Token',
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  token ?? 'Awaiting device token from Firebase...',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: token != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  maxLines: 3,
                ),
                if (token != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _controller.copyFcmToken(context),
                      icon: Icon(
                        _controller.isTokenCopied
                            ? Icons.check_rounded
                            : Icons.copy_rounded,
                        size: 14,
                        color: AppColors.primaryRed,
                      ),
                      label: Text(
                        _controller.isTokenCopied ? 'Copied' : 'Copy Token',
                        style: const TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // If a push notification was received
          if (notifTitle != null || notifBody != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Latest Push Notification Received',
              style: AppTextStyles.labelMedium,
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.redSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primaryRedLight.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.mark_email_unread_rounded,
                        color: AppColors.primaryRed,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          notifTitle ?? 'Notification',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primaryRedDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (notifBody != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      notifBody,
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 4. Card for QR Scanner and Displaying Scanned Text
  Widget _buildQrScannerCard() {
    final scanned = _controller.scannedQr;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.redSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: AppColors.primaryRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.qrSection,
                      style: AppTextStyles.sectionTitle,
                    ),
                    Text(
                      AppStrings.qrPrompt,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 18),

          // Scanned QR result container
          if (scanned != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryRed.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            AppStrings.scannedDataLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.redSurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          scanned.format,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Display the scanned QR text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: SelectableText(
                      scanned.rawValue,
                      style: AppTextStyles.valueBold.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Actions row: Copy & Scan again
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _controller.copyScannedContent(context),
                          icon: Icon(
                            _controller.isCopied
                                ? Icons.check_rounded
                                : Icons.copy_rounded,
                            size: 16,
                            color: AppColors.primaryRed,
                          ),
                          label: Text(
                            _controller.isCopied
                                ? 'Copied'
                                : AppStrings.copyToClipboard,
                            style: const TextStyle(
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryRedLight),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        tooltip: 'Clear Scanned Data',
                        onPressed: _controller.clearScannedQr,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Prompt view when no QR has been scanned yet
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cardBorder,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 48,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.noQrScannedYet,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap the red button below to activate your camera and scan any QR code.',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Primary Red Scan Button (Image 1 Theme)
          ElevatedButton.icon(
            onPressed: _openQrScanner,
            icon: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 20,
            ),
            label: Text(
              scanned != null ? AppStrings.scanAgainButton : AppStrings.scanQrButton,
              style: AppTextStyles.buttonLabel,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
