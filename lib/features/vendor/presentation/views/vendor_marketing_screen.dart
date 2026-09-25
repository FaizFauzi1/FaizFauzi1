import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/marketing_provider.dart';
import '../../../../core/utils/app_theme.dart';
import '../../models/marketing_campaign.dart';
import 'package:intl/intl.dart';

class VendorMarketingScreen extends StatefulWidget {
  const VendorMarketingScreen({Key? key}) : super(key: key);

  @override
  State<VendorMarketingScreen> createState() => _VendorMarketingScreenState();
}

class _VendorMarketingScreenState extends State<VendorMarketingScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketing Campaigns'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateCampaignDialog,
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showAnalytics,
          ),
        ],
      ),
      body: Consumer<MarketingProvider>(
        builder: (context, marketingProvider, child) {
          final analytics = marketingProvider.getMarketingAnalytics('vendor_1');
          final campaigns = marketingProvider.campaigns;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Marketing Overview
                _buildMarketingOverview(analytics),

                const SizedBox(height: 24),

                // Campaign List
                _buildCampaignList(campaigns),

                const SizedBox(height: 24),

                // Campaign Insights
                _buildCampaignInsights(marketingProvider),

                const SizedBox(height: 24),

                // Performance Metrics
                _buildPerformanceMetrics(analytics),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMarketingOverview(dynamic analytics) {
    final overview = analytics['overview'];

    if (overview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentColor, AppTheme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Marketing Overview',
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
                  'Total Campaigns',
                  '${overview['totalCampaigns'] ?? 0}',
                  Icons.campaign,
                  Colors.blue.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Active Campaigns',
                  '${overview['activeCampaigns'] ?? 0}',
                  Icons.play_circle,
                  Colors.green.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Total Budget',
                  currencyFormat.format(overview['totalBudget'] ?? 0),
                  Icons.account_balance_wallet,
                  Colors.orange.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Budget Used',
                  '${overview['budgetUtilization']?.toStringAsFixed(1) ?? '0.0'}%',
                  Icons.trending_up,
                  Colors.purple.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Total Leads',
                  '${overview['totalLeads']?.toStringAsFixed(0) ?? '0'}',
                  Icons.people,
                  Colors.teal.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Conversion Rate',
                  '${overview['conversionRate']?.toStringAsFixed(1) ?? '0.0'}%',
                  Icons.percent,
                  Colors.indigo.shade100,
                ),
              ),
            ],
          ),
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

  Widget _buildCampaignList(List<MarketingCampaign> campaigns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Campaigns',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/vendor-campaigns'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (campaigns.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No campaigns yet'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return _buildCampaignCard(campaign);
            },
          ),
      ],
    );
  }

  Widget _buildCampaignCard(MarketingCampaign campaign) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaign.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(campaign.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  campaign.statusDisplayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(campaign.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCampaignMetric(
                  'Budget',
                  currencyFormat.format(campaign.budget),
                  Icons.account_balance_wallet,
                ),
              ),
              Expanded(
                child: _buildCampaignMetric(
                  'Spent',
                  currencyFormat.format(campaign.spent),
                  Icons.attach_money,
                ),
              ),
              Expanded(
                child: _buildCampaignMetric(
                  'Leads',
                  '${campaign.metrics['leads']?.toStringAsFixed(0) ?? '0'}',
                  Icons.people,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: campaign.budgetUtilization / 100,
                  backgroundColor: AppTheme.textSecondaryColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    campaign.isOverBudget ? Colors.red : AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${campaign.budgetUtilization.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: campaign.channels.map((channel) {
              return Chip(
                label: Text(
                  channel,
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                labelStyle: TextStyle(color: AppTheme.primaryColor),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCampaignInsights(MarketingProvider provider) {
    final insights = provider.insights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Campaign Insights',
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
            children: insights.map((insight) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getInsightColor(insight.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getInsightColor(insight.type).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getInsightIcon(insight.type),
                          color: _getInsightColor(insight.type),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getInsightColor(insight.type),
                            ),
                          ),
                        ),
                        Text(
                          '${insight.impact.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getInsightColor(insight.type),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      insight.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      insight.recommendation,
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textSecondaryColor,
                      ),
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

  Widget _buildPerformanceMetrics(dynamic analytics) {
    final channelPerformance = analytics['channelPerformance'] as Map<String, double>? ?? {};

    return Column(
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
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: channelPerformance.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(color: AppTheme.textPrimaryColor),
                      ),
                    ),
                    Text(
                      currencyFormat.format(entry.value),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
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

  Color _getStatusColor(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.active:
        return Colors.green;
      case CampaignStatus.paused:
        return Colors.orange;
      case CampaignStatus.completed:
        return Colors.blue;
      case CampaignStatus.draft:
        return Colors.grey;
      case CampaignStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'opportunity':
        return Colors.blue;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'opportunity':
        return Icons.lightbulb;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  void _showCreateCampaignDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Campaign'),
        content: const Text('Campaign creation form would be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Detailed analytics view coming soon!')),
    );
  }
}
