import 'package:equatable/equatable.dart';

enum BoostType { searchPriority, featuredBadge, topListing }

class BoostedListing extends Equatable {
  final String id;
  final String vendorId;
  final String? campaignId;
  final BoostType boostType;
  final int boostDurationHours;
  final DateTime boostStart;
  final DateTime boostEnd;
  final bool isActive;
  final List<String> searchKeywords;
  final DateTime createdAt;

  const BoostedListing({
    required this.id,
    required this.vendorId,
    this.campaignId,
    required this.boostType,
    required this.boostDurationHours,
    required this.boostStart,
    required this.boostEnd,
    this.isActive = true,
    this.searchKeywords = const [],
    required this.createdAt,
  });

  factory BoostedListing.fromJson(Map<String, dynamic> json) {
    return BoostedListing(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      campaignId: json['campaign_id'] as String?,
      boostType: BoostType.values.firstWhere(
        (type) => type.name == json['boost_type'],
        orElse: () => BoostType.searchPriority,
      ),
      boostDurationHours: json['boost_duration_hours'] as int,
      boostStart: DateTime.parse(json['boost_start']),
      boostEnd: DateTime.parse(json['boost_end']),
      isActive: json['is_active'] ?? true,
      searchKeywords: List<String>.from(json['search_keywords'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'campaign_id': campaignId,
      'boost_type': boostType.name,
      'boost_duration_hours': boostDurationHours,
      'boost_start': boostStart.toIso8601String(),
      'boost_end': boostEnd.toIso8601String(),
      'is_active': isActive,
      'search_keywords': searchKeywords,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BoostedListing copyWith({
    String? id,
    String? vendorId,
    String? campaignId,
    BoostType? boostType,
    int? boostDurationHours,
    DateTime? boostStart,
    DateTime? boostEnd,
    bool? isActive,
    List<String>? searchKeywords,
    DateTime? createdAt,
  }) {
    return BoostedListing(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      campaignId: campaignId ?? this.campaignId,
      boostType: boostType ?? this.boostType,
      boostDurationHours: boostDurationHours ?? this.boostDurationHours,
      boostStart: boostStart ?? this.boostStart,
      boostEnd: boostEnd ?? this.boostEnd,
      isActive: isActive ?? this.isActive,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        campaignId,
        boostType,
        boostDurationHours,
        boostStart,
        boostEnd,
        isActive,
        searchKeywords,
        createdAt,
      ];
}
