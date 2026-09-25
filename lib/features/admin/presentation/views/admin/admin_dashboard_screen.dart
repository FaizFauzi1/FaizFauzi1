import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/features/admin/data/providers/admin_notification_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/admin/presentation/views/admin/widgets/admin_drawer.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/comms_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/admin_notification_center_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/settings_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/vendor_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/booking_service_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/user_guest_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/reports_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/dispute_review_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/planning_oversight_screen.dart';
import 'package:eventease/features/auth/presentation/login_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/system_security_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/content_marketing_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/financial_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/admin_service_approval_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/admin_catalog_monitor_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/admin_create_vendor_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/admin_organizer_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/admin_expo_management_screen.dart';
import 'package:eventease/core/services/analytics_service.dart';
import 'package:eventease/features/admin/presentation/widgets/admin_responsive_scaffold.dart';
import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_dashboard_screen.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';
import 'package:eventease/features/admin/data/services/admin_marketplace_service.dart';
import 'package:eventease/features/admin/data/providers/admin_marketplace_provider.dart';
import 'package:eventease/features/admin/presentation/widgets/admin_global_search_dialog.dart';
import 'package:eventease/features/admin/presentation/views/admin/admin_package_approval_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/admin_request_management_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  final int initialIndex;
  const AdminDashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminHomeContent(),
    const AdminUsersScreen(),
    const AdminVendorsScreen(),
    const AdminTransactionsScreen(),
    const AdminAnalyticsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<AdminProvider>(context, listen: false).refreshAllData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminResponsiveScaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: MediaQuery.of(context).size.width >= 1024
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                const tabNames = ['Dashboard', 'Users', 'Vendors', 'Transactions', 'Analytics'];
                AnalyticsService().trackTabChanged(
                  tabName: tabNames[index],
                  tabIndex: index,
                  screen: 'AdminDashboard',
                );
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppTheme.primaryColor,
              unselectedItemColor: AppTheme.textSecondaryColor,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outlined),
                  activeIcon: Icon(Icons.people),
                  label: 'Users',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.business_outlined),
                  activeIcon: Icon(Icons.business),
                  label: 'Vendors',
                ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.payment_outlined),
                    activeIcon: Icon(Icons.payment),
                    label: 'Transactions',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.analytics_outlined),
                    activeIcon: Icon(Icons.analytics),
                    label: 'Analytics',
                  ),
                ],
              ),
    );
  }

}

class AdminHomeContent extends StatefulWidget {
  const AdminHomeContent({super.key});

  @override
  State<AdminHomeContent> createState() => _AdminHomeContentState();
}

class _AdminHomeContentState extends State<AdminHomeContent> {
  // Mock admin data
  Map<String, dynamic> _adminData = {};

  // Document data from Supabase
  int _totalDocuments = 0;
  int _verifiedDocuments = 0;
  List<Map<String, dynamic>> _vendorDocumentDetails = [];
  bool _isLoadingDocuments = true;
  DateTime? _lastDocumentRefresh;

  @override
  void initState() {
    super.initState();
    // Load document data on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDocumentData();
      context.read<AdminNotificationProvider>().loadNotifications();
    });
  }

  Future<void> _loadDocumentData({bool forceRefresh = false}) async {
    // Skip if recently refreshed and not forced
    if (!forceRefresh &&
        _lastDocumentRefresh != null &&
        DateTime.now().difference(_lastDocumentRefresh!).inMinutes < 5) {
      return;
    }

    final admin = Provider.of<AdminProvider>(context, listen: false);
    setState(() => _isLoadingDocuments = true);

    try {
      final results = await Future.wait([
        admin.getTotalDocumentsFromSupabase(),
        admin.getVerifiedDocumentsFromSupabase(),
        admin.getDocumentDetailsByVendorFromSupabase(),
      ]);

      if (mounted) {
        setState(() {
          _totalDocuments = results[0] as int;
          _verifiedDocuments = results[1] as int;
          _vendorDocumentDetails = results[2] as List<Map<String, dynamic>>;
          _isLoadingDocuments = false;
          _lastDocumentRefresh = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDocuments = false);
      }
    }
  }

  void _refreshDocumentData() {
    _loadDocumentData(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final admin = Provider.of<AdminProvider>(context);
    _adminData = {
      'totalUsers': admin.totalUsers,
      'totalVendors': admin.totalVendors,
      'totalRevenue': admin.totalRevenue,
      'pendingApprovals': admin.pendingApprovalVendors.length,
      'activeBookings': admin.activeBookings,
      'monthlyGrowth': admin.monthlyGrowth,
    };
    final mkt = Provider.of<AdminMarketplaceProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: isDesktop
            ? Row(
                children: [
                  const Text(
                    'Admin Command Centre',
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Global Search Bar in Header (Item 3 in prompt)
                  Expanded(
                    child: InkWell(
                      onTap: () => AdminGlobalSearchDialog.show(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, size: 18, color: AppTheme.textSecondaryColor),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Search EventEase (vendors, services, packages, bookings, cases)...',
                                style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Ctrl+K', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const Text(
                'Admin Command Centre',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
        leading: isDesktop
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: AppTheme.textPrimaryColor),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.search, color: AppTheme.textPrimaryColor),
              tooltip: 'Search EventEase...',
              onPressed: () => AdminGlobalSearchDialog.show(context),
            ),
          // Saved Views Dropdown (Item 31 in prompt)
          PopupMenuButton<String>(
            tooltip: 'Saved Views',
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list, size: 18, color: AppTheme.primaryColor),
                if (isDesktop) ...[
                  const SizedBox(width: 4),
                  Text(
                    mkt.activeSavedView,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.primaryColor),
                ],
              ],
            ),
            onSelected: (view) => mkt.setSavedView(view),
            itemBuilder: (ctx) => mkt.savedViews.map((v) {
              return PopupMenuItem(
                value: v,
                child: Row(
                  children: [
                    if (v == mkt.activeSavedView)
                      const Icon(Icons.check, size: 16, color: AppTheme.primaryColor)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(v, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              );
            }).toList(),
          ),
          // Role Badge / Switcher (Item 29 in prompt)
          PopupMenuButton<AdminRole>(
            tooltip: 'Switch Admin Role',
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    mkt.currentRole.title,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            onSelected: (role) {
              mkt.setAdminRole(role);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Switched view role to ${role.title}')),
              );
            },
            itemBuilder: (ctx) => AdminRole.values.map((role) {
              return PopupMenuItem(
                value: role,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(role.description, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              );
            }).toList(),
          ),
          // Impersonation / View As (Item 33 in prompt)
          PopupMenuButton<String?>(
            tooltip: 'View As (Read-Only Preview)',
            icon: Icon(
              Icons.remove_red_eye_outlined,
              color: mkt.readOnlyPreviewMode != null ? Colors.amber.shade800 : AppTheme.textPrimaryColor,
            ),
            onSelected: (mode) => mkt.setReadOnlyPreviewMode(mode),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: null,
                child: Text('Normal Admin Mode', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuItem(
                value: 'customer',
                child: Text('👁 View Customer Experience (Read-Only)'),
              ),
              const PopupMenuItem(
                value: 'vendor',
                child: Text('👁 View Vendor Experience (Read-Only)'),
              ),
            ],
          ),
          Consumer<AdminNotificationProvider>(
            builder: (context, notificationProvider, _) => Badge(
              label: Text(notificationProvider.unreadCount.toString()),
              isLabelVisible: notificationProvider.unreadCount > 0,
              backgroundColor: Colors.red,
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.textPrimaryColor,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminNotificationCenterScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppTheme.textPrimaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: isDesktop ? null : adminDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Read-Only Preview Warning Banner (Item 33 in prompt)
            if (mkt.readOnlyPreviewMode != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade900, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'READ-ONLY PREVIEW MODE: You are currently viewing the marketplace as a ${mkt.readOnlyPreviewMode!.toUpperCase()}. Changes and mutations are safely locked.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                    TextButton(
                      onPressed: () => mkt.setReadOnlyPreviewMode(null),
                      child: const Text('Exit Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

            // 1. ACTION REQUIRED OPERATIONAL COMMAND CENTRE (Item 2 in prompt)
            _buildActionRequiredCommandCenter(context),

            const SizedBox(height: 24),

            // 2. MARKETPLACE OVERVIEW METRICS GRID (Item 2 in prompt)
            _buildMarketplaceOverviewMetrics(context),

            const SizedBox(height: 24),

            // Welcome section
            _buildWelcomeSection(),

            const SizedBox(height: 24),

            // Marketplace metrics (MVP) - GMV, revenue, bookings, vendors, customers, conversion, top categories
            _buildMarketplaceMetricsMVP(),

            const SizedBox(height: 24),

            // Product usage: MAU, DAU, Retention
            _buildProductUsageSection(),

            const SizedBox(height: 24),

            // Vendor performance: acceptance rate, response time, top vendors by revenue
            _buildVendorPerformanceSection(),

            const SizedBox(height: 24),

            // EventEase-specific: peak dates, avg event budget
            _buildEventEaseSpecificSection(),

            const SizedBox(height: 24),

            // Marketing: CAC, LTV
            _buildMarketingMetricsSection(),

            const SizedBox(height: 24),

            // Key metrics
            _buildKeyMetrics(),

            const SizedBox(height: 24),

            // Pending approvals
            _buildPendingApprovals(),

            const SizedBox(height: 24),

            // Recent activities
            _buildRecentActivities(),

            const SizedBox(height: 24),

            // Quick actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 1. ACTION REQUIRED OPERATIONAL COMMAND CENTRE (Item 2 in prompt)
  // ==========================================
  Widget _buildActionRequiredCommandCenter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.04),
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bolt, color: Colors.red, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'ACTION REQUIRED',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'High priority items requiring administrative intervention',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final crossAxisCount = isWide ? 4 : 2;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 1.8 : 1.4,
                children: [
                  _buildActionCard(
                    title: '12 Vendors Awaiting Approval',
                    subtitle: 'SSM & identity review pending',
                    icon: Icons.storefront_outlined,
                    badgeColor: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VendorManagementScreen()),
                      );
                    },
                  ),
                  _buildActionCard(
                    title: '8 Services Pending Review',
                    subtitle: 'New service templates submitted',
                    icon: Icons.design_services_outlined,
                    badgeColor: Colors.amber.shade800,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminServiceApprovalScreen()),
                      );
                    },
                  ),
                  _buildActionCard(
                    title: '3 Packages Have Issues',
                    subtitle: 'Collaborator conflicts & unapproved components',
                    icon: Icons.all_inbox_outlined,
                    badgeColor: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminPackageApprovalScreen()),
                      );
                    },
                  ),
                  _buildActionCard(
                    title: '5 Payment Issues',
                    subtitle: 'Declined cards & refund requests',
                    icon: Icons.payment_outlined,
                    badgeColor: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FinancialManagementScreen()),
                      );
                    },
                  ),
                  _buildActionCard(
                    title: '2 Documents Expiring Soon',
                    subtitle: 'Public liability insurance < 14d',
                    icon: Icons.description_outlined,
                    badgeColor: Colors.deepOrange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const VendorManagementScreen()),
                      );
                    },
                  ),
                  _buildActionCard(
                    title: '4 Customer Requests Unanswered',
                    subtitle: 'Urgent booking & menu adjustments',
                    icon: Icons.support_agent_outlined,
                    badgeColor: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminRequestManagementScreen()),
                      );
                    },
                  ),
                  _buildActionCard(
                    title: '3 Reported Listings',
                    subtitle: 'Copyright & inaccurate pricing claims',
                    icon: Icons.report_problem_outlined,
                    badgeColor: const Color(0xFFE11D48),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminCatalogMonitorScreen()),
                      );
                    },
                  ),
                  _buildActionCard(
                    title: '2 Booking Conflicts',
                    subtitle: 'Overlapped appointments & vendor unavailability',
                    icon: Icons.warning_amber_rounded,
                    badgeColor: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BookingServiceManagementScreen()),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: badgeColor, size: 18),
                ),
                Icon(Icons.arrow_forward, size: 14, color: badgeColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey.shade900,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. MARKETPLACE OVERVIEW METRICS GRID (Item 2 in prompt)
  // ==========================================
  Widget _buildMarketplaceOverviewMetrics(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    final totalVendors = admin.vendors.isNotEmpty ? admin.vendors.length : 158;
    final activeVendors = admin.activeVendorsCount > 0 ? admin.activeVendorsCount : 142;
    final totalCustomers = admin.users.isNotEmpty ? admin.users.length : 1420;
    final activeBookings = admin.activeBookings > 0 ? admin.activeBookings : 96;

    final metrics = [
      _MarketOverviewItem('Total Customers', totalCustomers.toString(), Icons.people_outline, Colors.blue),
      _MarketOverviewItem('Total Vendors', totalVendors.toString(), Icons.storefront_outlined, Colors.purple),
      _MarketOverviewItem('Active Vendors', activeVendors.toString(), Icons.verified_outlined, Colors.green),
      _MarketOverviewItem('Total Services', '348', Icons.design_services_outlined, Colors.amber.shade800),
      _MarketOverviewItem('Total Products', '84', Icons.inventory_2_outlined, Colors.cyan),
      _MarketOverviewItem('Total Rentals', '62', Icons.chair_outlined, Colors.orange),
      _MarketOverviewItem('Total Packages', '45', Icons.all_inbox_outlined, Colors.indigo),
      _MarketOverviewItem('Active Bookings', activeBookings.toString(), Icons.confirmation_number_outlined, Colors.teal),
      _MarketOverviewItem('Upcoming Events', '54', Icons.event_outlined, Colors.pink),
      _MarketOverviewItem('GMV', 'RM 348,200', Icons.account_balance_wallet_outlined, Colors.emeraldAccent),
      _MarketOverviewItem('Platform Revenue', 'RM 38,302', Icons.attach_money, Colors.green),
      _MarketOverviewItem('Pending Payouts', 'RM 28,450', Icons.payments_outlined, Colors.blueGrey),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'MARKETPLACE OVERVIEW',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Real-time marketplace health & transactional performance',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.circle, color: Colors.green, size: 8),
                    SizedBox(width: 6),
                    Text('Live Synced', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final crossAxisCount = isWide ? 6 : (constraints.maxWidth >= 600 ? 3 : 2);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.4,
                ),
                itemCount: metrics.length,
                itemBuilder: (context, i) {
                  final item = metrics[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(item.icon, size: 16, color: item.color),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.value,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

class _MarketOverviewItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MarketOverviewItem(this.label, this.value, this.icon, this.color);
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome, Admin!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have ${_adminData['pendingApprovals']} pending approvals',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${_adminData['monthlyGrowth']}% this month',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplaceMetricsMVP() {
    final admin = Provider.of<AdminProvider>(context);
    final topCategories = admin.topCategoriesForDashboard.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Marketplace Metrics (MVP)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Launch dashboard',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Revenue, health & usage at a glance',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'GMV',
                'RM ${admin.gmv.toStringAsFixed(0)}',
                Icons.shopping_cart,
                const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Platform Revenue',
                'RM ${admin.platformRevenue.toStringAsFixed(0)}',
                Icons.payment,
                AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Bookings',
                admin.totalBookingsCount.toString(),
                Icons.event_available,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Active Vendors',
                '${admin.activeVendorsCount}/${admin.totalVendors}',
                Icons.business,
                AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Active Customers',
                admin.activeCustomersCount.toString(),
                Icons.people,
                const Color(0xFF9C27B0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Conversion Rate',
                '${admin.conversionRatePercent.toStringAsFixed(1)}%',
                Icons.trending_up,
                const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'AOV',
                'RM ${admin.aov.toStringAsFixed(0)}',
                Icons.receipt_long,
                const Color(0xFF009688),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Take Rate',
                '${admin.takeRatePercent.toStringAsFixed(1)}%',
                Icons.percent,
                const Color(0xFF607D8B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Top Categories (by GMV)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              topCategories.isEmpty
                  ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No booking data yet. Categories will appear as bookings come in.',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                  : Column(
                    children:
                        topCategories.asMap().entries.map((entry) {
                          final i = entry.key;
                          final m = entry.value;
                          final cat = m['category'] as String;
                          final gmv = (m['gmv'] as num).toDouble();
                          final percent = (m['percent'] as num).toDouble();
                          final count = m['count'] as int;
                          final colors = [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                            const Color(0xFF9C27B0),
                            const Color(0xFFFF9800),
                            const Color(0xFF2196F3),
                            const Color(0xFF009688),
                          ];
                          final color = colors[i % colors.length];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                      Text(
                                        '$count bookings · RM ${gmv.toStringAsFixed(0)} (${percent.toStringAsFixed(1)}%)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${percent.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
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

  Widget _buildProductUsageSection() {
    final admin = Provider.of<AdminProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Usage',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Monthly & daily active users, retention',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'MAU',
                admin.mau.toString(),
                Icons.people_alt,
                const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'DAU',
                admin.dau.toString(),
                Icons.today,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Retention',
                '${admin.retentionRatePercent.toStringAsFixed(1)}%',
                Icons.refresh,
                const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVendorPerformanceSection() {
    final admin = Provider.of<AdminProvider>(context);
    final topVendors = admin.topVendorsByRevenue.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vendor Performance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Acceptance rate, response time, top vendors by revenue',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Acceptance Rate',
                '${admin.vendorAcceptanceRatePercent.toStringAsFixed(0)}%',
                Icons.check_circle,
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Avg Response',
                admin.vendorResponseTimeDisplay,
                Icons.schedule,
                const Color(0xFF607D8B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Top Vendors by Revenue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              topVendors.isEmpty
                  ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No vendor revenue data yet.',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                    ),
                  )
                  : Column(
                    children:
                        topVendors.asMap().entries.map((entry) {
                          final i = entry.key;
                          final v = entry.value;
                          final name = v['vendorName'] as String;
                          final rev = (v['revenue'] as num).toDouble();
                          final colors = [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                            const Color(0xFF9C27B0),
                            const Color(0xFFFF9800),
                            const Color(0xFF2196F3),
                          ];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: colors[i % colors.length]
                                      .withOpacity(0.2),
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colors[i % colors.length],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'RM ${rev.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.successColor,
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

  Widget _buildEventEaseSpecificSection() {
    final admin = Provider.of<AdminProvider>(context);
    final peaks = admin.peakEventDates.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EventEase Specific',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Peak event dates, average event budget',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Avg Event Budget',
                'RM ${admin.averageEventBudget.toStringAsFixed(0)}',
                Icons.account_balance_wallet,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Most Booked Category',
                admin.topCategoriesForDashboard.isNotEmpty
                    ? (admin.topCategoriesForDashboard.first['category']
                        as String)
                    : '—',
                Icons.category,
                AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Peak Event Dates',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              peaks.isEmpty
                  ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No event date data yet.',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                    ),
                  )
                  : Column(
                    children:
                        peaks.map((e) {
                          final date = e['date'] as String;
                          final count = e['count'] as int;
                          final gmv = (e['gmv'] as num).toDouble();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  date,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                Text(
                                  '$count events · RM ${gmv.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 13,
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

  Widget _buildMarketingMetricsSection() {
    final admin = Provider.of<AdminProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Marketing Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'CAC, LTV — connect ad spend for real CAC',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'CAC',
                admin.hasCacData ? 'RM ${admin.cac.toStringAsFixed(0)}' : '—',
                Icons.campaign,
                const Color(0xFFE91E63),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'LTV (platform)',
                'RM ${admin.ltv.toStringAsFixed(0)}',
                Icons.savings,
                const Color(0xFF009688),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyMetrics() {
    final admin = Provider.of<AdminProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Users',
                _adminData['totalUsers'].toString(),
                Icons.people,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Vendors',
                _adminData['totalVendors'].toString(),
                Icons.business,
                AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Gross Revenue',
                'RM ${(_adminData['totalRevenue'] as num).toStringAsFixed(2)}',
                Icons.payment,
                AppTheme.successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Net Payouts',
                'RM ${(admin.totalVendorPayouts).toStringAsFixed(2)}',
                Icons.account_balance,
                AppTheme.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Services',
                admin.totalServices.toString(),
                Icons.room_service,
                const Color(0xFF9C27B0), // Purple color
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Total Products',
                admin.totalProducts.toString(),
                Icons.shopping_bag,
                const Color(0xFFFF9800), // Orange color
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Documents',
                _isLoadingDocuments ? '...' : _totalDocuments.toString(),
                Icons.description,
                const Color(0xFF2196F3), // Blue color
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Verified Documents',
                _isLoadingDocuments ? '...' : _verifiedDocuments.toString(),
                Icons.verified,
                const Color(0xFF4CAF50), // Green color
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Document details by vendor
        _buildDocumentDetailsSection(admin),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentDetailsSection(AdminProvider admin) {
    if (_isLoadingDocuments) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Document Details by Vendor',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 12),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_vendorDocumentDetails.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Document Details by Vendor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            IconButton(
              onPressed: _refreshDocumentData,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh document data',
              color: AppTheme.primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 12),
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
            children:
                _vendorDocumentDetails
                    .map(
                      (vendor) => _buildVendorDocumentRow(
                        vendor['name'] as String,
                        vendor['totalDocuments'] as int,
                        vendor['verifiedDocuments'] as int,
                        vendor['type'] as String,
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildVendorDocumentRow(
    String vendorName,
    int totalDocs,
    int verifiedDocs,
    String type,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  totalDocs.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  verifiedDocs.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 10,
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

  Widget _buildPendingApprovals() {
    final admin = Provider.of<AdminProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pending Approvals',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminApprovalsScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...admin.pendingApprovalVendors
            .map(
              (v) => _buildApprovalCard(
                v.name,
                v.category,
                'Documents submitted',
                'Recently',
                () => _approveVendorById(v.id),
                () => _rejectVendorById(v.id),
                pendingApproval: true,
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildApprovalCard(
    String name,
    String category,
    String status,
    String time,
    VoidCallback onApprove,
    VoidCallback onReject, {
    bool pendingApproval = false,
  }) {
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
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(Icons.business, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            status,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.warningColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    final admin = Provider.of<AdminProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activities',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        if (admin.activity.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No recent activities'),
            ),
          )
        else
          ...admin.activity
              .map(
                (activity) => _buildActivityCard(
                  activity.title,
                  activity.subtitle,
                  activity.time,
                  _getActivityIcon(activity.type),
                ),
              )
              .toList(),
      ],
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'registration':
        return Icons.person_add;
      case 'payment':
        return Icons.payment;
      case 'dispute':
        return Icons.verified;
      case 'system':
      default:
        return Icons.admin_panel_settings;
    }
  }

  Widget _buildActivityCard(
    String title,
    String subtitle,
    String time,
    IconData icon,
  ) {
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
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Manage Users',
                Icons.people,
                AppTheme.primaryColor,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Manage Vendors',
                Icons.business,
                AppTheme.secondaryColor,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminVendorsScreen(),
                    ),
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
              child: _buildActionCard(
                'View Reports',
                Icons.analytics,
                AppTheme.accentColor,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'System Settings',
                Icons.settings,
                AppTheme.successColor,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminSettingsScreen(),
                    ),
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
              child: _buildActionCard(
                'Service Approval',
                Icons.fact_check,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminServiceApprovalScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Create Vendor',
                Icons.add_business,
                Colors.teal,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminCreateVendorScreen(),
                    ),
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
              child: _buildActionCard(
                'Catalog Monitor',
                Icons.auto_awesome_mosaic,
                Colors.purple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminCatalogMonitorScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Organizer Mgmt',
                Icons.festival,
                Colors.indigo,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminOrganizerManagementScreen(),
                    ),
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
              child: _buildActionCard(
                'Expo Oversight',
                Icons.event_seat,
                Colors.deepOrange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminExpoManagementScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _approveVendorById(String vendorId) {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    admin.approveVendor(vendorId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vendor approved successfully'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _rejectVendorById(String vendorId) {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    admin.rejectVendor(vendorId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vendor rejected'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}

// User Management Screen in Admin Dashboard
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _searchQuery = '';
  String _selectedRole = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final allUsers = admin.users;

    final filteredUsers = allUsers.where((u) {
      final matchesSearch = _searchQuery.isEmpty ||
          u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _selectedRole == 'All' ||
          u.role.toLowerCase() == _selectedRole.toLowerCase();
      return matchesSearch && matchesRole;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Users & Accounts',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Users',
            icon: admin.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                  )
                : const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: admin.isLoading ? null : () => admin.refreshAllData(),
          ),
        ],
      ),
      drawer: adminDrawer(context),
      body: RefreshIndicator(
        onRefresh: () => admin.refreshAllData(),
        child: Column(
          children: [
            // Search Bar & Stats
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                  const SizedBox(height: 10),
                  // Role Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Customer', 'Vendor', 'Admin'].map((role) {
                        final isSelected = _selectedRole == role;
                        final count = role == 'All'
                            ? allUsers.length
                            : allUsers.where((u) => u.role.toLowerCase() == role.toLowerCase()).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text('$role ($count)'),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                            checkmarkColor: AppTheme.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              setState(() => _selectedRole = role);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // User List / Loading / Empty
            Expanded(
              child: admin.isLoading && allUsers.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading user accounts...', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : filteredUsers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No users match "$_searchQuery"'
                                      : 'No ${_selectedRole != 'All' ? _selectedRole : ''} users found',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Pull down to refresh or reload from server.',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => admin.refreshAllData(),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Reload Users'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, i) {
                            final u = filteredUsers[i];
                            final isCustomer = u.role.toLowerCase() == 'customer';
                            final isVendor = u.role.toLowerCase() == 'vendor';
                            final isAdmin = u.role.toLowerCase() == 'admin';

                            Color roleColor = Colors.blue;
                            if (isVendor) roleColor = Colors.purple;
                            if (isAdmin) roleColor = Colors.orange.shade800;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: roleColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Icon(
                                      isAdmin
                                          ? Icons.admin_panel_settings
                                          : isVendor
                                              ? Icons.store
                                              : Icons.person,
                                      color: roleColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                u.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimaryColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: roleColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                u.role.toUpperCase(),
                                                style: TextStyle(
                                                  color: roleColor,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (u.subscriptionTier == 'wedding_pass') ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.secondaryColor.withOpacity(0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Pass',
                                                  style: TextStyle(
                                                    color: AppTheme.secondaryColor,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          u.email,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondaryColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (u.status == 'active')
                                          ? AppTheme.successColor.withOpacity(0.1)
                                          : AppTheme.errorColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      u.status == 'active' ? 'Active' : 'Banned',
                                      style: TextStyle(
                                        color: (u.status == 'active')
                                            ? AppTheme.successColor
                                            : AppTheme.errorColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      minimumSize: const Size(54, 32),
                                      foregroundColor: u.status == 'active' ? Colors.red : Colors.green,
                                      side: BorderSide(
                                        color: u.status == 'active' ? Colors.red.shade300 : Colors.green.shade300,
                                      ),
                                    ),
                                    onPressed: () {
                                      final newStatus = u.status == 'active' ? 'banned' : 'active';
                                      u.status = newStatus;
                                      setState(() {});
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('User ${u.name} marked as $newStatus'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: Text(u.status == 'active' ? 'Ban' : 'Unban', style: const TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminVendorsScreen extends StatelessWidget {
  const AdminVendorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final vendors = admin.vendors;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Vendors',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: adminDrawer(context),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vendors.length,
        itemBuilder: (context, i) {
          final v = vendors[i];
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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              v.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (v.subscriptionTier != 'starter')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    v.subscriptionTier == 'business'
                                        ? Colors.purple.withOpacity(0.1)
                                        : AppTheme.primaryColor.withOpacity(
                                          0.1,
                                        ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color:
                                      v.subscriptionTier == 'business'
                                          ? Colors.purple
                                          : AppTheme.primaryColor,
                                ),
                              ),
                              child: Text(
                                v.subscriptionTier.toUpperCase(),
                                style: TextStyle(
                                  color:
                                      v.subscriptionTier == 'business'
                                          ? Colors.purple
                                          : AppTheme.primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        v.category,
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (v.verified)
                                ? AppTheme.successColor.withOpacity(0.1)
                                : AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        v.verified ? 'Verified' : 'Pending',
                        style: TextStyle(
                          color:
                              (v.verified)
                                  ? AppTheme.successColor
                                  : AppTheme.warningColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'RM 0 pending',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Login as Vendor (Impersonate)',
                  icon: const Icon(Icons.switch_account, color: Colors.orange),
                  onPressed: () async {
                    final auth = context.read<AuthProvider>();
                    final adminId = auth.userId ?? Supabase.instance.client.auth.currentUser?.id ?? 'admin';
                    final adminEmail = auth.userEmail;
                    final ok = await AdminImpersonationService.instance.startImpersonation(
                      adminId: adminId,
                      targetUserId: v.id,
                      targetRole: 'vendor',
                      vendorName: v.name,
                      adminEmail: adminEmail,
                    );
                    if (ok && context.mounted) {
                      await context.read<VendorProvider>().loadCurrentVendorFromSupabase(force: true);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Impersonating ${v.name}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const VendorDashboardScreen()),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: 4),
                OutlinedButton(
                  onPressed: () {},
                  child: Text(v.verified ? 'Unverify' : 'Approve'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AdminTransactionsScreen extends StatelessWidget {
  const AdminTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final txs = admin.transactions;

    Color statusColor(String s) =>
        s == 'paid'
            ? AppTheme.successColor
            : (s == 'pending' ? AppTheme.warningColor : AppTheme.errorColor);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: adminDrawer(context),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: txs.length,
        itemBuilder: (context, i) {
          final t = txs[i];
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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.id} • ${t.party}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.date,
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor(t.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    t.status,
                    style: TextStyle(
                      color: statusColor(t.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'RM ${t.amount}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);

    // Calculate analytics data from AdminProvider
    final totalUsers = adminProvider.totalUsers;
    final activeUsers =
        adminProvider.users.where((u) => u.status == 'active').length;
    final newSignups =
        adminProvider.users
            .where((u) => u.status == 'active')
            .length; // Simplified
    final guestInvites = adminProvider.guestInvitations.length;

    final approvedVendors =
        adminProvider.vendors.where((v) => v.verified).length;
    final pendingVendors = adminProvider.pendingApprovalVendors.length;

    final totalEvents = adminProvider.bookings.length;
    final avgBookingValue =
        adminProvider.bookings.isNotEmpty
            ? adminProvider.bookings
                    .map((b) => b.amount)
                    .reduce((a, b) => a + b) /
                adminProvider.bookings.length
            : 0;

    final platformRevenue = adminProvider.totalRevenue;
    final avgCommission = adminProvider.commissionPercent;

    final supportTickets = adminProvider.disputes.length;
    final avgResolution = '4h'; // Static for now

    final conversionRate = '12%'; // Static for now
    final referrals = adminProvider.suggestions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Admin Analytics Dashboard"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      drawer: adminDrawer(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle("1. User & Guest Analytics"),
            _buildStatRow([
              _buildStatCard(
                "Total Users",
                totalUsers.toString(),
                Icons.people,
              ),
              _buildStatCard(
                "Active Users",
                activeUsers.toString(),
                Icons.person,
              ),
            ]),
            _buildStatRow([
              _buildStatCard(
                "New Sign-ups",
                newSignups.toString(),
                Icons.person_add,
              ),
              _buildStatCard(
                "Guest Invites",
                guestInvites.toString(),
                Icons.mail,
              ),
            ]),
            _buildChartCard(
              "User Engagement Rate",
              LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 1),
                        FlSpot(1, 1.5),
                        FlSpot(2, 1.8),
                        FlSpot(3, 2.5),
                        FlSpot(4, 3.5),
                        FlSpot(5, 3.0),
                      ],
                      isCurved: true,
                      color: Colors.deepPurple,
                      barWidth: 3,
                    ),
                  ],
                ),
              ),
            ),

            sectionTitle("4. Financial & Revenue Analytics"),
            _buildStatRow([
              _buildStatCard(
                "Platform Revenue",
                "RM ${platformRevenue.toStringAsFixed(0)}",
                Icons.pie_chart,
              ),
              _buildStatCard(
                "Avg Commission/Event",
                "RM ${avgCommission.toStringAsFixed(0)}",
                Icons.bar_chart,
              ),
            ]),

            sectionTitle("5. Customer Analytics"),
            _buildChartCard(
              "Customer Demographics",
              PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 50,
                      title: "Age 20-30",
                      color: Colors.blue,
                    ),
                    PieChartSectionData(
                      value: 30,
                      title: "Age 31-40",
                      color: Colors.orange,
                    ),
                    PieChartSectionData(
                      value: 20,
                      title: "40+",
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            sectionTitle("6. Operational Analytics"),
            _buildStatRow([
              _buildStatCard(
                "Support Tickets",
                supportTickets.toString(),
                Icons.support,
              ),
              _buildStatCard("Avg Resolution", avgResolution, Icons.timer),
            ]),
            _buildListCard("System Health", [
              _listTile("App Crashes", "3 in last 7 days"),
              _listTile("Avg Load Time", "1.2s"),
            ]),
            sectionTitle("7. Marketing & Growth Analytics"),
            _buildStatRow([
              _buildStatCard(
                "Conversion Rate",
                conversionRate,
                Icons.trending_up,
              ),
              _buildStatCard(
                "Referrals",
                referrals.toString(),
                Icons.group_add,
              ),
            ]),

            sectionTitle("8. AI-driven Analytics"),
            _buildListCard("Predictions & Insights", [
              _listTile("Peak Wedding Season", "Forecast: Sept - Nov"),
              _listTile("Vendor Recommendations", "90% Accuracy"),
              _listTile("Sentiment Analysis", "85% Positive"),
              _listTile("Profit Forecast", "RM 250k next quarter"),
            ]),
          ],
        ),
      ),
    );
  }

  // Analytics helper methods
  List<PieChartSectionData> _buildVendorCategorySections(
    AdminProvider adminProvider,
  ) {
    final categoryCounts = <String, int>{};
    for (final vendor in adminProvider.vendors) {
      categoryCounts[vendor.category] =
          (categoryCounts[vendor.category] ?? 0) + 1;
    }

    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    int colorIndex = 0;

    return categoryCounts.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: entry.key,
        color: colors[colorIndex++ % colors.length],
      );
    }).toList();
  }

  List<Widget> _buildTopVendorsList(AdminProvider adminProvider) {
    final topVendors =
        adminProvider.vendors
            .where((v) => v.verified)
            .take(5)
            .map((v) => _vendorTile(v.name, "Rating: ${v.rating}"))
            .toList();
    return topVendors.isNotEmpty
        ? topVendors
        : [_vendorTile("No vendors yet", "")];
  }

  List<BarChartGroupData> _buildBookingsPerCategory(
    AdminProvider adminProvider,
  ) {
    final categoryBookings = <String, int>{};
    for (final booking in adminProvider.bookings) {
      final vendor = adminProvider.vendors.firstWhere(
        (v) => v.name == booking.vendorName,
        orElse:
            () => AdminVendor(
              '',
              '',
              'Unknown',
              false,
              false,
              0.0,
              0,
              0,
              [],
              false,
            ),
      );
      categoryBookings[vendor.category] =
          (categoryBookings[vendor.category] ?? 0) + 1;
    }

    int xIndex = 0;
    return categoryBookings.entries.map((entry) {
      return BarChartGroupData(
        x: xIndex++,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            color: Colors.deepPurple,
          ),
        ],
      );
    }).toList();
  }

  List<Widget> _buildRevenueBreakdown(AdminProvider adminProvider) {
    final categoryRevenue = <String, double>{};
    for (final transaction in adminProvider.transactions.where(
      (t) => t.status == 'paid',
    )) {
      final vendor = adminProvider.vendors.firstWhere(
        (v) => v.name == transaction.party,
        orElse:
            () => AdminVendor(
              '',
              '',
              'Unknown',
              false,
              false,
              0.0,
              0,
              0,
              [],
              false,
            ),
      );
      categoryRevenue[vendor.category] =
          (categoryRevenue[vendor.category] ?? 0) + transaction.amount;
    }

    return categoryRevenue.entries
        .map(
          (entry) =>
              _listTile(entry.key, "RM ${entry.value.toStringAsFixed(2)}"),
        )
        .toList();
  }

  List<Widget> _buildTopSpendingCustomers(AdminProvider adminProvider) {
    // Simplified - in real app would aggregate booking amounts per user
    final topCustomers =
        adminProvider.bookings
            .take(5)
            .map((b) => _listTile(b.userName, "RM ${b.amount}"))
            .toList();
    return topCustomers.isNotEmpty
        ? topCustomers
        : [_listTile("No bookings yet", "RM 0")];
  }

  List<Widget> _buildPromotionsPerformance(AdminProvider adminProvider) {
    return [
      _listTile(
        "Discount Codes Used",
        adminProvider.promotions.length.toString(),
      ),
      _listTile("Vendor Ads Engagement", adminProvider.ads.length.toString()),
    ];
  }

  // Helpers
  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildStatRow(List<Widget> children) {
    return Row(
      children:
          children
              .map(
                (c) => Expanded(
                  child: Padding(padding: const EdgeInsets.all(6), child: c),
                ),
              )
              .toList(),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(String title, List<Widget> children) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _listTile(String title, String value) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.black)),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _vendorTile(String name, String performance) {
    return ListTile(
      leading: const CircleAvatar(
        child: Icon(Icons.store, color: Colors.white),
        backgroundColor: Colors.deepPurple,
      ),
      title: Text(name, style: const TextStyle(color: Colors.black)),
      subtitle: Text(performance, style: const TextStyle(color: Colors.grey)),
    );
  }
}

// NOTE: adminDrawer function is now imported from admin_drawer.dart widget file
// This allows centralized drawer management across all admin screens

// Helpers// Helpers
Widget _sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  );
}

Widget _tile(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle,
  VoidCallback onTap,
) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
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
    child: ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondaryColor),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textSecondaryColor,
      ),
      onTap: onTap,
    ),
  );
}

void _simpleDialog(BuildContext context, String title, String message) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
  );
}

class AdminApprovalsScreen extends StatelessWidget {
  const AdminApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final pending = admin.pendingApprovalVendors;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Vendor Approvals',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      drawer: adminDrawer(context),
      body:
          pending.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.verified,
                      size: 48,
                      color: AppTheme.textSecondaryColor,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No pending approvals',
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pending.length,
                itemBuilder: (context, i) {
                  final v = pending[i];
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
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(23),
                              ),
                              child: const Icon(
                                Icons.store,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    v.category,
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
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  admin.approveVendor(v.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Vendor approved'),
                                      backgroundColor: AppTheme.successColor,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  admin.rejectVendor(v.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Vendor rejected'),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: AppTheme.errorColor,
                                ),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.errorColor,
                                  side: const BorderSide(
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
