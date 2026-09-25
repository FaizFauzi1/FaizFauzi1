import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/finance/shop_performance.dart';
import '../../../../core/database/database_helper.dart';

class ShopProvider with ChangeNotifier {
  final List<ShopPerformance> _performances = [];
  final List<ProductPerformance> _products = [];
  final List<CustomerSegment> _customerSegments = [];

  UnmodifiableListView<ShopPerformance> get performances => UnmodifiableListView(_performances);
  UnmodifiableListView<ProductPerformance> get products => UnmodifiableListView(_products);
  UnmodifiableListView<CustomerSegment> get customerSegments => UnmodifiableListView(_customerSegments);

  ShopProvider() {
    _initializeSampleData();
  }

  void _initializeSampleData() {
    // Initialize with sample product performance data
    _products.addAll([
      ProductPerformance(
        productId: 'prod_1',
        productName: 'Wedding Photography Package',
        unitsSold: 45,
        revenue: 22500.0,
        profit: 13500.0,
        views: 1200,
        clicks: 180,
        conversionRate: 25.0,
        averageRating: 4.8,
        reviewCount: 23,
        isActive: true,
      ),
      ProductPerformance(
        productId: 'prod_2',
        productName: 'Event Catering Service',
        unitsSold: 32,
        revenue: 16000.0,
        profit: 9600.0,
        views: 890,
        clicks: 145,
        conversionRate: 22.1,
        averageRating: 4.6,
        reviewCount: 18,
        isActive: true,
      ),
      ProductPerformance(
        productId: 'prod_3',
        productName: 'Venue Decoration Package',
        unitsSold: 28,
        revenue: 8400.0,
        profit: 4200.0,
        views: 650,
        clicks: 95,
        conversionRate: 29.5,
        averageRating: 4.9,
        reviewCount: 15,
        isActive: true,
      ),
      ProductPerformance(
        productId: 'prod_4',
        productName: 'DJ Services',
        unitsSold: 38,
        revenue: 15200.0,
        profit: 9120.0,
        views: 780,
        clicks: 120,
        conversionRate: 31.6,
        averageRating: 4.7,
        reviewCount: 21,
        isActive: true,
      ),
      ProductPerformance(
        productId: 'prod_5',
        productName: 'Photo Booth Rental',
        unitsSold: 52,
        revenue: 7800.0,
        profit: 4680.0,
        views: 950,
        clicks: 165,
        conversionRate: 31.5,
        averageRating: 4.5,
        reviewCount: 28,
        isActive: true,
      ),
    ]);

    // Initialize customer segments
    _customerSegments.addAll([
      CustomerSegment(
        segmentId: 'seg_1',
        segmentName: 'Wedding Planners',
        customerCount: 45,
        totalRevenue: 35000.0,
        averageOrderValue: 777.78,
        totalOrders: 67,
        retentionRate: 85.0,
        demographics: {
          'ageRange': '25-45',
          'incomeLevel': 'High',
          'location': 'Urban',
        },
      ),
      CustomerSegment(
        segmentId: 'seg_2',
        segmentName: 'Corporate Clients',
        customerCount: 23,
        totalRevenue: 28000.0,
        averageOrderValue: 1217.39,
        totalOrders: 34,
        retentionRate: 92.0,
        demographics: {
          'ageRange': '30-55',
          'incomeLevel': 'Very High',
          'location': 'Business Districts',
        },
      ),
      CustomerSegment(
        segmentId: 'seg_3',
        segmentName: 'Private Events',
        customerCount: 67,
        totalRevenue: 22000.0,
        averageOrderValue: 328.36,
        totalOrders: 89,
        retentionRate: 78.0,
        demographics: {
          'ageRange': '25-50',
          'incomeLevel': 'Middle to High',
          'location': 'Mixed',
        },
      ),
    ]);

    // Initialize performance data
    _performances.add(ShopPerformance(
      id: 'perf_1',
      vendorId: 'vendor_1',
      date: DateTime.now(),
      totalRevenue: 62100.0,
      totalOrders: 156,
      uniqueCustomers: 89,
      averageOrderValue: 398.08,
      conversionRate: 27.8,
      revenueByCategory: {
        'Photography': 22500.0,
        'Catering': 16000.0,
        'Decoration': 8400.0,
        'Entertainment': 15200.0,
        'Other': 7800.0,
      },
      ordersByCategory: {
        'Photography': 45,
        'Catering': 32,
        'Decoration': 28,
        'Entertainment': 38,
        'Other': 52,
      },
      topProducts: _products.take(5).toList(),
      customerSegments: _customerSegments,
      metadata: {
        'profitMargin': 45.2,
        'customerRetentionRate': 82.5,
        'inventoryTurnover': 3.2,
      },
    ));
  }

  void _generateSampleDataForVendor(String vendorId) {
    // Generate a unique performance ID
    final performanceId = 'perf_${vendorId}_${DateTime.now().millisecondsSinceEpoch}';

    // Create sample performance data for the new vendor
    final samplePerformance = ShopPerformance(
      id: performanceId,
      vendorId: vendorId,
      date: DateTime.now(),
      totalRevenue: 15000.0 + (vendorId.hashCode % 50000), // Vary revenue based on vendorId
      totalOrders: 25 + (vendorId.hashCode % 100), // Vary orders
      uniqueCustomers: 15 + (vendorId.hashCode % 50), // Vary customers
      averageOrderValue: 450.0 + (vendorId.hashCode % 200), // Vary AOV
      conversionRate: 15.0 + (vendorId.hashCode % 20), // Vary conversion
      revenueByCategory: {
        'Photography': 5000.0,
        'Catering': 4000.0,
        'Decoration': 3000.0,
        'Entertainment': 2000.0,
        'Other': 1000.0,
      },
      ordersByCategory: {
        'Photography': 8,
        'Catering': 6,
        'Decoration': 5,
        'Entertainment': 4,
        'Other': 2,
      },
      topProducts: _products.take(3).toList(), // Use existing products
      customerSegments: _customerSegments.take(2).toList(), // Use existing segments
      metadata: {
        'profitMargin': 35.0 + (vendorId.hashCode % 20),
        'customerRetentionRate': 70.0 + (vendorId.hashCode % 20),
        'inventoryTurnover': 2.0 + (vendorId.hashCode % 2),
      },
    );

    _performances.add(samplePerformance);
    notifyListeners();
  }

  // Product Management
  void addProduct(ProductPerformance product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(String productId, ProductPerformance updatedProduct) {
    final index = _products.indexWhere((p) => p.productId == productId);
    if (index != -1) {
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }

  void deleteProduct(String productId) {
    _products.removeWhere((p) => p.productId == productId);
    notifyListeners();
  }

  ProductPerformance? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.productId == productId);
    } catch (e) {
      return null;
    }
  }

  List<ProductPerformance> getTopProducts({int limit = 10}) {
    final sorted = _products.where((p) => p.isActive).toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return sorted.take(limit).toList();
  }

  List<ProductPerformance> getLowPerformingProducts({int limit = 10}) {
    final sorted = _products.where((p) => p.isActive).toList()
      ..sort((a, b) => a.conversionRate.compareTo(b.conversionRate));
    return sorted.take(limit).toList();
  }

  // Customer Segment Management
  void addCustomerSegment(CustomerSegment segment) {
    _customerSegments.add(segment);
    notifyListeners();
  }

  void updateCustomerSegment(String segmentId, CustomerSegment updatedSegment) {
    final index = _customerSegments.indexWhere((s) => s.segmentId == segmentId);
    if (index != -1) {
      _customerSegments[index] = updatedSegment;
      notifyListeners();
    }
  }

  void deleteCustomerSegment(String segmentId) {
    _customerSegments.removeWhere((s) => s.segmentId == segmentId);
    notifyListeners();
  }

  CustomerSegment? getCustomerSegmentById(String segmentId) {
    try {
      return _customerSegments.firstWhere((s) => s.segmentId == segmentId);
    } catch (e) {
      return null;
    }
  }

  // Performance Management
  void addPerformance(ShopPerformance performance) {
    _performances.add(performance);
    notifyListeners();
  }

  void updatePerformance(String performanceId, ShopPerformance updatedPerformance) {
    final index = _performances.indexWhere((p) => p.id == performanceId);
    if (index != -1) {
      _performances[index] = updatedPerformance;
      notifyListeners();
    }
  }

  ShopPerformance? getLatestPerformance(String vendorId) {
    try {
      return _performances
          .where((p) => p.vendorId == vendorId)
          .reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    } catch (e) {
      return null;
    }
  }

  List<ShopPerformance> getPerformanceHistory(String vendorId, {int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _performances
        .where((p) => p.vendorId == vendorId && p.date.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Analytics Methods - FIXED VERSION
  Map<String, dynamic> getShopAnalytics(String vendorId) {
    // Generate sample data for new vendors
    if (getLatestPerformance(vendorId) == null) {
      _generateSampleDataForVendor(vendorId);
    }

    final performance = getLatestPerformance(vendorId);
    final products = _products.where((p) => p.isActive).toList();
    final segments = _customerSegments;

    // If no performance data, return default structure with safe values
    if (performance == null) {
      return {
        'currentPerformance': {
          'totalRevenue': 0.0,
          'totalOrders': 0,
          'averageOrderValue': 0.0,
          'conversionRate': 0.0,
        },
        'growthMetrics': {
          'revenueGrowth': 0.0,
          'orderGrowth': 0.0,
          'customerGrowth': 0.0,
        },
        'productAnalytics': {
          'totalProducts': 0,
          'activeProducts': 0,
          'topProducts': [],
          'lowPerformers': [],
          'averageConversionRate': 0.0,
        },
        'customerAnalytics': {
          'totalCustomers': 0,
          'customerSegments': [],
          'averageOrderValue': 0.0,
          'retentionRate': 0.0,
        },
        'inventoryMetrics': {
          'inventoryTurnover': 0.0,
          'stockoutRate': 0.0,
          'overstockItems': 0,
        },
      };
    }

    // Calculate growth rates safely
    double revenueGrowth = 0.0;
    double orderGrowth = 0.0;

    try {
      final previousPerformances = _performances
          .where((p) => p.vendorId == vendorId && p.date.isBefore(performance.date))
          .toList();

      if (previousPerformances.isNotEmpty) {
        final previousPerformance = previousPerformances
            .reduce((a, b) => a.date.isAfter(b.date) ? a : b);

        if (previousPerformance.totalRevenue > 0) {
          revenueGrowth = ((performance.totalRevenue - previousPerformance.totalRevenue) / previousPerformance.totalRevenue) * 100;
        }

        if (previousPerformance.totalOrders > 0) {
          orderGrowth = ((performance.totalOrders - previousPerformance.totalOrders) / previousPerformance.totalOrders) * 100;
        }
      }
    } catch (e) {
      // If there's any error calculating growth, use default values
      revenueGrowth = 0.0;
      orderGrowth = 0.0;
    }

    // Product analytics with safe calculations
    final topProducts = getTopProducts(limit: 5);
    final lowPerformers = getLowPerformingProducts(limit: 5);

    double averageConversionRate = 0.0;
    if (products.isNotEmpty) {
      try {
        averageConversionRate = products.map((p) => p.conversionRate).reduce((a, b) => a + b) / products.length;
      } catch (e) {
        averageConversionRate = 0.0;
      }
    }

    // Customer analytics with safe calculations
    final totalCustomers = segments.fold<int>(0, (sum, s) => sum + s.customerCount);
    final totalRevenue = segments.fold<double>(0, (sum, s) => sum + s.totalRevenue);
    final totalOrders = segments.fold<int>(0, (sum, s) => sum + s.totalOrders);
    final averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    double retentionRate = 0.0;
    if (segments.isNotEmpty) {
      try {
        retentionRate = segments.map((s) => s.retentionRate).reduce((a, b) => a + b) / segments.length;
      } catch (e) {
        retentionRate = 0.0;
      }
    }

    return {
      'currentPerformance': performance.toJson(),
      'growthMetrics': {
        'revenueGrowth': revenueGrowth,
        'orderGrowth': orderGrowth,
        'customerGrowth': 0.0,
      },
      'productAnalytics': {
        'totalProducts': products.length,
        'activeProducts': products.where((p) => p.isActive).length,
        'topProducts': topProducts.map((p) => p.toJson()).toList(),
        'lowPerformers': lowPerformers.map((p) => p.toJson()).toList(),
        'averageConversionRate': averageConversionRate,
      },
      'customerAnalytics': {
        'totalCustomers': totalCustomers,
        'customerSegments': segments.map((s) => s.toJson()).toList(),
        'averageOrderValue': averageOrderValue,
        'retentionRate': retentionRate,
      },
      'inventoryMetrics': {
        'inventoryTurnover': performance.metadata?['inventoryTurnover'] ?? 0.0,
        'stockoutRate': 0.0,
        'overstockItems': 0,
      },
    };
  }

  // Sales Analytics
  SalesAnalytics getSalesAnalytics(String vendorId, DateTime startDate, DateTime endDate) {
    final performances = getPerformanceHistory(vendorId, days: 365);

    double totalSales = 0.0;
    int totalOrders = 0;
    double averageOrderValue = 0.0;
    double growthRate = 0.0;

    final salesByPeriod = <String, double>{};
    final topSellingCategories = <String, double>{};

    // Calculate totals
    for (final performance in performances) {
      totalSales += performance.totalRevenue;
      totalOrders += performance.totalOrders;
    }

    if (totalOrders > 0) {
      averageOrderValue = totalSales / totalOrders;
    }

    // Calculate growth rate (simplified)
    if (performances.length >= 2) {
      final current = performances.first.totalRevenue;
      final previous = performances[1].totalRevenue;
      if (previous > 0) {
        growthRate = ((current - previous) / previous) * 100;
      }
    }

    // Group by month
    for (final performance in performances) {
      final monthKey = '${performance.date.year}-${performance.date.month.toString().padLeft(2, '0')}';
      salesByPeriod[monthKey] = (salesByPeriod[monthKey] ?? 0) + performance.totalRevenue;
    }

    // Top selling categories
    if (performances.isNotEmpty) {
      final latest = performances.first;
      topSellingCategories.addAll(latest.revenueByCategory);
    }

    return SalesAnalytics(
      vendorId: vendorId,
      periodStart: startDate,
      periodEnd: endDate,
      totalSales: totalSales,
      totalOrders: totalOrders,
      averageOrderValue: averageOrderValue,
      growthRate: growthRate,
      salesByPeriod: salesByPeriod,
      topSellingCategories: topSellingCategories,
      trends: [],
      seasonalPatterns: [],
    );
  }

  // Utility Methods
  double getTotalRevenue(String vendorId, {DateTime? startDate, DateTime? endDate}) {
    final performances = getPerformanceHistory(vendorId, days: 365);
    double total = 0.0;

    for (final performance in performances) {
      if (startDate != null && endDate != null) {
        if (performance.date.isAfter(startDate) && performance.date.isBefore(endDate)) {
          total += performance.totalRevenue;
        }
      } else {
        total += performance.totalRevenue;
      }
    }

    return total;
  }

  int getTotalOrders(String vendorId, {DateTime? startDate, DateTime? endDate}) {
    final performances = getPerformanceHistory(vendorId, days: 365);
    int total = 0;

    for (final performance in performances) {
      if (startDate != null && endDate != null) {
        if (performance.date.isAfter(startDate) && performance.date.isBefore(endDate)) {
          total += performance.totalOrders;
        }
      } else {
        total += performance.totalOrders;
      }
    }

    return total;
  }

  double getAverageOrderValue(String vendorId) {
    final totalRevenue = getTotalRevenue(vendorId);
    final totalOrders = getTotalOrders(vendorId);

    return totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
  }

  // Bulk Operations
  void bulkUpdateProducts(List<String> productIds, Map<String, dynamic> updates) {
    for (final id in productIds) {
      final product = _products.firstWhere(
        (p) => p.productId == id,
        orElse: () => throw Exception('Product not found'),
      );

      final updatedProduct = ProductPerformance(
        productId: product.productId,
        productName: updates['productName'] ?? product.productName,
        unitsSold: updates['unitsSold'] ?? product.unitsSold,
        revenue: updates['revenue'] ?? product.revenue,
        profit: updates['profit'] ?? product.profit,
        views: updates['views'] ?? product.views,
        clicks: updates['clicks'] ?? product.clicks,
        conversionRate: updates['conversionRate'] ?? product.conversionRate,
        averageRating: updates['averageRating'] ?? product.averageRating,
        reviewCount: updates['reviewCount'] ?? product.reviewCount,
        isActive: updates['isActive'] ?? product.isActive,
      );

      updateProduct(id, updatedProduct);
    }
  }

  void bulkUpdateCustomerSegments(List<String> segmentIds, Map<String, dynamic> updates) {
    for (final id in segmentIds) {
      final segment = _customerSegments.firstWhere(
        (s) => s.segmentId == id,
        orElse: () => throw Exception('Customer segment not found'),
      );

      final updatedSegment = CustomerSegment(
        segmentId: segment.segmentId,
        segmentName: updates['segmentName'] ?? segment.segmentName,
        customerCount: updates['customerCount'] ?? segment.customerCount,
        totalRevenue: updates['totalRevenue'] ?? segment.totalRevenue,
        averageOrderValue: updates['averageOrderValue'] ?? segment.averageOrderValue,
        totalOrders: updates['totalOrders'] ?? segment.totalOrders,
        retentionRate: updates['retentionRate'] ?? segment.retentionRate,
        demographics: updates['demographics'] ?? segment.demographics,
      );

      updateCustomerSegment(id, updatedSegment);
    }
  }
}
