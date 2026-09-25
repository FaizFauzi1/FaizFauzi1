import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart'; // Added for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:share_plus/share_plus.dart';
// Removed dart:io and path_provider for better web/cross-platform support

class VendorQRCodeScreen extends StatefulWidget {
  const VendorQRCodeScreen({super.key});

  @override
  State<VendorQRCodeScreen> createState() => _VendorQRCodeScreenState();
}

class _VendorQRCodeScreenState extends State<VendorQRCodeScreen> {
  String _selectedType = 'profile'; // 'profile' or 'service'
  String? _selectedServiceId;
  final GlobalKey _qrKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorProvider>(
      builder: (context, vendorProvider, child) {
        final vendor = vendorProvider.currentVendor;
        final services = vendorProvider.getCustomServices();

        if (vendor == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('QR Codes'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text('No vendor profile found'),
            ),
          );
        }

        final qrData = _selectedType == 'profile'
            ? 'https://eventease-web.netlify.app/vendor/${vendor.id}'
            : _selectedServiceId != null
                ? 'https://eventease-web.netlify.app/service/$_selectedServiceId'
                : 'https://eventease-web.netlify.app/vendor/${vendor.id}';

        final displayName = _selectedType == 'profile'
            ? vendor.name
            : _selectedServiceId != null
                ? services
                    .where((s) => s.id == _selectedServiceId)
                    .map((s) => s.name)
                    .cast<String?>()
                    .firstWhere((_) => true, orElse: () => vendor.name)!
                : vendor.name;

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('QR Codes'),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareQRCode(qrData, displayName),
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _downloadQRCode(qrData, displayName),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type selector
                _buildTypeSelector(),
                
                const SizedBox(height: 20),

                // Service selector (if service type selected)
                if (_selectedType == 'service') ...[
                  _buildServiceSelector(services),
                  const SizedBox(height: 20),
                ],

                // QR Code Display
                _buildQRCodeCard(qrData, displayName, vendor.name),

                const SizedBox(height: 20),

                // Instructions
                _buildInstructions(),

                const SizedBox(height: 20),

                // Action buttons
                _buildActionButtons(qrData, displayName),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton('profile', 'My Profile', Icons.business),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTypeButton('service', 'My Services', Icons.business_center),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return ElevatedButton.icon(
      onPressed: () => setState(() => _selectedType = type),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.transparent,
        foregroundColor: isSelected ? Colors.white : AppTheme.textPrimaryColor,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildServiceSelector(List services) {
    if (services.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No services available. Create a service first.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Service',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedServiceId,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Choose a service'),
            items: services.map((service) {
              return DropdownMenuItem<String>(
                value: service.id,
                child: Text(service.name),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedServiceId = value),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeCard(String qrData, String displayName, String vendorName) {
    return RepaintBoundary(
      key: _qrKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        vendorName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 250,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                embeddedImage: null, // Could add vendor logo here
                embeddedImageStyle: const QrEmbeddedImageStyle(
                  size: Size(40, 40),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Footer text
            const Text(
              'Scan with any QR scanner',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'How to use',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionItem('1', 'Share this QR code with potential customers'),
          _buildInstructionItem('2', 'They scan it using any QR scanner (camera app, etc.)'),
          _buildInstructionItem('3', 'They\'ll be directed to your profile or service on the web'),
          _buildInstructionItem('4', 'Download and print for physical marketing materials'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String qrData, String displayName) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _shareQRCode(qrData, displayName),
            icon: const Icon(Icons.share),
            label: const Text('Share QR Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _downloadQRCode(qrData, displayName),
            icon: const Icon(Icons.download),
            label: const Text('Download as Image'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _shareQRCode(String qrData, String displayName) async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _showError('Unable to generate QR code image');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showError('Failed to capture QR code image data');
        return;
      }
      final pngBytes = byteData.buffer.asUint8List();

      // Use XFile.fromData for cross-platform sharing (works on Web too)
      final xFile = XFile.fromData(
        pngBytes,
        name: 'qr_code_${DateTime.now().millisecondsSinceEpoch}.png',
        mimeType: 'image/png',
      );

      await Share.shareXFiles(
        [xFile],
        text: 'Check out $displayName on EventEase: $qrData',
      );
    } catch (e) {
      _showError('Failed to share QR code: $e');
    }
  }

  Future<void> _downloadQRCode(String qrData, String displayName) async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _showError('Unable to generate QR code image');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showError('Failed to capture QR code image data');
        return;
      }
      final pngBytes = byteData.buffer.asUint8List();

      final fileName = 'eventease_qr_${displayName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';

      // On Web, Share.shareXFiles will naturally trigger a download/save prompt
      // This is the most consistent cross-platform way without using dart:io or path_provider
      final xFile = XFile.fromData(
        pngBytes,
        name: fileName,
        mimeType: 'image/png',
      );

      if (mounted) {
        // We use shareXFiles as a proxy for download on mobile and web
        // On Web, this triggers a file download in most browsers
        await Share.shareXFiles([xFile], text: 'Download QR Code');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR Code process started for $displayName'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to process QR code download: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
