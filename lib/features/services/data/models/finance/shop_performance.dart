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
  final Map<String, dynamic>? metadata;

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
    this.metadata,
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
      'customerSegments': customerSegments.map((s) => s.toJson()).toList(),
      'metadata': metadata,
    };
  }
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

  double get profitMargin => profit / revenue;

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
  final List<String> trends;
  final List<String> seasonalPatterns;

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
}