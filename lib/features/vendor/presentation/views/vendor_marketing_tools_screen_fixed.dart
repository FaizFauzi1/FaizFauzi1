import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';

class VendorMarketingToolsScreen extends StatefulWidget {
  const VendorMarketingToolsScreen({super.key});

  @override
  State<VendorMarketingToolsScreen> createState() => _VendorMarketingToolsScreenState();
}

class _VendorMarketingToolsScreenState extends State<VendorMarketingToolsScreen> {
  final List<Map<String, dynamic>> _campaigns = [
    {
      'id': 'CAMP001',
      'name': 'Spring Wedding Promotion',
      'type': 'Email Campaign',
      'status': 'Active',
      'sent': 1250,
      'opened': 387,
      'clicked': 89,
      'conversions': 23,
      'budget': 500.0,
      'spent': 350.0,
      'startDate': '2024-03-01',
      'endDate': '2024-03-31',
    },
    {
      'id': 'CAMP002',
      'name': 'Facebook Ads - Birthday Parties',
      'type': 'Social Media',
      'status': 'Active',
      'sent': 0,
      'opened': 0,
      'clicked': 2450,
      'conversions': 67,
      'budget': 1000.0,
      'spent': 750.0,
      'startDate': '2024-03-10',
      'endDate': '2024-03-25',
    },
    {
      'id': 'CAMP003',
      'name': 'Customer Retention Campaign',
      'type': 'Automated',
      'status': 'Draft',
      'sent': 0,
      'opened': 0,
      'clicked': 0,
      'conversions': 0,
      'budget': 0.0,
      'spent': 0.0,
      'startDate': null,
      'endDate': null,
    },
  ];

  final List<Map<String, dynamic>> _marketingTools = [
    {
      'name': 'Email Campaigns',
      'description': 'Create and send targeted email campaigns',
      'icon': Icons.email,
      'color': AppTheme.primaryColor,
      'features': ['Template designer', 'A/B testing', 'Automation', 'Analytics'],
    },
    {
      'name': 'Social Media Manager',
      'description': 'Schedule and manage social media posts',
      'icon': Icons.share,
      'color': AppTheme.secondaryColor,
      'features': ['Multi-platform', 'Content calendar', 'Hashtag suggestions', 'Performance tracking'],
    },
    {
      'name': 'Customer Segmentation',
      'description': 'Create targeted customer groups',
      'icon': Icons.groups,
      'color': AppTheme.successColor,
      'features': ['Dynamic segments', 'Behavioral targeting', 'RFM analysis', 'Custom filters'],
    },
    {
      'name': 'Automated Workflows',
      'description': 'Set up marketing automation sequences',
      'icon': Icons.autorenew,
      'color': AppTheme.accentColor,
      'features': ['Welcome series', 'Re-engagement', 'Birthday campaigns', 'Abandoned cart'],
    },
    {
      'name': 'Review Management',
      'description': 'Monitor and respond to customer reviews',
      'icon': Icons.star,
      'color': AppTheme.warningColor,
      'features': ['Review monitoring', 'Response templates', 'Rating analytics', 'Review requests'],
    },
    {
      'name': 'Loyalty Program',
      'description': 'Create and manage customer loyalty programs',
      'icon': Icons.card_giftcard,
      'color': AppTheme.errorColor,
      'features': ['Points system', 'Rewards catalog', 'Tier management', 'Referral program'],
    },
  ];

  String _selectedTab = 'Campaigns';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Marketing Tools2',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: _createNewCampaign,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          _buildTabSelector(),

          // Content based on selected tab
          Expanded(
            child: _selectedTab == 'Campaigns'
                ? _buildCampaignsView()
                : _buildToolsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Campaigns', _selectedTab == 'Campaigns'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTabButton('Tools', _selectedTab == 'Tools'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return ElevatedButton(
      key: ValueKey('tab_$title'),
      onPressed: () => setState(() => _selectedTab = title),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppTheme.textPrimaryColor,
        elevation: isSelected ? 2 : 0,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
      ),
      child: Text(title),
    );
  }

  Widget _buildCampaignsView() {
    final activeCampaigns = _campaigns.where((c) => c['status'] == 'Active').length;
    final totalSpent = _campaigns.fold<double>(0, (sum, c) => sum + (c['spent'] as double));
    final totalConversions = _campaigns.fold<int>(0, (sum, c) => sum + (c['conversions'] as int));

    return Column(
      children: [
        // Campaign stats
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active Campaigns',
                  activeCampaigns.toString(),
                  Icons.campaign,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Spent',
                  'RM ${totalSpent.toStringAsFixed(0)}',
                  Icons.attach_money,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Conversions',
                  totalConversions.toString(),
                  Icons.trending_up,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ),

        // Campaigns list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _campaigns.length,
            itemBuilder: (context, index) =>
                _buildCampaignCard(_campaigns[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Map<String, dynamic> campaign) {
    final statusColor = _getStatusColor(campaign['status'] as String);
    final sent = campaign['sent'] as int;
    final opened = campaign['opened'] as int;
    final clicked = campaign['clicked'] as int;
    final conversions = campaign['conversions'] as int;
    final budget = campaign['budget'] as double;
    final spent = campaign['spent'] as double;

    final openRate = sent > 0 ? (opened / sent * 100) : 0.0;
    final clickRate = sent > 0 ? (clicked / sent * 100) : 0.0;

    return Container(
      key: ValueKey(campaign['id']),
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          Row(
            children: [
              // Campaign icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCampaignColor(campaign['type'] as String).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getCampaignIcon(campaign['type'] as String),
                  color: _getCampaignColor(campaign['type'] as String),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Campaign details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          campaign['name'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            campaign['status'] as String,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaign['type'] as String,
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    if (campaign['startDate'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${campaign['startDate']} - ${campaign['endDate']}',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Budget info
              if (budget > 0) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RM ${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 80,
                      child: LinearProgressIndicator(
                        value: budget > 0 ? spent / budget : 0.0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ] else if (campaign['status'] == 'Active') ...[
                // Show budget info for active campaigns even if budget is 0
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RM ${spent.toStringAsFixed(0)} / No Budget Set',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 80,
                      child: LinearProgressIndicator(
                        value: 0.0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Performance metrics
          if (campaign['status'] == 'Active') ...[
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem('Sent', sent.toString()),
                ),
                Expanded(
                  child: _buildMetricItem('Opened', '${openRate.toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildMetricItem('Clicked', '${clickRate.toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildMetricItem('Converted', conversions.toString()),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editCampaign(campaign),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewAnalytics(campaign),
                    icon: const Icon(Icons.analytics, size: 16),
                    label: const Text('Analytics'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _duplicateCampaign(campaign),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Duplicate'),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Draft campaign actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _activateCampaign(campaign),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Activate'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editCampaign(campaign),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
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
    );
  }

  Widget _buildToolsView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _marketingTools.length,
      itemBuilder: (context, index) =>
          _buildToolCard(_marketingTools[index]),
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    return Container(
      key: ValueKey('tool_${tool['name']}'),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (tool['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              tool['icon'] as IconData,
              color: tool['color'] as Color,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tool['name'] as String,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            tool['description'] as String,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Fixed layout instead of Wrap to avoid mouse tracker issues
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (tool['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (tool['features'] as List)[0],
                    style: TextStyle(
                      color: tool['color'] as Color,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if ((tool['features'] as List).length > 1) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (tool['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (tool['features'] as List)[1],
                      style: TextStyle(
                        color: tool['color'] as Color,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _openTool(tool),
            style: ElevatedButton.styleFrom(
              backgroundColor: tool['color'] as Color,
              minimumSize: const Size(double.infinity, 32),
            ),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return Colors.green;
      case 'Draft':
        return Colors.grey;
      case 'Paused':
        return Colors.orange;
      case 'Completed':
        return Colors.blue;
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _getCampaignColor(String type) {
    switch (type) {
      case 'Email Campaign':
        return AppTheme.primaryColor;
      case 'Social Media':
        return AppTheme.secondaryColor;
      case 'Automated':
        return AppTheme.accentColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getCampaignIcon(String type) {
    switch (type) {
      case 'Email Campaign':
        return Icons.email;
      case 'Social Media':
        return Icons.share;
      case 'Automated':
        return Icons.autorenew;
      default:
        return Icons.campaign;
    }
  }

  void _createNewCampaign() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create new campaign (placeholder)')),
    );
  }

  void _editCampaign(Map<String, dynamic> campaign) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${campaign['name']} (placeholder)')),
    );
  }

  void _viewAnalytics(Map<String, dynamic> campaign) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View analytics for ${campaign['name']} (placeholder)')),
    );
  }

  void _duplicateCampaign(Map<String, dynamic> campaign) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Duplicate ${campaign['name']} (placeholder)')),
    );
  }

  void _activateCampaign(Map<String, dynamic> campaign) {
    setState(() {
      campaign['status'] = 'Active';
      campaign['startDate'] = DateTime.now().toString().substring(0, 10);
      campaign['endDate'] = DateTime.now().add(const Duration(days: 30)).toString().substring(0, 10);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${campaign['name']} activated')),
    );
  }

  void _openTool(Map<String, dynamic> tool) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open ${tool['name']} (placeholder)')),
    );
  }
}
