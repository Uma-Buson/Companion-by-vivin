/// Model holding hardware and operating system identifiers.
class DeviceInfoModel {
  /// Code identifier, e.g. "TP1A.220624.014" on Android, or iOS build/identifier
  final String deviceCode;

  /// Human readable device name / model, e.g. "Google Pixel 7" or "iPhone 15"
  final String deviceName;

  /// Device brand or manufacturer (e.g. "Google", "Samsung", "Apple")
  final String manufacturer;

  /// Operating system release/version
  final String osVersion;

  /// Whether running on physical hardware or emulator/simulator
  final bool isPhysicalDevice;

  const DeviceInfoModel({
    required this.deviceCode,
    required this.deviceName,
    required this.manufacturer,
    required this.osVersion,
    required this.isPhysicalDevice,
  });

  factory DeviceInfoModel.empty() {
    return const DeviceInfoModel(
      deviceCode: 'Loading...',
      deviceName: 'Detecting Device...',
      manufacturer: 'Detecting...',
      osVersion: 'Detecting...',
      isPhysicalDevice: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'deviceCode': deviceCode,
        'deviceName': deviceName,
        'manufacturer': manufacturer,
        'osVersion': osVersion,
        'isPhysicalDevice': isPhysicalDevice,
      };
}
