import 'dart:convert';
import '../../../shared/models/event/event_category.dart';
import '../../../shared/models/services/service_enums.dart';
import '../../../shared/models/services/service_package.dart';
import 'vendor_service_enhanced.dart';
import 'service_template_models.dart';
import '../../../shared/models/services/service_time_rule.dart';
import '../../../shared/models/services/service_logistics.dart';
import '../../../shared/models/services/pricing_model.dart';
import '../../../shared/models/services/team_capacity.dart';
import '../../../shared/models/services/wedding_preparation_timeline.dart';
import '../../../shared/models/services/service_guarantee.dart';

class VendorService {
   final String id;
   final String vendorId;
   final String? vendorName;
   final String name;
  final String description;
  final EventCategory category;
  final String? subcategory;
  final Map<String, double> multiLayerPricing;
  final double basePrice;
  final double? originalPrice; // Original price before promo
  final DateTime? promoExpiry; // When the promo ends
  final double? hourlyRate;
  final bool active;
  final ApprovalStatus approvalStatus;
  final Map<String, dynamic> availability;
  final int maxBookingsPerDay;
  final int advanceBookingDays;
  final List<ServiceType> types;
  ServiceType get type => types.isNotEmpty ? types.first : ServiceType.service;

  final List<String> images;
  final Map<String, dynamic> options;
  final Map<String, dynamic> requirements;
  final Map<String, dynamic> logistics;
  final ServiceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool supportsAppointments;
  final bool supportsRentals;
  final List<String>? amenities;
  final String? cancellationPolicy;
  final List<Map<String, dynamic>>? reviews;
  final List<ServicePackage>? packages;
  final List<String> allowedActions;
  final List<String>? locations;
  final String? venueAddress;
  final String? coverageArea;
  final List<String> eventTypes;
  final String cancellationPolicyType;
  final ServiceTimeRule? timeRule;
  final ServiceLogistics? logisticsConfig;
  final List<ServicePricingTier> pricingTiers;
  final List<ServiceComponent> components;
  final String? videoUrl; // NEW Media Field
  
  // NEW Preorder & Rental Fields
  final int? minOrderQty;
  final int? productionDays;
  final int? minRentalDays;
  final int? maxRentalDays;

  // NEW Universal Service Fields
  final PricingModel? pricingModel;
  final List<ServiceAddOn>? addOns;
  final TeamCapacityConfig? teamCapacity;
  final AvailabilitySlotConfig? slotConfig;
  final bool allowSameDayMultiEvent;
  final double? sameDayDiscount;
  final double? differentDaySurcharge;

  /// Parent vendor marketplace weight (from `vendor_profiles.priority_score` when joined).
  final double vendorPriorityScore;

  // NEW Installment Fields
  final bool installmentEnabled;
  final double? depositPercentage;
  final int? maxInstallments;
  final int? paymentDeadlineDays;

  // NEW Wedding Package Fields
  final List<WeddingPrepMilestone>? weddingTimeline;
  final ServiceGuarantee? guarantee;

  // Hierarchical Commission & Fees
  final double? commissionRate;
  final bool commissionOverride;
  final bool isTransportIncluded;
  final bool isAccommodationIncluded;
  final bool isSetupIncluded;
  final String? otherFeesDescription;
  
  // NEW Logistics & Pricing Models
  final ProductLogistics? productLogistics;
  final List<BulkPricingTier>? bulkPricingTiers;
  final List<ProductVariation>? variations;

  VendorService({
     required this.id,
     required this.vendorId,
     this.vendorName,
     required this.name,
    required this.description,
    required this.category,
    this.subcategory,
    this.multiLayerPricing = const {},
    this.basePrice = 0.0,
    this.originalPrice,
    this.promoExpiry,
    this.hourlyRate,
    this.active = true,
    this.approvalStatus = ApprovalStatus.pending,
    this.availability = const {},
    this.maxBookingsPerDay = 10,
    this.advanceBookingDays = 7,
    this.types = const [ServiceType.product],
    this.images = const [],
    this.options = const {},
    this.requirements = const {},
    this.logistics = const {},
    this.status = ServiceStatus.active,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.supportsAppointments = false,
    this.supportsRentals = false,
    this.amenities,
    this.cancellationPolicy,
    this.reviews,
    this.packages,
    this.allowedActions = const ['book'], // Default to book action
    this.locations,
    this.venueAddress,
    this.coverageArea,
    this.eventTypes = const [],
    this.cancellationPolicyType = 'platform',
    this.timeRule,
    this.logisticsConfig,
    this.pricingTiers = const [],
    this.components = const [],
    this.minOrderQty,
    this.productionDays,
    this.minRentalDays,
    this.maxRentalDays,
    this.pricingModel,
    this.addOns,
    this.teamCapacity,
    this.slotConfig,
    this.allowSameDayMultiEvent = false,
    this.sameDayDiscount,
    this.differentDaySurcharge,
    this.vendorPriorityScore = 0,
    this.installmentEnabled = false,
    this.depositPercentage,
    this.maxInstallments,
    this.paymentDeadlineDays,
    this.videoUrl,
    this.weddingTimeline,
    this.guarantee,
    this.commissionRate,
    this.commissionOverride = false,
    this.isTransportIncluded = false,
    this.isAccommodationIncluded = false,
    this.isSetupIncluded = true,
    this.otherFeesDescription,
    this.productLogistics,
    this.bulkPricingTiers,
    this.variations,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  VendorServiceEnhanced toEnhanced() {
    return VendorServiceEnhanced(
      id: id,
      name: name,
      productCategory: category,
      serviceTypes: types,
      description: description,
      subcategory: subcategory,
      multiLayerPricing: multiLayerPricing,
      images: images,
      availability: availability,
      inventory: 0, // Basic doesn't have inventory
      logistics: logistics,
      isActive: active,
      vendorId: vendorId,
      price: basePrice,
      status: status,
      approvalStatus: approvalStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      extendedAvailability: availability,
      unavailablePeriods: [], // Basic doesn't have unavailablePeriods
      maxBookingsPerDay: maxBookingsPerDay,
      advanceBookingDays: advanceBookingDays,
      options: options,
      supportsAppointments: supportsAppointments,
      supportsRentals: supportsRentals,
      allowedActions: allowedActions,
      locations: locations,
      venueAddress: venueAddress,
      coverageArea: coverageArea,
      reviews: reviews,
      eventTypes: eventTypes,
      cancellationPolicy: cancellationPolicy,
      cancellationPolicyType: cancellationPolicyType,
      timeRule: timeRule,
      logisticsConfig: logisticsConfig,
      pricingTiers: pricingTiers,
      components: components,
      minOrderQty: minOrderQty,
      productionDays: productionDays,
      minRentalDays: minRentalDays,
      maxRentalDays: maxRentalDays,
      originalPrice: originalPrice,
      promoExpiry: promoExpiry,
      installmentEnabled: installmentEnabled,
      depositPercentage: depositPercentage,
      maxInstallments: maxInstallments,
      paymentDeadlineDays: paymentDeadlineDays,
      videoUrl: videoUrl,
      weddingTimeline: weddingTimeline,
      guarantee: guarantee,
    );
  }

  static VendorServiceEnhanced fromBasic(VendorService basic) {
    return basic.toEnhanced();
  }

  // Deprecation note: Use VendorServiceEnhanced for new implementations
  @deprecated
  VendorService copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    String? name,
    String? description,
    EventCategory? category,
    String? subcategory,
    Map<String, double>? multiLayerPricing,
    double? basePrice,
    bool? active,
    ApprovalStatus? approvalStatus,
    Map<String, dynamic>? availability,
    int? maxBookingsPerDay,
    int? advanceBookingDays,
    List<ServiceType>? types,
    List<String>? images,
    Map<String, dynamic>? options,
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? logistics,
    ServiceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? supportsAppointments,
    bool? supportsRentals,
    List<String>? amenities,
    String? cancellationPolicy,
    List<Map<String, dynamic>>? reviews,
    List<ServicePackage>? packages,
    List<String>? allowedActions,
    List<String>? locations,
    String? venueAddress,
    String? coverageArea,
    List<String>? eventTypes,
    String? cancellationPolicyType,
    ServiceTimeRule? timeRule,
    ServiceLogistics? logisticsConfig,
    List<ServiceComponent>? components,
    List<ServicePricingTier>? pricingTiers,
    int? minOrderQty,
    int? productionDays,
    int? minRentalDays,
    int? maxRentalDays,
    double? originalPrice,
    DateTime? promoExpiry,
    PricingModel? pricingModel,
    List<ServiceAddOn>? addOns,
    TeamCapacityConfig? teamCapacity,
    AvailabilitySlotConfig? slotConfig,
    bool? allowSameDayMultiEvent,
    double? sameDayDiscount,
    double? differentDaySurcharge,
    double? vendorPriorityScore,
    bool? installmentEnabled,
    double? depositPercentage,
    int? maxInstallments,
    int? paymentDeadlineDays,
    String? videoUrl,
    List<WeddingPrepMilestone>? weddingTimeline,
    ServiceGuarantee? guarantee,
    double? commissionRate,
    bool? commissionOverride,
    bool? isTransportIncluded,
    bool? isAccommodationIncluded,
    bool? isSetupIncluded,
    String? otherFeesDescription,
    ProductLogistics? productLogistics,
    List<BulkPricingTier>? bulkPricingTiers,
    List<ProductVariation>? variations,
  }) {
    return VendorService(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      multiLayerPricing: multiLayerPricing ?? this.multiLayerPricing,
      basePrice: basePrice ?? this.basePrice,
      originalPrice: originalPrice ?? this.originalPrice,
      promoExpiry: promoExpiry ?? this.promoExpiry,
      active: active ?? this.active,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      availability: availability ?? this.availability,
      maxBookingsPerDay: maxBookingsPerDay ?? this.maxBookingsPerDay,
      advanceBookingDays: advanceBookingDays ?? this.advanceBookingDays,
      types: types ?? this.types,
      images: images ?? this.images,
      options: options ?? this.options,
      requirements: requirements ?? this.requirements,
      logistics: logistics ?? this.logistics,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      supportsAppointments: supportsAppointments ?? this.supportsAppointments,
      supportsRentals: supportsRentals ?? this.supportsRentals,
      amenities: amenities ?? this.amenities,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      reviews: reviews ?? this.reviews,
      packages: packages ?? this.packages,
      allowedActions: allowedActions ?? this.allowedActions,
      locations: locations ?? this.locations,
      venueAddress: venueAddress ?? this.venueAddress,
      coverageArea: coverageArea ?? this.coverageArea,
      eventTypes: eventTypes ?? this.eventTypes,
      cancellationPolicyType: cancellationPolicyType ?? this.cancellationPolicyType,
      timeRule: timeRule ?? this.timeRule,
      logisticsConfig: logisticsConfig ?? this.logisticsConfig,
      pricingTiers: pricingTiers ?? this.pricingTiers,
      components: components ?? this.components,
      minOrderQty: minOrderQty ?? this.minOrderQty,
      productionDays: productionDays ?? this.productionDays,
      minRentalDays: minRentalDays ?? this.minRentalDays,
      maxRentalDays: maxRentalDays ?? this.maxRentalDays,
      pricingModel: pricingModel ?? this.pricingModel,
      addOns: addOns ?? this.addOns,
      teamCapacity: teamCapacity ?? this.teamCapacity,
      slotConfig: slotConfig ?? this.slotConfig,
      allowSameDayMultiEvent: allowSameDayMultiEvent ?? this.allowSameDayMultiEvent,
      sameDayDiscount: sameDayDiscount ?? this.sameDayDiscount,
      differentDaySurcharge: differentDaySurcharge ?? this.differentDaySurcharge,
      vendorPriorityScore: vendorPriorityScore ?? this.vendorPriorityScore,
      installmentEnabled: installmentEnabled ?? this.installmentEnabled,
      depositPercentage: depositPercentage ?? this.depositPercentage,
      maxInstallments: maxInstallments ?? this.maxInstallments,
      paymentDeadlineDays: paymentDeadlineDays ?? this.paymentDeadlineDays,
      videoUrl: videoUrl ?? this.videoUrl,
      weddingTimeline: weddingTimeline ?? this.weddingTimeline,
      guarantee: guarantee ?? this.guarantee,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionOverride: commissionOverride ?? this.commissionOverride,
      isTransportIncluded: isTransportIncluded ?? this.isTransportIncluded,
      isAccommodationIncluded: isAccommodationIncluded ?? this.isAccommodationIncluded,
      isSetupIncluded: isSetupIncluded ?? this.isSetupIncluded,
      otherFeesDescription: otherFeesDescription ?? this.otherFeesDescription,
      productLogistics: productLogistics ?? this.productLogistics,
      bulkPricingTiers: bulkPricingTiers ?? this.bulkPricingTiers,
      variations: variations ?? this.variations,
    );
  }

  bool get hasPackagePricing => (packages?.isNotEmpty ?? false) || pricingTiers.isNotEmpty || multiLayerPricing.isNotEmpty || (pricingModel != null && pricingModel!.eventCombinations != null && pricingModel!.eventCombinations!.isNotEmpty);

  List<int> getAvailablePaxOptions() {
    final Set<int> pax = {};
    if (packages != null) {
      for (var p in packages!) {
        pax.addAll(p.getAvailablePax());
      }
    }
    for (var tier in pricingTiers) {
      pax.add(tier.minPax);
    }
    // Check new pricing model pax tiers
    if (pricingModel?.paxTiers != null) {
      for (var tier in pricingModel!.paxTiers!) {
        pax.add(tier.minPax);
      }
    }
    
    // Fallback to old multiLayerPricing
    if (multiLayerPricing.isNotEmpty) {
      for (var key in multiLayerPricing.keys) {
        final p = int.tryParse(key);
        if (p != null) pax.add(p);
      }
    }
    final result = pax.toList();
    result.sort();
    return result;
  }

  double getPriceForPax(int pax) {
    if (packages != null && packages!.isNotEmpty) {
      // Find package with closest match or first
      return packages!.first.getPriceForPax(pax);
    }
    
    // Check new pricing model
    if (pricingModel?.type == PricingModelType.perPax) {
      if (pricingModel!.paxTiers != null) {
        final tier = pricingModel!.findPaxTier(pax);
        if (tier != null) return tier.pricePerPax * pax;
      }
      if (pricingModel!.pricePerPax != null) {
        return pricingModel!.pricePerPax! * pax;
      }
    }
    
    if (pricingTiers.isNotEmpty) {
      // Find the tier that includes this pax count
      ServicePricingTier? selectedTier;
      
      // Sort tiers by minPax to ensure we check in order
      final sortedTiers = List<ServicePricingTier>.from(pricingTiers)
        ..sort((a, b) => a.minPax.compareTo(b.minPax));
        
      for (var tier in sortedTiers) {
        if (pax >= tier.minPax && (tier.maxPax == null || pax <= tier.maxPax!)) {
          selectedTier = tier;
          break;
        }
      }
      
      if (selectedTier != null) return selectedTier.price;
      
      // Fallback: If pax is lower than all tiers, return the first tier's price
      // instead of potentially returning 0 or basePrice
      if (sortedTiers.isNotEmpty && pax < sortedTiers.first.minPax) {
        return sortedTiers.first.price;
      }

      // Fallback: Highest minPax that is <= pax
      final matchingTiers = sortedTiers.where((t) => t.minPax <= pax).toList();
      if (matchingTiers.isNotEmpty) {
        return matchingTiers.last.price;
      }
      
      return pricingTiers.first.price;
    }
    
    // Fallback to legacy multiLayerPricing
    if (multiLayerPricing.isNotEmpty) {
      if (multiLayerPricing.containsKey(pax.toString())) {
        return multiLayerPricing[pax.toString()]!;
      }
      // Find closest Match
      final keys = multiLayerPricing.keys.map((k) => int.tryParse(k) ?? 0).toList()..sort();
      int? bestMatch;
      for (var k in keys) {
        if (k <= pax) bestMatch = k;
      }
      if (bestMatch != null) return multiLayerPricing[bestMatch.toString()]!;
      return multiLayerPricing[keys.first.toString()]!;
    }
    
    return basePrice;
  }

  double get price => getMinPrice();

  bool get hasDynamicPricing => hourlyRate != null || pricingModel != null;

  /// Best-effort helper to resolve a vendor contact email from this service.
  /// Returns `null` if no reasonable email can be found.
  String? getVendorEmail() {
    final candidates = <dynamic>[
      // Common keys where email might be stored
      options['email'],
      options['vendor_email'],
      options['contact_email'],
      logistics['email'],
      logistics['vendor_email'],
      logistics['contact_email'],
      requirements['email'],
      requirements['contact_email'],
    ];

    for (final value in candidates) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }

  double get averageRating {
    if (reviews == null || reviews!.isEmpty) return 0.0;
    final sum = reviews!.fold<double>(0.0, (acc, r) => acc + (r['rating'] as num).toDouble());
    return sum / reviews!.length;
  }

  int get variationCount {
    final variations = options['variations'];
    if (variations is Map) return variations.length;
    return 0;
  }

  bool get hasVariations => variationCount > 0;

  Map<String, dynamic> get packageOptions => options;

  double getMinPrice() {
    double min = basePrice;
    
    // Check new pricing model
    if (pricingModel != null) {
      if (pricingModel!.basePrice != null) {
        if (min == 0 || pricingModel!.basePrice! < min) min = pricingModel!.basePrice!;
      }
      // Check event combinations
      if (pricingModel!.eventCombinations != null && pricingModel!.eventCombinations!.isNotEmpty) {
        double comboMin = pricingModel!.eventCombinations!.map((c) => c.price).reduce((a, b) => a < b ? a : b);
        if (min == 0 || comboMin < min) min = comboMin;
      }
    }
    
    // Check old packages
    if (packages != null && packages!.isNotEmpty) {
      try {
        double pkgMin = packages!.map((p) {
          final availablePax = p.getAvailablePax();
          return availablePax.isNotEmpty 
              ? p.getPriceForPax(availablePax.first) 
              : p.priceByPax.values.fold(0.0, (prev, curr) => (prev == 0 || curr < prev) ? curr : prev);
        }).reduce((a, b) => a < b ? a : b);
        if (min == 0 || pkgMin < min) min = pkgMin;
      } catch (_) {}
    }

    // Check new pricing tiers
    if (pricingTiers.isNotEmpty) {
      double tierMin = pricingTiers.map((t) => t.price).reduce((a, b) => a < b ? a : b);
      if (min == 0 || tierMin < min) min = tierMin;
    }

    // Check legacy multiLayerPricing
    if (multiLayerPricing.isNotEmpty) {
      double multiMin = multiLayerPricing.values.reduce((a, b) => a < b ? a : b);
      if (min == 0 || multiMin < min) min = multiMin;
    }

    return min;
  }

  double getMaxPrice() {
    double max = basePrice;
    
    // Check new pricing model
    if (pricingModel != null) {
      if (pricingModel!.basePrice != null && pricingModel!.basePrice! > max) {
        max = pricingModel!.basePrice!;
      }
      // Check event combinations
      if (pricingModel!.eventCombinations != null && pricingModel!.eventCombinations!.isNotEmpty) {
        double comboMax = pricingModel!.eventCombinations!.map((c) => c.price).reduce((a, b) => a > b ? a : b);
        if (comboMax > max) max = comboMax;
      }
    }

    // Check old packages
    if (packages != null && packages!.isNotEmpty) {
      try {
        double pkgMax = packages!.map((p) {
          final availablePax = p.getAvailablePax();
          return availablePax.isNotEmpty 
              ? p.getPriceForPax(availablePax.first) 
              : p.priceByPax.values.fold(0.0, (prev, curr) => curr > prev ? curr : prev);
        }).reduce((a, b) => a > b ? a : b);
        if (pkgMax > max) max = pkgMax;
      } catch (_) {}
    }

    // Check new pricing tiers
    if (pricingTiers.isNotEmpty) {
      double tierMax = pricingTiers.map((t) => t.price).reduce((a, b) => a > b ? a : b);
      if (tierMax > max) max = tierMax;
    }

    return max;
  }

  factory VendorService.fromJson(Map<String, dynamic> json) {
    return VendorService(
      id: json['id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      vendorName: json['vendor']?['business_name'] ?? json['vendor_profiles']?['business_name'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: EventCategory.fromId((json['category'] ?? json['product_category'] ?? '').toString()),
      subcategory: json['subcategory']?.toString(),
      multiLayerPricing: _parseMultiLayerPricing(json['multi_layer_pricing'] ?? json['multiLayerPricing']),
      basePrice: (json['base_price'] ?? json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: json['original_price'] != null ? (json['original_price'] as num).toDouble() : null,
      promoExpiry: json['promo_expiry'] != null ? DateTime.tryParse(json['promo_expiry'].toString()) : null,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      active: json['is_active'] ?? true,
      approvalStatus: ApprovalStatus.values.firstWhere(
        (e) => e.name == (json['approval_status'] ?? 'pending'),
        orElse: () => ApprovalStatus.pending,
      ),
      availability: _parseMap(json['availability']),
      maxBookingsPerDay: (json['max_bookings_per_day'] as num?)?.toInt() ?? 10,
      advanceBookingDays: (json['advance_booking_days'] as num?)?.toInt() ?? 7,
      types: (json['service_types'] is List)
          ? (json['service_types'] as List)
              .map((e) => ServiceType.values.firstWhere(
                  (t) => t.name == e.toString(),
                  orElse: () => ServiceType.service))
              .toList()
          : [
              ServiceType.values.firstWhere(
                (e) => e.name == (json['service_type'] ?? 'service'),
                orElse: () => ServiceType.service,
              )
            ],
      images: (json['images'] is List) 
          ? (json['images'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      options: _parseMap(json['options']),
      requirements: _parseMap(json['requirements']),
      logistics: _parseMap(json['logistics']),
      status: ServiceStatus.values.firstWhere(
        (e) => e.name == (json['service_status'] ?? 'draft'),
        orElse: () => ServiceStatus.draft,
      ),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      supportsAppointments: json['supports_appointments'] ?? false,
      supportsRentals: json['supports_rentals'] ?? false,
      amenities: (json['amenities'] is List) 
          ? (json['amenities'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
          : (json['options'] != null && json['options'] is Map && json['options']['facilities'] is List)
              ? (json['options']['facilities'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
              : [],
      cancellationPolicy: json['cancellation_policy']?.toString(),
      cancellationPolicyType: json['cancellation_policy_type']?.toString() ?? 'platform',
      reviews: (json['reviews'] is List) 
          ? (json['reviews'] as List).map((e) {
              if (e is Map) {
                return Map<String, dynamic>.from(e);
              }
              return <String, dynamic>{};
            }).toList()
          : (json['reviews'] is Map) 
              ? [Map<String, dynamic>.from(json['reviews'] as Map)]
              : null,
      packages: (json['packages'] is List)
          ? (json['packages'] as List).map((e) {
              try {
                if (e is Map) {
                  return ServicePackage.fromJson(Map<String, dynamic>.from(e));
                }
                return ServicePackage.fromJson(e);
              } catch (err) {
                print('Error parsing package: $err');
                return null;
              }
            }).whereType<ServicePackage>().toList()
          : (json['packages'] is Map)
              ? [ServicePackage.fromJson(Map<String, dynamic>.from(json['packages'] as Map))]
              : null,
      eventTypes: (json['event_types'] is List) 
          ? (json['event_types'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
          : (json['options'] != null && json['options'] is Map && json['options']['eventTypes'] is List)
              ? (json['options']['eventTypes'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
              : [],
      allowedActions: (json['allowed_actions'] is List) 
          ? (json['allowed_actions'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
          : (json['allowed_actions'] is Map)
              ? []
              : ['book'],
      locations: (json['locations'] is List) 
          ? (json['locations'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
          : (json['locations'] is Map)
              ? []
              : [],
      venueAddress: json['venue_address']?.toString(),
      coverageArea: json['coverage_area']?.toString(),
      timeRule: json['time_rule'] != null ? ServiceTimeRule.fromJson(_parseMap(json['time_rule'])) : null,
      logisticsConfig: json['logistics_config'] != null ? ServiceLogistics.fromJson(_parseMap(json['logistics_config'])) : null,
      pricingTiers: _parseList(json['pricing_tiers'] ?? json['pricingTiers'] ?? json['service_pricing_tiers']).map((e) => ServicePricingTier.fromJson(e)).toList().cast<ServicePricingTier>(),
      components: _parseList(json['components'] ?? json['service_components']).map((e) => ServiceComponent.fromJson(e)).toList().cast<ServiceComponent>(),
      
      minOrderQty: (json['min_order_qty'] as num?)?.toInt(),
      productionDays: (json['production_days'] as num?)?.toInt(),
      minRentalDays: (json['min_rental_days'] as num?)?.toInt(),
      maxRentalDays: (json['max_rental_days'] as num?)?.toInt(),
      
      // New fields parsing
      pricingModel: json['pricing_model'] != null ? PricingModel.fromJson(_parseMap(json['pricing_model'])) : null,
      addOns: json['add_ons'] != null ? _parseList(json['add_ons']).map((e) => ServiceAddOn.fromJson(e)).toList().cast<ServiceAddOn>() : null,
      teamCapacity: json['team_capacity'] != null ? TeamCapacityConfig.fromJson(_parseMap(json['team_capacity'])) : null,
      slotConfig: json['slot_config'] != null ? AvailabilitySlotConfig.fromJson(_parseMap(json['slot_config'])) : null,
      allowSameDayMultiEvent: json['allow_same_day_multi_event'] ?? false,
      sameDayDiscount: (json['same_day_discount'] as num?)?.toDouble(),
      differentDaySurcharge: (json['different_day_surcharge'] as num?)?.toDouble(),
      installmentEnabled: json['installment_enabled'] ?? false,
      depositPercentage: (json['deposit_percentage'] as num?)?.toDouble(),
      maxInstallments: (json['max_installments'] as num?)?.toInt(),
      paymentDeadlineDays: (json['payment_deadline_days'] as num?)?.toInt(),
      videoUrl: json['video_url']?.toString(),
      weddingTimeline: WeddingPrepTimeline.fromJsonList(json['wedding_timeline']),
      guarantee: ServiceGuarantee.fromNullableJson(json['guarantee']),
      commissionRate: (json['commission_rate'] as num?)?.toDouble(),
      commissionOverride: json['commission_override'] ?? false,
      isTransportIncluded: json['is_transport_included'] ?? false,
      isAccommodationIncluded: json['is_accommodation_included'] ?? false,
      isSetupIncluded: json['is_setup_included'] ?? true,
      otherFeesDescription: json['other_fees_description']?.toString(),
      productLogistics: json['product_logistics'] != null ? ProductLogistics.fromJson(_parseMap(json['product_logistics'])) : null,
      bulkPricingTiers: json['bulk_pricing_tiers'] != null ? _parseList(json['bulk_pricing_tiers']).map((e) => BulkPricingTier.fromJson(e)).toList().cast<BulkPricingTier>() : null,
      variations: json['variations'] != null ? _parseList(json['variations']).map((e) => ProductVariation.fromJson(e)).toList().cast<ProductVariation>() : null,
      vendorPriorityScore: json['vendor_profiles'] is Map
          ? ((json['vendor_profiles'] as Map)['priority_score'] as num?)?.toDouble() ?? 0
          : 0,
    );
  }

  static List<dynamic> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is String) {
      if (data.isEmpty || data == '[]' || data == '{}') return [];
      try {
        final decoded = jsonDecode(data);
        if (decoded is List) return decoded;
      } catch (e) {
        print('Error decoding JSON list string: $e');
      }
    }
    return [];
  }

  static Map<String, dynamic> _parseMap(dynamic data) {
    if (data == null) return {};
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      if (data.isEmpty || data == '{}' || data == '[]') return {};
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (e) {
        print('Error decoding JSON string: $e');
      }
    }
    return {};
  }

  static Map<String, double> _parseMultiLayerPricing(dynamic data) {
    final map = _parseMap(data);
    return map.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'name': name,
      'description': description,
      'category': category.id,
      'subcategory': subcategory,
      'multi_layer_pricing': multiLayerPricing,
      'base_price': basePrice,
      'original_price': originalPrice,
      'promo_expiry': promoExpiry?.toIso8601String(),
      'hourly_rate': hourlyRate,
      'is_active': active,
      'approval_status': approvalStatus.name,
      'availability': availability,
      'max_bookings_per_day': maxBookingsPerDay,
      'advance_booking_days': advanceBookingDays,
      'service_type': type.name,
      'service_types': types.map((e) => e.name).toList(),
      'images': images,
      'options': options,
      'requirements': requirements,
      'logistics': logistics,
      'service_status': status.name,
      // 'created_at': createdAt.toIso8601String(), // Usually handled by DB
      'updated_at': DateTime.now().toIso8601String(),
      'supports_appointments': supportsAppointments,
      'supports_rentals': supportsRentals,
      'amenities': amenities,
      'cancellation_policy': cancellationPolicy,
      'cancellation_policy_type': cancellationPolicyType,
      'reviews': reviews,
      'packages': packages?.map((p) => p.toJson()).toList(),
      'allowed_actions': allowedActions,
      'locations': locations,
      'venue_address': venueAddress,
      'coverage_area': coverageArea,
      'event_types': eventTypes,
      'time_rule': timeRule?.toJson(),
      'logistics_config': logisticsConfig?.toJson(),
      'pricing_tiers': pricingTiers.map((t) => t.toJson()).toList(),
      'components': components.map((c) => c.toJson()).toList(),
      
      'min_order_qty': minOrderQty,
      'production_days': productionDays,
      'min_rental_days': minRentalDays,
      'max_rental_days': maxRentalDays,
      
      // New fields serialization
      'pricing_model': pricingModel?.toJson(),
      'add_ons': addOns?.map((a) => a.toJson()).toList(),
      'team_capacity': teamCapacity?.toJson(),
      'slot_config': slotConfig?.toJson(),
      'allow_same_day_multi_event': allowSameDayMultiEvent,
      'same_day_discount': sameDayDiscount,
      'different_day_surcharge': differentDaySurcharge,
      'installment_enabled': installmentEnabled,
      'deposit_percentage': depositPercentage,
      'max_installments': maxInstallments,
      'payment_deadline_days': paymentDeadlineDays,
      'wedding_timeline': weddingTimeline != null ? WeddingPrepTimeline.toJsonList(weddingTimeline!) : null,
      'guarantee': guarantee?.toJson(),
      'product_logistics': productLogistics?.toJson(),
      'bulk_pricing_tiers': bulkPricingTiers?.map((e) => e.toJson()).toList(),
      'variations': variations?.map((e) => e.toJson()).toList(),
      'commission_rate': commissionRate,
      'commission_override': commissionOverride,
      'is_transport_included': isTransportIncluded,
      'is_accommodation_included': isAccommodationIncluded,
      'is_setup_included': isSetupIncluded,
      'other_fees_description': otherFeesDescription,
    };
  }
}
