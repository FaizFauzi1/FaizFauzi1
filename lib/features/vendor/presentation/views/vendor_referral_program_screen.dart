import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';

class VendorReferralProgramScreen extends StatefulWidget {
  const VendorReferralProgramScreen({super.key});

  @override
  State<VendorReferralProgramScreen> createState() => _VendorReferralProgramScreenState();
}

class _VendorReferralProgramScreenState extends State<VendorReferralProgramScreen> {
  final List<Map<String, dynamic>> _referralPrograms = [
    {
      'id': 'REF001',
      'name': 'Friends & Family Rewards',
      'description': 'Get RM100 off when you refer a friend who books with us',
      'status': 'Active',
      'rewardType': 'Fixed Amount',
      'rewardValue': 100.0,
      'referrerReward': 100.0,
      'refereeReward': 50.0,
      'totalReferrals': 245,
      'successfulReferrals': 189,
      'totalRewardsGiven': 18900.0,
      'startDate': '2024-01-01',
      'endDate': null,
      'rules': {
        'minBookingAmount': 500.0,
        'referralExpiryDays': 30,
        'maxReferralsPerCustomer': 5,
      },
    },
    {
      'id': 'REF002',
      'name': 'VIP Referral Club',
      'description': 'Exclusive program for our top customers - earn double rewards',
      'status': 'Active',
      'rewardType': 'Percentage',
      'rewardValue': 15.0,
      'referrerReward': 200.0,
      'refereeReward': 100.0,
      'totalReferrals': 67,
      'successfulReferrals': 52,
      'totalRewardsGiven': 10400.0,
      'startDate': '2024-02-01',
      'endDate': null,
      'rules': {
        'minBookingAmount': 2000.0,
        'referralExpiryDays': 60,
        'maxReferralsPerCustomer': 10,
      },
    },
  ];

  final List<Map<String, dynamic>> _referralCodes = [
    {
      'code': 'EVENTEASE2024',
      'generatedBy': 'John Doe',
      'status': 'Active',
      'uses': 12,
      'maxUses': 50,
      'expiryDate': '2024-12-31',
      'rewardAmount': 75.0,
    },
    {
      'code': 'WEDDINGBUDDY',
      'generatedBy': 'Sarah Wilson',
      'status': 'Active',
      'uses': 8,
      'maxUses': 20,
      'expiryDate': '2024-06-30',
      'rewardAmount': 150.0,
    },
    {
      'code': 'CORPORATEPARTNER',
      'generatedBy': 'Mike Chen',
      'status': 'Expired',
      'uses': 15,
      'maxUses': 15,
      'expiryDate': '2024-03-01',
      'rewardAmount': 200.0,
    },
  ];

  final List<Map<String, dynamic>> _referralAnalytics = [
    {
      'metric': 'Total Referrals',
      'value': '312',
      'change': '+23.5%',
      'period': 'This Month',
    },
    {
      'metric': 'Conversion Rate',
      'value': '77.2%',
      'change': '+5.1%',
      'period': 'This Month',
    },
    {
      'metric': 'Average Order Value',
      'value': 'RM 1,245',
      'change': '+12.8%',
      'period': 'From Referrals',
    },
    {
      'metric': 'Customer Lifetime Value',
      'value': 'RM 3,890',
      'change': '+18.3%',
      'period': 'Referred Customers',
    },
  ];

  final List<Map<String, dynamic>> _topReferrers = [
    {
      'name': 'John Doe',
      'referrals': 15,
      'successfulReferrals': 12,
      'totalEarned': 1200.0,
      'lastReferral': '2024-03-10',
    },
    {
      'name': 'Sarah Wilson',
      'referrals': 12,
      'successfulReferrals': 10,
      'totalEarned': 1000.0,
      'lastReferral': '2024-03-08',
    },
    {
      'name': 'Mike Chen',
      'referrals': 8,
      'successfulReferrals': 7,
      'totalEarned': 700.0,
      'lastReferral': '2024-03-05',
    },
  ];

  String _selectedTab = 'Programs';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Referral Programs',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: _createNewProgram,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          _buildTabSelector(),

          // Content based on selected tab
          Expanded(
            child: _selectedTab == 'Programs'
                ? _buildProgramsView()
                : _selectedTab == 'Codes'
                ? _buildCodesView()
                : _buildAnalyticsView(),
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
            child: _buildTabButton('Programs', _selectedTab == 'Programs'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Codes', _selectedTab == 'Codes'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Analytics', _selectedTab == 'Analytics'),
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

  Widget _buildProgramsView() {
    final activePrograms = _referralPrograms.where((p) => p['status'] == 'Active').length;
    final totalReferrals = _referralPrograms.fold<int>(0, (sum, p) => sum + (p['totalReferrals'] as int));
    final totalRewards = _referralPrograms.fold<double>(0, (sum, p) => sum + (p['totalRewardsGiven'] as double));

    return Column(
      children: [
        // Program overview
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Active Programs',
                  activePrograms.toString(),
                  Icons.campaign,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Total Referrals',
                  _formatNumber(totalReferrals),
                  Icons.people,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Rewards Given',
                  'RM ${_formatNumber(totalRewards.toInt())}',
                  Icons.card_giftcard,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ),

        // Programs list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _referralPrograms.length,
            itemBuilder: (context, index) =>
                _buildProgramCard(_referralPrograms[index]),
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

  Widget _buildProgramCard(Map<String, dynamic> program) {
    final isActive = program['status'] == 'Active';
    final successRate = (program['successfulReferrals'] as int) / (program['totalReferrals'] as int) * 100;

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
                      program['name'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      program['description'] as String,
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
                  program['status'] as String,
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

          // Program metrics
          Row(
            children: [
              Expanded(
                child: _buildProgramMetric(
                  'Total Referrals',
                  _formatNumber(program['totalReferrals'] as int),
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildProgramMetric(
                  'Success Rate',
                  '${successRate.toStringAsFixed(1)}%',
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildProgramMetric(
                  'Rewards Given',
                  'RM ${_formatNumber((program['totalRewardsGiven'] as double).toInt())}',
                  Icons.card_giftcard,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Reward details
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
                  'Rewards:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Referrer: RM ${program['referrerReward']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Referee: RM ${program['refereeReward']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                  ],
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
                  onPressed: () => _editProgram(program),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewProgramAnalytics(program),
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('Analytics'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateReferralCode(program),
                  icon: const Icon(Icons.qr_code, size: 16),
                  label: const Text('Generate Code'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgramMetric(String label, String value, IconData icon) {
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

  Widget _buildCodesView() {
    return Column(
      children: [
        // Add code button
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: ElevatedButton.icon(
            onPressed: _generateNewCode,
            icon: const Icon(Icons.add),
            label: const Text('Generate New Referral Code'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),

        // Codes list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _referralCodes.length,
            itemBuilder: (context, index) =>
                _buildCodeCard(_referralCodes[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeCard(Map<String, dynamic> code) {
    final isActive = code['status'] == 'Active';
    final usagePercentage = (code['uses'] as int) / (code['maxUses'] as int);

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.qr_code,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        code['code'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'by ${code['generatedBy']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  code['status'] as String,
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Usage stats
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${code['uses']}/${code['maxUses']} uses',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: usagePercentage,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${code['rewardAmount']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const Text(
                    'reward',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Expires: ${code['expiryDate']}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareCode(code),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewCodeAnalytics(code),
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('Analytics'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editCode(code),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Analytics metrics
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsMetricCard(
                  _referralAnalytics[0]['metric'] as String,
                  _referralAnalytics[0]['value'] as String,
                  Icons.people,
                  AppTheme.primaryColor,
                  _referralAnalytics[0]['change'] as String,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsMetricCard(
                  _referralAnalytics[1]['metric'] as String,
                  _referralAnalytics[1]['value'] as String,
                  Icons.trending_up,
                  AppTheme.successColor,
                  _referralAnalytics[1]['change'] as String,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildAnalyticsMetricCard(
                  _referralAnalytics[2]['metric'] as String,
                  _referralAnalytics[2]['value'] as String,
                  Icons.attach_money,
                  AppTheme.accentColor,
                  _referralAnalytics[2]['change'] as String,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsMetricCard(
                  _referralAnalytics[3]['metric'] as String,
                  _referralAnalytics[3]['value'] as String,
                  Icons.star,
                  AppTheme.warningColor,
                  _referralAnalytics[3]['change'] as String,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Top referrers
          Container(
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
                  'Top Referrers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                ..._topReferrers.map((referrer) => _buildTopReferrerItem(referrer)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Referral funnel
          Container(
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
                  'Referral Conversion Funnel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFunnelStep('Referral Codes Generated', 100.0, '312'),
                _buildFunnelStep('Codes Shared', 78.0, '244'),
                _buildFunnelStep('New Signups', 65.0, '203'),
                _buildFunnelStep('First Bookings', 45.0, '141'),
                _buildFunnelStep('Repeat Customers', 25.0, '78'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Program performance comparison
          Container(
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
                  'Program Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                ..._referralPrograms.map((program) {
                  final successRate = (program['successfulReferrals'] as int) / (program['totalReferrals'] as int);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            program['name'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: successRate,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${(successRate * 100).toStringAsFixed(1)}%',
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
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsMetricCard(String title, String value, IconData icon, Color color, String change) {
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
              Icon(icon, color: color, size: 20),
              Text(
                change,
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopReferrerItem(Map<String, dynamic> referrer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              (referrer['name'] as String).substring(0, 1),
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referrer['name'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  '${referrer['successfulReferrals']} successful referrals',
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
                'RM ${(referrer['totalEarned'] as double).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
              Text(
                'earned',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelStep(String step, double percentage, String count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 12,
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
            width: 40,
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
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              count,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.right,
            ),
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

  void _createNewProgram() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create new referral program (placeholder)')),
    );
  }

  void _editProgram(Map<String, dynamic> program) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit program: ${program['name']} (placeholder)')),
    );
  }

  void _viewProgramAnalytics(Map<String, dynamic> program) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View analytics for: ${program['name']} (placeholder)')),
    );
  }

  void _generateReferralCode(Map<String, dynamic> program) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generate code for: ${program['name']} (placeholder)')),
    );
  }

  void _generateNewCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generate new referral code (placeholder)')),
    );
  }

  void _shareCode(Map<String, dynamic> code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share code: ${code['code']} (placeholder)')),
    );
  }

  void _viewCodeAnalytics(Map<String, dynamic> code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View analytics for code: ${code['code']} (placeholder)')),
    );
  }

  void _editCode(Map<String, dynamic> code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit code: ${code['code']} (placeholder)')),
    );
  }
}
