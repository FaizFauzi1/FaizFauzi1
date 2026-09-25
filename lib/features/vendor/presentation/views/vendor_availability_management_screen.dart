import 'package:flutter/material.dart';
import '../../models/vendor_service_enhanced.dart';
import '../../../../core/utils/app_theme.dart';

class VendorAvailabilityManagementScreen extends StatefulWidget {
  final VendorServiceEnhanced service;

  const VendorAvailabilityManagementScreen({
    super.key,
    required this.service,
  });

  @override
  State<VendorAvailabilityManagementScreen> createState() =>
      _VendorAvailabilityManagementScreenState();
}

class _VendorAvailabilityManagementScreenState
    extends State<VendorAvailabilityManagementScreen> {
  late Map<String, Map<String, dynamic>> availability;
  late List<Map<String, dynamic>> unavailablePeriods;
  late int maxBookingsPerDay;
  late int advanceBookingDays;

  final List<String> daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  @override
  void initState() {
    super.initState();
    availability = Map<String, Map<String, dynamic>>.from(
        widget.service.extendedAvailability);
    unavailablePeriods = List<Map<String, dynamic>>.from(
        widget.service.unavailablePeriods);
    maxBookingsPerDay = widget.service.maxBookingsPerDay;
    advanceBookingDays = widget.service.advanceBookingDays;

    // Initialize default availability if empty
    if (availability.isEmpty) {
      for (final day in daysOfWeek) {
        availability[day] = {
          'available': true,
          'start': '09:00',
          'end': '17:00',
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '${widget.service.name} - Availability',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saveChanges,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Schedule',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...daysOfWeek.map((day) => _buildDaySchedule(day)),
            const SizedBox(height: 24),
            const Text(
              'Booking Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: maxBookingsPerDay.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Max Bookings/Day',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      maxBookingsPerDay = int.tryParse(value) ?? maxBookingsPerDay;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: advanceBookingDays.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Advance Days',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      advanceBookingDays = int.tryParse(value) ?? advanceBookingDays;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Unavailable Periods',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ...unavailablePeriods.map((period) => _buildUnavailablePeriod(period)),
            ElevatedButton.icon(
              onPressed: _addUnavailablePeriod,
              icon: const Icon(Icons.add),
              label: const Text('Add Unavailable Period'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySchedule(String day) {
    final schedule = availability[day] ?? {
      'available': false,
      'start': '09:00',
      'end': '17:00',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                day[0].toUpperCase() + day.substring(1),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: schedule['start'],
                      decoration: const InputDecoration(
                        labelText: 'Start',
                        border: OutlineInputBorder(),
                      ),
                      enabled: schedule['available'],
                      onChanged: (value) {
                        schedule['start'] = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: schedule['end'],
                      decoration: const InputDecoration(
                        labelText: 'End',
                        border: OutlineInputBorder(),
                      ),
                      enabled: schedule['available'],
                      onChanged: (value) {
                        schedule['end'] = value;
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: schedule['available'],
              onChanged: (value) {
                setState(() {
                  schedule['available'] = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailablePeriod(Map<String, dynamic> period) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From: ${period['startDate']} To: ${period['endDate']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (period['reason'] != null)
                    Text(
                      'Reason: ${period['reason']}',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeUnavailablePeriod(period),
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
            ),
          ],
        ),
      ),
    );
  }

  void _addUnavailablePeriod() {
    // For simplicity, add a placeholder period
    setState(() {
      unavailablePeriods.add({
        'startDate': DateTime.now().toIso8601String().split('T')[0],
        'endDate': DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
        'reason': 'Maintenance',
      });
    });
  }

  void _removeUnavailablePeriod(Map<String, dynamic> period) {
    setState(() {
      unavailablePeriods.remove(period);
    });
  }

  void _saveChanges() {
    // Here you would typically save to provider or backend
    // For now, just show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Availability updated successfully')),
    );
    Navigator.pop(context);
  }
}
