import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:eventease/shared/presentation/views/rescue_room_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventCommandCenterScreen extends StatefulWidget {
  const EventCommandCenterScreen({Key? key}) : super(key: key);

  @override
  State<EventCommandCenterScreen> createState() => _EventCommandCenterScreenState();
}

class _EventCommandCenterScreenState extends State<EventCommandCenterScreen> {
  final List<Map<String, dynamic>> _liveEvents = [];
  final List<Map<String, dynamic>> _activeIncidents = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadCommandCenterData();
  }

  Future<void> _loadCommandCenterData() async {
    try {
      final client = Supabase.instance.client;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final responses = await Future.wait([
        client
            .from('bookings')
            .select('*, vendor:vendor_profiles(business_name), service:vendor_services(name, category)')
            .gte('booking_date', today)
            .neq('status', 'cancelled')
            .order('booking_date')
            .order('booking_time'),
        client
            .from('event_incidents')
            .select('*, vendor:vendor_profiles(business_name), booking:bookings(booking_date, booking_time, notes)')
            .inFilter('status', ['open', 'investigating', 'searching_backup', 'backup_found'])
            .order('created_at', ascending: false),
      ]);

      final bookings = (responses[0] as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final bookingIds = bookings
          .map((booking) => booking['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      final checkins = bookingIds.isEmpty
          ? <Map<String, dynamic>>[]
          : (await client
                  .from('vendor_checkins')
                  .select('booking_id, vendor_id, status, created_at')
                  .inFilter('booking_id', bookingIds)
                  .order('created_at', ascending: false) as List)
              .map((row) => Map<String, dynamic>.from(row as Map))
              .toList();
      final latestCheckinByBooking = <String, Map<String, dynamic>>{};
      for (final checkin in checkins) {
        latestCheckinByBooking.putIfAbsent(
          checkin['booking_id'].toString(),
          () => checkin,
        );
      }

      final incidents = (responses[1] as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
      final activeIncidents = incidents.map((incident) {
        final booking = _asMap(incident['booking']);
        final vendor = _asMap(incident['vendor']);
        final bookingId = incident['booking_id']?.toString() ?? '';
        final createdAt = DateTime.tryParse(
              incident['created_at']?.toString() ?? '',
            ) ??
            DateTime.now();

        return {
          'ticket': incident['id']?.toString() ?? '',
          'bookingId': bookingId,
          'event': booking['event_name'] ??
              booking['package_name'] ??
              'Booking $bookingId',
          'vendor': vendor['business_name'] ??
              incident['vendor_id']?.toString() ??
              '',
          'issue': (incident['incident_type']?.toString() ?? 'incident')
              .replaceAll('_', ' '),
          'status': incident['status']?.toString() ?? '',
          'time_elapsed': _elapsedTime(createdAt),
          'priority': incident['priority']?.toString() ?? '',
        };
      }).toList();

      final events = <Map<String, dynamic>>[];
      for (final booking in bookings) {
        final id = booking['id']?.toString() ?? '';
        final dateValue = booking['event_date'] ?? booking['booking_date'];
        if (dateValue == null) continue;

        final dateText = dateValue.toString();
        final timeText = booking['booking_time']?.toString() ?? '00:00:00';
        final eventDate = DateTime.tryParse('${dateText}T$timeText') ??
            DateTime.tryParse(dateText);
        if (eventDate == null) continue;

        final service = _asMap(booking['service']);
        final vendor = _asMap(booking['vendor']);
        final checkin = latestCheckinByBooking[id];
        final status = checkin?['status']?.toString() ?? 'scheduled';
        final hasIncident = activeIncidents.any(
          (incident) => incident['bookingId'] == id,
        );

        events.add({
          'id': id,
          'title': booking['event_name'] ??
              booking['package_name'] ??
              service['name'] ??
              'Booking $id',
          'date': eventDate,
          'priority': hasIncident ? 'critical' : 'medium',
          'services': [
            {
              'type': service['category'] ?? service['name'] ?? 'Service',
              'vendor': vendor['business_name'] ?? '',
              'status': status,
            }
          ],
        });
      }

      if (!mounted) return;
      setState(() {
        _liveEvents
          ..clear()
          ..addAll(events);
        _activeIncidents
          ..clear()
          ..addAll(activeIncidents);
        _loadError = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty) return _asMap(value.first);
    return {};
  }

  String _elapsedTime(DateTime createdAt) {
    final minutes = DateTime.now().difference(createdAt).inMinutes;
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60} hr ${minutes % 60} min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ops Command Center', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black87,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_activeIncidents.length} Active Alerts',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKPIHeader(),
              if (_loadError != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Could not refresh command-center data: $_loadError',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildLiveEventsRadar(),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: _buildIncidentPanel(),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPIHeader() {
    final now = DateTime.now();
    final eventsToday = _liveEvents.where((event) {
      final date = event['date'] as DateTime;
      return DateUtils.isSameDay(date, now);
    }).length;
    var vendorsDispatched = 0;
    var successfulCheckins = 0;
    for (final event in _liveEvents) {
      final services = event['services'] as List;
      vendorsDispatched += services.length;
      successfulCheckins += services.where((service) {
        return const {'arrived', 'started', 'completed'}
            .contains((service as Map)['status']);
      }).length;
    }

    return Row(
      children: [
        _buildKPIBox('Events Today', '$eventsToday', Icons.event),
        const SizedBox(width: 16),
        _buildKPIBox('Vendors Dispatched', '$vendorsDispatched', Icons.local_shipping),
        const SizedBox(width: 16),
        _buildKPIBox('Successful Check-ins', '$successfulCheckins', Icons.check_circle, color: Colors.green),
        const SizedBox(width: 16),
        _buildKPIBox('Active Rescues', '${_activeIncidents.length}', Icons.emergency, color: Colors.redAccent),
      ],
    );
  }

  Widget _buildKPIBox(String title, String value, IconData icon, {Color color = AppTheme.primaryColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                Icon(icon, color: color.withOpacity(0.8)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveEventsRadar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Events Radar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text('Tracking vendor check-ins for upcoming events.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          if (_isLoading) const LinearProgressIndicator(),
          if (!_isLoading && _liveEvents.isEmpty)
            const Text('No upcoming bookings found.'),
          ..._liveEvents.map((event) => _buildEventCard(event)).toList(),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final bool isCritical = event['priority'] == 'critical';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: isCritical ? Colors.red.shade200 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        color: isCritical ? Colors.red.shade50 : Colors.white,
      ),
      child: Column(
        children: [
          // Event Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCritical ? Colors.red.shade100 : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.event, color: isCritical ? Colors.red.shade700 : AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      event['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  'Starts: ${DateFormat('h:mm a').format(event['date'])}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCritical ? Colors.red.shade700 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Vendor Status List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: (event['services'] as List).map((service) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      _getStatusIcon(service['status']),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(service['type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(service['vendor'], style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(service['status']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(service['status']),
                          style: TextStyle(
                            color: _getStatusTextColor(service['status']),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIncidentPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emergency, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Active Rescues', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (!_isLoading && _activeIncidents.isEmpty)
            const Text(
              'No active rescues',
              style: TextStyle(color: Colors.white70),
            ),
          ..._activeIncidents.map((incident) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(incident['ticket'], style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    Text(incident['time_elapsed'], style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(incident['event'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(incident['vendor'], style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(incident['issue'], style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RescueRoomScreen(
                            incidentId: incident['ticket'],
                            bookingTitle: incident['event'],
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Enter Rescue Room'),
                  ),
                )
              ],
            ),
          )).toList()
        ],
      ),
    );
  }

  // Helpers
  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'arrived':
      case 'started':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'on_the_way':
        return const Icon(Icons.local_shipping, color: Colors.blue);
      case 'no_show_suspected':
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const Icon(Icons.schedule, color: Colors.grey);
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'arrived':
      case 'started':
        return Colors.green.shade50;
      case 'on_the_way':
        return Colors.blue.shade50;
      case 'no_show_suspected':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'arrived':
      case 'started':
        return Colors.green.shade700;
      case 'on_the_way':
        return Colors.blue.shade700;
      case 'no_show_suspected':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'arrived': return 'Checked In';
      case 'started': return 'Service Started';
      case 'on_the_way': return 'On The Way';
      case 'no_show_suspected': return 'Unreachable - Flagged';
      default: return 'Scheduled';
    }
  }
}
