import 'package:equatable/equatable.dart';
import 'services/service_time_rule.dart';
import 'services/service_logistics.dart';

enum ServiceStatus { active, inactive, suspended }
enum ServiceType { basic, premium, custom }

class VendorService extends Equatable {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final String category;
  final double basePrice;
  final String? priceType; // 'fixed', 'hourly', 'per_person', etc.
  final int? durationHours;
  final int? maxGuests;
  final List<String> features;
  final List<String> images;
  final ServiceStatus status;
  final ServiceType serviceType;
  final bool isFeatured;
  final int? minAdvanceBookingDays;
  final Map<String, dynamic> pricingTiers;
  final Map<String, dynamic> availability;
  final String? venueAddress;
  final String? coverageArea;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ServiceTimeRule? timeRule;
  final ServiceLogistics? logisticsConfig;

  const VendorService({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.category,
    required this.basePrice,
    this.priceType,
    this.durationHours,
    this.maxGuests,
    required this.features,
    required this.images,
    this.status = ServiceStatus.active,
    this.serviceType = ServiceType.basic,
    this.isFeatured = false,
    this.minAdvanceBookingDays,
    required this.pricingTiers,
    required this.availability,
    this.venueAddress,
    this.coverageArea,
    required this.createdAt,
    required this.updatedAt,
    this.timeRule,
    this.logisticsConfig,
  });

  factory VendorService.fromJson(Map<String, dynamic> json) {
    return VendorService(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      basePrice: (json['base_price'] ?? 0).toDouble(),
      priceType: json['price_type'] as String?,
      durationHours: json['duration_hours'] as int?,
      maxGuests: json['max_guests'] as int?,
      features: (json['features'] is List) ? List<String>.from(json['features']) : [],
      images: (json['images'] is List) ? List<String>.from(json['images']) : [],
      status: ServiceStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ServiceStatus.active,
      ),
      serviceType: ServiceType.values.firstWhere(
        (type) => type.name == json['service_type'],
        orElse: () => ServiceType.basic,
      ),
      isFeatured: json['is_featured'] ?? false,
      minAdvanceBookingDays: json['min_advance_booking_days'] as int?,
      pricingTiers: (json['pricing_tiers'] is Map) ? Map<String, dynamic>.from(json['pricing_tiers']) : {},
      availability: (json['availability'] is Map) ? Map<String, dynamic>.from(json['availability']) : {},
      venueAddress: json['venue_address'] as String?,
      coverageArea: json['coverage_area'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : DateTime.now(),
      timeRule: json['time_rule'] != null ? ServiceTimeRule.fromJson(json['time_rule'] as Map<String, dynamic>) : null,
      logisticsConfig: json['logistics_config'] != null ? ServiceLogistics.fromJson(json['logistics_config'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'name': name,
      'description': description,
      'category': category,
      'base_price': basePrice,
      'price_type': priceType,
      'duration_hours': durationHours,
      'max_guests': maxGuests,
      'features': features,
      'images': images,
      'status': status.name,
      'service_type': serviceType.name,
      'is_featured': isFeatured,
      'min_advance_booking_days': minAdvanceBookingDays,
      'pricing_tiers': pricingTiers,
      'availability': availability,
      'venue_address': venueAddress,
      'coverage_area': coverageArea,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'time_rule': timeRule?.toJson(),
      'logistics_config': logisticsConfig?.toJson(),
    };
  }

  VendorService copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    String? category,
    double? basePrice,
    String? priceType,
    int? durationHours,
    int? maxGuests,
    List<String>? features,
    List<String>? images,
    ServiceStatus? status,
    ServiceType? serviceType,
    bool? isFeatured,
    int? minAdvanceBookingDays,
    Map<String, dynamic>? pricingTiers,
    Map<String, dynamic>? availability,
    String? venueAddress,
    String? coverageArea,
    DateTime? createdAt,
    DateTime? updatedAt,
    ServiceTimeRule? timeRule,
    ServiceLogistics? logisticsConfig,
  }) {
    return VendorService(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      priceType: priceType ?? this.priceType,
      durationHours: durationHours ?? this.durationHours,
      maxGuests: maxGuests ?? this.maxGuests,
      features: features ?? this.features,
      images: images ?? this.images,
      status: status ?? this.status,
      serviceType: serviceType ?? this.serviceType,
      isFeatured: isFeatured ?? this.isFeatured,
      minAdvanceBookingDays: minAdvanceBookingDays ?? this.minAdvanceBookingDays,
      pricingTiers: pricingTiers ?? this.pricingTiers,
      availability: availability ?? this.availability,
      venueAddress: venueAddress ?? this.venueAddress,
      coverageArea: coverageArea ?? this.coverageArea,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timeRule: timeRule ?? this.timeRule,
      logisticsConfig: logisticsConfig ?? this.logisticsConfig,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        name,
        description,
        category,
        basePrice,
        priceType,
        durationHours,
        maxGuests,
        features,
        images,
        status,
        serviceType,
        isFeatured,
        minAdvanceBookingDays,
        pricingTiers,
        availability,
        venueAddress,
        coverageArea,
        createdAt,
        updatedAt,
        timeRule,
        logisticsConfig,
      ];
}
