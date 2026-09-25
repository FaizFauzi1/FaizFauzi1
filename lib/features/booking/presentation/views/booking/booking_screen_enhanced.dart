import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/shared/widgets/service_image_carousel.dart';
import 'package:eventease/shared/widgets/package_selection_widget.dart';
import 'package:eventease/shared/models/services/service_package.dart';
import 'package:eventease/shared/models/services/service_time_rule.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/data/models/installment_plan.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/shared/models/services/pricing_model.dart';
import 'package:eventease/core/services/admin_notification_service.dart';
import 'package:eventease/core/services/notification_service.dart';
import 'package:eventease/shared/models/event/event_type.dart';

class BookingScreenEnhanced extends StatefulWidget {
  final Vendor vendor;
  final String? serviceId;
  final String? eventId;
  final DateTime? initialDate;
  final DateTimeRange? initialDateRange;
  final String? initialEventType;
  final String? initialPackageId;
  final String? initialTierId;
  final int? initialPax;
  final Map<String, List<String>>? initialSelectedItems;

  const BookingScreenEnhanced({
    super.key,
    required this.vendor,
    this.serviceId,
    this.eventId,
    this.initialDate,
    this.initialDateRange,
    this.initialEventType,
    this.initialPackageId,
    this.initialTierId,
    this.initialPax,
    this.initialSelectedItems,
  });

  @override
  State<BookingScreenEnhanced> createState() => _BookingScreenEnhancedState();
}

class _BookingScreenEnhancedState extends State<BookingScreenEnhanced> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Booking data
  VendorService? _selectedService;
  String _selectedPackageId = '';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  DateTimeRange? _selectedDateRange;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String _selectedDuration = '1 hour';
  String _location = '';
  String _notes = '';
  String _customerName = '';
  String _customerPhone = '';
  String _customerEmail = '';
  int _guestCount = 1;
  String? _eventType;
  String? _selectedTierId; // Added for multi-tier pricing
  Map<String, List<String>> _selectedItemsByComponent = {}; // Added for package options

  // Durations list
  final List<String> _durations = ['30 minutes', '1 hour', '1.5 hours', '2 hours', '3 hours', '4 hours', 'Full day'];

  List<VendorService> _availableServices = [];
  bool _isLoading = true;

  Map<String, dynamic>? _selectedSessionSlot;
  
  @override
  void initState() {
    super.initState();
    _initializeInitialValues();
    _loadServices();
    _loadCustomerDetails();
  }

  void _initializeInitialValues() {
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    if (widget.initialDateRange != null) {
      _selectedDateRange = widget.initialDateRange;
      _selectedDate = widget.initialDateRange!.start;
    }
    if (widget.initialEventType != null) {
      _eventType = widget.initialEventType;
    }
    if (widget.initialPackageId != null) {
      _selectedPackageId = widget.initialPackageId!;
    }
    if (widget.initialPax != null) {
      _guestCount = widget.initialPax!;
    } else if (widget.serviceId != null) {
      // Default to first valid pax option if we have a service ID
      // This will be refined once services are loaded in _loadServices
    }

    if (widget.initialTierId != null) {
      _selectedTierId = widget.initialTierId;
    }
    if (widget.initialSelectedItems != null) {
      _selectedItemsByComponent = Map<String, List<String>>.from(widget.initialSelectedItems!);
    }
    // Initialize tier if provided
    if (widget.serviceId != null) {
      // We'll set this after services are loaded
    }
  }

  void _loadCustomerDetails() {
    // Rely on AuthProvider to pre-fill details
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      setState(() {
        _customerName = authProvider.userName;
        _customerEmail = authProvider.userEmail;
        _customerPhone = authProvider.userData['phone'] ?? '';
      });
    } catch (e) {
      debugPrint('Error loading customer details: $e');
    }
  }

  Future<void> _loadServices() async {
    try {
      final response = await Supabase.instance.client
          .from('vendor_services')
          .select('*, vendor_profiles(*), service_components(*, service_items(*)), service_pricing_tiers(*)')
          .eq('vendor_id', widget.vendor.id)
          .eq('approval_status', 'approved');

      final List<VendorService> fetchedServices = response
          .map<VendorService>((json) => VendorService.fromJson(json))
          .where((s) => s.active || s.status.name.toLowerCase() == 'active')
          .toList();

      if (mounted) {
        setState(() {
          _availableServices = fetchedServices;

          if (widget.serviceId != null && _availableServices.isNotEmpty) {
            _selectedService = _availableServices.firstWhere(
              (s) => s.id == widget.serviceId,
              orElse: () => _availableServices.first,
            );
          } else if (_availableServices.isNotEmpty) {
            _selectedService = _availableServices.first;
          }
          
          if (_selectedService != null && _guestCount == 1) {
            final paxOptions = _selectedService!.getAvailablePaxOptions();
            if (paxOptions.isNotEmpty) {
              _guestCount = paxOptions.first;
            }
          }
          _isLoading = false;
          
          // DEBUG: Booking Screen Data
          debugPrint('\n📅 BOOKING SCREEN ENHANCED - DATA LOADED');
          debugPrint('├─ Selected Service: ${_selectedService?.name ?? "None"}');
          debugPrint('├─ Event Type: ${_eventType ?? "None"} (${_eventType != null ? PredefinedEventTypes.getDisplayNameByCode(_eventType!) : "N/A"})');
          debugPrint('└─ Guest Count: $_guestCount\n');
          
          // Jump to Step 1 if service is already selected
          if (widget.serviceId != null && _availableServices.isNotEmpty) {
            _currentStep = 1;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(1);
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading services for booking: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
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
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.chat, color: AppTheme.textPrimaryColor),
            onPressed: () => Navigator.pushNamed(context, '/messages'),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: AppTheme.textPrimaryColor),
            onPressed: () => Navigator.pushNamed(context, '/shop'),
          ),
        ],
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
            'Select Service',
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
          if (_availableServices.isEmpty)
            const Center(
              child: Text(
                'No active services available for this vendor.',
                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 16),
              ),
            )
          else
            ..._availableServices.map((service) => _buildServiceCard(service)).toList(),
        ],
      ),
    );
  }

  Widget _buildServiceCard(VendorService service) {
    final isSelected = _selectedService?.id == service.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedService = service;
            _selectedPackageId = ''; // Reset package selection
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            ServiceImageCarousel(
              images: service.images,
              serviceName: service.name,
              height: 150,
            ),

            // Service Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
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

                  const SizedBox(height: 8),

                  // Category and Type
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          service.category.displayName,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          service.type.toString().split('.').last,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    service.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Pricing
                  Row(
                    children: [
                      Text(
                  'RM ${service.basePrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const Spacer(),
                      if (service.packageOptions.isNotEmpty)
                        Text(
                          '${service.packageOptions.length} packages',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),

                  if (service.packages?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${service.packages!.length} packages',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: const Text('Change'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    if (_selectedService == null) return const SizedBox.shrink();
    
    // Prioritize sessions and custom slots
    final timeRule = _selectedService!.timeRule;
    final legacyTimeSlots = (_selectedService!.availability['timeSlots'] ?? _selectedService!.options['timeSlots']) as List?;
    final sessions = timeRule?.sessions ?? [];
    
    // 1. Check for Session-based model in timeRule (Strongly typed)
    if (sessions.isNotEmpty) {
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
          ...sessions.map((session) {
            final isSelected = _selectedSessionSlot != null && _selectedSessionSlot!['name'] == session.name;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSessionSlot = {
                    'name': session.name,
                    'start': session.startTime,
                    'end': session.endTime,
                    'priceMultiplier': session.priceMultiplier,
                  };
                  final parts = session.startTime.split(':');
                  if (parts.length >= 2) {
                    _selectedTime = TimeOfDay(
                      hour: int.tryParse(parts[0]) ?? 9,
                      minute: int.tryParse(parts[1]) ?? 0,
                    );
                  }
                  _selectedDuration = session.name;
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
                            session.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                            ),
                          ),
                          Text(
                            "${session.startTime} - ${session.endTime}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (session.priceMultiplier != 1.0)
                      Text(
                        "x${session.priceMultiplier}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
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

    // 2. Check for legacy/explicit time slots from availability or options
    if (legacyTimeSlots != null && legacyTimeSlots.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Slot',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...legacyTimeSlots.map((slot) {
            final isSelected = _selectedSessionSlot != null && _selectedSessionSlot!['name'] == slot['name'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSessionSlot = slot is Map<String, dynamic> ? slot : Map<String, dynamic>.from(slot);
                  if (slot['start'] != null) {
                    final parts = slot['start'].toString().split(':');
                    if (parts.length >= 2) {
                      _selectedTime = TimeOfDay(
                        hour: int.tryParse(parts[0]) ?? 9,
                        minute: int.tryParse(parts[1]) ?? 0,
                      );
                    }
                  }
                  _selectedDuration = slot['name'] ?? 'Session';
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

    // 3. Fallback to dynamic hourly slot generation for fixedSlot or fullDay
    final List<TimeOfDay> slots = [];

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
                    _selectedSessionSlot = null; // Clear session if picking manual slot
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
                    _selectedSessionSlot = null;
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
          child: _selectedSessionSlot != null 
            ? Row(
                children: [
                  const Icon(Icons.schedule, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDuration,
                    style: const TextStyle(fontSize: 16, color: AppTheme.textPrimaryColor),
                  ),
                ],
              )
            : DropdownButtonFormField<String>(
                value: _durations.contains(_selectedDuration) ? _selectedDuration : _durations.first,
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

          // Package Selection
          if (_selectedService != null && (_selectedService!.packages?.isNotEmpty ?? false)) ...[
            PackageSelectionWidget(
              packages: _selectedService!.packages?.map((p) => {
                'id': p.id,
                'name': p.name,
                'description': p.description,
                'price': p.priceByPax.isNotEmpty ? p.priceByPax.values.first : 0.0,
              }).toList() ?? [],
              selectedPackageId: _selectedPackageId,
              onPackageSelected: (packageId) {
                setState(() {
                  _selectedPackageId = packageId;
                });
              },
              showAsCards: true,
            ),
            const SizedBox(height: 24),
          ],

          // Multi-Tier Pricing Selection
          if (_selectedService != null && _selectedService!.pricingTiers.isNotEmpty) ...[
            const Text(
              'Select Pricing Tier',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ..._selectedService!.pricingTiers.map((tier) {
              final isSelected = _selectedTierId == tier.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: RadioListTile<String>(
                  value: tier.id ?? '',
                  groupValue: _selectedTierId,
                  onChanged: (value) {
                    setState(() {
                      _selectedTierId = value;
                      // Update guest count if tier has minPax and current is lower
                      if (tier.minPax > _guestCount) {
                        _guestCount = tier.minPax;
                      }
                    });
                  },
                  title: Text(
                    tier.name ?? 'Tier',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tier.description != null && tier.description!.isNotEmpty)
                        Text(tier.description!),
                      Text(
                        'Minimum ${tier.minPax} pax',
                        style: TextStyle(
                          fontSize: 12,
                          color: tier.minPax > _guestCount ? Colors.orange : Colors.grey,
                          fontWeight: tier.minPax > _guestCount ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  secondary: Text(
                    'RM ${tier.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
          ],

          // Guest Count Selection (Pax) - Only show if service actually needs it
          if (_selectedService != null && _shouldShowPaxSelector()) ...[
            _buildGuestCountSelector(),
            const SizedBox(height: 24),
          ],

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
    final selectedPackage = _selectedService?.packages?.firstWhere(
      (p) => p.id == _selectedPackageId,
      orElse: () => ServicePackage(
        id: '',
        name: 'Base Package',
        description: '',
        category: '',
        priceByPax: {1: _selectedService?.basePrice ?? 0},
        facilities: [],
        services: [],
        photography: [],
      ),
    );

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

          // Service Summary
          if (_selectedService != null) ...[
            Container(
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
                    _selectedService!.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedService!.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ServiceImageCarousel(
                    images: _selectedService!.images,
                    serviceName: _selectedService!.name,
                    height: 120,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          _buildReviewSection('Service Details', [
            'Service: ${_selectedService?.name ?? 'Not selected'}',
            'Category: ${_selectedService?.category.displayName ?? 'N/A'}',
            if (_eventType != null) 'Event Type: ${PredefinedEventTypes.getDisplayNameByCode(_eventType!)}',
            'Package: ${selectedPackage?.name ?? 'Base Package'}',
            if (_guestCount > 1) 'Guest Count: $_guestCount',
            'Price: RM ${_calculateTotalPrice().toStringAsFixed(2)}',
          ]),
          const SizedBox(height: 20),
          _buildReviewSection('Date & Time', [
            'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            'Time: ${_selectedTime.format(context)}${_selectedSessionSlot != null ? ' (${_selectedSessionSlot!['name']})' : ''}',
            'Duration: $_selectedDuration',
          ]),
          const SizedBox(height: 20),

          // Selected Options Summary
          if (_selectedItemsByComponent.isNotEmpty) ...[
            _buildReviewSection('Selected Options', _selectedItemsByComponent.entries.expand((entry) {
              final componentId = entry.key;
              final itemIds = entry.value;
              final component = _selectedService?.components.firstWhere((c) => c.id == componentId);
              if (component == null) return <String>[];
              
              return itemIds.map((itemId) {
                final item = component.items.firstWhere((it) => it.id == itemId);
                String label = '${component.name}: ${item.name}';
                if (item.extraPrice != null && item.extraPrice! > 0) {
                  label += ' (+RM ${item.extraPrice!.toStringAsFixed(2)})';
                }
                return label;
              });
            }).toList()),
            const SizedBox(height: 20),
          ],
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
          if (_selectedService?.installmentEnabled ?? false) ...[
            const SizedBox(height: 20),
            _buildPaymentBreakdownSection(),
          ],
          if (_selectedService?.cancellationPolicy != null && _selectedService!.cancellationPolicy!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildReviewSection('Cancellation Policy', [
              _selectedService!.cancellationPolicy!,
              'Policy Type: ${_selectedService!.cancellationPolicyType.toUpperCase()}',
            ]),
          ],
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enhance Your Event',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Browse our shop for additional items like decorations, rentals, and more to make your event special.',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/shop'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Browse Shop',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowPaxSelector() {
    if (_selectedService == null) return false;
    
    final paxOptions = _selectedService!.getAvailablePaxOptions();
    
    // Show if explicitly per-pax pricing
    if (_selectedService!.pricingModel?.type == PricingModelType.perPax) return true;
    
    // Show if multiple tiers are available to choose from
    if (paxOptions.length > 1) return true;
    
    // Show for categories that inherently depend on guest count
    final category = _selectedService!.category.id.toLowerCase();
    if (['catering', 'venue', 'venues', 'all-in package'].contains(category)) return true;
    
    return false;
  }

  Widget _buildGuestCountSelector() {
    final paxOptions = _selectedService?.getAvailablePaxOptions() ?? [];
    final bool hasDiscreteTiers = _selectedService != null && 
        (_selectedService!.hasPackagePricing || _selectedService!.pricingTiers.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Number of Guests (Pax)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        if (hasDiscreteTiers && paxOptions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: paxOptions.map((pax) {
              final isSelected = _guestCount == pax;
              return ChoiceChip(
                label: Text('$pax pax'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _guestCount = pax);
                  }
                },
                selectedColor: AppTheme.primaryColor,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  ),
                ),
              );
            }).toList(),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Total Pax',
                    style: TextStyle(fontSize: 16, color: AppTheme.textSecondaryColor),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _guestCount > _getMinPax() ? () => setState(() => _guestCount--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$_guestCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(() => _guestCount++),
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  int _getMinPax() {
    if (_selectedService == null) return 1;
    
    // 1. Check if a specific tier is selected
    if (_selectedTierId != null && _selectedTierId!.isNotEmpty) {
      try {
        final tier = _selectedService!.pricingTiers.firstWhere((t) => t.id == _selectedTierId);
        return tier.minPax > 0 ? tier.minPax : 1;
      } catch (_) {}
    }

    // 2. Default to service min pax
    final paxOptions = _selectedService!.getAvailablePaxOptions();
    return paxOptions.isNotEmpty ? paxOptions.first : 1;
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

  double _calculateTotalPrice() {
    if (_selectedService == null) return 0.0;
    
    double total = 0.0;

    // 1. Determine base price (Tier, Pax, or Base)
    double basePrice = _selectedService!.basePrice;
    if (_selectedTierId != null && _selectedTierId!.isNotEmpty) {
      try {
        final tier = _selectedService!.pricingTiers.firstWhere((t) => t.id == _selectedTierId);
        basePrice = tier.price;
      } catch (_) {}
    } else if (_selectedService!.hasPackagePricing) {
      basePrice = _selectedService!.getPriceForPax(_guestCount);
    }

    // 2. Apply Session-specific pricing if selected
    if (_selectedSessionSlot != null) {
      if (_selectedSessionSlot!['price'] != null) {
        total = double.tryParse(_selectedSessionSlot!['price'].toString()) ?? basePrice;
      } else if (_selectedSessionSlot!['priceMultiplier'] != null) {
        final multiplier = double.tryParse(_selectedSessionSlot!['priceMultiplier'].toString()) ?? 1.0;
        total = basePrice * multiplier;
      } else {
        total = basePrice;
      }
    } else {
      total = basePrice;
    }

    // 3. Add extra prices from selected components/items
    _selectedItemsByComponent.forEach((componentId, itemIds) {
      final component = _selectedService!.components.firstWhere((c) => c.id == componentId);
      for (var itemId in itemIds) {
        try {
          final item = component.items.firstWhere((it) => it.id == itemId);
          if (item.extraPrice != null && item.extraPrice! > 0) {
            total += item.extraPrice!;
          }
        } catch (_) {}
      }
    });
    
    return total;
  }

  Widget _buildPaymentBreakdownSection() {
    final total = _calculateTotalPrice();
    final depositPercent = _selectedService?.depositPercentage ?? 0;
    final depositAmount = total * (depositPercent / 100);
    final remaining = total - depositAmount;
    final maxInstallments = _selectedService?.maxInstallments ?? 1;
    final installmentAmount = remaining / maxInstallments;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow('Total Amount', 'RM ${total.toStringAsFixed(2)}', isBold: true),
          const Divider(),
          _buildPriceRow('Initial Deposit (${depositPercent.toInt()}%)', 'RM ${depositAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildPriceRow('Remaining Balance', 'RM ${remaining.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildPriceRow('Installments', '$maxInstallments x RM ${installmentAmount.toStringAsFixed(2)}', isPrimary: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false, bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold || isPrimary ? FontWeight.bold : FontWeight.normal,
            color: isPrimary ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
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
    if (_currentStep == 0) {
      return _selectedService != null;
    } else if (_currentStep == 1) {
      // Validate date and time
      return true; // Simplified for now
    } else if (_currentStep == 2) {
      // Validate location if required
      return true;
    } else if (_currentStep == 3) {
      // Validate customer info
      return _customerName.isNotEmpty && _customerPhone.isNotEmpty && _customerEmail.isNotEmpty;
    } else if (_currentStep == 4) {
      return true; // Always can confirm on review step
    }
    return false; // Default case for any other step
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

  Future<void> _confirmBooking() async {
    // Validate vendor service availability and status
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service')),
      );
      return;
    }

    // Check if service is active
    if (!_selectedService!.active) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This service is currently not available')),
      );
      return;
    }

    // Check advance booking days
    final daysDifference = _selectedDate.difference(DateTime.now()).inDays;
    if (daysDifference < _selectedService!.advanceBookingDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This service requires booking at least ${_selectedService!.advanceBookingDays} days in advance')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      final String customerId = authProvider.userId ?? 'anonymous';
      final String bookingId = const Uuid().v4();
      final double totalAmount = _calculateTotalPrice();
      
      String selectedPackageName = 'Base Package';
      
      // Handle Multi-Tier Selection
      if (_selectedTierId != null && _selectedTierId!.isNotEmpty) {
        try {
          final tier = _selectedService!.pricingTiers.firstWhere((t) => t.id == _selectedTierId);
          selectedPackageName = tier.name ?? 'Tier';
        } catch (_) {
          selectedPackageName = 'Custom Tier';
        }
      } else if (_selectedPackageId.isNotEmpty) {
        // Handle Legacy Package Selection
        final selectedPackage = _selectedService!.packageOptions.isNotEmpty
            ? (_selectedService!.packageOptions as List<Map<String, dynamic>>).firstWhere(
                (p) => p['id']?.toString() == _selectedPackageId,
                orElse: () => {'name': 'Base Package', 'price': _selectedService!.basePrice},
              )
            : {'name': 'Base Package', 'price': _selectedService!.basePrice};
        selectedPackageName = selectedPackage['name'] ?? 'Base Package';
      }

      if (_selectedSessionSlot != null) {
        selectedPackageName = "$selectedPackageName - ${_selectedSessionSlot!['name']}";
      }

      // 1. Create Booking Object
      final booking = Booking(
        id: bookingId,
        vendorId: widget.vendor.id,
        customerId: customerId,
        serviceId: _selectedService!.id,
        serviceName: _selectedService!.name,
        customerName: _customerName,
        customerPhone: _customerPhone,
        customerEmail: _customerEmail,
        bookingDate: _selectedDate,
        bookingTime: _selectedTime,
        duration: _selectedDuration,
        packageName: selectedPackageName,
        amount: totalAmount,
        location: _location,
        notes: _notes,
        guestCount: _guestCount,
        eventType: _eventType,
        status: BookingStatus.pendingVendor,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        selectedOptions: _selectedItemsByComponent,
      );

      // 2. Submit Booking
      final createdBooking = await bookingProvider.addBooking(booking);

      if (createdBooking != null) {
        // 3. Handle Installments if enabled
        if (_selectedService!.installmentEnabled) {
          final depositPercent = _selectedService!.depositPercentage ?? 0;
          final depositAmount = totalAmount * (depositPercent / 100);
          final remainingBalance = totalAmount - depositAmount;
          final numberOfInstallments = _selectedService!.maxInstallments ?? 1;
          
          final plan = InstallmentPlan(
            id: const Uuid().v4(),
            bookingId: createdBooking.id,
            totalAmount: totalAmount,
            depositAmount: depositAmount,
            remainingBalance: remainingBalance,
            numberOfInstallments: numberOfInstallments,
            status: InstallmentPlanStatus.active,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          // Generate payment schedule (simplified: monthly from booking date)
          final List<Map<String, dynamic>> schedule = [];
          final installmentAmount = remainingBalance / numberOfInstallments;
          
          for (int i = 1; i <= numberOfInstallments; i++) {
            schedule.add({
              'amount': installmentAmount,
              'dueDate': _selectedDate.add(Duration(days: 30 * i)),
              'status': 'pending',
            });
          }

          await bookingProvider.createInstallmentPlan(plan, schedule);
        }

        if (mounted) {
          Navigator.pop(context); // Close loading
          
          // Show success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Booking Successful'),
                ],
              ),
              content: const Text(
                  'Your booking request has been sent to the vendor for approval. You can track its status in your bookings list.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close success dialog
                    Navigator.of(context).pop(); // Go back to service screen
                  },
                  child: const Text('Great!'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit booking. Please try again.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _confirmBooking: $e');
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  bool _isTimeWithinAvailability(VendorService service, DateTime date, TimeOfDay time) {
    final dayName = _getDayName(date.weekday);
    final availability = service.availability[dayName];
    if (availability == null || availability['available'] != true) {
      return false;
    }
    final startTimeStr = availability['start'] as String? ?? '00:00';
    final endTimeStr = availability['end'] as String? ?? '23:59';

    final startParts = startTimeStr.split(':');
    final endParts = endTimeStr.split(':');

    final startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
    final endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));

    bool isAfterStart = (time.hour > startTime.hour) || (time.hour == startTime.hour && time.minute >= startTime.minute);
    bool isBeforeEnd = (time.hour < endTime.hour) || (time.hour == endTime.hour && time.minute <= endTime.minute);

    return isAfterStart && isBeforeEnd;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  bool _isDurationValid(VendorService service, String duration) {
    return true;
  }
}
