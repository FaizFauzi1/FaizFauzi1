import '../../../shared/models/event/event_category.dart';
import '../../../shared/models/services/service_enums.dart';
import '../../../shared/models/services/service_components.dart';
import '../../../shared/models/services/universal_service.dart';
import '../../../shared/models/services/service_time_rule.dart';
import '../../../shared/models/services/service_logistics.dart';
import 'service_template_models.dart';
import '../../../shared/models/services/pricing_model.dart';
import '../../../shared/models/services/team_capacity.dart';
import 'vendor_service.dart';
import '../../../shared/models/services/wedding_preparation_timeline.dart';
import '../../../shared/models/services/service_guarantee.dart';

class VendorServiceEnhanced {
  final String id;
  final String name;
  final EventCategory productCategory;
  final List<ServiceType> serviceTypes;
  ServiceType get serviceType => serviceTypes.isNotEmpty ? serviceTypes.first : ServiceType.product;
  List<ServiceType> get types => serviceTypes;
  
  final String description;
  final String? subcategory;
  final Map<String, double> multiLayerPricing;
  final List<String> images;
  final Map<String, dynamic> availability;
  final int inventory;
  final Map<String, dynamic> logistics; // e.g., deliveryFee, radius
  final bool isActive;
  final String vendorId;
  final double price;
  final double? hourlyRate;
  final double? dailyRate;
  final ServiceStatus status;
  final ApprovalStatus approvalStatus;
  final double? originalPrice; 
  final DateTime? promoExpiry; 
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> extendedAvailability;
  final List<Map<String, dynamic>> unavailablePeriods;
  final int maxBookingsPerDay;
  final int advanceBookingDays;
  final Map<String, dynamic> options;
  final bool supportsAppointments;
  final bool supportsRentals;
  final String? coverageArea;
  final List<String>? locations;
  final String? venueAddress;
  final List<Map<String, dynamic>>? reviews;
  final List<String> allowedActions;
  final List<String> eventTypes;
  final String? cancellationPolicy;
  final String cancellationPolicyType; 
  final ServiceTimeRule? timeRule;
  final ServiceLogistics? logisticsConfig;
  final BookingLogistics? bookingLogistics;
  
  final List<ServicePricingTier> pricingTiers;
  final List<ServiceComponent> components;

  final int? minOrderQty;
  final int? productionDays;
  final int? minRentalDays;
  final int? maxRentalDays;

  final String? videoUrl;

  final PricingModel? pricingModel;
  final List<ServiceAddOn>? addOns;
  final TeamCapacityConfig? teamCapacity;
  final AvailabilitySlotConfig? slotConfig;
  final bool allowSameDayMultiEvent;
  final double? sameDayDiscount;
  final double? differentDaySurcharge;

  final bool installmentEnabled;
  final double? depositPercentage;
  final int? maxInstallments;
  final int? paymentDeadlineDays;

  // NEW Wedding Package Fields
  final List<WeddingPrepMilestone>? weddingTimeline;
  final ServiceGuarantee? guarantee;

  // NEW Logistics & Pricing Models
  final ProductLogistics? productLogistics;
  final List<BulkPricingTier>? bulkPricingTiers;
  final List<ProductVariation>? variations;

  VendorServiceEnhanced({
    required this.id,
    required this.name,
    required this.productCategory,
    this.serviceTypes = const [ServiceType.product],
    this.description = '',
    this.subcategory,
    this.multiLayerPricing = const {},
    this.images = const [],
    this.availability = const {},
    this.inventory = 0,
    this.logistics = const {},
    this.isActive = true,
    required this.vendorId,
    this.price = 0.0,
    this.hourlyRate,
    this.dailyRate,
    this.status = ServiceStatus.active,
    this.approvalStatus = ApprovalStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.extendedAvailability = const {},
    this.unavailablePeriods = const [],
    this.maxBookingsPerDay = 10,
    this.advanceBookingDays = 7,
    this.options = const {},
    this.supportsAppointments = false,
    this.supportsRentals = false,
    this.allowedActions = const ['book'], 
    this.eventTypes = const [],
    this.locations,
    this.venueAddress,
    this.coverageArea,
    this.reviews,
    this.cancellationPolicy,
    this.cancellationPolicyType = 'platform',
    this.timeRule,
    this.logisticsConfig,
    this.bookingLogistics,
    this.originalPrice,
    this.promoExpiry,
    this.pricingTiers = const [],
    this.components = const [],
    this.minOrderQty,
    this.productionDays,
    this.minRentalDays,
    this.maxRentalDays,
    this.videoUrl,
    this.pricingModel,
    this.addOns,
    this.teamCapacity,
    this.slotConfig,
    this.allowSameDayMultiEvent = false,
    this.sameDayDiscount,
    this.differentDaySurcharge,
    this.installmentEnabled = false,
    this.depositPercentage,
    this.maxInstallments,
    this.paymentDeadlineDays,
    this.weddingTimeline,
    this.guarantee,
    this.productLogistics,
    this.bulkPricingTiers,
    this.variations,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();


  EventCategory get category => productCategory;

  double get basePrice => getMinPrice();

  double getMinPrice() {
    double min = price;
    if (pricingModel != null) {
      if (pricingModel!.basePrice != null) {
        if (min == 0 || pricingModel!.basePrice! < min) min = pricingModel!.basePrice!;
      }
      if (pricingModel!.eventCombinations != null && pricingModel!.eventCombinations!.isNotEmpty) {
        double comboMin = pricingModel!.eventCombinations!.map((c) => c.price).reduce((a, b) => a < b ? a : b);
        if (min == 0 || comboMin < min) min = comboMin;
      }
    }
    if (pricingTiers.isNotEmpty) {
      double tierMin = pricingTiers.map((t) => t.price).reduce((a, b) => a < b ? a : b);
      if (min == 0 || tierMin < min) min = tierMin;
    }
    if (multiLayerPricing.isNotEmpty) {
      double multiMin = multiLayerPricing.values.reduce((a, b) => a < b ? a : b);
      if (min == 0 || multiMin < min) min = multiMin;
    }
    return min;
  }

  double getMaxPrice() {
    double max = price;
    if (pricingModel != null) {
      if (pricingModel!.basePrice != null && pricingModel!.basePrice! > max) {
        max = pricingModel!.basePrice!;
      }
      if (pricingModel!.eventCombinations != null && pricingModel!.eventCombinations!.isNotEmpty) {
        double comboMax = pricingModel!.eventCombinations!.map((c) => c.price).reduce((a, b) => a > b ? a : b);
        if (comboMax > max) max = comboMax;
      }
    }
    if (pricingTiers.isNotEmpty) {
      double tierMax = pricingTiers.map((t) => t.price).reduce((a, b) => a > b ? a : b);
      if (tierMax > max) max = tierMax;
    }
    if (multiLayerPricing.isNotEmpty) {
      double multiMax = multiLayerPricing.values.reduce((a, b) => a > b ? a : b);
      if (multiMax > max) max = multiMax;
    }
    return max;
  }

  bool get hasDynamicPricing => multiLayerPricing.isNotEmpty || pricingModel != null || pricingTiers.isNotEmpty;
  Map<String, dynamic> get packageOptions => options;
  bool get hasDelivery => logistics.containsKey('deliveryFee');
  bool get hasSetup => options.containsKey('setup');

  static String _getDayName(int weekday) {
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

  bool isAvailableOnDate(DateTime date) {
    final dayName = _getDayName(date.weekday);
    final daySchedule = availability[dayName];
    return daySchedule != null && daySchedule['available'] == true;
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

  VendorServiceEnhanced copyWith({
    String? id,
    String? name,
    EventCategory? productCategory,
    List<ServiceType>? serviceTypes,
    String? description,
    String? subcategory,
    Map<String, double>? multiLayerPricing,
    List<String>? images,
    Map<String, dynamic>? availability,
    int? inventory,
    Map<String, dynamic>? logistics,
    bool? isActive,
    String? vendorId,
    double? price,
    double? hourlyRate,
    double? dailyRate,
    ServiceStatus? status,
    ApprovalStatus? approvalStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? extendedAvailability,
    List<Map<String, dynamic>>? unavailablePeriods,
    int? maxBookingsPerDay,
    int? advanceBookingDays,
    Map<String, dynamic>? options,
    bool? supportsAppointments,
    bool? supportsRentals,
    List<String>? allowedActions,
    List<String>? eventTypes,
    List<String>? locations,
    String? venueAddress,
    String? coverageArea,
    String? cancellationPolicy,
    String? cancellationPolicyType,
    ServiceTimeRule? timeRule,
    ServiceLogistics? logisticsConfig,
    BookingLogistics? bookingLogistics,
    List<ServicePricingTier>? pricingTiers,
    double? originalPrice,
    DateTime? promoExpiry,
    List<ServiceComponent>? components,
    int? minOrderQty,
    int? productionDays,
    int? minRentalDays,
    int? maxRentalDays,
    PricingModel? pricingModel,
    List<ServiceAddOn>? addOns,
    TeamCapacityConfig? teamCapacity,
    AvailabilitySlotConfig? slotConfig,
    bool? allowSameDayMultiEvent,
    double? sameDayDiscount,
    double? differentDaySurcharge,
    bool? installmentEnabled,
    double? depositPercentage,
    int? maxInstallments,
    int? paymentDeadlineDays,
    String? videoUrl,
    List<WeddingPrepMilestone>? weddingTimeline,
    ServiceGuarantee? guarantee,
    ProductLogistics? productLogistics,
    List<BulkPricingTier>? bulkPricingTiers,
    List<ProductVariation>? variations,
  }) {
    return VendorServiceEnhanced(
      id: id ?? this.id,
      name: name ?? this.name,
      productCategory: productCategory ?? this.productCategory,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      description: description ?? this.description,
      subcategory: subcategory ?? this.subcategory,
      multiLayerPricing: multiLayerPricing ?? this.multiLayerPricing,
      images: images ?? this.images,
      availability: availability ?? this.availability,
      inventory: inventory ?? this.inventory,
      logistics: logistics ?? this.logistics,
      isActive: isActive ?? this.isActive,
      vendorId: vendorId ?? this.vendorId,
      price: price ?? this.price,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      dailyRate: dailyRate ?? this.dailyRate,
      status: status ?? this.status,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      extendedAvailability: extendedAvailability ?? this.extendedAvailability,
      unavailablePeriods: unavailablePeriods ?? this.unavailablePeriods,
      maxBookingsPerDay: maxBookingsPerDay ?? this.maxBookingsPerDay,
      advanceBookingDays: advanceBookingDays ?? this.advanceBookingDays,
      options: options ?? this.options,
      supportsAppointments: supportsAppointments ?? this.supportsAppointments,
      supportsRentals: supportsRentals ?? this.supportsRentals,
      allowedActions: allowedActions ?? this.allowedActions,
      eventTypes: eventTypes ?? this.eventTypes,
      locations: locations ?? this.locations,
      venueAddress: venueAddress ?? this.venueAddress,
      coverageArea: coverageArea ?? this.coverageArea,
      reviews: reviews ?? this.reviews,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      cancellationPolicyType: cancellationPolicyType ?? this.cancellationPolicyType,
      timeRule: timeRule ?? this.timeRule,
      logisticsConfig: logisticsConfig ?? this.logisticsConfig,
      bookingLogistics: bookingLogistics ?? this.bookingLogistics,
      pricingTiers: pricingTiers ?? this.pricingTiers,
      originalPrice: originalPrice ?? this.originalPrice,
      promoExpiry: promoExpiry ?? this.promoExpiry,
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
      installmentEnabled: installmentEnabled ?? this.installmentEnabled,
      depositPercentage: depositPercentage ?? this.depositPercentage,
      maxInstallments: maxInstallments ?? this.maxInstallments,
      paymentDeadlineDays: paymentDeadlineDays ?? this.paymentDeadlineDays,
      videoUrl: videoUrl ?? this.videoUrl,
      weddingTimeline: weddingTimeline ?? this.weddingTimeline,
      guarantee: guarantee ?? this.guarantee,
      productLogistics: productLogistics ?? this.productLogistics,
      bulkPricingTiers: bulkPricingTiers ?? this.bulkPricingTiers,
      variations: variations ?? this.variations,
    );
  }

  VendorService toVendorService() {
    return VendorService(
      id: id,
      vendorId: vendorId,
      name: name,
      description: description,
      category: productCategory,
      subcategory: subcategory,
      multiLayerPricing: multiLayerPricing,
      basePrice: price,
      originalPrice: originalPrice,
      promoExpiry: promoExpiry,
      hourlyRate: hourlyRate,
      active: isActive,
      approvalStatus: approvalStatus,
      availability: availability,
      maxBookingsPerDay: maxBookingsPerDay,
      advanceBookingDays: advanceBookingDays,
      types: serviceTypes,
      images: images,
      videoUrl: videoUrl,
      options: options,
      logistics: logistics,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      supportsAppointments: supportsAppointments,
      supportsRentals: supportsRentals,
      cancellationPolicy: cancellationPolicy,
      cancellationPolicyType: cancellationPolicyType,
      reviews: reviews,
      allowedActions: allowedActions,
      locations: locations,
      venueAddress: venueAddress,
      coverageArea: coverageArea,
      eventTypes: eventTypes,
      timeRule: timeRule,
      logisticsConfig: logisticsConfig,
      pricingTiers: pricingTiers,
      components: components,
      minOrderQty: minOrderQty,
      productionDays: productionDays,
      minRentalDays: minRentalDays,
      maxRentalDays: maxRentalDays,
      pricingModel: pricingModel,
      addOns: addOns,
      teamCapacity: teamCapacity,
      slotConfig: slotConfig,
      allowSameDayMultiEvent: allowSameDayMultiEvent,
      sameDayDiscount: sameDayDiscount,
      differentDaySurcharge: differentDaySurcharge,
      installmentEnabled: installmentEnabled,
      depositPercentage: depositPercentage,
      maxInstallments: maxInstallments,
      paymentDeadlineDays: paymentDeadlineDays,
      weddingTimeline: weddingTimeline,
      guarantee: guarantee,
      productLogistics: productLogistics,
      bulkPricingTiers: bulkPricingTiers,
      variations: variations,
    );
  }

  UniversalService toUniversalService() {
    List<int> availableDays = [];
    String? startTime;
    String? endTime;

    if (availability.isNotEmpty) {
      availability.forEach((day, schedule) {
        if (schedule is Map && schedule['available'] == true) {
          switch (day.toLowerCase()) {
            case 'monday': availableDays.add(1); break;
            case 'tuesday': availableDays.add(2); break;
            case 'wednesday': availableDays.add(3); break;
            case 'thursday': availableDays.add(4); break;
            case 'friday': availableDays.add(5); break;
            case 'saturday': availableDays.add(6); break;
            case 'sunday': availableDays.add(7); break;
          }
          if (startTime == null && schedule['startTime'] != null) startTime = schedule['startTime'];
          if (endTime == null && schedule['endTime'] != null) endTime = schedule['endTime'];
        }
      });
    }

    if (availableDays.isEmpty) availableDays = [1, 2, 3, 4, 5, 6, 7];

    List<IncludedItem> includedItems = [];
    List<Addon> optionalAddons = [];

    if (options.isNotEmpty) {
      options.forEach((key, value) {
        if (value is Map) {
          if (value['type'] == 'included') {
            includedItems.add(IncludedItem(
              id: key,
              name: value['name'] ?? key,
              description: value['description'] ?? '',
              quantity: value['quantity'] ?? 1,
              customizable: value['customizable'] ?? false,
            ));
          } else if (value['type'] == 'addon') {
            optionalAddons.add(Addon(
              id: key,
              name: value['name'] ?? key,
              description: value['description'] ?? '',
              price: (value['price'] ?? 0.0).toDouble(),
              required: value['required'] ?? false,
              maxQuantity: value['maxQuantity'],
            ));
          }
        }
      });
    }
    
    if (addOns != null) {
      for (var addon in addOns!) {
        optionalAddons.add(Addon(
          id: addon.id,
          name: addon.name,
          description: addon.description ?? '',
          price: addon.fixedPrice ?? 0.0,
          required: !addon.isOptional,
          maxQuantity: addon.maxQuantity,
        ));
      }
    }

    PricingMode pricingMode = PricingMode.flatRate;
    if (supportsRentals && (hourlyRate != null || dailyRate != null)) {
      pricingMode = PricingMode.perHour;
    } else if (serviceType == ServiceType.rental) {
      pricingMode = PricingMode.perDay;
    } else if (pricingModel != null) {
      switch (pricingModel!.type) {
        case PricingModelType.perHour: pricingMode = PricingMode.perHour; break;
        case PricingModelType.perDay: pricingMode = PricingMode.perDay; break;
        case PricingModelType.perPax: pricingMode = PricingMode.perPax; break;
        default: pricingMode = PricingMode.flatRate; break;
      }
    }

    AvailabilityType availabilityType = supportsAppointments ? AvailabilityType.timeSlot : AvailabilityType.alwaysAvailable;

    List<DateTime> blockedDates = [];
    for (var period in unavailablePeriods) {
      if (period['startDate'] != null && period['endDate'] != null) {
        try {
          DateTime start = DateTime.parse(period['startDate']);
          DateTime end = DateTime.parse(period['endDate']);
          for (DateTime date = start; date.isBefore(end) || date.isAtSameMomentAs(end); date = date.add(const Duration(days: 1))) {
            blockedDates.add(date);
          }
        } catch (e) {
          print('Error parsing blocked dates: $e');
        }
      }
    }

    return UniversalService(
      id: id,
      name: name,
      category: productCategory,
      subcategory: subcategory,
      shortDescription: description,
      detailedDescription: description,
      coverImages: images,
      galleryImages: images,
      videoUrl: videoUrl,
      tags: [serviceType.name],
      status: status,
      vendorId: vendorId,
      basePrice: price,
      pricingMode: pricingMode,
      capacity: maxBookingsPerDay,
      tierPricing: multiLayerPricing,
      priceVisible: true,
      currency: 'MYR',
      availabilityType: availabilityType,
      availableDays: availableDays,
      startTime: startTime,
      endTime: endTime,
      blockedDates: blockedDates,
      advanceBookingNotice: advanceBookingDays,
      rentalDurationOptions: supportsRentals ? {'hourly': hourlyRate != null, 'daily': dailyRate != null} : {},
      deliveryTime: logistics['deliveryTime'],
      setupTime: options['setupTime'],
      variationGroups: [], 
      customInputs: extendedAvailability,
      stockControlEnabled: inventory > 0,
      stockQuantity: inventory,
      includedItems: includedItems,
      optionalAddons: optionalAddons,
      bundledServiceIds: [], 
      promotionEnabled: originalPrice != null && (originalPrice ?? 0) > price,
      activePromotion: originalPrice != null && (originalPrice ?? 0) > price ? Promotion(
        id: 'promo_$id',
        name: 'Special Offer',
        type: DiscountType.flat,
        value: (originalPrice ?? 0) - price,
        endDate: promoExpiry,
      ) : null,
      isFree: false,
      venueAddress: venueAddress ?? (locations?.isNotEmpty == true ? locations!.first : null),
      coverageArea: coverageArea ?? logistics['coverageArea'],
      city: logistics['city'],
      state: logistics['state'],
      googleMapEmbed: logistics['googleMapEmbed'] ?? '',
      deliveryRadius: logistics['radius']?.toDouble(),
      deliveryFee: logistics['deliveryFee']?.toDouble(),
      rentalType: supportsRentals ? RentalType.item : null,
      rentalRates: {
        if (hourlyRate != null) 'hourly': hourlyRate!,
        if (dailyRate != null) 'daily': dailyRate!,
      },
      rentalDeposit: logistics['deposit']?.toDouble(),
      refundPolicy: logistics['refundPolicy'] ?? cancellationPolicy ?? '', 
      damageFee: logistics['damageFee']?.toDouble(),
      allowChatNegotiation: allowedActions.contains('enquiry'),
      allowDirectBooking: allowedActions.contains('book'),
      hideContactInfo: logistics['hideContactInfo'] ?? false,
      showInSearch: isActive,
      featuredListing: logistics['featured'] ?? false,
      allowedActions: allowedActions,
      analytics: ServiceAnalytics(),
      approvalStatus: approvalStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      adminNotes: null,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'product_category': productCategory.id,
      'service_type': serviceType.name,
      'service_types': serviceTypes.map((e) => e.name).toList(),
      'description': description,
      'subcategory': subcategory,
      'multi_layer_pricing': multiLayerPricing,
      'images': images,
      'availability': availability,
      'inventory': inventory,
      'logistics': logistics,
      'is_active': isActive,
      'vendor_id': vendorId,
      'price': price,
      'hourly_rate': hourlyRate,
      'daily_rate': dailyRate,
      'status': status.name,
      'approval_status': approvalStatus.name,
      'original_price': originalPrice,
      'promo_expiry': promoExpiry?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'extended_availability': extendedAvailability,
      'unavailable_periods': unavailablePeriods,
      'max_bookings_per_day': maxBookingsPerDay,
      'advance_booking_days': advanceBookingDays,
      'options': options,
      'supports_appointments': supportsAppointments,
      'supports_rentals': supportsRentals,
      'coverage_area': coverageArea,
      'locations': locations,
      'venue_address': venueAddress,
      'reviews': reviews,
      'allowed_actions': allowedActions,
      'event_types': eventTypes,
      'cancellation_policy': cancellationPolicy,
      'cancellation_policy_type': cancellationPolicyType,
      'time_rule': timeRule?.toJson(),
      'logistics_config': logisticsConfig?.toJson(),
      'booking_logistics': bookingLogistics?.toJson(),
      'pricing_tiers': pricingTiers.map((e) => e.toJson()).toList(),
      'components': components.map((e) => e.toJson()).toList(),
      'min_order_qty': minOrderQty,
      'production_days': productionDays,
      'min_rental_days': minRentalDays,
      'max_rental_days': maxRentalDays,
      'video_url': videoUrl,
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
    };
  }
}
