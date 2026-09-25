import '../../../features/vendor/data/models/vendor.dart';
import '../../../shared/models/event/event_category.dart';
import 'service_components.dart';
import 'service_enums.dart';

/// Universal Service Model covering all service types (venues, products, packages, rentals, services, free/promotional listings)
class UniversalService {
  // A. Basic Information (Required for All Types)
  final String id;
  final String name;
  final EventCategory category;
  final String? subcategory;
  final String shortDescription;
  final String? detailedDescription;
  final List<String> coverImages;
  final List<String> galleryImages;
  final List<String> tags;
  final ServiceStatus status;
  final String vendorId;
  final String? vendorName;
  final String? vendorProfileLink;
  final String? videoUrl; // Added

  // B. Pricing & Payment Settings
  final PricingMode pricingMode;
  final double basePrice;
  final double? deposit;
  final int? minQuantity;
  final int? maxQuantity;
  final int? capacity;
  final Map<String, double> tierPricing; // e.g., {'50-100': 100.0, '101-200': 150.0}
  final bool priceVisible;
  final String currency;
  final double? taxRate;
  final double? serviceCharge;

  // C. Availability & Scheduling
  final AvailabilityType availabilityType;
  final List<int> availableDays; // 1=Monday, 7=Sunday
  final String? startTime;
  final String? endTime;
  final List<DateTime> blockedDates;
  final int? advanceBookingNotice; // in days
  final Map<String, dynamic> rentalDurationOptions; // e.g., {'hourly': true, 'daily': true, 'weekly': false}
  final String? deliveryTime;
  final String? setupTime;

  // D. Variations & Options
  final List<VariationGroup> variationGroups;
  final Map<String, dynamic> customInputs; // For special instructions
  final bool stockControlEnabled;
  final int? stockQuantity;

  // E. Included Items / Components
  final List<IncludedItem> includedItems;
  final List<Addon> optionalAddons;
  final List<String> bundledServiceIds; // For combo packages

  // F. Promotions & Discounts
  final bool promotionEnabled;
  final Promotion? activePromotion;

  // G. Free Section / Giveaway
  final bool isFree;
  final int? freeQuota;
  final DateTime? freeStartDate;
  final DateTime? freeEndDate;
  final bool convertToPaidAfterExpiry;
  final int freeClaimsCount;

  // H. Location / Service Area
  final String? venueAddress;
  final String? coverageArea;
  final String? city;
  final String? state;
  final String? googleMapEmbed;
  final double? deliveryRadius;
  final double? deliveryFee;

  // I. Rental / Equipment Settings
  final RentalType? rentalType;
  final Map<String, double> rentalRates; // e.g., {'hourly': 50.0, 'daily': 200.0}
  final double? rentalDeposit;
  final String? refundPolicy;
  final double? damageFee;

  // J. Customer Interaction & Visibility
  final bool allowChatNegotiation;
  final bool allowDirectBooking;
  final bool hideContactInfo;
  final bool showInSearch;
  final bool featuredListing;
  final List<String> allowedActions; // e.g., ['book', 'enquiry', 'quote']

  // K. Analytics & Tracking
  final ServiceAnalytics analytics;

  // L. Admin / Approval Metadata
  final ApprovalStatus approvalStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? adminNotes;

  UniversalService({
    required this.id,
    required this.name,
    required this.category,
    this.subcategory,
    required this.shortDescription,
    this.detailedDescription,
    this.coverImages = const [],
    this.galleryImages = const [],
    this.tags = const [],
    this.status = ServiceStatus.active,
    required this.vendorId,
    this.vendorName,
    this.vendorProfileLink,
    this.videoUrl, // Added
    this.pricingMode = PricingMode.flatRate,
    required this.basePrice,
    this.deposit,
    this.minQuantity,
    this.maxQuantity,
    this.capacity,
    this.tierPricing = const {},
    this.priceVisible = true,
    this.currency = 'MYR',
    this.taxRate,
    this.serviceCharge,
    this.availabilityType = AvailabilityType.alwaysAvailable,
    this.availableDays = const [1, 2, 3, 4, 5, 6, 7], // All days
    this.startTime,
    this.endTime,
    this.blockedDates = const [],
    this.advanceBookingNotice,
    this.rentalDurationOptions = const {},
    this.deliveryTime,
    this.setupTime,
    this.variationGroups = const [],
    this.customInputs = const {},
    this.stockControlEnabled = false,
    this.stockQuantity,
    this.includedItems = const [],
    this.optionalAddons = const [],
    this.bundledServiceIds = const [],
    this.promotionEnabled = false,
    this.activePromotion,
    this.isFree = false,
    this.freeQuota,
    this.freeStartDate,
    this.freeEndDate,
    this.convertToPaidAfterExpiry = false,
    this.freeClaimsCount = 0,
    this.venueAddress,
    this.coverageArea,
    this.city,
    this.state,
    this.googleMapEmbed,
    this.deliveryRadius,
    this.deliveryFee,
    this.rentalType,
    this.rentalRates = const {},
    this.rentalDeposit,
    this.refundPolicy,
    this.damageFee,
    this.allowChatNegotiation = true,
    this.allowDirectBooking = true,
    this.hideContactInfo = false,
    this.showInSearch = true,
    this.featuredListing = false,
    this.allowedActions = const ['book'],
    ServiceAnalytics? analytics,
    this.approvalStatus = ApprovalStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.adminNotes,
  }) : analytics = analytics ?? ServiceAnalytics(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Computed properties
  bool get isAvailable => status == ServiceStatus.active && approvalStatus == ApprovalStatus.approved;
  bool get hasVariations => variationGroups.isNotEmpty;
  bool get hasAddons => optionalAddons.isNotEmpty;
  bool get hasPromotion => promotionEnabled && activePromotion?.isActive == true;
  bool get isRental => rentalType != null;
  bool get isPackage => bundledServiceIds.isNotEmpty || includedItems.isNotEmpty;
  double get effectivePrice => hasPromotion && activePromotion != null
      ? activePromotion!.type == DiscountType.percentage
          ? basePrice * (1 - activePromotion!.value / 100)
          : basePrice - activePromotion!.value
      : basePrice;


  // Check availability for a specific date
  bool isAvailableOnDate(DateTime date) {
    if (blockedDates.contains(date)) return false;
    if (availabilityType == AvailabilityType.alwaysAvailable) return true;
    if (!availableDays.contains(date.weekday)) return false;
    // Additional time-based checks can be added here
    return true;
  }

  // Copy with method for immutability
  UniversalService copyWith({
    String? id,
    String? name,
    EventCategory? category,
    String? subcategory,
    String? shortDescription,
    String? detailedDescription,
    List<String>? coverImages,
    List<String>? galleryImages,
    List<String>? tags,
    ServiceStatus? status,
    String? vendorId,
    String? vendorName,
    String? vendorProfileLink,
    String? videoUrl, // Added
    PricingMode? pricingMode,
    double? basePrice,
    double? deposit,
    int? minQuantity,
    int? maxQuantity,
    int? capacity,
    Map<String, double>? tierPricing,
    bool? priceVisible,
    String? currency,
    double? taxRate,
    double? serviceCharge,
    AvailabilityType? availabilityType,
    List<int>? availableDays,
    String? startTime,
    String? endTime,
    List<DateTime>? blockedDates,
    int? advanceBookingNotice,
    Map<String, dynamic>? rentalDurationOptions,
    String? deliveryTime,
    String? setupTime,
    List<VariationGroup>? variationGroups,
    Map<String, dynamic>? customInputs,
    bool? stockControlEnabled,
    int? stockQuantity,
    List<IncludedItem>? includedItems,
    List<Addon>? optionalAddons,
    List<String>? bundledServiceIds,
    bool? promotionEnabled,
    Promotion? activePromotion,
    bool? isFree,
    int? freeQuota,
    DateTime? freeStartDate,
    DateTime? freeEndDate,
    bool? convertToPaidAfterExpiry,
    int? freeClaimsCount,
    String? venueAddress,
    String? coverageArea,
    String? city,
    String? state,
    String? googleMapEmbed,
    double? deliveryRadius,
    double? deliveryFee,
    RentalType? rentalType,
    Map<String, double>? rentalRates,
    double? rentalDeposit,
    String? refundPolicy,
    double? damageFee,
    bool? allowChatNegotiation,
    bool? allowDirectBooking,
    bool? hideContactInfo,
    bool? showInSearch,
    bool? featuredListing,
    List<String>? allowedActions,
    ServiceAnalytics? analytics,
    ApprovalStatus? approvalStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminNotes,
  }) {
    return UniversalService(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      shortDescription: shortDescription ?? this.shortDescription,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      coverImages: coverImages ?? this.coverImages,
      galleryImages: galleryImages ?? this.galleryImages,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorProfileLink: vendorProfileLink ?? this.vendorProfileLink,
      videoUrl: videoUrl ?? this.videoUrl, // Added
      pricingMode: pricingMode ?? this.pricingMode,
      basePrice: basePrice ?? this.basePrice,
      deposit: deposit ?? this.deposit,
      minQuantity: minQuantity ?? this.minQuantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      capacity: capacity ?? this.capacity,
      tierPricing: tierPricing ?? this.tierPricing,
      priceVisible: priceVisible ?? this.priceVisible,
      currency: currency ?? this.currency,
      taxRate: taxRate ?? this.taxRate,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      availabilityType: availabilityType ?? this.availabilityType,
      availableDays: availableDays ?? this.availableDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      blockedDates: blockedDates ?? this.blockedDates,
      advanceBookingNotice: advanceBookingNotice ?? this.advanceBookingNotice,
      rentalDurationOptions: rentalDurationOptions ?? this.rentalDurationOptions,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      setupTime: setupTime ?? this.setupTime,
      variationGroups: variationGroups ?? this.variationGroups,
      customInputs: customInputs ?? this.customInputs,
      stockControlEnabled: stockControlEnabled ?? this.stockControlEnabled,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      includedItems: includedItems ?? this.includedItems,
      optionalAddons: optionalAddons ?? this.optionalAddons,
      bundledServiceIds: bundledServiceIds ?? this.bundledServiceIds,
      promotionEnabled: promotionEnabled ?? this.promotionEnabled,
      activePromotion: activePromotion ?? this.activePromotion,
      isFree: isFree ?? this.isFree,
      freeQuota: freeQuota ?? this.freeQuota,
      freeStartDate: freeStartDate ?? this.freeStartDate,
      freeEndDate: freeEndDate ?? this.freeEndDate,
      convertToPaidAfterExpiry: convertToPaidAfterExpiry ?? this.convertToPaidAfterExpiry,
      freeClaimsCount: freeClaimsCount ?? this.freeClaimsCount,
      venueAddress: venueAddress ?? this.venueAddress,
      coverageArea: coverageArea ?? this.coverageArea,
      city: city ?? this.city,
      state: state ?? this.state,
      googleMapEmbed: googleMapEmbed ?? this.googleMapEmbed,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      rentalType: rentalType ?? this.rentalType,
      rentalRates: rentalRates ?? this.rentalRates,
      rentalDeposit: rentalDeposit ?? this.rentalDeposit,
      refundPolicy: refundPolicy ?? this.refundPolicy,
      damageFee: damageFee ?? this.damageFee,
      allowChatNegotiation: allowChatNegotiation ?? this.allowChatNegotiation,
      allowDirectBooking: allowDirectBooking ?? this.allowDirectBooking,
      hideContactInfo: hideContactInfo ?? this.hideContactInfo,
      showInSearch: showInSearch ?? this.showInSearch,
      featuredListing: featuredListing ?? this.featuredListing,
      allowedActions: allowedActions ?? this.allowedActions,
      analytics: analytics ?? this.analytics,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.id,
        'subcategory': subcategory,
        'shortDescription': shortDescription,
        'detailedDescription': detailedDescription,
        'coverImages': coverImages,
        'galleryImages': galleryImages,
        'tags': tags,
        'status': status.name,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'vendorProfileLink': vendorProfileLink,
        'videoUrl': videoUrl, // Added
        'pricingMode': pricingMode.name,
        'basePrice': basePrice,
        'deposit': deposit,
        'minQuantity': minQuantity,
        'maxQuantity': maxQuantity,
        'capacity': capacity,
        'tierPricing': tierPricing,
        'priceVisible': priceVisible,
        'currency': currency,
        'taxRate': taxRate,
        'serviceCharge': serviceCharge,
        'availabilityType': availabilityType.name,
        'availableDays': availableDays,
        'startTime': startTime,
        'endTime': endTime,
        'blockedDates': blockedDates.map((d) => d.toIso8601String()).toList(),
        'advanceBookingNotice': advanceBookingNotice,
        'rentalDurationOptions': rentalDurationOptions,
        'deliveryTime': deliveryTime,
        'setupTime': setupTime,
        'variationGroups': variationGroups.map((v) => v.toJson()).toList(),
        'customInputs': customInputs,
        'stockControlEnabled': stockControlEnabled,
        'stockQuantity': stockQuantity,
        'includedItems': includedItems.map((i) => i.toJson()).toList(),
        'optionalAddons': optionalAddons.map((a) => a.toJson()).toList(),
        'bundledServiceIds': bundledServiceIds,
        'promotionEnabled': promotionEnabled,
        'activePromotion': activePromotion?.toJson(),
        'isFree': isFree,
        'freeQuota': freeQuota,
        'freeStartDate': freeStartDate?.toIso8601String(),
        'freeEndDate': freeEndDate?.toIso8601String(),
        'convertToPaidAfterExpiry': convertToPaidAfterExpiry,
        'freeClaimsCount': freeClaimsCount,
        'venueAddress': venueAddress,
        'coverageArea': coverageArea,
        'city': city,
        'state': state,
        'googleMapEmbed': googleMapEmbed,
        'deliveryRadius': deliveryRadius,
        'deliveryFee': deliveryFee,
        'rentalType': rentalType?.name,
        'rentalRates': rentalRates,
        'rentalDeposit': rentalDeposit,
        'refundPolicy': refundPolicy,
        'damageFee': damageFee,
        'allowChatNegotiation': allowChatNegotiation,
        'allowDirectBooking': allowDirectBooking,
        'hideContactInfo': hideContactInfo,
        'showInSearch': showInSearch,
        'featuredListing': featuredListing,
        'allowedActions': allowedActions,
        'analytics': analytics.toJson(),
        'approvalStatus': approvalStatus.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'adminNotes': adminNotes,
      };

  factory UniversalService.fromJson(Map<String, dynamic> json) => UniversalService(
        id: json['id'],
        name: json['name'],
        category: EventCategory.values.firstWhere((c) => c.id == json['category'], orElse: () => EventCategory.catering),
        subcategory: json['subcategory'],
        shortDescription: json['shortDescription'],
        detailedDescription: json['detailedDescription'],
        coverImages: List<String>.from(json['coverImages'] ?? []),
        galleryImages: List<String>.from(json['galleryImages'] ?? []),
        tags: List<String>.from(json['tags'] ?? []),
        status: ServiceStatus.values.firstWhere((s) => s.name == json['status'], orElse: () => ServiceStatus.inactive),
        vendorId: json['vendorId'],
        vendorName: json['vendorName'],
        vendorProfileLink: json['vendorProfileLink'],
        videoUrl: json['videoUrl'], // Added
        pricingMode: PricingMode.values.firstWhere((p) => p.name == json['pricingMode'], orElse: () => PricingMode.flatRate),
        basePrice: json['basePrice'].toDouble(),
        deposit: json['deposit']?.toDouble(),
        minQuantity: json['minQuantity'],
        maxQuantity: json['maxQuantity'],
        capacity: json['capacity'],
        tierPricing: Map<String, double>.from(json['tierPricing'] ?? {}),
        priceVisible: json['priceVisible'] ?? true,
        currency: json['currency'] ?? 'MYR',
        taxRate: json['taxRate']?.toDouble(),
        serviceCharge: json['serviceCharge']?.toDouble(),
        availabilityType: AvailabilityType.values.firstWhere((a) => a.name == json['availabilityType'], orElse: () => AvailabilityType.alwaysAvailable),
        availableDays: List<int>.from(json['availableDays'] ?? [1, 2, 3, 4, 5, 6, 7]),
        startTime: json['startTime'],
        endTime: json['endTime'],
        blockedDates: (json['blockedDates'] as List?)?.map((d) => DateTime.parse(d)).toList() ?? [],
        advanceBookingNotice: json['advanceBookingNotice'],
        rentalDurationOptions: Map<String, dynamic>.from(json['rentalDurationOptions'] ?? {}),
        deliveryTime: json['deliveryTime'],
        setupTime: json['setupTime'],
        variationGroups: (json['variationGroups'] as List?)?.map((v) => VariationGroup.fromJson(v)).toList() ?? [],
        customInputs: Map<String, dynamic>.from(json['customInputs'] ?? {}),
        stockControlEnabled: json['stockControlEnabled'] ?? false,
        stockQuantity: json['stockQuantity'],
        includedItems: (json['includedItems'] as List?)?.map((i) => IncludedItem.fromJson(i)).toList() ?? [],
        optionalAddons: (json['optionalAddons'] as List?)?.map((a) => Addon.fromJson(a)).toList() ?? [],
        bundledServiceIds: List<String>.from(json['bundledServiceIds'] ?? []),
        promotionEnabled: json['promotionEnabled'] ?? false,
        activePromotion: json['activePromotion'] != null ? Promotion.fromJson(json['activePromotion']) : null,
        isFree: json['isFree'] ?? false,
        freeQuota: json['freeQuota'],
        freeStartDate: json['freeStartDate'] != null ? DateTime.parse(json['freeStartDate']) : null,
        freeEndDate: json['freeEndDate'] != null ? DateTime.parse(json['freeEndDate']) : null,
        convertToPaidAfterExpiry: json['convertToPaidAfterExpiry'] ?? false,
        freeClaimsCount: json['freeClaimsCount'] ?? 0,
        venueAddress: json['venueAddress'],
        coverageArea: json['coverageArea'],
        city: json['city'],
        state: json['state'],
        googleMapEmbed: json['googleMapEmbed'],
        deliveryRadius: json['deliveryRadius']?.toDouble(),
        deliveryFee: json['deliveryFee']?.toDouble(),
        rentalType: json['rentalType'] != null ? RentalType.values.firstWhere((r) => r.name == json['rentalType']) : null,
        rentalRates: Map<String, double>.from(json['rentalRates'] ?? {}),
        rentalDeposit: json['rentalDeposit']?.toDouble(),
        refundPolicy: json['refundPolicy'],
        damageFee: json['damageFee']?.toDouble(),
        allowChatNegotiation: json['allowChatNegotiation'] ?? true,
        allowDirectBooking: json['allowDirectBooking'] ?? true,
        hideContactInfo: json['hideContactInfo'] ?? false,
        showInSearch: json['showInSearch'] ?? true,
        featuredListing: json['featuredListing'] ?? false,
        allowedActions: List<String>.from(json['allowedActions'] ?? ['book']),
        analytics: json['analytics'] != null ? ServiceAnalytics.fromJson(json['analytics']) : const ServiceAnalytics(),
        approvalStatus: ApprovalStatus.values.firstWhere((a) => a.name == json['approvalStatus'], orElse: () => ApprovalStatus.pending),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        adminNotes: json['adminNotes'],
      );

}
