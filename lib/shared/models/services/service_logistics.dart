import 'package:equatable/equatable.dart';

enum VehicleType { van, lorry, truck, trailer, car, bike }

extension VehicleTypeExtension on VehicleType {
  String get name => toString().split('.').last;
  String get displayName {
    switch (this) {
      case VehicleType.van: return 'Van';
      case VehicleType.lorry: return 'Lorry';
      case VehicleType.truck: return 'Truck';
      case VehicleType.trailer: return 'Trailer';
      case VehicleType.car: return 'Standard Car';
      case VehicleType.bike: return 'Motorcycle';
    }
  }
}

/// Logistics specific to Products and Rentals (Delivery, Pickup, Security)
class ProductLogistics extends Equatable {
  final bool hasDelivery;
  final bool hasSelfPickup;
  final String deliveryFeeType; // 'free', 'fixed', 'per_km'
  final double deliveryFee;
  final double freeDeliveryThreshold;
  final int estimatedDays; // Production or shipping lead time
  final String? pickupAddress;
  final String? pickupHours;

  // Rental Specific
  final double? rentalDeposit;
  final bool hasDamageWaiver;
  final double? damageWaiverPct;
  final String? returnCondition;

  const ProductLogistics({
    this.hasDelivery = true,
    this.hasSelfPickup = false,
    this.deliveryFeeType = 'fixed',
    this.deliveryFee = 0.0,
    this.freeDeliveryThreshold = 0.0,
    this.estimatedDays = 3,
    this.pickupAddress,
    this.pickupHours,
    this.rentalDeposit,
    this.hasDamageWaiver = false,
    this.damageWaiverPct,
    this.returnCondition,
  });

  factory ProductLogistics.fromJson(Map<String, dynamic> json) {
    return ProductLogistics(
      hasDelivery: json['has_delivery'] ?? true,
      hasSelfPickup: json['has_self_pickup'] ?? false,
      deliveryFeeType: json['delivery_fee_type'] ?? 'fixed',
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      freeDeliveryThreshold: (json['free_delivery_threshold'] as num?)?.toDouble() ?? 0.0,
      estimatedDays: (json['estimated_days'] as num?)?.toInt() ?? 3,
      pickupAddress: json['pickup_address'],
      pickupHours: json['pickup_hours'],
      rentalDeposit: (json['rental_deposit'] as num?)?.toDouble(),
      hasDamageWaiver: json['has_damage_waiver'] ?? false,
      damageWaiverPct: (json['damage_waiver_pct'] as num?)?.toDouble(),
      returnCondition: json['return_condition'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_delivery': hasDelivery,
      'has_self_pickup': hasSelfPickup,
      'delivery_fee_type': deliveryFeeType,
      'delivery_fee': deliveryFee,
      'free_delivery_threshold': freeDeliveryThreshold,
      'estimated_days': estimatedDays,
      if (pickupAddress != null) 'pickup_address': pickupAddress,
      if (pickupHours != null) 'pickup_hours': pickupHours,
      if (rentalDeposit != null) 'rental_deposit': rentalDeposit,
      'has_damage_waiver': hasDamageWaiver,
      if (damageWaiverPct != null) 'damage_waiver_pct': damageWaiverPct,
      if (returnCondition != null) 'return_condition': returnCondition,
    };
  }

  @override
  List<Object?> get props => [
        hasDelivery,
        hasSelfPickup,
        deliveryFeeType,
        deliveryFee,
        freeDeliveryThreshold,
        estimatedDays,
        pickupAddress,
        pickupHours,
        rentalDeposit,
        hasDamageWaiver,
        damageWaiverPct,
        returnCondition,
      ];
}

class ServiceLogistics extends Equatable {
  final String? id;
  final String serviceId;
  
  // Requirements
  final bool requiresVehicle;
  final VehicleType? vehicleType;
  final int defaultCrewCount;
  
  // Timeline (Hours)
  final double defaultSetupTime;
  final double defaultTeardownTime;
  
  // Geometry & Coverage
  final double freeRadiusKm;
  final double perKmRate;
  final String? primaryState;
  
  // Financial Policies
  final bool parkingRequired;
  final bool powerRequired;
  final bool overnightRequired;
  final double nightSurcharge;
  final String? tollParkingPolicy; // e.g. "Vendor Claims", "Customer Provides"
  final double minOrderForFreeDelivery;

  const ServiceLogistics({
    this.id,
    required this.serviceId,
    this.requiresVehicle = false,
    this.vehicleType,
    this.defaultCrewCount = 1,
    this.defaultSetupTime = 1.0,
    this.defaultTeardownTime = 1.0,
    this.freeRadiusKm = 20.0,
    this.perKmRate = 0.0,
    this.primaryState,
    this.parkingRequired = false,
    this.powerRequired = false,
    this.overnightRequired = false,
    this.nightSurcharge = 0.0,
    this.tollParkingPolicy,
    this.minOrderForFreeDelivery = 0.0,
  });

  factory ServiceLogistics.fromJson(Map<String, dynamic> json) {
    return ServiceLogistics(
      id: json['id']?.toString(),
      serviceId: json['service_id']?.toString() ?? '',
      requiresVehicle: json['requires_vehicle'] ?? false,
      vehicleType: json['vehicle_type'] != null 
          ? VehicleType.values.firstWhere(
              (e) => e.name == json['vehicle_type']?.toString(),
              orElse: () => VehicleType.van,
            )
          : null,
      defaultCrewCount: (json['crew_count'] as num?)?.toInt() ?? 1,
      defaultSetupTime: (json['setup_time_hours'] as num?)?.toDouble() ?? 1.0,
      defaultTeardownTime: (json['teardown_time_hours'] as num?)?.toDouble() ?? 1.0,
      freeRadiusKm: (json['free_radius_km'] as num?)?.toDouble() ?? 20.0,
      perKmRate: (json['per_km_rate'] as num?)?.toDouble() ?? 0.0,
      primaryState: json['primary_state']?.toString(),
      parkingRequired: json['parking_required'] ?? false,
      powerRequired: json['power_required'] ?? false,
      overnightRequired: json['overnight_required'] ?? false,
      nightSurcharge: (json['night_surcharge'] as num?)?.toDouble() ?? 0.0,
      tollParkingPolicy: json['toll_parking_policy']?.toString(),
      minOrderForFreeDelivery: (json['min_order_for_free_delivery'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'service_id': serviceId,
      'requires_vehicle': requiresVehicle,
      'vehicle_type': vehicleType?.name,
      'crew_count': defaultCrewCount,
      'setup_time_hours': defaultSetupTime,
      'teardown_time_hours': defaultTeardownTime,
      'free_radius_km': freeRadiusKm,
      'per_km_rate': perKmRate,
      'primary_state': primaryState,
      'parking_required': parkingRequired,
      'power_required': powerRequired,
      'overnight_required': overnightRequired,
      'night_surcharge': nightSurcharge,
      'toll_parking_policy': tollParkingPolicy,
      'min_order_for_free_delivery': minOrderForFreeDelivery,
    };
  }

  @override
  List<Object?> get props => [
        id, serviceId, requiresVehicle, vehicleType, 
        defaultCrewCount, defaultSetupTime, defaultTeardownTime,
        freeRadiusKm, perKmRate, primaryState, parkingRequired,
        powerRequired, overnightRequired, nightSurcharge, tollParkingPolicy,
        minOrderForFreeDelivery
      ];
}

class BookingLogistics extends Equatable {
  final String? eventLocation;
  final bool locationTbc;
  final double distanceKm;
  final double travelFee;
  final int crewCount;
  final double setupTime;
  final double teardownTime;
  final String? arrivalTime;
  final String? loadingPoint;
  final bool parkingProvided;
  final bool powerProvided;

  const BookingLogistics({
    this.eventLocation,
    this.locationTbc = false,
    this.distanceKm = 0.0,
    this.travelFee = 0.0,
    this.crewCount = 1,
    this.setupTime = 1.0,
    this.teardownTime = 1.0,
    this.arrivalTime,
    this.loadingPoint,
    this.parkingProvided = false,
    this.powerProvided = false,
  });

  factory BookingLogistics.fromJson(Map<String, dynamic> json) {
    return BookingLogistics(
      eventLocation: json['event_location']?.toString(),
      locationTbc: json['location_tbc'] ?? false,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      travelFee: (json['travel_fee'] as num?)?.toDouble() ?? 0.0,
      crewCount: (json['crew_count'] as num?)?.toInt() ?? 1,
      setupTime: (json['setup_time_hours'] as num?)?.toDouble() ?? 1.0,
      teardownTime: (json['teardown_time_hours'] as num?)?.toDouble() ?? 1.0,
      arrivalTime: json['arrival_time']?.toString(),
      loadingPoint: json['loading_point']?.toString(),
      parkingProvided: json['parking_provided'] ?? false,
      powerProvided: json['power_provided'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_location': eventLocation,
      'location_tbc': locationTbc,
      'distance_km': distanceKm,
      'travel_fee': travelFee,
      'crew_count': crewCount,
      'setup_time_hours': setupTime,
      'teardown_time_hours': teardownTime,
      'arrival_time': arrivalTime,
      'loading_point': loadingPoint,
      'parking_provided': parkingProvided,
      'power_provided': powerProvided,
    };
  }

  @override
  List<Object?> get props => [
        eventLocation, locationTbc, distanceKm, travelFee,
        crewCount, setupTime, teardownTime, arrivalTime,
        loadingPoint, parkingProvided, powerProvided
      ];
}
