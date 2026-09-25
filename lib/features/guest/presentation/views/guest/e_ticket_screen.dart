import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/guest/data/models/guest.dart';
import 'package:eventease/core/utils/guest_routes.dart';
import 'package:eventease/core/utils/app_theme.dart';

class ETicketScreen extends StatefulWidget {
  final Event event;
  final Guest guest;

  const ETicketScreen({
    super.key,
    required this.event,
    required this.guest,
  });

  @override
  State<ETicketScreen> createState() => _ETicketScreenState();
}

class _ETicketScreenState extends State<ETicketScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('E-Ticket'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareTicket(context),
            tooltip: 'Share Ticket',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadTicket(context),
            tooltip: 'Download Ticket',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ticket Card
                _buildTicketCard(),

                const SizedBox(height: 24),

                // Instructions
                _buildInstructions(),

                const SizedBox(height: 24),

                // Action Buttons
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Event Logo/Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        widget.event.type.icon,
                        size: 30,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Event Title
                    Text(
                      widget.event.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Event Date & Time
                    Text(
                      _formatDateTime(widget.event.date, widget.event.startTime),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Ticket Details Section
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Guest Name
                    _buildTicketField('Guest Name', widget.guest.name),

                    const SizedBox(height: 12),

                    // Guest Email
                    _buildTicketField('Email', widget.guest.email),

                    const SizedBox(height: 12),

                    // Guest Phone (if available)
                    if (widget.guest.phone != null)
                      _buildTicketField('Phone', widget.guest.phone!),

                    const SizedBox(height: 12),

                    // Number of Guests
                    _buildTicketField('Party Size', widget.guest.numberOfGuests.toString()),

                    const SizedBox(height: 20),

                    // Venue
                    Text(
                      widget.event.venue.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      widget.event.venue.location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // QR Code Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // QR Code
                      RepaintBoundary(
                        key: _qrKey,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: _generateTicketQR(),
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Ticket ID
                    Text(
                      'Ticket ID: ${_generateTicketId()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Valid Until
                    Text(
                      'Valid until: ${_formatDateTime(widget.event.date, widget.event.endTime ?? widget.event.startTime.add(const Duration(hours: 2)))}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketField(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'How to Use Your E-Ticket',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInstructionItem(
              Icons.qr_code_scanner,
              'Show QR Code',
              'Present this QR code at the entrance for scanning',
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              Icons.smartphone,
              'Digital Access',
              'Keep your phone charged and screen unlocked',
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              Icons.access_time,
              'Arrival Time',
              'Arrive 15-30 minutes before the event starts',
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
              Icons.group,
              'Party Check-in',
              'All guests in your party must check in together',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _addToWallet(context),
          icon: const Icon(Icons.add_card),
          label: const Text('Add to Digital Wallet'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _navigateToEventDetails(context),
          icon: const Icon(Icons.event),
          label: const Text('View Event Details'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _navigateToVenueMap(context),
          icon: const Icon(Icons.map),
          label: const Text('Venue Map & Directions'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  String _generateTicketQR() {
    // Generate QR code data containing ticket information
    final ticketData = {
      'ticketId': _generateTicketId(),
      'eventId': widget.event.id,
      'guestId': widget.guest.id,
      'guestName': widget.guest.name,
      'eventTitle': widget.event.title,
      'eventDate': widget.event.date.toIso8601String(),
      'partySize': widget.guest.numberOfGuests,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Convert to JSON string for QR code
    return jsonEncode(ticketData);
  }

  String _generateTicketId() {
    // Generate a unique ticket ID
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final eventId = widget.event.id.hashCode.abs();
    final guestId = widget.guest.id.hashCode.abs();
    return 'TKT-${timestamp.toString().substring(8)}-${eventId.toString().substring(0, 3)}-${guestId.toString().substring(0, 3)}'.toUpperCase();
  }

  String _formatDateTime(DateTime date, DateTime time) {
    final dateStr = '${date.day}/${date.month}/${date.year}';
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '${hour}:${time.minute.toString().padLeft(2, '0')} $amPm';
    return '$dateStr at $timeStr';
  }

  Future<void> _shareTicket(BuildContext context) async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _showError(context, 'Unable to generate ticket image');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showError(context, 'Failed to capture ticket image data');
        return;
      }
      final pngBytes = byteData.buffer.asUint8List();

      final xFile = XFile.fromData(
        pngBytes,
        name: 'ticket_${widget.guest.name.replaceAll(' ', '_')}.png',
        mimeType: 'image/png',
      );

      await Share.shareXFiles(
        [xFile],
        text: 'Here is my ticket for ${widget.event.title}!',
      );
    } catch (e) {
      _showError(context, 'Failed to share ticket: $e');
    }
  }

  Future<void> _downloadTicket(BuildContext context) async {
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _showError(context, 'Unable to generate ticket image');
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _showError(context, 'Failed to capture ticket image data');
        return;
      }
      final pngBytes = byteData.buffer.asUint8List();

      final xFile = XFile.fromData(
        pngBytes,
        name: 'ticket_${widget.guest.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png',
        mimeType: 'image/png',
      );

      await Share.shareXFiles([xFile], text: 'Download Ticket');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket processing started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(context, 'Failed to process ticket download: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _addToWallet(BuildContext context) {
    // TODO: Implement add to digital wallet functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Digital wallet integration coming soon!')),
    );
  }

  void _navigateToEventDetails(BuildContext context) {
    Navigator.of(context).pushNamed(
      GuestRoutes.eventDetails,
      arguments: {'event': widget.event},
    );
  }

  void _navigateToVenueMap(BuildContext context) {
    Navigator.of(context).pushNamed(
      GuestRoutes.eventMap,
      arguments: {'event': widget.event},
    );
  }
}
