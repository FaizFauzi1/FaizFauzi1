import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/booking/presentation/views/booking/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/shared/models/services/service_time_rule.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingScreen extends StatefulWidget {
  final Vendor vendor;
  final String? serviceId;
  final String? eventId;
  final VendorService? service; // Added service parameter
  
  const BookingScreen({
    super.key,
    required this.vendor,
    this.serviceId,
    this.eventId,
    this.service,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}



class _BookingScreenState extends State<BookingScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  
  // Booking data
  String _selectedService = '';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  DateTime _focusedDay = DateTime.now().add(const Duration(days: 1)); // Added for TableCalendar
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String _selectedDuration = '1 hour';
  String _location = '';
  String _notes = '';
  String _customerName = '';
  String _customerPhone = '';
  String _customerEmail = '';
  
  Set<DateTime> _unavailableDates = {};
  bool _useWhitelist = false;
  Set<DateTime> _whitelistDates = {};
  
  final List<String> _durations = [
    '30 minutes',
    '1 hour',
    '1.5 hours',
    '2 hours',
    '3 hours',
    '4 hours',
    'Full day',
  ];

  List<Map<String, dynamic>> _availableServices = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _parseAvailability();
  }

  void _initializeServices() {
    if (widget.service != null) {
      _availableServices = [{
        'id': widget.service!.id,
        'name': widget.service!.name,
        'price': widget.service!.basePrice,
        'description': widget.service!.description,
        'duration': widget.service!.options['duration'] != null 
            ? '${widget.service!.options['duration']} ${widget.service!.options['durationUnit'] ?? ''}' 
            : 'Custom',
      }];
      _selectedService = widget.service!.id;
    } else {
      // Fallback or fetch from vendor if needed (keeping existing behavior logic as placeholder)
       _availableServices = [
        {
          'id': '1',
          'name': 'Wedding Package A',
          'price': 8500.0,
          'description': 'Complete wedding catering package with 5-course meal',
          'duration': 'Full day',
        },
      ];
      if (widget.serviceId != null) {
         _selectedService = widget.serviceId!;
      } else if (_availableServices.isNotEmpty) {
        _selectedService = _availableServices.first['id'];
      }
    }
  }

  void _parseAvailability() {
    if (widget.service != null && widget.service!.availability.isNotEmpty) {
       final availability = widget.service!.availability;
       
       if (availability['type'] == 'whitelist') {
         _useWhitelist = true;
         if (availability['availableDates'] is List) {
           for (var d in availability['availableDates']) {
             try { _whitelistDates.add(DateTime.parse(d)); } catch (_) {}
           }
         }
       } else {
         // Blacklist mode
         if (availability['unavailableDates'] is List) {
           for (var d in availability['unavailableDates']) {
             try { _unavailableDates.add(DateTime.parse(d)); } catch (_) {}
           }
         }
         // Also check blockedDates
         if (availability['blockedDates'] is List) {
           for (var d in availability['blockedDates']) {
             try { _unavailableDates.add(DateTime.parse(d)); } catch (_) {}
           }
         }
       }
    }
  }

  bool _isDateSelectable(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    if (normalized.isBefore(DateTime.now())) return false;
    
    if (_useWhitelist) {
      return _whitelistDates.any((d) => 
        d.year == normalized.year && 
        d.month == normalized.month && 
        d.day == normalized.day
      );
    } else {
      return !_unavailableDates.any((d) => 
        d.year == normalized.year && 
        d.month == normalized.month && 
        d.day == normalized.day
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Book Service',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildServiceSelectionStep(),
                _buildDateTimeSelectionStep(),
                _buildDetailsStep(),
                _buildCustomerInfoStep(),
                _buildReviewStep(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(5, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: isCompleted 
                    ? AppTheme.primaryColor 
                    : isActive 
                        ? AppTheme.primaryColor.withOpacity(0.3)
                        : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildServiceSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Service dulu',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from ${widget.vendor.name}\'s available services',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          ..._availableServices.map((service) => _buildServiceCard(service)).toList(),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final isSelected = _selectedService == service['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedService = service['id'];
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            ),
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.business_center,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service['description'],
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'RM ${service['price'].toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          service['duration'],
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Date & Time',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose when you\'d like to book this service',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          _buildDateSelector(),
          const SizedBox(height: 24),
          _buildTimeSelector(),
          const SizedBox(height: 24),
          _buildDurationSelector(),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                currentDay: DateTime.now(),
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                enabledDayPredicate: _isDateSelectable,
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month',
                },
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDate, selectedDay)) {
                    setState(() {
                      _selectedDate = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (!_isDateSelectable(day)) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  disabledBuilder: (context, day, focusedDay) {
                     // Style for disabled/blocked dates
                     return Center(
                        child: Container(
                          margin: const EdgeInsets.all(6.0),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(color: Colors.red.shade300),
                            ),
                          ),
                        ),
                      );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.circle, size: 12, color: Colors.red),
                     SizedBox(width: 4),
                     Text('Unavailable', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic>? _selectedSessionSlot;

  Widget _buildTimeSelector() {
    final timeSlots = widget.service?.availability['timeSlots'] as List?;
    
    // If the vendor has configured specific named time slots/sessions
    if (timeSlots != null && timeSlots.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Session',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...timeSlots.map((slot) {
            final isSelected = _selectedSessionSlot == slot;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSessionSlot = slot;
                  // Auto set time if needed
                  if (slot['start'] != null) {
                    final parts = slot['start'].toString().split(':');
                    if (parts.length >= 2) {
                      _selectedTime = TimeOfDay(
                        hour: int.tryParse(parts[0]) ?? 9,
                        minute: int.tryParse(parts[1]) ?? 0,
                      );
                    }
                  }
                  // Set duration if needed based on start/end
                  _selectedDuration = slot['name'] ?? 'Custom Session';
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot['name'] ?? 'Session',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                            ),
                          ),
                          Text(
                            "${slot['start']} - ${slot['end']}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (slot['price'] != null)
                      Text(
                        "RM ${slot['price']}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      );
    }

    // Fallback to dynamic hourly slot generation
    final List<TimeOfDay> slots = [];
    final timeRule = widget.service?.timeRule;

    if (timeRule != null && (timeRule.timeType == TimeType.fixedSlot || timeRule.timeType == TimeType.fullDay)) {
      final duration = timeRule.slotDurationMinutes ?? 60;
      int startHour = 9;
      int startMinute = 0;
      int endHour = 17;
      int endMinute = 0;

      if (timeRule.startTime != null && timeRule.startTime!.isNotEmpty) {
        final parts = timeRule.startTime!.split(':');
        if (parts.length >= 2) {
          startHour = int.tryParse(parts[0]) ?? 9;
          startMinute = int.tryParse(parts[1]) ?? 0;
        }
      }
      if (timeRule.endTime != null && timeRule.endTime!.isNotEmpty) {
        final parts = timeRule.endTime!.split(':');
        if (parts.length >= 2) {
          endHour = int.tryParse(parts[0]) ?? 17;
          endMinute = int.tryParse(parts[1]) ?? 0;
        }
      }

      int currentTotalMinutes = startHour * 60 + startMinute;
      final endTotalMinutes = endHour * 60 + endMinute;

      while (currentTotalMinutes + duration <= endTotalMinutes) {
        slots.add(TimeOfDay(
          hour: currentTotalMinutes ~/ 60,
          minute: currentTotalMinutes % 60,
        ));
        currentTotalMinutes += duration;
      }
    } else {
      // Default fallback
      for (int i = 9; i <= 17; i++) {
        slots.add(TimeOfDay(hour: i, minute: 0));
        if (i < 17) slots.add(TimeOfDay(hour: i, minute: 30));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Time Slots',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: slots.map((time) {
            final isSelected = _selectedTime.hour == time.hour && _selectedTime.minute == time.minute;
            return ChoiceChip(
              label: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  time.format(context),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                ),
              ),
              elevation: isSelected ? 2 : 0,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Custom time fallback
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) {
                  setState(() {
                    _selectedTime = time;
                  });
                }
              },
              icon: const Icon(Icons.access_time, size: 18),
              label: const Text('Pick Custom Time'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedDuration,
            decoration: const InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(Icons.schedule),
            ),
            items: _durations.map((duration) {
              return DropdownMenuItem(
                value: duration,
                child: Text(duration),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDuration = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Provide any additional information for your booking',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField('Location', _location, Icons.location_on, 'Where should the service be provided?'),
          const SizedBox(height: 20),
          _buildTextField('Notes', _notes, Icons.note, 'Any special requirements or notes?', maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please provide your contact details for the booking',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField('Full Name', _customerName, Icons.person, 'Enter your full name'),
          const SizedBox(height: 20),
          _buildTextField('Phone Number', _customerPhone, Icons.phone, 'Enter your phone number'),
          const SizedBox(height: 20),
          _buildTextField('Email Address', _customerEmail, Icons.email, 'Enter your email address'),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final selectedService = _availableServices.firstWhere((s) => s['id'] == _selectedService);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Booking',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please review your booking details before confirming',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          _buildReviewSection('Service Details', [
            'Service: ${selectedService['name']}',
            'Price: RM ${(_selectedSessionSlot != null && _selectedSessionSlot!['price'] != null) ? double.parse(_selectedSessionSlot!['price'].toString()).toStringAsFixed(0) : selectedService['price'].toStringAsFixed(0)}',
            'Duration: ${_selectedSessionSlot != null ? _selectedSessionSlot!['name'] : selectedService['duration']}',
          ]),
          const SizedBox(height: 20),
          _buildReviewSection('Date & Time', [
            'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            'Time: ${_selectedTime.format(context)}',
            'Duration: $_selectedDuration',
          ]),
          const SizedBox(height: 20),
          _buildReviewSection('Location & Notes', [
            'Location: ${_location.isNotEmpty ? _location : 'Not specified'}',
            'Notes: ${_notes.isNotEmpty ? _notes : 'None'}',
          ]),
          const SizedBox(height: 20),
          _buildReviewSection('Contact Information', [
            'Name: $_customerName',
            'Phone: $_customerPhone',
            'Email: $_customerEmail',
          ]),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You will receive a confirmation email once your booking is confirmed by the vendor.',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value, IconData icon, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (text) {
            setState(() {
              switch (label) {
                case 'Location':
                  _location = text;
                  break;
                case 'Notes':
                  _notes = text;
                  break;
                case 'Full Name':
                  _customerName = text;
                  break;
                case 'Phone Number':
                  _customerPhone = text;
                  break;
                case 'Email Address':
                  _customerEmail = text;
                  break;
              }
            });
          },
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection(String title, List<String> items) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '• $item',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _canProceed() ? _nextStep : null,
              child: Text(_currentStep == 4 ? 'Confirm Booking' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedService.isNotEmpty;
      case 1:
        return true; // Date/time always valid
      case 2:
        return true; // Details optional
      case 3:
        return _customerName.isNotEmpty && _customerPhone.isNotEmpty && _customerEmail.isNotEmpty;
      case 4:
        return true; // Always can confirm on review step
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _confirmBooking();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _confirmBooking() {
    // Navigate to payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          vendor: widget.vendor,
          serviceId: _selectedService,
          eventId: widget.eventId,
          amount: (_selectedSessionSlot != null && _selectedSessionSlot!['price'] != null) 
              ? double.parse(_selectedSessionSlot!['price'].toString()) 
              : _availableServices.firstWhere((s) => s['id'] == _selectedService)['price'],
          bookingDetails: {
            'service': _availableServices.firstWhere((s) => s['id'] == _selectedService)['name'],
            'date': _selectedDate,
            'time': _selectedTime,
            'duration': _selectedDuration,
            'location': _location,
            'notes': _notes,
            'customerName': _customerName,
            'customerPhone': _customerPhone,
            'customerEmail': _customerEmail,
          },
        ),
      ),
    );
  }
}
