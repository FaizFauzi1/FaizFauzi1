import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';

class VendorServiceCreatorScreen extends StatefulWidget {
  final CommonServiceInfo? existingService;

  const VendorServiceCreatorScreen({super.key, this.existingService});

  @override
  State<VendorServiceCreatorScreen> createState() => _VendorServiceCreatorScreenState();
}

class _VendorServiceCreatorScreenState extends State<VendorServiceCreatorScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Category selection & search
  ServiceCategoryType? _selectedCategory;
  final TextEditingController _categorySearchController = TextEditingController();
  String _categorySearchQuery = '';

  // Step 2: Common Basic Information
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _subcategoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _serviceAreaController = TextEditingController();
  final TextEditingController _startingPriceController = TextEditingController();
  ServicePricingModel _pricingModel = ServicePricingModel.packagePrice;
  ServiceStatus _serviceStatus = ServiceStatus.published;
  List<String> _selectedEventTypes = ['Wedding', 'Corporate'];
  final List<String> _tags = [];
  final TextEditingController _tagInputController = TextEditingController();

  // Step 2: Availability & Policies
  final List<String> _availableDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  String _workingHoursStart = '09:00';
  String _workingHoursEnd = '18:00';
  int _minBookingNoticeDays = 7;
  int _maxBookingsPerDay = 2;
  final TextEditingController _cancellationPolicyController = TextEditingController();
  final TextEditingController _depositPercentController = TextEditingController(text: '30');
  final TextEditingController _paymentScheduleController = TextEditingController();
  final TextEditingController _termsController = TextEditingController();

  // Category-Specific Dynamic Data Map
  final Map<String, dynamic> _categoryFields = {};

  // Step 3: Service Packages
  final List<ServicePackageItem> _packages = [];

  // Step 4: Appointment Configuration
  bool _allowAppointments = true;
  final List<ServiceAppointmentType> _appointmentTypes = [];

  final List<String> _allEventTypes = [
    'Wedding',
    'Corporate',
    'Birthday',
    'Anniversary',
    'Engagement',
    'Baby Shower',
    'Gala Dinner',
    'Exhibition',
    'Conference',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingService != null) {
      _loadExistingService(widget.existingService!);
    } else {
      _cancellationPolicyController.text =
          'Free cancellation up to 14 days prior to event. 50% refund thereafter.';
      _paymentScheduleController.text =
          '30% deposit upon booking confirmation. Remaining 70% due 3 days before event date.';
      _termsController.text =
          'Standard EventEase vendor service terms and service level agreements apply.';
      _locationController.text = 'Kuala Lumpur & Klang Valley';
      _serviceAreaController.text = 'Within 50km radius';
    }
  }

  void _loadExistingService(CommonServiceInfo s) {
    _selectedCategory = s.category;
    _nameController.text = s.serviceName;
    _subcategoryController.text = s.subcategory;
    _descriptionController.text = s.description;
    _locationController.text = s.serviceLocation;
    _serviceAreaController.text = s.serviceArea;
    _startingPriceController.text = s.startingPrice.toStringAsFixed(0);
    _pricingModel = s.pricingModel;
    _serviceStatus = s.status;
    _selectedEventTypes = List.from(s.eventTypesSupported);
    _tags.addAll(s.tags);
    _minBookingNoticeDays = s.minBookingNoticeDays;
    _maxBookingsPerDay = s.maxBookingsPerDay;
    _cancellationPolicyController.text = s.cancellationPolicy;
    _depositPercentController.text = s.depositRequirementPercent.toStringAsFixed(0);
    _paymentScheduleController.text = s.paymentSchedule;
    _termsController.text = s.termsAndConditions;

    final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);
    _packages.addAll(provider.getPackagesForService(s.id));
    _appointmentTypes.addAll(provider.getAppointmentTypesForService(s.id));
    _categoryFields.addAll(provider.getCategorySpecificData(s.id));
    _allowAppointments = _appointmentTypes.isNotEmpty;
  }

  @override
  void dispose() {
    _categorySearchController.dispose();
    _nameController.dispose();
    _subcategoryController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _serviceAreaController.dispose();
    _startingPriceController.dispose();
    _tagInputController.dispose();
    _cancellationPolicyController.dispose();
    _depositPercentController.dispose();
    _paymentScheduleController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  void _setDefaultDefaultsForCategory(ServiceCategoryType cat) {
    if (_packages.isEmpty) {
      if (cat == ServiceCategoryType.photography) {
        _packages.addAll([
          ServicePackageItem(
            id: 'pkg-temp-1',
            serviceId: '',
            packageName: 'Essential Photography',
            description: '8 hours single photographer, 500 edited photos.',
            price: 2500.0,
            duration: '8 hours',
            includedServices: ['1 Photographer', '500 Edited Photos', 'Online Gallery'],
          ),
          ServicePackageItem(
            id: 'pkg-temp-2',
            serviceId: '',
            packageName: 'Premium Storyteller',
            description: '10 hours 2 photographers, 800 edited photos + Album.',
            price: 4000.0,
            duration: '10 hours',
            includedServices: ['2 Photographers', '800 Edited Photos', 'Wedding Album'],
          ),
        ]);
      } else if (cat == ServiceCategoryType.catering) {
        _packages.addAll([
          ServicePackageItem(
            id: 'pkg-temp-c1',
            serviceId: '',
            packageName: 'Classic Banquet Buffet',
            description: '10-course buffet with equipment, servers, and cordials.',
            price: 65.0,
            duration: '4 hours serving',
            includedServices: ['10-course buffet', 'Chafing warmers', '6 staff'],
          ),
        ]);
      } else {
        _packages.add(
          ServicePackageItem(
            id: 'pkg-temp-std',
            serviceId: '',
            packageName: 'Standard Service Package',
            description: 'Full comprehensive execution of service for your special event.',
            price: double.tryParse(_startingPriceController.text) ?? 1500.0,
            duration: 'Standard Event Duration',
            includedServices: ['Full Setup', 'Dedicated Coordinator', 'Post-Event Cleanup'],
          ),
        );
      }
    }

    if (_appointmentTypes.isEmpty && _allowAppointments) {
      if (cat == ServiceCategoryType.catering) {
        _appointmentTypes.add(
          ServiceAppointmentType(
            id: 'apt-temp-taste',
            serviceId: '',
            name: 'Food Tasting Session',
            description: 'Sample up to 6 dishes in our tasting room.',
            purpose: AppointmentPurpose.tasting,
            durationMinutes: 60,
            fee: 100.0,
            isPaid: true,
            creditTowardBooking: true,
          ),
        );
      } else if (cat == ServiceCategoryType.venue) {
        _appointmentTypes.add(
          ServiceAppointmentType(
            id: 'apt-temp-visit',
            serviceId: '',
            name: 'Venue Site Visit',
            description: 'Guided tour of the hall, dressing room, and audio setup.',
            purpose: AppointmentPurpose.visit,
            durationMinutes: 60,
            fee: 0.0,
            isPaid: false,
          ),
        );
      } else if (cat == ServiceCategoryType.makeupAndBeauty) {
        _appointmentTypes.add(
          ServiceAppointmentType(
            id: 'apt-temp-trial',
            serviceId: '',
            name: 'Makeup Trial Session',
            description: 'Trial look, airbrush testing, and hair styling.',
            purpose: AppointmentPurpose.trial,
            durationMinutes: 90,
            fee: 150.0,
            isPaid: true,
            creditTowardBooking: true,
          ),
        );
      } else if (cat == ServiceCategoryType.boutiqueFashion) {
        _appointmentTypes.add(
          ServiceAppointmentType(
            id: 'apt-temp-fitting',
            serviceId: '',
            name: 'Bridal Fitting',
            description: 'Try on up to 5 designer gowns in our bridal suite.',
            purpose: AppointmentPurpose.fitting,
            durationMinutes: 45,
            fee: 50.0,
            isPaid: true,
            creditTowardBooking: true,
          ),
        );
      } else {
        _appointmentTypes.add(
          ServiceAppointmentType(
            id: 'apt-temp-consult',
            serviceId: '',
            name: '${cat.displayName} Consultation',
            description: '1-on-1 meeting to tailor service details and timeline.',
            purpose: AppointmentPurpose.consultation,
            durationMinutes: 45,
            fee: 0.0,
            isPaid: false,
          ),
        );
      }
    }
  }

  void _saveAndPublish() {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service category')),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a service name')),
      );
      setState(() => _currentStep = 1);
      return;
    }

    final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);
    final serviceId = widget.existingService?.id ?? 'srv-${DateTime.now().millisecondsSinceEpoch}';

    final startingPrice = double.tryParse(_startingPriceController.text) ??
        (_packages.isNotEmpty ? _packages.first.price : 500.0);

    final depositPercent = double.tryParse(_depositPercentController.text) ?? 30.0;

    final updatedService = CommonServiceInfo(
      id: serviceId,
      vendorId: provider.currentVendorId,
      vendorName: provider.currentVendorName,
      serviceName: _nameController.text.trim(),
      category: _selectedCategory!,
      subcategory: _subcategoryController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? 'Professional ${_selectedCategory!.displayName} service tailored for events.'
          : _descriptionController.text.trim(),
      serviceLocation: _locationController.text.trim(),
      serviceArea: _serviceAreaController.text.trim(),
      eventTypesSupported: _selectedEventTypes,
      tags: _tags,
      startingPrice: startingPrice,
      pricingModel: _pricingModel,
      availableDays: _availableDays,
      workingHoursStart: _workingHoursStart,
      workingHoursEnd: _workingHoursEnd,
      minBookingNoticeDays: _minBookingNoticeDays,
      maxBookingsPerDay: _maxBookingsPerDay,
      cancellationPolicy: _cancellationPolicyController.text.trim(),
      depositRequirementPercent: depositPercent,
      paymentSchedule: _paymentScheduleController.text.trim(),
      termsAndConditions: _termsController.text.trim(),
      status: _serviceStatus,
    );

    // Attach serviceId to packages & appointment types
    final savedPackages = _packages.map((p) => p.copyWith(serviceId: serviceId)).toList();
    final savedAppointments = _allowAppointments
        ? _appointmentTypes.map((a) => a.copyWith(serviceId: serviceId)).toList()
        : <ServiceAppointmentType>[];

    provider.saveService(
      service: updatedService,
      packages: savedPackages,
      appointmentTypes: savedAppointments,
      categoryData: _categoryFields,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.successColor,
        content: Text('Service "${updatedService.serviceName}" saved successfully!'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.existingService != null ? 'Edit Service' : 'Add New Service',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            onPressed: _saveAndPublish,
            icon: const Icon(Icons.check, color: AppTheme.primaryColor),
            label: const Text(
              'Publish',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildStepProgressHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildCurrentStepContent(),
            ),
          ),
          _buildBottomActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStepProgressHeader() {
    final steps = ['Category', 'Details & Dynamic', 'Packages', 'Appointments', 'Policies & Review'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = _currentStep > index;
          final isCurrent = _currentStep == index;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (_selectedCategory != null || index == 0) {
                  setState(() => _currentStep = index);
                }
              },
              child: Column(
                children: [
                  Row(
                    children: [
                      if (index > 0)
                        Expanded(
                          child: Container(
                            height: 3,
                            color: isCompleted ? AppTheme.primaryColor : Colors.grey.shade300,
                          ),
                        ),
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: isCompleted
                            ? AppTheme.primaryColor
                            : isCurrent
                                ? AppTheme.primaryColor
                                : Colors.grey.shade300,
                        child: isCompleted
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                      ),
                      if (index < steps.length - 1)
                        Expanded(
                          child: Container(
                            height: 3,
                            color: isCompleted ? AppTheme.primaryColor : Colors.grey.shade300,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1CategorySelector();
      case 1:
        return _buildStep2ServiceDetails();
      case 2:
        return _buildStep3Packages();
      case 3:
        return _buildStep4Appointments();
      case 4:
        return _buildStep5PoliciesAndReview();
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // STEP 1 — SERVICE TYPE / CATEGORY SELECTOR
  // ==========================================
  Widget _buildStep1CategorySelector() {
    final categories = ServiceCategoryType.values.where((c) {
      if (_categorySearchQuery.isEmpty) return true;
      return c.displayName.toLowerCase().contains(_categorySearchQuery.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What service are you offering?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
        ),
        const SizedBox(height: 6),
        const Text(
          'Select a category to automatically load category-specific fields, appointment models, and package presets.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 18),

        // Search Input
        TextField(
          controller: _categorySearchController,
          onChanged: (val) => setState(() => _categorySearchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search service categories (e.g. Photography, Catering)...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
            suffixIcon: _categorySearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _categorySearchController.clear();
                      setState(() => _categorySearchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Category Cards Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.15,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = _selectedCategory == cat;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  _setDefaultDefaultsForCategory(cat);
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? cat.brandColor.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? cat.brandColor : AppTheme.borderColor,
                    width: isSelected ? 2.2 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cat.brandColor.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: isSelected ? cat.brandColor : cat.brandColor.withOpacity(0.12),
                      child: Icon(
                        cat.iconData,
                        color: isSelected ? Colors.white : cat.brandColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      cat.displayName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? cat.brandColor : AppTheme.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        if (_selectedCategory != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedCategory!.brandColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _selectedCategory!.brandColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(_selectedCategory!.iconData, color: _selectedCategory!.brandColor, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected: ${_selectedCategory!.displayName}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _selectedCategory!.brandColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Category-specific parameters & appointment options are ready to configure in the next step.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedCategory!.brandColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => setState(() => _currentStep = 1),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // STEP 2 — COMMON & CATEGORY SPECIFIC FIELDS
  // ==========================================
  Widget _buildStep2ServiceDetails() {
    if (_selectedCategory == null) {
      return Center(
        child: Column(
          children: [
            const Text('Please select a category first.'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => setState(() => _currentStep = 0),
              child: const Text('Go to Step 1'),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _selectedCategory!.brandColor.withOpacity(0.12),
                  child: Icon(_selectedCategory!.iconData, color: _selectedCategory!.brandColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category: ${_selectedCategory!.displayName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Text(
                        'Common service parameters + dynamic category specifications',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- COMMON BASIC INFORMATION ---
          _buildSectionHeader('Common Basic Information', Icons.info_outline),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _nameController,
            label: 'Service Name *',
            hint: 'e.g. Signature Wedding Photography Collection, Grand Ballroom',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _subcategoryController,
                  label: 'Subcategory',
                  hint: 'e.g. Cinematic, Heritage Buffet, Bridal',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pricing Model', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<ServicePricingModel>(
                      value: _pricingModel,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: ServicePricingModel.values
                          .map((m) => DropdownMenuItem(value: m, child: Text(m.displayName, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _pricingModel = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _startingPriceController,
                  label: 'Starting Price (RM) *',
                  hint: 'e.g. 2500',
                  keyboardType: TextInputModelNumber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _locationController,
                  label: 'Service Location',
                  hint: 'e.g. Kuala Lumpur & Selangor',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _serviceAreaController,
            label: 'Service Area / Travel Radius',
            hint: 'e.g. Within 60km of Klang Valley, Nationwide travel available',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Describe your service, experience, deliverables, and what makes it extraordinary...',
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Supported Event Types
          const Text('Event Types Supported', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allEventTypes.map((type) {
              final isSel = _selectedEventTypes.contains(type);
              return FilterChip(
                label: Text(type),
                selected: isSel,
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedEventTypes.add(type);
                    } else {
                      _selectedEventTypes.remove(type);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // --- DYNAMIC CATEGORY-SPECIFIC FIELDS ---
          _buildSectionHeader('Category-Specific Fields: ${_selectedCategory!.displayName}', _selectedCategory!.iconData),
          const SizedBox(height: 14),
          _buildDynamicFieldsForCategory(_selectedCategory!),
        ],
      ),
    );
  }

  static const TextInputType TextInputModelNumber = TextInputType.number;

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
          ),
        ),
      ],
    );
  }

  // Dynamic Category Fields Builder
  Widget _buildDynamicFieldsForCategory(ServiceCategoryType cat) {
    switch (cat) {
      case ServiceCategoryType.photography:
        return _buildPhotographyFields();
      case ServiceCategoryType.catering:
        return _buildCateringFields();
      case ServiceCategoryType.decoration:
        return _buildDecorationFields();
      case ServiceCategoryType.makeupAndBeauty:
        return _buildMakeupFields();
      case ServiceCategoryType.entertainment:
        return _buildEntertainmentFields();
      case ServiceCategoryType.venue:
        return _buildVenueFields();
      case ServiceCategoryType.boutiqueFashion:
        return _buildBoutiqueFashionFields();
      default:
        return _buildGenericCategoryFields(cat);
    }
  }

  // 1. PHOTOGRAPHY DYNAMIC FIELDS
  Widget _buildPhotographyFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropDownField(
                  label: 'Photography Style',
                  keyName: 'photoStyle',
                  options: ['Candid / Documentary', 'Editorial / Fashion', 'Traditional', 'Cinematic', 'Fine Art'],
                  defaultValue: 'Cinematic',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropDownField(
                  label: 'Indoor / Outdoor',
                  keyName: 'indoorOutdoor',
                  options: ['Both Indoor & Outdoor', 'Indoor Only', 'Outdoor Only'],
                  defaultValue: 'Both Indoor & Outdoor',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleNumberField(label: 'Number of Photographers', keyName: 'photographerCount', initial: '2'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Coverage Duration (Hours)', keyName: 'coverageDurationHours', initial: '10'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleNumberField(label: 'Number of Edited Photos', keyName: 'editedPhotosCount', initial: '800'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Delivery Time (Days)', keyName: 'deliveryDays', initial: '21'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleNumberField(label: 'Extra Hour Price (RM)', keyName: 'extraHourPrice', initial: '300'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Second Photographer (RM)', keyName: 'secondPhotographerPrice', initial: '600'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          _buildCheckboxTile('Raw Unedited Files Included', 'rawFilesIncluded'),
          _buildCheckboxTile('Wedding Album Included', 'albumIncluded'),
          _buildCheckboxTile('Drone Aerial Photography Included', 'droneIncluded'),
          _buildCheckboxTile('Second Photographer Included in Base', 'secondPhotographerIncluded'),
        ],
      ),
    );
  }

  // 2. CATERING DYNAMIC FIELDS
  Widget _buildCateringFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropDownField(
                  label: 'Cuisine Type',
                  keyName: 'cuisineType',
                  options: ['Traditional Malay', 'Chinese Banquet', 'Indian / South Asian', 'Western / Fusion', 'International Buffet'],
                  defaultValue: 'Traditional Malay',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropDownField(
                  label: 'Service Style',
                  keyName: 'serviceStyle',
                  options: ['Buffet', 'Dome VIP Service', 'Plated Banquet', 'Packed Bento / Box'],
                  defaultValue: 'Buffet',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleNumberField(label: 'Price Per Person (RM)', keyName: 'pricePerPerson', initial: '65'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Serving Duration (Hours)', keyName: 'servingDurationHours', initial: '4'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleNumberField(label: 'Minimum Guests', keyName: 'minGuests', initial: '100'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Maximum Guests', keyName: 'maxGuests', initial: '2000'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSimpleNumberField(label: 'Number of Waitstaff Included', keyName: 'staffCount', initial: '10'),
          const SizedBox(height: 14),
          const Divider(),
          _buildCheckboxTile('100% Certified Halal Ingredients & Prep', 'isHalal', defaultVal: true),
          _buildCheckboxTile('Vegetarian / Vegan Options Available', 'isVegetarian', defaultVal: true),
          _buildCheckboxTile('Chafing Equipment & Linens Included', 'equipmentIncluded', defaultVal: true),
          _buildCheckboxTile('Full Setup & Teardown Included', 'setupCleanupIncluded', defaultVal: true),
          _buildCheckboxTile('Food Delivery & Logistics Included', 'deliveryIncluded', defaultVal: true),
        ],
      ),
    );
  }

  // 3. DECORATION DYNAMIC FIELDS
  Widget _buildDecorationFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropDownField(
                  label: 'Decoration Style',
                  keyName: 'decorStyle',
                  options: ['Modern Floral', 'Rustic Garden', 'Royal Traditional', 'Minimalist Boho', 'Grand Luxury Glam'],
                  defaultValue: 'Modern Floral',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Setup Time Required (Hours)', keyName: 'setupTimeHours', initial: '4'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSimpleTextField(label: 'Color Palette / Theme', keyName: 'colorTheme', initial: 'Champagne Gold, Dusty Rose, Ivory White'),
          const SizedBox(height: 14),
          const Divider(),
          _buildCheckboxTile('Main Stage / Dais (Pelamin) Included', 'stageIncluded', defaultVal: true),
          _buildCheckboxTile('Photo Backdrop / Photo Wall Included', 'backdropIncluded', defaultVal: true),
          _buildCheckboxTile('VIP Table Centerpieces Included', 'centerpiecesIncluded', defaultVal: true),
          _buildCheckboxTile('Walkway & Aisle Flower Stands Included', 'flowersIncluded', defaultVal: true),
          _buildCheckboxTile('Fairy Lights / Chandeliers / Ambience Lighting Included', 'lightingIncluded', defaultVal: true),
          _buildCheckboxTile('Teardown & Cleanup Included', 'teardownIncluded', defaultVal: true),
          _buildCheckboxTile('Custom Theme Adaptations Available', 'customizationAvailable', defaultVal: true),
        ],
      ),
    );
  }

  // 4. MAKEUP & BEAUTY DYNAMIC FIELDS
  Widget _buildMakeupFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropDownField(
                  label: 'Service Focus',
                  keyName: 'makeupFocus',
                  options: ['Bridal (Nikah / Sanding / Reception)', 'Dinner / Gala Event', 'Photoshoot & Fashion', 'Bridal Party Bundle'],
                  defaultValue: 'Bridal (Nikah / Sanding / Reception)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Makeup Duration (Minutes)', keyName: 'makeupDurationMinutes', initial: '90'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleNumberField(label: 'Number of People Included', keyName: 'peopleCount', initial: '1'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Additional Person Price (RM)', keyName: 'additionalPersonPrice', initial: '250'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleNumberField(label: 'Early Morning Fee (RM, if before 7am)', keyName: 'earlyMorningFee', initial: '100'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Touch-up / Extra Hour (RM)', keyName: 'touchUpPrice', initial: '150'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          _buildCheckboxTile('Hair Styling Included', 'hairIncluded', defaultVal: true),
          _buildCheckboxTile('False Eyelashes & Skin Ampoule Included', 'lashesIncluded', defaultVal: true),
          _buildCheckboxTile('Touch-up Kit Provided for Bride', 'touchUpKitIncluded', defaultVal: true),
          _buildCheckboxTile('Travel to Venue / Home Included', 'travelToVenue', defaultVal: true),
          _buildCheckboxTile('Trial Session Available', 'trialAvailable', defaultVal: true),
        ],
      ),
    );
  }

  // 5. ENTERTAINMENT DYNAMIC FIELDS
  Widget _buildEntertainmentFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropDownField(
                  label: 'Performer Type',
                  keyName: 'performerType',
                  options: ['Live Band (Acoustic / Full)', 'DJ & Emcee', 'Traditional Gamelan / Kompang', 'String Quartet', 'Solo Singer & Pianist'],
                  defaultValue: 'Live Band (Acoustic / Full)',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Number of Performers', keyName: 'performerCount', initial: '4'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleNumberField(label: 'Performance Duration (Minutes)', keyName: 'perfMinutes', initial: '180'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Number of Sets', keyName: 'setCount', initial: '3'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleNumberField(label: 'Overtime Rate Per Hour (RM)', keyName: 'overtimeRate', initial: '400'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Setup Time (Minutes)', keyName: 'setupMinutes', initial: '60'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          _buildCheckboxTile('Full PA Sound System Included', 'soundSystemIncluded', defaultVal: true),
          _buildCheckboxTile('Stage Lights & Mic System Included', 'lightingIncluded', defaultVal: true),
          _buildCheckboxTile('Song Requests & Playlist Customization Allowed', 'songRequestsAllowed', defaultVal: true),
          _buildCheckboxTile('Emcee / Hosting Service Included', 'emceeIncluded'),
        ],
      ),
    );
  }

  // 6. VENUE DYNAMIC FIELDS
  Widget _buildVenueFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropDownField(
                  label: 'Venue Type',
                  keyName: 'venueType',
                  options: ['Ballroom', 'Outdoor Garden', 'Glasshouse', 'Rooftop Lounge', 'Heritage Villa', 'Auditorium'],
                  defaultValue: 'Ballroom',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Maximum Guest Capacity', keyName: 'capacityGuests', initial: '800'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleNumberField(label: 'Parking Spaces Available', keyName: 'parkingSpaces', initial: '300'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Security Deposit (RM)', keyName: 'securityDeposit', initial: '2000'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleNumberField(label: 'Setup Buffer Time (Hours)', keyName: 'setupBufferHours', initial: '2'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Additional Hour Rate (RM)', keyName: 'additionalHourRate', initial: '800'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          _buildCheckboxTile('Banquet Tables & Chairs Included', 'tablesChairsIncluded', defaultVal: true),
          _buildCheckboxTile('Air Conditioning', 'airConditioning', defaultVal: true),
          _buildCheckboxTile('Built-in Sound System & Microphones', 'soundSystemIncluded', defaultVal: true),
          _buildCheckboxTile('LED Screen & Projectors Included', 'ledScreenIncluded', defaultVal: true),
          _buildCheckboxTile('Outside Catering Permitted', 'outsideCateringAllowed', defaultVal: true),
          _buildCheckboxTile('Outside Decorators Permitted', 'outsideVendorsAllowed', defaultVal: true),
          _buildCheckboxTile('Wheelchair & Handicap Accessible', 'accessibilityIncluded', defaultVal: true),
        ],
      ),
    );
  }

  // 7. BOUTIQUE / FASHION DYNAMIC FIELDS
  Widget _buildBoutiqueFashionFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropDownField(
                  label: 'Offering Model',
                  keyName: 'purchaseRentalCustom',
                  options: ['Rental Only', 'Purchase Only', 'Both Rental & Purchase', 'Bespoke Custom Tailoring'],
                  defaultValue: 'Rental Only',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Rental Duration (Days)', keyName: 'rentalDurationDays', initial: '4'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleNumberField(label: 'Rental Security Deposit (RM)', keyName: 'rentalDeposit', initial: '300'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleNumberField(label: 'Order Lead Time (Days)', keyName: 'leadTimeDays', initial: '30'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSimpleTextField(label: 'Available Sizes (e.g. XS, S, M, L, XL, Custom)', keyName: 'availableSizes', initial: 'S, M, L, XL, Plus Size'),
          const SizedBox(height: 14),
          const Divider(),
          _buildCheckboxTile('Appointment Required for Showroom Visits', 'appointmentRequired', defaultVal: true),
          _buildCheckboxTile('Fitting & Styling Session Available', 'fittingAvailable', defaultVal: true),
          _buildCheckboxTile('Basic Alteration Service Included', 'alterationAvailable', defaultVal: true),
          _buildCheckboxTile('Custom Body Measurement Taken On-site', 'customMeasurementAvailable', defaultVal: true),
          _buildCheckboxTile('Post-Rental Dry Cleaning Included', 'dryCleaningIncluded', defaultVal: true),
        ],
      ),
    );
  }

  // Fallback for other categories
  Widget _buildGenericCategoryFields(ServiceCategoryType cat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSimpleTextField(label: 'Specialty & Focus for ${cat.displayName}', keyName: 'specialty', initial: 'Event ${cat.displayName}'),
          const SizedBox(height: 12),
          _buildSimpleTextField(label: 'Equipment & Deliverables', keyName: 'deliverables', initial: 'Full standard package deliverables'),
          const SizedBox(height: 14),
          const Divider(),
          _buildCheckboxTile('On-site Setup Included', 'setupIncluded', defaultVal: true),
          _buildCheckboxTile('Custom Requirements Consultation Available', 'consultationAvailable', defaultVal: true),
        ],
      ),
    );
  }

  // Reusable helper widgets for dynamic form
  Widget _buildDropDownField({
    required String label,
    required String keyName,
    required List<String> options,
    required String defaultValue,
  }) {
    if (!_categoryFields.containsKey(keyName)) {
      _categoryFields[keyName] = defaultValue;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _categoryFields[keyName] as String? ?? defaultValue,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.backgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.borderColor)),
          ),
          items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _categoryFields[keyName] = val);
          },
        ),
      ],
    );
  }

  Widget _buildSimpleNumberField({required String label, required String keyName, required String initial}) {
    if (!_categoryFields.containsKey(keyName)) {
      _categoryFields[keyName] = initial;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initial,
          keyboardType: TextInputModelNumber,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.backgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.borderColor)),
          ),
          onChanged: (val) => _categoryFields[keyName] = val,
        ),
      ],
    );
  }

  Widget _buildSimpleTextField({required String label, required String keyName, required String initial}) {
    if (!_categoryFields.containsKey(keyName)) {
      _categoryFields[keyName] = initial;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initial,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.backgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.borderColor)),
          ),
          onChanged: (val) => _categoryFields[keyName] = val,
        ),
      ],
    );
  }

  Widget _buildCheckboxTile(String title, String keyName, {bool defaultVal = false}) {
    if (!_categoryFields.containsKey(keyName)) {
      _categoryFields[keyName] = defaultVal;
    }
    final isChecked = _categoryFields[keyName] as bool? ?? defaultVal;
    return CheckboxListTile(
      value: isChecked,
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      activeColor: AppTheme.primaryColor,
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (val) {
        setState(() => _categoryFields[keyName] = val ?? false);
      },
    );
  }

  // ==========================================
  // STEP 3 — SERVICE PACKAGES (Part 2 of spec)
  // ==========================================
  Widget _buildStep3Packages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Tier Packages',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Create multiple package options (e.g. Essential, Premium, Luxury)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _showAddPackageDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Package'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_packages.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No Packages Created Yet', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Create tiered packages to give your customers flexible choices.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _showAddPackageDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create First Package'),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _packages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final pkg = _packages[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Tier ${index + 1}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              pkg.packageName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          'RM ${pkg.price.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(pkg.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(pkg.duration, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        if (pkg.extraHourPrice > 0) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.add_alarm, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('Extra hour: RM ${pkg.extraHourPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        ],
                      ],
                    ),
                    if (pkg.includedServices.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: pkg.includedServices.map((inc) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check, size: 12, color: AppTheme.successColor),
                                const SizedBox(width: 4),
                                Text(inc, style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() => _packages.removeAt(index));
                          },
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.errorColor),
                          label: const Text('Delete', style: TextStyle(color: AppTheme.errorColor, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAddPackageDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durCtrl = TextEditingController(text: '8 hours');
    final inclusionsCtrl = TextEditingController();
    final extraHourCtrl = TextEditingController(text: '250');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Service Package Tier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Package Name (e.g. Essential, Premium, Luxury)'),
              ),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputModelNumber,
                decoration: const InputDecoration(labelText: 'Price (RM)'),
              ),
              TextField(
                controller: durCtrl,
                decoration: const InputDecoration(labelText: 'Duration (e.g. 8 hours, 4 days)'),
              ),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Package Summary'),
              ),
              TextField(
                controller: inclusionsCtrl,
                decoration: const InputDecoration(labelText: 'Included Features (comma-separated)'),
              ),
              TextField(
                controller: extraHourCtrl,
                keyboardType: TextInputModelNumber,
                decoration: const InputDecoration(labelText: 'Extra Hour Rate (RM)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                final inclusions = inclusionsCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                setState(() {
                  _packages.add(
                    ServicePackageItem(
                      id: 'pkg-${DateTime.now().millisecondsSinceEpoch}',
                      serviceId: '',
                      packageName: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      price: double.tryParse(priceCtrl.text) ?? 1000.0,
                      duration: durCtrl.text.trim(),
                      includedServices: inclusions,
                      extraHourPrice: double.tryParse(extraHourCtrl.text) ?? 0.0,
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Package'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 4 — APPOINTMENTS CONFIGURATION (Part 3 of spec)
  // ==========================================
  Widget _buildStep4Appointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Toggle Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Allow customers to book appointments for this service',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Appointments are pre-booking interactions (Food tasting, Venue tour, Dress fitting, Makeup trial, Consultations).',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _allowAppointments,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) => setState(() => _allowAppointments = val),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_allowAppointments) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Configured Appointment Types',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _showAddAppointmentTypeDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('+ Add Appointment Type'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_appointmentTypes.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('No Appointment Types Configured', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Offer food tastings, fitting sessions, site visits, or consultations.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _showAddAppointmentTypeDialog, child: const Text('+ Add Appointment Type')),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _appointmentTypes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final appt = _appointmentTypes[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                child: Icon(appt.purpose.iconData, size: 16, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appt.name,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Purpose: ${appt.purpose.displayName}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: appt.fee > 0 ? Colors.amber.shade50 : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              appt.fee > 0 ? 'RM ${appt.fee.toStringAsFixed(0)}' : 'Free',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: appt.fee > 0 ? Colors.amber.shade800 : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(appt.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('${appt.durationMinutes} min', style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 16),
                          Icon(Icons.group_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text('Max ${appt.maxParticipants} pax', style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 16),
                          Icon(Icons.place_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(child: Text(appt.location, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      if (appt.creditTowardBooking) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 12, color: Colors.blue),
                              SizedBox(width: 4),
                              Text(
                                'Fee is credited toward final service booking',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                            onPressed: () => setState(() => _appointmentTypes.removeAt(index)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ],
    );
  }

  void _showAddAppointmentTypeDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '60');
    final feeCtrl = TextEditingController(text: '0');
    final locCtrl = TextEditingController(text: 'Vendor Studio');
    final maxPaxCtrl = TextEditingController(text: '4');
    AppointmentPurpose selectedPurpose = AppointmentPurpose.consultation;
    bool creditToward = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Appointment Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Appointment Name *', hintText: 'e.g. Food Tasting, Site Visit, Test Fitting'),
                ),
                const SizedBox(height: 10),
                const Text('Purpose', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                DropdownButtonFormField<AppointmentPurpose>(
                  value: selectedPurpose,
                  items: AppointmentPurpose.values
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.displayName, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedPurpose = val);
                  },
                ),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description / What to Expect'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationCtrl,
                        keyboardType: TextInputModelNumber,
                        decoration: const InputDecoration(labelText: 'Duration (Min)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxPaxCtrl,
                        keyboardType: TextInputModelNumber,
                        decoration: const InputDecoration(labelText: 'Max Pax'),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: feeCtrl,
                        keyboardType: TextInputModelNumber,
                        decoration: const InputDecoration(labelText: 'Fee (RM, 0 for free)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: locCtrl,
                        decoration: const InputDecoration(labelText: 'Location Type'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: creditToward,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Credit fee toward service booking', style: TextStyle(fontSize: 12)),
                  subtitle: const Text('If booked, the fee paid will be deducted from the customer final total.', style: TextStyle(fontSize: 10)),
                  onChanged: (val) => setDialogState(() => creditToward = val ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final fee = double.tryParse(feeCtrl.text) ?? 0.0;
                  setState(() {
                    _appointmentTypes.add(
                      ServiceAppointmentType(
                        id: 'appt-${DateTime.now().millisecondsSinceEpoch}',
                        serviceId: '',
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        purpose: selectedPurpose,
                        durationMinutes: int.tryParse(durationCtrl.text) ?? 60,
                        location: locCtrl.text.trim(),
                        maxParticipants: int.tryParse(maxPaxCtrl.text) ?? 4,
                        fee: fee,
                        isPaid: fee > 0,
                        creditTowardBooking: creditToward,
                      ),
                    );
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add Type'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // STEP 5 — POLICIES, AVAILABILITY & REVIEW
  // ==========================================
  Widget _buildStep5PoliciesAndReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Availability & Notice', Icons.access_time),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Operating Working Days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                  final isSel = _availableDays.contains(day);
                  return ChoiceChip(
                    label: Text(day),
                    selected: isSel,
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _availableDays.add(day);
                        } else {
                          _availableDays.remove(day);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Min Notice (Days)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          initialValue: _minBookingNoticeDays.toString(),
                          keyboardType: TextInputModelNumber,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) => _minBookingNoticeDays = int.tryParse(val) ?? 7,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Max Bookings / Day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          initialValue: _maxBookingsPerDay.toString(),
                          keyboardType: TextInputModelNumber,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.backgroundColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) => _maxBookingsPerDay = int.tryParse(val) ?? 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        _buildSectionHeader('Policies & Payments', Icons.policy_outlined),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _depositPercentController,
                label: 'Deposit Requirement (%)',
                hint: 'e.g. 30',
                keyboardType: TextInputModelNumber,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _paymentScheduleController,
                label: 'Payment Schedule',
                hint: 'e.g. 30% deposit upon confirmation, 70% 3 days before event.',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _cancellationPolicyController,
                label: 'Cancellation Policy',
                hint: 'Specify refund conditions and timeline.',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _termsController,
                label: 'Terms & Conditions',
                hint: 'Specify terms of service.',
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Service Publishing Status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Service Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(
                    _serviceStatus == ServiceStatus.published
                        ? 'Visible to marketplace customers'
                        : 'Saved privately as draft',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              DropdownButton<ServiceStatus>(
                value: _serviceStatus,
                underline: const SizedBox.shrink(),
                items: ServiceStatus.values.map((st) {
                  return DropdownMenuItem(
                    value: st,
                    child: Row(
                      children: [
                        CircleAvatar(radius: 5, backgroundColor: st.color),
                        const SizedBox(width: 8),
                        Text(st.displayName, style: TextStyle(fontWeight: FontWeight.bold, color: st.color)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _serviceStatus = val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('Back'),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (_currentStep < 4) {
                if (_currentStep == 0 && _selectedCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a category to continue')),
                  );
                  return;
                }
                setState(() => _currentStep++);
              } else {
                _saveAndPublish();
              }
            },
            child: Text(_currentStep < 4 ? 'Next Step' : 'Save & Publish Service'),
          ),
        ],
      ),
    );
  }
}
