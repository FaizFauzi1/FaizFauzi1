enum CampaignStatus {
  active,
  paused,
  completed,
  draft,
  cancelled,
}

class MarketingCampaign {
  final String id;
  final String name;
  final String description;
  final CampaignStatus status;
  final double budget;
  final double spent;
  final Map<String, dynamic> metrics;
  final List<String> channels;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MarketingCampaign({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.budget,
    required this.spent,
    required this.metrics,
    required this.channels,
    required this.createdAt,
    this.updatedAt,
  });

  String get statusDisplayName {
    switch (status) {
      case CampaignStatus.active:
        return 'Active';
      case CampaignStatus.paused:
        return 'Paused';
      case CampaignStatus.completed:
        return 'Completed';
      case CampaignStatus.draft:
        return 'Draft';
      case CampaignStatus.cancelled:
        return 'Cancelled';
    }
  }

  double get budgetUtilization => budget > 0 ? (spent / budget) * 100 : 0.0;

  bool get isOverBudget => spent > budget;

  // Sample data for testing
  static List<MarketingCampaign> getSampleCampaigns() {
    return [
      MarketingCampaign(
        id: 'camp_1',
        name: 'Summer Wedding Promotion',
        description: 'Promote wedding packages for summer season',
        status: CampaignStatus.active,
        budget: 5000.0,
        spent: 3200.0,
        metrics: {'leads': 45, 'conversions': 12},
        channels: ['Facebook', 'Instagram', 'Email'],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      MarketingCampaign(
        id: 'camp_2',
        name: 'Corporate Event Special',
        description: 'Target corporate clients for event services',
        status: CampaignStatus.active,
        budget: 3000.0,
        spent: 1800.0,
        metrics: {'leads': 28, 'conversions': 8},
        channels: ['LinkedIn', 'Email'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      MarketingCampaign(
        id: 'camp_3',
        name: 'Holiday Package Launch',
        description: 'Launch new holiday event packages',
        status: CampaignStatus.paused,
        budget: 2500.0,
        spent: 1200.0,
        metrics: {'leads': 15, 'conversions': 3},
        channels: ['Facebook', 'Google Ads'],
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];
  }
}