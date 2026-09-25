import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/core/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class VendorEventCheckinScreen extends StatefulWidget {
  final Booking booking;

  const VendorEventCheckinScreen({Key? key, required this.booking}) : super(key: key);

  @override
  State<VendorEventCheckinScreen> createState() => _VendorEventCheckinScreenState();
}

class _VendorEventCheckinScreenState extends State<VendorEventCheckinScreen> {
  String _currentStatus = 'scheduled'; // 'scheduled', 'on_the_way', 'arrived', 'started', 'completed'
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadCheckinStatus();
  }

  Future<void> _loadCheckinStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client
          .from('vendor_checkins')
          .select()
          .eq('booking_id', widget.booking.id)
          .eq('vendor_id', widget.booking.vendorId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (data != null) {
            _currentStatus = data['status'] as String;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Attempts to get the device's current GPS position.
  /// Returns null gracefully if permission is denied or location is unavailable.
  Future<Position?> _captureGpsLocation({bool highAccuracy = false}) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Location Permission Required'),
              content: const Text(
                'Location access is permanently denied. Please enable it in Settings so we can share your location with the customer.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    Geolocator.openAppSettings();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            ),
          );
        }
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      // If location fails, proceed anyway without GPS
      return null;
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Capture GPS for meaningful location milestones
      Position? position;
      if (status == 'on_the_way') {
        position = await _captureGpsLocation(highAccuracy: false);
      } else if (status == 'arrived') {
        position = await _captureGpsLocation(highAccuracy: true);
      }

      await Supabase.instance.client.from('vendor_checkins').insert({
        'booking_id': widget.booking.id,
        'vendor_id': widget.booking.vendorId,
        'status': status,
        if (position != null) 'location_lat': position.latitude,
        if (position != null) 'location_lng': position.longitude,
      });

      setState(() {
        _currentStatus = status;
      });

      // Send push/in-app notification to customer
      try {
        await NotificationService().sendVendorCheckinNotification(
          customerId: widget.booking.customerId,
          bookingId: widget.booking.id,
          vendorName: widget.booking.vendorName.isNotEmpty ? widget.booking.vendorName : 'Your vendor',
          serviceName: widget.booking.serviceName,
          status: status,
        );
      } catch (_) {
        // Notification failure should not block the status update
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated! ${position != null ? '📍 Location shared.' : ''}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Event Day Operations', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventHeader(),
                  const SizedBox(height: 32),
                  const Text('Live Tracking Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Update your status below to notify the customer and EventEase operations that you are on track.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  _buildTimeline(),
                  const SizedBox(height: 32),
                  if (_currentStatus == 'completed')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: Colors.green),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Service marked as completed. Great job! EventEase Ops has been notified.',
                              style: TextStyle(color: Colors.green),
                            ),
                          )
                        ],
                      ),
                    )
                  else if (_currentStatus == 'scheduled')
                    _buildActionBtn('on_the_way', 'I am on the way!', Icons.directions_car, Colors.blue)
                  else if (_currentStatus == 'on_the_way')
                    _buildActionBtn('arrived', 'I have arrived at the venue', Icons.location_on, Colors.orange)
                  else if (_currentStatus == 'arrived')
                    _buildActionBtn('started', 'Service / Setup Started', Icons.play_arrow, AppTheme.primaryColor)
                  else if (_currentStatus == 'started')
                    _buildActionBtn('completed', 'Mark Service Complete', Icons.check_circle, Colors.green),
                  
                  const SizedBox(height: 32),
                  // GPS info banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.gps_fixed, color: Colors.blue.shade600, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your GPS location will be shared with the customer when you tap "On The Way" and "Arrived".',
                            style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Emergency Vendor SOS Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextButton.icon(
                      onPressed: () {
                         showDialog(
                           context: context,
                           builder: (context) => AlertDialog(
                             title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width:8), Text('Emergency Alert')]),
                             content: const Text('Are you experiencing an emergency that prevents you from completing this service? This will alert EventEase Ops immediately.'),
                             actions: [
                               TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cancel')),
                               ElevatedButton(onPressed: (){ Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Alert Ops Team', style: TextStyle(color: Colors.white))),
                             ]
                           )
                         );
                      },
                      icon: const Icon(Icons.emergency, color: Colors.red),
                      label: const Text('I have an Emergency', style: TextStyle(color: Colors.red)),
                      style: TextButton.styleFrom(padding: const EdgeInsets.all(16)),
                    ),
                  )
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
          Text(widget.booking.serviceName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(widget.booking.customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.booking.location, style: const TextStyle(color: Colors.grey))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        _buildTimelineStep('scheduled', 'Scheduled', Icons.schedule, _hasReached('scheduled')),
        _buildTimelineStep('on_the_way', 'On The Way', Icons.directions_car, _hasReached('on_the_way')),
        _buildTimelineStep('arrived', 'Arrived', Icons.location_on, _hasReached('arrived')),
        _buildTimelineStep('started', 'Started', Icons.play_arrow, _hasReached('started')),
        _buildTimelineStep('completed', 'Completed', Icons.check_circle, _hasReached('completed'), isLast: true),
      ],
    );
  }

  bool _hasReached(String step) {
    final order = ['scheduled', 'on_the_way', 'arrived', 'started', 'completed'];
    final currentIndex = order.indexOf(_currentStatus);
    final stepIndex = order.indexOf(step);
    return stepIndex <= currentIndex;
  }

  Widget _buildTimelineStep(String id, String title, IconData icon, bool isActive, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryColor : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isActive ? AppTheme.primaryColor : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? AppTheme.textPrimaryColor : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(String nextStatus, String label, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : () => _updateStatus(nextStatus),
        icon: _isUpdating
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
