import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/features/booking/presentation/views/booking/payment_screen.dart';
import 'package:eventease/features/chat/presentation/views/messages/messages_screen.dart';
import 'package:eventease/shared/widgets/service_image_carousel.dart';
import 'package:eventease/shared/widgets/package_selection_widget.dart';
import 'package:eventease/shared/models/services/service_package.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/features/booking/presentation/views/booking/order_details_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:eventease/shared/models/services/service_time_rule.dart';
import 'package:eventease/shared/models/services/service_logistics.dart';
import 'package:eventease/core/utils/logistics_engine.dart';
import 'package:eventease/features/vendor/models/service_coupon.dart';
import 'package:eventease/core/providers/coupon_provider.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/core/services/installment_service.dart';

class BookingScreenEnhancedFixed extends StatefulWidget {
  final Vendor vendor;
  final VendorService? service;
  final String? serviceId;
  final String? eventId;
  // Pre-selected values from product detail
  final ServicePackage? preSelectedPackage;
  final int? preSelectedPax;
  final DateTime? preSelectedDate;
  final TimeOfDay? preSelectedTime;
  final String? preSelectedDuration;
  final String? preSelectedMenu;
  final Map<String, bool>? preSelectedAddOns;

  const BookingScreenEnhancedFixed({
    super.key,
    required this.vendor,
    this.service,
    this.serviceId,
    this.eventId,
    this.preSelectedPackage,
    this.preSelectedPax,
    this.preSelectedDate,
    this.preSelectedTime,
    this.preSelectedDuration,
    this.preSelectedMenu,
    this.preSelectedAddOns,
  });

  @override
  State<BookingScreenEnhancedFixed> createState() => _BookingScreenEnhancedFixedState();
}

class _BookingScreenEnhancedFixedState extends State<BookingScreenEnhancedFixed> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  bool _isProcessing = false;

  // Booking data
  VendorService? _selectedService;
  String _selectedPackageId = '';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  DateTime _focusedDay = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String _selectedDuration = '1 hour';
  String _location = '';
  String _notes = '';
  String _customerName = '';
  String _customerPhone = '';
  String _customerEmail = '';
  int _selectedPax = 0; // Selected number of guests
  String? _selectedMenu;
  Map<String, bool> _selectedAddOns = {};

  // Promo Code State
  final _promoController = TextEditingController();
  ServiceCoupon? _appliedCoupon;
  bool _isValidatingPromo = false;
  String? _promoError;
  
  // Logistics & Location State
  bool _locationTbc = false;
  double _distanceKm = 0.0;
  double _travelFee = 0.0;
  int _crewCount = 1;
  double _setupTime = 1.0;
  double _teardownTime = 1.0;
  bool _isLogisticsLoading = false;
  
  // New Platform Architecture State
  ServiceSession? _selectedSession;
  DateTimeRange? _selectedDateRange;

  final List<String> _durations = [
    '30 minutes',
    '1 hour',
    '1.5 hours',
    '2 hours',
    '3 hours',
    '4 hours',
    'Full day',
  ];

  // Get available services from VendorService model
  List<VendorService> _availableServices = [];
  
  Set<DateTime> _unavailableDates = {};
  bool _useWhitelist = false;
  Set<DateTime> _whitelistDates = {};
  
  // Installment State
  bool _useInstallmentPlan = false;

  @override
  void initState() {
    super.initState();

    // Initialize with pre-selected values from product detail
    if (widget.preSelectedPackage != null) {
      _selectedPackageId = widget.preSelectedPackage!.id;
    }
    if (widget.preSelectedDate != null) {
      _selectedDate = widget.preSelectedDate!;
    }
    if (widget.preSelectedTime != null) {
      _selectedTime = widget.preSelectedTime!;
    }
    if (widget.preSelectedDuration != null) {
      _selectedDuration = widget.preSelectedDuration!;
    }
    if (widget.preSelectedMenu != null) {
      _selectedMenu = widget.preSelectedMenu;
    }
    if (widget.preSelectedAddOns != null) {
      _selectedAddOns = Map.from(widget.preSelectedAddOns!);
    }
    if (widget.preSelectedPax != null) {
      _selectedPax = widget.preSelectedPax!;
    }

    // If service is provided directly, use it and skip service selection
    if (widget.service != null) {
      _selectedService = widget.service;
      _currentStep = 1; // Start from date/time selection
    } else {
      // Load services from Supabase for this vendor
      _loadVendorServices();
    }
    
    _parseAvailability();
  }

  Future<void> _loadVendorServices() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('vendor_services')
          .select('*')
          .eq('vendor_id', widget.vendor.id)
          .eq('is_active', true);
      final services = (response as List)
          .map((s) => VendorService.fromJson(s))
          .toList();
      if (mounted) {
        setState(() {
          _availableServices = services;
          if (widget.serviceId != null) {
            _selectedService = _availableServices.firstWhere(
              (s) => s.id == widget.serviceId,
              orElse: () => _availableServices.isNotEmpty ? _availableServices.first : _defaultService(),
            );
          } else if (_availableServices.isNotEmpty) {
            _selectedService = _availableServices.first;
          }
          _parseAvailability();
        });
      }
    } catch (e) {
      debugPrint('Error loading vendor services: $e');
    }
  }

  VendorService _defaultService() {
    return VendorService(
      id: '00000000-0000-0000-0000-000000000000',
      vendorId: widget.vendor.id,
      name: 'Default Service',
      description: 'Default service description',
      category: EventCategory.package,
      basePrice: 0,
      images: [],
      active: true,
      maxBookingsPerDay: 1,
      advanceBookingDays: 1,
    );
  }

  void _parseAvailability() {
    if (_selectedService != null && _selectedService!.availability.isNotEmpty) {
       final availability = _selectedService!.availability;
       
       _unavailableDates.clear();
       _whitelistDates.clear();
       _useWhitelist = false;
       
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MessagesScreen()),
            ),
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
                _buildLocationStep(),
                _buildLogisticsStep(),
                _buildDetailsStep(), // Packages & Notes
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
        children: List.generate(6, (index) {
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
            _parseAvailability(); // Re-parse availability when service changes
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
                        'RM ${service.basePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const Spacer(),
                      if (service.packages?.isNotEmpty ?? false)
                        Text(
                          '${service.packages?.length ?? 0} packages',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),

                  if (service.hasDynamicPricing) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Dynamic pricing available',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
          const SizedBox(height: 32),
          _buildDynamicDateTimeContent(),
        ],
      ),
    );
  }

  Widget _buildDynamicDateTimeContent() {
    final rule = _selectedService?.timeRule;
    final timeType = rule?.timeType ?? TimeType.fullDay;

    switch (timeType) {
      case TimeType.session:
        return _buildSessionPicker(rule!);
      case TimeType.dateRange:
        return _buildDateRangePicker(rule!);
      case TimeType.fixedSlot:
        return Column(
          children: [
            _buildDateSelector(),
            const SizedBox(height: 24),
            _buildFixedSlotPicker(rule!),
          ],
        );
      case TimeType.fullDay:
        return Column(
          children: [
            _buildDateSelector(),
            if (rule?.startTime != null && rule?.endTime != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Booking covers full day from ${rule!.startTime} to ${rule.endTime} (${rule.totalHours.toStringAsFixed(1)} hours)",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      case TimeType.flexibleHour:
      default:
        return Column(
          children: [
            _buildDateSelector(),
            const SizedBox(height: 24),
            _buildFlexibleTimePicker(rule),
          ],
        );
    }
  }

  Widget _buildSessionPicker(ServiceTimeRule rule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDateSelector(),
        const SizedBox(height: 24),
        const Text(
          'Select Session',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor),
        ),
        const SizedBox(height: 12),
        ...rule.sessions.map((session) {
          final isSelected = _selectedSession == session;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
            ),
            child: ListTile(
              onTap: () => setState(() {
                _selectedSession = session;
                // Update time for legacy compatibility
                final parts = session.startTime.split(':');
                _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
              }),
              title: Text(session.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${session.startTime} - ${session.endTime}"),
              trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDateRangePicker(ServiceTimeRule rule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (range != null) {
              setState(() => _selectedDateRange = range);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  _selectedDateRange == null 
                    ? "Select range" 
                    : "${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedSlotPicker(ServiceTimeRule rule) {
    // Basic slot picker implementation
    return _buildTimeSelector(); // Fallback for now or implement detailed slots
  }

  Widget _buildFlexibleTimePicker(ServiceTimeRule? rule) {
    // Use the existing time selector + a dynamic duration selector
    return Column(
      children: [
        _buildTimeSelector(),
        const SizedBox(height: 24),
        _buildDynamicDurationSelector(rule),
      ],
    );
  }

  Widget _buildDynamicDurationSelector(ServiceTimeRule? rule) {
    if (rule == null) return _buildDurationSelector();

    final int min = rule.minDurationMinutes ?? 60;
    final int max = rule.maxDurationMinutes ?? 480;
    final int step = rule.durationStepMinutes;

    final List<int> options = [];
    for (int i = min; i <= max; i += step) {
      options.add(i);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: options.map((mins) {
            final label = mins >= 60 ? "${mins ~/ 60}h ${mins % 60 > 0 ? '${mins % 60}m' : ''}" : "${mins}m";
            final isSelected = _selectedDuration == label;
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (v) => setState(() => _selectedDuration = label),
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              labelStyle: TextStyle(color: isSelected ? AppTheme.primaryColor : Colors.black),
            );
          }).toList(),
        ),
      ],
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

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time',
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
              Icon(Icons.access_time, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              TextButton(
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
                child: const Text('Change'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    // Defensive coding: Ensure _selectedDuration is in _durations
    if (!_durations.contains(_selectedDuration)) {
       // If current selection is invalid, reset to the first available option
       if (_durations.isNotEmpty) {
          // Schedule a microtask to update state after build is complete if needed, 
          // but for build method correctness, we just use a local valid value for the dropdown
          // or we can update the state variable if we are sure it won't cause setstate during build error.
          // Safer to just use a local valid variable for the dropdown value
       }
    }
    
    // Select a valid value for the dropdown
    String validDuration = _durations.contains(_selectedDuration) 
        ? _selectedDuration 
        : _durations.first;

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
            value: validDuration,
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
    final packages = _selectedService?.packages ?? [];
    
    // Extract all unique pax tiers from all packages and pricing tiers
    final List<int> paxOptions = _selectedService?.getAvailablePaxOptions() ?? [];
    
    // Determine if guest count selector is actually needed
    final bool isPerPaxPricing = _selectedService?.pricingModel?.type == PricingModelType.perPax;
    final bool hasMultipleTiers = paxOptions.length > 1;
    final bool isGuestDependentCategory = ['catering', 'venue', 'venues', 'all-in package'].contains(_selectedService?.category.id.toLowerCase());
    
    final bool showPaxSelector = isPerPaxPricing || hasMultipleTiers || isGuestDependentCategory;
    
    // Initialize _selectedPax if not set or if current value is invalid
    if (_selectedPax == 0 && paxOptions.isNotEmpty) {
      _selectedPax = paxOptions.first;
    } else if (paxOptions.isNotEmpty && !paxOptions.contains(_selectedPax)) {
      _selectedPax = paxOptions.first;
    }

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

          // Guest Count (Pax) Selector
          if (showPaxSelector && paxOptions.isNotEmpty) ...[
            const Text(
              'Number of Guests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  // Ensure existing value is in the items list
                  value: paxOptions.contains(_selectedPax) ? _selectedPax : (paxOptions.isNotEmpty ? paxOptions.first : null),
                  isExpanded: true,
                  items: paxOptions.map((pax) {
                    return DropdownMenuItem<int>(
                      value: pax,
                      child: Text('$pax Guests'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPax = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Package Selection
          if (_selectedService != null && (packages.isNotEmpty)) ...[
            PackageSelectionWidget(
              packages: packages.map((p) => {
                'id': p.id,
                'name': p.name,
                'description': p.description,
                'price': p.getPriceForPax(_selectedPax),
              }).toList(),
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
        id: 'base',
        name: 'Base Package',
        description: 'Base service package',
        category: _selectedService?.category.displayName ?? 'General',
        priceByPax: {1: _selectedService?.basePrice ?? 0},
        facilities: [],
        services: [],
        photography: [],
      ),
    );

    double basePrice = (selectedPackage?.getPriceForPax(_selectedPax) ?? _selectedService?.basePrice ?? 0).toDouble();
    
    // Apply session multiplier if applicable
    if (_selectedService?.timeRule?.timeType == TimeType.session && _selectedSession != null) {
      basePrice *= _selectedSession!.priceMultiplier;
    }

    double discountAmount = 0;
    if (_appliedCoupon != null) {
      if (_appliedCoupon!.discountType == 'percentage') {
        discountAmount = basePrice * (_appliedCoupon!.discountValue / 100);
      } else {
        discountAmount = _appliedCoupon!.discountValue;
      }
    }

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
            'Package: ${selectedPackage?.name ?? 'Base Package'}',
            if (_selectedPax > 0) 'Guests: $_selectedPax pax',
            if (_selectedMenu != null) 'Selected Menu: $_selectedMenu',
            'Service Price: RM ${basePrice.toStringAsFixed(0)}',
            if (discountAmount > 0) 'Discount: - RM ${discountAmount.toStringAsFixed(2)}',
            'Travel & Logistics: RM ${_travelFee.toStringAsFixed(2)}',
            'Total Price: RM ${(basePrice - discountAmount + _travelFee).toStringAsFixed(2)}',
          ]),
          const SizedBox(height: 20),
          _buildReviewSection('Date & Time', [
            if (_selectedService?.timeRule?.timeType == TimeType.dateRange && _selectedDateRange != null)
              'Range: ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}'
            else if (_selectedService?.timeRule?.timeType == TimeType.session && _selectedSession != null)
              ...[
                'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                'Session: ${_selectedSession!.name} (${_selectedSession!.startTime} - ${_selectedSession!.endTime})',
              ]
            else if (_selectedService?.timeRule?.timeType == TimeType.fullDay)
              ...[
                'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                'Type: Full Day (${_selectedService?.timeRule?.startTime} - ${_selectedService?.timeRule?.endTime})',
                'Total: ${_selectedService?.timeRule?.totalHours.toStringAsFixed(1)} hours',
              ]
            else ...[
              'Date: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              'Time: ${_selectedTime.format(context)}',
              'Duration: $_selectedDuration',
            ]
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
          const SizedBox(height: 20),
          _buildPromoCodeSection(),
          const SizedBox(height: 20),
          _buildPaymentPlanSection(basePrice - discountAmount + _travelFee),
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
              onPressed: (_canProceed() && !_isProcessing) ? _nextStep : null,
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_currentStep == 4 ? 'Submit Request' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _selectedService != null;
      case 1:
        return true; // Date/time always valid
      case 2:
        return _locationTbc || _location.isNotEmpty || _selectedService?.category == EventCategory.venue;
      case 3:
        return true; // Logistics is auto-comp
      case 4:
        return true; // Details optional
      case 5:
        return _customerName.isNotEmpty && _customerPhone.isNotEmpty && _customerEmail.isNotEmpty;
      case 6:
        return true; // Always can confirm on review step
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_currentStep < 6) {
      if (_currentStep == 2) {
        _calculateLogistics();
      }
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

  Widget _buildLocationStep() {
    final isVenue = _selectedService?.category == EventCategory.venue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Location',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            isVenue ? 'The service is tied to a specific venue address.' : 'Where should the service be provided?',
            style: const TextStyle(fontSize: 16, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 32),
          if (isVenue) ...[
             _buildReviewSection('Venue Address', [
               _selectedService?.venueAddress ?? 'Address not specified',
             ]),
             const SizedBox(height: 16),
             const Text("Note: Logistics will be based on this fixed address.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ] else ...[
            SwitchListTile(
              title: const Text("Location Not Yet Known (TBC)"),
              subtitle: const Text("We will use an estimate for logistics for now."),
              value: _locationTbc,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) => setState(() => _locationTbc = v ?? false),
            ),
            const SizedBox(height: 16),
            if (!_locationTbc)
              _buildTextField('Location', _location, Icons.location_on, 'Enter the event venue/address'),
            if (_locationTbc)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Final logistics will be recalculated once the venue is confirmed.",
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogisticsStep() {
    if (_isLogisticsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final logistics = _selectedService?.logisticsConfig;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operational Details',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'Auto-computed based on distance and service requirements.',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 32),
          
          _buildLogisticsCard(
            title: 'Travel & Distance',
            icon: Icons.map,
            items: [
              if (_locationTbc) 'Distance: ~35.0 km (Estimate)' else 'Distance: ${_distanceKm.toStringAsFixed(1)} km',
              'Travel Fee: RM ${_travelFee.toStringAsFixed(2)}',
              if (logistics?.freeRadiusKm != null && logistics!.freeRadiusKm > 0)
                'Note: Includes ${logistics.freeRadiusKm}km free radius',
            ],
          ),
          const SizedBox(height: 20),
          _buildLogisticsCard(
            title: 'Crew & Timeline',
            icon: Icons.groups,
            items: [
              'Crew Size: $_crewCount person(s)',
              'Setup Window: ${_setupTime.toStringAsFixed(1)} hours',
              'Teardown Window: ${_teardownTime.toStringAsFixed(1)} hours',
            ],
          ),
          const SizedBox(height: 20),
          _buildLogisticsCard(
            title: 'Site Requirements',
            icon: Icons.handyman,
            items: [
              'Power: ${logistics?.powerRequired ?? false ? "Required" : "Regular"}',
              'Parking: ${logistics?.parkingRequired ?? false ? "Required for loading" : "Standard"}',
              'Vehicle: ${logistics?.requiresVehicle ?? false ? logistics?.vehicleType?.displayName ?? "Standard" : "None"}',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsCard({required String title, required IconData icon, required List<String> items}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Divider(height: 24),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.check, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: const TextStyle(color: AppTheme.textSecondaryColor))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Future<void> _applyPromoCode() async {
    if (_promoController.text.isEmpty) return;
    
    setState(() {
      _isValidatingPromo = true;
      _promoError = null;
    });

    try {
      final couponProvider = context.read<CouponProvider>();
      
      final selectedPackage = _selectedService?.packages?.firstWhere(
        (p) => p.id == _selectedPackageId,
        orElse: () => ServicePackage(
          id: 'base',
          name: 'Base Package',
          description: 'Base service package',
          category: _selectedService?.category.displayName ?? 'General',
          priceByPax: {1: _selectedService?.basePrice ?? 0},
          facilities: [],
          services: [],
          photography: [],
        ),
      );
      
      final currentAmount = (selectedPackage?.getPriceForPax(_selectedPax) ?? 0).toDouble();

      final coupon = await couponProvider.validateCoupon(
        code: _promoController.text,
        serviceId: _selectedService!.id,
        orderAmount: currentAmount,
      );

      if (coupon != null) {
        setState(() {
          _appliedCoupon = coupon;
          _promoError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promo code applied successfully!'), backgroundColor: Colors.green),
        );
      } else {
        setState(() => _promoError = "Invalid code for this service");
      }
    } catch (e) {
      setState(() => _promoError = e.toString());
    } finally {
      setState(() => _isValidatingPromo = false);
    }
  }

  Widget _buildPromoCodeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Promo Code", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          if (_appliedCoupon == null)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: InputDecoration(
                      hintText: "Enter code",
                      errorText: _promoError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isValidatingPromo ? null : _applyPromoCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isValidatingPromo 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Apply"),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green[200]!)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Applied: ${_appliedCoupon!.code} (${_appliedCoupon!.discountType == 'percentage' ? '${_appliedCoupon!.discountValue.toStringAsFixed(0)}%' : 'RM ${_appliedCoupon!.discountValue.toStringAsFixed(0)}'} OFF)",
                      style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _appliedCoupon = null;
                      _promoController.clear();
                    }),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentPlanSection(double totalAmount) {
    if (totalAmount < 500) return const SizedBox.shrink(); // Minimum RM 500 for installments

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Payment Plan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          RadioListTile<bool>(
            title: const Text("Full Payment"),
            subtitle: Text("Pay RM ${totalAmount.toStringAsFixed(2)} upfront"),
            value: false,
            groupValue: _useInstallmentPlan,
            onChanged: (v) => setState(() => _useInstallmentPlan = v ?? false),
            activeColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<bool>(
            title: const Text("Installment Plan (MVP)"),
            subtitle: const Text("30% deposit + 5 monthly installments (0% interest)"),
            value: true,
            groupValue: _useInstallmentPlan,
            onChanged: (v) => setState(() => _useInstallmentPlan = v ?? true),
            activeColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
          if (_useInstallmentPlan) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildPaymentPlanRow("Initial Deposit (30%)", totalAmount * 0.3),
                  _buildPaymentPlanRow("5 Monthly Installments", (totalAmount * 0.7) / 5, isInstallment: true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentPlanRow(String label, double amount, {bool isInstallment = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isInstallment ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor, fontWeight: isInstallment ? FontWeight.normal : FontWeight.w600)),
          Text("RM ${amount.toStringAsFixed(2)}", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _calculateLogistics() async {
    setState(() => _isLogisticsLoading = true);
    
    final logistics = _selectedService?.logisticsConfig;
    if (logistics == null) {
      setState(() => _isLogisticsLoading = false);
      return;
    }

    // 1. Distance
    if (_locationTbc) {
      _distanceKm = LogisticsEngine.estimateTbcDistance(logistics.primaryState);
    } else {
      _distanceKm = await LogisticsEngine.getDistanceKm(
        logistics.primaryState ?? 'Center', // In reality, use vendor home
        _location,
      );
    }

    // 2. Fees
    _travelFee = LogisticsEngine.calculateTravelFee(
      distanceKm: _distanceKm,
      logistics: logistics,
    );

    // 3. Defaults
    _crewCount = logistics.defaultCrewCount;
    _setupTime = logistics.defaultSetupTime;
    _teardownTime = logistics.defaultTeardownTime;

    setState(() => _isLogisticsLoading = false);
  }

  void _confirmBooking() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      if (currentUser == null) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to make a booking'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final customerId = currentUser.id;

      final selectedPackage = _selectedService?.packages?.firstWhere(
        (p) => p.id == _selectedPackageId,
        orElse: () => ServicePackage(
          id: 'base',
          name: 'Base Package',
          description: 'Base service package',
          category: _selectedService?.category.displayName ?? 'General',
          priceByPax: {1: _selectedService?.basePrice ?? 0},
          facilities: [],
          services: [],
          photography: [],
        ),
      );

      final startTime = _selectedService?.timeRule?.timeType == TimeType.dateRange && _selectedDateRange != null
          ? _selectedDateRange!.start
          : DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedTime.hour,
              _selectedTime.minute,
            );

      int durationMinutes = 60;
      DateTime endTime;

      if (_selectedService?.timeRule?.timeType == TimeType.dateRange && _selectedDateRange != null) {
        endTime = _selectedDateRange!.end;
        durationMinutes = endTime.difference(startTime).inMinutes;
      } else if (_selectedService?.timeRule?.timeType == TimeType.session && _selectedSession != null) {
        final endParts = _selectedSession!.endTime.split(':');
        endTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          int.parse(endParts[0]),
          int.parse(endParts[1]),
        );
        durationMinutes = endTime.difference(startTime).inMinutes;
      } else if (_selectedService?.timeRule?.timeType == TimeType.fullDay && _selectedService?.timeRule?.startTime != null) {
        final startParts = _selectedService!.timeRule!.startTime!.split(':');
        final endParts = _selectedService!.timeRule!.endTime!.split(':');
        final fullDayStart = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          int.parse(startParts[0]),
          int.parse(startParts[1]),
        );
        final fullDayEnd = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          int.parse(endParts[0]),
          int.parse(endParts[1]),
        );
        durationMinutes = fullDayEnd.difference(fullDayStart).inMinutes;
        if (durationMinutes < 0) durationMinutes += 24 * 60;
        endTime = fullDayEnd;
      } else {
        if (_selectedDuration.contains('minutes')) {
          durationMinutes = int.tryParse(_selectedDuration.split(' ')[0]) ?? 30;
        } else if (_selectedDuration.contains('hour')) {
          final val = double.tryParse(_selectedDuration.split(' ')[0]) ?? 1.0;
          durationMinutes = (val * 60).toInt();
        } else if (_selectedDuration == 'Full day') {
          durationMinutes = 8 * 60;
        }
        endTime = startTime.add(Duration(minutes: durationMinutes));
      }
      
      double baseAmount = selectedPackage?.getPriceForPax(_selectedPax) ?? widget.preSelectedPackage?.getPriceForPax(_selectedPax) ?? (_selectedService?.basePrice ?? 0).toDouble();
      
      // Calculate Discount
      double discountAmount = 0;
      if (_appliedCoupon != null) {
        if (_appliedCoupon!.discountType == 'percentage') {
          discountAmount = baseAmount * (_appliedCoupon!.discountValue / 100);
        } else {
          discountAmount = _appliedCoupon!.discountValue;
        }
      }

      // Apply session multiplier if applicable
      if (_selectedService?.timeRule?.timeType == TimeType.session && _selectedSession != null) {
        baseAmount *= _selectedSession!.priceMultiplier;
      }

      final totalWithLogistics = baseAmount - discountAmount + _travelFee;

      final bookingLogistics = BookingLogistics(
        eventLocation: _locationTbc ? 'Location TBC' : _location,
        locationTbc: _locationTbc,
        distanceKm: _distanceKm,
        travelFee: _travelFee,
        crewCount: _crewCount,
        setupTime: _setupTime,
        teardownTime: _teardownTime,
      );
      
      final bookingDetails = {
        'service': _selectedService?.name ?? 'Unknown Service',
        'package': selectedPackage?.name ?? 'Base Package',
        'date': _selectedDate,
        'time': _selectedTime,
        'duration': _selectedDuration,
        'session': _selectedSession?.name,
        'dateRange': _selectedDateRange != null ? {
          'start': _selectedDateRange!.start.toIso8601String(),
          'end': _selectedDateRange!.end.toIso8601String(),
        } : null,
        'location': _locationTbc ? 'Location TBC' : _location,
        'notes': _notes,
        'customerName': _customerName,
        'customerPhone': _customerPhone,
        'customerEmail': _customerEmail,
        'guestCount': _selectedPax,
        'selectedMenu': _selectedMenu,
        'logistics': bookingLogistics.toJson(),
      };

      // Insert into Supabase
      final bookingResponse = await Supabase.instance.client.from('bookings').insert({
        'customer_id': customerId,
        'vendor_id': widget.vendor.id,
        'service_id': _selectedService?.id,
        'booking_date': _selectedDate.toIso8601String(),
        'booking_time': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}:00',
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'guest_count': _selectedPax,
        'total_amount': totalWithLogistics,
        'deposit_amount': _useInstallmentPlan ? totalWithLogistics * 0.3 : totalWithLogistics * 0.5,
        'status': 'pending_vendor', // Initial request from user
        'payment_status': 'unpaid',
        'special_requests': _notes,
        'booking_details': bookingDetails.map((key, value) {
          if (value is DateTime || value is TimeOfDay) return MapEntry(key, value.toString());
          return MapEntry(key, value);
        }),
        'logistics_data': bookingLogistics.toJson(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      final bookingId = bookingResponse['id'];

      // Create Installment Plan if selected
      if (_useInstallmentPlan) {
        final bookingProvider = context.read<BookingProvider>();
        final installmentService = InstallmentService();
        final plan = installmentService.calculateMVPPlan(
          bookingId: bookingId,
          totalAmount: totalWithLogistics,
        );
        final schedule = installmentService.generatePaymentSchedule(plan);

        await bookingProvider.createInstallmentPlan(plan, schedule);
        bookingDetails['installmentPlanId'] = plan.id;
      }

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // Navigate to order details screen (Success)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(
            vendor: widget.vendor,
            serviceId: _selectedService?.id ?? '',
            eventId: widget.eventId,
            amount: totalWithLogistics,
            bookingDetails: bookingDetails,
            paymentMethod: 'Pending Approval', // Indicates no payment yet
          ),
        ),
      );
    } catch (e) {
      print('Error creating booking: $e');
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to request booking: $e')),
      );
    }
  }
}
