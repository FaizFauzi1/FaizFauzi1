import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';

class VendorLoyaltyProgramsScreen extends StatefulWidget {
  const VendorLoyaltyProgramsScreen({super.key});

  @override
  State<VendorLoyaltyProgramsScreen> createState() => _VendorLoyaltyProgramsScreenState();
}

class _VendorLoyaltyProgramsScreenState extends State<VendorLoyaltyProgramsScreen> {
  final List<Map<String, dynamic>> _loyaltyPrograms = [
    {
      'id': 'LOY001',
      'name': 'EventEase Rewards',
      'description': 'Earn points on every booking and redeem for exclusive rewards',
      'status': 'Active',
      'pointsEarned': 12500,
      'pointsRedeemed': 8900,
      'activeMembers': 245,
      'tiers': ['Bronze', 'Silver', 'Gold', 'Platinum'],
      'rules': {
        'pointsPerRM': 1,
        'minPointsRedemption': 100,
        'expiryDays': 365,
      },
    },
  ];

  final List<Map<String, dynamic>> _rewards = [
    {
      'id': 'REW001',
      'name': 'RM 50 Discount',
      'description': 'Get RM 50 off your next booking',
      'pointsCost': 500,
      'category': 'Discount',
      'availability': 'Unlimited',
      'claimed': 45,
      'status': 'Active',
    },
    {
      'id': 'REW002',
      'name': 'Free Service Upgrade',
      'description': 'Upgrade to premium service at no extra cost',
      'pointsCost': 750,
      'category': 'Service',
      'availability': 'Limited (50)',
      'claimed': 23,
      'status': 'Active',
    },
    {
      'id': 'REW003',
      'name': 'Exclusive Event Access',
      'description': 'Early access to special events and promotions',
      'pointsCost': 1000,
      'category': 'Exclusive',
      'availability': 'Limited (10)',
      'claimed': 7,
      'status': 'Active',
    },
    {
      'id': 'REW004',
      'name': 'Birthday Surprise',
      'description': 'Special birthday package with complimentary items',
      'pointsCost': 300,
      'category': 'Special',
      'availability': 'Seasonal',
      'claimed': 12,
      'status': 'Active',
    },
  ];

  final List<Map<String, dynamic>> _tiers = [
    {
      'name': 'Bronze',
      'minPoints': 0,
      'benefits': ['1x points on bookings', 'Basic support', 'Monthly newsletter'],
      'color': const Color(0xFFCD7F32),
      'memberCount': 156,
    },
    {
      'name': 'Silver',
      'minPoints': 1000,
      'benefits': ['1.5x points on bookings', 'Priority support', 'Exclusive offers', 'Birthday bonus'],
      'color': const Color(0xFFC0C0C0),
      'memberCount': 67,
    },
    {
      'name': 'Gold',
      'minPoints': 5000,
      'benefits': ['2x points on bookings', 'VIP support', 'Free upgrades', 'Dedicated manager', 'Exclusive events'],
      'color': const Color(0xFFFFD700),
      'memberCount': 18,
    },
    {
      'name': 'Platinum',
      'minPoints': 10000,
      'benefits': ['3x points on bookings', 'Concierge service', 'All Gold benefits', 'Custom packages', 'Annual bonus'],
      'color': const Color(0xFFE5E4E2),
      'memberCount': 4,
    },
  ];

  String _selectedTab = 'Overview';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Loyalty Programs',
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
            child: _selectedTab == 'Overview'
                ? _buildOverviewView()
                : _selectedTab == 'Rewards'
                ? _buildRewardsView()
                : _buildTiersView(),
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
            child: _buildTabButton('Overview', _selectedTab == 'Overview'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Rewards', _selectedTab == 'Rewards'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Tiers', _selectedTab == 'Tiers'),
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

  Widget _buildOverviewView() {
    final program = _loyaltyPrograms[0];
    final totalPoints = program['pointsEarned'] - program['pointsRedeemed'];
    final redemptionRate = (program['pointsRedeemed'] / program['pointsEarned'] * 100);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program status
          Container(
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
                    Text(
                      program['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  program['description'],
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Key metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Active Members',
                  program['activeMembers'].toString(),
                  Icons.people,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Points Balance',
                  totalPoints.toString(),
                  Icons.stars,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Redemption Rate',
                  '${redemptionRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Program rules
          Container(
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
                  'Program Rules',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRuleItem('Points earned per RM spent', '${program['rules']['pointsPerRM']} points'),
                _buildRuleItem('Minimum points for redemption', '${program['rules']['minPointsRedemption']} points'),
                _buildRuleItem('Points expiry', '${program['rules']['expiryDays']} days'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick actions
          Container(
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
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _editProgram,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Program'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _viewAnalytics,
                        icon: const Icon(Icons.analytics),
                        label: const Text('View Analytics'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildRuleItem(String rule, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            rule,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsView() {
    return Column(
      children: [
        // Add reward button
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: ElevatedButton.icon(
            onPressed: _addNewReward,
            icon: const Icon(Icons.add),
            label: const Text('Add New Reward'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),

        // Rewards list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _rewards.length,
            itemBuilder: (context, index) =>
                _buildRewardCard(_rewards[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
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
        children: [
          Row(
            children: [
              // Reward details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          reward['name'],
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
                            color: _getCategoryColor(reward['category']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            reward['category'],
                            style: TextStyle(
                              color: _getCategoryColor(reward['category']),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reward['description'],
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.stars, color: AppTheme.primaryColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${reward['pointsCost']} points',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.inventory, color: AppTheme.textSecondaryColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          reward['availability'],
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Claimed count
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${reward['claimed']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const Text(
                    'claimed',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editReward(reward),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewRewardAnalytics(reward),
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('Analytics'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toggleRewardStatus(reward),
                  icon: Icon(
                    reward['status'] == 'Active' ? Icons.pause : Icons.play_arrow,
                    size: 16,
                  ),
                  label: Text(reward['status'] == 'Active' ? 'Pause' : 'Activate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTiersView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tiers.length,
      itemBuilder: (context, index) =>
          _buildTierCard(_tiers[index]),
    );
  }

  Widget _buildTierCard(Map<String, dynamic> tier) {
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
        children: [
          Row(
            children: [
              // Tier indicator
              Container(
                width: 12,
                height: 40,
                decoration: BoxDecoration(
                  color: tier['color'],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),

              // Tier details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tier['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${tier['minPoints']} points required',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${tier['memberCount']} members',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Benefits
          const Text(
            'Benefits:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          ...tier['benefits'].map((benefit) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.check, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  benefit,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          )),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editTier(tier),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Benefits'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewTierMembers(tier),
                  icon: const Icon(Icons.people, size: 16),
                  label: const Text('View Members'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Discount':
        return AppTheme.successColor;
      case 'Service':
        return AppTheme.primaryColor;
      case 'Exclusive':
        return AppTheme.accentColor;
      case 'Special':
        return AppTheme.warningColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  void _createNewProgram() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create new loyalty program (placeholder)')),
    );
  }

  void _editProgram() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit loyalty program (placeholder)')),
    );
  }

  void _viewAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View loyalty analytics (placeholder)')),
    );
  }

  void _addNewReward() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add new reward (placeholder)')),
    );
  }

  void _editReward(Map<String, dynamic> reward) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${reward['name']} (placeholder)')),
    );
  }

  void _viewRewardAnalytics(Map<String, dynamic> reward) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View analytics for ${reward['name']} (placeholder)')),
    );
  }

  void _toggleRewardStatus(Map<String, dynamic> reward) {
    setState(() {
      reward['status'] = reward['status'] == 'Active' ? 'Inactive' : 'Active';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${reward['name']} ${reward['status'].toLowerCase()}')),
    );
  }

  void _editTier(Map<String, dynamic> tier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${tier['name']} tier (placeholder)')),
    );
  }

  void _viewTierMembers(Map<String, dynamic> tier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View ${tier['name']} members (placeholder)')),
    );
  }
}
