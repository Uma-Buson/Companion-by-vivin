import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../model/device_info_model.dart';

/// Service for inspecting hardware, device build code, and system metadata.
class DeviceService {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();

  Future<DeviceInfoModel> getDeviceInfo() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfoPlugin.webBrowserInfo;
        return DeviceInfoModel(
          deviceCode: webInfo.userAgent ?? 'WEB_BROWSER',
          deviceName: webInfo.browserName.name.toUpperCase(),
          manufacturer: webInfo.vendor ?? 'Web Client',
          osVersion: webInfo.platform ?? 'Web',
          isPhysicalDevice: true,
        );
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        // Build display / ID is typically formatted like "TP1A.220624.014"
        final code = androidInfo.display.isNotEmpty
            ? androidInfo.display
            : (androidInfo.id.isNotEmpty ? androidInfo.id : 'BUILD_UNKNOWN');

        final name = '${androidInfo.brand.toUpperCase()} ${androidInfo.model}';

        return DeviceInfoModel(
          deviceCode: code,
          deviceName: name,
          manufacturer: androidInfo.manufacturer.toUpperCase(),
          osVersion: 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})',
          isPhysicalDevice: androidInfo.isPhysicalDevice,
        );
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        final code = iosInfo.utsname.machine.isNotEmpty
            ? iosInfo.utsname.machine
            : (iosInfo.identifierForVendor ?? 'IOS_DEVICE');

        return DeviceInfoModel(
          deviceCode: code,
          deviceName: iosInfo.name.isNotEmpty ? iosInfo.name : iosInfo.model,
          manufacturer: 'APPLE',
          osVersion: '${iosInfo.systemName} ${iosInfo.systemVersion}',
          isPhysicalDevice: iosInfo.isPhysicalDevice,
        );
      } else if (Platform.isWindows) {
        final winInfo = await _deviceInfoPlugin.windowsInfo;
        return DeviceInfoModel(
          deviceCode: winInfo.deviceId.isNotEmpty ? winInfo.deviceId : 'WIN_DEV_01',
          deviceName: winInfo.computerName,
          manufacturer: 'MICROSOFT',
          osVersion: 'Windows (Build ${winInfo.buildNumber})',
          isPhysicalDevice: true,
        );
      } else {
        return const DeviceInfoModel(
          deviceCode: 'GENERIC_BUILD_ID',
          deviceName: 'Standard Device',
          manufacturer: 'Generic',
          osVersion: 'Universal',
          isPhysicalDevice: true,
        );
      }
    } catch (e) {
      debugPrint('Error retrieving device info: $e');
      return DeviceInfoModel(
        deviceCode: 'TP1A.220624.014', // Fallback standard build code
        deviceName: 'Android / iOS Device',
        manufacturer: 'System Hardware',
        osVersion: 'Mobile OS',
        isPhysicalDevice: true,
      );
    }
  }
}
