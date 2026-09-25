import 'package:equatable/equatable.dart';

enum CampaignStatus { draft, active, paused, completed, cancelled }

enum CampaignType { banner, sponsored, featured, promoted }

class AdsCampaigns extends Equatable {
  final String id;
  final String vendorId;
  final String name;
  final String? description;
  final CampaignType campaignType;
  final CampaignStatus status;
  final double budget;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final int? targetImpressions;
  final int? targetClicks;
  final Map<String, dynamic>? targetingOptions;
  final double spentAmount;
  final int impressions;
  final int clicks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdsCampaigns({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    required this.campaignType,
    this.status = CampaignStatus.draft,
    required this.budget,
    this.currency = 'USD',
    required this.startDate,
    required this.endDate,
    this.targetImpressions,
    this.targetClicks,
    this.targetingOptions,
    this.spentAmount = 0.0,
    this.impressions = 0,
    this.clicks = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdsCampaigns.fromJson(Map<String, dynamic> json) {
    return AdsCampaigns(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      campaignType: CampaignType.values.firstWhere(
        (type) => type.name == json['campaign_type'],
        orElse: () => CampaignType.banner,
      ),
      status: CampaignStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => CampaignStatus.draft,
      ),
      budget: (json['budget'] as num).toDouble(),
      currency: json['currency'] ?? 'USD',
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      targetImpressions: json['target_impressions'] as int?,
      targetClicks: json['target_clicks'] as int?,
      targetingOptions: json['targeting_options'] as Map<String, dynamic>?,
      spentAmount: (json['spent_amount'] as num?)?.toDouble() ?? 0.0,
      impressions: json['impressions'] ?? 0,
      clicks: json['clicks'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'name': name,
      'description': description,
      'campaign_type': campaignType.name,
      'status': status.name,
      'budget': budget,
      'currency': currency,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'target_impressions': targetImpressions,
      'target_clicks': targetClicks,
      'targeting_options': targetingOptions,
      'spent_amount': spentAmount,
      'impressions': impressions,
      'clicks': clicks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AdsCampaigns copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    CampaignType? campaignType,
    CampaignStatus? status,
    double? budget,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
    int? targetImpressions,
    int? targetClicks,
    Map<String, dynamic>? targetingOptions,
    double? spentAmount,
    int? impressions,
    int? clicks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdsCampaigns(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      campaignType: campaignType ?? this.campaignType,
      status: status ?? this.status,
      budget: budget ?? this.budget,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetImpressions: targetImpressions ?? this.targetImpressions,
      targetClicks: targetClicks ?? this.targetClicks,
      targetingOptions: targetingOptions ?? this.targetingOptions,
      spentAmount: spentAmount ?? this.spentAmount,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        name,
        description,
        campaignType,
        status,
        budget,
        currency,
        startDate,
        endDate,
        targetImpressions,
        targetClicks,
        targetingOptions,
        spentAmount,
        impressions,
        clicks,
        createdAt,
        updatedAt,
      ];
}
