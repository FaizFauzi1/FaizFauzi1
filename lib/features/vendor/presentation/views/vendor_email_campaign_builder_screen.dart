import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';

class VendorEmailCampaignBuilderScreen extends StatefulWidget {
  const VendorEmailCampaignBuilderScreen({super.key});

  @override
  State<VendorEmailCampaignBuilderScreen> createState() => _VendorEmailCampaignBuilderScreenState();
}

class _VendorEmailCampaignBuilderScreenState extends State<VendorEmailCampaignBuilderScreen> {
  final List<Map<String, dynamic>> _emailCampaigns = [];

  final List<Map<String, dynamic>> _emailTemplates = [
    {
      'name': 'Wedding Promotion',
      'description': 'Promote wedding packages with beautiful imagery',
      'category': 'Promotional',
      'preview': 'wedding_template.jpg',
      'elements': ['Hero Image', 'Package Details', 'Call to Action', 'Contact Info'],
    },
    {
      'name': 'Thank You',
      'description': 'Express gratitude to customers after booking',
      'category': 'Transactional',
      'preview': 'thank_you_template.jpg',
      'elements': ['Personalized Message', 'Booking Details', 'Next Steps', 'Social Links'],
    },
    {
      'name': 'Service Launch',
      'description': 'Announce new services or features',
      'category': 'Announcement',
      'preview': 'service_launch_template.jpg',
      'elements': ['Announcement', 'Service Benefits', 'Pricing', 'Book Now Button'],
    },
    {
      'name': 'Newsletter',
      'description': 'Regular updates and event planning tips',
      'category': 'Newsletter',
      'preview': 'newsletter_template.jpg',
      'elements': ['Featured Content', 'Tips & Tricks', 'Upcoming Events', 'Subscribe CTA'],
    },
    {
      'name': 'Re-engagement',
      'description': 'Bring back inactive customers',
      'category': 'Re-engagement',
      'preview': 'reengagement_template.jpg',
      'elements': ['Personalized Greeting', 'Special Offer', 'Recent Activity', 'Come Back CTA'],
    },
  ];

  final List<Map<String, dynamic>> _subscriberLists = [];

  String _selectedTab = 'Campaigns';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Email Campaign Builder',
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
                : _selectedTab == 'Templates'
                ? _buildTemplatesView()
                : _buildSubscribersView(),
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
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Templates', _selectedTab == 'Templates'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Subscribers', _selectedTab == 'Subscribers'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return ElevatedButton(
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
    final sentCampaigns = _emailCampaigns.where((c) => c['status'] == 'Sent').length;
    final totalRecipients = _emailCampaigns
        .where((c) => c['status'] == 'Sent')
        .fold<int>(0, (sum, c) => sum + (c['recipients'] as int));
    final avgOpenRate = sentCampaigns == 0 ? 0.0 : _emailCampaigns
        .where((c) => c['status'] == 'Sent')
        .fold<double>(0, (sum, c) => sum + (c['openRate'] as double)) /
        sentCampaigns;

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
                  'Sent Campaigns',
                  sentCampaigns.toString(),
                  Icons.send,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Recipients',
                  _formatNumber(totalRecipients),
                  Icons.people,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Open Rate',
                  '${avgOpenRate.toStringAsFixed(1)}%',
                  Icons.visibility,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ),

        // Campaigns list
        Expanded(
          child: _emailCampaigns.isEmpty
              ? const Center(child: Text('No email campaigns are available.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _emailCampaigns.length,
                  itemBuilder: (context, index) =>
                      _buildCampaignCard(_emailCampaigns[index]),
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

    return Container(
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
                      campaign['name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaign['subject'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  campaign['status'] as String,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (campaign['status'] == 'Sent') ...[
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem('Recipients', _formatNumber(campaign['recipients'] as int)),
                ),
                Expanded(
                  child: _buildMetricItem('Open Rate', '${campaign['openRate'].toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildMetricItem('Click Rate', '${campaign['clickRate'].toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildMetricItem('Conversions', (campaign['conversions'] as int).toString()),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'Sent: ${campaign['sentDate']}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ] else if (campaign['status'] == 'Scheduled') ...[
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 4),
                Text(
                  'Scheduled for: ${campaign['sentDate']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

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
              if (campaign['status'] == 'Draft')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _scheduleCampaign(campaign),
                    icon: const Icon(Icons.schedule_send),
                    label: const Text('Schedule'),
                  ),
                )
              else if (campaign['status'] == 'Scheduled')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _sendNow(campaign),
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Send Now'),
                  ),
                ),
            ],
          ),
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _emailTemplates.length,
      itemBuilder: (context, index) =>
          _buildTemplateCard(_emailTemplates[index]),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
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
          // Template preview placeholder
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.email, color: Colors.grey, size: 32),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            template['name'] as String,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            template['description'] as String,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getCategoryColor(template['category'] as String).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              template['category'] as String,
              style: TextStyle(
                color: _getCategoryColor(template['category'] as String),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Elements:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                ...((template['elements'] as List<String>).take(3)).map((element) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.check, color: Colors.green, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          element,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _previewTemplate(template),
                  child: const Text('Preview'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _useTemplate(template),
                  child: const Text('Use'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribersView() {
    final totalSubscribers = _subscriberLists.fold<int>(0, (sum, list) => sum + (list['count'] as int));

    return Column(
      children: [
        // Subscriber overview
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildSubscriberOverviewCard(
                  'Total Subscribers',
                  _formatNumber(totalSubscribers),
                  Icons.people,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSubscriberOverviewCard(
                  'Lists',
                  _subscriberLists.length.toString(),
                  Icons.list,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSubscriberOverviewCard(
                  'Avg Growth',
                  '—',
                  Icons.trending_up,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ),

        // Subscriber lists
        Expanded(
          child: _subscriberLists.isEmpty
              ? const Center(child: Text('No subscriber lists are available.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subscriberLists.length,
                  itemBuilder: (context, index) =>
                      _buildSubscriberListCard(_subscriberLists[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildSubscriberOverviewCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildSubscriberListCard(Map<String, dynamic> list) {
    final growth = list['growth'] as String;
    final isPositive = growth.startsWith('+');

    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      list['name'] as String,
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
                        color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        growth,
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  list['description'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last updated: ${list['lastUpdated']}',
                  style: const TextStyle(
                    fontSize: 10,
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
                _formatNumber(list['count'] as int),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Text(
                'subscribers',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            onSelected: (value) => _handleListAction(value, list),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('View Subscribers')),
              const PopupMenuItem(value: 'edit', child: Text('Edit List')),
              const PopupMenuItem(value: 'export', child: Text('Export List')),
              const PopupMenuItem(value: 'delete', child: Text('Delete List')),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Sent':
        return Colors.green;
      case 'Scheduled':
        return Colors.blue;
      case 'Draft':
        return Colors.grey;
      default:
        return AppTheme.primaryColor;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Promotional':
        return AppTheme.primaryColor;
      case 'Transactional':
        return AppTheme.successColor;
      case 'Announcement':
        return AppTheme.accentColor;
      case 'Newsletter':
        return AppTheme.warningColor;
      case 'Re-engagement':
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  void _createNewCampaign() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create new email campaign (placeholder)')),
    );
  }

  void _editCampaign(Map<String, dynamic> campaign) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit campaign: ${campaign['name']} (placeholder)')),
    );
  }

  void _viewAnalytics(Map<String, dynamic> campaign) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View analytics for: ${campaign['name']} (placeholder)')),
    );
  }

  void _scheduleCampaign(Map<String, dynamic> campaign) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Schedule campaign: ${campaign['name']} (placeholder)')),
    );
  }

  void _sendNow(Map<String, dynamic> campaign) {
    setState(() {
      campaign['status'] = 'Sent';
      campaign['sentDate'] = DateTime.now().toString().split(' ')[0];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${campaign['name']} sent successfully')),
    );
  }

  void _previewTemplate(Map<String, dynamic> template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Preview template: ${template['name']} (placeholder)')),
    );
  }

  void _useTemplate(Map<String, dynamic> template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Using template: ${template['name']} (placeholder)')),
    );
  }

  void _handleListAction(String action, Map<String, dynamic> list) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action: ${list['name']} (placeholder)')),
    );
  }
}
