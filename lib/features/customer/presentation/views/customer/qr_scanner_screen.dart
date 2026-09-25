import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:provider/provider.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanning = true;

  void _handleCapture(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        debugPrint('Barcode found! $code');
        _processQRCode(code);
        break;
      }
    }
  }

  void _processQRCode(String rawCode) {
    setState(() => _isScanning = false);

    final String code = rawCode.trim();
    debugPrint('Processing refined code: "$code"');

    // Supported QR code patterns:
    // 1. Deep links: eventease://vendor/{vendorId} or eventease://service/{serviceId}
    // 2. Web URLs: https://eventease-web.netlify.app/vendor/{vendorId} or /service/{serviceId}
    // 3. Any domain: https://*/vendor/{vendorId} or https://*/service/{serviceId}
    
    try {
      String? vendorId;
      String? serviceId;

      // Handle custom scheme links (eventease://...)
      if (code.startsWith('eventease://')) {
        final uri = Uri.parse(code);
        if (uri.host == 'vendor') {
          vendorId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
          // Fallback if path segments is empty (e.g. eventease://vendor/123 -> host=vendor, path=/123)
          if (vendorId == null || vendorId.isEmpty) {
             vendorId = uri.path.replaceAll('/', '');
          }
        } else if (uri.host == 'service') {
          serviceId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
          if (serviceId == null || serviceId.isEmpty) {
             serviceId = uri.path.replaceAll('/', '');
          }
        }
      } 
      // Handle web URLs and any other format
      else {
        final uri = Uri.parse(code);
        final segments = uri.pathSegments;
        
        // Find vendor keyword (support singular or plural)
        final vendorIndex = segments.indexWhere((s) => s == 'vendor' || s == 'vendors');
        if (vendorIndex != -1 && vendorIndex + 1 < segments.length) {
          vendorId = segments[vendorIndex + 1];
        } 
        
        // Find service keyword (support singular or plural)
        final serviceIndex = segments.indexWhere((s) => s == 'service' || s == 'services');
        if (serviceIndex != -1 && serviceIndex + 1 < segments.length) {
          serviceId = segments[serviceIndex + 1];
        }
      }

      // Final sanitization of IDs (remove trailing slashes if any)
      vendorId = vendorId?.replaceAll('/', '')?.trim();
      serviceId = serviceId?.replaceAll('/', '')?.trim();

      debugPrint('Extracted - VendorId: $vendorId, ServiceId: $serviceId');

      // Navigate based on what was found
      if (vendorId != null && vendorId.isNotEmpty) {
        _navigateToVendor(vendorId);
      } else if (serviceId != null && serviceId.isNotEmpty) {
        _navigateToService(serviceId);
      } else {
        debugPrint('No valid ID found in QR code');
        _showInvalidQR();
      }
    } catch (e) {
      debugPrint('Error processing QR: $e');
      _showInvalidQR();
    }
  }

  void _navigateToVendor(String vendorId) {
    Navigator.pushReplacementNamed(
      context, 
      '/vendor-profile', 
      arguments: {'vendorId': vendorId},
    );
  }

  void _navigateToService(String serviceId) {
    Navigator.pushReplacementNamed(
      context, 
      '/product-detail', 
      arguments: {'serviceId': serviceId},
    );
  }

  void _showInvalidQR() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invalid QR Code'),
        content: const Text('This QR code is not recognized by EventEase. Please scan a valid EventEase service or vendor QR.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isScanning = true);
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleCapture,
            controller: MobileScannerController(
              detectionSpeed: DetectionSpeed.normal,
              facing: CameraFacing.back,
              torchEnabled: false,
            ),
          ),
          // Scanning Overlay
          _buildOverlay(),
          // Back Button / Instructions
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Center the QR code in the frame',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.7;
        return Stack(
          children: [
            Container(
              decoration: ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderColor: AppTheme.primaryColor,
                  borderRadius: 20,
                  borderLength: 40,
                  borderWidth: 10,
                  cutOutSize: size,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.borderLength = 20.0,
    this.borderRadius = 0.0,
    this.cutOutSize = 250.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final double _cutOutSize = cutOutSize;

    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(rect)
      ..addRect(Rect.fromCenter(
        center: rect.center,
        width: _cutOutSize,
        height: _cutOutSize,
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final halfCutOut = _cutOutSize / 2;
    final center = rect.center;
    
    // Draw corners
    final left = center.dx - halfCutOut;
    final top = center.dy - halfCutOut;
    final right = center.dx + halfCutOut;
    final bottom = center.dy + halfCutOut;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + borderLength)
        ..lineTo(left, top + borderRadius)
        ..quadraticBezierTo(left, top, left + borderRadius, top)
        ..lineTo(left + borderLength, top),
      borderPaint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(right - borderLength, top)
        ..lineTo(right - borderRadius, top)
        ..quadraticBezierTo(right, top, right, top + borderRadius)
        ..lineTo(right, top + borderLength),
      borderPaint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - borderLength)
        ..lineTo(left, bottom - borderRadius)
        ..quadraticBezierTo(left, bottom, left + borderRadius, bottom)
        ..lineTo(left + borderLength, bottom),
      borderPaint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(right - borderLength, bottom)
        ..lineTo(right - borderRadius, bottom)
        ..quadraticBezierTo(right, bottom, right, bottom - borderRadius)
        ..lineTo(right, bottom - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
        borderColor: borderColor,
        borderWidth: borderWidth * t,
        borderLength: borderLength * t,
        borderRadius: borderRadius * t,
        cutOutSize: cutOutSize * t,
      );
}
