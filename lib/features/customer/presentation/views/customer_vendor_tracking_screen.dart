import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

/// Customer-facing screen to track the vendor's real-time event-day status.
class CustomerVendorTrackingScreen extends StatefulWidget {
  final String bookingId;
  final String vendorName;
  final String serviceName;
  final DateTime eventDate;
  final String eventLocation;
  final String? vendorUserId; // Optional: for chat navigation

  const CustomerVendorTrackingScreen({
    Key? key,
    required this.bookingId,
    required this.vendorName,
    required this.serviceName,
    required this.eventDate,
    required this.eventLocation,
    this.vendorUserId,
  }) : super(key: key);

  @override
  State<CustomerVendorTrackingScreen> createState() => _CustomerVendorTrackingScreenState();
}

class _CustomerVendorTrackingScreenState extends State<CustomerVendorTrackingScreen> {
  static const _statusOrder = ['scheduled', 'on_the_way', 'arrived', 'started', 'completed'];

  String _currentStatus = 'scheduled';
  double? _lastLat;
  double? _lastLng;
  DateTime? _lastUpdated;
  bool _isLoading = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    // Poll every 30 seconds for updates
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchStatus());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    try {
      final data = await Supabase.instance.client
          .from('vendor_checkins')
          .select()
          .eq('booking_id', widget.bookingId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted && data != null) {
        setState(() {
          _currentStatus = data['status'] as String? ?? 'scheduled';
          _lastLat = (data['location_lat'] as num?)?.toDouble();
          _lastLng = (data['location_lng'] as num?)?.toDouble();
          _lastUpdated = data['created_at'] != null
              ? DateTime.tryParse(data['created_at'].toString())?.toLocal()
              : null;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _hasReached(String step) {
    final current = _statusOrder.indexOf(_currentStatus);
    final target = _statusOrder.indexOf(step);
    return target <= current;
  }

  String _timeSince(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('d MMM, h:mm a').format(dt);
  }

  Future<void> _openInMaps() async {
    if (_lastLat == null || _lastLng == null) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$_lastLat,$_lastLng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _statusColor() {
    switch (_currentStatus) {
      case 'on_the_way': return Colors.blue;
      case 'arrived': return Colors.orange;
      case 'started': return AppTheme.primaryColor;
      case 'completed': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (_currentStatus) {
      case 'on_the_way': return 'On The Way 🚗';
      case 'arrived': return 'Arrived at Venue 📍';
      case 'started': return 'Service in Progress ✅';
      case 'completed': return 'Service Completed 🎉';
      default: return 'Scheduled 📅';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Track Your Vendor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchStatus();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventHeader(),
                  const SizedBox(height: 20),
                  _buildStatusBanner(),
                  const SizedBox(height: 20),
                  if (_lastLat != null && _lastLng != null) ...[
                    _buildLocationCard(),
                    const SizedBox(height: 20),
                  ],
                  _buildTimeline(),
                  const SizedBox(height: 24),
                  if (_currentStatus == 'completed') _buildCompletedCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildEventHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.serviceName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.business, size: 15, color: Colors.grey),
            const SizedBox(width: 6),
            Text(widget.vendorName, style: const TextStyle(color: Colors.grey)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.calendar_today, size: 15, color: Colors.grey),
            const SizedBox(width: 6),
            Text(DateFormat('EEEE, d MMMM yyyy').format(widget.eventDate),
                style: const TextStyle(color: Colors.grey)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.location_on, size: 15, color: Colors.grey),
            const SizedBox(width: 6),
            Expanded(child: Text(widget.eventLocation, style: const TextStyle(color: Colors.grey))),
          ]),
          if (_lastUpdated != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('Updated ${_timeSince(_lastUpdated!)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _statusColor(),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            _statusLabel(),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          if (_currentStatus == 'on_the_way')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Your vendor is heading to the venue!',
                  style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return GestureDetector(
      onTap: _openInMaps,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.shade100),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: Icon(Icons.my_location, color: Colors.blue.shade600),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vendor Location Shared', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'Lat: ${_lastLat!.toStringAsFixed(5)}, Lng: ${_lastLng!.toStringAsFixed(5)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Status Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildStep('Scheduled', Icons.schedule, 'scheduled'),
          _buildStep('On The Way', Icons.directions_car, 'on_the_way'),
          _buildStep('Arrived at Venue', Icons.location_on, 'arrived'),
          _buildStep('Service Started', Icons.play_arrow, 'started'),
          _buildStep('Completed', Icons.check_circle, 'completed', isLast: true),
        ],
      ),
    );
  }

  Widget _buildStep(String label, IconData icon, String stepId, {bool isLast = false}) {
    final isActive = _hasReached(stepId);
    final isCurrent = _currentStatus == stepId;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? (isCurrent ? _statusColor() : AppTheme.primaryColor) : Colors.grey.shade100,
                shape: BoxShape.circle,
                boxShadow: isCurrent
                    ? [BoxShadow(color: _statusColor().withOpacity(0.4), blurRadius: 8, spreadRadius: 2)]
                    : [],
              ),
              child: Icon(icon, color: isActive ? Colors.white : Colors.grey.shade400, size: 20),
            ),
            if (!isLast)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 2,
                height: 40,
                color: isActive ? AppTheme.primaryColor : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppTheme.textPrimaryColor : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified, color: Colors.green, size: 40),
          const SizedBox(height: 12),
          const Text('Service Complete!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 8),
          const Text('We hope everything went perfectly. Please take a moment to leave a review.',
              style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to review screen
              Navigator.pop(context);
            },
            icon: const Icon(Icons.star, color: Colors.white),
            label: const Text('Leave a Review', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
}
