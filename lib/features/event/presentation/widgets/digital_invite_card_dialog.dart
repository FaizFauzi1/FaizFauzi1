import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eventease/core/constants/app_config.dart';
import 'package:eventease/core/services/analytics_service.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/event/data/models/event.dart';

enum CardTemplateTheme {
  weddingFloral,
  birthdayBash,
  modernDark,
  luxuryGold,
  minimalistClean,
}

class DigitalInviteCardDialog extends StatefulWidget {
  final Event event;
  final String? initialGuestName;

  const DigitalInviteCardDialog({
    super.key,
    required this.event,
    this.initialGuestName,
  });

  static Future<void> show(BuildContext context, {required Event event, String? guestName}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DigitalInviteCardDialog(
        event: event,
        initialGuestName: guestName,
      ),
    );
  }

  @override
  State<DigitalInviteCardDialog> createState() => _DigitalInviteCardDialogState();
}

class _DigitalInviteCardDialogState extends State<DigitalInviteCardDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  
  // Customization State
  int _selectedTabIndex = 0; // 0 = Templates, 1 = Custom Image Upload, 2 = Custom PDF
  CardTemplateTheme _selectedTheme = CardTemplateTheme.weddingFloral;
  File? _customUploadedImage;
  File? _customUploadedPdf;
  
  late TextEditingController _customMessageController;
  late TextEditingController _websiteUrlController;
  
  bool _showQrCode = true;
  bool _showVenue = true;
  bool _showWebsite = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final masterCode = widget.event.id.substring(0, 8).toUpperCase();
    final defaultUrl = widget.event.additionalInfo['customWebsiteUrl'] as String? ??
        widget.event.additionalInfo['websiteUrl'] as String? ??
        '${AppConfig.inviteLinkBase}$masterCode';

    _customMessageController = TextEditingController(
      text: widget.event.invitationMessage ?? 'We cordially invite you to celebrate this special occasion with us!',
    );
    _websiteUrlController = TextEditingController(text: defaultUrl);
  }

  @override
  void dispose() {
    _customMessageController.dispose();
    _websiteUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (picked != null) {
        setState(() {
          _customUploadedImage = File(picked.path);
          _selectedTabIndex = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    }
  }

  Future<void> _pickCustomPdf() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _customUploadedPdf = File(result.files.single.path!);
          _selectedTabIndex = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select PDF: $e')),
        );
      }
    }
  }

  Future<File?> _captureCardImage() async {
    try {
      setState(() => _isExporting = true);
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/invitation_card_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (e) {
      debugPrint('Error capturing card image: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<File?> _exportCardAsPdf() async {
    try {
      final pngImageFile = await _captureCardImage();
      if (pngImageFile == null || !await pngImageFile.exists()) return null;

      final imageBytes = await pngImageFile.readAsBytes();
      final pdfImage = pw.MemoryImage(imageBytes);

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 420,
                    child: pw.Image(pdfImage),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Event Join Code: ${widget.event.id.substring(0, 8).toUpperCase()}',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  if (_websiteUrlController.text.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Host Website: ${_websiteUrlController.text.trim()}',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.blue800),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final pdfFile = File('${tempDir.path}/invitation_card_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await pdfFile.writeAsBytes(await pdf.save());
      return pdfFile;
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      return null;
    }
  }

  Future<void> _shareToWhatsApp() async {
    final masterCode = widget.event.id.substring(0, 8).toUpperCase();
    final websiteUrl = _websiteUrlController.text.trim();
    final guestGreeting = widget.initialGuestName != null ? 'Dear ${widget.initialGuestName},\n\n' : '';

    final whatsappText = '✨ *YOU ARE CORDIALLY INVITED!* ✨\n\n'
        '$guestGreeting*Event:* ${widget.event.title}\n'
        '📅 *Date:* ${_formatDate(widget.event.date)}\n'
        '⏰ *Time:* ${_formatTime(widget.event.startTime)}\n'
        '📍 *Venue:* ${widget.event.venue.name}, ${widget.event.venue.location}\n\n'
        '${_customMessageController.text.trim()}\n\n'
        '🔑 *Join Code:* `$masterCode`\n'
        '🌐 *Host Website:* $websiteUrl\n\n'
        'Powered by EventEase 🌟';

    // Capture Digital Card Image
    final cardImageFile = await _captureCardImage();

    if (cardImageFile != null && await cardImageFile.exists()) {
      try {
        final xFile = XFile(cardImageFile.path);
        await Share.shareXFiles(
          [xFile],
          text: whatsappText,
          subject: 'Invitation to ${widget.event.title}',
        );
        // Track successful card share
        AnalyticsService().trackInvitationShared(
          eventId: widget.event.id,
          format: 'image_card',
          template: _selectedTabIndex == 1 ? 'custom_image' : _selectedTheme.name,
          guestName: widget.initialGuestName,
          hasCustomWebsite: _showWebsite && websiteUrl.isNotEmpty,
        );
        return;
      } catch (e) {
        debugPrint('Fallback sharing: $e');
      }
    }

    // Direct WhatsApp text fallback if image share fails
    final encodedText = Uri.encodeComponent(whatsappText);
    final whatsappUri = Uri.parse('whatsapp://send?text=$encodedText');
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      final webWhatsapp = Uri.parse('https://wa.me/?text=$encodedText');
      if (await canLaunchUrl(webWhatsapp)) {
        await launchUrl(webWhatsapp, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: whatsappText));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp not installed. Invitation text copied to clipboard!')),
          );
        }
      }
    }
  }

  Future<void> _sharePdfToWhatsApp() async {
    File? pdfFileToSend;
    if (_selectedTabIndex == 2 && _customUploadedPdf != null) {
      pdfFileToSend = _customUploadedPdf;
    } else {
      pdfFileToSend = await _exportCardAsPdf();
    }

    if (pdfFileToSend == null || !await pdfFileToSend.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate or read PDF file')),
        );
      }
      return;
    }

    final masterCode = widget.event.id.substring(0, 8).toUpperCase();
    final websiteUrl = _websiteUrlController.text.trim();
    final guestGreeting = widget.initialGuestName != null ? 'Dear ${widget.initialGuestName},\n\n' : '';

    final whatsappText = '📄 *YOU ARE INVITED (PDF Attached)* 📄\n\n'
        '$guestGreeting*Event:* ${widget.event.title}\n'
        '📅 *Date:* ${_formatDate(widget.event.date)}\n'
        '⏰ *Time:* ${_formatTime(widget.event.startTime)}\n'
        '📍 *Venue:* ${widget.event.venue.name}, ${widget.event.venue.location}\n\n'
        '${_customMessageController.text.trim()}\n\n'
        '🔑 *Join Code:* `$masterCode`\n'
        '🌐 *Host Website:* $websiteUrl\n\n'
        'Powered by EventEase 🌟';

    try {
      final xFile = XFile(pdfFileToSend.path);
      await Share.shareXFiles(
        [xFile],
        text: whatsappText,
        subject: 'PDF Invitation - ${widget.event.title}',
      );
      // Track PDF invite share
      AnalyticsService().trackInvitationShared(
        eventId: widget.event.id,
        format: 'pdf',
        template: _selectedTabIndex == 2 ? 'custom_pdf' : _selectedTheme.name,
        guestName: widget.initialGuestName,
        hasCustomWebsite: _showWebsite && websiteUrl.isNotEmpty,
      );
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
    }
  }

  Future<void> _saveCardToGallery() async {
    final imageFile = await _captureCardImage();
    if (imageFile != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Digital invitation card saved to: ${imageFile.path}'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              Share.shareXFiles([XFile(imageFile.path)]);
            },
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final masterCode = widget.event.id.substring(0, 8).toUpperCase();

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 880),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.style, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Digital & PDF Invitation Card',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Buttons (Templates vs Custom Image vs Custom PDF)
            Container(
              color: Colors.grey.shade100,
              child: Row(
                children: [
                  _buildTabButton(0, Icons.palette_outlined, 'Templates'),
                  _buildTabButton(1, Icons.cloud_upload_outlined, 'Custom Image'),
                  _buildTabButton(2, Icons.picture_as_pdf_outlined, 'Custom PDF'),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card / PDF Preview Widget
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 360),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _selectedTabIndex == 2
                              ? _buildPdfPreviewWidget(masterCode)
                              : RepaintBoundary(
                                  key: _repaintKey,
                                  child: _selectedTabIndex == 1 && _customUploadedImage != null
                                      ? _buildCustomUploadedCard(masterCode)
                                      : _buildTemplateCard(masterCode),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Selection Controls based on tab
                    if (_selectedTabIndex == 0) ...[
                      const Text(
                        'Select Card Style:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 70,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildThemeChip(CardTemplateTheme.weddingFloral, '🌸 Floral Elegance', Colors.pink.shade50),
                            _buildThemeChip(CardTemplateTheme.birthdayBash, '🎉 Birthday Party', Colors.purple.shade50),
                            _buildThemeChip(CardTemplateTheme.modernDark, '✨ Modern Dark', Colors.blueGrey.shade900),
                            _buildThemeChip(CardTemplateTheme.luxuryGold, '👑 Luxury Gold', Colors.amber.shade50),
                            _buildThemeChip(CardTemplateTheme.minimalistClean, '🌿 Minimalist', Colors.teal.shade50),
                          ],
                        ),
                      ),
                    ] else if (_selectedTabIndex == 1) ...[
                      // Custom Image Upload Controls
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickCustomImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Choose from Gallery'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                foregroundColor: AppTheme.primaryColor,
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickCustomImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Take Photo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                foregroundColor: AppTheme.primaryColor,
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Custom PDF Upload Controls
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _pickCustomPdf,
                          icon: const Icon(Icons.upload_file),
                          label: Text(_customUploadedPdf != null ? 'Change PDF File' : 'Upload Custom PDF Invitation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Customization Text Fields
                    const Text(
                      'Customize Details & Host Website:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: _customMessageController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Personal Invitation Message',
                        hintText: 'Add a warm welcome message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _websiteUrlController,
                      decoration: InputDecoration(
                        labelText: "Host's Custom Website / RSVP Link",
                        hintText: 'e.g. https://our-special-wedding.com',
                        helperText: "Enter host's personal website URL or custom landing page",
                        prefixIcon: const Icon(Icons.language, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Toggle Switches
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Show QR Code'),
                          selected: _showQrCode,
                          onSelected: (val) => setState(() => _showQrCode = val),
                        ),
                        FilterChip(
                          label: const Text('Show Venue'),
                          selected: _showVenue,
                          onSelected: (val) => setState(() => _showVenue = val),
                        ),
                        FilterChip(
                          label: const Text('Show Website'),
                          selected: _showWebsite,
                          onSelected: (val) => setState(() => _showWebsite = val),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer Share Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Main WhatsApp Card Share Button
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isExporting ? null : _shareToWhatsApp,
                          icon: const Icon(Icons.image, color: Colors.white, size: 18),
                          label: const Text(
                            'Share Image Card',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isExporting ? null : _sharePdfToWhatsApp,
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                          label: const Text(
                            'Share PDF Invite',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Secondary Actions (Save & Copy Link)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isExporting ? null : _saveCardToGallery,
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Save Card'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final masterCode = widget.event.id.substring(0, 8).toUpperCase();
                            final url = _websiteUrlController.text.trim();
                            Clipboard.setData(ClipboardData(text: 'Host Website: $url\nJoin Code: $masterCode'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Host website link & code copied!')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy Website & Code'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String label) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeChip(CardTemplateTheme theme, String label, Color bgColor) {
    final isSelected = _selectedTheme == theme && _selectedTabIndex == 0;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = theme;
          _selectedTabIndex = 0;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PDF PREVIEW WIDGET
  // --------------------------------------------------------------------------

  Widget _buildPdfPreviewWidget(String masterCode) {
    if (_customUploadedPdf == null) {
      return Container(
        padding: const EdgeInsets.all(32),
        color: Colors.red.shade50,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 54),
            const SizedBox(height: 12),
            Text(
              'No Custom PDF Selected',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 16),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload a PDF file or export your digital card as a PDF document.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final fileName = _customUploadedPdf!.path.split(Platform.pathSeparator).last;

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.red.shade50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 48),
          const SizedBox(height: 12),
          Text(
            fileName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Chip(
            avatar: const Icon(Icons.check_circle, color: Colors.green, size: 16),
            label: const Text('Custom PDF Attached'),
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            'Host Website: ${_websiteUrlController.text}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.blue, fontSize: 11, decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TEMPLATE CARD RENDERERS
  // --------------------------------------------------------------------------

  Widget _buildTemplateCard(String masterCode) {
    switch (_selectedTheme) {
      case CardTemplateTheme.weddingFloral:
        return _buildFloralWeddingCard(masterCode);
      case CardTemplateTheme.birthdayBash:
        return _buildBirthdayBashCard(masterCode);
      case CardTemplateTheme.modernDark:
        return _buildModernDarkCard(masterCode);
      case CardTemplateTheme.luxuryGold:
        return _buildLuxuryGoldCard(masterCode);
      case CardTemplateTheme.minimalistClean:
        return _buildMinimalistCard(masterCode);
    }
  }

  // 1. Floral Wedding Card Theme
  Widget _buildFloralWeddingCard(String masterCode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F0),
        border: Border.all(color: const Color(0xFFD4AF37), width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_florist, color: Color(0xFFC86D51), size: 36),
          const SizedBox(height: 8),
          const Text(
            'YOU ARE INVITED',
            style: TextStyle(
              color: Color(0xFF8B4513),
              fontSize: 12,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.event.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF2C1810),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            width: 80,
            color: const Color(0xFFD4AF37),
          ),
          const SizedBox(height: 12),
          Text(
            _customMessageController.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF5C4033),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Color(0xFF8B4513)),
              const SizedBox(width: 6),
              Text(
                '${_formatDate(widget.event.date)} at ${_formatTime(widget.event.startTime)}',
                style: const TextStyle(
                  color: Color(0xFF2C1810),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (_showVenue) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 14, color: Color(0xFFC86D51)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${widget.event.venue.name}, ${widget.event.venue.location}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF5C4033), fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (_showQrCode) ...[
            QrImageView(
              data: _websiteUrlController.text,
              version: QrVersions.auto,
              size: 80.0,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF2C1810)),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF8B4513)),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2C1810),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Join Code: $masterCode',
              style: const TextStyle(color: Color(0xFFFFF8F0), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          if (_showWebsite) ...[
            const SizedBox(height: 8),
            Text(
              _websiteUrlController.text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8B4513), fontSize: 10, decoration: TextDecoration.underline),
            ),
          ],
        ],
      ),
    );
  }

  // 2. Birthday Bash Theme
  Widget _buildBirthdayBashCard(String masterCode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉 CELEBRATION TIME 🎉', style: TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(
            widget.event.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            _customMessageController.text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '🗓️ ${_formatDate(widget.event.date)}  ⏰ ${_formatTime(widget.event.startTime)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (_showVenue) ...[
                  const SizedBox(height: 4),
                  Text(
                    '📍 ${widget.event.venue.name}, ${widget.event.venue.location}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_showQrCode) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: QrImageView(
                data: _websiteUrlController.text,
                size: 75.0,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'RSVP Code: $masterCode',
            style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.5),
          ),
          if (_showWebsite) ...[
            const SizedBox(height: 6),
            Text(_websiteUrlController.text, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
          ],
        ],
      ),
    );
  }

  // 3. Modern Dark Glass Theme
  Widget _buildModernDarkCard(String masterCode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.cyanAccent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              const Text('OFFICIAL INVITATION', style: TextStyle(color: Colors.cyanAccent, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.event.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _customMessageController.text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(
                  '${_formatDate(widget.event.date)} @ ${_formatTime(widget.event.startTime)}',
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                if (_showVenue) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${widget.event.venue.name}, ${widget.event.venue.location}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_showQrCode) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: QrImageView(data: _websiteUrlController.text, size: 75.0),
            ),
            const SizedBox(height: 8),
          ],
          Text('CODE: $masterCode', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2)),
          if (_showWebsite) ...[
            const SizedBox(height: 4),
            Text(_websiteUrlController.text, style: const TextStyle(color: Colors.cyanAccent, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  // 4. Luxury Gold Theme
  Widget _buildLuxuryGoldCard(String masterCode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Color(0xFFFFD700), size: 30),
          const SizedBox(height: 8),
          const Text('VIP INVITATION', style: TextStyle(color: Color(0xFFFFD700), fontSize: 11, letterSpacing: 3, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            widget.event.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'serif'),
          ),
          const SizedBox(height: 10),
          Text(
            _customMessageController.text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          Text(
            'DATE: ${_formatDate(widget.event.date)} | TIME: ${_formatTime(widget.event.startTime)}',
            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          if (_showVenue) ...[
            const SizedBox(height: 4),
            Text(
              '${widget.event.venue.name}, ${widget.event.venue.location}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
          if (_showQrCode) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(6)),
              child: QrImageView(data: _websiteUrlController.text, size: 70.0),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFFD700)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'PASS: $masterCode',
              style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2),
            ),
          ),
          if (_showWebsite) ...[
            const SizedBox(height: 6),
            Text(_websiteUrlController.text, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  // 5. Minimalist Clean Theme
  Widget _buildMinimalistCard(String masterCode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.event.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            _customMessageController.text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Text(
            '${_formatDate(widget.event.date)} • ${_formatTime(widget.event.startTime)}',
            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          if (_showVenue) ...[
            const SizedBox(height: 4),
            Text(
              '${widget.event.venue.name}, ${widget.event.venue.location}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          if (_showQrCode) ...[
            QrImageView(data: _websiteUrlController.text, size: 75.0),
            const SizedBox(height: 8),
          ],
          Text('CODE: $masterCode', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
          if (_showWebsite) ...[
            const SizedBox(height: 4),
            Text(_websiteUrlController.text, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // CUSTOM UPLOADED IMAGE CARD RENDERER
  // --------------------------------------------------------------------------

  Widget _buildCustomUploadedCard(String masterCode) {
    return Stack(
      children: [
        // Uploaded Background Image
        Image.file(
          _customUploadedImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 380,
        ),
        
        // Gradient overlay for readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Text & Details Overlay
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.event.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _customMessageController.text,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
              ),
              const SizedBox(height: 10),
              Text(
                '📅 ${_formatDate(widget.event.date)} at ${_formatTime(widget.event.startTime)}',
                style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              if (_showVenue) ...[
                const SizedBox(height: 2),
                Text(
                  '📍 ${widget.event.venue.name}, ${widget.event.venue.location}',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_showQrCode) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                      child: QrImageView(data: _websiteUrlController.text, size: 55.0),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Join Code: $masterCode',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      if (_showWebsite) ...[
                        const SizedBox(height: 4),
                        Text(
                          _websiteUrlController.text,
                          style: const TextStyle(color: Colors.white70, fontSize: 9),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
