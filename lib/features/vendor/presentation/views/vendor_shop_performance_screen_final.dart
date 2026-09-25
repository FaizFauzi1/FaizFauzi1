import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/services/data/providers/shop_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/services/data/models/finance/shop_performance.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:intl/intl.dart';

class VendorShopPerformanceScreen extends StatefulWidget {
  const VendorShopPerformanceScreen({Key? key}) : super(key: key);

  @override
  State<VendorShopPerformanceScreen> createState() => _VendorShopPerformanceScreenState();
}

class _VendorShopPerformanceScreenState extends State<VendorShopPerformanceScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Performance'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportPerformanceReport,
          ),
        ],
      ),
      body: Consumer2<AuthProvider, ShopProvider>(
        builder: (context, authProvider, shopProvider, child) {
          if (!authProvider.isAuthenticated) {
            return const Center(
              child: Text('Please log in to view shop performance.'),
            );
          }

          try {
            final vendorId = authProvider.userEmail;
            final analytics = shopProvider.getShopAnalytics(vendorId);

            // Check if analytics data is available
            if (analytics.isEmpty) {
              return _buildErrorState(
                'No performance data available',
                'Please check your connection and try refreshing.',
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Performance Overview
                  _buildPerformanceOverview(analytics),

                  const SizedBox(height: 24),

                  // Top Products
                  _buildTopProducts(shopProvider),

                  const SizedBox(height: 24),

                  // Customer Segments
                  _buildCustomerSegments(shopProvider),

                  const SizedBox(height: 24),

                  // Product Analytics
                  _buildProductAnalytics(analytics),

                  const SizedBox(height: 24),

                  // Growth Metrics
                  _buildGrowthMetrics(analytics),
                ],
              ),
            );
          } catch (e) {
            return _buildErrorState(
              'Error loading performance data',
              'An error occurred while loading your shop performance data. Please try again.',
            );
          }
        },
      ),
    );
  }

  Widget _buildErrorState(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview(Map<String, dynamic> analytics) {
    final performance = analytics['currentPerformance'] as Map<String, dynamic>?;
    final growth = analytics['growthMetrics'] as Map<String, dynamic>?;

    // If no performance data, show loading or error state
    if (performance == null || performance.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.textSecondaryColor.withOpacity(0.2)),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 48, color: AppTheme.textSecondaryColor),
              SizedBox(height: 16),
              Text(
                'Performance data is being calculated...',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shop Performance Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Total Revenue',
                  currencyFormat.format(performance['totalRevenue'] ?? 0),
                  Icons.attach_money,
                  Colors.green.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Total Orders',
                  '${performance['totalOrders'] ?? 0}',
                  Icons.shopping_cart,
                  Colors.blue.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Avg Order Value',
                  currencyFormat.format(performance['averageOrderValue'] ?? 0),
                  Icons.trending_up,
                  Colors.orange.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Conversion Rate',
                  '${(performance['conversionRate'] ?? 0).toStringAsFixed(1)}%',
                  Icons.percent,
                  Colors.purple.shade100,
                ),
              ),
            ],
          ),
          if (growth != null && growth.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildGrowthIndicator(
                    'Revenue Growth',
                    (growth['revenueGrowth'] ?? 0.0).toDouble(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGrowthIndicator(
                    'Order Growth',
                    (growth['orderGrowth'] ?? 0.0).toDouble(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthIndicator(String title, double growth) {
    final isPositive = growth >= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${growth.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(ShopProvider shopProvider) {
    final topProducts = shopProvider.getTopProducts(limit: 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/vendor-products'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        topProducts.isEmpty
            ? _buildEmptyState('No products available', 'Add some products to see performance data.')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topProducts.length,
                itemBuilder: (context, index) {
                  final product = topProducts[index];
                  return _buildProductCard(product, index + 1);
                },
              ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductPerformance product, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3 ? AppTheme.primaryColor : AppTheme.textSecondaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rank <= 3 ? Colors.white : AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName.isNotEmpty ? product.productName : 'Unknown Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${product.unitsSold} sold',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${product.conversionRate.toStringAsFixed(1)}% conversion',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(product.revenue),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${product.profitMargin.toStringAsFixed(1)}% margin',
                style: TextStyle(
                  fontSize: 12,
                  color: product.profitMargin >= 40 ? Colors.green : AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSegments(ShopProvider shopProvider) {
    final segments = shopProvider.customerSegments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Segments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        segments.isEmpty
            ? _buildEmptyState('No customer segments', 'Customer segments will appear here as you get more customers.')
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: segments.map((segment) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  segment.segmentName.isNotEmpty ? segment.segmentName : 'Unknown Segment',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${segment.customerCount} customers • ${segment.retentionRate.toStringAsFixed(1)}% retention',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currencyFormat.format(segment.totalRevenue),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormat.format(segment.averageOrderValue),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }

  Widget _buildProductAnalytics(Map<String, dynamic> analytics) {
    final productAnalytics = analytics['productAnalytics'] as Map<String, dynamic>?;

    if (productAnalytics == null || productAnalytics.isEmpty) {
      return _buildEmptyState('No product analytics', 'Product analytics will be available once you have product data.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Analytics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Total Products',
                '${productAnalytics['totalProducts'] ?? 0}',
                Icons.inventory,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'Active Products',
                '${productAnalytics['activeProducts'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'Avg Conversion',
                '${(productAnalytics['averageConversionRate'] ?? 0).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthMetrics(Map<String, dynamic> analytics) {
    final customerAnalytics = analytics['customerAnalytics'] as Map<String, dynamic>?;

    if (customerAnalytics == null || customerAnalytics.isEmpty) {
      return _buildEmptyState('No customer analytics', 'Customer analytics will be available once you have customer data.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Metrics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      'Total Customers',
                      '${customerAnalytics['totalCustomers'] ?? 0}',
                      Icons.people,
                    ),
                  ),
                  Expanded(
                    child: _buildMetricItem(
                      'Avg Order Value',
                      currencyFormat.format(customerAnalytics['averageOrderValue'] ?? 0),
                      Icons.attach_money,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricItem(
                      'Retention Rate',
                      '${(customerAnalytics['retentionRate'] ?? 0).toStringAsFixed(1)}%',
                      Icons.repeat,
                    ),
                  ),
                  const Expanded(child: SizedBox()), // Empty space for alignment
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate data refresh - in a real app, this would call an API
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Performance data refreshed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to refresh data. Please try again.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    }
  }

  void _exportPerformanceReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Performance report export feature coming soon!')),
    );
  }
}
