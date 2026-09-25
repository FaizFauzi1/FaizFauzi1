import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/features/vendor/presentation/widgets/calendar_availability_widget.dart';

class VendorServiceAvailabilityScreen extends StatefulWidget {
  final VendorServiceEnhanced service;

  const VendorServiceAvailabilityScreen({super.key, required this.service});

  @override
  State<VendorServiceAvailabilityScreen> createState() => _VendorServiceAvailabilityScreenState();
}

class _VendorServiceAvailabilityScreenState extends State<VendorServiceAvailabilityScreen> {
  late Set<DateTime> _availableDates;
  late Set<DateTime> _unavailableDates;
  bool _useWhitelist = false;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _parseAvailability();
  }

  void _parseAvailability() {
    final availability = widget.service.availability;
    _availableDates = {};
    _unavailableDates = {};

    if (availability.isNotEmpty) {
      if (availability['type'] == 'whitelist') {
        _useWhitelist = true;
      } else {
        _useWhitelist = false;
      }

      if (availability['availableDates'] is List) {
        for (var dateStr in availability['availableDates']) {
          try {
            _availableDates.add(DateTime.parse(dateStr));
          } catch (_) {}
        }
      }

      if (availability['unavailableDates'] is List) {
        for (var dateStr in availability['unavailableDates']) {
          try {
            _unavailableDates.add(DateTime.parse(dateStr));
          } catch (_) {}
        }
      }
      
      // Also check for 'blockedDates' as consistent with other parts of the app
      if (availability['blockedDates'] is List) {
         for (var dateStr in availability['blockedDates']) {
          try {
            _unavailableDates.add(DateTime.parse(dateStr));
          } catch (_) {}
        }
      }
    }
  }

  Future<void> _saveAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      
      // Construct new availability map
      final Map<String, dynamic> newAvailability = {
        'type': _useWhitelist ? 'whitelist' : 'blacklist',
        'availableDates': _availableDates.map((d) => d.toIso8601String()).toList(),
        'unavailableDates': _unavailableDates.map((d) => d.toIso8601String()).toList(),
        'blockedDates': _unavailableDates.map((d) => d.toIso8601String()).toList(),
      };

      // Create enhanced copy with updated availability
      final enhancedService = widget.service.copyWith(
        availability: newAvailability,
      );

      await vendorProvider.updateCustomService(widget.service.id, enhancedService);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating availability: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Edit Availability: ${widget.service.name}'),
        actions: [
          TextButton(
            onPressed: (_hasChanges && !_isLoading) ? _saveAvailability : null,
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
              : Text('Save', style: TextStyle(
                  color: _hasChanges ? AppTheme.primaryColor : Colors.grey,
                  fontWeight: FontWeight.bold
                )),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CalendarAvailabilityWidget(
                initialAvailableDates: _availableDates,
                initialUnavailableDates: _unavailableDates,
                useWhitelist: _useWhitelist,
                onChanged: (available, unavailable, useWhitelist) {
                  _availableDates = available;
                  _unavailableDates = unavailable;
                  _useWhitelist = useWhitelist;
                  setState(() {
                    _hasChanges = true;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
