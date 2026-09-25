import 'package:equatable/equatable.dart';

enum PartnershipType {
  jointPackage,
  referral,
  resourceSharing,
  marketingAlliance,
}

enum PartnershipStatus {
  pending,
  active,
  paused,
  terminated,
  completed,
}

class VendorPartnership extends Equatable {
  final String id;
  final String partnershipName;
  final List<String> vendorIds;
  final List<String> vendorNames;
  final PartnershipType type;
  final PartnershipStatus status;
  final String description;
  final Map<String, dynamic> terms;
  final Map<String, double> revenueShares;
  final DateTime createdAt;
  final DateTime? startedAt;
  final List<String> packageIds;

  const VendorPartnership({
    required this.id,
    required this.partnershipName,
    required this.vendorIds,
    required this.vendorNames,
    required this.type,
    required this.status,
    required this.description,
    required this.terms,
    required this.revenueShares,
    required this.createdAt,
    this.startedAt,
    required this.packageIds,
  });

  bool get isActive => status == PartnershipStatus.active;

  VendorPartnership copyWith({
    String? id,
    String? partnershipName,
    List<String>? vendorIds,
    List<String>? vendorNames,
    PartnershipType? type,
    PartnershipStatus? status,
    String? description,
    Map<String, dynamic>? terms,
    Map<String, double>? revenueShares,
    DateTime? createdAt,
    DateTime? startedAt,
    List<String>? packageIds,
  }) {
    return VendorPartnership(
      id: id ?? this.id,
      partnershipName: partnershipName ?? this.partnershipName,
      vendorIds: vendorIds ?? this.vendorIds,
      vendorNames: vendorNames ?? this.vendorNames,
      type: type ?? this.type,
      status: status ?? this.status,
      description: description ?? this.description,
      terms: terms ?? this.terms,
      revenueShares: revenueShares ?? this.revenueShares,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      packageIds: packageIds ?? this.packageIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        partnershipName,
        vendorIds,
        vendorNames,
        type,
        status,
        description,
        terms,
        revenueShares,
        createdAt,
        startedAt,
        packageIds,
      ];
}
