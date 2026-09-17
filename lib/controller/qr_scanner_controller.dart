import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Controller encapsulating the mobile scanner hardware states and detection events.
class QrScannerController extends ChangeNotifier {
  late final MobileScannerController scannerController;

  bool _isTorchOn = false;
  bool get isTorchOn => _isTorchOn;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  QrScannerController() {
    scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  /// Toggle torch/flashlight
  Future<void> toggleTorch() async {
    try {
      await scannerController.toggleTorch();
      _isTorchOn = !_isTorchOn;
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling torch: $e');
    }
  }

  /// Switch between front and back camera
  Future<void> switchCamera() async {
    try {
      await scannerController.switchCamera();
      notifyListeners();
    } catch (e) {
      debugPrint('Error switching camera: $e');
    }
  }

  /// Handle detected barcode safely
  bool processBarcode(BarcodeCapture capture, Function(String value, String format) onScanSuccess) {
    if (_isProcessing) return false;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue ?? barcode.displayValue;
      if (value != null && value.trim().isNotEmpty) {
        _isProcessing = true;
        notifyListeners();

        final format = barcode.format.name;
        onScanSuccess(value, format);
        return true;
      }
    }
    return false;
  }

  void resetProcessing() {
    _isProcessing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    scannerController.dispose();
    super.dispose();
  }
}
