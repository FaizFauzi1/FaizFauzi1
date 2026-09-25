import 'package:flutter/material.dart';
import '../../models/marketing_campaign.dart';

class MarketingInsight {
  final String type;
  final String title;
  final String description;
  final String recommendation;
  final double impact;

  MarketingInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.impact,
  });
}

class MarketingProvider extends ChangeNotifier {
  final List<MarketingCampaign> _campaigns = [];
  final List<MarketingInsight> _insights = [];

  MarketingProvider() {
    _initializeData();
  }

  List<MarketingCampaign> get campaigns => List.unmodifiable(_campaigns);

  List<MarketingInsight> get insights => List.unmodifiable(_insights);

  void _initializeData() {
    // Campaigns will be loaded from Supabase; no mockup data here.
    _generateInsights();
  }

  void _generateInsights() {
    _insights.clear();

    // Calculate some basic metrics
    final activeCampaigns = _campaigns.where((c) => c.status == CampaignStatus.active).length;
    final totalBudget = _campaigns.fold<double>(0, (sum, c) => sum + c.budget);
    final totalSpent = _campaigns.fold<double>(0, (sum, c) => sum + c.spent);
    final totalLeads = _campaigns.fold<int>(0, (sum, c) => sum + (c.metrics['leads'] as int? ?? 0));
    final totalConversions = _campaigns.fold<int>(0, (sum, c) => sum + (c.metrics['conversions'] as int? ?? 0));

    final conversionRate = totalLeads > 0 ? (totalConversions / totalLeads) * 100 : 0.0;
    final budgetUtilization = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;

    // Generate insights based on data
    if (activeCampaigns == 0) {
      _insights.add(MarketingInsight(
        type: 'warning',
        title: 'No Active Campaigns',
        description: 'You currently have no active marketing campaigns.',
        recommendation: 'Create and launch new campaigns to reach potential customers.',
        impact: 80.0,
      ));
    }

    if (conversionRate < 10.0) {
      _insights.add(MarketingInsight(
        type: 'opportunity',
        title: 'Low Conversion Rate',
        description: 'Your current conversion rate is ${conversionRate.toStringAsFixed(1)}%, which is below optimal.',
        recommendation: 'Review campaign targeting and messaging to improve conversion rates.',
        impact: 60.0,
      ));
    }

    if (budgetUtilization > 90.0) {
      _insights.add(MarketingInsight(
        type: 'warning',
        title: 'High Budget Utilization',
        description: 'You\'ve used ${budgetUtilization.toStringAsFixed(1)}% of your total marketing budget.',
        recommendation: 'Monitor spending closely and consider budget adjustments.',
        impact: 70.0,
      ));
    }

    if (totalLeads > 50) {
      _insights.add(MarketingInsight(
        type: 'success',
        title: 'Strong Lead Generation',
        description: 'Your campaigns have generated $totalLeads leads this period.',
        recommendation: 'Continue current strategies and consider scaling successful campaigns.',
        impact: 40.0,
      ));
    }

    // Add some default insights if none were generated
    if (_insights.isEmpty) {
      _insights.addAll([
        MarketingInsight(
          type: 'opportunity',
          title: 'Optimize Channel Performance',
          description: 'Analyze which marketing channels are performing best.',
          recommendation: 'Focus budget on high-performing channels like Facebook and Instagram.',
          impact: 50.0,
        ),
        MarketingInsight(
          type: 'success',
          title: 'Campaign Performance',
          description: 'Your marketing campaigns are showing positive results.',
          recommendation: 'Maintain current strategies and monitor for further improvements.',
          impact: 30.0,
        ),
      ]);
    }
  }

  Map<String, dynamic> getMarketingAnalytics(String vendorId) {
    final vendorCampaigns = _campaigns; // In a real app, filter by vendorId

    final totalCampaigns = vendorCampaigns.length;
    final activeCampaigns = vendorCampaigns.where((c) => c.status == CampaignStatus.active).length;
    final totalBudget = vendorCampaigns.fold<double>(0, (sum, c) => sum + c.budget);
    final totalSpent = vendorCampaigns.fold<double>(0, (sum, c) => sum + c.spent);
    final totalLeads = vendorCampaigns.fold<int>(0, (sum, c) => sum + (c.metrics['leads'] as int? ?? 0));
    final totalConversions = vendorCampaigns.fold<int>(0, (sum, c) => sum + (c.metrics['conversions'] as int? ?? 0));

    final conversionRate = totalLeads > 0 ? (totalConversions / totalLeads) * 100 : 0.0;
    final budgetUtilization = totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0.0;

    // Channel performance (mock data)
    final channelPerformance = {
      'Facebook': 2500.0,
      'Instagram': 1800.0,
      'Google Ads': 1200.0,
      'Email': 800.0,
      'LinkedIn': 600.0,
    };

    return {
      'overview': {
        'totalCampaigns': totalCampaigns,
        'activeCampaigns': activeCampaigns,
        'totalBudget': totalBudget,
        'totalSpent': totalSpent,
        'budgetUtilization': budgetUtilization,
        'totalLeads': totalLeads,
        'conversionRate': conversionRate,
      },
      'channelPerformance': channelPerformance,
    };
  }

  // Campaign management methods
  void addCampaign(MarketingCampaign campaign) {
    _campaigns.add(campaign);
    _generateInsights();
    notifyListeners();
  }

  void updateCampaign(String campaignId, MarketingCampaign updatedCampaign) {
    final index = _campaigns.indexWhere((c) => c.id == campaignId);
    if (index != -1) {
      _campaigns[index] = updatedCampaign;
      _generateInsights();
      notifyListeners();
    }
  }

  void removeCampaign(String campaignId) {
    _campaigns.removeWhere((c) => c.id == campaignId);
    _generateInsights();
    notifyListeners();
  }

  void pauseCampaign(String campaignId) {
    final index = _campaigns.indexWhere((c) => c.id == campaignId);
    if (index != -1) {
      final campaign = _campaigns[index];
      _campaigns[index] = MarketingCampaign(
        id: campaign.id,
        name: campaign.name,
        description: campaign.description,
        status: CampaignStatus.paused,
        budget: campaign.budget,
        spent: campaign.spent,
        metrics: campaign.metrics,
        channels: campaign.channels,
        createdAt: campaign.createdAt,
        updatedAt: DateTime.now(),
      );
      _generateInsights();
      notifyListeners();
    }
  }

  void resumeCampaign(String campaignId) {
    final index = _campaigns.indexWhere((c) => c.id == campaignId);
    if (index != -1) {
      final campaign = _campaigns[index];
      _campaigns[index] = MarketingCampaign(
        id: campaign.id,
        name: campaign.name,
        description: campaign.description,
        status: CampaignStatus.active,
        budget: campaign.budget,
        spent: campaign.spent,
        metrics: campaign.metrics,
        channels: campaign.channels,
        createdAt: campaign.createdAt,
        updatedAt: DateTime.now(),
      );
      _generateInsights();
      notifyListeners();
    }
  }
}