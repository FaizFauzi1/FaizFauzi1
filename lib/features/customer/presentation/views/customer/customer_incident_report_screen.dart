import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/shared/presentation/views/rescue_room_screen.dart';

class CustomerIncidentReportScreen extends StatefulWidget {
  final Booking booking;

  const CustomerIncidentReportScreen({Key? key, required this.booking})
      : super(key: key);

  @override
  State<CustomerIncidentReportScreen> createState() =>
      _CustomerIncidentReportScreenState();
}

class _CustomerIncidentReportScreenState
    extends State<CustomerIncidentReportScreen> {
  String? _selectedIncidentType;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _incidentTypes = [
    {
      'id': 'vendor_no_show',
      'title': 'Vendor No-Show',
      'desc': 'Vendor did not arrive at the scheduled time.',
      'icon': Icons.person_off,
      'color': Colors.red,
    },
    {
      'id': 'vendor_late',
      'title': 'Vendor Very Late',
      'desc': 'Vendor is more than 30 minutes late.',
      'icon': Icons.watch_later,
      'color': Colors.orange,
    },
    {
      'id': 'equipment_failure',
      'title': 'Equipment Failure',
      'desc': 'Vendor arrived but equipment is broken/unusable.',
      'icon': Icons.build,
      'color': Colors.amber,
    },
    {
      'id': 'wrong_service',
      'title': 'Wrong Service Delivered',
      'desc': 'Service/items completely mismatch the booking.',
      'icon': Icons.warning,
      'color': Colors.deepOrange,
    },
    {
      'id': 'emergency',
      'title': 'Safety / Emergency Issue',
      'desc': 'Immediate danger or major venue issue.',
      'icon': Icons.local_hospital,
      'color': Colors.redAccent,
    },
  ];

  Future<void> _submitReport() async {
    if (_selectedIncidentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an incident type.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Determine priority
      String priority = 'medium';
      if (_selectedIncidentType == 'vendor_no_show' ||
          _selectedIncidentType == 'emergency') {
        priority = 'critical';
      } else if (_selectedIncidentType == 'vendor_late' ||
          _selectedIncidentType == 'equipment_failure') {
        priority = 'high';
      }

      await Supabase.instance.client.from('event_incidents').insert({
        'booking_id': widget.booking.id,
        'customer_id': user.id,
        'vendor_id': widget.booking.vendorId,
        'incident_type': _selectedIncidentType,
        'priority': priority,
        'description': _descriptionController.text.trim(),
        'status': 'open',
      });

      if (mounted) {
        Navigator.pop(context); // Go back to booking screen
        // Show success/rescue room dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.emergency, color: Colors.red),
                SizedBox(width: 8),
                Text('Rescue Initiated'),
              ],
            ),
            content: const Text(
                'Your emergency report has been sent directly to the EventEase Operations Team. We are opening a Rescue Room and will assist you immediately.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RescueRoomScreen(
                        incidentId: 'INC-NEW',
                        bookingTitle: widget.booking.packageName,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Enter Rescue Room', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting report: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Emergency Help', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.red),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use this only for critical event day emergencies. False reports may result in account penalties.',
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'What is the emergency?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._incidentTypes.map((type) => _buildIncidentTypeTile(type)).toList(),
            const SizedBox(height: 24),
            const Text(
              'Additional Details (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Provide any specific details to help our Ops Team...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Trigger Emergency Rescue',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentTypeTile(Map<String, dynamic> type) {
    final isSelected = _selectedIncidentType == type['id'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIncidentType = type['id'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? type['color'].withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? type['color'] : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: type['color'].withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(type['icon'], color: type['color']),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected ? type['color'] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type['desc'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: type['color']),
          ],
        ),
      ),
    );
  }
}
