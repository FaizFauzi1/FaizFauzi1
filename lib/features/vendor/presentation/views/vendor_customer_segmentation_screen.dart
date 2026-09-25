import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';

class VendorCustomerSegmentationScreen extends StatefulWidget {
  const VendorCustomerSegmentationScreen({super.key});

  @override
  State<VendorCustomerSegmentationScreen> createState() => _VendorCustomerSegmentationScreenState();
}

class _VendorCustomerSegmentationScreenState extends State<VendorCustomerSegmentationScreen> {
  final List<Map<String, dynamic>> _segments = [
    {
      'id': 'SEG001',
      'name': 'High-Value Wedding Clients',
      'description': 'Customers who have booked wedding packages worth RM5,000+',
      'criteria': {
        'totalSpent': {'operator': '>=', 'value': 5000},
        'serviceType': 'Wedding',
        'bookingFrequency': {'operator': '>=', 'value': 1},
      },
      'customerCount': 145,
      'avgSpent': 8750.0,
      'lastUsed': '2024-03-10',
      'status': 'Active',
    },
    {
      'id': 'SEG002',
      'name': 'Corporate Event Planners',
      'description': 'Business clients who book corporate events regularly',
      'criteria': {
        'serviceType': 'Corporate',
        'companySize': {'operator': '>=', 'value': 50},
        'bookingFrequency': {'operator': '>=', 'value': 2},
      },
      'customerCount': 89,
      'avgSpent': 3200.0,
      'lastUsed': '2024-03-08',
      'status': 'Active',
    },
    {
      'id': 'SEG003',
      'name': 'New Customers (Last 30 Days)',
      'description': 'Recently acquired customers who made their first booking',
      'criteria': {
        'firstBookingDate': {'operator': '>=', 'value': '2024-02-10'},
        'bookingCount': 1,
      },
      'customerCount': 67,
      'avgSpent': 1200.0,
      'lastUsed': '2024-03-12',
      'status': 'Active',
    },
    {
      'id': 'SEG004',
      'name': 'Birthday Party Parents',
      'description': 'Parents who frequently book birthday parties for children',
      'criteria': {
        'serviceType': 'Birthday',
        'hasChildren': true,
        'ageRange': '30-45',
      },
      'customerCount': 203,
      'avgSpent': 950.0,
      'lastUsed': '2024-02-28',
      'status': 'Inactive',
    },
  ];

  final List<Map<String, dynamic>> _segmentTemplates = [
    {
      'name': 'RFM Analysis',
      'description': 'Segment based on Recency, Frequency, and Monetary value',
      'icon': Icons.analytics,
      'color': AppTheme.primaryColor,
      'criteria': ['Recency', 'Frequency', 'Monetary'],
    },
    {
      'name': 'Demographic',
      'description': 'Segment based on age, location, and personal attributes',
      'icon': Icons.people,
      'color': AppTheme.successColor,
      'criteria': ['Age Range', 'Location', 'Gender', 'Income Level'],
    },
    {
      'name': 'Behavioral',
      'description': 'Segment based on customer actions and preferences',
      'icon': Icons.track_changes,
      'color': AppTheme.accentColor,
      'criteria': ['Service Types', 'Booking Frequency', 'Cancellation Rate', 'Referral Count'],
    },
    {
      'name': 'Lifecycle',
      'description': 'Segment based on customer journey stage',
      'icon': Icons.timeline,
      'color': AppTheme.warningColor,
      'criteria': ['New Customer', 'Regular Customer', 'VIP Customer', 'At-Risk Customer'],
    },
  ];

  final List<Map<String, dynamic>> _segmentInsights = [
    {
      'title': 'Top Performing Segment',
      'segment': 'High-Value Wedding Clients',
      'metric': 'Revenue Contribution',
      'value': 'RM 1,268,750',
      'change': '+15.2%',
      'insight': 'This segment contributes 45% of total revenue',
    },
    {
      'title': 'Growing Segment',
      'segment': 'Corporate Event Planners',
      'metric': 'Customer Growth',
      'value': '+23 new customers',
      'change': '+35.8%',
      'insight': 'Strong growth in corporate bookings this quarter',
    },
    {
      'title': 'Declining Segment',
      'segment': 'Birthday Party Parents',
      'metric': 'Engagement Rate',
      'value': '12.3%',
      'change': '-8.4%',
      'insight': 'Consider re-engagement campaigns for this segment',
    },
  ];

  String _selectedTab = 'Segments';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Customer Segmentation',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: _createNewSegment,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          _buildTabSelector(),

          // Content based on selected tab
          Expanded(
            child: _selectedTab == 'Segments'
                ? _buildSegmentsView()
                : _selectedTab == 'Templates'
                ? _buildTemplatesView()
                : _buildInsightsView(),
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
            child: _buildTabButton('Segments', _selectedTab == 'Segments'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Templates', _selectedTab == 'Templates'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Insights', _selectedTab == 'Insights'),
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

  Widget _buildSegmentsView() {
    final activeSegments = _segments.where((s) => s['status'] == 'Active').length;
    final totalCustomers = _segments.fold<int>(0, (sum, s) => sum + (s['customerCount'] as int));
    final avgRevenuePerSegment = _segments
        .where((s) => s['status'] == 'Active')
        .fold<double>(0, (sum, s) => sum + (s['avgSpent'] as double)) /
        activeSegments;

    return Column(
      children: [
        // Segment overview
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Active Segments',
                  activeSegments.toString(),
                  Icons.group_work,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Total Customers',
                  _formatNumber(totalCustomers),
                  Icons.people,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Avg Revenue/Segment',
                  'RM ${avgRevenuePerSegment.toStringAsFixed(0)}',
                  Icons.attach_money,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ),

        // Segments list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _segments.length,
            itemBuilder: (context, index) =>
                _buildSegmentCard(_segments[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildSegmentCard(Map<String, dynamic> segment) {
    final isActive = segment['status'] == 'Active';

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
                      segment['name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      segment['description'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.shade100 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  segment['status'] as String,
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Segment metrics
          Row(
            children: [
              Expanded(
                child: _buildSegmentMetric(
                  'Customers',
                  _formatNumber(segment['customerCount'] as int),
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildSegmentMetric(
                  'Avg Spent',
                  'RM ${(segment['avgSpent'] as double).toStringAsFixed(0)}',
                  Icons.attach_money,
                ),
              ),
              Expanded(
                child: _buildSegmentMetric(
                  'Last Used',
                  segment['lastUsed'] as String,
                  Icons.schedule,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Criteria preview
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Key Criteria:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _buildCriteriaChips(segment['criteria'] as Map<String, dynamic>),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editSegment(segment),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewSegmentDetails(segment),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _createCampaignForSegment(segment),
                  icon: const Icon(Icons.campaign, size: 16),
                  label: const Text('Campaign'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 16),
        const SizedBox(height: 4),
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

  List<Widget> _buildCriteriaChips(Map<String, dynamic> criteria) {
    return criteria.entries.take(3).map((entry) {
      String displayText;
      if (entry.value is Map) {
        final operator = entry.value['operator'] as String;
        final value = entry.value['value'];
        displayText = '${entry.key}: $operator $value';
      } else {
        displayText = '${entry.key}: ${entry.value}';
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          displayText,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTemplatesView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: _segmentTemplates.length,
      itemBuilder: (context, index) =>
          _buildTemplateCard(_segmentTemplates[index]),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (template['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              template['icon'] as IconData,
              color: template['color'] as Color,
              size: 30,
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            template['description'] as String,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: (template['criteria'] as List<String>).take(2).map((criterion) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (template['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  criterion,
                  style: TextStyle(
                    color: template['color'] as Color,
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _useTemplate(template),
            style: ElevatedButton.styleFrom(
              backgroundColor: template['color'] as Color,
              minimumSize: const Size(double.infinity, 32),
            ),
            child: const Text('Use Template'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _segmentInsights.length,
      itemBuilder: (context, index) =>
          _buildInsightCard(_segmentInsights[index]),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    final change = insight['change'] as String;
    final isPositive = change.startsWith('+');
    final isNegative = change.startsWith('-');

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
              Text(
                insight['title'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.shade100
                      : isNegative
                          ? Colors.red.shade100
                          : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: isPositive
                        ? Colors.green
                        : isNegative
                            ? Colors.red
                            : Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight['segment'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                insight['metric'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              Text(
                insight['value'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: AppTheme.primaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight['insight'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewSegmentDetailsByName(insight['segment'] as String),
                  child: const Text('View Segment'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _createActionFromInsight(insight),
                  child: const Text('Take Action'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  void _createNewSegment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create new customer segment (placeholder)')),
    );
  }

  void _editSegment(Map<String, dynamic> segment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit segment: ${segment['name']} (placeholder)')),
    );
  }

  void _viewSegmentDetails(Map<String, dynamic> segment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for: ${segment['name']} (placeholder)')),
    );
  }

  void _createCampaignForSegment(Map<String, dynamic> segment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Create campaign for segment: ${segment['name']} (placeholder)')),
    );
  }

  void _useTemplate(Map<String, dynamic> template) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Using template: ${template['name']} (placeholder)')),
    );
  }

  void _viewSegmentDetailsByName(String segmentName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View segment: $segmentName (placeholder)')),
    );
  }

  void _createActionFromInsight(Map<String, dynamic> insight) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Create action from insight: ${insight['title']} (placeholder)')),
    );
  }
}
