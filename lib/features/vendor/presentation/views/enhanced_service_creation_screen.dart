import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/services/service_enums.dart';
import '../../../../shared/models/event/event_category.dart';
import '../../../../shared/models/services/service_category.dart'; // Added
import '../../../../features/event/data/models/event_type.dart';
import '../../models/vendor_service_enhanced.dart';
import '../../models/vendor_service.dart';
import '../../data/providers/vendor_provider_updated.dart';
import '../../../../core/services/ai_extraction_service.dart';
import '../../data/providers/subscription_provider.dart';
import '../widgets/service_review_summary.dart';
import '../widgets/calendar_availability_widget.dart';
import '../../../../shared/models/services/service_time_rule.dart';
import '../../../../shared/models/services/service_logistics.dart';
import '../../models/service_template_models.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'package:eventease/core/utils/app_theme.dart';
import '../../../../shared/models/region.dart';
import 'package:eventease/shared/utils/constants/image_constants.dart';
import 'package_component_config_screen.dart'; // Added
import 'package:eventease/core/utils/location_helper.dart';
import 'package:eventease/core/utils/currency_formatter.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';

// --- ENUMS & MODELS ---

enum AvailabilityMode { daily, hourly, slotBased, sessionBased }

enum SessionType { morning, afternoon, evening, night, fullDay }

enum CateringStyle { flat, simpleSets, complexSets }

class TimeSlot {
  TimeOfDay startTime;
  TimeOfDay endTime;
  String name;
  double? price;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.name,
    this.price,
  });
}

class VariationGroup {
  String name;
  List<String> options;
  Map<String, double> optionPrices;
  VariationGroup({
    required this.name,
    required this.options,
    Map<String, double>? optionPrices,
  }) : optionPrices = optionPrices ?? {};
}

enum AddOnPricingType { fixed, perPax, perUnit, perHour }

class AddOn {
  String name;
  String description;
  double price;
  int? maxQuantity;
  bool isRequired;
  AddOnPricingType pricingType;
  bool isFree;

  AddOn({
    required this.name,
    required this.description,
    required this.price,
    this.maxQuantity,
    this.isRequired = false,
    this.pricingType = AddOnPricingType.fixed,
    this.isFree = false,
  });
}

// --- MAIN SCREEN ---

class EnhancedServiceCreationScreen extends StatefulWidget {
  final VendorServiceEnhanced? existingService;
  final String vendorId;

  const EnhancedServiceCreationScreen({
    super.key,
    this.existingService,
    required this.vendorId,
  });

  @override
  State<EnhancedServiceCreationScreen> createState() =>
      _EnhancedServiceCreationScreenState();
}

class _EnhancedServiceCreationScreenState
    extends State<EnhancedServiceCreationScreen> {
  int _currentStep = 0;
  // Structured Service Template State
  List<ServicePricingTier> _pricingTiers = [];
  List<ServiceComponent> _components = [];

  // Existing state variables...
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController(); // Added for universal promo
  DateTime? _promoExpiry; // Added for universal promo
  final _weekendPriceController = TextEditingController(); // Added
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _googleMapsController = TextEditingController();
  final List<VariationGroup> _variations = [];
  final List<AddOn> _addOns = [];
  final List<String> _includedServices = [];
  final List<String> _selectedExistingServices = [];
  final List<EventCategory> _includedCategories = [];
  final Map<String, TextEditingController> _categoryAttributes = {};
  final Map<EventCategory, Map<String, TextEditingController>>
  _includedCategoryAttributes = {};
  
  // Per Event Type Pricing
  final Map<String, TextEditingController> _eventPricingControllers = {};

  // Facilities for venue services
  final List<String> _facilities = [];

  // Multi-tier / Pax Pricing
  // _multiLayerPricing is legacy, mapped to _pricingTiers internally now
  Map<String, double> _multiLayerPricing = {}; 
  final _paxCountController = TextEditingController();
  final _paxPriceController = TextEditingController();
  final _paxOriginalPriceController = TextEditingController();
  DateTime? _paxPromoExpiry;
  
  // Duration
  final _durationValueController = TextEditingController();
  String _durationUnit = 'Hours'; // Default to Hours

  // Image & Video handling
  final List<String> _serviceImages = [];
  String? _serviceVideoUrl; // Added
  bool _isUploadingVideo = false; // Added
  String? _servicePdfUrl; // Added for PDF upload
  bool _isUploadingPdf = false; // Added for PDF upload
  bool _isExtractingAiData = false; // Added for AI auto-fill
  final ImagePicker _imagePicker = ImagePicker();

  // Cancellation Policy
  String _cancellationPolicyType = 'platform';
  final _cancellationPolicyController = TextEditingController();

  // Local Categories list to handle fallbacks
  List<ServiceCategory> _localCategories = [];

  ServiceType? _selectedType;
  PricingMode? _selectedPricing;
  ServiceCategory? _selectedCategory; // Changed from EventCategory
  String? _selectedSubcategory;
  VenueType? _selectedVenueType; // Added
  bool _showPrice = true;
  bool _directoryShowcaseOnly = false;
  bool _hasWeekendPricing = false; // Added
  bool _isRentable = false;
  int _minQty = 1;
  int _maxQty = 1;
  int _stockQuantity = 0;
  CateringStyle _cateringStyle = CateringStyle.flat;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  List<DateTime> _blockedDates = [];
  Map<String, bool> _availableDays = {
    'monday': true,
    'tuesday': true,
    'wednesday': true,
    'thursday': true,
    'friday': true,
    'saturday': false,
    'sunday': false,
  };

  // Availability Mode
  AvailabilityMode _availabilityMode = AvailabilityMode.daily;
  List<TimeSlot> _timeSlots = [];
  Map<String, TimeOfDay> _hourlyAvailability = {};
  Map<String, bool> _dayAvailability = {
    'monday': true,
    'tuesday': true,
    'wednesday': true,
    'thursday': true,
    'friday': true,
    'saturday': false,
    'sunday': false,
  };
  
  // Event Types for Venue
  final List<String> _eventTypes = [];

  // Calendar-based availability (new)
  Set<DateTime> _availableDates = {};
  Set<DateTime> _unavailableDates = {};
  bool _useWhitelist = false; // false = all available except blocked, true = only listed available

  bool _isSaving = false;
  bool _isDetectingLocation = false;

  // Service Time Rules (New Platform Architecture)
  TimeType _selectedTimeType = TimeType.fullDay;
  final _slotDurationController = TextEditingController(text: '60');
  final _minDurationController = TextEditingController(text: '60');
  final _maxDurationController = TextEditingController(text: '480');
  final _durationStepController = TextEditingController(text: '60');
  final _bufferBeforeController = TextEditingController(text: '0');
  final _bufferAfterController = TextEditingController(text: '0');
  final List<ServiceSession> _serviceSessions = [];
  bool _allowMultiDayBooking = false;
  final _maxDaysController = TextEditingController(text: '1');
  final _fullDayStartController = TextEditingController(text: '08:00');
  final _fullDayEndController = TextEditingController(text: '23:00');

  // Logistics & Operations (New Platform Architecture)
  bool _requiresVehicle = false;
  VehicleType _selectedVehicleType = VehicleType.van;
  final _crewCountController = TextEditingController(text: '1');
  final _setupTimeController = TextEditingController(text: '1.0');
  final _teardownTimeController = TextEditingController(text: '1.0');
  final _freeRadiusController = TextEditingController(text: '20.0');
  final _perKmRateController = TextEditingController(text: '0.0');
  String? _primaryState;
  bool _parkingRequired = false;
  bool _powerRequired = false;
  bool _overnightRequired = false;
  final _nightSurchargeController = TextEditingController(text: '0.0');
  final _tollPolicyController = TextEditingController(text: 'Vendor to claim reimbursement from customer for tolls & parking as per receipt.');
  final _minOrderForFreeDeliveryController = TextEditingController(text: '0.0');

  bool _isActive = true; // Added for status toggle
  
  // Service Areas (internationalized - free text + detect location)
  List<String> _selectedServiceAreas = [];

  // Installment Settings
  bool _installmentEnabled = false;
  final _depositPercentageController = TextEditingController();
  final _maxInstallmentsController = TextEditingController();
  final _paymentDeadlineDaysController = TextEditingController();

  // -- Product / Rental: Delivery & Pickup --
  bool _hasDelivery = true;
  bool _hasSelfPickup = false;
  String _deliveryFeeType = 'fixed'; // 'free', 'fixed', 'per_km'
  final _deliveryFeeController = TextEditingController(text: '0.0');
  final _freeDeliveryThresholdController = TextEditingController(text: '0.0');
  final _estimatedDaysController = TextEditingController(text: '3');
  final _pickupAddressController = TextEditingController();
  final _pickupHoursController = TextEditingController(text: 'Mon–Fri, 9am–5pm');

  // -- Rental specific --
  final _rentalDepositController = TextEditingController(text: '0.0');
  bool _hasDamageWaiver = false;
  final _damageWaiverPctController = TextEditingController(text: '5.0');
  final _returnConditionController = TextEditingController();

  // -- Bulk Pricing --
  bool _bulkPricingEnabled = false;
  final List<Map<String, dynamic>> _bulkPricingTiers = [];

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_enforceInstallmentRules);
    // Initialize active status
    if (widget.existingService != null) {
      _isActive = widget.existingService!.isActive;
    }
    
    // Load dynamic categories and check limits before allowing creation
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.existingService == null) {
         final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
         final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
         final vendorId = vendorProvider.currentVendor?.id;
         
         if (vendorId != null) {
           await subscriptionProvider.loadSubscriptionData(vendorId);
           final maxListings = subscriptionProvider.maxListings;
           final currentListings = vendorProvider.getServicesForVendor(vendorId).length;
           
           if (maxListings != -1 && currentListings >= maxListings) {
             if (mounted) {
               showDialog(
                 context: context,
                 barrierDismissible: false,
                 builder: (context) => AlertDialog(
                   title: const Text('Limit Reached'),
                   content: Text('Your current plan allows up to $maxListings services. Please upgrade your subscription to add more.'),
                   actions: [
                     ElevatedButton(
                       onPressed: () {
                         Navigator.of(context).pop();
                         Navigator.of(context).pop(); // Go back to dashboard
                       },
                       child: const Text('Okay'),
                     )
                   ],
                 ),
               );
             }
             return;
           }
         }
      }

      Provider.of<VendorProvider>(context, listen: false).loadServiceCategories().then((_) {
        // Safe to populate default values now that list is loaded
        _initializeExistingService();
      });
    });
  }

  @override
  void dispose() {
    _priceController.removeListener(_enforceInstallmentRules);
    
    // Dispose all standard controllers
    final controllers = [
      _nameController, _priceController, _originalPriceController, _weekendPriceController,
      _descController, _locationController, _cityController, _stateController,
      _googleMapsController, _paxCountController, _paxPriceController, _paxOriginalPriceController,
      _durationValueController, _cancellationPolicyController, _slotDurationController,
      _minDurationController, _maxDurationController, _durationStepController,
      _bufferBeforeController, _bufferAfterController, _maxDaysController,
      _fullDayStartController, _fullDayEndController, _crewCountController,
      _setupTimeController, _teardownTimeController, _freeRadiusController,
      _perKmRateController, _nightSurchargeController, _tollPolicyController,
      _minOrderForFreeDeliveryController, _depositPercentageController,
      _maxInstallmentsController, _paymentDeadlineDaysController,
      _deliveryFeeController, _freeDeliveryThresholdController,
      _estimatedDaysController, _pickupAddressController, _pickupHoursController,
      _rentalDepositController, _damageWaiverPctController, _returnConditionController,
    ];
    for (var c in controllers) {
      c.dispose();
    }
    
    // Dispose controller maps
    for (var c in _categoryAttributes.values) {
      c.dispose();
    }
    for (var map in _includedCategoryAttributes.values) {
      for (var c in map.values) {
        c.dispose();
      }
    }
    for (var c in _eventPricingControllers.values) {
      c.dispose();
    }

    super.dispose();
  }

  double _getMaxPrice() {
    double maxPrice = double.tryParse(_priceController.text) ?? 0.0;
    
    // Check tiers (used for both TIERED and PER PAX modes in newer structure)
    for (var tier in _pricingTiers) {
      if (tier.price > maxPrice) {
        maxPrice = tier.price;
      }
    }

    // Check legacy multiLayerPricing map
    for (var price in _multiLayerPricing.values) {
      if (price > maxPrice) {
        maxPrice = price;
      }
    }

    // Check event-specific pricing
    for (var controller in _eventPricingControllers.values) {
       final p = double.tryParse(controller.text) ?? 0.0;
       if (p > maxPrice) {
         maxPrice = p;
       }
    }

    return maxPrice;
  }

  void _enforceInstallmentRules() {
    final maxPrice = _getMaxPrice();

    setState(() {
      if (maxPrice > 0 && maxPrice < 1000) {
        // Rule: < CurrencyFormatter.symbol 1,000 - Full Payment required
        _installmentEnabled = false;
      } else if (maxPrice > 5000) {
        // Rule: > CurrencyFormatter.symbol 5,000 - Installment recommended/required
        if (!_installmentEnabled) {
          _installmentEnabled = true;
          _depositPercentageController.text = '30';
          _maxInstallmentsController.text = '3';
          _paymentDeadlineDaysController.text = '14';
          
          // Notify the user if they are currently looking at the screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Installments auto-enabled for services > ${CurrencyFormatter.symbol} 5,000'),
                  backgroundColor: AppTheme.primaryColor,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          });
        }
      }
    });
  }

  EventCategory _mapToEventCategory(ServiceCategory? category) {
    if (category == null) return EventCategory.package;
    
    final categoryNameLower = category.name.toLowerCase();
    final categoryIdLower = category.id.toLowerCase();
    
    // Try to find exact match by ID or name
    for (var eventCat in EventCategory.values) {
      final eventNameLower = eventCat.name.toLowerCase();
      final eventDisplayLower = eventCat.displayName.toLowerCase();
      final eventIdLower = eventCat.id.toLowerCase();
      
      // Exact matches
      if (categoryIdLower == eventIdLower ||
          categoryNameLower == eventNameLower ||
          categoryNameLower == eventDisplayLower) {
        return eventCat;
      }
      
      // Handle plural/singular variations (e.g., "Venues" -> "Venue")
      if (categoryNameLower.endsWith('s') && categoryNameLower.substring(0, categoryNameLower.length - 1) == eventNameLower) {
        return eventCat;
      }
      if (eventNameLower.endsWith('s') && eventNameLower.substring(0, eventNameLower.length - 1) == categoryNameLower) {
        return eventCat;
      }
      if (categoryNameLower.endsWith('s') && categoryNameLower.substring(0, categoryNameLower.length - 1) == eventDisplayLower) {
        return eventCat;
      }
      if (eventDisplayLower.endsWith('s') && eventDisplayLower.substring(0, eventDisplayLower.length - 1) == categoryNameLower) {
        return eventCat;
      }
    }
    
    print('WARNING: No EventCategory match found for "${category.name}" (ID: ${category.id}), defaulting to other');
    return EventCategory.other;
  }

  /// Check if package includes service-based categories that need availability
  bool _packageNeedsAvailability() {
    if (_selectedType != ServiceType.package) return false;
    
    // Service-based categories that typically need availability settings
    const serviceCategoryNames = [
      'venue',
      'catering',
      'photography',
      'videography',
      'entertainment',
      'decoration',
      'makeup',
      'transportation',
    ];
    
    // Check if any included category is service-based
    for (var category in _includedCategories) {
      final categoryName = category.name.toLowerCase();
      if (serviceCategoryNames.any((name) => categoryName.contains(name))) {
        return true;
      }
    }
    
    return false;
  }

  CategoryType? _mapServiceTypeToCategoryType(ServiceType? type) {
    if (type == null) return null;
    switch (type) {
      case ServiceType.service:
      case ServiceType.consultation:
        return CategoryType.service;
      case ServiceType.product:
        return CategoryType.product;
      case ServiceType.rental:
        return CategoryType.rental;
      case ServiceType.package:
        return CategoryType.package;
      default:
        return CategoryType.service;
    }
  }

  void _initializeExistingService() {
    if (widget.existingService != null) {
      final service = widget.existingService!;
      _nameController.text = service.name;
      _priceController.text = service.price.toString();
      _originalPriceController.text = service.originalPrice?.toString() ?? '';
      _promoExpiry = service.promoExpiry;
      _descController.text = service.description;
      
      // Initialize Type
      _selectedType = service.serviceType;
      
      // Load Structured Template Data
      _pricingTiers = List.from(service.pricingTiers);
      _components = List.from(service.components.map((c) => c.copyWith(items: List.from(c.items))));

      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      _localCategories = List.from(vendorProvider.serviceCategories);
      
      // 1. Try to find match in existing list
      ServiceCategory? matchedCategory;
      try {
        if (_localCategories.isNotEmpty) {
           matchedCategory = _localCategories.firstWhere(
            (c) => 
                c.id.toLowerCase() == service.productCategory.name.toLowerCase() ||
                c.name.toLowerCase() == service.productCategory.displayName.toLowerCase() ||
                c.id.toLowerCase() == service.productCategory.id.toLowerCase(),
            orElse: () => _localCategories.firstWhere(
                (c) => c.name.toLowerCase().contains(service.productCategory.displayName.toLowerCase()),
                orElse: () => _localCategories.first
            ),
          );
        }
      } catch (e) {
        print("Error matching category: $e");
      }

      // 2. If no match or empty, create fallback and add to local list
      if (matchedCategory == null) {
          matchedCategory = ServiceCategory(
            id: service.productCategory.id,
            name: service.productCategory.displayName,
            slug: service.productCategory.id.toLowerCase().replaceAll(' ', '-'),
            description: 'Service Category',
            categoryType: CategoryType.service,
            pricingModel: PricingModel.fixed,
            icon: service.productCategory.icon,
            color: Colors.blue, // Default color
          );
          _localCategories.add(matchedCategory);
      } else {
        // Subcategories are no longer part of ServiceCategory model
        // They are managed separately via event_type_categories table
      }

      setState(() {
        _selectedCategory = matchedCategory;
      });
      
      // Initialize Subcategory
      if (service.subcategory != null) {
         setState(() {
           _selectedSubcategory = service.subcategory;
         });
      }

      // Initialize Venue Type
      if (service.options.containsKey('venueType')) {
        try {
          setState(() {
            _selectedVenueType = VenueType.values.firstWhere(
              (e) => e.name == service.options['venueType'],
              orElse: () => VenueType.other,
            );
          });
        } catch (_) {}
      }

      _showPrice = service.price > 0;
      _directoryShowcaseOnly = !(service.allowedActions.contains('book') || 
                                 service.allowedActions.contains('buy') || 
                                 service.allowedActions.contains('rent'));
      _isRentable = service.supportsRentals ?? false;
      _stockQuantity = service.inventory;
      _availableDays = Map<String, bool>.from(
        service.availability.map(
          (key, value) => MapEntry(key, value['available'] ?? false),
        ),
      );

      // Initialize images & video
      _serviceImages.clear();
      _serviceImages.addAll(service.images);
      _serviceVideoUrl = service.videoUrl; // Added
      _servicePdfUrl = service.options['pdfBrochureUrl']; // Added for PDF upload

      _locationController.text = service.venueAddress ?? '';
      
      // Parse coverage areas
      if (service.coverageArea != null && service.coverageArea!.isNotEmpty) {
        _selectedServiceAreas = service.coverageArea!
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        _selectedServiceAreas = [];
      }
      
      if (service.logistics['city'] != null) {
        _cityController.text = service.logistics['city'];
      }
      if (service.logistics['state'] != null) {
        _stateController.text = service.logistics['state'];
      }
      if (service.logistics['googleMapEmbed'] != null) {
        _googleMapsController.text = service.logistics['googleMapEmbed'];
      }

      _cancellationPolicyType = service.cancellationPolicyType;
      if (service.cancellationPolicy != null) {
        _cancellationPolicyController.text = service.cancellationPolicy!;
      }

      _multiLayerPricing = Map<String, double>.from(service.multiLayerPricing);
      if (_multiLayerPricing.isNotEmpty && _selectedPricing == null) {
        if (_selectedType == ServiceType.package) {
          _selectedPricing = PricingMode.perPax;
        }
      }
      
      // MIGRATION: If we have legacy multiLayerPricing but no tiers, convert them
      if (_pricingTiers.isEmpty && _multiLayerPricing.isNotEmpty) {
        _multiLayerPricing.forEach((pax, price) {
          _pricingTiers.add(ServicePricingTier(
            id: const Uuid().v4(), // Generate a unique ID if migrating
            name: "$pax Pax",
            price: price,
            minPax: int.tryParse(pax) ?? 1,
            maxPax: int.tryParse(pax) ?? 1,
          ));
        });
      } else {
        // Ensure all loaded tiers have IDs for UI state management (FilterChip selection)
        bool modified = false;
        for (int i = 0; i < _pricingTiers.length; i++) {
          if (_pricingTiers[i].id == null) {
            _pricingTiers[i] = ServicePricingTier(
              id: const Uuid().v4(),
              serviceId: _pricingTiers[i].serviceId,
              name: _pricingTiers[i].name,
              minPax: _pricingTiers[i].minPax,
              maxPax: _pricingTiers[i].maxPax,
              price: _pricingTiers[i].price,
              originalPrice: _pricingTiers[i].originalPrice,
              promoExpiry: _pricingTiers[i].promoExpiry,
              description: _pricingTiers[i].description,
            );
            modified = true;
          }
        }
        if (modified) {
          debugPrint("Added missing IDs to ${_pricingTiers.length} pricing tiers");
        }
      }

      if (service.options != null) {
        if (service.options!['pricingMode'] != null) {
          _selectedPricing = PricingMode.values.firstWhere(
            (m) => m.name == service.options!['pricingMode'],
            orElse: () => _selectedPricing ?? PricingMode.flatRate,
          );
        }

        if (service.options!['cateringStyle'] != null) {
          _cateringStyle = CateringStyle.values.firstWhere(
            (s) => s.name == service.options!['cateringStyle'],
            orElse: () => CateringStyle.flat,
          );
        }

        if (service.options!['weekendPrice'] != null) {
          _hasWeekendPricing = true;
          _weekendPriceController.text = service.options!['weekendPrice'].toString();
        }

        if (service.options!['variations'] != null) {
          final variations = Map<String, dynamic>.from(
              service.options!['variations'] as Map);
          _variations.clear();
          _variations.addAll(
            variations.entries.map((entry) {
              final varData = Map<String, dynamic>.from(entry.value as Map);
              return VariationGroup(
                name: entry.key,
                options: List<String>.from(varData['options'] ?? []),
                optionPrices: Map<String, double>.from(varData['prices'] ?? {}),
              );
            }),
          );
        }

        if (service.options!['addOns'] != null) {
          final addOns = Map<String, dynamic>.from(
              service.options!['addOns'] as Map);
          _addOns.clear();
          _addOns.addAll(
            addOns.entries.map((entry) {
              final addOnData = Map<String, dynamic>.from(entry.value as Map);
              return AddOn(
                name: entry.key,
                description: addOnData['description'] ?? '',
                price: addOnData['price'] ?? 0.0,
                maxQuantity: addOnData['maxQuantity'],
                isRequired: addOnData['required'] ?? false,
              );
            }),
          );
        }

        _eventTypes.clear();
        if (service.eventTypes.isNotEmpty) {
           _eventTypes.addAll(service.eventTypes);
        } else if (service.options['eventTypes'] != null) {
          _eventTypes.addAll(List<String>.from(service.options['eventTypes']));
        }

        // Load delivery logistics
        if (service.options['delivery'] is Map) {
          final delivery = Map<String, dynamic>.from(service.options['delivery'] as Map);
          _hasDelivery = delivery['hasDelivery'] ?? true;
          _hasSelfPickup = delivery['hasSelfPickup'] ?? false;
          _deliveryFeeType = delivery['deliveryFeeType'] ?? 'fixed';
          _deliveryFeeController.text = (delivery['deliveryFee'] ?? 0.0).toString();
          _freeDeliveryThresholdController.text = (delivery['freeDeliveryThreshold'] ?? 0.0).toString();
          _estimatedDaysController.text = (delivery['estimatedDays'] ?? 3).toString();
          _pickupAddressController.text = delivery['pickupAddress'] ?? '';
          _pickupHoursController.text = delivery['pickupHours'] ?? 'Mon–Fri, 9am–5pm';
          _rentalDepositController.text = (delivery['rentalDeposit'] ?? 0.0).toString();
          _hasDamageWaiver = delivery['hasDamageWaiver'] ?? false;
          _damageWaiverPctController.text = (delivery['damageWaiverPct'] ?? 5.0).toString();
          _returnConditionController.text = delivery['returnCondition'] ?? '';
        }
        // Load bulk pricing
        if (service.options['bulkPricing'] is Map) {
          final bp = Map<String, dynamic>.from(service.options['bulkPricing'] as Map);
          _bulkPricingEnabled = bp['enabled'] ?? false;
          if (bp['tiers'] is List) {
            _bulkPricingTiers.clear();
            _bulkPricingTiers.addAll(
              (bp['tiers'] as List).map((t) => Map<String, dynamic>.from(t as Map)));
          }
        }

        if (service.options!['duration'] != null) {
          _durationValueController.text = service.options!['duration'].toString();
        }
        if (service.options!['durationUnit'] != null) {
           _durationUnit = service.options!['durationUnit'];
        }

        if (service.options!['facilities'] != null) {
          _facilities.clear();
          _facilities.addAll(List<String>.from(service.options!['facilities']));
        }

        if (service.options!['timeSlots'] is List) {
          final slots = service.options!['timeSlots'] as List;
          _timeSlots.clear();
          _timeSlots.addAll(slots.map((s) {
            final slot = Map<String, dynamic>.from(s is Map ? s : {});
            return TimeSlot(
              name: slot['name'] ?? 'Slot',
              startTime: TimeOfDay(
                 hour: int.tryParse(slot['start']?.split(':')[0] ?? '0') ?? 0, 
                 minute: int.tryParse(slot['start']?.split(':')[1] ?? '0') ?? 0
              ),
              endTime: TimeOfDay(
                 hour: int.tryParse(slot['end']?.split(':')[0] ?? '0') ?? 0, 
                 minute: int.tryParse(slot['end']?.split(':')[1] ?? '0') ?? 0
              ),
              price: slot['price']?.toDouble(),
            );
          }));
        }

        if (service.options!['eventPricing'] != null) {
          final eventPricing = Map<String, dynamic>.from(service.options!['eventPricing'] as Map);
          eventPricing.forEach((type, price) {
            _eventPricingControllers[type] = TextEditingController(text: price.toString());
          });
        }

        if (_selectedType == ServiceType.package) {
          _includedServices.clear();
          _includedServices.addAll(
            List<String>.from(service.options!['includedServices'] ?? []),
          );
          _selectedExistingServices.clear();
          _selectedExistingServices.addAll(
            List<String>.from(
              service.options!['selectedExistingServices'] ?? [],
            ),
          );
          if (service.options!['includedCategories'] is List) {
            _includedCategories.clear();
            _includedCategories.addAll(
              (service.options!['includedCategories'] as List)
                      .map(
                        (e) => EventCategory.values.firstWhere(
                          (cat) => cat.name == e,
                          orElse: () => EventCategory.package,
                        ),
                      )
                      .toList(),
            );
          }

          // --- LOAD CATEGORY ATTRIBUTES ---
          if (service.options!['attributes'] != null) {
            final attrs = Map<String, dynamic>.from(service.options!['attributes'] as Map);
            attrs.forEach((key, value) {
              _categoryAttributes[key] = TextEditingController(text: value.toString());
            });
          }

          // Load included category attributes
          if (service.options!['includedCategoryAttributes'] != null) {
            final incAttrs = Map<String, dynamic>.from(service.options!['includedCategoryAttributes'] as Map);
            incAttrs.forEach((categoryName, attrsMap) {
              final cat = EventCategory.values.firstWhere(
                (c) => c.name == categoryName,
                orElse: () => EventCategory.package,
              );
              final targetMap = _includedCategoryAttributes[cat] = {};
              final actualAttrs = Map<String, dynamic>.from(attrsMap as Map);
              actualAttrs.forEach((key, value) {
                targetMap[key] = TextEditingController(text: value.toString());
              });
            });
          }
        }
      }

      if (service.timeRule != null) {
        final rule = service.timeRule!;
        _selectedTimeType = rule.timeType;
        _slotDurationController.text = (rule.slotDurationMinutes ?? 60).toString();
        _minDurationController.text = (rule.minDurationMinutes ?? 60).toString();
        _maxDurationController.text = (rule.maxDurationMinutes ?? 480).toString();
        _durationStepController.text = rule.durationStepMinutes.toString();
        _bufferBeforeController.text = rule.bufferBeforeMinutes.toString();
        _bufferAfterController.text = rule.bufferAfterMinutes.toString();
        _serviceSessions.clear();
        _serviceSessions.addAll(rule.sessions);
        _allowMultiDayBooking = rule.allowMultiDay;
        _maxDaysController.text = (rule.maxDays ?? 1).toString();
        _fullDayStartController.text = rule.startTime ?? '08:00';
        _fullDayEndController.text = rule.endTime ?? '23:00';
      }

      if (service.logisticsConfig != null) {
        final log = service.logisticsConfig!;
        _requiresVehicle = log.requiresVehicle;
        _selectedVehicleType = log.vehicleType ?? VehicleType.van;
        _crewCountController.text = log.defaultCrewCount.toString();
        _setupTimeController.text = log.defaultSetupTime.toString();
        _teardownTimeController.text = log.defaultTeardownTime.toString();
        _freeRadiusController.text = log.freeRadiusKm.toString();
        _perKmRateController.text = log.perKmRate.toString();
        _primaryState = log.primaryState;
        _parkingRequired = log.parkingRequired;
        _powerRequired = log.powerRequired;
        _overnightRequired = log.overnightRequired;
        _nightSurchargeController.text = log.nightSurcharge.toString();
        _tollPolicyController.text = log.tollParkingPolicy ?? '';
        _minOrderForFreeDeliveryController.text = log.minOrderForFreeDelivery.toString();
      }

      // Initialize Installment Settings
      _installmentEnabled = service.installmentEnabled;
      _depositPercentageController.text = service.depositPercentage?.toString() ?? '';
      _maxInstallmentsController.text = service.maxInstallments?.toString() ?? '';
      _paymentDeadlineDaysController.text = service.paymentDeadlineDays?.toString() ?? '';

      // Sync logic with price limits
      _enforceInstallmentRules();

      // Final debug print to show successfully loaded data
      final _collectedServiceForDebug = _collectServiceData(service.id, false);
      print('\n--- DEBUG: Full Service Data (Loaded) ---');
      print(_collectedServiceForDebug.toJson());
      print('Options: ${_collectedServiceForDebug.options}');
      print('------------------------------------------\n');
    }
  }

  Future<void> _deleteService() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete "${widget.existingService?.name ?? 'this service'}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (mounted) {
      setState(() => _isSaving = true);
    }

    try {
      // Use VendorProvider for deletion as it handles state updates too
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      
      if (widget.existingService != null) {
        await vendorProvider.removeCustomService(widget.existingService!.id, vendorId: widget.vendorId);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service deleted successfully'), backgroundColor: Colors.teal),
        );
        Navigator.of(context).pop(true); // Return true to indicate status change/deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting service: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              widget.existingService != null
                  ? "Edit Service"
                  : "Create New Service",
            ),
            backgroundColor: Colors.teal,
            actions: [
              if (widget.existingService != null) ...[
                Row(
                  children: [
                    Text(
                      _isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (val) {
                        setState(() {
                          _isActive = val;
                        });
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.greenAccent,
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete Service',
                  onPressed: _deleteService,
                ),
              ],
            ],
          ),
          body: Form(
            key: _formKey,
            child: Stepper(
              type: StepperType.vertical,
              physics: const ClampingScrollPhysics(),
              currentStep: _currentStep,
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              onStepContinue: () {
                if (_currentStep < 3) {
                  setState(() => _currentStep += 1);
                }
              },
              onStepTapped: (step) => setState(() => _currentStep = step),
              controlsBuilder: (BuildContext context, ControlsDetails details) {
                final isLastStep = _currentStep == 3;
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
                  child: Row(
                    children: [
                      if (!isLastStep)
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: details.onStepContinue,
                            child: const Text('Next'),
                          ),
                        ),
                      if (isLastStep) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                            label: Text(_isSaving ? "Saving..." : "Save Draft"),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: _isSaving ? null : () {
                              if (_formKey.currentState!.validate()) {
                                _saveService(isDraft: true);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send),
                            label: Text(_isSaving ? "Submit" : "Submit"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: _isSaving ? null : () {
                              if (_formKey.currentState!.validate()) {
                                _saveService(isDraft: false);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
                              }
                            },
                          ),
                        ),
                      ],
                      if (_currentStep > 0 && !isLastStep) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: details.onStepCancel,
                            child: const Text('Back'),
                          ),
                        ),
                      ],
                      if (isLastStep) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            onPressed: details.onStepCancel,
                            child: const Text('Back'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Basic Information'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Service / Product Name",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Service Type
                  DropdownButtonFormField<ServiceType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: "Service Type",
                      border: OutlineInputBorder(),
                    ),
                    items:
                        ServiceType.values.map((e) {
                          return DropdownMenuItem(
                            value: e,
                            child: Text(e.name.toUpperCase()),
                          );
                        }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedType = v;
                        // Just reset category selection to let user pick
                        _selectedCategory = null;
                        _selectedSubcategory = null;
                        _categoryAttributes.clear();
                      });
                    },
                    validator: (v) => v == null ? "Required" : null,
                  ),
                  const SizedBox(height: 16),

                  // Directory / Listing Mode Toggle Container
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.06),
                          AppTheme.primaryColor.withOpacity(0.01),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              color: AppTheme.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                "Directory Showcase Only",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              activeColor: AppTheme.primaryColor,
                              value: _directoryShowcaseOnly,
                              onChanged: (val) {
                                setState(() {
                                  _directoryShowcaseOnly = val;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _directoryShowcaseOnly
                              ? "Enabled: Showcase this listing in the marketplace directory without active checkout/booking. Customers can only message or chat to inquire."
                              : "Disabled: Standard transactional service. Customers can book, pay, or reserve this item online.",
                          style: TextStyle(
                            fontSize: 12,
                            color: _directoryShowcaseOnly
                                ? Colors.teal.shade800
                                : AppTheme.textSecondaryColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Master Category Selection (Hidden for packages)
                  if (_selectedType != null && _selectedType != ServiceType.package)
                    Consumer<VendorProvider>(
                      builder: (context, vendorProvider, child) {
                        return DropdownButtonFormField<ServiceCategory>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: "Main Service Category",
                            border: OutlineInputBorder(),
                          ),
                          items: (() {
                            final sourceCategories = _localCategories.isNotEmpty 
                                ? _localCategories 
                                : vendorProvider.serviceCategories;
                            
                            final targetType = _mapServiceTypeToCategoryType(_selectedType);
                            
                            // Filter categories by type
                            // For packages, allow ALL categories since they can bundle services, rentals, and products
                            final filtered = sourceCategories.where((c) {
                              if (_selectedType == ServiceType.package) {
                                return true;
                              }
                              return c.categoryType == targetType;
                            }).toList();
                            
                            // If _selectedCategory exists but is not in filtered list, it might be due to 
                            // historical data or being a fallback. We should probably still show it 
                            // if it's the current value to avoid errors, or handle the reset in onChanged.
                            if (_selectedCategory != null && !filtered.contains(_selectedCategory)) {
                              filtered.add(_selectedCategory!);
                            }
                            
                            return filtered.map((e) {
                              return DropdownMenuItem(
                                value: e,
                                child: Row(
                                  children: [
                                    Icon(e.icon, size: 20, color: e.color),
                                    const SizedBox(width: 8),
                                    Text(e.name),
                                  ],
                                ),
                              );
                            }).toList();
                          })(),
                          onChanged: (v) {
                            setState(() {
                              _selectedCategory = v;
                              _selectedSubcategory = null;
                              _categoryAttributes.clear();
                            });
                          },
                          validator: (v) =>
                              (_selectedType != ServiceType.package && v == null)
                                  ? "Required"
                                  : null,
                        );
                      }
                    ),
                  if (_selectedType != null && _selectedType != ServiceType.package)
                    const SizedBox(height: 16),

                  // Catering Menu Configuration (Specifically for food/drinks)
                  // Show full configurator for: standalone catering service,
                  // OR any package that includes catering as a category.
                  if (_mapToEventCategory(_selectedCategory) == EventCategory.catering ||
                      (_selectedType == ServiceType.package &&
                       _includedCategories.contains(EventCategory.catering)))
                    _buildCateringConfigurator(),

                  // Generic Package Categories & Setup
                  if (_selectedType == ServiceType.package)
                     _buildPackageCategoriesGenericSection(),

                  const SizedBox(height: 16),

                  // Category-specific attributes (only show if not package)
                  if (_selectedCategory != null &&
                      _selectedType != ServiceType.package)
                    _buildCategoryAttributes(),

                  const Divider(height: 32),
                  
                  // REORDERED: Facilities / Amenities / Event Types moved ABOVE Time Configuration
                  if (_mapToEventCategory(_selectedCategory) == EventCategory.venue) ...[
                    _buildFacilitiesSection(),
                    const Divider(height: 32),
                  ],

                  // Event Types 
                  _buildEventTypeSection(),

                  const SizedBox(height: 24),
                  // Moved from Step 3: Description
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),

                  // Moved from Step 3: Image Upload Section
                  _buildImageUploadSection(),
                  const SizedBox(height: 16),
                  _buildVideoUploadSection(), // Added
                  const SizedBox(height: 16),
                  _buildPdfUploadSection(), // Added for PDF upload
                  const SizedBox(height: 16),
                    ],
                  ),
                ),
                Step(
                  title: const Text('Pricing & Availability'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimeConfigurationSection(),

                  // Enhanced Pricing Section
                  _buildPricingSection(),
                  const SizedBox(height: 16),

                  // Quantity Controls
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _minQty.toString(),
                          decoration: const InputDecoration(
                            labelText: "Min Quantity",
                            border: OutlineInputBorder(),
                          ),
                          onChanged:
                              (v) => setState(() => _minQty = int.tryParse(v) ?? 1),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _maxQty.toString(),
                          decoration: const InputDecoration(
                            labelText: "Max Quantity",
                            border: OutlineInputBorder(),
                          ),
                          onChanged:
                              (v) => setState(() => _maxQty = int.tryParse(v) ?? 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stock Quantity (for products)
                  if (_selectedType == ServiceType.product) ...[
                    TextFormField(
                      initialValue: _stockQuantity.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Stock Quantity",
                        border: OutlineInputBorder(),
                      ),
                      onChanged:
                          (v) =>
                              setState(() => _stockQuantity = int.tryParse(v) ?? 0),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Duration Section
                  if (!_isRentable) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _durationValueController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: "Duration (Optional)",
                              hintText: "e.g. 2",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _durationUnit,
                            decoration: const InputDecoration(
                              labelText: "Unit",
                              border: OutlineInputBorder(),
                            ),
                            items: ['Minutes', 'Hours', 'Days', 'Weeks'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() => _durationUnit = newValue);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(height: 32),

                  // Availability Section
                  if (_selectedType == ServiceType.service ||
                      (_selectedType == ServiceType.package && _packageNeedsAvailability()))
                    _buildAvailabilitySection(),

                  // Rentable Toggle
                  SwitchListTile(
                    title: const Text("Is Rentable Item?"),
                    value: _isRentable,
                    onChanged: (v) => setState(() => _isRentable = v),
                  ),
                  if (_isRentable) _buildTimeSelector(),

                  const SizedBox(height: 16),

                  // Location / Service Area Section
                  if (_mapToEventCategory(_selectedCategory) == EventCategory.venue) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: "Venue Address",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                        hintText: "Enter full venue address",
                      ),
                      validator:
                          (v) =>
                              (_mapToEventCategory(_selectedCategory) == EventCategory.venue &&
                                      (v == null || v.isEmpty))
                                  ? "Address is required for venues"
                                  : null,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: "City",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            validator:
                                (v) =>
                                    (_mapToEventCategory(_selectedCategory) == EventCategory.venue &&
                                            (v == null || v.isEmpty))
                                        ? "City is required"
                                        : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: const InputDecoration(
                              labelText: "State",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.map),
                            ),
                            validator:
                                (v) =>
                                    (_mapToEventCategory(_selectedCategory) == EventCategory.venue &&
                                            (v == null || v.isEmpty))
                                        ? "State is required"
                                        : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _googleMapsController,
                      decoration: const InputDecoration(
                        labelText: "Google Maps Embed URL (Optional)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map_outlined),
                        hintText: "Paste Google Maps embed URL",
                      ),
                      maxLines: 2,
                    ),
                  ] else ...[
                    const Text(
                      "Service Areas",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedServiceAreas.isEmpty)
                            Text(
                              "No areas selected. Add areas or detect your location.",
                              style: TextStyle(color: Colors.grey.shade600),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _selectedServiceAreas.map((area) {
                                return Chip(
                                  label: Text(area, style: const TextStyle(fontSize: 12)),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedServiceAreas.remove(area);
                                    });
                                  },
                                  deleteIconColor: Colors.red,
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  side: BorderSide.none,
                                  padding: EdgeInsets.zero,
                                );
                              }).toList(),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _showServiceAreaSelectionDialog,
                                icon: const Icon(Icons.add_location_alt, size: 18),
                                label: const Text("Browse Regions"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _isDetectingLocation ? null : () async {
                                  setState(() => _isDetectingLocation = true);
                                  try {
                                    final area = await LocationHelper.detectServiceArea();
                                    if (area != null && area.isNotEmpty && mounted) {
                                      setState(() {
                                        if (!_selectedServiceAreas.contains(area)) {
                                          _selectedServiceAreas.add(area);
                                        }
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Added: $area'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Could not detect location. Please enable location services.'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Location detection failed. Please add areas manually.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) setState(() => _isDetectingLocation = false);
                                  }
                                },
                                icon: _isDetectingLocation
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.my_location, size: 18),
                                label: Text(_isDetectingLocation ? "Detecting..." : "Detect Location"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  side: const BorderSide(color: AppTheme.primaryColor),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                    ],
                  ),
                ),
                Step(
                  title: const Text('Add-ons & Logistics (Optional)'),
                  isActive: _currentStep >= 2,
                  state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Customize your service with extra options or define logistical requirements if applicable.",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                  // AddOns Section
                  _buildAddOnsSection(),
                  const Divider(height: 48),

                  _buildLogisticsConfigurationSection(),
                  const SizedBox(height: 16),

                  // Delivery & Pickup (product/rental only)
                  if (_selectedType == ServiceType.product || _selectedType == ServiceType.rental) ...[
                    const Divider(height: 32),
                    _buildDeliveryLogisticsSection(),
                    const SizedBox(height: 16),
                  ],

                  // Enhanced Variations (product only)
                  if (_selectedType == ServiceType.product) ...[
                    const Divider(height: 32),
                    _buildEnhancedVariationsSection(),
                    const SizedBox(height: 16),
                  ],
                    ],
                  ),
                ),
                Step(
                  title: const Text('Payment Policies'),
                  isActive: _currentStep >= 3,
                  state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Set your cancellation terms and choose how you accept payments for this service.",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                  // Cancellation Policy Section
                  _buildCancellationPolicySection(),
                  const SizedBox(height: 24),

                  // Bulk Pricing (product/rental only)
                  if (_selectedType == ServiceType.product || _selectedType == ServiceType.rental) ...[
                    _buildBulkPricingSection(),
                    const SizedBox(height: 24),
                  ],

                  // Installment Settings Section
                  _buildInstallmentSection(),
                  const SizedBox(height: 24),

                      const SizedBox(height: 50), // Extra space to prevent overflow

                      const SizedBox(height: 50), // Extra space to prevent overflow
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _isSaving 
          ? const ModalBarrier(dismissible: false, color: Colors.black26) 
          : const SizedBox.shrink(),
        _isSaving 
          ? const Center(child: CircularProgressIndicator()) 
          : const SizedBox.shrink(),
      ],
    );
  }


  // --- Widgets for subsections ---

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Rental Availability Hours"),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTimePicker(
                label: "Start Time",
                selectedTime: _startTime,
                onPick: (time) => setState(() => _startTime = time),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimePicker(
                label: "End Time",
                selectedTime: _endTime,
                onPick: (time) => setState(() => _endTime = time),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay? selectedTime,
    required Function(TimeOfDay) onPick,
  }) {
    return OutlinedButton(
      onPressed: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: selectedTime ?? TimeOfDay.now(),
        );
        if (time != null) onPick(time);
      },
      child: Text(
        selectedTime == null
            ? label
            : "$label: ${selectedTime.format(context)}",
      ),
    );
  }

  Widget _buildVariationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Variation Tiers",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        for (var v in _variations)
          ListTile(
            title: Text(v.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.options.join(", ")),
                if (v.optionPrices.isNotEmpty)
                  Text(
                    "Prices: ${v.optionPrices.entries.map((e) => "${e.key}: ${CurrencyFormatter.symbol}${e.value.toStringAsFixed(2)}").join(", ")}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => _variations.remove(v)),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Add Variation"),
          onPressed: _addVariationDialog,
        ),
      ],
    );
  }

  Widget _buildFacilitiesSection() {
    // Predefined amenities list
    final predefinedAmenities = [
      'Parking',
      'WiFi',
      'Air Conditioning',
      'Restrooms',
      'Kitchen',
      'Catering Area',
      'Bar Area',
      'Sound System',
      'Projector',
      'Stage',
      'Lighting',
      'Tables & Chairs',
      'Decorations',
      'Dance Floor',
      'Bridal Room',
      'Prayer Room',
      'Outdoor Space',
      'Security',
      'Valet Parking',
      'Wheelchair Access',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Amenities & Facilities",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          "Select amenities available at your venue:",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        
        // Predefined amenities checkboxes
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: predefinedAmenities.map((amenity) {
            final isSelected = _facilities.contains(amenity);
            return FilterChip(
              label: Text(amenity),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _facilities.add(amenity);
                  } else {
                    _facilities.remove(amenity);
                  }
                });
              },
              selectedColor: Colors.teal.shade100,
              checkmarkColor: Colors.teal,
            );
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        
        // Custom amenities section
        const Text(
          "Custom Amenities:",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        
        // Display custom amenities (not in predefined list)
        ...(_facilities.where((f) => !predefinedAmenities.contains(f)).map((facility) => 
          ListTile(
            dense: true,
            leading: const Icon(Icons.check_circle, color: Colors.teal, size: 20),
            title: Text(facility),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => setState(() => _facilities.remove(facility)),
            ),
          ),
        )),
        
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Add Custom Amenity"),
          onPressed: _addFacilityDialog,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEventTypeSection() {
    final predefinedEventTypes = EventType.values.map((e) => e.displayName).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Suitable for Event Types",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          "Select event types suitable for this venue:",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: predefinedEventTypes.map((type) {
            final isSelected = _eventTypes.contains(type);
            return FilterChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _eventTypes.add(type);
                  } else {
                    _eventTypes.remove(type);
                  }
                });
              },
              selectedColor: Colors.teal.shade100,
              checkmarkColor: Colors.teal,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAddOnsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Add-Ons",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_addOns.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text("No add-ons added yet.", style: TextStyle(color: Colors.grey)),
          ),
        for (var addOn in _addOns)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(addOn.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (addOn.description.isNotEmpty)
                    Text(addOn.description),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.teal.shade100),
                        ),
                        child: Text(
                          "${CurrencyFormatter.symbol}${addOn.price.toStringAsFixed(2)} / ${_formatPricingType(addOn.pricingType)}",
                          style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (addOn.maxQuantity != null)
                        Text("Max: ${addOn.maxQuantity}", style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  if (addOn.isRequired)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: const [
                          Icon(Icons.error_outline, size: 14, color: Colors.red),
                          SizedBox(width: 4),
                          Text("Required Selection", style: TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () => setState(() => _addOns.remove(addOn)),
              ),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Add Add-On"),
          onPressed: _addAddOnDialog,
        ),
      ],
    );
  }

  Widget _buildIncludedServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Included Services (for packages)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),

        // Custom Services Section
        const Text(
          "Custom Services",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              _includedServices
                  .map(
                    (e) => Chip(
                      label: Text(e),
                      backgroundColor: Colors.blue.shade100,
                      onDeleted:
                          () => setState(() => _includedServices.remove(e)),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Add Custom Service"),
          onPressed: _addIncludedDialog,
        ),

        const SizedBox(height: 16),

        // Existing Services Section
        const Text(
          "Selected Existing Services",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              _selectedExistingServices
                  .map(
                    (e) => Chip(
                      label: Text(e),
                      backgroundColor: Colors.green.shade100,
                      onDeleted:
                          () => setState(
                            () => _selectedExistingServices.remove(e),
                          ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.library_add),
          label: const Text("Select Existing Service"),
          onPressed: _selectExistingServiceDialog,
        ),
      ],
    );
  }

  Future<void> _addVariationDialog() async {
    final nameCtrl = TextEditingController();
    final optsCtrl = TextEditingController();
    final List<TextEditingController> priceControllers = [];
    final List<String> options = [];

    await showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: const Text("Add Variation"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: "Name"),
                        ),
                        TextField(
                          controller: optsCtrl,
                          decoration: const InputDecoration(
                            labelText: "Options (comma separated)",
                          ),
                          onChanged: (value) {
                            final newOptions =
                                value
                                    .split(",")
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList();
                            if (newOptions.length != options.length) {
                              setStateDialog(() {
                                options.clear();
                                options.addAll(newOptions);
                                priceControllers.clear();
                                for (var _ in options) {
                                  priceControllers.add(TextEditingController());
                                }
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        if (options.isNotEmpty) ...[
                          const Text("Prices for each option (optional):"),
                          const SizedBox(height: 8),
                          ...options.asMap().entries.map((entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(child: Text("${entry.value}: ${CurrencyFormatter.symbol}")),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: priceControllers[entry.key],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: "0.00",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final optionPrices = <String, double>{};
                        for (var i = 0; i < options.length; i++) {
                          final price =
                              double.tryParse(priceControllers[i].text) ?? 0.0;
                          if (price > 0) {
                            optionPrices[options[i]] = price;
                          }
                        }
                        setState(() {
                          _variations.add(
                            VariationGroup(
                              name: nameCtrl.text,
                              options: options,
                              optionPrices: optionPrices,
                            ),
                          );
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Add"),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _addAddOnDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final maxQtyCtrl = TextEditingController();
    bool isRequired = false;
    bool isFree = false;
    AddOnPricingType selectedType = AddOnPricingType.fixed;

    await showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: const Text("Add Add-On"),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: "Name", hintText: "e.g. Extra Hour, Setup Service"),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descCtrl,
                          decoration: const InputDecoration(
                            labelText: "Description (Optional)",
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          title: const Text("Is Free"),
                          value: isFree,
                          onChanged: (v) => setStateDialog(() => isFree = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (!isFree)
                          Row(
                            children: [
                              Expanded(child: TextField(
                                controller: priceCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: "Price (${CurrencyFormatter.symbol})",
                                  prefixText: "${CurrencyFormatter.symbol} ",
                                ),
                              )),
                              const SizedBox(width: 12),
                              Expanded(child: DropdownButtonFormField<AddOnPricingType>(
                                value: selectedType,
                                decoration: const InputDecoration(labelText: "Per Unit"),
                                isExpanded: true,
                                items: AddOnPricingType.values.map((t) => DropdownMenuItem(
                                  value: t, 
                                  child: Text(_formatPricingType(t)),
                                )).toList(),
                                onChanged: (v) => setStateDialog(() => selectedType = v!),
                              )),
                            ],
                          ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: maxQtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Max Quantity (Optional)",
                            helperText: "Leave empty for unlimited",
                          ),
                        ),
                        SwitchListTile(
                          title: const Text("Required Selection"),
                          subtitle: const Text("Customer must select at least one"),
                          value: isRequired,
                          onChanged:
                              (value) =>
                                  setStateDialog(() => isRequired = value),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.isEmpty) return;
                        if (!isFree && priceCtrl.text.isEmpty) return;
                        
                        final price = isFree ? 0.0 : (double.tryParse(priceCtrl.text) ?? 0.0);
                        final maxQty = int.tryParse(maxQtyCtrl.text);
                        setState(() {
                          _addOns.add(
                            AddOn(
                              name: nameCtrl.text,
                              description: descCtrl.text,
                              price: price,
                              maxQuantity: maxQty,
                              isRequired: isRequired,
                              pricingType: selectedType,
                              isFree: isFree,
                            ),
                          );
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Add"),
                    ),
                  ],
                ),
          ),
    );
  }

  String _formatPricingType(AddOnPricingType type) {
    switch(type) {
      case AddOnPricingType.fixed: return "Flat Fee";
      case AddOnPricingType.perPax: return "Per Pax";
      case AddOnPricingType.perUnit: return "Per Unit";
      case AddOnPricingType.perHour: return "Per Hour";
    }
  }

  Future<void> _addIncludedDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Add Custom Service"),
            content: TextField(controller: ctrl),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _includedServices.add(ctrl.text));
                  Navigator.pop(context);
                },
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }

  Future<void> _addFacilityDialog() async {
    final ctrl = TextEditingController();
    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Add Facility"),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: "Facility Name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (ctrl.text.isNotEmpty &&
                      !_facilities.contains(ctrl.text)) {
                    setState(() => _facilities.add(ctrl.text));
                  }
                  Navigator.pop(context);
                },
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }

  Future<void> _selectExistingServiceDialog() async {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final existingServices = vendorProvider.getCurrentVendorServices();

    // Filter to only approved services
    final approvedServices =
        existingServices
            .where(
              (service) => service.approvalStatus == ApprovalStatus.approved,
            )
            .toList();

    await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Select Existing Service"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    approvedServices.map((service) {
                      final isSelected = _selectedExistingServices.contains(
                        service.name,
                      );
                      return CheckboxListTile(
                        title: Text(service.name),
                        subtitle: Text(
                          "${service.category.displayName} - ${CurrencyFormatter.symbol}${service.price.toStringAsFixed(2)}",
                        ),
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              if (!_selectedExistingServices.contains(
                                service.name,
                              )) {
                                _selectedExistingServices.add(service.name);
                              }
                            } else {
                              _selectedExistingServices.remove(service.name);
                            }
                          });
                          Navigator.pop(context);
                          _selectExistingServiceDialog(); // Reopen dialog to update state
                        },
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Done"),
              ),
            ],
          ),
    );
  }

  Widget _buildIncludedCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Included Categories (for packages)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (_includedCategories.isNotEmpty)
               Text(
                "${_includedCategories.length} Categories",
                style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_includedCategories.isEmpty)
          GestureDetector(
            onTap: _addIncludedCategoryDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none),
              ),
              child: Column(
                children: [
                  Icon(Icons.category_outlined, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text("No categories added yet", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  const Text("Click to select what is included in this package", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _includedCategories.map((e) {
              final component = _components.firstWhereOrNull((c) => c.componentType == e.id);
              final itemCount = component?.items.length ?? 0;
              
              return GestureDetector(
                onTap: () async {
                   final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PackageComponentConfigScreen(
                        component: component ?? ServiceComponent(
                          name: e.displayName,
                          componentType: e.id,
                          items: [],
                        ),
                        category: e,
                      ),
                    ),
                  );
                  
                  if (result != null && result is ServiceComponent) {
                    setState(() {
                      final idx = _components.indexWhere((c) => c.componentType == e.id);
                      if (idx != -1) {
                         _components[idx] = result;
                      } else {
                         _components.add(result);
                      }
                    });
                  }
                },
                child: Chip(
                  avatar: Icon(e.icon, size: 16, color: Colors.white),
                  backgroundColor: AppTheme.primaryColor,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.displayName, style: const TextStyle(color: Colors.white)),
                      if (itemCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "$itemCount",
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onDeleted: () {
                    setState(() {
                      _includedCategories.remove(e);
                      _components.removeWhere((c) => c.componentType == e.id);
                    });
                  },
                  deleteIconColor: Colors.white70,
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("Add / Manage Categories"),
            onPressed: _addIncludedCategoryDialog,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addIncludedCategoryDialog() async {
    final Set<EventCategory> selectedCategories = Set.from(_includedCategories);
    String searchQuery = "";

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final filteredCategories = EventCategory.values
              .where((e) => e != EventCategory.package && 
                           e.displayName.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          return AlertDialog(
            titlePadding: EdgeInsets.zero,
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Select Categories", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search categories...",
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setStateDialog(() => searchQuery = val),
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, index) {
                        final cat = filteredCategories[index];
                        final isSelected = selectedCategories.contains(cat);
                        
                        return GestureDetector(
                          onTap: () {
                            setStateDialog(() {
                              if (isSelected) {
                                selectedCategories.remove(cat);
                              } else {
                                selectedCategories.add(cat);
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))] : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(cat.icon, color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600, size: 28),
                                const SizedBox(height: 8),
                                Text(
                                  cat.displayName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                                  ),
                                ),
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 16),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            setState(() {
                              // Find which categories were added
                              final newCategories = selectedCategories.difference(Set.from(_includedCategories));
                              // Find which categories were removed
                              final removedCategories = Set.from(_includedCategories).difference(selectedCategories);

                              _includedCategories.clear();
                              _includedCategories.addAll(selectedCategories);

                              for (var cat in newCategories) {
                                final componentId = DateTime.now().millisecondsSinceEpoch.toString() + cat.name;
                                _components.add(
                                  ServiceComponent(
                                    id: componentId,
                                    name: cat.displayName,
                                    componentType: cat.id,
                                    items: [], 
                                  )
                                );
                              }

                              for (var cat in removedCategories) {
                                _components.removeWhere((c) => c.componentType == cat.id);
                              }
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("Save Selection"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time Slots Section (for slot-based pricing)
        if (_selectedPricing == PricingMode.perSlot) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Time Slots",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              PopupMenuButton<String>(
                child: Chip(
                  label: const Text("Load Presets"),
                  avatar: const Icon(Icons.flash_on, size: 16),
                  backgroundColor: Colors.teal.shade50,
                ),
                onSelected: (value) {
                  setState(() {
                    _timeSlots.clear();
                    if (value == 'Time of Day') {
                      _timeSlots.add(TimeSlot(
                          startTime: const TimeOfDay(hour: 9, minute: 0),
                          endTime: const TimeOfDay(hour: 12, minute: 0),
                          name: 'Morning Session',
                          price: double.tryParse(_priceController.text)));
                      _timeSlots.add(TimeSlot(
                          startTime: const TimeOfDay(hour: 14, minute: 0),
                          endTime: const TimeOfDay(hour: 18, minute: 0),
                          name: 'Afternoon Session',
                          price: double.tryParse(_priceController.text)));
                      _timeSlots.add(TimeSlot(
                          startTime: const TimeOfDay(hour: 19, minute: 0),
                          endTime: const TimeOfDay(hour: 23, minute: 0),
                          name: 'Evening Session',
                          price: (double.tryParse(_priceController.text) ?? 0) * 1.2));
                    } else if (value == 'Hourly') {
                      _timeSlots.add(TimeSlot(
                          startTime: const TimeOfDay(hour: 9, minute: 0),
                          endTime: const TimeOfDay(hour: 10, minute: 0),
                          name: '1 Hour Slot',
                          price: double.tryParse(_priceController.text)));
                    }
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'Time of Day',
                      child: Text("Morning / Afternoon / Evening")),
                  const PopupMenuItem(
                      value: 'Hourly', child: Text("Hourly Slots")),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Defined Sessions:",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          if (_timeSlots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                  "No sessions defined. Add one below or load a preset.",
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ),
          ..._timeSlots.map((slot) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.access_time, color: Colors.teal),
                title: Text(slot.name),
                subtitle: Text(
                    "${slot.startTime.format(context)} - ${slot.endTime.format(context)}  •  ${CurrencyFormatter.symbol} ${(slot.price ?? 0).toStringAsFixed(2)}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => setState(() => _timeSlots.remove(slot)),
                ),
              ),
            );
          }).toList(),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add Custom Session"),
            onPressed: _addSessionDialog,
          ),
          const SizedBox(height: 24),
        ],

        // Calendar-based Availability
        CalendarAvailabilityWidget(
          initialAvailableDates: _availableDates,
          initialUnavailableDates: _unavailableDates,
          useWhitelist: _useWhitelist,
          onChanged: (availableDates, unavailableDates, useWhitelist) {
            setState(() {
              _availableDates = availableDates;
              _unavailableDates = unavailableDates;
              _useWhitelist = useWhitelist;
            });
          },
        ),
      ],
    );
  }

  Future<void> _addSessionDialog() async {
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 10, minute: 0);
    final nameCtrl = TextEditingController(text: "New Session");
    final priceCtrl = TextEditingController(text: _priceController.text);

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Session"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Session Name (e.g. Morning)")),
               const SizedBox(height: 8),
               Row(children: [
                 Expanded(child: _buildTimePicker(
                   label: "Start", 
                   selectedTime: start, 
                   onPick: (t) => setDialogState(() => start = t)
                 )),
                 const SizedBox(width: 8),
                 Expanded(child: _buildTimePicker(
                   label: "End", 
                   selectedTime: end, 
                   onPick: (t) => setDialogState(() => end = t)
                 )),
               ]),
               const SizedBox(height: 8),
               TextField(
                 controller: priceCtrl, 
                 keyboardType: const TextInputType.numberWithOptions(decimal: true),
                 decoration: InputDecoration(labelText: "Price (${CurrencyFormatter.symbol})", prefixText: "${CurrencyFormatter.symbol} ")
               ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                 if (nameCtrl.text.isNotEmpty) {
                    setState(() {
                       _timeSlots.add(TimeSlot(
                         startTime: start, 
                         endTime: end, 
                         name: nameCtrl.text, 
                         price: double.tryParse(priceCtrl.text)
                       ));
                    });
                    Navigator.pop(context);
                 }
              }, 
              child: const Text("Add")
            ),
          ],
        ),
      )
    );
  }

  Future<void> _addBlockedDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && !_blockedDates.contains(pickedDate)) {
      setState(() {
        _blockedDates.add(pickedDate);
      });
    }
  }

  Widget _buildCategoryAttributes() {
    final List<Widget> attributeSections = [];

    // 1. Primary Category (only if not a package and category is selected)
    if (_selectedCategory != null && _selectedType != ServiceType.package) {
      attributeSections.add(_buildCategoryAttributeBlock(_mapToEventCategory(_selectedCategory), isPrimary: true));
    }

    // 2. Included Categories (if package)
    if (_selectedType == ServiceType.package) {
      for (var cat in _includedCategories) {
        attributeSections.add(_buildCategoryAttributeBlock(cat, isPrimary: false));
      }
    }

    if (attributeSections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...attributeSections,
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildCategoryAttributeBlock(EventCategory eventCat, {required bool isPrimary}) {
    final attributes = _getCategoryAttributes(
      eventCat,
      isPrimary ? _selectedSubcategory : null,
    );

    String sectionTitle = "Additional Details";
    switch (eventCat) {
      case EventCategory.catering: sectionTitle = "Menu & Service Requirements"; break;
      case EventCategory.venue: sectionTitle = "Venue Specifications"; break;
      case EventCategory.photography: 
      case EventCategory.videography: sectionTitle = "Session & Equipment Details"; break;
      case EventCategory.decoration: sectionTitle = "Design & Theme Details"; break;
      default: sectionTitle = "${eventCat.displayName} Details";
    }

    // Use specific map for included categories
    final Map<String, TextEditingController> targetMap = isPrimary 
        ? _categoryAttributes 
        : (_includedCategoryAttributes[eventCat] ??= {});

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
          ),
          const SizedBox(height: 12),
          if (eventCat == EventCategory.venue && isPrimary) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<VenueType>(
                value: _selectedVenueType,
                decoration: const InputDecoration(
                  labelText: "Venue Type",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                ),
                items: VenueType.values.map((e) {
                  return DropdownMenuItem(
                    value: e,
                    child: Text(e.displayName),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedVenueType = v),
                validator: (v) => v == null ? "Required" : null,
              ),
            ),
          ],
          ...attributes.map((attr) {
            if (!targetMap.containsKey(attr)) {
              targetMap[attr] = TextEditingController();
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: targetMap[attr],
                decoration: InputDecoration(
                  labelText: attr,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    final hasImages = _serviceImages.isNotEmpty;
    final category = _mapToEventCategory(_selectedCategory);
    final displayUrl = hasImages 
        ? _serviceImages.first 
        : ImageConstants.getDefaultImageUrl(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Service Cover Image",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          hasImages 
              ? "This is the main image customers will see first."
              : "No images uploaded yet. The default mystery/placeholder below will be used if you don't provide one.",
          style: TextStyle(
            fontSize: 13, 
            color: hasImages ? Colors.grey[600] : AppTheme.primaryColor,
            fontWeight: hasImages ? FontWeight.normal : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        
        // Main Image Preview
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[100],
            image: DecorationImage(
              image: NetworkImage(displayUrl),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: !hasImages 
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_not_supported, color: Colors.white, size: 48),
                        SizedBox(height: 8),
                        Text(
                          "DEFAULT PLACEHOLDER",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),

        // Multiple Images Scroll
        const Text(
          "Additional Gallery Images",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            itemCount: _serviceImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _serviceImages.length) {
                return InkWell(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: AppTheme.primaryColor),
                        const SizedBox(height: 4),
                        const Text("Add more", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              }
              return Container(
                width: 100,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        _serviceImages[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: InkWell(
                        onTap: () => setState(() => _serviceImages.removeAt(index)),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              "${_serviceImages.length} custom image(s) uploaded",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      print('Picking image for service...');
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      print('Image picked: ${image?.name ?? "None"}');
      if (image != null) {
        // Upload image to Supabase Storage
        setState(() {
          // Show loading indicator
        });

        try {
          print('Starting image upload...');
          final supabase = Supabase.instance.client;
          final user = supabase.auth.currentUser;
          print('Current User ID: ${user?.id}');
          
          final fileBytes = await image.readAsBytes();
          print('File size: ${fileBytes.length} bytes');
          
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.name}';
          final currentUser = supabase.auth.currentUser;
          if (currentUser == null) throw Exception("User not authenticated");

          // Use the Auth User ID for the folder name
          final storagePath = '${currentUser.id}/$fileName';
          print('Uploading to bucket: service-images, path: $storagePath');

          // Upload to Supabase Storage using 'service-images' bucket
          await supabase.storage
              .from('service-images')
              .uploadBinary(storagePath, fileBytes);

          print('Upload successful');

          // Get public URL
          final publicUrl = supabase.storage
              .from('service-images')
              .getPublicUrl(storagePath);
          
          print('Public URL: $publicUrl');

          setState(() {
            _serviceImages.add(publicUrl);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Image uploaded successfully"),
              backgroundColor: Colors.green,
            ),
          );
        } catch (uploadError, stackTrace) {
          print('DART_UPLOAD_ERROR: $uploadError');
          print('STACK_TRACE: $stackTrace');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error uploading image: $uploadError"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    }
  }

  List<String> _getCategoryAttributes(
    EventCategory category, [
    String? subcategory,
  ]) {
    switch (category) {
      case EventCategory.photography:
        if (subcategory == 'Wedding Photography') {
          return [
            'Years of Experience',
            'Wedding Packages',
            'Camera Equipment',
            'Lighting Setup',
          ];
        } else if (subcategory == 'Event Photography') {
          return [
            'Years of Experience',
            'Event Types Covered',
            'Equipment',
            'Editing Software',
          ];
        } else if (subcategory == 'Portrait Photography') {
          return [
            'Years of Experience',
            'Studio Setup',
            'Props Available',
            'Retouching Skills',
          ];
        } else if (subcategory == 'Commercial Photography') {
          return [
            'Years of Experience',
            'Industry Focus',
            'Equipment',
            'Post-Production',
          ];
        } else if (subcategory == 'Drone Photography') {
          return [
            'Years of Experience',
            'Drone Certification',
            'Flight Hours',
            'Software Skills',
          ];
        } else {
          return ['Years of Experience', 'Camera Equipment', 'Specialization'];
        }
      case EventCategory.catering:
        if (subcategory == 'Wedding Catering') {
          return [
            'Cuisine Type',
            'Wedding Menu Options',
            'Dietary Accommodations',
            'Service Style',
            'Included Items',
            'Customer Choice Options',
          ];
        } else if (subcategory == 'Corporate Catering') {
          return [
            'Cuisine Type',
            'Meeting Sizes Served',
            'Business Hours',
            'Setup Requirements',
            'Included Items',
            'Customer Choice Options',
          ];
        } else if (subcategory == 'Party Catering') {
          return [
            'Cuisine Type',
            'Party Themes',
            'Guest Count Range',
            'Beverage Options',
            'Included Items',
            'Customer Choice Options',
          ];
        } else if (subcategory == 'Fine Dining') {
          return [
            'Cuisine Type',
            'Chef Credentials',
            'Wine Pairing',
            'Ambiance',
            'Included Items',
            'Customer Choice Options',
          ];
        } else if (subcategory == 'Buffet Service') {
          return [
            'Cuisine Type',
            'Buffet Stations',
            'Serving Capacity',
            'Presentation Style',
            'Included Items',
            'Customer Choice Options',
          ];
        } else {
          return [
            'Cuisine Type',
            'Serving Capacity',
            'Dietary Options',
            'Included Items',
            'Customer Choice Options',
          ];
        }
      case EventCategory.venue:
        if (subcategory == 'Ballroom') {
          return [
            'Capacity',
            'Dance Floor Size',
            'AV Facilities',
            'Catering Kitchen',
            'Included Equipment',
            'Included Furnishings',
          ];
        } else if (subcategory == 'Garden') {
          return [
            'Capacity',
            'Outdoor Features',
            'Weather Backup',
            'Decor Restrictions',
            'Included Equipment',
            'Included Furnishings',
          ];
        } else if (subcategory == 'Beach') {
          return [
            'Capacity',
            'Tidal Schedule',
            'Facilities',
            'Environmental Permits',
            'Included Equipment',
            'Included Furnishings',
          ];
        } else if (subcategory == 'Hotel') {
          return [
            'Capacity',
            'Room Types',
            'Amenities',
            'Conference Facilities',
            'Included Equipment',
            'Included Furnishings',
          ];
        } else if (subcategory == 'Convention Center') {
          return [
            'Capacity',
            'Booth Spaces',
            'AV Equipment',
            'Loading Docks',
            'Included Equipment',
            'Included Furnishings',
          ];
        } else if (subcategory == 'Restaurant') {
          return [
            'Capacity',
            'Private Dining Rooms',
            'Menu Options',
            'Bar Facilities',
            'Included Equipment',
            'Included Furnishings',
          ];
        } else {
          return [
            'Capacity',
            'Location',
            'Facilities',
            'Included Equipment',
            'Included Furnishings',
          ];
        }
      case EventCategory.decoration:
        if (subcategory == 'Floral Decoration') {
          return [
            'Flower Types',
            'Arrangement Styles',
            'Seasonal Availability',
            'Delivery Service',
          ];
        } else if (subcategory == 'Lighting Decoration') {
          return [
            'Lighting Types',
            'Setup Requirements',
            'Power Needs',
            'Color Options',
          ];
        } else if (subcategory == 'Theme Decoration') {
          return [
            'Theme Specialties',
            'Prop Rentals',
            'Installation Time',
            'Customization',
          ];
        } else if (subcategory == 'Balloon Decoration') {
          return [
            'Balloon Types',
            'Design Styles',
            'Helium Service',
            'Setup Time',
          ];
        } else if (subcategory == 'Table Decoration') {
          return ['Table Settings', 'Linens', 'Centerpieces', 'Place Cards'];
        } else {
          return ['Specialization', 'Materials Used'];
        }
      case EventCategory.entertainment:
        if (subcategory == 'Live Band') {
          return ['Genre', 'Band Size', 'Sound Equipment', 'Set Length'];
        } else if (subcategory == 'DJ') {
          return [
            'Music Genres',
            'Equipment',
            'Lighting Setup',
            'Crowd Interaction',
          ];
        } else if (subcategory == 'MC/Host') {
          return [
            'Experience Level',
            'Languages',
            'Event Types',
            'Scripting Skills',
          ];
        } else if (subcategory == 'Dancers') {
          return [
            'Dance Styles',
            'Group Size',
            'Costume Requirements',
            'Performance Length',
          ];
        } else if (subcategory == 'Magicians') {
          return ['Magic Styles', 'Audience Size', 'Props', 'Show Length'];
        } else if (subcategory == 'Photo Booth') {
          return [
            'Setup Type',
            'Props Included',
            'Printing Options',
            'Operator Service',
          ];
        } else {
          return ['Performance Type', 'Experience Level'];
        }
      case EventCategory.transportation:
        if (subcategory == 'Limousine') {
          return [
            'Vehicle Models',
            'Passenger Capacity',
            'Amenities',
            'Service Area',
          ];
        } else if (subcategory == 'Party Bus') {
          return [
            'Vehicle Features',
            'Capacity',
            'Entertainment System',
            'Bar Setup',
          ];
        } else if (subcategory == 'Vintage Car') {
          return [
            'Car Models',
            'Condition',
            'Driver Uniform',
            'Photography Allowance',
          ];
        } else if (subcategory == 'Luxury Van') {
          return [
            'Seating Capacity',
            'Amenities',
            'Driver Experience',
            'Route Planning',
          ];
        } else if (subcategory == 'Motorcycle Escort') {
          return [
            'Bike Types',
            'Formation Options',
            'Safety Equipment',
            'Route Coverage',
          ];
        } else {
          return ['Vehicle Type', 'Capacity', 'Service Area'];
        }
      case EventCategory.equipment:
        if (subcategory == 'Sound System') {
          return [
            'Speaker Types',
            'Power Rating',
            'Setup Time',
            'Operator Included',
          ];
        } else if (subcategory == 'Lighting Equipment') {
          return [
            'Lighting Types',
            'Power Requirements',
            'DMX Knowledge',
            'Setup Crew',
          ];
        } else if (subcategory == 'AV Equipment') {
          return ['Projectors', 'Screens', 'Microphones', 'Technical Support'];
        } else if (subcategory == 'Furniture Rental') {
          return [
            'Furniture Types',
            'Quantity Available',
            'Delivery Service',
            'Setup Included',
          ];
        } else if (subcategory == 'Tent Rental') {
          return [
            'Tent Sizes',
            'Weather Resistance',
            'Setup Time',
            'Anchoring Options',
          ];
        } else {
          return ['Equipment Type', 'Rental Terms'];
        }
      case EventCategory.beauty:
        if (subcategory == 'Bridal Makeup') {
          return [
            'Makeup Styles',
            'Trial Sessions',
            'Products Used',
            'Touch-up Service',
          ];
        } else if (subcategory == 'Hair Styling') {
          return [
            'Hair Services',
            'Styling Tools',
            'Extensions Available',
            'Consultation',
          ];
        } else if (subcategory == 'Spa Services') {
          return [
            'Treatment Types',
            'Duration',
            'Products',
            'Relaxation Areas',
          ];
        } else if (subcategory == 'Nail Services') {
          return ['Nail Types', 'Design Styles', 'Products', 'Sanitization'];
        } else if (subcategory == 'Skincare') {
          return [
            'Skin Types',
            'Treatment Methods',
            'Products',
            'Results Timeline',
          ];
        } else {
          return ['Specialization', 'Certifications'];
        }
      case EventCategory.fashion:
        if (subcategory == 'Dress Rental') {
          return [
            'Dress Styles',
            'Size Range',
            'Designer Brands',
            'Alteration Service',
          ];
        } else if (subcategory == 'Suit Rental') {
          return [
            'Suit Styles',
            'Size Range',
            'Fitting Service',
            'Accessories',
          ];
        } else if (subcategory == 'Accessories') {
          return ['Accessory Types', 'Materials', 'Sizing', 'Cleaning Service'];
        } else if (subcategory == 'Shoes') {
          return [
            'Shoe Types',
            'Size Range',
            'Heel Heights',
            'Cleaning Service',
          ];
        } else if (subcategory == 'Jewelry') {
          return [
            'Jewelry Types',
            'Materials',
            'Gemstones',
            'Insurance Coverage',
          ];
        } else {
          return ['Style Specialization', 'Size Range'];
        }
      case EventCategory.accommodation:
        if (subcategory == 'Hotel Booking') {
          return [
            'Hotel Types',
            'Star Rating',
            'Amenities',
            'Cancellation Policy',
          ];
        } else if (subcategory == 'Resort Booking') {
          return [
            'Resort Features',
            'Activities',
            'Spa Services',
            'Dining Options',
          ];
        } else if (subcategory == 'Villa Rental') {
          return ['Villa Types', 'Bedrooms', 'Amenities', 'Location'];
        } else if (subcategory == 'Apartment Rental') {
          return ['Apartment Types', 'Furnishing', 'Amenities', 'Lease Terms'];
        } else if (subcategory == 'Guest House') {
          return [
            'Room Types',
            'Breakfast Service',
            'Amenities',
            'Local Attractions',
          ];
        } else {
          return ['Room Type', 'Amenities', 'Check-in Policy'];
        }
      case EventCategory.package:
        if (subcategory == 'Wedding Package') {
          return [
            'Package Components',
            'Customization Options',
            'Vendor Coordination',
            'Timeline',
          ];
        } else if (subcategory == 'Corporate Package') {
          return [
            'Package Components',
            'Team Building',
            'AV Setup',
            'Catering Options',
          ];
        } else if (subcategory == 'Birthday Package') {
          return [
            'Package Components',
            'Theme Options',
            'Entertainment',
            'Cake Service',
          ];
        } else if (subcategory == 'Anniversary Package') {
          return [
            'Package Components',
            'Romantic Elements',
            'Photography',
            'Dining',
          ];
        } else if (subcategory == 'Custom Package') {
          return [
            'Package Components',
            'Budget Range',
            'Vendor Selection',
            'Coordination',
          ];
        } else if (subcategory == 'Graduation Package') {
          return [
            'Package Components',
            'Photography',
            'Venue Options',
            'Guest Services',
          ];
        } else if (subcategory == 'Engagement Package') {
          return [
            'Package Components',
            'Photography',
            'Venue',
            'Celebration Elements',
          ];
        } else if (subcategory == 'Retirement Package') {
          return [
            'Package Components',
            'Tributes',
            'Entertainment',
            'Reception',
          ];
        } else if (subcategory == 'Reunion Package') {
          return [
            'Package Components',
            'Activities',
            'Photography',
            'Accommodations',
          ];
        } else if (subcategory == 'Bridal Shower Package') {
          return ['Package Components', 'Games', 'Decor', 'Favors'];
        } else {
          return ['Package Type', 'Included Services'];
        }
      case EventCategory.planning:
        if (subcategory == 'Event Planning') {
          return [
            'Experience Level',
            'Event Types',
            'Budget Management',
            'Vendor Relations',
          ];
        } else if (subcategory == 'Wedding Planning') {
          return [
            'Experience Level',
            'Wedding Styles',
            'Vendor Network',
            'Timeline Management',
          ];
        } else if (subcategory == 'Corporate Planning') {
          return [
            'Experience Level',
            'Corporate Events',
            'Logistics',
            'Budget Control',
          ];
        } else if (subcategory == 'Party Planning') {
          return [
            'Experience Level',
            'Party Types',
            'Theme Creation',
            'Entertainment Booking',
          ];
        } else if (subcategory == 'Destination Planning') {
          return [
            'Experience Level',
            'Destinations',
            'Travel Coordination',
            'Local Vendors',
          ];
        } else {
          return ['Experience Level', 'Specialization'];
        }
      case EventCategory.doorgift:
         if (subcategory == 'Edible Gifts') {
           return ['Shelf Life', 'Ingredients', 'Dietary Info', 'Packaging Type'];
         } else if (subcategory == 'Personalized Items') {
           return ['Personalization Method', 'Material', 'Lead Time', 'Min Order Qty'];
         } else {
           return ['Material', 'Weight', 'Dimensions', 'Min Order Qty'];
         }
      case EventCategory.videography:
        if (subcategory == 'Wedding Videography') {
          return ['Years of Experience', 'Video Packages', 'Camera Equipment', 'Editing Software'];
        } else if (subcategory == 'Event Videography') {
          return ['Years of Experience', 'Event Types Covered', 'Equipment', 'Drone Capability'];
        } else if (subcategory == 'Corporate Videography') {
          return ['Years of Experience', 'Corporate Portfolio', 'Equipment', 'Turnaround Time'];
        } else if (subcategory == 'Drone Videography') {
          return ['Drone Certification', 'Flight Hours', 'Camera Specs', 'Insurance Coverage'];
        } else if (subcategory == 'Cinematic Video') {
          return ['Years of Experience', 'Cinematic Style', 'Equipment', 'Color Grading'];
        } else {
          return ['Years of Experience', 'Camera Equipment', 'Specialization'];
        }
      case EventCategory.emcee:
        if (subcategory == 'Wedding Emcee') {
          return ['Years of Experience', 'Languages Spoken', 'Wedding Packages', 'Script Preparation'];
        } else if (subcategory == 'Corporate Emcee') {
          return ['Years of Experience', 'Languages Spoken', 'Corporate Events', 'Presentation Skills'];
        } else if (subcategory == 'Bilingual Host') {
          return ['Languages Spoken', 'Experience Level', 'Event Types', 'Cultural Sensitivity'];
        } else if (subcategory == 'Event Host') {
          return ['Years of Experience', 'Event Types', 'Audience Engagement', 'Improvisation Skills'];
        } else if (subcategory == 'Master of Ceremonies') {
          return ['Years of Experience', 'Ceremony Types', 'Script Writing', 'Voice Training'];
        } else {
          return ['Years of Experience', 'Languages Spoken', 'Event Types'];
        }
      case EventCategory.coordinator:
        if (subcategory == 'Wedding Coordinator') {
          return ['Years of Experience', 'Weddings Coordinated', 'Vendor Network', 'Timeline Management'];
        } else if (subcategory == 'Event Coordinator') {
          return ['Years of Experience', 'Event Types', 'Logistics Management', 'Budget Control'];
        } else if (subcategory == 'Day-of Coordinator') {
          return ['Years of Experience', 'Day-of Services', 'Vendor Coordination', 'Emergency Handling'];
        } else if (subcategory == 'Corporate Event Manager') {
          return ['Years of Experience', 'Corporate Events', 'Stakeholder Management', 'ROI Tracking'];
        } else if (subcategory == 'Party Coordinator') {
          return ['Years of Experience', 'Party Types', 'Theme Planning', 'Entertainment Booking'];
        } else {
          return ['Years of Experience', 'Event Types', 'Coordination Skills'];
        }
      case EventCategory.makeupArtist:
        return ['Makeup Styles', 'Trial Sessions', 'Products Used', 'Touch-up Service', 'Experience Level'];
      case EventCategory.hennaArtist:
        return ['Henna Styles', 'Design Complexity', 'Products Used', 'Session Duration', 'Experience Level'];
      case EventCategory.other:
        return ['General Service', 'Other'];
    }
  }

  VendorServiceEnhanced _collectServiceData(String serviceId, bool isDraft) {
    // Collect category attributes
    final categoryAttrs = <String, String>{};
    _categoryAttributes.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        categoryAttrs[key] = controller.text;
      }
    });

    // Build availability map
    final availability = <String, dynamic>{};
    _availableDays.forEach((day, available) {
      availability[day] = {
        'start': available ? '09:00' : '00:00',
        'end': available ? '18:00' : '00:00',
        'available': available,
      };
    });

    // Build options map (variations and add-ons)
    final options = <String, dynamic>{};
    
    // Store category attributes in options for persistence
    options['attributes'] = categoryAttrs;
    // Store event types
    options['eventTypes'] = _eventTypes;
    
    // Store PDF Brochure URL
    if (_servicePdfUrl != null) {
      options['pdfBrochureUrl'] = _servicePdfUrl;
    }
    
    if (_selectedPricing != null) {
      options['pricingMode'] = _selectedPricing!.name;
    }
    
    // Add catering style
    if (_selectedCategory == EventCategory.catering || _selectedType == ServiceType.package) {
      options['cateringStyle'] = _cateringStyle.name;
    }

    // Add variations
    if (_variations.isNotEmpty) {
      final variationOptions = <String, dynamic>{};
      for (var variation in _variations) {
        variationOptions[variation.name] = {
          'options': variation.options,
          'prices': variation.optionPrices,
        };
      }
      options['variations'] = variationOptions;
    }

    // Add add-ons
    if (_addOns.isNotEmpty) {
      final addOnOptions = <String, dynamic>{};
      for (var addOn in _addOns) {
        addOnOptions[addOn.name] = {
          'description': addOn.description,
          'price': addOn.price,
          'maxQuantity': addOn.maxQuantity,
          'required': addOn.isRequired,
          'isFree': addOn.isFree,
          'pricingType': addOn.pricingType.name,
        };
      }
      options['addOns'] = addOnOptions;
    }

    // Delivery logistics (product/rental)
    if (_selectedType == ServiceType.product || _selectedType == ServiceType.rental) {
      options['delivery'] = {
        'hasDelivery': _hasDelivery,
        'hasSelfPickup': _hasSelfPickup,
        'deliveryFeeType': _deliveryFeeType,
        'deliveryFee': double.tryParse(_deliveryFeeController.text) ?? 0.0,
        'freeDeliveryThreshold': double.tryParse(_freeDeliveryThresholdController.text) ?? 0.0,
        'estimatedDays': int.tryParse(_estimatedDaysController.text) ?? 3,
        'pickupAddress': _pickupAddressController.text,
        'pickupHours': _pickupHoursController.text,
        if (_selectedType == ServiceType.rental) ...{
          'rentalDeposit': double.tryParse(_rentalDepositController.text) ?? 0.0,
          'hasDamageWaiver': _hasDamageWaiver,
          'damageWaiverPct': double.tryParse(_damageWaiverPctController.text) ?? 5.0,
          'returnCondition': _returnConditionController.text,
        },
      };
    }
    if (_bulkPricingEnabled && _bulkPricingTiers.isNotEmpty) {
      options['bulkPricing'] = {
        'enabled': true,
        'tiers': List<Map<String, dynamic>>.from(_bulkPricingTiers),
      };
    }

    // Add Venue Type
    if (_selectedVenueType != null) {
      options['venueType'] = _selectedVenueType!.name;
    }

    // Add facilities
    if (_facilities.isNotEmpty) {
      options['facilities'] = _facilities;
    }

    // Add package-specific data
    if (_selectedType == ServiceType.package) {
      options['includedServices'] = _includedServices;
      options['selectedExistingServices'] = _selectedExistingServices;
      options['includedCategories'] =
          _includedCategories.map((c) => c.name).toList();

      // Collect included category attributes
      final includedCategoryAttrs = <String, Map<String, String>>{};
      _includedCategoryAttributes.forEach((category, attrs) {
        includedCategoryAttrs[category.name] = {};
        attrs.forEach((attr, controller) {
          if (controller.text.isNotEmpty) {
            includedCategoryAttrs[category.name]![attr] = controller.text;
          }
        });
      });
      options['includedCategoryAttributes'] = includedCategoryAttrs;
    }

    // Add rental information
    if (_isRentable) {
      options['rental'] = {
        'startTime': _startTime?.format(context),
        'endTime': _endTime?.format(context),
      };
    }

    // Add Weekend Pricing
    if (_hasWeekendPricing && _selectedPricing != PricingMode.tiered) {
      options['hasWeekendPricing'] = true;
      options['weekendPrice'] = double.tryParse(_weekendPriceController.text) ?? 0.0;
    }

    // Add Time Slots
    if (_selectedPricing == PricingMode.perSlot && _timeSlots.isNotEmpty) {
      options['timeSlots'] = _timeSlots.map((s) => {
        'name': s.name,
        'start': '${s.startTime.hour}:${s.startTime.minute.toString().padLeft(2, '0')}',
        'end': '${s.endTime.hour}:${s.endTime.minute.toString().padLeft(2, '0')}',
        'price': s.price,
      }).toList();
    }

    // Add Per Event Type Pricing
    if (_selectedPricing == PricingMode.perEventType) {
      final eventPricing = <String, double>{};
      _eventPricingControllers.forEach((type, controller) {
        if (controller.text.isNotEmpty) {
          eventPricing[type] = double.tryParse(controller.text) ?? 0.0;
        }
      });
      options['eventPricing'] = eventPricing;
    }

    // Build logistics map
    final logistics = <String, dynamic>{};
    if (_selectedType == ServiceType.service) {
      logistics['hasDelivery'] = false;
      logistics['deliveryFee'] = 0.0;
      logistics['deliveryRadius'] = '0km';
      logistics['hasSetup'] = false;
      logistics['hasPickup'] = false;
    }
    
    // Add venue-specific location data
    if (_mapToEventCategory(_selectedCategory) == EventCategory.venue) {
      if (_cityController.text.isNotEmpty) {
        logistics['city'] = _cityController.text;
      }
      if (_stateController.text.isNotEmpty) {
        logistics['state'] = _stateController.text;
      }
      if (_googleMapsController.text.isNotEmpty) {
        logistics['googleMapEmbed'] = _googleMapsController.text;
      }
    }

    // Determine allowed actions based on service type
    final allowedActions = <String>[];
    if (_directoryShowcaseOnly) {
      allowedActions.add('enquiry');
    } else {
      if (_selectedType == ServiceType.product) {
        allowedActions.add('buy');
      } else if (_selectedType == ServiceType.rental) {
        allowedActions.add('rent');
      } else {
        allowedActions.addAll(['book', 'enquiry']);
      }
    }

    options['directoryMode'] = _directoryShowcaseOnly;

    // Add Duration to options
    if (_durationValueController.text.isNotEmpty) {
      options['duration'] = _durationValueController.text;
      options['durationUnit'] = _durationUnit;
    }

    // Construct Time Rule
    final timeRule = ServiceTimeRule(
      serviceId: serviceId,
      timeType: _selectedTimeType,
      slotDurationMinutes: int.tryParse(_slotDurationController.text),
      minDurationMinutes: int.tryParse(_minDurationController.text),
      maxDurationMinutes: int.tryParse(_maxDurationController.text),
      durationStepMinutes: int.tryParse(_durationStepController.text) ?? 60,
      bufferBeforeMinutes: int.tryParse(_bufferBeforeController.text) ?? 0,
      bufferAfterMinutes: int.tryParse(_bufferAfterController.text) ?? 0,
      sessions: _serviceSessions,
      allowMultiDay: _allowMultiDayBooking,
      maxDays: int.tryParse(_maxDaysController.text),
      startTime: (_selectedTimeType == TimeType.fullDay || _selectedTimeType == TimeType.fixedSlot) ? _fullDayStartController.text : null,
      endTime: (_selectedTimeType == TimeType.fullDay || _selectedTimeType == TimeType.fixedSlot) ? _fullDayEndController.text : null,
    );

    // Construct Logistics Rule
    final logisticsConfig = ServiceLogistics(
      serviceId: serviceId,
      requiresVehicle: _requiresVehicle,
      vehicleType: _requiresVehicle ? _selectedVehicleType : null,
      defaultCrewCount: int.tryParse(_crewCountController.text) ?? 1,
      defaultSetupTime: double.tryParse(_setupTimeController.text) ?? 1.0,
      defaultTeardownTime: double.tryParse(_teardownTimeController.text) ?? 1.0,
      freeRadiusKm: double.tryParse(_freeRadiusController.text) ?? 20.0,
      perKmRate: double.tryParse(_perKmRateController.text) ?? 0.0,
      primaryState: _primaryState,
      parkingRequired: _parkingRequired,
      powerRequired: _powerRequired,
      overnightRequired: _overnightRequired,
      nightSurcharge: double.tryParse(_nightSurchargeController.text) ?? 0.0,
      tollParkingPolicy: _tollPolicyController.text,
      minOrderForFreeDelivery: double.tryParse(_minOrderForFreeDeliveryController.text) ?? 0.0,
    );

    return VendorServiceEnhanced(
      id: serviceId,
      vendorId: widget.vendorId,
      name: _nameController.text,
      description: _descController.text,
      productCategory: _selectedType == ServiceType.package 
          ? EventCategory.package 
          : (_selectedCategory != null ? _mapToEventCategory(_selectedCategory) : EventCategory.other),
      subcategory: _selectedSubcategory,
      multiLayerPricing: _multiLayerPricing,
      images: List<String>.from(_serviceImages), // Clone the list
      videoUrl: _serviceVideoUrl, // Added
      availability: availability,
      inventory: _selectedType == ServiceType.product ? _stockQuantity : 0,
      logistics: logistics,
      isActive: !isDraft,
      price: _pricingTiers.isNotEmpty 
          ? _pricingTiers.map((t) => t.price).reduce((a, b) => a < b ? a : b)
          : (double.tryParse(_priceController.text) ?? 0.0),
      originalPrice: _pricingTiers.isNotEmpty
          ? _pricingTiers.map((t) => t.originalPrice ?? t.price).reduce((a, b) => a < b ? a : b) // Simple fallback
          : double.tryParse(_originalPriceController.text),
      promoExpiry: _promoExpiry,
      status: isDraft ? ServiceStatus.draft : ServiceStatus.active,
      approvalStatus:
          widget.existingService?.approvalStatus ?? ApprovalStatus.pending,
      maxBookingsPerDay: 10,
      advanceBookingDays: 7,
      serviceTypes: [_selectedType ?? ServiceType.service],
      venueAddress: _locationController.text.trim(),
      coverageArea: _selectedServiceAreas.join(', '),
      options: options,
      supportsAppointments: _selectedType == ServiceType.service,
      supportsRentals: _isRentable,
      allowedActions: allowedActions,
      eventTypes: _eventTypes,
      cancellationPolicy: _cancellationPolicyType == 'custom' ? _cancellationPolicyController.text : null,
      cancellationPolicyType: _cancellationPolicyType,
      timeRule: timeRule, // Added
      logisticsConfig: logisticsConfig, // Added
      pricingTiers: _pricingTiers, // Structured templates
      components: _components, // Structured templates
      installmentEnabled: _installmentEnabled,
      depositPercentage: double.tryParse(_depositPercentageController.text),
      maxInstallments: int.tryParse(_maxInstallmentsController.text),
      paymentDeadlineDays: int.tryParse(_paymentDeadlineDaysController.text),
    );
  }

  Future<void> _pickVideo() async {
    print('VIDEO_UPLOAD: Starting video pick...');
    final XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (video == null) {
      print('VIDEO_UPLOAD: No video selected, cancelled.');
      return;
    }

    print('VIDEO_UPLOAD: Video selected — name: ${video.name}, path: ${video.path}');
    setState(() => _isUploadingVideo = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      print('VIDEO_UPLOAD: Current user ID: ${currentUser?.id}');
      if (currentUser == null) throw Exception("User not authenticated");

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${video.name}';
      final path = '${currentUser.id}/service_videos/$fileName';
      print('VIDEO_UPLOAD: Storage path: $path');

      final fileBytes = await video.readAsBytes();
      print('VIDEO_UPLOAD: File size: ${fileBytes.length} bytes');

      print('VIDEO_UPLOAD: Uploading to bucket "service-images"...');
      await supabase.storage
          .from('service-images')
          .uploadBinary(path, fileBytes);
      print('VIDEO_UPLOAD: Upload complete.');

      final videoUrl = supabase.storage
          .from('service-images')
          .getPublicUrl(path);
      print('VIDEO_UPLOAD: Public URL: $videoUrl');

      setState(() {
        _serviceVideoUrl = videoUrl;
        _isUploadingVideo = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e, stackTrace) {
      print('VIDEO_UPLOAD_ERROR: $e');
      print('VIDEO_UPLOAD_STACK: $stackTrace');
      setState(() => _isUploadingVideo = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading video: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildVideoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Service Video (Optional)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        const SizedBox(height: 8),
        const Text(
          "Upload a short promotional video for your service to attract more customers.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        if (_serviceVideoUrl != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.videocam, color: Colors.teal),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Video uploaded successfully",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _serviceVideoUrl = null),
                  child: const Text("Remove", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _isUploadingVideo ? null : _pickVideo,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: DashPainter(color: Colors.grey.shade400),
                  child: Center(
                    child: _isUploadingVideo
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_call, size: 32, color: Colors.grey.shade600),
                              const SizedBox(height: 8),
                              Text(
                                "Click to upload video",
                                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickPdf() async {
    print('PDF_UPLOAD: Starting PDF pick...');
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    
    if (result == null || result.files.isEmpty) {
      print('PDF_UPLOAD: No PDF selected, cancelled.');
      return;
    }

    final file = result.files.single;
    print('PDF_UPLOAD: PDF selected — name: ${file.name}');
    setState(() => _isUploadingPdf = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      print('PDF_UPLOAD: Current user ID: ${currentUser?.id}');
      if (currentUser == null) throw Exception("User not authenticated");

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final path = '${currentUser.id}/service_pdfs/$fileName';
      print('PDF_UPLOAD: Storage path: $path');

      final fileBytes = file.bytes;
      if (fileBytes == null) throw Exception("Could not load file bytes.");
      print('PDF_UPLOAD: File size: ${fileBytes.length} bytes');

      print('PDF_UPLOAD: Uploading to bucket "service-images"...');
      await supabase.storage
          .from('service-images')
          .uploadBinary(path, fileBytes);
      print('PDF_UPLOAD: Upload complete.');

      final pdfUrl = supabase.storage
          .from('service-images')
          .getPublicUrl(path);
      print('PDF_UPLOAD: Public URL: $pdfUrl');

      setState(() {
        _servicePdfUrl = pdfUrl;
        _isUploadingPdf = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF uploaded successfully'), backgroundColor: Colors.green),
        );
        
        final shouldExtract = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Auto-fill details?'),
            content: const Text('Would you like to use AI to automatically extract information from this brochure and fill the form?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Yes, auto-fill'),
              ),
            ],
          ),
        );

        if (shouldExtract == true && mounted) {
          await _extractPdfDetails(fileBytes);
        }
      }
    } catch (e, stackTrace) {
      print('PDF_UPLOAD_ERROR: $e');
      print('PDF_UPLOAD_STACK: $stackTrace');
      setState(() => _isUploadingPdf = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  Future<void> _extractPdfDetails(Uint8List bytes) async {
    _showLoadingDialog("Analyzing Brochure with AI...");
    try {
      final extractedList = await AiExtractionService.extractServiceDetailsFromPdf(bytes);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      if (extractedList != null && extractedList.isNotEmpty) {
        if (extractedList.length == 1) {
          // Only one item found, populate directly
          _populateFormFromExtractedData(extractedList.first);
        } else {
          // Multiple items found, let user select
          _showServiceSelectionDialog(extractedList);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not extract details. Ensure the PDF contains text or check API key.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error extracting details: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showServiceSelectionDialog(List<Map<String, dynamic>> extractedList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Multiple Services Found",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "We found multiple packages/services in your brochure. Select which one you'd like to create right now.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: extractedList.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = extractedList[index];
                      final name = item['name']?.toString() ?? 'Unnamed Service';
                      final price = item['price']?.toString() ?? 'No price';
                      final desc = item['description']?.toString() ?? 'No description available';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade50,
                          child: const Icon(Icons.business_center, color: Colors.teal),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${CurrencyFormatter.symbol} $price",
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.pop(context); // Close bottom sheet
                          _populateFormFromExtractedData(item);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _populateFormFromExtractedData(Map<String, dynamic> extractedData) {
    setState(() {
      if (extractedData['name'] != null && extractedData['name'].toString().isNotEmpty) {
        _nameController.text = extractedData['name'].toString();
      }
      if (extractedData['description'] != null && extractedData['description'].toString().isNotEmpty) {
        _descController.text = extractedData['description'].toString();
      }
      if (extractedData['price'] != null) {
        _priceController.text = extractedData['price'].toString();
      }
      if (extractedData['duration'] != null) {
        _durationValueController.text = extractedData['duration'].toString();
      }
      if (extractedData['durationUnit'] != null) {
        _durationUnit = extractedData['durationUnit'].toString();
      }
      if (extractedData['serviceType'] != null) {
        final typeStr = extractedData['serviceType'].toString().toLowerCase();
        if (typeStr.contains('package')) _selectedType = ServiceType.package;
        else if (typeStr.contains('product')) _selectedType = ServiceType.product;
        else if (typeStr.contains('rental')) _selectedType = ServiceType.rental;
        else _selectedType = ServiceType.service;
      }
      if (extractedData['stockQuantity'] != null) {
        _stockQuantity = int.tryParse(extractedData['stockQuantity'].toString()) ?? _stockQuantity;
      }
      if (extractedData['minQty'] != null) {
        _minQty = int.tryParse(extractedData['minQty'].toString()) ?? _minQty;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form auto-filled successfully!'), backgroundColor: Colors.green),
    );
  }

  Widget _buildPdfUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Service Brochure/Menu (PDF)",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        const SizedBox(height: 8),
        const Text(
          "Upload a PDF brochure or menu for your customers.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        if (_servicePdfUrl != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.teal),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "PDF uploaded successfully",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _servicePdfUrl = null),
                  child: const Text("Remove", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          )
        else
          InkWell(
            onTap: _isUploadingPdf ? null : _pickPdf,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                  painter: DashPainter(color: Colors.grey.shade400),
                  child: Center(
                    child: _isUploadingPdf
                        ? const CircularProgressIndicator()
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file, size: 32, color: Colors.grey.shade600),
                              const SizedBox(height: 8),
                              Text(
                                "Click to upload PDF",
                                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _saveService({bool isDraft = false}) async {
    if (!isDraft && !_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    // Use current ID or empty for new
    final currentId = widget.existingService?.id ?? '';
    final tempService = _collectServiceData(currentId, isDraft);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDraft ? 'Review Draft' : 'Review Submission'),
        content: SizedBox(
          width: double.maxFinite,
          child: ServiceReviewSummary(service: tempService),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Edit Further'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: Text(isDraft ? 'Confirm Save Draft' : 'Confirm & Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      final vendorProvider = Provider.of<VendorProvider>(
        context,
        listen: false,
      );

      final service = tempService;

      // Save or update the service using VendorProvider
      if (widget.existingService != null) {
        await vendorProvider.updateCustomService(widget.existingService!.id, service);
      } else {
        await vendorProvider.addCustomService(service);
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingService != null
                  ? (isDraft ? "Service updated as draft" : "Service updated successfully")
                  : (isDraft ? "Service saved as draft" : "Service submitted for review"),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Always pop back to the list screen, passing true to indicate success
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving service: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  // --- Enhanced Pricing UI Methods ---

  List<PricingMode> _getAllowedPricingModes() {
    // User requested all categories to have all pricing options
    return [
      PricingMode.flatRate,
      PricingMode.perHour,
      PricingMode.perDay,
      PricingMode.perPax,
      PricingMode.perItem,
      PricingMode.perSlot,
      PricingMode.tiered,
      PricingMode.custom,
      PricingMode.perEventType,
    ];
  }

  Future<void> _showServiceAreaSelectionDialog() async {
    final TextEditingController cityCtrl = TextEditingController();
    final adminProvider = context.read<AdminProvider>();
    if (adminProvider.regions.isEmpty) {
      await adminProvider.ensureRegionsLoaded();
    }
    if (!mounted) {
      cityCtrl.dispose();
      return;
    }
    final List<Region> allRegions = adminProvider.regions;
    final List<Region> countries = allRegions.where((r) => r.type == RegionType.country).toList();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Service Areas"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Custom City / Town Input
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cityCtrl,
                              decoration: const InputDecoration(
                                labelText: "Add Custom City / Area",
                                hintText: "e.g. New York, London, Tokyo",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onSubmitted: (val) {
                                if (val.trim().isNotEmpty) {
                                  setDialogState(() {
                                    if (!_selectedServiceAreas.contains(val.trim())) {
                                      _selectedServiceAreas.add(val.trim());
                                    }
                                    cityCtrl.clear();
                                  });
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                            onPressed: () {
                              if (cityCtrl.text.trim().isNotEmpty) {
                                setDialogState(() {
                                  final val = cityCtrl.text.trim();
                                  if (!_selectedServiceAreas.contains(val)) {
                                    _selectedServiceAreas.add(val);
                                  }
                                  cityCtrl.clear();
                                });
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text("Select by Region:", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: countries.length,
                        itemBuilder: (context, countryIndex) {
                          final country = countries[countryIndex];
                          final states = allRegions.where((r) => r.parentId == country.id && r.type == RegionType.state).toList();
                          
                          return ExpansionTile(
                            title: Text(country.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            leading: const Icon(Icons.flag, color: AppTheme.primaryColor),
                            initiallyExpanded: countryIndex == 0,
                            children: states.map((state) {
                              final cities = allRegions.where((r) => r.parentId == state.id && r.type == RegionType.city).toList();
                              final isStateSelected = _selectedServiceAreas.contains(state.name);
                              
                              // Check if all cities of this state are selected
                              final selectedCitiesCount = cities.where((c) => _selectedServiceAreas.contains(c.name)).length;
                              final allCitiesSelected = cities.isNotEmpty && selectedCitiesCount == cities.length;

                              return ExpansionTile(
                                title: Row(
                                  children: [
                                    Checkbox(
                                      value: isStateSelected,
                                      onChanged: (val) {
                                        setDialogState(() {
                                          if (val == true) {
                                            if (!_selectedServiceAreas.contains(state.name)) {
                                              _selectedServiceAreas.add(state.name);
                                            }
                                          } else {
                                            _selectedServiceAreas.remove(state.name);
                                          }
                                        });
                                        setState(() {});
                                      },
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                    Expanded(child: Text(state.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                children: [
                                  if (cities.isNotEmpty) ...[
                                    CheckboxListTile(
                                      title: const Text("Select All Cities", style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                                      value: allCitiesSelected,
                                      onChanged: (val) {
                                        setDialogState(() {
                                          for (var city in cities) {
                                            if (val == true) {
                                              if (!_selectedServiceAreas.contains(city.name)) {
                                                _selectedServiceAreas.add(city.name);
                                              }
                                            } else {
                                              _selectedServiceAreas.remove(city.name);
                                            }
                                          }
                                        });
                                        setState(() {});
                                      },
                                      controlAffinity: ListTileControlAffinity.leading,
                                      dense: true,
                                    ),
                                    ...cities.map((city) {
                                      final isCitySelected = _selectedServiceAreas.contains(city.name);
                                      return CheckboxListTile(
                                        title: Text(city.name, style: const TextStyle(fontSize: 13)),
                                        value: isCitySelected,
                                        onChanged: (val) {
                                          setDialogState(() {
                                            if (val == true) {
                                              if (!_selectedServiceAreas.contains(city.name)) {
                                                _selectedServiceAreas.add(city.name);
                                              }
                                            } else {
                                              _selectedServiceAreas.remove(city.name);
                                            }
                                          });
                                          setState(() {});
                                        },
                                        controlAffinity: ListTileControlAffinity.leading,
                                        dense: true,
                                      );
                                    }).toList(),
                                  ] else ...[
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text("No cities listed for this region", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    )
                                  ]
                                ],
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedServiceAreas.clear();
                    });
                    setDialogState(() {});
                  },
                  child: const Text("Clear All", style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () {
                    cityCtrl.dispose();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text("Done", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimeConfigurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Time & Duration Configuration",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        const SizedBox(height: 8),
        const Text(
          "Define how customers book your time. This depends on your service type (e.g. Photography is flexible, Venue is session-based).",
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<TimeType>(
          value: _selectedTimeType,
          decoration: const InputDecoration(
            labelText: "Time Model",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.timer_outlined),
          ),
          items: TimeType.values.map((e) {
            return DropdownMenuItem(
              value: e,
              child: Text(e.displayName),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedTimeType = v);
          },
        ),
        const SizedBox(height: 16),
        _buildDynamicTimeForm(),
        const SizedBox(height: 16),
        _buildBufferConfiguration(),
      ],
    );
  }

  Widget _buildDynamicTimeForm() {
    switch (_selectedTimeType) {
      case TimeType.flexibleHour:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildNumberField("Min Duration (Min)", _minDurationController),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField("Max Duration (Min)", _maxDurationController),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNumberField("Step Size (Min) - e.g. 30 or 60", _durationStepController),
          ],
        );
      case TimeType.fixedSlot:
        return Column(
          children: [
            _buildNumberField("Slot Duration (Min)", _slotDurationController),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField("Start Time (e.g. 08:00)", _fullDayStartController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField("End Time (e.g. 23:00)", _fullDayEndController)),
              ],
            ),
          ],
        );
      case TimeType.session:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._serviceSessions.map((s) => ListTile(
                  title: Text(s.name),
                  subtitle: Text("${s.startTime} - ${s.endTime}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _serviceSessions.remove(s)),
                  ),
                )),
            TextButton.icon(
              onPressed: _showAddSessionDialog,
              icon: const Icon(Icons.add),
              label: const Text("Add Session (e.g. Morning, Evening)"),
            ),
          ],
        );
      case TimeType.dateRange:
        return Column(
          children: [
            CheckboxListTile(
              title: const Text("Allow Multi-day Booking"),
              value: _allowMultiDayBooking,
              onChanged: (v) => setState(() => _allowMultiDayBooking = v ?? false),
            ),
            if (_allowMultiDayBooking)
              _buildNumberField("Max Days", _maxDaysController),
          ],
        );
      case TimeType.fullDay:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTextField("Start Time (e.g. 08:00)", _fullDayStartController)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField("End Time (e.g. 23:00)", _fullDayEndController)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Total Hours: ${_calculateTotalHours(_fullDayStartController.text, _fullDayEndController.text)}",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _calculateTotalHours(String start, String end) {
    try {
      final s = start.split(':');
      final e = end.split(':');
      final startDate = DateTime(2000, 1, 1, int.parse(s[0]), int.parse(s[1]));
      final endDate = DateTime(2000, 1, 1, int.parse(e[0]), int.parse(e[1]));
      var diff = endDate.difference(startDate).inMinutes;
      if (diff < 0) diff += 24 * 60;
      return "${(diff / 60).toStringAsFixed(1)} hours";
    } catch (_) {
      return "0 hours";
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildBufferConfiguration() {
    return Row(
      children: [
        Expanded(
          child: _buildNumberField("Buffer Before (Min)", _bufferBeforeController),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildNumberField("Buffer After (Min)", _bufferAfterController),
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _showAddSessionDialog() {
    final nameCtrl = TextEditingController();
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Session"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Session Name")),
            TextField(controller: startCtrl, decoration: const InputDecoration(labelText: "Start Time (HH:mm)")),
            TextField(controller: endCtrl, decoration: const InputDecoration(labelText: "End Time (HH:mm)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() {
                  _serviceSessions.add(ServiceSession(
                    name: nameCtrl.text,
                    startTime: startCtrl.text,
                    endTime: endCtrl.text,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _suggestTimeModelForCategory(ServiceCategory category) {
    setState(() {
      final name = category.name.toLowerCase();
      if (name.contains('catering')) {
        _selectedTimeType = TimeType.session;
        if (_serviceSessions.isEmpty) {
          _serviceSessions.addAll([
            const ServiceSession(name: 'Lunch Session', startTime: '11:00', endTime: '15:00'),
            const ServiceSession(name: 'Dinner Session', startTime: '18:00', endTime: '22:00'),
          ]);
        }
      } else if (name.contains('photograph') || name.contains('video')) {
        _selectedTimeType = TimeType.flexibleHour;
        _minDurationController.text = '120'; // 2h min
        _maxDurationController.text = '600'; // 10h max
      } else if (name.contains('venue')) {
        _selectedTimeType = TimeType.session;
        if (_serviceSessions.isEmpty) {
          _serviceSessions.addAll([
            const ServiceSession(name: 'Morning Session', startTime: '08:00', endTime: '13:00'),
            const ServiceSession(name: 'Evening Session', startTime: '17:00', endTime: '23:00'),
            const ServiceSession(name: 'Full Day', startTime: '08:00', endTime: '23:00'),
          ]);
        }
      } else if (name.contains('makeup') || name.contains('hair')) {
        _selectedTimeType = TimeType.fixedSlot;
        _slotDurationController.text = '120'; // 2h slots
      } else if (name.contains('attire') || name.contains('rental')) {
        _selectedTimeType = TimeType.dateRange;
        _allowMultiDayBooking = true;
      }
    });
  }

  String _getPricingDescription(PricingMode mode) {
    switch (mode) {
      case PricingMode.flatRate:
        return "One fixed price for this item/service.";
      case PricingMode.perHour:
        return "Charged based on duration.";
      case PricingMode.perDay:
        return "Charged per day of rental.";
      case PricingMode.perPax:
        return "Price per guest (Pax).";
      case PricingMode.perItem:
        return "Price per unit.";
      case PricingMode.tiered:
        return "Different prices for different variations.";
      case PricingMode.custom:
        return "Variable price (e.g., 'Starting from').";
      case PricingMode.perSlot:
        return "Price per booked time slot.";
      default:
        return "";
    }
  }

  Widget _buildPricingSection() {
    final modes = _getAllowedPricingModes();
     // Ensure selected pricing is valid for current type
    if (_selectedPricing == null || !modes.contains(_selectedPricing)) {
      if (modes.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedPricing = modes.first);
        });
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monetization_on_outlined, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  _selectedType == ServiceType.product ? "Product Pricing" : "Service Rates",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Pricing Strategies Segmented Control
            Container(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: modes.length,
                separatorBuilder: (c, i) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final mode = modes[index];
                  final isSelected = _selectedPricing == mode;
                  return InkWell(
                    onTap: () => setState(() => _selectedPricing = mode),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.teal : Colors.white,
                        border: Border.all(
                          color: isSelected ? Colors.teal : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ] : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getPricingIcon(mode),
                            color: isSelected ? Colors.white : Colors.teal.shade700,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getPricingModeDisplayName(mode),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 10,
                              color: isSelected ? Colors.white : Colors.black87,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            if (_selectedPricing != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getPricingDescription(_selectedPricing!),
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Pax Pricing: Show Builder
            if (_selectedPricing == PricingMode.perPax) ...[
               _buildPaxPricingSection(),
            ]
            // Tiered Pricing: Show Builder
            else if (_selectedPricing == PricingMode.tiered) ...[
               _buildPricingTiersSection(),
            ]
            // Per Event Type Pricing: Show Table
            else if (_selectedPricing == PricingMode.perEventType) ...[
               const Text(
                 "Set specific prices for each selected event type:",
                 style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
               ),
               const SizedBox(height: 12),
               if (_eventTypes.isEmpty)
                 const Text("Please select event types above first.", style: TextStyle(color: Colors.red, fontSize: 12))
               else
                 Column(
                   children: _eventTypes.map((type) {
                     if (!_eventPricingControllers.containsKey(type)) {
                       _eventPricingControllers[type] = TextEditingController()..addListener(_enforceInstallmentRules);
                     }
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 12),
                       child: TextFormField(
                         controller: _eventPricingControllers[type],
                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
                         decoration: InputDecoration(
                           labelText: "Price for $type",
                           prefixText: "${CurrencyFormatter.symbol} ",
                           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                         ),
                       ),
                     );
                   }).toList(),
                 ),
            ] 
            // Standard Pricing: Show Input
            else ...[
               SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Show Price Publicly"),
                  value: _showPrice,
                  onChanged: (v) => setState(() => _showPrice = v),
               ),
               if (_showPrice) ...[
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
                    decoration: InputDecoration(
                      labelText: _getPriceLabel(),
                      prefixText: "${CurrencyFormatter.symbol} ",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (v) {
                       if (!_showPrice) return null;
                       if (v == null || v.isEmpty) return "Required";
                       if (double.tryParse(v) == null) return "Invalid price";
                       return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _originalPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: "Original Price (Optional)",
                            prefixText: "${CurrencyFormatter.symbol} ",
                            hintText: "Cut price",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _promoExpiry ?? DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() => _promoExpiry = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: Colors.teal.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _promoExpiry == null 
                                      ? "Expiry Date" 
                                      : DateFormat('dd MMM yyyy').format(_promoExpiry!),
                                    style: TextStyle(
                                      color: _promoExpiry == null ? Colors.grey.shade600 : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (_promoExpiry != null)
                                  GestureDetector(
                                    onTap: () => setState(() => _promoExpiry = null),
                                    child: const Icon(Icons.close, size: 18),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
               ] else
                 const Text("Price hidden. Customers will request a quote."),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaxPricingSection() {
    // We filter tiers that look like pax pricing (have minPax)
    // or just show all tiers since we are in "Pricing by Pax" mode
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pricing by Pax (Min Guest Count)", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_pricingTiers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("No pax pricing tiers added yet.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          ),
          
        ..._pricingTiers.map((tier) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text("${tier.minPax} Pax"),
            subtitle: tier.originalPrice != null 
                ? Text("Promo: ${CurrencyFormatter.symbol} ${tier.price.toStringAsFixed(2)} (Was: ${CurrencyFormatter.symbol} ${tier.originalPrice!.toStringAsFixed(2)})") 
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (tier.originalPrice != null)
                      Text(
                        "${CurrencyFormatter.symbol} ${tier.originalPrice!.toStringAsFixed(2)}",
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      "${CurrencyFormatter.symbol} ${tier.price.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () {
                     setState(() {
                       _pricingTiers.remove(tier);
                       if (_multiLayerPricing.containsKey(tier.minPax.toString())) {
                         _multiLayerPricing.remove(tier.minPax.toString());
                       }
                       _enforceInstallmentRules();
                     });
                  },
                ),
              ],
            ),
          ),
        )),
        
        const SizedBox(height: 16),
        const Text("Add New Pax Tier", style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _paxCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Pax Count", 
                  hintText: "e.g. 50",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _paxPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Price", 
                  prefixText: "${CurrencyFormatter.symbol} ",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _paxOriginalPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Original (Opt)", 
                  prefixText: "${CurrencyFormatter.symbol} ",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  helperText: "For struck-through price",
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _paxPromoExpiry ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _paxPromoExpiry = date);
                  }
                },
                child: Container(
                  height: 48, // Match input height roughly
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade500),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _paxPromoExpiry == null 
                            ? "Expiry" 
                            : DateFormat('dd/MM').format(_paxPromoExpiry!),
                          style: TextStyle(
                            fontSize: 13,
                            color: _paxPromoExpiry == null ? Colors.grey.shade700 : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_paxPromoExpiry != null)
                        GestureDetector(
                          onTap: () => setState(() => _paxPromoExpiry = null),
                          child: const Icon(Icons.close, size: 16),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 48,
              alignment: Alignment.topCenter,
              child: ElevatedButton(
                onPressed: () {
                  final count = _paxCountController.text;
                  final price = double.tryParse(_paxPriceController.text);
                  final original = double.tryParse(_paxOriginalPriceController.text);
                  
                  if (count.isNotEmpty && price != null) {
                    setState(() {
                      // Add to Pricing Tiers
                      _pricingTiers.add(ServicePricingTier(
                        name: "$count Pax",
                        price: price,
                        minPax: int.tryParse(count) ?? 1,
                        maxPax: int.tryParse(count) ?? 1,
                        originalPrice: original,
                        promoExpiry: _paxPromoExpiry,
                      ));
                      
                      // Legacy Sync (Optional, but keeps map populated for now if needed elsewhere)
                      _multiLayerPricing[count] = price;
                      
                      // Clear inputs
                      _paxCountController.clear();
                      _paxPriceController.clear();
                      _paxOriginalPriceController.clear();
                      _paxPromoExpiry = null;
                      _enforceInstallmentRules();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Icon(Icons.add),
              ),
            ),
           ],
        ),
      ],
    );
  }

  String _getPricingModeDisplayName(PricingMode mode) {
    switch (mode) {
      case PricingMode.flatRate: return "FLAT RATE";
      case PricingMode.perHour: return "HOURLY";
      case PricingMode.perDay: return "DAILY";
      case PricingMode.perPax: return "PER PAX";
      case PricingMode.perItem: return "PER ITEM";
      case PricingMode.perSlot: return "PER SLOT";
      case PricingMode.perArea: return "PER AREA";
      case PricingMode.custom: return "CUSTOM";
      case PricingMode.tiered: return "TIERED";
      case PricingMode.perEventType: return "EVENT TYPE";
      default: return mode.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').toUpperCase();
    }
  }

  IconData _getPricingIcon(PricingMode mode) {
    switch (mode) {
      case PricingMode.flatRate: return Icons.local_offer_outlined;
      case PricingMode.perHour: return Icons.access_time;
      case PricingMode.perDay: return Icons.calendar_today;
      case PricingMode.perPax: return Icons.people_outline;
      case PricingMode.perItem: return Icons.category_outlined;
      case PricingMode.tiered: return Icons.layers_outlined;
      case PricingMode.custom: return Icons.request_quote_outlined;
      case PricingMode.perSlot: return Icons.event_available;
      default: return Icons.attach_money;
    }
  }

  String _getPriceLabel() {
    switch (_selectedPricing) {
      case PricingMode.perHour: return "Hourly Rate";
      case PricingMode.perDay: return "Daily Rate";
      case PricingMode.perPax: return "Price Per Pax";
      case PricingMode.custom: return "Starting From";
      case PricingMode.perSlot: return "Price Per Slot";
      default: return "Unit Price";
    }
  }

  Widget _buildCancellationPolicySection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.policy_outlined, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  "Cancellation Policy",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                RadioListTile<String>(
                  title: const Text("Use Platform Policy"),
                  subtitle: const Text("Standard cancellations policy applied by the platform."),
                  value: 'platform',
                  groupValue: _cancellationPolicyType,
                  onChanged: (value) {
                    setState(() {
                      _cancellationPolicyType = value!;
                    });
                  },
                  activeColor: Colors.teal,
                ),
                RadioListTile<String>(
                  title: const Text("Custom Policy"),
                  subtitle: const Text("Set your own specific cancellation terms."),
                  value: 'custom',
                  groupValue: _cancellationPolicyType,
                  onChanged: (value) {
                    setState(() {
                      _cancellationPolicyType = value!;
                    });
                  },
                  activeColor: Colors.teal,
                ),
              ],
            ),
            if (_cancellationPolicyType == 'custom') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _cancellationPolicyController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Custom Policy Terms",
                  hintText: "Enter your cancellation terms here...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (v) {
                  if (_cancellationPolicyType == 'custom' && (v == null || v.isEmpty)) {
                    return "Custom policy terms are required";
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsConfigurationSection() {
    final cat = _selectedCategory != null ? _mapToEventCategory(_selectedCategory) : null;
    
    // Only show for relevant categories
    final relevantCategories = [
      EventCategory.catering,
      EventCategory.photography,
      EventCategory.videography,
      EventCategory.decoration,
      EventCategory.entertainment,
      EventCategory.emcee,
      EventCategory.coordinator,
      EventCategory.transportation,
      EventCategory.equipment,
      EventCategory.doorgift,
      EventCategory.beauty,
      EventCategory.package,
    ];

    if (cat != null && !relevantCategories.contains(cat)) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: Colors.teal),
                SizedBox(width: 8),
                Text(
                  "Logistics & Operations",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Define your operational requirements and travel policies. This ensures transparent pricing for your logistics effort.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Resource Requirements
            const Text("Resource Requirements", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text("Requires Transport Vehicle?"),
              subtitle: const Text("Enable if you need a van/lorry for equipment."),
              contentPadding: EdgeInsets.zero,
              value: _requiresVehicle,
              activeColor: Colors.teal,
              onChanged: (v) => setState(() => _requiresVehicle = v),
            ),
            if (_requiresVehicle) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<VehicleType>(
                value: _selectedVehicleType,
                decoration: const InputDecoration(labelText: "Vehicle Type", border: OutlineInputBorder()),
                items: VehicleType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.displayName))).toList(),
                onChanged: (v) => setState(() => _selectedVehicleType = v ?? VehicleType.van),
              ),
            ],
            const SizedBox(height: 16),
            _buildNumberField("Default Crew Count", _crewCountController),
            const SizedBox(height: 24),
            
            // Timeline
            const Text("Operational Timeline", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildNumberField("Setup Time (Hours)", _setupTimeController)),
                const SizedBox(width: 12),
                Expanded(child: _buildNumberField("Teardown Time (Hours)", _teardownTimeController)),
              ],
            ),
            const Divider(height: 48),
            
            // Coverage & Fees
            const Row(
              children: [
                Icon(Icons.map_outlined, color: Colors.teal, size: 20),
                SizedBox(width: 8),
                Text("Travel & Service Radius", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildNumberField("Free Radius (KM)", _freeRadiusController)),
                const SizedBox(width: 12),
                Expanded(child: _buildNumberField("Fee per KM (Above Free)", _perKmRateController)),
              ],
            ),
            const SizedBox(height: 24),
            
            // NEW: Free Delivery Policy
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.redeem, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text("Free Delivery Policy", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildNumberField("Minimum Order Amount for Free Delivery (${CurrencyFormatter.symbol})", _minOrderForFreeDeliveryController),
                  const SizedBox(height: 8),
                  const Text(
                    "If the total booking value exceeds this amount, the travel fee based on distance will be waived automatically.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 48),

            const Text("Policies", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text("Parking Required at Site"),
              contentPadding: EdgeInsets.zero,
              value: _parkingRequired,
              activeColor: Colors.teal,
              onChanged: (v) => setState(() => _parkingRequired = v ?? false),
            ),
            CheckboxListTile(
              title: const Text("Power Required at Site"),
              contentPadding: EdgeInsets.zero,
              value: _powerRequired,
              activeColor: Colors.teal,
              onChanged: (v) => setState(() => _powerRequired = v ?? false),
            ),
            CheckboxListTile(
              title: const Text("Overnight Stay Required (for long distance)"),
              contentPadding: EdgeInsets.zero,
              value: _overnightRequired,
              activeColor: Colors.teal,
              onChanged: (v) => setState(() => _overnightRequired = v ?? false),
            ),
            const SizedBox(height: 16),
            _buildNumberField("Late Night / Night Work Surcharge (${CurrencyFormatter.symbol})", _nightSurchargeController),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tollPolicyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Toll & Parking Policy", 
                border: OutlineInputBorder(),
                hintText: "State your policy on claims...",
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Service Template Helpers ---

  Widget _buildPricingTiersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Service Rates / Packages",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        const Text("Create different rates or packages (e.g. Wedding Package, Nikah Only, Special Rate). Guest counts (Pax) are optional.", style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        if (_pricingTiers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(child: Text("No rates added yet. Click 'Add Service Rate' to define your first rate.", style: TextStyle(color: Colors.black87))),
              ],
            ),
          ),
        ..._pricingTiers.mapIndexed((index, tier) {
          final showPax = (tier.minPax > 0 || (tier.maxPax ?? 0) > 0);
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Expanded(
                         child: Text(
                           tier.name ?? "Rate ${index + 1}",
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                         ),
                       ),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                           color: AppTheme.primaryColor.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.end,
                           children: [
                             if (tier.originalPrice != null)
                               Text(
                                 "${CurrencyFormatter.symbol} ${tier.originalPrice!.toStringAsFixed(0)}",
                                 style: const TextStyle(
                                   color: Colors.grey,
                                   fontSize: 12,
                                   decoration: TextDecoration.lineThrough,
                                 ),
                               ),
                             Text(
                               "${CurrencyFormatter.symbol} ${tier.price.toStringAsFixed(0)}",
                               style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                   if (showPax || tier.promoExpiry != null) ...[
                     const SizedBox(height: 8),
                     Row(
                       children: [
                         if (showPax) ...[
                           const Icon(Icons.people, size: 16, color: Colors.grey),
                           const SizedBox(width: 4),
                           Text(
                             "${tier.minPax} - ${tier.maxPax ?? 'Unlimited'} Pax",
                             style: const TextStyle(color: Colors.grey, fontSize: 13),
                           ),
                         ],
                         if (showPax && tier.promoExpiry != null) const SizedBox(width: 16),
                         if (tier.promoExpiry != null) ...[
                           const Icon(Icons.timer_outlined, size: 16, color: Colors.orange),
                           const SizedBox(width: 4),
                           Text(
                             "Ends: ${DateFormat('dd MMM').format(tier.promoExpiry!)}",
                             style: const TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w500),
                           ),
                         ],
                       ],
                     ),
                   ],
                   if (tier.description != null && tier.description!.isNotEmpty) ...[
                     const SizedBox(height: 8),
                     Text(tier.description!, style: const TextStyle(color: Colors.black87, fontSize: 13)),
                   ],
                   const Divider(),
                   Align(
                     alignment: Alignment.centerRight,
                     child: TextButton.icon(
                       icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                       label: const Text("Remove", style: TextStyle(color: Colors.red)),
                        onPressed: () {
                          setState(() {
                            _pricingTiers.removeAt(index);
                            _enforceInstallmentRules();
                          });
                        },
                     ),
                   ),
                ],
              ),
            ),
          );
        }).toList(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addPricingTierDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
            ),
            icon: const Icon(Icons.add_circle_outline, size: 20),
            label: const Text(
              "Add Service Rate / Package",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addPricingTierDialog() async {
    final minPaxCtrl = TextEditingController();
    final maxPaxCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final originalPriceCtrl = TextEditingController(); // Added
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? selectedExpiry; // Added

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // Use StatefulBuilder for date picker update
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Service Rate"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Rate Name (e.g. Nikah Only)", hintText: "Enter a descriptive name")),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: minPaxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Min Pax (Optional)"))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: maxPaxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Max Pax (Optional)"))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: "Promo Price (${CurrencyFormatter.symbol})", prefixText: "${CurrencyFormatter.symbol} "))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: originalPriceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: "Original Price (Optional)", prefixText: "${CurrencyFormatter.symbol} ", hintText: "Cut price"))),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Description (Optional)")),
                const SizedBox(height: 12),
                
                // Promotion Expiry Picker
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Promotion Expiry (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedExpiry = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Text(selectedExpiry == null ? "Set Expiry Date" : DateFormat('dd MMM yyyy').format(selectedExpiry!), style: TextStyle(color: selectedExpiry == null ? Colors.grey : Colors.black87)),
                        if (selectedExpiry != null)
                          const Spacer(),
                        if (selectedExpiry != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => setDialogState(() => selectedExpiry = null),
                          )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (priceCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                  setState(() {
                    _pricingTiers.add(ServicePricingTier(
                      id: UniqueKey().toString(), // Assign a unique ID for referencing
                      name: nameCtrl.text,
                      minPax: int.tryParse(minPaxCtrl.text) ?? 0,
                      maxPax: int.tryParse(maxPaxCtrl.text),
                      price: double.tryParse(priceCtrl.text) ?? 0.0,
                      originalPrice: double.tryParse(originalPriceCtrl.text),
                      promoExpiry: selectedExpiry,
                      description: descCtrl.text.isNotEmpty ? descCtrl.text : null,
                    ));
                    _enforceInstallmentRules();
                  });
                  Navigator.pop(context);
                } else if (nameCtrl.text.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a rate name")));
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //   CATERING SERVICE CONFIGURATOR  (free-form, any catering variation)
  // ─────────────────────────────────────────────────────────────────────────
  //
  //  Data mapping:
  //    • Pricing tiers  → _pricingTiers  (ServicePricingTier)
  //    • Item-list sections → _components  (componentType: 'catering_section')
  //    • Add-on sections    → _addOns     (AddOn)
  //

  /// All item-list components added by the vendor.
  List<ServiceComponent> get _cateringSectionComponents =>
      _components
          .where((c) => c.componentType == 'catering_section')
          .toList();

  Widget _buildCateringConfigurator() {
    const tealDark = Color(0xFF00695C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Banner ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF004D40), Color(0xFF00897B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.restaurant, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Catering Service Builder',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    SizedBox(height: 2),
                    Text(
                      'Add any sections your service needs — pricing, menus, add-ons, or anything else.',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── 1. Pricing Tiers (always useful) ─────────────────────
        _cfgCard(
          icon: Icons.people_alt_outlined,
          title: 'Pricing / Packages',
          subtitle: 'e.g. 300 Pax – RM 4,500 · 500 Pax – RM 7,500',
          accentColor: const Color(0xFF1565C0),
          child: _buildCfgPricingTiers(),
        ),

        const SizedBox(height: 12),

        // ── 2. Free-form sections (vendor creates any they need) ──
        ..._cateringSectionComponents.map(
          (comp) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCfgSectionCard(comp),
          ),
        ),

        // ── 3. Add-Ons ────────────────────────────────────────────
        _cfgCard(
          icon: Icons.add_shopping_cart_outlined,
          title: 'Optional Add-Ons',
          subtitle: 'Items customers can add at booking (with price)',
          accentColor: const Color(0xFFE65100),
          child: _buildCfgAddOns(),
        ),

        const SizedBox(height: 16),

        // ── "Add Section" button ──────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showAddCfgSectionDialog,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Add Custom Section'),
            style: OutlinedButton.styleFrom(
              foregroundColor: tealDark,
              side: const BorderSide(color: Color(0xFF00897B)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  // ── Card wrapper ─────────────────────────────────────────────────────────

  Widget _cfgCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: accentColor)),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  // ── 1. Pricing tiers ─────────────────────────────────────────────────────

  Widget _buildCfgPricingTiers() {
    const accent = Color(0xFF1565C0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_pricingTiers.isEmpty)
          _cfgEmptyHint('No pricing tiers yet.'),

        for (int i = 0; i < _pricingTiers.length; i++)
          _buildCfgTierRow(_pricingTiers[i], i),

        const SizedBox(height: 10),
        const Text('Add Tier',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _cfgTextField(
                controller: _paxCountController,
                hint: 'Pax (e.g. 300)',
                numeric: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: _cfgTextField(
                controller: _paxPriceController,
                hint: 'Price',
                numeric: true,
                prefix: '${CurrencyFormatter.symbol} ',
              ),
            ),
            const SizedBox(width: 8),
            _cfgAddBtn(
              color: accent,
              onPressed: () {
                final count = _paxCountController.text.trim();
                final price = double.tryParse(_paxPriceController.text);
                if (count.isEmpty || price == null) return;
                setState(() {
                  _pricingTiers.add(ServicePricingTier(
                    name: '$count Pax',
                    price: price,
                    minPax: int.tryParse(count) ?? 1,
                    maxPax: int.tryParse(count) ?? 1,
                  ));
                  _multiLayerPricing[count] = price;
                  _paxCountController.clear();
                  _paxPriceController.clear();
                  _enforceInstallmentRules();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCfgTierRow(ServicePricingTier tier, int i) {
    const accent = Color(0xFF1565C0);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, size: 15, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text('${tier.minPax} Pax',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Text(
            '${CurrencyFormatter.symbol} ${tier.price.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: accent, fontSize: 13),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() {
              _pricingTiers.removeAt(i);
              _multiLayerPricing.remove(tier.minPax.toString());
              _enforceInstallmentRules();
            }),
            child: const Icon(Icons.close, size: 16, color: Colors.red),
          ),
        ],
      ),
    );
  }

  // ── 2. Free-form item-list section cards ─────────────────────────────────

  Widget _buildCfgSectionCard(ServiceComponent comp) {
    final compIdx = _components.indexOf(comp);
    const accent = Color(0xFF2E7D32);

    // Find parent section name if it is a nested section
    String? parentName;
    if (comp.parentComponentId != null) {
      final p = _components.firstWhere(
        (c) => c.id == comp.parentComponentId || c.name == comp.parentComponentId,
        orElse: () => ServiceComponent(componentType: '', name: ''),
      );
      if (p.name.isNotEmpty) {
        parentName = p.name;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header + delete
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: parentName != null ? accent.withOpacity(0.03) : accent.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: accent.withOpacity(0.15))),
            ),
            child: Row(
              children: [
                Icon(
                  parentName != null ? Icons.subdirectory_arrow_right : Icons.list_alt_outlined,
                  color: accent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comp.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13, color: accent),
                      ),
                      if (parentName != null)
                        Text(
                          'Part of: $parentName',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
                if (comp.description != null && comp.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(comp.description!,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ),
                GestureDetector(
                  onTap: () => setState(() {
                    // Remove both the component and any child components that reference it
                    final toRemove = [comp.id, comp.name];
                    _components.removeWhere((c) => 
                      c.id == comp.id || 
                      (c.parentComponentId != null && toRemove.contains(c.parentComponentId))
                    );
                  }),
                  child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                ),
              ],
            ),
          ),

          // Items list + inline add + Selection limit control
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selection Limit Config & Optional Toggle
                Row(
                  children: [
                    const Text(
                      'Selection Rule:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: comp.selectionLimit,
                      isDense: true,
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                      items: [
                        const DropdownMenuItem<int>(
                          value: 0,
                          child: Text('All Included'),
                        ),
                        ...List.generate(10, (index) => DropdownMenuItem<int>(
                          value: index + 1,
                          child: Text('Pick ${index + 1}'),
                        )),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _components[compIdx] = comp.copyWith(selectionLimit: val);
                          });
                        }
                      },
                    ),
                    const Spacer(),
                    // Optional toggle: Allows customer to choose this section or opt out of it (e.g. choose between Option 1 / Option 2)
                    const Text(
                      'Optional Section:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: comp.isOptional,
                      onChanged: (val) {
                        setState(() {
                          _components[compIdx] = comp.copyWith(isOptional: val);
                        });
                      },
                      activeColor: accent,
                    ),
                  ],
                ),
                const Divider(height: 16),

                if (comp.items.isEmpty)
                  _cfgEmptyHint('No items yet — add below'),

                ...comp.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Icon(Icons.fiber_manual_record,
                          size: 6, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(item.name,
                              style: const TextStyle(fontSize: 13))),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            final updated = List<ServiceItem>.from(comp.items)..remove(item);
                            _components[compIdx] = comp.copyWith(items: updated);
                          });
                        },
                        child: const Icon(Icons.close, size: 14, color: Colors.red),
                      ),
                    ],
                  ),
                )),

                const SizedBox(height: 8),
                _buildCfgInlineItemAdd(comp, compIdx),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCfgInlineItemAdd(ServiceComponent comp, int compIdx) {
    final ctrl = TextEditingController();
    const accent = Color(0xFF2E7D32);
    return StatefulBuilder(builder: (ctx, ss) {
      return Row(
        children: [
          Expanded(
            child: _cfgTextField(controller: ctrl, hint: 'Add item…'),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              final v = ctrl.text.trim();
              if (v.isEmpty) return;
              setState(() {
                final updated = List<ServiceItem>.from(comp.items)
                  ..add(ServiceItem(name: v));
                _components[compIdx] = comp.copyWith(items: updated);
              });
              ctrl.clear();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, size: 18, color: accent),
            ),
          ),
        ],
      );
    });
  }

  // ── Dialog: add a new custom section ─────────────────────────────────────

  Future<void> _showAddCfgSectionDialog() async {
    final nameCtrl = TextEditingController();
    bool isOptionalSection = false;
    String? selectedParentId;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Get candidate parent sections (only top-level sections that are not already sub-sections themselves)
          final topLevelSections = _components
              .where((c) => c.componentType == 'catering_section' && c.parentComponentId == null)
              .toList();

          return AlertDialog(
            title: const Text('Add Section'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Give this section a name — e.g. "Main Menu", "Rice", "Hi-Tea", "Kuih" etc.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Section name',
                      hintText: 'e.g. Rice / Hi-Tea',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Parent section dropdown for nested structures
                  if (topLevelSections.isNotEmpty) ...[
                    const Text(
                      'Parent Session / Section (Optional):',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedParentId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      hint: const Text('None (Top-Level Session)'),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('None (Top-Level Session)'),
                        ),
                        ...topLevelSections.map((parent) => DropdownMenuItem<String>(
                          value: parent.id ?? parent.name, // Fallback to name if ID is not yet saved/generated
                          child: Text(parent.name),
                        )),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedParentId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  CheckboxListTile(
                    title: const Text(
                      'Optional Section (Customer chooses between options)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    contentPadding: EdgeInsets.zero,
                    value: isOptionalSection,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          isOptionalSection = val;
                        });
                      }
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty) return;
                  
                  // Generate a temporary local ID if none exists, so child sections can reference it immediately
                  final tempId = UniqueKey().toString();
                  
                  setState(() {
                    _components.add(ServiceComponent(
                      id: tempId,
                      componentType: 'catering_section',
                      name: nameCtrl.text.trim(),
                      parentComponentId: selectedParentId,
                      isOptional: isOptionalSection,
                      items: const [],
                    ));
                  });
                  Navigator.pop(context);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── 3. Add-ons ───────────────────────────────────────────────────────────

  Widget _buildCfgAddOns() {
    const accent = Color(0xFFE65100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_addOns.isEmpty)
          _cfgEmptyHint('No add-ons yet.'),

        for (int i = 0; i < _addOns.length; i++)
          _buildCfgAddOnRow(_addOns[i], i),

        const SizedBox(height: 8),
        _buildCfgAddOnInlineRow(),

        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _addAddOnDialog,
          icon: const Icon(Icons.tune, size: 14),
          label: const Text('More add-on options', style: TextStyle(fontSize: 11)),
          style: TextButton.styleFrom(
            foregroundColor: accent,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildCfgAddOnRow(AddOn addOn, int i) {
    const accent = Color(0xFFE65100);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_circle_outline, size: 15, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addOn.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                addOn.isFree
                    ? const Text('Free',
                        style: TextStyle(fontSize: 11, color: Colors.green))
                    : Text(
                        '${CurrencyFormatter.symbol} ${addOn.price.toStringAsFixed(2)} / ${_formatPricingType(addOn.pricingType)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _addOns.removeAt(i)),
            child: const Icon(Icons.close, size: 16, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildCfgAddOnInlineRow() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    const accent = Color(0xFFE65100);
    return StatefulBuilder(builder: (ctx, ss) {
      return Row(
        children: [
          Expanded(
            flex: 3,
            child: _cfgTextField(controller: nameCtrl, hint: 'Add-on name'),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: _cfgTextField(
              controller: priceCtrl,
              hint: 'Price',
              numeric: true,
              prefix: '${CurrencyFormatter.symbol} ',
            ),
          ),
          const SizedBox(width: 6),
          _cfgAddBtn(
            color: accent,
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              setState(() {
                _addOns.add(AddOn(
                  name: nameCtrl.text.trim(),
                  description: '',
                  price: price,
                  isFree: price == 0.0,
                ));
              });
              nameCtrl.clear();
              priceCtrl.clear();
            },
          ),
        ],
      );
    });
  }

  // ── Shared helpers ───────────────────────────────────────────────────────

  Widget _cfgTextField({
    required TextEditingController controller,
    required String hint,
    bool numeric = false,
    String? prefix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefix,
        hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }

  Widget _cfgAddBtn({required Color color, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(42, 42),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Icon(Icons.add, size: 20),
    );
  }

  Widget _cfgEmptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic)),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //   END CATERING SERVICE CONFIGURATOR
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCateringMenuSection() {
    final bool isCateringService = _mapToEventCategory(_selectedCategory) == EventCategory.catering;
    final bool isPackageWithCatering = _selectedType == ServiceType.package && 
                                        _includedCategories.contains(EventCategory.catering);
    
    if (!isCateringService && !isPackageWithCatering) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    "Catering Menu",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Define your food & beverage sets",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CateringStyle>(
                    value: _cateringStyle,
                    icon: const Icon(Icons.tune, size: 18, color: Colors.teal),
                    isDense: true,
                    onChanged: (v) => setState(() => _cateringStyle = v!),
                    items: CateringStyle.values.map((s) {
                       String label = "";
                       switch(s) {
                         case CateringStyle.flat: label = "Standard List"; break;
                         case CateringStyle.simpleSets: label = "Simple Sets"; break;
                         case CateringStyle.complexSets: label = "Sets + Categories"; break;
                       }
                       return DropdownMenuItem(value: s, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.teal.shade900)));
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          if (_cateringStyle == CateringStyle.complexSets || _cateringStyle == CateringStyle.simpleSets)
            ..._buildHierarchicalComponents()
          else
            ..._components.where((c) => c.componentType == 'catering' || (c.componentType == 'category' && c.parentComponentId == null))
                .mapIndexed((index, component) {
                  return _buildComponentCard(component, _components.indexOf(component));
                }).toList(),

          if (_components.isEmpty)
             Center(
               child: Padding(
                 padding: const EdgeInsets.symmetric(vertical: 20),
                 child: Column(
                   children: [
                     Icon(Icons.restaurant_menu, size: 40, color: Colors.grey.shade300),
                     const SizedBox(height: 8),
                     Text("No menu items yet", style: TextStyle(color: Colors.grey.shade500)),
                   ],
                 ),
               ),
             ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addComponentDialog(isCateringContext: true),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.teal.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text("Add Menu Item / Set"),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHierarchicalComponents() {
    final sets = _components.where((c) => c.componentType == 'set').toList();
    final lonelyComponents = _components.where((c) => c.componentType != 'set' && c.parentComponentId == null).toList();
    
    final List<Widget> widgets = [];

    for (var set in sets) {
      final children = _components.where((c) => c.parentComponentId == set.id).toList();
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            children: [
              ListTile(
                title: Text(set.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                subtitle: _cateringStyle == CateringStyle.simpleSets 
                    ? Text("${set.items.length} items", style: TextStyle(fontSize: 12, color: Colors.blue.shade700))
                    : Text("${children.length} categories", style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                      onPressed: () {
                         // TODO: Edit set name logic
                      },
                    ),
                     IconButton(
                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                      onPressed: () => setState(() => _components.remove(set)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (_cateringStyle == CateringStyle.simpleSets) ...[
                       _buildItemsSummary(set), // Changed from _buildItemsList
                    ] else ...[
                       ...children.mapIndexed((i, child) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildComponentCard(child, _components.indexOf(child), isNested: true),
                       )),
                    ]
                  ],
                ),
              ),
            ],
          ),
        )
      );
    }

    for (var component in lonelyComponents) {
      widgets.add(_buildComponentCard(component, _components.indexOf(component)));
    }

    return widgets;
  }

  Widget _buildComponentCard(ServiceComponent component, int index, {bool isNested = false}) {
    final matchingCategory = EventCategory.values.firstWhereOrNull((e) => e.id == component.componentType);
    final itemsCount = component.items.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isNested ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isNested ? Colors.grey.shade300 : Colors.grey.shade200),
        boxShadow: [
          if (!isNested) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PackageComponentConfigScreen(
                  component: component,
                  category: matchingCategory ?? EventCategory.other,
                ),
              ),
            );
            
            if (result != null && result is ServiceComponent) {
              setState(() {
                _components[index] = result;
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (matchingCategory?.icon != null ? AppTheme.primaryColor : Colors.teal).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    matchingCategory?.icon ?? (isNested ? Icons.subdirectory_arrow_right : Icons.category_outlined), 
                    size: 20, 
                    color: matchingCategory?.icon != null ? AppTheme.primaryColor : Colors.teal
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        component.name, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                      ),
                      Text(
                        "$itemsCount configured ${itemsCount == 1 ? 'item' : 'items'}",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: () {
                     setState(() {
                       _components.removeAt(index);
                       // Also remove from _includedCategories if it matches
                       if (matchingCategory != null) {
                         _includedCategories.remove(matchingCategory);
                       }
                     });
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsSummary(ServiceComponent component) {
    if (component.items.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: component.items.take(5).map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name, 
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700)
                ),
                if (item.isFree) ...[
                  const SizedBox(width: 4),
                  const Text('FREE', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
                ] else if (item.isConditionalFree) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline, size: 10, color: Colors.orange),
                ],
              ],
            ),
          )).toList(),
        ),
        if (component.items.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "+ ${component.items.length - 5} more...",
              style: TextStyle(fontSize: 10, color: AppTheme.primaryColor),
            ),
          ),
      ],
    );
  }

  Widget _buildPackageCategoriesGenericSection() {
    // Only show for packages
    if (_selectedType != ServiceType.package) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Included Categories Selection
          _buildIncludedCategoriesSection(),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          // 2. Package Structure Header & Layout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text(
                    "Package Structure",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Organize your package contents",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (_includedCategories.contains(EventCategory.catering))
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12),
                   decoration: BoxDecoration(
                     color: Colors.deepPurple.shade50,
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: Colors.deepPurple.shade100),
                   ),
                   child: DropdownButtonHideUnderline(
                     child: DropdownButton<CateringStyle>(
                       value: _cateringStyle,
                        icon: const Icon(Icons.tune, size: 18, color: Colors.deepPurple),
                       isDense: true,
                       onChanged: (v) => setState(() => _cateringStyle = v!),
                       items: CateringStyle.values.map((s) {
                          String label = "";
                          switch(s) {
                            case CateringStyle.flat: label = "Standard List"; break;
                            case CateringStyle.simpleSets: label = "Simple Sets"; break;
                            case CateringStyle.complexSets: label = "Sets + Categories"; break;
                          }
                          return DropdownMenuItem(value: s, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.deepPurple.shade900)));
                       }).toList(),
                     ),
                   ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          if (_cateringStyle == CateringStyle.complexSets || _cateringStyle == CateringStyle.simpleSets)
            ..._buildHierarchicalComponents()
          else
            ..._components.where((c) => c.componentType != 'set' && c.parentComponentId == null)
                .mapIndexed((index, component) {
                  return _buildComponentCard(component, _components.indexOf(component));
                }).toList(),

          if (_components.isEmpty)
             Center(
               child: Padding(
                 padding: const EdgeInsets.symmetric(vertical: 20),
                 child: Column(
                   children: [
                     Icon(Icons.layers_clear, size: 40, color: Colors.grey.shade300),
                     const SizedBox(height: 8),
                     Text("No package items yet", style: TextStyle(color: Colors.grey.shade500)),
                   ],
                 ),
               ),
             ),

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addComponentDialog(isCateringContext: false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.deepPurple.shade200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text("Add Category"),
                ),
              ),
              if (_cateringStyle == CateringStyle.simpleSets || _cateringStyle == CateringStyle.complexSets) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addComponentDialog(isCateringContext: false, forceSet: true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.deepPurple.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.layers, size: 18),
                    label: const Text("Add Set"),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Updated _addComponentDialog to accept forceSet and manage types better
  Future<void> _addComponentDialog({String? parentComponentId, bool isCateringContext = false, bool forceSet = false}) async {
    final nameCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: '0');
    
    // Default type logic
    String selectedType = 'decoration';
    
    // If forcing a set (e.g. "Combo A", "Photography Package A")
    if (forceSet) {
      selectedType = 'set';
    } else if (isCateringContext) {
      selectedType = 'catering';
    } else if (parentComponentId != null) {
      // If adding to a parent, it's usually a sub-category or item group
      selectedType = 'category';
    } else {
      // Default for generic package
      selectedType = 'category';
    }
    
    final cateringTypes = ['set', 'category', 'catering'];
    // Expanded generic types for package components
    final generalTypes = ['set', 'category', 'decoration', 'hall', 'photography', 'makeup', 'apparel', 'sound', 'emcee', 'gift', 'invitation', 'other'];
    final types = isCateringContext ? cateringTypes : generalTypes;
    
    String? parentId = parentComponentId;
    bool isOptional = false;

    // Filter potential parents (only 'set' type components)
    final parentSets = _components.where((c) => c.componentType == 'set').toList();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(forceSet ? "Add Set" : "Add Component / Category"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!forceSet) ...[
                  DropdownButtonFormField<String>(
                    value: types.contains(selectedType) ? selectedType : types.first,
                    decoration: const InputDecoration(labelText: "Component Type"),
                    items: types.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 12),
                ],
                if ((selectedType == 'category' || selectedType == 'catering' || selectedType == 'decoration' || selectedType == 'photography' || selectedType == 'other') && parentSets.isNotEmpty && parentId == null && !forceSet) ...[
                  DropdownButtonFormField<String>(
                    value: parentId,
                    decoration: const InputDecoration(labelText: "Belongs to Set (Optional)"),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text("No Parent (Generic)")),
                      ...parentSets.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))),
                    ],
                    onChanged: (v) => setDialogState(() => parentId = v),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: forceSet ? "Set Name (e.g. Gold Package)" : "Name (e.g. Main Course, Photographer)")),
                const SizedBox(height: 12),
                if (selectedType != 'set') ...[
                  TextField(
                    controller: limitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Selection Limit (Pick X)",
                      helperText: "0 = All items included, >0 = Customer must pick X",
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text("Optional Category"),
                    subtitle: const Text("Customer can skip this entire category"),
                    value: isOptional,
                    onChanged: (v) => setDialogState(() => isOptional = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    _components.add(ServiceComponent(
                      id: const Uuid().v4(),
                      name: nameCtrl.text,
                      componentType: selectedType,
                      items: [],
                      selectionLimit: int.tryParse(limitCtrl.text) ?? 0,
                      parentComponentId: parentId,
                      isOptional: isOptional,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addItemDialog(ServiceComponent component) async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '0.0');
    final extraPriceCtrl = TextEditingController(text: '0.0');
    bool isOptional = false;
    bool isFree = false;
    
    List<XFile> selectedGallery = [];
    PlatformFile? selectedPdf;
    // Initializing with all current tiers if they exist (safe map without !)
    List<String> selectedTierIds = _pricingTiers.map((t) => t.id).whereType<String>().toList();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Add Item to ${component.name}"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Item Name")),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Quantity"))),
                        const SizedBox(width: 8),
                        if (!isFree)
                          Expanded(child: TextField(controller: priceCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: "Unit Price (${CurrencyFormatter.symbol})"))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text("Is Free Item"),
                      value: isFree,
                      onChanged: (v) => setDialogState(() => isFree = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description (Optional)")),
                    const SizedBox(height: 16),

                    const Divider(),
                    SwitchListTile(
                      title: const Text("Is Optional Item"),
                      subtitle: const Text("Customer can choose to add this item later"),
                      value: isOptional,
                      onChanged: (v) => setDialogState(() => isOptional = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (isOptional)
                      TextField(
                        controller: extraPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: "Extra Price for selecting this item (${CurrencyFormatter.symbol})",
                          prefixText: "${CurrencyFormatter.symbol} ",
                        ),
                      ),
                    const SizedBox(height: 16),

                    if (_pricingTiers.isNotEmpty) ...[
                      const Text("Included in Packages", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      const Text("Select which rates/packages include this item:", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 0,
                        children: _pricingTiers.map((tier) {
                          final isSelected = selectedTierIds.contains(tier.id);
                          return FilterChip(
                            label: Text(tier.name ?? "Unnamed", style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                            selected: isSelected,
                            selectedColor: Colors.teal,
                            checkmarkColor: Colors.white,
                            onSelected: (selected) {
                              if (tier.id == null) return;
                              setDialogState(() {
                                if (selected) {
                                  selectedTierIds.add(tier.id!);
                                } else {
                                  selectedTierIds.remove(tier.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    const Text("Item Gallery (Visual Breakdown)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    if (selectedGallery.isNotEmpty)
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedGallery.length,
                          itemBuilder: (context, index) => Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(File(selectedGallery[index].path)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 8,
                                child: InkWell(
                                  onTap: () => setDialogState(() => selectedGallery.removeAt(index)),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final images = await _imagePicker.pickMultiImage();
                        if (images.isNotEmpty) {
                          setDialogState(() => selectedGallery.addAll(images));
                        }
                      },
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                      label: const Text("Add Images"),
                    ),
                    
                    const SizedBox(height: 16),
                    const Text("Brochure / Menu (PDF)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    if (selectedPdf != null)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(selectedPdf!.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.grey),
                          onPressed: () => setDialogState(() => selectedPdf = null),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                        if (result != null) {
                          setDialogState(() => selectedPdf = result.files.first);
                        }
                      },
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text("Upload PDF"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isNotEmpty) {
                      setState(() {
                        component.items.add(ServiceItem(
                          id: const Uuid().v4(),
                          name: nameCtrl.text,
                          quantity: int.tryParse(qtyCtrl.text) ?? 1,
                          description: descCtrl.text,
                          unitPrice: isFree ? 0.0 : (double.tryParse(priceCtrl.text) ?? 0.0),
                          isFree: isFree,
                          isOptional: isOptional,
                          extraPrice: isOptional ? double.tryParse(extraPriceCtrl.text) : null,
                          newGalleryFiles: selectedGallery,
                          newPdfFile: selectedPdf,
                          applicableTierIds: selectedTierIds,
                        ));
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInstallmentSection() {
    final price = _getMaxPrice();
    
    String? ruleWarning;
    bool forceInstallment = false;
    bool disableInstallment = false;

    if (price > 0) {
      if (price < 1000) {
        ruleWarning = "For services below ${CurrencyFormatter.symbol} 1,000, full payment is required by the platform.";
        disableInstallment = true;
      } else if (price > 5000) {
        ruleWarning = "For high-value services (> ${CurrencyFormatter.symbol} 5,000), installments are automatically enabled to increase booking conversion.";
        forceInstallment = true;
      } else {
        ruleWarning = "Optional: For services between ${CurrencyFormatter.symbol} 1,000 - ${CurrencyFormatter.symbol} 5,000, you can offer a deposit option.";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Installment Settings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            Switch(
              value: _installmentEnabled,
              onChanged: (disableInstallment || forceInstallment) 
                  ? null 
                  : (v) => setState(() => _installmentEnabled = v),
              activeColor: Colors.teal,
            ),
          ],
        ),
        if (ruleWarning != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              ruleWarning,
              style: TextStyle(
                fontSize: 12, 
                color: forceInstallment ? Colors.teal.shade700 : (disableInstallment ? Colors.orange.shade800 : Colors.grey.shade600),
                fontWeight: (forceInstallment || disableInstallment) ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        const Text(
          "Allow customers to pay in installments for this service. This overrides global vendor settings if enabled.",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        if (_installmentEnabled) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _depositPercentageController,
                  keyboardType: TextInputType.number,
                  readOnly: forceInstallment, // Lock to recommended 30% for high value
                  decoration: InputDecoration(
                    labelText: "Deposit %",
                    hintText: "e.g., 30",
                    border: const OutlineInputBorder(),
                    suffixText: "%",
                    filled: forceInstallment,
                    fillColor: forceInstallment ? Colors.grey.shade100 : null,
                  ),
                  validator: (v) => (_installmentEnabled && (v == null || v.isEmpty)) ? "Required" : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _maxInstallmentsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Number of Installments (Times)",
                    hintText: "e.g., 3",
                    border: OutlineInputBorder(),
                    helperText: "Total number of payment parts",
                  ),
                  validator: (v) => (_installmentEnabled && (v == null || v.isEmpty)) ? "Required" : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _paymentDeadlineDaysController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Final Payment Deadline (Days before event)",
              hintText: "e.g., 14",
              border: OutlineInputBorder(),
              helperText: "Remaining installments will be spread between booking and this deadline.",
            ),
            validator: (v) => (_installmentEnabled && (v == null || v.isEmpty)) ? "Required" : null,
          ),
        ],
        const Divider(height: 32),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DELIVERY & PICKUP LOGISTICS SECTION
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildDeliveryLogisticsSection() {
    final isRental = _selectedType == ServiceType.rental;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.teal.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isRental ? Icons.swap_horiz : Icons.local_shipping_outlined, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  isRental ? 'Return & Delivery Logistics' : 'Delivery & Pickup Options',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isRental
                  ? 'Configure how customers receive and return rental items.'
                  : 'Choose how customers receive their orders.',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // Delivery toggle
            Container(
              decoration: BoxDecoration(
                color: _hasDelivery ? Colors.teal.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _hasDelivery ? Colors.teal.shade200 : Colors.grey.shade300),
              ),
              child: SwitchListTile(
                title: const Text('Delivery Available', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Items shipped / delivered to customer address'),
                value: _hasDelivery,
                activeColor: Colors.teal,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                onChanged: (v) => setState(() => _hasDelivery = v),
              ),
            ),
            if (_hasDelivery) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _deliveryFeeType,
                decoration: const InputDecoration(
                  labelText: 'Delivery Fee Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                items: const [
                  DropdownMenuItem(value: 'free', child: Text('Free Delivery')),
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed Fee')),
                  DropdownMenuItem(value: 'per_km', child: Text('Per Km Rate')),
                ],
                onChanged: (v) => setState(() => _deliveryFeeType = v ?? 'fixed'),
              ),
              const SizedBox(height: 12),
              if (_deliveryFeeType != 'free') ...[
                TextFormField(
                  controller: _deliveryFeeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _deliveryFeeType == 'per_km' ? 'Rate per km (${CurrencyFormatter.symbol})' : 'Delivery Fee (${CurrencyFormatter.symbol})',
                    border: const OutlineInputBorder(),
                    prefixText: '${CurrencyFormatter.symbol} ',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _freeDeliveryThresholdController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Free Delivery Min Order (${CurrencyFormatter.symbol})',
                        border: const OutlineInputBorder(),
                        prefixText: '${CurrencyFormatter.symbol} ',
                        helperText: '0 = no minimum',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _estimatedDaysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Est. Dispatch (days)',
                        border: OutlineInputBorder(),
                        helperText: 'Production / shipping days',
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Self-Pickup toggle
            Container(
              decoration: BoxDecoration(
                color: _hasSelfPickup ? Colors.orange.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _hasSelfPickup ? Colors.orange.shade200 : Colors.grey.shade300),
              ),
              child: SwitchListTile(
                title: const Text('Self-Pickup Available', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Customer collects from your location'),
                value: _hasSelfPickup,
                activeColor: Colors.orange,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                onChanged: (v) => setState(() => _hasSelfPickup = v),
              ),
            ),
            if (_hasSelfPickup) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _pickupAddressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Pickup Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.storefront),
                  hintText: 'Full address for customer pickup',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pickupHoursController,
                decoration: const InputDecoration(
                  labelText: 'Pickup Hours',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
                  hintText: 'e.g. Mon–Sat, 9am–6pm',
                ),
              ),
            ],
            // Rental-specific: Deposit & Damage Waiver
            if (isRental) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Rental Deposit & Protection',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rentalDepositController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Security Deposit (${CurrencyFormatter.symbol})',
                  border: const OutlineInputBorder(),
                  prefixText: '${CurrencyFormatter.symbol} ',
                  helperText: 'Refunded upon good-condition return',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Offer Damage Waiver', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Optional protection plan customer can add'),
                value: _hasDamageWaiver,
                activeColor: Colors.indigo,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _hasDamageWaiver = v),
              ),
              if (_hasDamageWaiver) ...[
                TextFormField(
                  controller: _damageWaiverPctController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Waiver Fee (% of rental price)',
                    border: OutlineInputBorder(),
                    suffixText: '%',
                    helperText: 'e.g. 5 = 5% of rental value',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _returnConditionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Return Condition Notes',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. Items must be cleaned and packed in original packaging.',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // ENHANCED VARIATIONS SECTION (Product)
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildEnhancedVariationsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text('Product Variations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Add variants like size, colour, or material with optional price differences.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_variations.isNotEmpty) ...[
              ..._variations.asMap().entries.map((entry) {
                final v = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => setState(() => _variations.remove(v)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: v.options.map((opt) {
                          final priceDelta = v.optionPrices[opt];
                          return Chip(
                            label: Text(
                              priceDelta != null && priceDelta > 0
                                  ? '$opt (+${CurrencyFormatter.symbol}${priceDelta.toStringAsFixed(2)})'
                                  : opt,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.blue.shade200),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Variation Group'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _addVariationDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // BULK PRICING SECTION
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildBulkPricingSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.deepPurple.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.layers, color: Colors.deepPurple.shade400),
                    const SizedBox(width: 8),
                    const Text('Bulk / Quantity Pricing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Switch(
                  value: _bulkPricingEnabled,
                  activeColor: Colors.deepPurple,
                  onChanged: (v) => setState(() => _bulkPricingEnabled = v),
                ),
              ],
            ),
            const Text(
              'Offer lower per-unit prices for larger order quantities.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            if (_bulkPricingEnabled) ...[
              const SizedBox(height: 16),
              if (_bulkPricingTiers.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepPurple.shade100),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.deepPurple.shade50,
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Expanded(flex: 2, child: Text('Min Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            const Expanded(flex: 2, child: Text('Max Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(flex: 3, child: Text('Price/Unit (${CurrencyFormatter.symbol})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            const SizedBox(width: 36),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ..._bulkPricingTiers.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final tier = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text('${tier['minQty']}', style: const TextStyle(fontSize: 14))),
                              Expanded(flex: 2, child: Text(tier['maxQty'] != null ? '${tier['maxQty']}' : '\u221e', style: const TextStyle(fontSize: 14))),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '${CurrencyFormatter.symbol} ${(tier['pricePerUnit'] as num).toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.deepPurple.shade700),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => setState(() => _bulkPricingTiers.removeAt(idx)),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add Bulk Tier'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: BorderSide(color: Colors.deepPurple.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _showAddBulkTierDialog,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showAddBulkTierDialog() async {
    final minQtyCtrl = TextEditingController();
    final maxQtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Bulk Pricing Tier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minQtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min Qty', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: maxQtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Qty (blank = ∞)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Price Per Unit (${CurrencyFormatter.symbol})',
                border: const OutlineInputBorder(),
                prefixText: '${CurrencyFormatter.symbol} ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
            onPressed: () {
              final minQty = int.tryParse(minQtyCtrl.text);
              final maxQty = int.tryParse(maxQtyCtrl.text);
              final price = double.tryParse(priceCtrl.text);
              if (minQty == null || price == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in Min Qty and Price per unit')),
                );
                return;
              }
              setState(() {
                _bulkPricingTiers.add({'minQty': minQty, 'maxQty': maxQty, 'pricePerUnit': price});
                _bulkPricingTiers.sort((a, b) => (a['minQty'] as int).compareTo(b['minQty'] as int));
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class DashPainter extends CustomPainter {
  final Color color;
  DashPainter({this.color = Colors.grey});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 5;
    const dashSpace = 3;

    final path = Path();
    // Top border
    for (double i = 0; i < size.width; i += dashWidth + dashSpace) {
      path.moveTo(i, 0);
      path.lineTo(i + dashWidth, 0);
    }
    // Right border
    for (double i = 0; i < size.height; i += dashWidth + dashSpace) {
      path.moveTo(size.width, i);
      path.lineTo(size.width, i + dashWidth);
    }
    // Bottom border
    for (double i = 0; i < size.width; i += dashWidth + dashSpace) {
      path.moveTo(i, size.height);
      path.lineTo(i + dashWidth, size.height);
    }
    // Left border
    for (double i = 0; i < size.height; i += dashWidth + dashSpace) {
      path.moveTo(0, i);
      path.lineTo(0, i + dashWidth);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
