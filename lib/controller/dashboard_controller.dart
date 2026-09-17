import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constant/app_strings.dart';
import '../model/device_info_model.dart';
import '../model/location_model.dart';
import '../model/qr_result_model.dart';
import '../service/device_service.dart';
import '../service/fcm_service.dart';
import '../service/location_service.dart';

/// Controller managing Dashboard state (Device Info, GPS Location, Scanned QR code, and FCM Push Notifications).
class DashboardController extends ChangeNotifier {
  final DeviceService _deviceService;
  final LocationService _locationService;
  final FcmService _fcmService;

  DashboardController({
    DeviceService? deviceService,
    LocationService? locationService,
    FcmService? fcmService,
  })  : _deviceService = deviceService ?? DeviceService(),
        _locationService = locationService ?? LocationService(),
        _fcmService = fcmService ?? FcmService() {
    _initFcmListeners();
  }

  // Device Info State
  DeviceInfoModel _deviceInfo = DeviceInfoModel.empty();
  DeviceInfoModel get deviceInfo => _deviceInfo;
  bool _isLoadingDevice = true;
  bool get isLoadingDevice => _isLoadingDevice;

  // Location State
  LocationModel _location = LocationModel.initial();
  LocationModel get location => _location;
  bool _isLoadingLocation = false;
  bool get isLoadingLocation => _isLoadingLocation;

  // QR Scan Result State
  QrResultModel? _scannedQr;
  QrResultModel? get scannedQr => _scannedQr;

  bool _isCopied = false;
  bool get isCopied => _isCopied;

  // FCM Push Notification State
  String? _fcmToken;
  String? get fcmToken => _fcmToken ?? _fcmService.fcmToken;
  bool get hasFcmToken => (_fcmToken ?? _fcmService.fcmToken) != null;

  String? _latestNotificationTitle;
  String? get latestNotificationTitle => _latestNotificationTitle;

  String? _latestNotificationBody;
  String? get latestNotificationBody => _latestNotificationBody;

  bool _isTokenCopied = false;
  bool get isTokenCopied => _isTokenCopied;

  void _initFcmListeners() {
    _fcmToken = _fcmService.fcmToken;
    _fcmService.tokenNotifier.addListener(() {
      _fcmToken = _fcmService.tokenNotifier.value;
      notifyListeners();
    });

    _fcmService.messageNotifier.addListener(() {
      final msg = _fcmService.messageNotifier.value;
      if (msg != null) {
        _latestNotificationTitle = msg.notification?.title ?? 'Notification';
        _latestNotificationBody = msg.notification?.body ?? 'New message received';
        notifyListeners();
      }
    });
  }

  /// Load initial dashboard data
  Future<void> initDashboard() async {
    await Future.wait([
      fetchDeviceInfo(),
      fetchLocation(),
      _fetchFcmToken(),
    ]);
  }

  Future<void> _fetchFcmToken() async {
    try {
      final token = await _fcmService.fetchFcmToken();
      if (token != null) {
        _fcmToken = token;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching FCM token: $e');
    }
  }

  /// Copy FCM Token to clipboard for testing
  Future<void> copyFcmToken(BuildContext context) async {
    final token = _fcmToken ?? _fcmService.fcmToken;
    if (token == null || token.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: token));
    _isTokenCopied = true;
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FCM Device Token copied to clipboard!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    await Future.delayed(const Duration(seconds: 2));
    _isTokenCopied = false;
    notifyListeners();
  }

  /// Fetch device code (e.g. "TP1A.220624.014") and device name
  Future<void> fetchDeviceInfo() async {
    _isLoadingDevice = true;
    notifyListeners();

    try {
      _deviceInfo = await _deviceService.getDeviceInfo();
    } catch (e) {
      debugPrint('Error in DashboardController.fetchDeviceInfo: $e');
    } finally {
      _isLoadingDevice = false;
      notifyListeners();
    }
  }

  /// Fetch or refresh current latitude and longitude
  Future<void> fetchLocation() async {
    _isLoadingLocation = true;
    _location = LocationModel.loading();
    notifyListeners();

    try {
      _location = await _locationService.getCurrentLocation();
    } catch (e) {
      _location = LocationModel.error('Unable to fetch coordinates: $e');
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// Save scanned QR code result
  void setScannedQr({
    required String rawValue,
    String format = 'QR_CODE',
  }) {
    _scannedQr = QrResultModel(
      rawValue: rawValue,
      format: format,
      scannedAt: DateTime.now(),
    );
    notifyListeners();
  }

  /// Copy scanned QR content to device clipboard
  Future<void> copyScannedContent(BuildContext context) async {
    if (_scannedQr == null || _scannedQr!.rawValue.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _scannedQr!.rawValue));
    _isCopied = true;
    notifyListeners();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.copiedToClipboard),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    await Future.delayed(const Duration(seconds: 2));
    _isCopied = false;
    notifyListeners();
  }

  /// Clear scanned QR code
  void clearScannedQr() {
    _scannedQr = null;
    notifyListeners();
  }
}
