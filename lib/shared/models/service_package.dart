import 'package:equatable/equatable.dart';
import 'services/service_package_item.dart';

enum PackageStatus { active, inactive, draft }

class ServicePackage extends Equatable {
  final String id;
  final String vendorId;
  final List<String> serviceIds;
  final String name;
  final String description;
  final double price;
  final int durationHours;
  final List<String> inclusions;
  final List<String> exclusions;
  final PackageStatus status;
  final int maxGuests;
  final Map<String, dynamic> customizations;
  final List<ServicePackageItem> items; // Added
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServicePackage({
    required this.id,
    required this.vendorId,
    required this.serviceIds,
    required this.name,
    required this.description,
    required this.price,
    required this.durationHours,
    required this.inclusions,
    required this.exclusions,
    this.status = PackageStatus.active,
    required this.maxGuests,
    required this.customizations,
    this.items = const [], // Added
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServicePackage.fromJson(Map<String, dynamic> json) {
    return ServicePackage(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      serviceIds: List<String>.from(json['service_ids'] ?? []),
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] ?? 0).toDouble(),
      durationHours: json['duration_hours'] ?? 0,
      inclusions: List<String>.from(json['inclusions'] ?? []),
      exclusions: List<String>.from(json['exclusions'] ?? []),
      status: PackageStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => PackageStatus.active,
      ),
      maxGuests: json['max_guests'] ?? 0,
      customizations: Map<String, dynamic>.from(json['customizations'] ?? {}),
      items: (json['items'] as List?)
          ?.map((e) => ServicePackageItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [], // Added
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'service_ids': serviceIds,
      'name': name,
      'description': description,
      'price': price,
      'duration_hours': durationHours,
      'inclusions': inclusions,
      'exclusions': exclusions,
      'status': status.name,
      'max_guests': maxGuests,
      'customizations': customizations,
      'items': items.map((e) => e.toJson()).toList(), // Added
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ServicePackage copyWith({
    String? id,
    String? vendorId,
    List<String>? serviceIds,
    String? name,
    String? description,
    double? price,
    int? durationHours,
    List<String>? inclusions,
    List<String>? exclusions,
    PackageStatus? status,
    int? maxGuests,
    Map<String, dynamic>? customizations,
    List<ServicePackageItem>? items, // Added
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServicePackage(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      serviceIds: serviceIds ?? this.serviceIds,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationHours: durationHours ?? this.durationHours,
      inclusions: inclusions ?? this.inclusions,
      exclusions: exclusions ?? this.exclusions,
      status: status ?? this.status,
      maxGuests: maxGuests ?? this.maxGuests,
      customizations: customizations ?? this.customizations,
      items: items ?? this.items, // Added
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        serviceIds,
        name,
        description,
        price,
        durationHours,
        inclusions,
        exclusions,
        status,
        maxGuests,
        customizations,
        items, // Added
        createdAt,
        updatedAt,
      ];
}

