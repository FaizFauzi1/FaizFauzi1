import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_theme.dart';
import 'vendor_marketing_analytics_screen.dart';
import 'vendor_social_media_manager_screen.dart';
import 'vendor_social_media_integration_screen.dart';
import 'vendor_email_campaign_builder_screen.dart';
import 'vendor_customer_segmentation_screen.dart';
import 'vendor_referral_program_screen.dart';
import 'package:eventease/features/referral/presentation/views/referral_home_screen.dart';

class VendorMarketingScreen extends StatefulWidget {
  const VendorMarketingScreen({Key? key}) : super(key: key);

  @override
  State<VendorMarketingScreen> createState() => _VendorMarketingScreenState();
}

class _VendorMarketingScreenState extends State<VendorMarketingScreen> {
  List<Map<String, dynamic>> _campaigns = [];
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoadingData = true;
  String? _dataError;

  final List<Map<String, dynamic>> _marketingTools = [
    {
      'title': 'Marketing Analytics',
      'description': 'Track campaign performance and ROI',
      'icon': Icons.analytics,
      'color': AppTheme.primaryColor,
      'screen': const VendorMarketingAnalyticsScreen(),
    },
    {
      'title': 'Social Media & Integrations',
      'description': 'Instagram, TikTok, and Facebook sync & manager',
      'icon': Icons.share,
      'color': AppTheme.successColor,
      'screen': const VendorSocialMediaIntegrationScreen(),
    },
    {
      'title': 'Email Campaign Builder',
      'description': 'Create targeted email marketing newsletters',
      'icon': Icons.email,
      'color': AppTheme.accentColor,
      'screen': const VendorEmailCampaignBuilderScreen(),
    },
    {
      'title': 'Social Portfolio Flyer Sharing',
      'description': 'Generate aesthetic cards for WhatsApp & IG Stories',
      'icon': Icons.auto_awesome_mosaic,
      'color': Colors.deepOrange,
      'action': 'social_flyer',
    },
    {
      'title': 'Flash Deals & Coupon Sharing',
      'description': 'Time-limited discounts & promotional promo codes',
      'icon': Icons.local_offer,
      'color': Colors.teal,
      'action': 'flash_deals',
    },
    {
      'title': 'Customer Segmentation',
      'description': 'Target High-Value, Repeat, and Corporate groups',
      'icon': Icons.group_work,
      'color': AppTheme.warningColor,
      'screen': const VendorCustomerSegmentationScreen(),
    },
    {
      'title': 'Referral / Loyalty Hub',
      'description': 'Milestones, referral QR codes & leaderboards',
      'icon': Icons.card_giftcard,
      'color': AppTheme.secondaryColor,
      'screen': const ReferralHomeScreen(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadMarketingData();
  }

  Future<void> _loadMarketingData() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _campaigns = [];
            _coupons = [];
            _dataError = 'Sign in to view your marketing data.';
          });
        }
        return;
      }

      final profile = await client
          .from('vendor_profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (profile == null) {
        if (mounted) {
          setState(() {
            _campaigns = [];
            _coupons = [];
            _dataError = 'No vendor profile is linked to this account.';
          });
        }
        return;
      }

      final vendorId = profile['id'].toString();
      String? queryError;
      List<Map<String, dynamic>> campaigns = [];
      List<Map<String, dynamic>> coupons = [];

      try {
        final response = await client
            .from('ads_campaigns')
            .select()
            .eq('vendor_id', vendorId)
            .order('created_at', ascending: false);
        campaigns = (response as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
      } catch (e) {
        queryError = e.toString();
      }

      try {
        final response = await client
            .from('service_coupons')
            .select()
            .eq('vendor_id', vendorId)
            .eq('is_active', true)
            .order('created_at', ascending: false);
        coupons = (response as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
      } catch (e) {
        queryError ??= e.toString();
      }

      if (mounted) {
        setState(() {
          _campaigns = campaigns;
          _coupons = coupons;
          _dataError = queryError;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _dataError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  int _intValue(Map<String, dynamic> row, String key) =>
      (row[key] as num?)?.toInt() ?? 0;

  DateTime? _recordDate(Map<String, dynamic> row) =>
      DateTime.tryParse((row['created_at'] ?? row['updated_at'] ?? '').toString());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Marketing Hub',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: _showQuickActions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            _buildWelcomeSection(),

            const SizedBox(height: 24),

            // Marketing Tools Grid
            _buildMarketingToolsGrid(),

            const SizedBox(height: 24),

            // Quick Stats
            _buildQuickStats(),

            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Marketing Hub',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Grow your business with powerful marketing tools',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Marketing tools active',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingToolsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Marketing Tools',
          style: TextStyle(
            fontSize: 20,
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
            childAspectRatio: 0.85,
          ),
          itemCount: _marketingTools.length,
          itemBuilder: (context, index) => _buildToolCard(_marketingTools[index]),
        ),
      ],
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    return GestureDetector(
      onTap: () => _navigateToTool(tool),
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (tool['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                tool['icon'] as IconData,
                color: tool['color'] as Color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tool['title'] as String,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              tool['description'] as String,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    final activeCampaigns = _campaigns
        .where((campaign) => campaign['status'] == 'active')
        .length;
    final totalImpressions = _campaigns.fold<int>(
      0,
      (total, campaign) => total + _intValue(campaign, 'impressions'),
    );
    final totalClicks = _campaigns.fold<int>(
      0,
      (total, campaign) => total + _intValue(campaign, 'clicks'),
    );
    final totalConversions = _campaigns.fold<int>(
      0,
      (total, campaign) => total + _intValue(campaign, 'conversions'),
    );
    final conversionRate = totalClicks == 0
        ? 0.0
        : totalConversions / totalClicks * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Stats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingData) const LinearProgressIndicator(),
        if (_dataError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Could not load all marketing data: $_dataError',
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active Campaigns',
                '$activeCampaigns',
                Icons.campaign,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Reach',
                NumberFormat.compact().format(totalImpressions),
                Icons.people,
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Conversion Rate',
                '${conversionRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                AppTheme.accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildRecentActivity() {
    final campaigns = [..._campaigns]
      ..sort((a, b) => (_recordDate(b) ?? DateTime(0))
          .compareTo(_recordDate(a) ?? DateTime(0)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Campaigns',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        if (campaigns.isEmpty)
          const Text(
            'No campaigns have been created yet.',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
        ...campaigns.take(4).map((campaign) {
          final date = _recordDate(campaign);
          return _buildActivityItem({
            'title': campaign['campaign_name']?.toString() ?? 'Campaign',
            'time': date == null
                ? campaign['status']?.toString() ?? ''
                : DateFormat('d MMM, h:mm a').format(date.toLocal()),
            'type': 'campaign',
          });
        }),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    IconData icon;
    Color color;

    switch (activity['type']) {
      case 'email':
        icon = Icons.email;
        color = AppTheme.accentColor;
        break;
      case 'social':
        icon = Icons.share;
        color = AppTheme.successColor;
        break;
      case 'segment':
        icon = Icons.group_work;
        color = AppTheme.warningColor;
        break;
      case 'referral':
        icon = Icons.card_giftcard;
        color = AppTheme.secondaryColor;
        break;
      case 'campaign':
        icon = Icons.campaign;
        color = AppTheme.primaryColor;
        break;
      default:
        icon = Icons.info;
        color = AppTheme.primaryColor;
    }

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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity['time'] as String,
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
  }

  void _navigateToTool(Map<String, dynamic> tool) {
    if (tool.containsKey('screen')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => tool['screen'] as Widget),
      );
    } else if (tool['action'] == 'social_flyer') {
      _showSocialFlyerModal();
    } else if (tool['action'] == 'flash_deals') {
      _showFlashDealsModal();
    } else if (tool['action'] == 'traditional') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Traditional print & billboard campaigns view')),
      );
    }
  }

  void _showSocialFlyerModal() {
    String selectedTemplate = 'Wedding Elegance';
    String customHeadline = '';
    String discountOffer = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Social Portfolio Flyer Generator',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Generate high-res branded story cards optimized for IG Stories, WhatsApp Status & TikTok.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 16),

                // Flyer Preview Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF312E81)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.stars, color: Colors.amberAccent, size: 20),
                              SizedBox(width: 6),
                              Text('EVENT-EASE VERIFIED', style: TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
                            child: Text(discountOffer, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        customHeadline.isEmpty ? 'Your campaign headline' : customHeadline,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Premium Photography & Cinematography Packages',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.qr_code_2, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Scan to View Portfolio & Book', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Choose Aesthetic Theme', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Wedding Elegance', 'Modern Luxe', 'Boho Chic', 'Corporate Minimal'].map((theme) {
                    final isSel = selectedTemplate == theme;
                    return ChoiceChip(
                      label: Text(theme),
                      selected: isSel,
                      onSelected: (val) => setModalState(() => selectedTemplate = theme),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Flyer copied and ready to share to Instagram Stories / WhatsApp!'), backgroundColor: Colors.green),
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share to IG & WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('High-res poster image saved to gallery!')),
                        );
                      },
                      icon: const Icon(Icons.download, color: AppTheme.primaryColor),
                      tooltip: 'Save Image',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFlashDealsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Flash Deals & Promo Codes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoadingData) const LinearProgressIndicator(),
              if (!_isLoadingData && _coupons.isEmpty)
                const Text('No active coupons found.'),
              ..._coupons.map((coupon) {
                final expiry = DateTime.tryParse(
                  coupon['expiry_date']?.toString() ?? '',
                );
                final discountValue =
                    (coupon['discount_value'] as num?)?.toDouble() ?? 0;
                final isPercentage = coupon['discount_type'] == 'percentage';
                final usageLimit = coupon['usage_limit'] as num?;
                final currentUsage = _intValue(coupon, 'current_usage');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildFlashDealCard(
                    title: coupon['code']?.toString() ?? 'Coupon',
                    discount: isPercentage
                        ? '${discountValue.toStringAsFixed(0)}% OFF'
                        : 'RM ${discountValue.toStringAsFixed(2)} OFF',
                    code: coupon['code']?.toString() ?? '',
                    timeLeft: expiry == null
                        ? 'No expiry date'
                        : 'Expires ${DateFormat('d MMM yyyy').format(expiry.toLocal())}',
                    claimed: usageLimit == null
                        ? '$currentUsage used'
                        : '$currentUsage / ${usageLimit.toInt()} used',
                    isActive: coupon['is_active'] == true,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlashDealCard({
    required String title,
    required String discount,
    required String code,
    required String timeLeft,
    required String claimed,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(6)),
                child: Text(discount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              Row(
                children: [
                  const Icon(Icons.timer, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(timeLeft, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Code: ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
                    child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
                  ),
                ],
              ),
              Text(claimed, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'New Campaign',
                    Icons.add,
                    AppTheme.primaryColor,
                    () {
                      Navigator.pop(context);
                      _showCreateCampaignDialog();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'Schedule Post',
                    Icons.schedule,
                    AppTheme.successColor,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VendorSocialMediaManagerScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    'Send Email',
                    Icons.email,
                    AppTheme.accentColor,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VendorEmailCampaignBuilderScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionButton(
                    'View Analytics',
                    Icons.analytics,
                    AppTheme.warningColor,
                    () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VendorMarketingAnalyticsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCampaignDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Campaign'),
        content: const Text('Choose the type of campaign you want to create'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VendorEmailCampaignBuilderScreen()),
              );
            },
            child: const Text('Email Campaign'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VendorSocialMediaManagerScreen()),
              );
            },
            child: const Text('Social Media'),
          ),
        ],
      ),
    );
  }


}
