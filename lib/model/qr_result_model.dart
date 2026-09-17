/// Model encapsulating scanned QR code data.
class QrResultModel {
  final String rawValue;
  final String format;
  final DateTime scannedAt;

  const QrResultModel({
    required this.rawValue,
    required this.format,
    required this.scannedAt,
  });

  Map<String, dynamic> toJson() => {
        'rawValue': rawValue,
        'format': format,
        'scannedAt': scannedAt.toIso8601String(),
      };
}
