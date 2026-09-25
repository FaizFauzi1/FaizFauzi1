import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/shared/models/services/service_package.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/booking/presentation/views/booking/payment_screen_with_installment.dart';
import 'package:eventease/features/chat/presentation/views/messages/messages_screen.dart';
import 'package:eventease/shared/widgets/service_image_carousel.dart';
import 'package:eventease/shared/widgets/package_selection_widget.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class BookingScreenEnhancedWorking extends StatefulWidget {
  final Vendor vendor;
  final String? serviceId;
  final String? eventId;

  const BookingScreenEnhancedWorking({
    super.key,
    required this.vendor,
    this.serviceId,
    this.eventId,
  });

  @override
  State<BookingScreenEnhancedWorking> createState() => _BookingScreenEnhancedWorkingState();
}

class _BookingScreenEnhancedWorkingState extends State<BookingScreenEnhancedWorking> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Booking data
  VendorService? _selectedService;
  String _selectedPackageId = '';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String _selectedDuration = '1 hour';
  String _location = '';
  String _notes = '';
  String _customerName = '';
  String _customerPhone = '';
  String _customerEmail = '';

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

  @override
  void initState() {
    super.initState();
    // Load vendor services from Supabase
    _loadVendorServices();
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
          if (widget.serviceId != null && _availableServices.isNotEmpty) {
            _selectedService = _availableServices.firstWhere(
              (s) => s.id == widget.serviceId,
              orElse: () => _availableServices.first,
            );
          } else if (_availableServices.isNotEmpty) {
            _selectedService = _availableServices.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading vendor services: $e');
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
                        'RM ${service.basePrice.toStringAsFixed(0)}',
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

                  if (service.hasDynamicPricing) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Dynamic pricing available',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
            'Category: ${_selectedService?.category ?? 'N/A'}',
            'Package: ${selectedPackage?.name ?? 'Base Package'}',
            'Price: RM ${(selectedPackage != null && selectedPackage.priceByPax.isNotEmpty ? selectedPackage.priceByPax.values.first : _selectedService?.basePrice ?? 0).toStringAsFixed(0)}',
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
        return _selectedService != null;
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

    final amount = selectedPackage != null && selectedPackage.priceByPax.isNotEmpty
        ? selectedPackage.priceByPax.values.first
        : _selectedService?.basePrice ?? 0.0;

    // Navigate to payment screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreenWithInstallment(
          vendor: widget.vendor,
          serviceId: _selectedService?.id ?? '',
          service: _selectedService,
          eventId: widget.eventId,
          amount: amount,
          bookingDetails: {
            'service': _selectedService?.name ?? 'Unknown Service',
            'package': selectedPackage?.name ?? 'Base Package',
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
