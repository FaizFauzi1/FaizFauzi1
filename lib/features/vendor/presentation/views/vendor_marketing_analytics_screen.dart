import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_analytics_provider.dart';
import 'package:provider/provider.dart';
class VendorMarketingAnalyticsScreen extends StatefulWidget {
  const VendorMarketingAnalyticsScreen({super.key});

  @override
  State<VendorMarketingAnalyticsScreen> createState() => _VendorMarketingAnalyticsScreenState();
}

class _VendorMarketingAnalyticsScreenState extends State<VendorMarketingAnalyticsScreen> {
  String _selectedPeriod = '30 Days';
  final List<String> _periods = ['7 Days', '30 Days', '90 Days', '1 Year'];

  @override
  void initState() {
    super.initState();
    // Load analytics data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<VendorAnalyticsProvider>(context, listen: false);
      provider.updatePeriod(_selectedPeriod);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VendorAnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Marketing Analytics',
                  style: TextStyle(
                      color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.error != null) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Marketing Analytics',
                  style: TextStyle(
                      color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.loadAnalyticsData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Marketing Analytics',
                style: TextStyle(
                    color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() => _selectedPeriod = value);
                  provider.updatePeriod(value);
                },
                itemBuilder: (context) => _periods.map((period) => PopupMenuItem(
                  value: period,
                  child: Text(period),
                )).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedPeriod,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Key Metrics Overview
                _buildKeyMetricsGrid(provider),

                const SizedBox(height: 24),

                // Channel Performance
                _buildChannelPerformanceChart(provider),

                const SizedBox(height: 24),

                // Campaign Performance
                _buildCampaignPerformanceTable(provider),

                const SizedBox(height: 24),

                // Audience Insights
                _buildAudienceInsights(provider),

                const SizedBox(height: 24),

                // Conversion Funnel
                _buildConversionFunnel(provider),

                const SizedBox(height: 24),

                // ROI Trends
                _buildROITrends(provider),

                const SizedBox(height: 24),

                // Recommendations
                _buildRecommendations(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeyMetricsGrid(VendorAnalyticsProvider provider) {
    final analyticsData = provider.analyticsData;
    if (analyticsData == null) {
      return const SizedBox.shrink();
    }

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
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildMetricCard(
              'Total Revenue',
              'RM ${(analyticsData['total_revenue'] ?? 0).toStringAsFixed(0)}',
              Icons.attach_money,
              AppTheme.successColor,
              '+12.5%',
            ),
            _buildMetricCard(
              'Average Order Value',
              'RM ${(analyticsData['average_order_value'] ?? 0).toStringAsFixed(0)}',
              Icons.trending_up,
              AppTheme.primaryColor,
              '+8.3%',
            ),
            _buildMetricCard(
              'Total Orders',
              '${analyticsData['total_orders'] ?? 0}',
              Icons.shopping_cart,
              AppTheme.accentColor,
              '+2.1%',
            ),
            _buildMetricCard(
              'Unique Customers',
              '${analyticsData['unique_customers'] ?? 0}',
              Icons.people,
              AppTheme.warningColor,
              '+15.2%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String change) {
    final isPositive = change.startsWith('+');

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                change,
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelPerformanceChart(VendorAnalyticsProvider provider) {
    final analyticsData = provider.analyticsData;
    if (analyticsData == null) {
      return const SizedBox.shrink();
    }
    final channelData = analyticsData['channel_performance'] as Map<String, dynamic>? ?? {};

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
          const Text(
            'Channel Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...channelData.entries.map((entry) {
            final data = entry.value as Map<String, dynamic>;
            final roi = data['roi'] as double;
            final revenue = data['revenue'] as double;
            final cost = data['cost'] as double;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${roi.toStringAsFixed(1)}% ROI',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: roi > 200 ? Colors.green : roi > 100 ? Colors.orange : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Revenue: RM ${revenue.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Cost: RM ${cost.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'ROI: ${roi.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: roi / 500.0, // Normalize for progress bar
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      roi > 200 ? Colors.green : roi > 100 ? Colors.orange : Colors.red,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCampaignPerformanceTable(VendorAnalyticsProvider provider) {
    final analyticsData = provider.analyticsData;
    if (analyticsData == null) {
      return const SizedBox.shrink();
    }
    final campaigns = analyticsData['campaign_performance'] as List<dynamic>? ?? [];

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Campaign Performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Campaign')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Revenue')),
                DataColumn(label: Text('Cost')),
                DataColumn(label: Text('ROI')),
              ],
              rows: campaigns.map((campaign) {
                final roi = campaign['roi'] as double;
                return DataRow(
                  cells: [
                    DataCell(Text(campaign['name'])),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: campaign['status'] == 'Active' ? Colors.green.shade100 : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          campaign['status'],
                          style: TextStyle(
                            color: campaign['status'] == 'Active' ? Colors.green : Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text('RM ${campaign['revenue'].toStringAsFixed(0)}')),
                    DataCell(Text('RM ${campaign['cost'].toStringAsFixed(0)}')),
                    DataCell(
                      Text(
                        '${roi.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: roi > 200 ? Colors.green : roi > 100 ? Colors.orange : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceInsights(VendorAnalyticsProvider provider) {
    final analyticsData = provider.analyticsData;
    if (analyticsData == null) {
      return const SizedBox.shrink();
    }
    final insights = analyticsData['audience_insights'] as Map<String, dynamic>? ?? {};

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
          const Text(
            'Audience Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInsightItem(
                  'New Customers',
                  (insights['newCustomers']?.toString() ?? '0'),
                  Icons.person_add,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightItem(
                  'Returning Customers',
                  (insights['returningCustomers']?.toString() ?? '0'),
                  Icons.refresh,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Demographics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDemographicItem('Top Age Group', (insights['topAgeGroup'] as String?) ?? 'N/A'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDemographicItem('Top Location', (insights['topLocation'] as String?) ?? 'N/A'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Popular Services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ((insights['preferredServices'] as List<dynamic>?) ?? []).map((service) => service as String).map((service) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  service,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
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
  }

  Widget _buildDemographicItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionFunnel(VendorAnalyticsProvider provider) {
    final analyticsData = provider.analyticsData;
    if (analyticsData == null) {
      return const SizedBox.shrink();
    }
    final funnel = analyticsData['conversion_funnel'] as Map<String, dynamic>? ?? {};

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
          const Text(
            'Conversion Funnel',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...funnel.entries.map((entry) {
            final percentage = entry.value as double;
            final stageName = entry.key.toString().toUpperCase();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      stageName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildROITrends(VendorAnalyticsProvider provider) {
    // Mock ROI trend data
    final roiTrends = [
      {'month': 'Jan', 'roi': 180.5},
      {'month': 'Feb', 'roi': 220.3},
      {'month': 'Mar', 'roi': 270.5},
      {'month': 'Apr', 'roi': 245.8},
      {'month': 'May', 'roi': 290.2},
      {'month': 'Jun', 'roi': 310.7},
    ];

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
          const Text(
            'ROI Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: roiTrends.length,
              itemBuilder: (context, index) {
                final trend = roiTrends[index];
                final roi = trend['roi'] as double;
                final maxROI = roiTrends.map((t) => t['roi'] as double).reduce((a, b) => a > b ? a : b);

                return Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 40,
                        height: (roi / maxROI) * 120,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '${roi.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        trend['month'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = [
      {
        'title': 'Optimize Email Campaigns',
        'description': 'Your email campaigns have the highest ROI. Consider increasing budget allocation.',
        'type': 'opportunity',
        'impact': 'High',
      },
      {
        'title': 'Review Paid Ads Strategy',
        'description': 'Paid ads ROI is below target. Consider refining targeting or creative.',
        'type': 'warning',
        'impact': 'Medium',
      },
      {
        'title': 'Expand Referral Program',
        'description': 'Referral program shows strong performance. Consider adding incentives.',
        'type': 'opportunity',
        'impact': 'High',
      },
      {
        'title': 'Focus on Customer Retention',
        'description': 'Retention rate could be improved with personalized follow-up campaigns.',
        'type': 'info',
        'impact': 'Medium',
      },
    ];

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
          const Text(
            'AI Recommendations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) {
            final type = rec['type'] as String;
            final impact = rec['impact'] as String;

            Color typeColor;
            IconData typeIcon;

            switch (type) {
              case 'opportunity':
                typeColor = Colors.green;
                typeIcon = Icons.trending_up;
                break;
              case 'warning':
                typeColor = Colors.orange;
                typeIcon = Icons.warning;
                break;
              case 'info':
                typeColor = Colors.blue;
                typeIcon = Icons.info;
                break;
              default:
                typeColor = Colors.grey;
                typeIcon = Icons.info;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: typeColor.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(typeIcon, color: typeColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              rec['title'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: impact == 'High' ? Colors.red.shade100 : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                impact,
                                style: TextStyle(
                                  color: impact == 'High' ? Colors.red : Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rec['description'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
