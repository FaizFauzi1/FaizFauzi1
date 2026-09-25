import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/marketing_campaign.dart';

class MarketingProvider with ChangeNotifier {
  final List<MarketingCampaign> _campaigns = [];
  final List<MarketingAnalytics> _analytics = [];
  final List<CampaignInsight> _insights = [];

  UnmodifiableListView<MarketingCampaign> get campaigns => UnmodifiableListView(_campaigns);
  UnmodifiableListView<MarketingAnalytics> get analytics => UnmodifiableListView(_analytics);
  UnmodifiableListView<CampaignInsight> get insights => UnmodifiableListView(_insights);

  MarketingProvider() {
    _initializeSampleData();
  }

  void _initializeSampleData() {
    // Initialize with sample campaigns
    _campaigns.addAll([
      MarketingCampaign(
        id: 'camp_1',
        vendorId: 'vendor_1',
        name: 'Summer Wedding Season Promotion',
        description: 'Promote wedding photography and catering services for summer season',
        type: CampaignType.socialMedia,
        objective: CampaignObjective.leadGeneration,
        status: CampaignStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 45)),
        budget: 3000.0,
        spent: 1200.0,
        targetAudience: {
          'ageRange': '25-45',
          'interests': ['weddings', 'photography', 'catering'],
          'location': 'Local area',
          'incomeLevel': 'Middle to High',
        },
        channels: ['Facebook', 'Instagram', 'Google Ads'],
        content: {
          'platforms': ['Facebook', 'Instagram'],
          'adCopy': 'Book your dream wedding package today!',
          'images': ['wedding_photo_1.jpg', 'wedding_photo_2.jpg'],
          'hashtags': ['#WeddingPhotography', '#WeddingCatering', '#DreamWedding'],
        },
        metrics: {
          'impressions': 45000.0,
          'clicks': 1200.0,
          'leads': 45.0,
          'conversions': 12.0,
          'costPerClick': 1.0,
          'costPerLead': 26.67,
          'conversionRate': 3.0,
        },
        milestones: [
          CampaignMilestone(
            id: 'milestone_1',
            campaignId: 'camp_1',
            title: 'Reach 10,000 impressions',
            description: 'Achieve 10,000 impressions across all platforms',
            dueDate: DateTime.now().add(const Duration(days: 10)),
            isCompleted: true,
            completedAt: DateTime.now().subtract(const Duration(days: 5)),
            metadata: {'actualImpressions': 12000},
          ),
          CampaignMilestone(
            id: 'milestone_2',
            campaignId: 'camp_1',
            title: 'Generate 30 leads',
            description: 'Generate at least 30 qualified leads',
            dueDate: DateTime.now().add(const Duration(days: 30)),
            isCompleted: true,
            completedAt: DateTime.now().subtract(const Duration(days: 2)),
            metadata: {'actualLeads': 45},
          ),
          CampaignMilestone(
            id: 'milestone_3',
            campaignId: 'camp_1',
            title: 'Achieve 5% conversion rate',
            description: 'Convert 5% of leads into actual bookings',
            dueDate: DateTime.now().add(const Duration(days: 45)),
            isCompleted: false,
            metadata: {'currentRate': 3.0},
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      MarketingCampaign(
        id: 'camp_2',
        vendorId: 'vendor_1',
        name: 'Corporate Event Email Campaign',
        description: 'Targeted email campaign for corporate event planning',
        type: CampaignType.email,
        objective: CampaignObjective.leadGeneration,
        status: CampaignStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 20)),
        budget: 1500.0,
        spent: 800.0,
        targetAudience: {
          'companySize': '50-500 employees',
          'industry': 'Technology, Finance, Healthcare',
          'jobTitles': ['Event Planner', 'HR Manager', 'Office Manager'],
          'location': 'Business districts',
        },
        channels: ['Email Marketing'],
        content: {
          'subjectLines': ['Plan Your Next Corporate Event with Us', 'Professional Event Services for Your Company'],
          'templates': ['corporate_template_1', 'corporate_template_2'],
          'personalization': true,
        },
        metrics: {
          'emailsSent': 2500.0,
          'openRate': 28.5,
          'clickRate': 12.3,
          'leads': 18.0,
          'conversions': 3.0,
          'costPerLead': 44.44,
        },
        milestones: [
          CampaignMilestone(
            id: 'milestone_4',
            campaignId: 'camp_2',
            title: 'Achieve 25% open rate',
            description: 'Get at least 25% of emails opened',
            dueDate: DateTime.now().add(const Duration(days: 5)),
            isCompleted: true,
            completedAt: DateTime.now().subtract(const Duration(days: 1)),
            metadata: {'actualOpenRate': 28.5},
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      MarketingCampaign(
        id: 'camp_3',
        vendorId: 'vendor_1',
        name: 'Holiday Season Content Marketing',
        description: 'Create and distribute holiday-themed content to drive engagement',
        type: CampaignType.content,
        objective: CampaignObjective.brandAwareness,
        status: CampaignStatus.draft,
        startDate: DateTime.now().add(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 90)),
        budget: 2000.0,
        spent: 0.0,
        targetAudience: {
          'interests': ['holidays', 'family events', 'celebrations'],
          'ageRange': '25-55',
          'contentPreferences': ['blogs', 'videos', 'infographics'],
        },
        channels: ['Blog', 'YouTube', 'Instagram'],
        content: {
          'contentTypes': ['blog posts', 'videos', 'infographics'],
          'themes': ['Holiday Event Planning', 'Seasonal Decorations', 'Family Celebrations'],
          'postingSchedule': '3 times per week',
        },
        metrics: {},
        milestones: [],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ]);

    // Initialize insights
    _insights.addAll([
      CampaignInsight(
        insightId: 'insight_1',
        title: 'High Performing Social Media Campaign',
        description: 'Your Summer Wedding campaign is performing 40% above average with excellent engagement rates.',
        type: 'success',
        impact: 85.0,
        recommendation: 'Consider increasing budget allocation to this campaign and replicating the strategy for other services.',
        generatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      CampaignInsight(
        insightId: 'insight_2',
        title: 'Email Campaign Optimization Needed',
        description: 'Email open rates are below industry average. Subject lines may need improvement.',
        type: 'warning',
        impact: 65.0,
        recommendation: 'A/B test different subject lines and consider personalizing email content based on recipient interests.',
        generatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      CampaignInsight(
        insightId: 'insight_3',
        title: 'Budget Underutilization',
        description: 'Content marketing campaign budget is unused. Consider launching earlier to maximize ROI.',
        type: 'opportunity',
        impact: 70.0,
        recommendation: 'Start the content marketing campaign earlier to take advantage of the full budget and improve brand awareness before peak season.',
        generatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ]);
  }

  // Campaign Management
  void addCampaign(MarketingCampaign campaign) {
    _campaigns.add(campaign);
    notifyListeners();
  }

  void updateCampaign(String campaignId, MarketingCampaign updatedCampaign) {
    final index = _campaigns.indexWhere((c) => c.id == campaignId);
    if (index != -1) {
      _campaigns[index] = updatedCampaign;
      notifyListeners();
    }
  }

  void deleteCampaign(String campaignId) {
    _campaigns.removeWhere((c) => c.id == campaignId);
    notifyListeners();
  }

  MarketingCampaign? getCampaignById(String campaignId) {
    try {
      return _campaigns.firstWhere((c) => c.id == campaignId);
    } catch (e) {
      return null;
    }
  }

  List<MarketingCampaign> getActiveCampaigns() {
    return _campaigns.where((c) => c.isActive).toList();
  }

  List<MarketingCampaign> getCampaignsByType(CampaignType type) {
    return _campaigns.where((c) => c.type == type).toList();
  }

  List<MarketingCampaign> getCampaignsByStatus(CampaignStatus status) {
    return _campaigns.where((c) => c.status == status).toList();
  }

  // Analytics Management
  void addAnalytics(MarketingAnalytics analytics) {
    _analytics.add(analytics);
    notifyListeners();
  }

  MarketingAnalytics? getLatestAnalytics(String vendorId) {
    try {
      return _analytics
          .where((a) => a.vendorId == vendorId)
          .reduce((a, b) => a.periodEnd.isAfter(b.periodEnd) ? a : b);
    } catch (e) {
      return null;
    }
  }

  // ROI Calculation
  MarketingROI calculateCampaignROI(String campaignId) {
    final campaign = getCampaignById(campaignId);
    if (campaign == null) {
      throw Exception('Campaign not found');
    }

    // In a real app, this would calculate actual ROI based on conversions and revenue
    final totalRevenue = campaign.metrics['conversions']! * 500; // Assuming average booking value
    final totalCost = campaign.spent;
    final grossProfit = totalRevenue - totalCost;
    final roiPercentage = totalCost > 0 ? (grossProfit / totalCost) * 100 : 0.0;
    final costPerAcquisition = campaign.metrics['leads']! > 0 ? totalCost / campaign.metrics['leads']! : 0.0;
    final customerLifetimeValue = 2500.0; // Estimated LTV

    return MarketingROI(
      campaignId: campaignId,
      totalRevenue: totalRevenue,
      totalCost: totalCost,
      grossProfit: grossProfit,
      roiPercentage: roiPercentage,
      costPerAcquisition: costPerAcquisition,
      customerLifetimeValue: customerLifetimeValue,
      channelROI: {
        'Facebook': roiPercentage * 1.2,
        'Instagram': roiPercentage * 1.1,
        'Google Ads': roiPercentage * 0.9,
      },
      calculatedAt: DateTime.now(),
    );
  }

  // Performance Analytics
  Map<String, dynamic> getMarketingAnalytics(String vendorId) {
    final activeCampaigns = getActiveCampaigns();
    final totalBudget = activeCampaigns.fold<double>(0, (sum, c) => sum + c.budget);
    final totalSpent = activeCampaigns.fold<double>(0, (sum, c) => sum + c.spent);
    final totalLeads = activeCampaigns.fold<double>(0, (sum, c) => sum + (c.metrics['leads'] ?? 0));
    final totalConversions = activeCampaigns.fold<double>(0, (sum, c) => sum + (c.metrics['conversions'] ?? 0));

    final channelPerformance = <String, double>{};
    for (final campaign in activeCampaigns) {
      for (final channel in campaign.channels) {
        channelPerformance[channel] = (channelPerformance[channel] ?? 0) + campaign.spent;
      }
    }

    final audienceReach = <String, int>{};
    for (final campaign in activeCampaigns) {
      final impressions = campaign.metrics['impressions'] ?? 0;
      for (final channel in campaign.channels) {
        audienceReach[channel] = (audienceReach[channel] ?? 0) + (impressions ~/ 10).toInt(); // Rough estimate
      }
    }

    return {
      'overview': {
        'totalCampaigns': _campaigns.length,
        'activeCampaigns': activeCampaigns.length,
        'totalBudget': totalBudget,
        'totalSpent': totalSpent,
        'budgetUtilization': totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0,
        'totalLeads': totalLeads,
        'totalConversions': totalConversions,
        'conversionRate': totalLeads > 0 ? (totalConversions / totalLeads) * 100 : 0.0,
      },
      'channelPerformance': channelPerformance,
      'audienceReach': audienceReach,
      'campaignInsights': _insights.map((i) => i.toJson()).toList(),
    };
  }

  // Campaign Optimization
  List<CampaignInsight> generateInsights() {
    final insights = <CampaignInsight>[];

    for (final campaign in _campaigns) {
      // Check budget utilization
      if (campaign.budgetUtilization < 50 && campaign.isActive) {
        insights.add(CampaignInsight(
          insightId: 'budget_low_${campaign.id}',
          title: 'Low Budget Utilization',
          description: '${campaign.name} has only used ${campaign.budgetUtilization.toStringAsFixed(1)}% of its budget.',
          type: 'warning',
          impact: 60.0,
          recommendation: 'Consider increasing campaign activity or reallocating budget to other campaigns.',
          generatedAt: DateTime.now(),
        ));
      }

      // Check over-budget campaigns
      if (campaign.isOverBudget) {
        insights.add(CampaignInsight(
          insightId: 'over_budget_${campaign.id}',
          title: 'Campaign Over Budget',
          description: '${campaign.name} has exceeded its budget by ${(campaign.spent - campaign.budget).toStringAsFixed(2)}.',
          type: 'warning',
          impact: 80.0,
          recommendation: 'Review campaign performance and consider pausing or adjusting the campaign.',
          generatedAt: DateTime.now(),
        ));
      }

      // Check high-performing campaigns
      if (campaign.metrics['conversionRate'] != null &&
          campaign.metrics['conversionRate']! > 5.0) {
        insights.add(CampaignInsight(
          insightId: 'high_performing_${campaign.id}',
          title: 'High Performing Campaign',
          description: '${campaign.name} has achieved a ${campaign.metrics['conversionRate']?.toStringAsFixed(1)}% conversion rate.',
          type: 'success',
          impact: 90.0,
          recommendation: 'Consider increasing budget for this campaign and replicating the strategy.',
          generatedAt: DateTime.now(),
        ));
      }
    }

    return insights;
  }

  // Bulk Operations
  void bulkUpdateCampaigns(List<String> campaignIds, Map<String, dynamic> updates) {
    for (final id in campaignIds) {
      final campaign = _campaigns.firstWhere(
        (c) => c.id == id,
        orElse: () => throw Exception('Campaign not found'),
      );

      final updatedCampaign = MarketingCampaign(
        id: campaign.id,
        vendorId: campaign.vendorId,
        name: updates['name'] ?? campaign.name,
        description: updates['description'] ?? campaign.description,
        type: updates['type'] ?? campaign.type,
        objective: updates['objective'] ?? campaign.objective,
        status: updates['status'] ?? campaign.status,
        startDate: updates['startDate'] ?? campaign.startDate,
        endDate: updates['endDate'] ?? campaign.endDate,
        budget: updates['budget'] ?? campaign.budget,
        spent: updates['spent'] ?? campaign.spent,
        targetAudience: updates['targetAudience'] ?? campaign.targetAudience,
        channels: updates['channels'] ?? campaign.channels,
        content: updates['content'] ?? campaign.content,
        metrics: updates['metrics'] ?? campaign.metrics,
        milestones: updates['milestones'] ?? campaign.milestones,
        assignedTo: updates['assignedTo'] ?? campaign.assignedTo,
        createdAt: campaign.createdAt,
        updatedAt: DateTime.now(),
      );

      updateCampaign(id, updatedCampaign);
    }
  }

  void bulkDeleteCampaigns(List<String> campaignIds) {
    for (final id in campaignIds) {
      deleteCampaign(id);
    }
  }

  // Utility Methods
  double getTotalMarketingSpend(String vendorId, {DateTime? startDate, DateTime? endDate}) {
    final campaigns = _campaigns.where((c) => c.vendorId == vendorId);
    double total = 0.0;

    for (final campaign in campaigns) {
      if (startDate != null && endDate != null) {
        if (campaign.startDate.isAfter(startDate) && campaign.startDate.isBefore(endDate)) {
          total += campaign.spent;
        }
      } else {
        total += campaign.spent;
      }
    }

    return total;
  }

  int getTotalLeadsGenerated(String vendorId) {
    final campaigns = _campaigns.where((c) => c.vendorId == vendorId);
    return campaigns.fold<int>(0, (sum, c) => sum + (c.metrics['leads']?.toInt() ?? 0));
  }

  double getAverageConversionRate(String vendorId) {
    final campaigns = _campaigns.where((c) => c.vendorId == vendorId && c.metrics['leads']! > 0);
    if (campaigns.isEmpty) return 0.0;

    final totalRate = campaigns.fold<double>(
      0,
      (sum, c) => sum + (c.metrics['conversionRate'] ?? 0),
    );

    return totalRate / campaigns.length;
  }
}
