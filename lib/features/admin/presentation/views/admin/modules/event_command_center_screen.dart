import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:eventease/shared/presentation/views/rescue_room_screen.dart';

class EventCommandCenterScreen extends StatefulWidget {
  const EventCommandCenterScreen({Key? key}) : super(key: key);

  @override
  State<EventCommandCenterScreen> createState() => _EventCommandCenterScreenState();
}

class _EventCommandCenterScreenState extends State<EventCommandCenterScreen> {
  // Temporary mock data to demonstrate the UI
  final List<Map<String, dynamic>> _liveEvents = [
    {
      'id': 'E-1024',
      'title': 'Sarah & John Wedding',
      'date': DateTime.now().add(const Duration(minutes: 45)),
      'location': 'Grand Ballroom, KL',
      'priority': 'critical',
      'services': [
        {'type': 'Photographer', 'vendor': 'LensArt Studio', 'status': 'on_the_way', 'eta': '15 mins'},
        {'type': 'Caterer', 'vendor': 'Royal Eats', 'status': 'arrived', 'eta': 'On Site'},
        {'type': 'Makeup Artist', 'vendor': 'GlamByJane', 'status': 'no_show_suspected', 'eta': 'Overdue by 30m'},
      ]
    },
    {
      'id': 'E-1025',
      'title': 'Tech Corp Annual Dinner',
      'date': DateTime.now().add(const Duration(hours: 3)),
      'location': 'Convention Center, PJ',
      'priority': 'medium',
      'services': [
        {'type': 'Emcee', 'vendor': 'HostMaster', 'status': 'scheduled', 'eta': '1 hr'},
        {'type': 'Audio/Visual', 'vendor': 'SoundBlast', 'status': 'started', 'eta': 'Running'}
      ]
    }
  ];

  final List<Map<String, dynamic>> _activeIncidents = [
    {
      'ticket': '#INC-889',
      'event': 'Sarah & John Wedding',
      'vendor': 'GlamByJane (Makeup)',
      'issue': 'Vendor No-Show',
      'status': 'searching_backup',
      'time_elapsed': '12 mins',
      'priority': 'high'
    }
  ];

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
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text('1 Active Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    return Row(
      children: [
        _buildKPIBox('Events Today', '14', Icons.event),
        const SizedBox(width: 16),
        _buildKPIBox('Vendors Dispatched', '42', Icons.local_shipping),
        const SizedBox(width: 16),
        _buildKPIBox('Successful Check-ins', '39', Icons.check_circle, color: Colors.green),
        const SizedBox(width: 16),
        _buildKPIBox('Active Rescues', '1', Icons.emergency, color: Colors.redAccent),
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
