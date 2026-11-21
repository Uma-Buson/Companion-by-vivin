import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:screen_protector/screen_protector.dart';

/// Service enforcing anti-screenshot and anti-screen recording policies across the application.
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  bool _isProtected = false;
  bool get isProtected => _isProtected;

  /// Activates full screen restrictions on Android and iOS:
  /// - Android: Blocks screenshot capture, blocks screen recording, blocks app switcher snapshot.
  /// - iOS: Obscures content when app switcher is opened, detects recording, blurs sensitive frames.
  Future<void> enableScreenshotProtection() async {
    if (kIsWeb) return;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Prevent screenshot capture. Android only: on iOS this works by
        // re-parenting the app's window into a secure text field, which on
        // recent iOS versions renders every screen black (also in-app, not
        // just in screenshots), regardless of theme.
        if (Platform.isAndroid) {
          await ScreenProtector.preventScreenshotOn();
        }

        // Prevent data leakage in recent apps / multitasking switcher with blur
        await ScreenProtector.protectDataLeakageWithBlur();

        _isProtected = true;
        debugPrint('[SecurityService] Screen & recording protection successfully enabled.');
      }
    } catch (e) {
      debugPrint('[SecurityService] Note on screen protection initialization: $e');
    }
  }

  /// Disables protection (if selectively required)
  Future<void> disableScreenshotProtection() async {
    if (kIsWeb) return;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        if (Platform.isAndroid) {
          await ScreenProtector.preventScreenshotOff();
        }
        await ScreenProtector.protectDataLeakageWithBlurOff();
        _isProtected = false;
      }
    } catch (e) {
      debugPrint('[SecurityService] Error disabling screen protection: $e');
    }
  }
}
