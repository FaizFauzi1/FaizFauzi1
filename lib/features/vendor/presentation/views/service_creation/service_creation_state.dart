import 'package:flutter/material.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/shared/models/services/pricing_model.dart';
import 'package:eventease/shared/models/services/team_capacity.dart';
import 'package:eventease/shared/models/event/event_type.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/shared/models/services/service_time_rule.dart';
import 'package:eventease/shared/models/services/wedding_preparation_timeline.dart';
import 'package:eventease/shared/models/services/service_guarantee.dart';
import 'package:eventease/shared/models/services/service_logistics.dart';

class ServiceCreationState extends ChangeNotifier {
  final String? vendorId;
  final VendorService? existingService;

  ServiceCreationState({this.vendorId, this.existingService}) {
    if (existingService != null) {
      _initializeFromService(existingService!);
    }
  }

  // --- Step 1: Basic Info ---
  String? id;
  String name = '';
  String description = '';
  EventCategory category = EventCategory.package;
  String? subcategory;
  List<String> images = [];
  bool isActive = true;
  List<ServiceType> selectedServiceTypes = [ServiceType.service];
  ServiceType get serviceType => selectedServiceTypes.isNotEmpty ? selectedServiceTypes.first : ServiceType.service;
  
  // --- Preorder & Rental Fields ---
  int? minOrderQty;
  int? productionDays;
  int? minRentalDays;
  int? maxRentalDays;

  // --- Step 2: Event Types ---
  List<String> selectedEventTypes = [];
  
  // --- Step 3: Pricing Model ---
  PricingModelType pricingType = PricingModelType.perEventType;
  double basePrice = 0.0;
  int minPax = 0;
  double pricePerPax = 0.0;
  List<PaxTierPricing> paxTiers = [];
  Map<String, double> hourlyRates = {};
  Map<String, double> dailyRates = {};
  
  // Fee Transparency
  bool isTransportIncluded = false;
  bool isAccommodationIncluded = false;
  bool isSetupIncluded = true;
  String otherFeesDescription = '';

  // --- Step 4: Event Combinations ---
  List<EventTypeCombination> eventCombinations = [];

  // --- Step 5: Duration & Day Control ---
  bool allowSameDayMultiEvent = false;
  double? sameDayDiscount;
  double? differentDaySurcharge;
  ServiceTimeRule? timeRule;

  // --- Step 6: Add-Ons ---
  List<ServiceAddOn> addOns = [];

  // --- Step 7: Capacity & Availability ---
  TeamCapacityConfig teamCapacity = TeamCapacityConfig(
    totalTeamsAvailable: 1, 
    maxEventsPerDay: 1
  );
  AvailabilitySlotConfig slotConfig = AvailabilitySlotConfig(
    slotDurationMinutes: 180, 
    maxEventsPerDay: 2
  );
  
  // --- New Logistics & Pricing Steps ---
  ProductLogistics productLogistics = const ProductLogistics();
  bool bulkPricingEnabled = false;
  List<BulkPricingTier> bulkPricingTiers = [];
  List<ProductVariation> productVariations = [];

  // --- Navigation & Helper ---
  int currentStep = 0;
  int get totalSteps {
    if (serviceType == ServiceType.product) return 12;
    if (serviceType == ServiceType.rental) return 11;
    return 9;
  }
  bool isLoading = false;

  // --- Step 8: Wedding Prep Timeline ---
  List<WeddingPrepMilestone> weddingTimeline = WeddingPrepTimeline.suggested;

  // --- Step 9: Guarantee ---
  ServiceGuarantee guarantee = const ServiceGuarantee();

  void _initializeFromService(VendorService service) {
    id = service.id;
    name = service.name;
    description = service.description;
    category = service.category;
    subcategory = service.subcategory;
    images = service.images;
    isActive = service.active;
    selectedServiceTypes = List.from(service.types);
    
    // New fields
    if (service.eventTypes != null) selectedEventTypes = List.from(service.eventTypes!);
    
    if (service.pricingModel != null) {
      final pm = service.pricingModel!;
      pricingType = pm.type;
      basePrice = pm.basePrice ?? 0.0;
      minPax = pm.minPax ?? 0;
      pricePerPax = pm.pricePerPax ?? 0.0;
      paxTiers = pm.paxTiers ?? [];
      hourlyRates = pm.hourlyRates ?? {};
      dailyRates = pm.dailyRates ?? {};
      eventCombinations = pm.eventCombinations ?? [];
    }
    
    if (service.addOns != null) addOns = List.from(service.addOns!);
    if (service.teamCapacity != null) teamCapacity = service.teamCapacity!;
    if (service.slotConfig != null) slotConfig = service.slotConfig!;
    
    allowSameDayMultiEvent = service.allowSameDayMultiEvent ?? false;
    sameDayDiscount = service.sameDayDiscount;
    differentDaySurcharge = service.differentDaySurcharge;
    timeRule = service.timeRule;

    // New wedding fields
    if (service.weddingTimeline != null && service.weddingTimeline!.isNotEmpty) {
      weddingTimeline = List.from(service.weddingTimeline!);
    }
    if (service.guarantee != null) {
      guarantee = service.guarantee!;
    }

    // Fee Transparency
    isTransportIncluded = service.isTransportIncluded;
    isAccommodationIncluded = service.isAccommodationIncluded;
    isSetupIncluded = service.isSetupIncluded;
    otherFeesDescription = service.otherFeesDescription ?? '';

    minOrderQty = service.minOrderQty;
    productionDays = service.productionDays;
    minRentalDays = service.minRentalDays;
    minRentalDays = service.minRentalDays;
    maxRentalDays = service.maxRentalDays;

    if (service.productLogistics != null) productLogistics = service.productLogistics!;
    if (service.bulkPricingTiers != null) {
      bulkPricingTiers = List.from(service.bulkPricingTiers!);
      bulkPricingEnabled = bulkPricingTiers.isNotEmpty;
    }
    if (service.variations != null) productVariations = List.from(service.variations!);
  }

  void nextStep() {
    if (currentStep < totalSteps - 1) {
      if (currentStep == 0) {
        _generateEventCombinations();
      }
      currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  // --- Data Update Methods ---

  void updateBasicInfo({
    String? name, 
    String? description, 
    EventCategory? category,
    String? subcategory,
    List<String>? images,
    ServiceType? type, // Still accept single for backward compat if needed
    List<ServiceType>? types,
  }) {
    if (name != null) this.name = name;
    if (description != null) this.description = description;
    if (category != null) this.category = category;
    if (subcategory != null) this.subcategory = subcategory;
    if (images != null) this.images = images;
    if (types != null) {
      this.selectedServiceTypes = types;
    } else if (type != null) {
      this.selectedServiceTypes = [type];
    }
    notifyListeners();
  }

  void toggleServiceType(ServiceType type) {
    if (selectedServiceTypes.contains(type)) {
      if (selectedServiceTypes.length > 1) {
        selectedServiceTypes.remove(type);
      }
    } else {
      selectedServiceTypes.add(type);
    }
    notifyListeners();
  }

  void toggleEventType(String eventType) {
    if (selectedEventTypes.contains(eventType)) {
      selectedEventTypes.remove(eventType);
    } else {
      selectedEventTypes.add(eventType);
    }
    notifyListeners();
  }

  void setPricingType(PricingModelType type) {
    pricingType = type;
    notifyListeners();
  }

  void updatePricingValues({
    double? basePrice,
    int? minPax,
    double? pricePerPax,
  }) {
    if (basePrice != null) this.basePrice = basePrice;
    if (minPax != null) this.minPax = minPax;
    if (pricePerPax != null) this.pricePerPax = pricePerPax;
    notifyListeners();
  }

  /// Automatically generate combinations based on selected event types
  void _generateEventCombinations() {
    // Logic to generate single events first
    // Then generate combinations if package or custom combo
    
    // 1. Preserve existing prices if possible
    final Map<String, double> existingPrices = {
      for (var c in eventCombinations) c.getCombinationKey(): c.price
    };

    List<EventTypeCombination> newCombinations = [];

    // Single events
    for (var type in selectedEventTypes) {
      newCombinations.add(EventTypeCombination(
        id: type, // temporary ID
        eventTypes: [type],
        price: existingPrices[type] ?? 0.0,
        displayName: _getDisplayNameForEvent(type),
      ));
    }

    // If more than 1 event type selected, and pricing allows combinations
    if (selectedEventTypes.length > 1) {
      // Add "All Selected" combination
      final allKey = (List<String>.from(selectedEventTypes)..sort()).join('_');
      newCombinations.add(EventTypeCombination(
        id: 'combo_all',
        eventTypes: List.from(selectedEventTypes),
        price: existingPrices[allKey] ?? 0.0,
        displayName: 'All Selected Events Bundle',
      ));

      // Ideally we generate 2-event combinations etc., but let's keep it simple for now:
      // Single events + Full Bundle
      // User can add custom combinations manually if needed (future enhancement)
    }

    eventCombinations = newCombinations;
    // Don't notify here as it's called during nextStep()
  }

  String _getDisplayNameForEvent(String code) {
    // In real app, look up from EventType.getAllEventTypes()
    // Simple fallback:
    return code.split('_').map((s) => s[0].toUpperCase() + s.substring(1)).join(' '); 
  }
  
  void updateCombinationPrice(int index, double price) {
    if (index >= 0 && index < eventCombinations.length) {
      final old = eventCombinations[index];
      eventCombinations[index] = EventTypeCombination(
        id: old.id,
        eventTypes: old.eventTypes,
        price: price,
        displayName: old.displayName,
        description: old.description,
      );
      notifyListeners();
    }
  }

  void addAddOn(ServiceAddOn addOn) {
    addOns.add(addOn);
    notifyListeners();
  }

  void removeAddOn(int index) {
    addOns.removeAt(index);
    notifyListeners();
  }
  
  void updateAddOn(int index, ServiceAddOn addOn) {
     addOns[index] = addOn;
     notifyListeners();
  }

  void updateDurationControls({bool? allowSameDay, double? sameDayDiscount, double? differentDaySurcharge}) {
    if (allowSameDay != null) allowSameDayMultiEvent = allowSameDay;
    if (sameDayDiscount != null) this.sameDayDiscount = sameDayDiscount;
    if (differentDaySurcharge != null) this.differentDaySurcharge = differentDaySurcharge;
    notifyListeners();
  }

  void updateFeeTransparency({
    bool? transport,
    bool? accommodation,
    bool? setup,
    String? other,
  }) {
    if (transport != null) isTransportIncluded = transport;
    if (accommodation != null) isAccommodationIncluded = accommodation;
    if (setup != null) isSetupIncluded = setup;
    if (other != null) otherFeesDescription = other;
    notifyListeners();
  }

  void updatePreorderRentalInfo({
    int? minOrderQty,
    int? productionDays,
    int? minRentalDays,
    int? maxRentalDays,
  }) {
    if (minOrderQty != null) this.minOrderQty = minOrderQty;
    if (productionDays != null) this.productionDays = productionDays;
    if (minRentalDays != null) this.minRentalDays = minRentalDays;
    if (maxRentalDays != null) this.maxRentalDays = maxRentalDays;
    notifyListeners();
  }

  // --- Wedding Timeline Methods ---

  void toggleWeddingMilestone(int index, bool enabled) {
    if (index >= 0 && index < weddingTimeline.length) {
      weddingTimeline[index] = weddingTimeline[index].copyWith(isEnabled: enabled);
      notifyListeners();
    }
  }

  void updateWeddingMilestone(int index, WeddingPrepMilestone milestone) {
    if (index >= 0 && index < weddingTimeline.length) {
      weddingTimeline[index] = milestone;
      notifyListeners();
    }
  }

  void addCustomWeddingMilestone(WeddingPrepMilestone milestone) {
    weddingTimeline.add(milestone);
    // Sort by weeks descending (furthest first)
    weddingTimeline.sort((a, b) => b.weeksBeforeEvent.compareTo(a.weeksBeforeEvent));
    notifyListeners();
  }

  void removeWeddingMilestone(int index) {
    if (index >= 0 && index < weddingTimeline.length) {
      weddingTimeline.removeAt(index);
      notifyListeners();
    }
  }

  void resetWeddingTimeline() {
    weddingTimeline = WeddingPrepTimeline.suggested;
    notifyListeners();
  }

  void setWeddingTimeline(List<WeddingPrepMilestone> newTimeline) {
    weddingTimeline = List.from(newTimeline);
    notifyListeners();
  }

  // --- Guarantee Methods ---

  void updateGuarantee(ServiceGuarantee newGuarantee) {
    guarantee = newGuarantee;
    notifyListeners();
  }

  // --- New Field Update Methods ---

  void updateProductLogistics(ProductLogistics newLogistics) {
    productLogistics = newLogistics;
    notifyListeners();
  }

  void toggleBulkPricing(bool enabled) {
    bulkPricingEnabled = enabled;
    if (!enabled) bulkPricingTiers.clear();
    notifyListeners();
  }

  void addBulkPricingTier(BulkPricingTier tier) {
    bulkPricingTiers.add(tier);
    bulkPricingTiers.sort((a, b) => a.minQty.compareTo(b.minQty));
    notifyListeners();
  }

  void removeBulkPricingTier(int index) {
    bulkPricingTiers.removeAt(index);
    notifyListeners();
  }

  void updateBulkPricingTier(int index, BulkPricingTier tier) {
    bulkPricingTiers[index] = tier;
    bulkPricingTiers.sort((a, b) => a.minQty.compareTo(b.minQty));
    notifyListeners();
  }

  void addVariation(ProductVariation variation) {
    productVariations.add(variation);
    notifyListeners();
  }

  void removeVariation(int index) {
    productVariations.removeAt(index);
    notifyListeners();
  }

  void updateVariation(int index, ProductVariation variation) {
    productVariations[index] = variation;
    notifyListeners();
  }

  bool _isProductCategory() => serviceType == ServiceType.product;
  bool _isRentalCategory() => serviceType == ServiceType.rental;

  VendorService toVendorService() {
    return VendorService(
      id: id ?? '',
      vendorId: vendorId ?? '',
      name: name,
      description: description,
      category: category,
      subcategory: subcategory,
      images: images,
      active: isActive,
      types: selectedServiceTypes,
      
      // New Fields
      eventTypes: selectedEventTypes,
      pricingModel: PricingModel(
        type: pricingType,
        basePrice: basePrice,
        minPax: minPax,
        pricePerPax: pricePerPax,
        paxTiers: paxTiers,
        eventCombinations: eventCombinations,
        hourlyRates: hourlyRates,
        dailyRates: dailyRates,
      ),
      addOns: addOns,
      teamCapacity: teamCapacity,
      slotConfig: slotConfig,
      allowSameDayMultiEvent: allowSameDayMultiEvent,
      sameDayDiscount: sameDayDiscount,
      differentDaySurcharge: differentDaySurcharge,
      timeRule: timeRule,
      weddingTimeline: weddingTimeline.where((m) => m.isEnabled).toList(),
      guarantee: guarantee.hasAnyGuarantee ? guarantee : null,
      isTransportIncluded: isTransportIncluded,
      isAccommodationIncluded: isAccommodationIncluded,
      isSetupIncluded: isSetupIncluded,
      otherFeesDescription: otherFeesDescription.isNotEmpty ? otherFeesDescription : null,
      minOrderQty: minOrderQty,
      productionDays: productionDays,
      minRentalDays: minRentalDays,
      maxRentalDays: maxRentalDays,
      productLogistics: (_isProductCategory() || _isRentalCategory()) ? productLogistics : null,
      bulkPricingTiers: bulkPricingEnabled ? bulkPricingTiers : null,
      variations: _isProductCategory() ? productVariations : null,
    );
  }

  Future<bool> submit(BuildContext context, dynamic vendorProvider) async {
    isLoading = true;
    notifyListeners();

    try {
      final service = toVendorService().toEnhanced();
      if (id != null && id!.isNotEmpty) {
        await vendorProvider.updateCustomService(id!, service);
      } else {
        await vendorProvider.addCustomService(service);
      }
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving service: $e')),
      );
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
