enum CampaignStatus { draft, active, paused, completed, cancelled }
enum CampaignType { socialMedia, email, paidAds, content, event, referral }
enum CampaignObjective { brandAwareness, leadGeneration, sales, engagement, retention }

class MarketingCampaign {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final CampaignType type;
  final CampaignObjective objective;
  final CampaignStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final double budget;
  final double spent;
  final Map<String, dynamic> targetAudience;
  final List<String> channels;
  final Map<String, dynamic> content;
  final Map<String, double> metrics;
  final List<CampaignMilestone> milestones;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketingCampaign({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.type,
    required this.objective,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.budget,
    required this.spent,
    required this.targetAudience,
    required this.channels,
    required this.content,
    required this.metrics,
    required this.milestones,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'name': name,
      'description': description,
      'type': type.toString(),
      'objective': objective.toString(),
      'status': status.toString(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'budget': budget,
      'spent': spent,
      'targetAudience': targetAudience,
      'channels': channels,
      'content': content,
      'metrics': metrics,
      'milestones': milestones.map((m) => m.toJson()).toList(),
      'assignedTo': assignedTo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MarketingCampaign.fromJson(Map<String, dynamic> json) {
    return MarketingCampaign(
      id: json['id'],
      vendorId: json['vendorId'],
      name: json['name'],
      description: json['description'],
      type: CampaignType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      objective: CampaignObjective.values.firstWhere(
        (e) => e.toString() == json['objective'],
      ),
      status: CampaignStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      budget: json['budget']?.toDouble() ?? 0.0,
      spent: json['spent']?.toDouble() ?? 0.0,
      targetAudience: json['targetAudience'] ?? {},
      channels: List<String>.from(json['channels'] ?? []),
      content: json['content'] ?? {},
      metrics: Map<String, double>.from(json['metrics'] ?? {}),
      milestones: (json['milestones'] as List?)?.map((m) => CampaignMilestone.fromJson(m)).toList() ?? [],
      assignedTo: json['assignedTo'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  double get remainingBudget => budget - spent;
  double get budgetUtilization => budget > 0 ? (spent / budget) * 100 : 0.0;
  bool get isOverBudget => spent > budget;
  bool get isActive => status == CampaignStatus.active;
  bool get isCompleted => status == CampaignStatus.completed;

  String get statusDisplayName {
    switch (status) {
      case CampaignStatus.draft:
        return 'Draft';
      case CampaignStatus.active:
        return 'Active';
      case CampaignStatus.paused:
        return 'Paused';
      case CampaignStatus.completed:
        return 'Completed';
      case CampaignStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case CampaignType.socialMedia:
        return 'Social Media';
      case CampaignType.email:
        return 'Email Marketing';
      case CampaignType.paidAds:
        return 'Paid Advertising';
      case CampaignType.content:
        return 'Content Marketing';
      case CampaignType.event:
        return 'Event Marketing';
      case CampaignType.referral:
        return 'Referral Program';
      default:
        return 'Unknown';
    }
  }

  String get objectiveDisplayName {
    switch (objective) {
      case CampaignObjective.brandAwareness:
        return 'Brand Awareness';
      case CampaignObjective.leadGeneration:
        return 'Lead Generation';
      case CampaignObjective.sales:
        return 'Sales';
      case CampaignObjective.engagement:
        return 'Engagement';
      case CampaignObjective.retention:
        return 'Customer Retention';
      default:
        return 'Unknown';
    }
  }
}

class CampaignMilestone {
  final String id;
  final String campaignId;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedBy;
  final Map<String, dynamic> metadata;

  CampaignMilestone({
    required this.id,
    required this.campaignId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.isCompleted,
    this.completedAt,
    this.completedBy,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaignId': campaignId,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'completedBy': completedBy,
      'metadata': metadata,
    };
  }

  factory CampaignMilestone.fromJson(Map<String, dynamic> json) {
    return CampaignMilestone(
      id: json['id'],
      campaignId: json['campaignId'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      completedBy: json['completedBy'],
      metadata: json['metadata'] ?? {},
    );
  }

  bool get isOverdue => !isCompleted && DateTime.now().isAfter(dueDate);
}

class MarketingROI {
  final String campaignId;
  final double totalRevenue;
  final double totalCost;
  final double grossProfit;
  final double roiPercentage;
  final double costPerAcquisition;
  final double customerLifetimeValue;
  final Map<String, double> channelROI;
  final DateTime calculatedAt;

  MarketingROI({
    required this.campaignId,
    required this.totalRevenue,
    required this.totalCost,
    required this.grossProfit,
    required this.roiPercentage,
    required this.costPerAcquisition,
    required this.customerLifetimeValue,
    required this.channelROI,
    required this.calculatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'campaignId': campaignId,
      'totalRevenue': totalRevenue,
      'totalCost': totalCost,
      'grossProfit': grossProfit,
      'roiPercentage': roiPercentage,
      'costPerAcquisition': costPerAcquisition,
      'customerLifetimeValue': customerLifetimeValue,
      'channelROI': channelROI,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  factory MarketingROI.fromJson(Map<String, dynamic> json) {
    return MarketingROI(
      campaignId: json['campaignId'],
      totalRevenue: json['totalRevenue']?.toDouble() ?? 0.0,
      totalCost: json['totalCost']?.toDouble() ?? 0.0,
      grossProfit: json['grossProfit']?.toDouble() ?? 0.0,
      roiPercentage: json['roiPercentage']?.toDouble() ?? 0.0,
      costPerAcquisition: json['costPerAcquisition']?.toDouble() ?? 0.0,
      customerLifetimeValue: json['customerLifetimeValue']?.toDouble() ?? 0.0,
      channelROI: Map<String, double>.from(json['channelROI'] ?? {}),
      calculatedAt: DateTime.parse(json['calculatedAt']),
    );
  }

  bool get isProfitable => roiPercentage > 0;
  String get roiStatus {
    if (roiPercentage > 100) return 'Excellent';
    if (roiPercentage > 50) return 'Good';
    if (roiPercentage > 0) return 'Break-even';
    return 'Loss';
  }
}

class MarketingAnalytics {
  final String vendorId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalBudget;
  final double totalSpent;
  final double totalRevenue;
  final double overallROI;
  final Map<String, double> channelPerformance;
  final Map<String, int> audienceReach;
  final List<ConversionFunnel> conversionFunnels;
  final List<CampaignInsight> insights;

  MarketingAnalytics({
    required this.vendorId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalBudget,
    required this.totalSpent,
    required this.totalRevenue,
    required this.overallROI,
    required this.channelPerformance,
    required this.audienceReach,
    required this.conversionFunnels,
    required this.insights,
  });

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'totalRevenue': totalRevenue,
      'overallROI': overallROI,
      'channelPerformance': channelPerformance,
      'audienceReach': audienceReach,
      'conversionFunnels': conversionFunnels.map((f) => f.toJson()).toList(),
      'insights': insights.map((i) => i.toJson()).toList(),
    };
  }

  factory MarketingAnalytics.fromJson(Map<String, dynamic> json) {
    return MarketingAnalytics(
      vendorId: json['vendorId'],
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
      totalBudget: json['totalBudget']?.toDouble() ?? 0.0,
      totalSpent: json['totalSpent']?.toDouble() ?? 0.0,
      totalRevenue: json['totalRevenue']?.toDouble() ?? 0.0,
      overallROI: json['overallROI']?.toDouble() ?? 0.0,
      channelPerformance: Map<String, double>.from(json['channelPerformance'] ?? {}),
      audienceReach: Map<String, int>.from(json['audienceReach'] ?? {}),
      conversionFunnels: (json['conversionFunnels'] as List?)?.map((f) => ConversionFunnel.fromJson(f)).toList() ?? [],
      insights: (json['insights'] as List?)?.map((i) => CampaignInsight.fromJson(i)).toList() ?? [],
    );
  }
}

class ConversionFunnel {
  final String funnelId;
  final String funnelName;
  final int impressions;
  final int clicks;
  final int leads;
  final int conversions;
  final double conversionRate;
  final double costPerClick;
  final double costPerLead;
  final double costPerConversion;

  ConversionFunnel({
    required this.funnelId,
    required this.funnelName,
    required this.impressions,
    required this.clicks,
    required this.leads,
    required this.conversions,
    required this.conversionRate,
    required this.costPerClick,
    required this.costPerLead,
    required this.costPerConversion,
  });

  Map<String, dynamic> toJson() {
    return {
      'funnelId': funnelId,
      'funnelName': funnelName,
      'impressions': impressions,
      'clicks': clicks,
      'leads': leads,
      'conversions': conversions,
      'conversionRate': conversionRate,
      'costPerClick': costPerClick,
      'costPerLead': costPerLead,
      'costPerConversion': costPerConversion,
    };
  }

  factory ConversionFunnel.fromJson(Map<String, dynamic> json) {
    return ConversionFunnel(
      funnelId: json['funnelId'],
      funnelName: json['funnelName'],
      impressions: json['impressions'] ?? 0,
      clicks: json['clicks'] ?? 0,
      leads: json['leads'] ?? 0,
      conversions: json['conversions'] ?? 0,
      conversionRate: json['conversionRate']?.toDouble() ?? 0.0,
      costPerClick: json['costPerClick']?.toDouble() ?? 0.0,
      costPerLead: json['costPerLead']?.toDouble() ?? 0.0,
      costPerConversion: json['costPerConversion']?.toDouble() ?? 0.0,
    );
  }
}

class CampaignInsight {
  final String insightId;
  final String title;
  final String description;
  final String type; // 'opportunity', 'warning', 'success', 'info'
  final double impact;
  final String recommendation;
  final DateTime generatedAt;

  CampaignInsight({
    required this.insightId,
    required this.title,
    required this.description,
    required this.type,
    required this.impact,
    required this.recommendation,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'insightId': insightId,
      'title': title,
      'description': description,
      'type': type,
      'impact': impact,
      'recommendation': recommendation,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory CampaignInsight.fromJson(Map<String, dynamic> json) {
    return CampaignInsight(
      insightId: json['insightId'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      impact: json['impact']?.toDouble() ?? 0.0,
      recommendation: json['recommendation'],
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }
}
