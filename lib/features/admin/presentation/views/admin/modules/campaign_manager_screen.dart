import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AdminCampaignManagerScreen extends StatefulWidget {
  const AdminCampaignManagerScreen({super.key});

  @override
  State<AdminCampaignManagerScreen> createState() => _AdminCampaignManagerScreenState();
}

class _AdminCampaignManagerScreenState extends State<AdminCampaignManagerScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Campaign Manager'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => admin.refreshAllData(),
          ),
          IconButton(
            icon: const Icon(Icons.add_chart),
            onPressed: () => _showCreateCampaignOptions(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Promotions'),
            Tab(text: 'Advertisements'),
            Tab(text: 'Automations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(admin),
          _buildPromotionsTab(admin),
          _buildAdsTab(admin),
          _buildAutomationsTab(admin),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(AdminProvider admin) {
    final activePromos = admin.promotions.where((p) => p.status == 'active').length;
    final activeAds = admin.ads.where((a) => a.status == 'active').length;
    final totalSpent = admin.ads.fold<double>(0, (sum, ad) => sum + ad.spent);
    final totalBudget = admin.ads.fold<double>(0, (sum, ad) => sum + ad.budget);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Campaign Performance Overview', Icons.insights),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  'Active Campaigns',
                  '${activePromos + activeAds}',
                  Icons.campaign,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  'Total Budget',
                  'RM ${totalBudget.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  'Spent Today',
                  'RM ${(totalSpent / 30).toStringAsFixed(2)}', // Mocked daily average
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  'Conversions',
                  '${admin.bookings.length ~/ 10}', // Mocked
                  Icons.shopping_cart,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Live Ad Performance', Icons.ads_click),
          const SizedBox(height: 12),
          _buildPerformanceChart(admin),
          const SizedBox(height: 24),
          _buildSectionHeader('Top Performing Promotions', Icons.star),
          const SizedBox(height: 12),
          ...admin.promotions.take(3).map((p) => _buildPromoPerformanceRow(p)),
        ],
      ),
    );
  }

  Widget _buildPromotionsTab(AdminProvider admin) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: admin.promotions.length,
      itemBuilder: (context, index) {
        final promo = admin.promotions[index];
        return _buildCampaignCard(
          title: promo.title,
          subtitle: promo.description ?? 'No description',
          status: promo.status,
          type: 'PROMOTION',
          icon: Icons.local_offer,
          color: Colors.orange,
          metrics: [
            _buildMiniMetric('Discount', '${promo.discountPercent?.toStringAsFixed(0)}%'),
            _buildMiniMetric('Redeemed', '${promo.redemptions}'),
          ],
          onEdit: () {},
          onDelete: () => admin.deletePromotion(promo.id),
        );
      },
    );
  }

  Widget _buildAdsTab(AdminProvider admin) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: admin.ads.length,
      itemBuilder: (context, index) {
        final ad = admin.ads[index];
        return _buildCampaignCard(
          title: ad.title,
          subtitle: ad.advertiser,
          status: ad.status,
          type: 'ADVERTISEMENT',
          icon: Icons.ads_click,
          color: Colors.blue,
          metrics: [
            _buildMiniMetric('CTR', '${ad.ctr.toStringAsFixed(1)}%'),
            _buildMiniMetric('Spent', 'RM ${ad.spent.toStringAsFixed(0)}'),
          ],
          onEdit: () {},
          onDelete: () => admin.deleteAdEntry(ad.id),
        );
      },
    );
  }

  Widget _buildAutomationsTab(AdminProvider admin) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_fix_high, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Campaign Automations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Set up rules to automatically start/stop campaigns based on performance or inventory.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Create Rule'),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.grey, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceChart(AdminProvider admin) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final height = 50.0 + (index * 20.0 % 100);
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 30,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPromoPerformanceRow(Promotion promo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.orange.withOpacity(0.1),
            child: const Icon(Icons.local_offer, color: Colors.orange, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promo.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '${promo.redemptions} redemptions',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildCampaignCard({
    required String title,
    required String subtitle,
    required String status,
    required String type,
    required IconData icon,
    required Color color,
    required List<Widget> metrics,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final statusColor = status == 'active' ? Colors.green : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ...metrics,
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showCreateCampaignOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create New Campaign',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildCampaignOption(
                'New Promotion',
                'Discount codes, flash deals, and coupons.',
                Icons.local_offer,
                Colors.orange,
                () {},
              ),
              const SizedBox(height: 16),
              _buildCampaignOption(
                'New Advertisement',
                'Boost vendor listings in search results.',
                Icons.ads_click,
                Colors.blue,
                () {},
              ),
              const SizedBox(height: 16),
              _buildCampaignOption(
                'Blast Campaign',
                'Email and push notification broadcasts.',
                Icons.notifications_active,
                Colors.purple,
                () {},
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCampaignOption(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
