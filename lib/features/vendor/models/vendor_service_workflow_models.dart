import 'package:flutter/material.dart';

/// Supported service categories in EventEase
enum ServiceCategoryType {
  photography,
  videography,
  catering,
  decoration,
  makeupAndBeauty,
  entertainment,
  eventPlanning,
  venue,
  florist,
  transport,
  rental,
  boutiqueFashion,
  cake,
  invitation,
  other;

  String get displayName {
    switch (this) {
      case ServiceCategoryType.photography:
        return 'Photography';
      case ServiceCategoryType.videography:
        return 'Videography';
      case ServiceCategoryType.catering:
        return 'Catering';
      case ServiceCategoryType.decoration:
        return 'Decoration';
      case ServiceCategoryType.makeupAndBeauty:
        return 'Makeup & Beauty';
      case ServiceCategoryType.entertainment:
        return 'Entertainment';
      case ServiceCategoryType.eventPlanning:
        return 'Event Planning';
      case ServiceCategoryType.venue:
        return 'Venue';
      case ServiceCategoryType.florist:
        return 'Florist';
      case ServiceCategoryType.transport:
        return 'Transport';
      case ServiceCategoryType.rental:
        return 'Rental';
      case ServiceCategoryType.boutiqueFashion:
        return 'Boutique / Fashion';
      case ServiceCategoryType.cake:
        return 'Cake';
      case ServiceCategoryType.invitation:
        return 'Invitation';
      case ServiceCategoryType.other:
        return 'Other';
    }
  }

  IconData get iconData {
    switch (this) {
      case ServiceCategoryType.photography:
        return Icons.camera_alt_outlined;
      case ServiceCategoryType.videography:
        return Icons.videocam_outlined;
      case ServiceCategoryType.catering:
        return Icons.restaurant_outlined;
      case ServiceCategoryType.decoration:
        return Icons.auto_awesome_mosaic_outlined;
      case ServiceCategoryType.makeupAndBeauty:
        return Icons.face_retouching_natural;
      case ServiceCategoryType.entertainment:
        return Icons.music_note_outlined;
      case ServiceCategoryType.eventPlanning:
        return Icons.event_note_outlined;
      case ServiceCategoryType.venue:
        return Icons.account_balance_outlined;
      case ServiceCategoryType.florist:
        return Icons.local_florist_outlined;
      case ServiceCategoryType.transport:
        return Icons.directions_car_outlined;
      case ServiceCategoryType.rental:
        return Icons.chair_outlined;
      case ServiceCategoryType.boutiqueFashion:
        return Icons.checkroom_outlined;
      case ServiceCategoryType.cake:
        return Icons.cake_outlined;
      case ServiceCategoryType.invitation:
        return Icons.mail_outline;
      case ServiceCategoryType.other:
        return Icons.more_horiz;
    }
  }

  Color get brandColor {
    switch (this) {
      case ServiceCategoryType.photography:
        return const Color(0xFF3B82F6); // Blue
      case ServiceCategoryType.videography:
        return const Color(0xFF6366F1); // Indigo
      case ServiceCategoryType.catering:
        return const Color(0xFFF59E0B); // Amber
      case ServiceCategoryType.decoration:
        return const Color(0xFFEC4899); // Pink
      case ServiceCategoryType.makeupAndBeauty:
        return const Color(0xFFD946EF); // Fuchsia
      case ServiceCategoryType.entertainment:
        return const Color(0xFF8B5CF6); // Purple
      case ServiceCategoryType.eventPlanning:
        return const Color(0xFF10B981); // Emerald
      case ServiceCategoryType.venue:
        return const Color(0xFF0EA5E9); // Sky
      case ServiceCategoryType.florist:
        return const Color(0xFF14B8A6); // Teal
      case ServiceCategoryType.transport:
        return const Color(0xFF64748B); // Slate
      case ServiceCategoryType.rental:
        return const Color(0xFFF97316); // Orange
      case ServiceCategoryType.boutiqueFashion:
        return const Color(0xFFE11D48); // Rose
      case ServiceCategoryType.cake:
        return const Color(0xFFF43F5E); // Crimson
      case ServiceCategoryType.invitation:
        return const Color(0xFF84CC16); // Lime
      case ServiceCategoryType.other:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

/// Service status
enum ServiceStatus {
  draft,
  published,
  paused,
  archived;

  String get displayName {
    switch (this) {
      case ServiceStatus.draft:
        return 'Draft';
      case ServiceStatus.published:
        return 'Published';
      case ServiceStatus.paused:
        return 'Paused';
      case ServiceStatus.archived:
        return 'Archived';
    }
  }

  Color get color {
    switch (this) {
      case ServiceStatus.draft:
        return const Color(0xFF9CA3AF);
      case ServiceStatus.published:
        return const Color(0xFF10B981);
      case ServiceStatus.paused:
        return const Color(0xFFF59E0B);
      case ServiceStatus.archived:
        return const Color(0xFFEF4444);
    }
  }
}

/// Pricing models supported across services
enum ServicePricingModel {
  packagePrice,
  hourlyPrice,
  dailyPrice,
  perPersonPrice,
  customQuote;

  String get displayName {
    switch (this) {
      case ServicePricingModel.packagePrice:
        return 'Package Price';
      case ServicePricingModel.hourlyPrice:
        return 'Hourly Rate';
      case ServicePricingModel.dailyPrice:
        return 'Daily Rate';
      case ServicePricingModel.perPersonPrice:
        return 'Per Person / Guest';
      case ServicePricingModel.customQuote:
        return 'Custom Quote Only';
    }
  }
}

/// Common service info shared across all categories
class CommonServiceInfo {
  final String id;
  final String vendorId;
  final String vendorName;
  final String serviceName;
  final ServiceCategoryType category;
  final String subcategory;
  final String description;
  final List<String> photos;
  final List<String> videos;
  final String serviceLocation;
  final String serviceArea;
  final List<String> eventTypesSupported;
  final List<String> tags;

  // Pricing
  final double startingPrice;
  final ServicePricingModel pricingModel;

  // Availability
  final List<String> availableDays;
  final String workingHoursStart;
  final String workingHoursEnd;
  final List<DateTime> blackoutDates;
  final int minBookingNoticeDays;
  final int maxBookingsPerDay;

  // Policies
  final String cancellationPolicy;
  final double depositRequirementPercent;
  final String paymentSchedule;
  final String termsAndConditions;

  // Status
  final ServiceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommonServiceInfo({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.serviceName,
    required this.category,
    this.subcategory = '',
    required this.description,
    this.photos = const [],
    this.videos = const [],
    required this.serviceLocation,
    required this.serviceArea,
    this.eventTypesSupported = const ['Wedding', 'Corporate', 'Birthday', 'Anniversary'],
    this.tags = const [],
    required this.startingPrice,
    this.pricingModel = ServicePricingModel.packagePrice,
    this.availableDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    this.workingHoursStart = '09:00',
    this.workingHoursEnd = '18:00',
    this.blackoutDates = const [],
    this.minBookingNoticeDays = 7,
    this.maxBookingsPerDay = 2,
    this.cancellationPolicy = 'Free cancellation up to 14 days before event date. 50% refund thereafter.',
    this.depositRequirementPercent = 30.0,
    this.paymentSchedule = '30% deposit upon booking, 70% 3 days before event.',
    this.termsAndConditions = 'Standard vendor terms and condition apply.',
    this.status = ServiceStatus.published,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  CommonServiceInfo copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    String? serviceName,
    ServiceCategoryType? category,
    String? subcategory,
    String? description,
    List<String>? photos,
    List<String>? videos,
    String? serviceLocation,
    String? serviceArea,
    List<String>? eventTypesSupported,
    List<String>? tags,
    double? startingPrice,
    ServicePricingModel? pricingModel,
    List<String>? availableDays,
    String? workingHoursStart,
    String? workingHoursEnd,
    List<DateTime>? blackoutDates,
    int? minBookingNoticeDays,
    int? maxBookingsPerDay,
    String? cancellationPolicy,
    double? depositRequirementPercent,
    String? paymentSchedule,
    String? termsAndConditions,
    ServiceStatus? status,
  }) {
    return CommonServiceInfo(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      serviceName: serviceName ?? this.serviceName,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      description: description ?? this.description,
      photos: photos ?? this.photos,
      videos: videos ?? this.videos,
      serviceLocation: serviceLocation ?? this.serviceLocation,
      serviceArea: serviceArea ?? this.serviceArea,
      eventTypesSupported: eventTypesSupported ?? this.eventTypesSupported,
      tags: tags ?? this.tags,
      startingPrice: startingPrice ?? this.startingPrice,
      pricingModel: pricingModel ?? this.pricingModel,
      availableDays: availableDays ?? this.availableDays,
      workingHoursStart: workingHoursStart ?? this.workingHoursStart,
      workingHoursEnd: workingHoursEnd ?? this.workingHoursEnd,
      blackoutDates: blackoutDates ?? this.blackoutDates,
      minBookingNoticeDays: minBookingNoticeDays ?? this.minBookingNoticeDays,
      maxBookingsPerDay: maxBookingsPerDay ?? this.maxBookingsPerDay,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      depositRequirementPercent: depositRequirementPercent ?? this.depositRequirementPercent,
      paymentSchedule: paymentSchedule ?? this.paymentSchedule,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Service tier package under a service
class ServicePackageItem {
  final String id;
  final String serviceId;
  final String packageName; // e.g. Essential, Premium, Luxury
  final String description;
  final double price;
  final String duration; // e.g. '8 hours', 'Full Day'
  final List<String> includedServices;
  final List<String> addOns;
  final double extraHourPrice;
  final double extraDayPrice;
  final double travelFee;
  final double accommodationFee;
  final String availability;
  final String packageSpecificTerms;

  ServicePackageItem({
    required this.id,
    required this.serviceId,
    required this.packageName,
    required this.description,
    required this.price,
    required this.duration,
    this.includedServices = const [],
    this.addOns = const [],
    this.extraHourPrice = 0.0,
    this.extraDayPrice = 0.0,
    this.travelFee = 0.0,
    this.accommodationFee = 0.0,
    this.availability = 'Available on all working days',
    this.packageSpecificTerms = '',
  });

  ServicePackageItem copyWith({
    String? id,
    String? serviceId,
    String? packageName,
    String? description,
    double? price,
    String? duration,
    List<String>? includedServices,
    List<String>? addOns,
    double? extraHourPrice,
    double? extraDayPrice,
    double? travelFee,
    double? accommodationFee,
    String? availability,
    String? packageSpecificTerms,
  }) {
    return ServicePackageItem(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      packageName: packageName ?? this.packageName,
      description: description ?? this.description,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      includedServices: includedServices ?? this.includedServices,
      addOns: addOns ?? this.addOns,
      extraHourPrice: extraHourPrice ?? this.extraHourPrice,
      extraDayPrice: extraDayPrice ?? this.extraDayPrice,
      travelFee: travelFee ?? this.travelFee,
      accommodationFee: accommodationFee ?? this.accommodationFee,
      availability: availability ?? this.availability,
      packageSpecificTerms: packageSpecificTerms ?? this.packageSpecificTerms,
    );
  }
}

/// Appointment purpose per EventEase specification
enum AppointmentPurpose {
  consultation,
  trial,
  visit,
  measurement,
  tasting,
  fitting,
  inspection,
  collection,
  returnItem,
  designReview;

  String get displayName {
    switch (this) {
      case AppointmentPurpose.consultation:
        return 'Consultation';
      case AppointmentPurpose.trial:
        return 'Trial';
      case AppointmentPurpose.visit:
        return 'Site Visit';
      case AppointmentPurpose.measurement:
        return 'Measurement';
      case AppointmentPurpose.tasting:
        return 'Tasting';
      case AppointmentPurpose.fitting:
        return 'Test Fitting';
      case AppointmentPurpose.inspection:
        return 'Inspection';
      case AppointmentPurpose.collection:
        return 'Collection';
      case AppointmentPurpose.returnItem:
        return 'Return';
      case AppointmentPurpose.designReview:
        return 'Design Review';
    }
  }

  IconData get iconData {
    switch (this) {
      case AppointmentPurpose.consultation:
        return Icons.chat_outlined;
      case AppointmentPurpose.trial:
        return Icons.brush_outlined;
      case AppointmentPurpose.visit:
        return Icons.place_outlined;
      case AppointmentPurpose.measurement:
        return Icons.straighten_outlined;
      case AppointmentPurpose.tasting:
        return Icons.restaurant_menu_outlined;
      case AppointmentPurpose.fitting:
        return Icons.accessibility_new_outlined;
      case AppointmentPurpose.inspection:
        return Icons.fact_check_outlined;
      case AppointmentPurpose.collection:
        return Icons.shopping_bag_outlined;
      case AppointmentPurpose.returnItem:
        return Icons.assignment_return_outlined;
      case AppointmentPurpose.designReview:
        return Icons.palette_outlined;
    }
  }
}

/// Defined appointment type configured for a service
class ServiceAppointmentType {
  final String id;
  final String serviceId;
  final String name; // e.g. "Food Tasting", "Venue Site Visit", "Bridal Fitting"
  final String description;
  final AppointmentPurpose purpose;
  final int durationMinutes;
  final String location; // 'Vendor Studio', 'On-site Venue', 'Online Video Call'
  final int maxParticipants;
  final int minBookingNoticeDays;
  final int bufferMinutes;

  // Pricing
  final double fee; // 0.0 for free
  final bool isPaid;
  final bool isDeposit;
  final bool isRefundable;
  final bool creditTowardBooking; // Fee credited to final service purchase

  ServiceAppointmentType({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.description,
    required this.purpose,
    this.durationMinutes = 60,
    this.location = 'Vendor Studio / Location',
    this.maxParticipants = 4,
    this.minBookingNoticeDays = 3,
    this.bufferMinutes = 15,
    this.fee = 0.0,
    this.isPaid = false,
    this.isDeposit = false,
    this.isRefundable = true,
    this.creditTowardBooking = true,
  });

  ServiceAppointmentType copyWith({
    String? id,
    String? serviceId,
    String? name,
    String? description,
    AppointmentPurpose? purpose,
    int? durationMinutes,
    String? location,
    int? maxParticipants,
    int? minBookingNoticeDays,
    int? bufferMinutes,
    double? fee,
    bool? isPaid,
    bool? isDeposit,
    bool? isRefundable,
    bool? creditTowardBooking,
  }) {
    return ServiceAppointmentType(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      description: description ?? this.description,
      purpose: purpose ?? this.purpose,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      minBookingNoticeDays: minBookingNoticeDays ?? this.minBookingNoticeDays,
      bufferMinutes: bufferMinutes ?? this.bufferMinutes,
      fee: fee ?? this.fee,
      isPaid: isPaid ?? this.isPaid,
      isDeposit: isDeposit ?? this.isDeposit,
      isRefundable: isRefundable ?? this.isRefundable,
      creditTowardBooking: creditTowardBooking ?? this.creditTowardBooking,
    );
  }
}

/// Comprehensive appointment booking status
enum ServiceAppointmentStatus {
  requested,
  pendingConfirmation,
  confirmed,
  reminderSent,
  checkedIn,
  inProgress,
  completed,
  cancelled,
  rescheduled,
  noShow,
  declined;

  String get displayName {
    switch (this) {
      case ServiceAppointmentStatus.requested:
        return 'Requested';
      case ServiceAppointmentStatus.pendingConfirmation:
        return 'Pending Confirmation';
      case ServiceAppointmentStatus.confirmed:
        return 'Confirmed';
      case ServiceAppointmentStatus.reminderSent:
        return 'Reminder Sent';
      case ServiceAppointmentStatus.checkedIn:
        return 'Checked In';
      case ServiceAppointmentStatus.inProgress:
        return 'In Progress';
      case ServiceAppointmentStatus.completed:
        return 'Completed';
      case ServiceAppointmentStatus.cancelled:
        return 'Cancelled';
      case ServiceAppointmentStatus.rescheduled:
        return 'Rescheduled';
      case ServiceAppointmentStatus.noShow:
        return 'No Show';
      case ServiceAppointmentStatus.declined:
        return 'Declined';
    }
  }

  Color get color {
    switch (this) {
      case ServiceAppointmentStatus.requested:
      case ServiceAppointmentStatus.pendingConfirmation:
        return const Color(0xFFF59E0B);
      case ServiceAppointmentStatus.confirmed:
        return const Color(0xFF3B82F6);
      case ServiceAppointmentStatus.reminderSent:
        return const Color(0xFF6366F1);
      case ServiceAppointmentStatus.checkedIn:
      case ServiceAppointmentStatus.inProgress:
        return const Color(0xFF8B5CF6);
      case ServiceAppointmentStatus.completed:
        return const Color(0xFF10B981);
      case ServiceAppointmentStatus.cancelled:
      case ServiceAppointmentStatus.declined:
      case ServiceAppointmentStatus.noShow:
        return const Color(0xFFEF4444);
      case ServiceAppointmentStatus.rescheduled:
        return const Color(0xFF0EA5E9);
    }
  }
}

/// Actual booked appointment instance
class ServiceAppointmentBooking {
  final String id;
  final String appointmentTypeId;
  final String appointmentTypeName;
  final AppointmentPurpose purpose;
  final String serviceId;
  final String serviceName;
  final String vendorId;
  final String vendorName;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String? eventId;
  final String? eventName;
  final DateTime scheduledDate;
  final String scheduledTime; // e.g. "14:00"
  final int durationMinutes;
  final int participantsCount;
  final String location;
  final double fee;
  final bool isPaid;
  final bool creditTowardBooking;
  final ServiceAppointmentStatus status;
  final Map<String, dynamic> categorySpecificDetails; // food preferences, sizes, etc.
  final String customerNotes;
  final String? outcomeNotes;
  final String? outcomeStatus; // e.g. "Interested", "Look Approved", "Alteration Required"
  final String? generatedQuoteId;
  final String? linkedChildBookingId;
  final String? packageId;
  final String? packageComponentName;

  ServiceAppointmentBooking({
    required this.id,
    required this.appointmentTypeId,
    required this.appointmentTypeName,
    required this.purpose,
    required this.serviceId,
    required this.serviceName,
    required this.vendorId,
    required this.vendorName,
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    this.eventId,
    this.eventName,
    required this.scheduledDate,
    required this.scheduledTime,
    this.durationMinutes = 60,
    this.participantsCount = 2,
    required this.location,
    this.fee = 0.0,
    this.isPaid = true,
    this.creditTowardBooking = true,
    this.status = ServiceAppointmentStatus.confirmed,
    this.categorySpecificDetails = const {},
    this.customerNotes = '',
    this.outcomeNotes,
    this.outcomeStatus,
    this.generatedQuoteId,
    this.linkedChildBookingId,
    this.packageId,
    this.packageComponentName,
  });

  ServiceAppointmentBooking copyWith({
    String? id,
    String? appointmentTypeId,
    String? appointmentTypeName,
    AppointmentPurpose? purpose,
    String? serviceId,
    String? serviceName,
    String? vendorId,
    String? vendorName,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? eventId,
    String? eventName,
    DateTime? scheduledDate,
    String? scheduledTime,
    int? durationMinutes,
    int? participantsCount,
    String? location,
    double? fee,
    bool? isPaid,
    bool? creditTowardBooking,
    ServiceAppointmentStatus? status,
    Map<String, dynamic>? categorySpecificDetails,
    String? customerNotes,
    String? outcomeNotes,
    String? outcomeStatus,
    String? generatedQuoteId,
    String? linkedChildBookingId,
    String? packageId,
    String? packageComponentName,
  }) {
    return ServiceAppointmentBooking(
      id: id ?? this.id,
      appointmentTypeId: appointmentTypeId ?? this.appointmentTypeId,
      appointmentTypeName: appointmentTypeName ?? this.appointmentTypeName,
      purpose: purpose ?? this.purpose,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      participantsCount: participantsCount ?? this.participantsCount,
      location: location ?? this.location,
      fee: fee ?? this.fee,
      isPaid: isPaid ?? this.isPaid,
      creditTowardBooking: creditTowardBooking ?? this.creditTowardBooking,
      status: status ?? this.status,
      categorySpecificDetails: categorySpecificDetails ?? this.categorySpecificDetails,
      customerNotes: customerNotes ?? this.customerNotes,
      outcomeNotes: outcomeNotes ?? this.outcomeNotes,
      outcomeStatus: outcomeStatus ?? this.outcomeStatus,
      generatedQuoteId: generatedQuoteId ?? this.generatedQuoteId,
      linkedChildBookingId: linkedChildBookingId ?? this.linkedChildBookingId,
      packageId: packageId ?? this.packageId,
      packageComponentName: packageComponentName ?? this.packageComponentName,
    );
  }
}

/// Component selection rule inside a collaborative package
enum ComponentSelectionRule {
  exactlyOne,
  upToX,
  multipleRequired,
  optional;

  String get displayName {
    switch (this) {
      case ComponentSelectionRule.exactlyOne:
        return 'Choose Exactly 1';
      case ComponentSelectionRule.upToX:
        return 'Choose Up to Limit';
      case ComponentSelectionRule.multipleRequired:
        return 'Multiple Required';
      case ComponentSelectionRule.optional:
        return 'Optional Add-on';
    }
  }
}

/// Appointment requirement rule for package components
enum ComponentAppointmentRule {
  noAppointment,
  optionalAppointment,
  recommendedAppointment,
  requiredBeforeBooking,
  requiredAfterBooking;

  String get displayName {
    switch (this) {
      case ComponentAppointmentRule.noAppointment:
        return 'No Appointment Needed';
      case ComponentAppointmentRule.optionalAppointment:
        return 'Optional Appointment';
      case ComponentAppointmentRule.recommendedAppointment:
        return 'Recommended Appointment';
      case ComponentAppointmentRule.requiredBeforeBooking:
        return 'Required Before Booking';
      case ComponentAppointmentRule.requiredAfterBooking:
        return 'Required After Booking';
    }
  }

  Color get badgeColor {
    switch (this) {
      case ComponentAppointmentRule.noAppointment:
        return const Color(0xFF9CA3AF);
      case ComponentAppointmentRule.optionalAppointment:
        return const Color(0xFF6B7280);
      case ComponentAppointmentRule.recommendedAppointment:
        return const Color(0xFFF59E0B);
      case ComponentAppointmentRule.requiredBeforeBooking:
        return const Color(0xFFEF4444);
      case ComponentAppointmentRule.requiredAfterBooking:
        return const Color(0xFF3B82F6);
    }
  }
}

/// Approved collaborator contributing to a package component
class CollaboratorOption {
  final String vendorId;
  final String vendorName;
  final String vendorAvatar;
  final double rating;
  final int reviewsCount;
  final String serviceId;
  final String serviceName;
  final double partnerPrice;
  final double priceDelta; // Difference from package allowance e.g. +200 or -50
  final List<ServiceAppointmentType> appointmentOptions;
  final bool isApproved;
  final bool isAvailable;

  CollaboratorOption({
    required this.vendorId,
    required this.vendorName,
    this.vendorAvatar = '',
    this.rating = 4.9,
    this.reviewsCount = 42,
    required this.serviceId,
    required this.serviceName,
    required this.partnerPrice,
    this.priceDelta = 0.0,
    this.appointmentOptions = const [],
    this.isApproved = true,
    this.isAvailable = true,
  });

  CollaboratorOption copyWith({
    String? vendorId,
    String? vendorName,
    String? vendorAvatar,
    double? rating,
    int? reviewsCount,
    String? serviceId,
    String? serviceName,
    double? partnerPrice,
    double? priceDelta,
    List<ServiceAppointmentType>? appointmentOptions,
    bool? isApproved,
    bool? isAvailable,
  }) {
    return CollaboratorOption(
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorAvatar: vendorAvatar ?? this.vendorAvatar,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      partnerPrice: partnerPrice ?? this.partnerPrice,
      priceDelta: priceDelta ?? this.priceDelta,
      appointmentOptions: appointmentOptions ?? this.appointmentOptions,
      isApproved: isApproved ?? this.isApproved,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}

/// Package Component: Fixed Vendor, Customer Choice, Optional, Quantity-Based
class PackageComponent {
  final String id;
  final String componentName; // e.g. "Venue", "Catering", "Bridal Makeup", "Photography"
  final ServiceCategoryType category;
  final String description;
  final bool isFixedVendor; // True = Fixed vendor, False = Customer Choice
  final ComponentSelectionRule selectionRule;
  final ComponentAppointmentRule appointmentRule;
  final double packageAllowance; // Budget portion in package for this component
  final bool isRequired;
  final int maxQuantity;
  final List<CollaboratorOption> approvedCollaborators;
  final String? selectedCollaboratorId;
  final String terms;

  PackageComponent({
    required this.id,
    required this.componentName,
    required this.category,
    required this.description,
    this.isFixedVendor = false,
    this.selectionRule = ComponentSelectionRule.exactlyOne,
    this.appointmentRule = ComponentAppointmentRule.optionalAppointment,
    required this.packageAllowance,
    this.isRequired = true,
    this.maxQuantity = 1,
    this.approvedCollaborators = const [],
    this.selectedCollaboratorId,
    this.terms = '',
  });

  bool get isReady {
    if (isFixedVendor) {
      return approvedCollaborators.isNotEmpty;
    }
    return approvedCollaborators.isNotEmpty;
  }

  CollaboratorOption? get selectedCollaborator {
    if (approvedCollaborators.isEmpty) return null;
    if (selectedCollaboratorId != null) {
      return approvedCollaborators.firstWhere(
        (c) => c.vendorId == selectedCollaboratorId,
        orElse: () => approvedCollaborators.first,
      );
    }
    return approvedCollaborators.first;
  }

  PackageComponent copyWith({
    String? id,
    String? componentName,
    ServiceCategoryType? category,
    String? description,
    bool? isFixedVendor,
    ComponentSelectionRule? selectionRule,
    ComponentAppointmentRule? appointmentRule,
    double? packageAllowance,
    bool? isRequired,
    int? maxQuantity,
    List<CollaboratorOption>? approvedCollaborators,
    String? selectedCollaboratorId,
    String? terms,
  }) {
    return PackageComponent(
      id: id ?? this.id,
      componentName: componentName ?? this.componentName,
      category: category ?? this.category,
      description: description ?? this.description,
      isFixedVendor: isFixedVendor ?? this.isFixedVendor,
      selectionRule: selectionRule ?? this.selectionRule,
      appointmentRule: appointmentRule ?? this.appointmentRule,
      packageAllowance: packageAllowance ?? this.packageAllowance,
      isRequired: isRequired ?? this.isRequired,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      approvedCollaborators: approvedCollaborators ?? this.approvedCollaborators,
      selectedCollaboratorId: selectedCollaboratorId ?? this.selectedCollaboratorId,
      terms: terms ?? this.terms,
    );
  }
}

/// Collaborative Package structure
class CollaborativePackage {
  final String id;
  final String ownerVendorId;
  final String ownerVendorName;
  final String title; // e.g. "Premium Wedding Package"
  final String description;
  final List<String> eventTypes;
  final double basePrice;
  final List<PackageComponent> components;
  final String bannerImageUrl;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  CollaborativePackage({
    required this.id,
    required this.ownerVendorId,
    required this.ownerVendorName,
    required this.title,
    required this.description,
    this.eventTypes = const ['Wedding'],
    required this.basePrice,
    this.components = const [],
    this.bannerImageUrl = '',
    this.isPublished = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get readyComponentsCount => components.where((c) => c.isReady).length;
  int get totalComponentsCount => components.length;

  CollaborativePackage copyWith({
    String? id,
    String? ownerVendorId,
    String? ownerVendorName,
    String? title,
    String? description,
    List<String>? eventTypes,
    double? basePrice,
    List<PackageComponent>? components,
    String? bannerImageUrl,
    bool? isPublished,
  }) {
    return CollaborativePackage(
      id: id ?? this.id,
      ownerVendorId: ownerVendorId ?? this.ownerVendorId,
      ownerVendorName: ownerVendorName ?? this.ownerVendorName,
      title: title ?? this.title,
      description: description ?? this.description,
      eventTypes: eventTypes ?? this.eventTypes,
      basePrice: basePrice ?? this.basePrice,
      components: components ?? this.components,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Collaborator Invitation Status
enum CollaborationStatus {
  invitationSent,
  pending,
  accepted,
  offerSubmitted,
  approved,
  available,
  selected,
  booked,
  declined,
  removed;

  String get displayName {
    switch (this) {
      case CollaborationStatus.invitationSent:
        return 'Invitation Sent';
      case CollaborationStatus.pending:
        return 'Pending';
      case CollaborationStatus.accepted:
        return 'Accepted';
      case CollaborationStatus.offerSubmitted:
        return 'Offer Submitted';
      case CollaborationStatus.approved:
        return 'Approved';
      case CollaborationStatus.available:
        return 'Available in Package';
      case CollaborationStatus.selected:
        return 'Selected by Customer';
      case CollaborationStatus.booked:
        return 'Booked';
      case CollaborationStatus.declined:
        return 'Declined';
      case CollaborationStatus.removed:
        return 'Removed';
    }
  }

  Color get color {
    switch (this) {
      case CollaborationStatus.invitationSent:
      case CollaborationStatus.pending:
        return const Color(0xFFF59E0B);
      case CollaborationStatus.accepted:
      case CollaborationStatus.offerSubmitted:
        return const Color(0xFF3B82F6);
      case CollaborationStatus.approved:
      case CollaborationStatus.available:
        return const Color(0xFF10B981);
      case CollaborationStatus.selected:
      case CollaborationStatus.booked:
        return const Color(0xFF8B5CF6);
      case CollaborationStatus.declined:
      case CollaborationStatus.removed:
        return const Color(0xFFEF4444);
    }
  }
}

/// Invitation sent to collaborate on a package
class CollaboratorInvitation {
  final String id;
  final String packageId;
  final String packageName;
  final String ownerVendorId;
  final String ownerVendorName;
  final String targetVendorId;
  final String targetVendorName;
  final ServiceCategoryType roleCategory;
  final String roleComponentName;
  final String eventDate;
  final String location;
  final double packageAllowance;
  final List<String> requestedAppointmentTypes; // e.g. ['Makeup Trial', 'Consultation']
  final CollaborationStatus status;
  final double? partnerPriceOffered;
  final double? partnerDiscount;
  final String? offeredServiceId;
  final String? offeredServiceName;
  final List<ServiceAppointmentType> offeredAppointments;
  final DateTime createdAt;

  CollaboratorInvitation({
    required this.id,
    required this.packageId,
    required this.packageName,
    required this.ownerVendorId,
    required this.ownerVendorName,
    required this.targetVendorId,
    required this.targetVendorName,
    required this.roleCategory,
    required this.roleComponentName,
    required this.eventDate,
    required this.location,
    required this.packageAllowance,
    this.requestedAppointmentTypes = const [],
    this.status = CollaborationStatus.pending,
    this.partnerPriceOffered,
    this.partnerDiscount,
    this.offeredServiceId,
    this.offeredServiceName,
    this.offeredAppointments = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  CollaboratorInvitation copyWith({
    String? id,
    String? packageId,
    String? packageName,
    String? ownerVendorId,
    String? ownerVendorName,
    String? targetVendorId,
    String? targetVendorName,
    ServiceCategoryType? roleCategory,
    String? roleComponentName,
    String? eventDate,
    String? location,
    double? packageAllowance,
    List<String>? requestedAppointmentTypes,
    CollaborationStatus? status,
    double? partnerPriceOffered,
    double? partnerDiscount,
    String? offeredServiceId,
    String? offeredServiceName,
    List<ServiceAppointmentType>? offeredAppointments,
  }) {
    return CollaboratorInvitation(
      id: id ?? this.id,
      packageId: packageId ?? this.packageId,
      packageName: packageName ?? this.packageName,
      ownerVendorId: ownerVendorId ?? this.ownerVendorId,
      ownerVendorName: ownerVendorName ?? this.ownerVendorName,
      targetVendorId: targetVendorId ?? this.targetVendorId,
      targetVendorName: targetVendorName ?? this.targetVendorName,
      roleCategory: roleCategory ?? this.roleCategory,
      roleComponentName: roleComponentName ?? this.roleComponentName,
      eventDate: eventDate ?? this.eventDate,
      location: location ?? this.location,
      packageAllowance: packageAllowance ?? this.packageAllowance,
      requestedAppointmentTypes: requestedAppointmentTypes ?? this.requestedAppointmentTypes,
      status: status ?? this.status,
      partnerPriceOffered: partnerPriceOffered ?? this.partnerPriceOffered,
      partnerDiscount: partnerDiscount ?? this.partnerDiscount,
      offeredServiceId: offeredServiceId ?? this.offeredServiceId,
      offeredServiceName: offeredServiceName ?? this.offeredServiceName,
      offeredAppointments: offeredAppointments ?? this.offeredAppointments,
      createdAt: createdAt,
    );
  }
}

/// Parent Package Booking & Child Vendor Bookings
class ParentPackageBooking {
  final String bookingCode; // e.g. "PKG-1024"
  final String packageId;
  final String packageName;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String? eventId;
  final String? eventName;
  final DateTime eventDate;
  final double basePackagePrice;
  final double totalCalculatedPrice;
  final List<ChildPackageBooking> childBookings;
  final List<String> linkedAppointmentIds;
  final String status; // 'confirmed', 'in_progress', 'completed'
  final DateTime createdAt;

  ParentPackageBooking({
    required this.bookingCode,
    required this.packageId,
    required this.packageName,
    required this.customerId,
    required this.customerName,
    this.customerEmail = '',
    this.eventId,
    this.eventName,
    required this.eventDate,
    required this.basePackagePrice,
    required this.totalCalculatedPrice,
    this.childBookings = const [],
    this.linkedAppointmentIds = const [],
    this.status = 'confirmed',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class ChildPackageBooking {
  final String childBookingId;
  final String parentBookingCode;
  final String componentName;
  final ServiceCategoryType category;
  final String vendorId;
  final String vendorName;
  final String serviceId;
  final String serviceName;
  final double agreedPrice;
  final double priceDelta;
  final List<String> linkedAppointmentIds;
  final String status;

  ChildPackageBooking({
    required this.childBookingId,
    required this.parentBookingCode,
    required this.componentName,
    required this.category,
    required this.vendorId,
    required this.vendorName,
    required this.serviceId,
    required this.serviceName,
    required this.agreedPrice,
    this.priceDelta = 0.0,
    this.linkedAppointmentIds = const [],
    this.status = 'confirmed',
  });
}

/// Unified Vendor Calendar Entry
enum VendorCalendarItemType {
  booking,
  appointment,
  blockedTime,
  travelTime,
  setupTime;

  String get displayName {
    switch (this) {
      case VendorCalendarItemType.booking:
        return 'Booking';
      case VendorCalendarItemType.appointment:
        return 'Appointment';
      case VendorCalendarItemType.blockedTime:
        return 'Blocked Time';
      case VendorCalendarItemType.travelTime:
        return 'Travel Time';
      case VendorCalendarItemType.setupTime:
        return 'Setup Time';
    }
  }

  Color get color {
    switch (this) {
      case VendorCalendarItemType.booking:
        return const Color(0xFF10B981); // Emerald Green
      case VendorCalendarItemType.appointment:
        return const Color(0xFF6366F1); // Indigo
      case VendorCalendarItemType.blockedTime:
        return const Color(0xFFEF4444); // Red
      case VendorCalendarItemType.travelTime:
        return const Color(0xFF0EA5E9); // Sky
      case VendorCalendarItemType.setupTime:
        return const Color(0xFFF59E0B); // Amber
    }
  }
}

class VendorCalendarItem {
  final String id;
  final String title;
  final VendorCalendarItemType type;
  final DateTime date;
  final String startTime; // '14:00'
  final String endTime; // '15:30'
  final String location;
  final String? clientName;
  final String? serviceOrEventName;
  final String? relatedId; // appointmentId or bookingId
  final String notes;

  VendorCalendarItem({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.location = '',
    this.clientName,
    this.serviceOrEventName,
    this.relatedId,
    this.notes = '',
  });
}
