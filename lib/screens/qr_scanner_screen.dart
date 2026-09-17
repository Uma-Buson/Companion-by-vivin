import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constant/app_colors.dart';
import '../constant/app_strings.dart';
import '../constant/app_text_styles.dart';
import '../controller/qr_scanner_controller.dart';

/// Screen 3: QR Scanner viewfinder with torch and camera switch controls.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  late final QrScannerController _scannerController;
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _scannerController = QrScannerController();
    _scannerController.addListener(_onStateChanged);

    // Laser animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.removeListener(_onStateChanged);
    _scannerController.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    _scannerController.processBarcode(
      capture,
      (value, format) {
        // Pop with scanned results
        if (mounted) {
          Navigator.of(context).pop({
            'rawValue': value,
            'format': format,
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanWindowSize = MediaQuery.of(context).size.width * 0.72;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          AppStrings.scannerTitle,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          // Torch toggle
          IconButton(
            icon: Icon(
              _scannerController.isTorchOn
                  ? Icons.flash_on_rounded
                  : Icons.flash_off_rounded,
              color: _scannerController.isTorchOn
                  ? Colors.amber
                  : Colors.white,
            ),
            tooltip: _scannerController.isTorchOn
                ? AppStrings.torchOff
                : AppStrings.torchOn,
            onPressed: _scannerController.toggleTorch,
          ),
          // Camera switch
          IconButton(
            icon: const Icon(
              Icons.flip_camera_ios_rounded,
              color: Colors.white,
            ),
            tooltip: AppStrings.cameraSwitch,
            onPressed: _scannerController.switchCamera,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Mobile Scanner Camera View
          MobileScanner(
            controller: _scannerController.scannerController,
            onDetect: _onBarcodeDetected,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.videocam_off_rounded,
                        color: AppColors.primaryRedLight,
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.permissionCameraDenied,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Back to Dashboard'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Dark Framing Overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.65),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
                Center(
                  child: Container(
                    width: scanWindowSize,
                    height: scanWindowSize,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Red Scanning Reticle Border & Moving Laser Line
          Center(
            child: SizedBox(
              width: scanWindowSize,
              height: scanWindowSize,
              child: Stack(
                children: [
                  // Reticle corners (Red themed)
                  CustomPaint(
                    size: Size(scanWindowSize, scanWindowSize),
                    painter: _ScannerReticlePainter(
                      color: AppColors.primaryRed,
                      strokeWidth: 4,
                      cornerLength: 28,
                    ),
                  ),

                  // Animated Red Laser Line
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Positioned(
                        top: (scanWindowSize - 4) * _animation.value,
                        left: 8,
                        right: 8,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.primaryRedLight,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryRed.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Helper Instruction
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppColors.primaryRed.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.primaryRedLight,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      AppStrings.scannerHint,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for crisp corner reticles around the scan target
class _ScannerReticlePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;

  _ScannerReticlePainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Top Left
    canvas.drawLine(const Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, cornerLength), paint);

    // Top Right
    canvas.drawLine(Offset(w, 0), Offset(w - cornerLength, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, cornerLength), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, h), Offset(cornerLength, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - cornerLength), paint);

    // Bottom Right
    canvas.drawLine(Offset(w, h), Offset(w - cornerLength, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
