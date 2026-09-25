enum PerformanceMetric { revenue, orders, customers, conversionRate, averageOrderValue }

class ShopPerformance {
  final String id;
  final String vendorId;
  final DateTime date;
  final double totalRevenue;
  final int totalOrders;
  final int uniqueCustomers;
  final double averageOrderValue;
  final double conversionRate;
  final Map<String, double> revenueByCategory;
  final Map<String, int> ordersByCategory;
  final List<ProductPerformance> topProducts;
  final List<CustomerSegment> customerSegments;
  final Map<String, dynamic> metadata;

  ShopPerformance({
    required this.id,
    required this.vendorId,
    required this.date,
    required this.totalRevenue,
    required this.totalOrders,
    required this.uniqueCustomers,
    required this.averageOrderValue,
    required this.conversionRate,
    required this.revenueByCategory,
    required this.ordersByCategory,
    required this.topProducts,
    required this.customerSegments,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'date': date.toIso8601String(),
      'totalRevenue': totalRevenue,
      'totalOrders': totalOrders,
      'uniqueCustomers': uniqueCustomers,
      'averageOrderValue': averageOrderValue,
      'conversionRate': conversionRate,
      'revenueByCategory': revenueByCategory,
      'ordersByCategory': ordersByCategory,
      'topProducts': topProducts.map((p) => p.toJson()).toList(),
      'customerSegments': customerSegments.map((c) => c.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory ShopPerformance.fromJson(Map<String, dynamic> json) {
    return ShopPerformance(
      id: json['id'],
      vendorId: json['vendorId'],
      date: DateTime.parse(json['date']),
      totalRevenue: json['totalRevenue']?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] ?? 0,
      uniqueCustomers: json['uniqueCustomers'] ?? 0,
      averageOrderValue: json['averageOrderValue']?.toDouble() ?? 0.0,
      conversionRate: json['conversionRate']?.toDouble() ?? 0.0,
      revenueByCategory: Map<String, double>.from(json['revenueByCategory'] ?? {}),
      ordersByCategory: Map<String, int>.from(json['ordersByCategory'] ?? {}),
      topProducts: (json['topProducts'] as List?)?.map((p) => ProductPerformance.fromJson(p)).toList() ?? [],
      customerSegments: (json['customerSegments'] as List?)?.map((c) => CustomerSegment.fromJson(c)).toList() ?? [],
      metadata: json['metadata'] ?? {},
    );
  }

  double get profitMargin => metadata['profitMargin']?.toDouble() ?? 0.0;
  double get customerRetentionRate => metadata['customerRetentionRate']?.toDouble() ?? 0.0;
  double get inventoryTurnover => metadata['inventoryTurnover']?.toDouble() ?? 0.0;
}

class ProductPerformance {
  final String productId;
  final String productName;
  final int unitsSold;
  final double revenue;
  final double profit;
  final int views;
  final int clicks;
  final double conversionRate;
  final double averageRating;
  final int reviewCount;
  final bool isActive;

  ProductPerformance({
    required this.productId,
    required this.productName,
    required this.unitsSold,
    required this.revenue,
    required this.profit,
    required this.views,
    required this.clicks,
    required this.conversionRate,
    required this.averageRating,
    required this.reviewCount,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'unitsSold': unitsSold,
      'revenue': revenue,
      'profit': profit,
      'views': views,
      'clicks': clicks,
      'conversionRate': conversionRate,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'isActive': isActive,
    };
  }

  factory ProductPerformance.fromJson(Map<String, dynamic> json) {
    return ProductPerformance(
      productId: json['productId'],
      productName: json['productName'],
      unitsSold: json['unitsSold'] ?? 0,
      revenue: json['revenue']?.toDouble() ?? 0.0,
      profit: json['profit']?.toDouble() ?? 0.0,
      views: json['views'] ?? 0,
      clicks: json['clicks'] ?? 0,
      conversionRate: json['conversionRate']?.toDouble() ?? 0.0,
      averageRating: json['averageRating']?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  double get profitMargin => revenue > 0 ? (profit / revenue) * 100 : 0.0;
}

class CustomerSegment {
  final String segmentId;
  final String segmentName;
  final int customerCount;
  final double totalRevenue;
  final double averageOrderValue;
  final int totalOrders;
  final double retentionRate;
  final Map<String, dynamic> demographics;

  CustomerSegment({
    required this.segmentId,
    required this.segmentName,
    required this.customerCount,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.totalOrders,
    required this.retentionRate,
    required this.demographics,
  });

  Map<String, dynamic> toJson() {
    return {
      'segmentId': segmentId,
      'segmentName': segmentName,
      'customerCount': customerCount,
      'totalRevenue': totalRevenue,
      'averageOrderValue': averageOrderValue,
      'totalOrders': totalOrders,
      'retentionRate': retentionRate,
      'demographics': demographics,
    };
  }

  factory CustomerSegment.fromJson(Map<String, dynamic> json) {
    return CustomerSegment(
      segmentId: json['segmentId'],
      segmentName: json['segmentName'],
      customerCount: json['customerCount'] ?? 0,
      totalRevenue: json['totalRevenue']?.toDouble() ?? 0.0,
      averageOrderValue: json['averageOrderValue']?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] ?? 0,
      retentionRate: json['retentionRate']?.toDouble() ?? 0.0,
      demographics: json['demographics'] ?? {},
    );
  }
}

class SalesAnalytics {
  final String vendorId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalSales;
  final int totalOrders;
  final double averageOrderValue;
  final double growthRate;
  final Map<String, double> salesByPeriod;
  final Map<String, double> topSellingCategories;
  final List<SalesTrend> trends;
  final List<SeasonalPattern> seasonalPatterns;

  SalesAnalytics({
    required this.vendorId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalSales,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.growthRate,
    required this.salesByPeriod,
    required this.topSellingCategories,
    required this.trends,
    required this.seasonalPatterns,
  });

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalSales': totalSales,
      'totalOrders': totalOrders,
      'averageOrderValue': averageOrderValue,
      'growthRate': growthRate,
      'salesByPeriod': salesByPeriod,
      'topSellingCategories': topSellingCategories,
      'trends': trends.map((t) => t.toJson()).toList(),
      'seasonalPatterns': seasonalPatterns.map((s) => s.toJson()).toList(),
    };
  }

  factory SalesAnalytics.fromJson(Map<String, dynamic> json) {
    return SalesAnalytics(
      vendorId: json['vendorId'],
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
      totalSales: json['totalSales']?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] ?? 0,
      averageOrderValue: json['averageOrderValue']?.toDouble() ?? 0.0,
      growthRate: json['growthRate']?.toDouble() ?? 0.0,
      salesByPeriod: Map<String, double>.from(json['salesByPeriod'] ?? {}),
      topSellingCategories: Map<String, double>.from(json['topSellingCategories'] ?? {}),
      trends: (json['trends'] as List?)?.map((t) => SalesTrend.fromJson(t)).toList() ?? [],
      seasonalPatterns: (json['seasonalPatterns'] as List?)?.map((s) => SeasonalPattern.fromJson(s)).toList() ?? [],
    );
  }
}

class SalesTrend {
  final String trendId;
  final String trendName;
  final double trendValue;
  final double previousValue;
  final double changePercentage;
  final bool isPositive;

  SalesTrend({
    required this.trendId,
    required this.trendName,
    required this.trendValue,
    required this.previousValue,
    required this.changePercentage,
    required this.isPositive,
  });

  Map<String, dynamic> toJson() {
    return {
      'trendId': trendId,
      'trendName': trendName,
      'trendValue': trendValue,
      'previousValue': previousValue,
      'changePercentage': changePercentage,
      'isPositive': isPositive,
    };
  }

  factory SalesTrend.fromJson(Map<String, dynamic> json) {
    return SalesTrend(
      trendId: json['trendId'],
      trendName: json['trendName'],
      trendValue: json['trendValue']?.toDouble() ?? 0.0,
      previousValue: json['previousValue']?.toDouble() ?? 0.0,
      changePercentage: json['changePercentage']?.toDouble() ?? 0.0,
      isPositive: json['isPositive'] ?? false,
    );
  }
}

class SeasonalPattern {
  final String patternId;
  final String patternName;
  final String period;
  final double averageSales;
  final double peakSales;
  final double lowSales;
  final List<String> peakMonths;

  SeasonalPattern({
    required this.patternId,
    required this.patternName,
    required this.period,
    required this.averageSales,
    required this.peakSales,
    required this.lowSales,
    required this.peakMonths,
  });

  Map<String, dynamic> toJson() {
    return {
      'patternId': patternId,
      'patternName': patternName,
      'period': period,
      'averageSales': averageSales,
      'peakSales': peakSales,
      'lowSales': lowSales,
      'peakMonths': peakMonths,
    };
  }

  factory SeasonalPattern.fromJson(Map<String, dynamic> json) {
    return SeasonalPattern(
      patternId: json['patternId'],
      patternName: json['patternName'],
      period: json['period'],
      averageSales: json['averageSales']?.toDouble() ?? 0.0,
      peakSales: json['peakSales']?.toDouble() ?? 0.0,
      lowSales: json['lowSales']?.toDouble() ?? 0.0,
      peakMonths: List<String>.from(json['peakMonths'] ?? []),
    );
  }
}
