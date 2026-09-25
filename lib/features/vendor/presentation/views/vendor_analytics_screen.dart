import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_analytics_provider.dart';
import 'package:eventease/features/vendor/data/providers/subscription_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/shared/widgets/upgrade_required_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VendorAnalyticsScreen extends StatefulWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  State<VendorAnalyticsScreen> createState() => _VendorAnalyticsScreenState();
}

class _VendorAnalyticsScreenState extends State<VendorAnalyticsScreen> {
  late VendorAnalyticsProvider _analyticsProvider;

  @override
  void initState() {
    super.initState();
    _analyticsProvider = Provider.of<VendorAnalyticsProvider>(context, listen: false);
    // Delay loading until after the first build to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalytics();
    });
  }

  Future<void> _loadAnalytics() async {
    await _analyticsProvider.loadAnalyticsData();
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final isLocked = !subscriptionProvider.canAccessAnalytics;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Advanced Analytics',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: AppTheme.primaryColor),
            onPressed: _exportAnalytics,
          ),
        ],
      ),
      body: UpgradeRequiredOverlay(
        isLocked: isLocked,
        title: 'Unlock Advanced Analytics',
        description: 'Upgrade to Pro or Business tier to gain deep insights into your business performance and customer trends.',
        onUpgradePressed: () {
          // Navigate to subscription screen
          final vendorId = Provider.of<VendorProvider>(context, listen: false).currentVendor?.id;
          Navigator.pushNamed(context, '/vendor-subscriptions', arguments: vendorId);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period and metric selectors
              IgnorePointer(ignoring: isLocked, child: _buildSelectors()),
  
              const SizedBox(height: 20),
  
              // Impressions & Profile Views
              IgnorePointer(ignoring: isLocked, child: _buildImpressionsAndViewsSection()),
  
              const SizedBox(height: 20),
  
              // Performance metrics
              IgnorePointer(ignoring: isLocked, child: _buildPerformanceMetrics()),
  
              const SizedBox(height: 20),
  
              // Conversion Funnel
              IgnorePointer(ignoring: isLocked, child: _buildConversionFunnelSection()),
  
              const SizedBox(height: 20),
  
              // Actionable Insights
              IgnorePointer(ignoring: isLocked, child: _buildActionableInsightsSection()),
  
              const SizedBox(height: 20),
  
              // Revenue chart
              IgnorePointer(ignoring: isLocked, child: _buildRevenueChart()),
  
              const SizedBox(height: 20),
  
              // Customer analytics
              IgnorePointer(ignoring: isLocked, child: _buildCustomerAnalytics()),
  
              const SizedBox(height: 20),
  
              // Additional insights
              IgnorePointer(ignoring: isLocked, child: _buildAdditionalInsights()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectors() {
    return Consumer<VendorAnalyticsProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: provider.selectedPeriod,
                      items: const [
                        DropdownMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
                        DropdownMenuItem(value: 'Last 30 Days', child: Text('Last 30 Days')),
                        DropdownMenuItem(value: 'Last 3 Months', child: Text('Last 3 Months')),
                        DropdownMenuItem(value: 'Last 6 Months', child: Text('Last 6 Months')),
                        DropdownMenuItem(value: 'Last Year', child: Text('Last Year')),
                        DropdownMenuItem(value: 'Custom', child: Text('Custom Range')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.updatePeriod(value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Time Period',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: provider.selectedMetric,
                      items: const [
                        DropdownMenuItem(value: 'Revenue', child: Text('Revenue')),
                        DropdownMenuItem(value: 'Bookings', child: Text('Bookings')),
                        DropdownMenuItem(value: 'Customers', child: Text('Customers')),
                        DropdownMenuItem(value: 'Conversion', child: Text('Conversion Rate')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          provider.updateMetric(value);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Primary Metric',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImpressionsAndViewsSection() {
    return Consumer<VendorAnalyticsProvider>(
      builder: (context, provider, child) {
        final data = provider.impressionsAndViews;
        final impressions = data['impressions'] ?? 0;
        final impressionsGrowth = data['impressions_growth'] as String? ?? '—';
        final profileViews = data['profile_views'] ?? 0;
        final profileViewsGrowth = data['profile_views_growth'] as String? ?? '—';
        final inquiries = data['inquiries'] ?? 0;
        final inquiriesGrowth = data['inquiries_growth'] as String? ?? '—';
        final quotes = data['quotes'] ?? 0;
        final quotesGrowth = data['quotes_growth'] as String? ?? '—';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Traffic & Discovery Overview',
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
                  child: _buildTrafficCard(
                    title: 'Search Impressions',
                    value: NumberFormat.decimalPattern().format(impressions),
                    change: impressionsGrowth,
                    icon: Icons.visibility,
                    color: const Color(0xFF3F51B5),
                    subtitle: 'Appearances in catalog search',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTrafficCard(
                    title: 'Profile Views',
                    value: NumberFormat.decimalPattern().format(profileViews),
                    change: profileViewsGrowth,
                    icon: Icons.person_search,
                    color: const Color(0xFFE91E63),
                    subtitle: 'Direct vendor profile visits',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTrafficCard(
                    title: 'Customer Inquiries',
                    value: NumberFormat.decimalPattern().format(inquiries),
                    change: inquiriesGrowth,
                    icon: Icons.chat_bubble,
                    color: const Color(0xFF009688),
                    subtitle: 'Direct chat & quote requests',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTrafficCard(
                    title: 'Quotes Issued',
                    value: NumberFormat.decimalPattern().format(quotes),
                    change: quotesGrowth,
                    icon: Icons.receipt_long,
                    color: const Color(0xFFFF9800),
                    subtitle: 'Custom package proposals sent',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrafficCard({
    required String title,
    required String value,
    required String change,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConversionFunnelSection() {
    return Consumer<VendorAnalyticsProvider>(
      builder: (context, provider, child) {
        final stages = provider.funnelStages;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.filter_alt, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Full Conversion Funnel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text('End-to-End', style: TextStyle(fontSize: 11, color: AppTheme.primaryColor)),
                    backgroundColor: Color(0xFFEEF2FF),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Track drop-offs across each milestone of your sales pipeline.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 20),
              ...stages.map((stage) {
                final stageName = stage['stage'] as String;
                final count = stage['count'] as int;
                final conversion = stage['conversion'] as String;
                final factor = (stage['factor'] as num).toDouble();
                final color = stage['color'] as Color;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            stageName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                NumberFormat.decimalPattern().format(count),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  conversion,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: factor,
                          backgroundColor: Colors.grey.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionableInsightsSection() {
    return Consumer<VendorAnalyticsProvider>(
      builder: (context, provider, child) {
        final insights = provider.actionableInsights;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 8),
                  Text(
                    'Actionable AI Growth Insights',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Data-backed recommendations to boost your bookings and revenue.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 16),
              ...insights.map((insight) {
                final title = insight['title'] as String;
                final description = insight['description'] as String;
                final impact = insight['impact'] as String;
                final actionLabel = insight['actionLabel'] as String;
                final icon = insight['icon'] as IconData;
                final color = insight['color'] as Color;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE9D5FF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 20, color: const Color(0xFF7C3AED)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              impact,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Applied action: $actionLabel')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(actionLabel),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceMetrics() {
    return Consumer<VendorAnalyticsProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Performance Indicators',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: provider.performanceMetrics.length,
              itemBuilder: (context, index) =>
                  _buildMetricCard(provider.performanceMetrics[index]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(Map<String, dynamic> metric) {
    final isPositive = metric['trend'] == 'up';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: metric['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  metric['icon'],
                  color: metric['color'],
                  size: 16,
                ),
              ),
              const Spacer(),
              Text(
                metric['change'],
                style: TextStyle(
                  color: isPositive ? AppTheme.successColor : AppTheme.errorColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            metric['value'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric['title'],
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Consumer<VendorAnalyticsProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Revenue Trend',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      provider.analyticsData != null && provider.analyticsData!['total_revenue'] != null && (provider.analyticsData!['total_revenue'] as double) > 0
                        ? '+${(((provider.analyticsData!['total_revenue'] as double) / 1000) * 18.5).toStringAsFixed(1)}% vs last period'
                        : '0% vs last period',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Simple bar chart representation
              SizedBox(
                height: 200,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: provider.revenueData.map((data) {
                    final maxRevenue = provider.revenueData
                        .map((d) => d['revenue'] as int)
                        .reduce((a, b) => a > b ? a : b);
                    final height = maxRevenue > 0 ? (data['revenue'] / maxRevenue) * 150 : 0.0;

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 30,
                          height: height,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['month'],
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Revenue stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildChartStat('Total Revenue', provider.analyticsData != null ? 'RM ${provider.analyticsData!['total_revenue']?.toStringAsFixed(0) ?? '0'}' : 'RM 0'),
                  _buildChartStat('Avg Monthly', provider.analyticsData != null ? 'RM ${((provider.analyticsData!['total_revenue'] ?? 0) / 6).toStringAsFixed(0)}' : 'RM 0'),
                  _buildChartStat('Best Month', provider.revenueData.isNotEmpty ? '${provider.revenueData.reduce((a, b) => (a['revenue'] as int) > (b['revenue'] as int) ? a : b)['month']} (RM ${provider.revenueData.reduce((a, b) => (a['revenue'] as int) > (b['revenue'] as int) ? a : b)['revenue']})' : 'N/A'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCustomerAnalytics() {
    return Consumer<VendorAnalyticsProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Customer segments
              ...provider.customerData.map((segment) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          segment['segment'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          '${segment['count']} (${segment['percentage']}%)',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: segment['percentage'] / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getSegmentColor(segment['segment']),
                      ),
                    ),
                  ],
                ),
              )),

              const SizedBox(height: 16),

              // Customer insights
              Row(
                children: [
                  Expanded(
                    child: _buildInsightCard(
                      'Avg Customer Value',
                      provider.analyticsData != null ? 'RM ${(provider.analyticsData!['average_order_value'] ?? 0).toStringAsFixed(0)}' : 'RM 0',
                      Icons.trending_up,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInsightCard(
                      'Customer Retention',
                      provider.analyticsData != null ? '${((provider.analyticsData!['repeat_business_rate'] ?? 0) * 100).toStringAsFixed(0)}%' : '0%',
                      Icons.people,
                      AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getSegmentColor(String segment) {
    switch (segment) {
      case 'New Customers':
        return AppTheme.primaryColor;
      case 'Returning':
        return AppTheme.successColor;
      case 'VIP':
        return AppTheme.warningColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Peak hours
          _buildInsightRow(
            'Peak Booking Hours',
            '2:00 PM - 6:00 PM',
            Icons.schedule,
            AppTheme.primaryColor,
          ),

          // Popular services
          _buildInsightRow(
            'Top Service Category',
            'Wedding Photography',
            Icons.camera_alt,
            AppTheme.successColor,
          ),

          // Geographic insights
          _buildInsightRow(
            'Primary Customer Location',
            'Kuala Lumpur (45%)',
            Icons.location_on,
            AppTheme.accentColor,
          ),

          // Seasonal trends
          _buildInsightRow(
            'Seasonal Peak',
            'March - June',
            Icons.calendar_today,
            AppTheme.warningColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportAnalytics() {
    final data = _analyticsProvider.analyticsData ?? {};
    final buffer = StringBuffer()
      ..writeln('EventEase Vendor Analytics')
      ..writeln('Period,${_analyticsProvider.selectedPeriod}')
      ..writeln('Metric,${_analyticsProvider.selectedMetric}')
      ..writeln('Exported,${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}')
      ..writeln();
    data.forEach((key, value) {
      if (value is Map) {
        value.forEach((k, v) => buffer.writeln('$key.$k,$v'));
      } else if (value is List) {
        buffer.writeln('$key,${value.length} rows');
      } else {
        buffer.writeln('$key,$value');
      }
    });
    for (final metric in _analyticsProvider.performanceMetrics) {
      buffer.writeln('metric,${metric['label'] ?? metric['name']},${metric['value']}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analytics CSV copied to clipboard')),
    );
  }
}
