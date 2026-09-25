enum PartnershipStatus {
  active,
  inactive,
  terminated,
  pending,
}

enum PartnershipType {
  jointPackage, // Joint package creation
  referral, // Lead sharing
  crossPromotion, // Cross-promotion
  resourceSharing, // Resource sharing
}

class VendorPartnership {
  final String id;
  final String partnershipName;
  final List<String> vendorIds; // IDs of participating vendors
  final List<String> vendorNames; // Names of participating vendors
  final PartnershipType type;
  final PartnershipStatus status;
  final String description;
  final Map<String, dynamic> terms; // Partnership terms and conditions
  final Map<String, double> revenueShares; // Revenue sharing percentages by vendor ID
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final List<String> packageIds; // IDs of joint packages created
  final Map<String, dynamic> metadata; // Additional partnership data

  const VendorPartnership({
    required this.id,
    required this.partnershipName,
    required this.vendorIds,
    required this.vendorNames,
    required this.type,
    this.status = PartnershipStatus.pending,
    required this.description,
    required this.terms,
    required this.revenueShares,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.packageIds = const [],
    this.metadata = const {},
  });

  // Copy with method
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
    DateTime? endedAt,
    List<String>? packageIds,
    Map<String, dynamic>? metadata,
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
      endedAt: endedAt ?? this.endedAt,
      packageIds: packageIds ?? this.packageIds,
      metadata: metadata ?? this.metadata,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnershipName': partnershipName,
      'vendorIds': vendorIds,
      'vendorNames': vendorNames,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'description': description,
      'terms': terms,
      'revenueShares': revenueShares,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'packageIds': packageIds,
      'metadata': metadata,
    };
  }

  factory VendorPartnership.fromJson(Map<String, dynamic> json) {
    return VendorPartnership(
      id: json['id'],
      partnershipName: json['partnershipName'],
      vendorIds: List<String>.from(json['vendorIds']),
      vendorNames: List<String>.from(json['vendorNames']),
      type: PartnershipType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      status: PartnershipStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      description: json['description'],
      terms: Map<String, dynamic>.from(json['terms']),
      revenueShares: Map<String, double>.from(json['revenueShares']),
      createdAt: DateTime.parse(json['createdAt']),
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      packageIds: List<String>.from(json['packageIds'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  // Helper methods
  bool get isActive => status == PartnershipStatus.active;
  bool get isPending => status == PartnershipStatus.pending;
  bool get isTerminated => status == PartnershipStatus.terminated;

  String get typeDisplayName {
    switch (type) {
      case PartnershipType.jointPackage:
        return 'Joint Package';
      case PartnershipType.referral:
        return 'Referral Partnership';
      case PartnershipType.crossPromotion:
        return 'Cross-Promotion';
      case PartnershipType.resourceSharing:
        return 'Resource Sharing';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case PartnershipStatus.active:
        return 'Active';
      case PartnershipStatus.inactive:
        return 'Inactive';
      case PartnershipStatus.terminated:
        return 'Terminated';
      case PartnershipStatus.pending:
        return 'Pending';
    }
  }

  // Check if a vendor is part of this partnership
  bool includesVendor(String vendorId) {
    return vendorIds.contains(vendorId);
  }

  // Get revenue share for a specific vendor
  double getRevenueShare(String vendorId) {
    return revenueShares[vendorId] ?? 0.0;
  }

  // Calculate total revenue share (should be 100%)
  double get totalRevenueShare {
    return revenueShares.values.fold(0.0, (sum, share) => sum + share);
  }

  // Check if revenue shares are valid (total 100%)
  bool get hasValidRevenueShares {
    const double tolerance = 0.01;
    return (totalRevenueShare - 100.0).abs() < tolerance;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VendorPartnership &&
        other.id == id &&
        other.partnershipName == partnershipName &&
        other.vendorIds == vendorIds &&
        other.vendorNames == vendorNames &&
        other.type == type &&
        other.status == status &&
        other.description == description &&
        other.terms == terms &&
        other.revenueShares == revenueShares &&
        other.createdAt == createdAt &&
        other.startedAt == startedAt &&
        other.endedAt == endedAt &&
        other.packageIds == packageIds &&
        other.metadata == metadata;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        partnershipName.hashCode ^
        vendorIds.hashCode ^
        vendorNames.hashCode ^
        type.hashCode ^
        status.hashCode ^
        description.hashCode ^
        terms.hashCode ^
        revenueShares.hashCode ^
        createdAt.hashCode ^
        startedAt.hashCode ^
        endedAt.hashCode ^
        packageIds.hashCode ^
        metadata.hashCode;
  }
}
