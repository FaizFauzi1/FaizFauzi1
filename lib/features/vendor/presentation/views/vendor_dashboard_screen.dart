import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/finance/data/providers/commission_provider.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_document_management_screen_fixed.dart';
import 'package:eventease/features/vendor/presentation/widgets/vendor_drawer.dart';
import 'package:eventease/features/vendor/presentation/widgets/vendor_responsive_scaffold.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/customer/data/providers/review_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_networking_provider.dart';
import 'package:eventease/shared/models/vendor_marketplace_item.dart';
import 'package:eventease/shared/models/services/service_review.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_booking_management_screen_fixed.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_review_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_availability_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_chat_screen.dart';
import 'package:eventease/features/vendor/presentation/views/coupon_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_service_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_analytics_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_profile_screen.dart';
import 'package:eventease/features/vendor/data/providers/vendor_analytics_provider.dart';
import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_order_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/vendor_services_hub_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/vendor_packages_hub_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/vendor_unified_calendar_screen.dart';
import 'package:eventease/features/vendor/presentation/views/enhanced_service_creation_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_catalog_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_notifications_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_settings_screen_enhanced.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_event_checkin_screen.dart';
import 'package:eventease/features/vendor/presentation/widgets/vendor_setup_checklist.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/services/analytics_service.dart';
import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';

class VendorDashboardScreen extends StatefulWidget {
  final Vendor? previewVendor;

  const VendorDashboardScreen({super.key, this.previewVendor});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  int _currentIndex = 0;
  String? _cachedVendorId;
  List<Widget> _screens = const [];

  List<Widget> _screensFor(Vendor? vendor) {
    final id = vendor?.id;
    if (_screens.isNotEmpty && _cachedVendorId == id) return _screens;
    _cachedVendorId = id;
    _screens = [
      VendorHomeContent(
        onTabChange: (index) => setState(() => _currentIndex = index),
        previewVendor: widget.previewVendor,
      ),
      vendor != null
          ? VendorBookingManagementScreenFixed(
            vendor: vendor,
            embeddedInDashboard: true,
          )
          : const Center(child: CircularProgressIndicator()),
      vendor != null
          ? VendorServiceManagementScreen(vendor: vendor)
          : const Center(child: CircularProgressIndicator()),
      const VendorChatScreen(embeddedInDashboard: true),
      const VendorProfileScreen(),
    ];
    return _screens;
  }

  @override
  void initState() {
    super.initState();
    if (widget.previewVendor == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<VendorProvider>(
          context,
          listen: false,
        ).loadCurrentVendorFromSupabase(force: true);
      });
    }
  }

  Widget _buildImpersonationBanner(BuildContext context, dynamic vendor) {
    final impersonation = AdminImpersonationService.instance;
    final vendorName =
        vendor?.name ??
        impersonation.impersonatingVendorName ??
        impersonation.impersonatingUserId ??
        'Vendor';
    final adminInfo =
        impersonation.originalAdminEmail != null &&
                impersonation.originalAdminEmail!.isNotEmpty
            ? 'Admin: ${impersonation.originalAdminEmail}'
            : 'Admin Mode';

    return Material(
      color: Colors.amber.shade900,
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.security,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'IMPERSONATION ACTIVE',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Viewing as: $vendorName ($adminInfo)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.amber.shade900,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () async {
                  await AdminImpersonationService.instance.endImpersonation();
                  if (context.mounted) {
                    Provider.of<VendorProvider>(
                      context,
                      listen: false,
                    ).clearCurrentVendor();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Returned to Admin Control Panel'),
                        backgroundColor: Colors.indigo,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.exit_to_app, size: 14),
                label: const Text(
                  'Exit',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabTap(int index) {
    const tabNames = ['Dashboard', 'Bookings', 'Management', 'Messages', 'Profile'];
    AnalyticsService().trackTabChanged(
      tabName: tabNames[index],
      tabIndex: index,
      screen: 'VendorDashboard',
    );
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final vendor =
        widget.previewVendor ??
        Provider.of<VendorProvider>(context).currentVendor;
    final screens = _screensFor(vendor);

    return ListenableBuilder(
      listenable: AdminImpersonationService.instance,
      builder: (context, child) {
        final isImpersonating =
            AdminImpersonationService.instance.isImpersonating;
        return Scaffold(
          body: Column(
            children: [
              if (isImpersonating) _buildImpersonationBanner(context, vendor),
              Expanded(
                child: IndexedStack(index: _currentIndex, children: screens),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              const tabNames = [
                'Dashboard',
                'Bookings',
                'Management',
                'Messages',
                'Profile',
              ];
              AnalyticsService().trackTabChanged(
                tabName: tabNames[index],
                tabIndex: index,
                screen: 'VendorDashboard',
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
                icon: Icon(Icons.book_online_outlined),
                activeIcon: Icon(Icons.book_online),
                label: 'Bookings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.business_center_outlined),
                activeIcon: Icon(Icons.business_center),
                label: 'Management',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_outlined),
                activeIcon: Icon(Icons.chat),
                label: 'Messages',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class VendorHomeContent extends StatefulWidget {
  final Function(int)? onTabChange;
  final Vendor? previewVendor;

  const VendorHomeContent({super.key, this.onTabChange, this.previewVendor});

  @override
  State<VendorHomeContent> createState() => _VendorHomeContentState();
}

class _VendorHomeContentState extends State<VendorHomeContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() async {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);

    // First check if we have a current user but no vendor
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (widget.previewVendor == null &&
        currentUser != null &&
        vendorProvider.currentVendor == null) {
      await vendorProvider.loadCurrentVendorFromSupabase(force: true);
    }

    final vendor = widget.previewVendor ?? vendorProvider.currentVendor;
    if (vendor != null && mounted) {
      // Load related data in parallel
      Future.wait([
        Provider.of<ReviewProvider>(
          context,
          listen: false,
        ).loadReviewsForVendor(vendor.id),
        Provider.of<BookingProvider>(
          context,
          listen: false,
        ).loadVendorBookings(vendor.id),
        Provider.of<VendorAnalyticsProvider>(
          context,
          listen: false,
        ).loadAnalyticsData(),
        Provider.of<VendorProfileProvider>(context, listen: false).loadVendorProfile(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);
    final vendor = widget.previewVendor ?? vendorProvider.currentVendor;
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final List<ServiceReview> reviews =
        vendor != null
            ? List<ServiceReview>.from(
              reviewProvider.getReviewsForVendor(vendor.id),
            )
            : [];

    double avgRating =
        reviews.isEmpty
            ? 0.0
            : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                reviews.length;

    final bookingProvider = Provider.of<BookingProvider>(context);
    final bookings = bookingProvider.vendorBookings;
    final totalBookings = bookings.length;
    final pendingBookings =
        bookings.where((b) => b.status == BookingStatus.pendingVendor).length;
    final confirmedBookings = bookings.where(
      (b) =>
          b.status == BookingStatus.confirmed ||
          b.status == BookingStatus.completed,
    );
    final monthlyRevenue = confirmedBookings.fold(
      0.0,
      (sum, b) => sum + b.amount,
    );

    // Dynamic metrics
    final totalCompleted =
        bookings.where((b) => b.status == BookingStatus.completed).length;
    final totalConfirmed =
        bookings.where((b) => b.status == BookingStatus.confirmed).length;
    final completionRate =
        totalBookings > 0
            ? '${((totalCompleted + totalConfirmed) / totalBookings * 100).toStringAsFixed(0)}%'
            : '100%';

    final searchVisibility =
        vendor != null
            ? '+${(vendor.priorityScore * 10).toStringAsFixed(0)}%'
            : '0%';

    // Calculate response rate from confirmed vs total bookings
    final responseRate =
        totalBookings > 0
            ? '${((totalConfirmed + totalCompleted) / totalBookings * 100).clamp(0, 100).toStringAsFixed(0)}%'
            : '0%';
    final activeServices =
        vendor == null
            ? <VendorServiceEnhanced>[]
            : vendorProvider.getCurrentVendorServicesForId(vendor.id);
    final analyticsProvider = Provider.of<VendorAnalyticsProvider>(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final contentPadding = ResponsiveUtils.getScreenPadding(context);

        if (vendorProvider.isLoading && vendor == null) {
          return const Center(child: CircularProgressIndicator());
        }

        Widget mainCards;
        if (isWide) {
          mainCards = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _buildRevenueOverviewCard(bookings, monthlyRevenue, analyticsProvider),
                    const SizedBox(height: 16),
                    _buildInquiryAndQuoteMetrics(analyticsProvider),
                    const SizedBox(height: 16),
                    _buildConversionFunnelPreview(analyticsProvider),
                    const SizedBox(height: 16),
                    _buildActiveServicesSection(activeServices),
                    const SizedBox(height: 16),
                    _buildPerformanceSection(avgRating, reviews.length, completionRate, searchVisibility, responseRate),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    _buildEventEaseWorkflowHubCard(),
                    const SizedBox(height: 16),
                    _buildLeadKanbanQuickActionCard(bookings),
                    const SizedBox(height: 16),
                    _buildEventsTodaySection(bookings),
                    const SizedBox(height: 16),
                    _buildRecentBookings(vendor, bookings),
                    const SizedBox(height: 16),
                    _buildRecentReviews(reviews),
                    const SizedBox(height: 16),
                    _buildCommissionSection(vendor?.id ?? ''),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 16),
                    _buildExhibitorPromoSection(),
                    const SizedBox(height: 16),
                    _buildNetworkingSection(),
                  ],
                ),
              ),
            ],
          );
        } else {
          mainCards = Column(
            children: [
              _buildEventEaseWorkflowHubCard(),
              const SizedBox(height: 16),
              _buildLeadKanbanQuickActionCard(bookings),
              const SizedBox(height: 16),
              _buildRevenueOverviewCard(
                bookings,
                monthlyRevenue,
                analyticsProvider,
              ),
              const SizedBox(height: 16),
              _buildInquiryAndQuoteMetrics(analyticsProvider),
              const SizedBox(height: 16),
              _buildConversionFunnelPreview(analyticsProvider),
              const SizedBox(height: 16),
              _buildEventsTodaySection(bookings),
              const SizedBox(height: 16),
              _buildActiveServicesSection(activeServices),
              const SizedBox(height: 16),
              _buildPerformanceSection(
                avgRating,
                reviews.length,
                completionRate,
                searchVisibility,
                responseRate,
              ),
              const SizedBox(height: 16),
              _buildRecentReviews(reviews),
              const SizedBox(height: 16),
              _buildRecentBookings(vendor, bookings),
              const SizedBox(height: 16),
              _buildCommissionSection(vendor?.id ?? ''),
              const SizedBox(height: 16),
              _buildQuickActions(),
              const SizedBox(height: 16),
              _buildExhibitorPromoSection(),
              const SizedBox(height: 16),
              _buildNetworkingSection(),
            ],
          );
        }

        return SingleChildScrollView(
          padding: contentPadding,
          child: Column(
            children: [
              _buildWelcomeSection(vendor?.name ?? 'Vendor', avgRating, reviews.length, pendingBookings),
              const SizedBox(height: 16),
              const VendorSetupChecklist(),
              const SizedBox(height: 16),
              _buildQuickStats(totalBookings, monthlyRevenue, pendingBookings),
              const SizedBox(height: 16),
              mainCards,
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(
    String name,
    double rating,
    int reviewCount,
    int pendingCount,
  ) {
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
                Text(
                  'Welcome back, $name!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You have $pendingCount pending bookings',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($reviewCount reviews)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
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
              Icons.auto_awesome,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventEaseWorkflowHubCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.hub_outlined,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Vendor Service & Collaboration Workflow',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Connected Lifecycle',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Connect Services, Appointments, Collaborative Packages, and Unified Calendar schedule.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.9,
            children: [
              _buildWorkflowShortcutItem(
                icon: Icons.business_center,
                title: 'Services & Appointments',
                subtitle: 'My Services, Packages & Tastings',
                color: const Color(0xFF6366F1),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VendorServicesHubScreen(),
                    ),
                  );
                },
              ),
              _buildWorkflowShortcutItem(
                icon: Icons.all_inclusive,
                title: 'Collaborative Packages',
                subtitle: 'Joint Bundles & Customer Choices',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VendorPackagesHubScreen(),
                    ),
                  );
                },
              ),
              _buildWorkflowShortcutItem(
                icon: Icons.calendar_month,
                title: 'Unified Calendar',
                subtitle: 'Bookings, Appointments & Times',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VendorUnifiedCalendarScreen(),
                    ),
                  );
                },
              ),
              _buildWorkflowShortcutItem(
                icon: Icons.add_circle_outline,
                title: 'Add New Service',
                subtitle: 'Category-Aware Dynamic Wizard',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  final v = Provider.of<VendorProvider>(context, listen: false).currentVendor;
                  if (v == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EnhancedServiceCreationScreen(vendorId: v.id),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowShortcutItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.textPrimaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadKanbanQuickActionCard(List<Booking> bookings) {
    // Derive kanban counts from booking statuses
    final newLeads =
        bookings.where((b) => b.status == BookingStatus.pendingVendor).length;
    final contacted =
        bookings.where((b) => b.status == BookingStatus.confirmed).length;
    final proposal =
        bookings.where((b) => b.status == BookingStatus.awaitingPayment).length;
    final won =
        bookings.where((b) => b.status == BookingStatus.completed).length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, '/vendor-lead-kanban');
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.view_kanban,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lead Pipeline (Kanban)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Track customer inquiries from lead to win',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildKanbanPill(
                        'New Leads',
                        '$newLeads',
                        Colors.lightBlueAccent,
                      ),
                      _buildKanbanDivider(),
                      _buildKanbanPill(
                        'Contacted',
                        '$contacted',
                        Colors.amberAccent,
                      ),
                      _buildKanbanDivider(),
                      _buildKanbanPill(
                        'Proposal',
                        '$proposal',
                        Colors.purpleAccent,
                      ),
                      _buildKanbanDivider(),
                      _buildKanbanPill('Won', '$won', Colors.greenAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKanbanPill(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildKanbanDivider() {
    return Container(height: 20, width: 1, color: Colors.white24);
  }

  Widget _buildRevenueOverviewCard(
    List<Booking> bookings,
    double monthlyRevenue,
    VendorAnalyticsProvider analyticsProvider,
  ) {
    final analyticsData = analyticsProvider.analyticsData;

    // Available = completed bookings revenue net of 5% platform commission
    final completedBookings = bookings.where(
      (b) => b.status == BookingStatus.completed,
    );
    final completedRevenue = completedBookings.fold(
      0.0,
      (sum, b) => sum + b.amount,
    );
    final availableBalance =
        completedRevenue > 0 ? (completedRevenue * 0.95) : 0.0;

    // Pending = confirmed or in-progress bookings awaiting event completion
    final escrowBookings = bookings.where(
      (b) =>
          b.status == BookingStatus.confirmed ||
          b.status == BookingStatus.inProgress,
    );
    final pendingBalance = escrowBookings.fold(0.0, (sum, b) => sum + b.amount);

    final totalEarnings =
        (analyticsData?['total_revenue'] as num?)?.toDouble() ??
        (completedRevenue + pendingBalance > 0
            ? (completedRevenue + pendingBalance)
            : monthlyRevenue);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Revenue & Finance Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap:
                    () =>
                        Navigator.pushNamed(context, '/vendor-payment-payout'),
                child: const Text(
                  'Manage Payouts →',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Balance',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'RM ${availableBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ready for withdrawal',
                        style: TextStyle(fontSize: 10, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pending (In Escrow)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'RM ${pendingBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Awaiting event completion',
                        style: TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lifetime Total Earnings',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Text(
                  'RM ${totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryAndQuoteMetrics(
    VendorAnalyticsProvider analyticsProvider,
  ) {
    final views = analyticsProvider.impressionsAndViews;
    final totalInquiries = views['inquiries'] ?? 0;
    final inquiriesGrowth = views['inquiries_growth'] ?? '+0%';
    final totalQuotes = views['quotes'] ?? 0;
    final quotesGrowth = views['quotes_growth'] ?? '+0%';

    // Derive response time & win rate from performance metrics
    String avgResponseTime = '—';
    String quoteWinRate = '—';
    String winRateChange = '';
    for (final m in analyticsProvider.performanceMetrics) {
      if (m['title'] == 'Avg Response Time')
        avgResponseTime = m['value'] ?? '—';
      if (m['title'] == 'Quote Win Rate') {
        quoteWinRate = m['value'] ?? '—';
        winRateChange = m['change'] ?? '';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                'Inquiries & Quotes Performance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Chip(
                label: Text(
                  analyticsProvider.selectedPeriod,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryColor,
                  ),
                ),
                backgroundColor: const Color(0xFFEEF2FF),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Total Inquiries',
                  value: '$totalInquiries',
                  change: '$inquiriesGrowth vs last period',
                  isPositive: true,
                  icon: Icons.chat_bubble_outline,
                  iconColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Avg Response Time',
                  value: avgResponseTime,
                  change: 'Based on inquiry data',
                  isPositive: true,
                  icon: Icons.timer_outlined,
                  iconColor: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Quotes Sent',
                  value: '$totalQuotes',
                  change: '$quotesGrowth vs last period',
                  isPositive: true,
                  icon: Icons.request_quote_outlined,
                  iconColor: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  title: 'Quote Win Rate',
                  value: quoteWinRate,
                  change: winRateChange,
                  isPositive: true,
                  icon: Icons.verified_outlined,
                  iconColor: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
              fontSize: 10,
              color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionFunnelPreview(
    VendorAnalyticsProvider analyticsProvider,
  ) {
    final stages = analyticsProvider.funnelStages;
    final funnelColors = [
      Colors.indigo.shade400,
      Colors.blue.shade400,
      Colors.teal.shade400,
      Colors.amber.shade600,
      Colors.green.shade500,
    ];

    // Calculate overall conversion rate from first to last stage
    String overallConversion = '0%';
    if (stages.length >= 2) {
      final first = (stages.first['count'] as num?) ?? 1;
      final last = (stages.last['count'] as num?) ?? 0;
      if (first > 0) {
        overallConversion = '${(last / first * 100).toStringAsFixed(1)}%';
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.filter_alt_outlined, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Conversion Funnel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.pushNamed(context, '/vendor-analytics'),
                child: const Text(
                  'Deep Analytics →',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...stages.asMap().entries.map((entry) {
            final i = entry.key;
            final stage = entry.value;
            final stageName = stage['stage'] ?? 'Stage ${i + 1}';
            final count = stage['count'] ?? 0;
            final conversion = stage['conversion'] ?? '';
            final factor = (stage['factor'] as num?)?.toDouble() ?? 0.0;
            final color =
                (stage['color'] as Color?) ??
                (i < funnelColors.length ? funnelColors[i] : Colors.grey);
            final label =
                conversion.isNotEmpty
                    ? '${i + 1}. $stageName'
                    : '${i + 1}. $stageName';
            final countLabel =
                conversion.isNotEmpty && conversion != '100%'
                    ? '$count ($conversion)'
                    : '$count';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildFunnelStage(label, countLabel, factor, color),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Overall lead conversion rate is $overallConversion',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelStage(
    String title,
    String count,
    double factor,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            Text(
              count,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: factor,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(
    double rating,
    int reviewCount,
    String completionRate,
    String visibility,
    String responseRate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Store Performance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
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
              _buildPerformanceRow(
                'Response Rate',
                responseRate,
                Icons.chat_bubble_outline,
                Colors.blue,
              ),
              const Divider(height: 32),
              _buildPerformanceRow(
                'Service Rating',
                rating.toStringAsFixed(1),
                Icons.star_outline,
                Colors.amber,
              ),
              const Divider(height: 32),
              _buildPerformanceRow(
                'Completion Rate',
                completionRate,
                Icons.check_circle_outline,
                Colors.green,
              ),
              const Divider(height: 32),
              _buildPerformanceRow(
                'Search Visibility',
                visibility,
                Icons.trending_up,
                Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(int total, double revenue, int pending) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 700;
        final cards = [
          _buildStatCard(
            'Total Bookings',
            total.toString(),
            Icons.book_online,
            AppTheme.primaryColor,
          ),
          _buildStatCard(
            'Revenue',
            'RM ${revenue.toStringAsFixed(0)}',
            Icons.attach_money,
            AppTheme.successColor,
          ),
          _buildStatCard(
            'Pending',
            pending.toString(),
            Icons.pending_actions,
            AppTheme.warningColor,
          ),
        ];
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              cards[i],
            ],
          ],
        );
      },
    );
  }

  Widget _buildCommissionSection(String vendorId) {
    return Consumer<CommissionProvider>(
      builder: (context, commissionProvider, child) {
        final summary = commissionProvider.getCommissionSummary(vendorId);

        if (summary == null) {
          return Container(
            padding: const EdgeInsets.all(20),
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
            child: const Center(
              child: Text(
                'No commission data available',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
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
                  const Text(
                    'Commission Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'This Month',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCommissionStatCard(
                      'Total Earnings',
                      'RM ${summary.totalEarnings.toStringAsFixed(2)}',
                      Icons.attach_money,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCommissionStatCard(
                      'Pending Payments',
                      'RM ${summary.pendingPayments.toStringAsFixed(2)}',
                      Icons.pending,
                      AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommissionStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
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
            textAlign: TextAlign.center,
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

  Widget _buildStatCard(
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
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
            textAlign: TextAlign.center,
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
                'Add Service',
                Icons.add_business,
                AppTheme.primaryColor,
                () {
                  final vendor =
                      Provider.of<VendorProvider>(
                        context,
                        listen: false,
                      ).currentVendor;
                  if (vendor != null) {
                    Navigator.pushNamed(
                      context,
                      '/service-creation',
                      arguments: {'vendorId': vendor.id},
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Shop Orders',
                Icons.shopping_bag,
                AppTheme.secondaryColor,
                () {
                  final vendor =
                      Provider.of<VendorProvider>(
                        context,
                        listen: false,
                      ).currentVendor;
                  if (vendor != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => VendorOrderManagementScreen(
                              vendorId: vendor.id,
                            ),
                      ),
                    );
                  }
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
                'Messages',
                Icons.chat,
                AppTheme.accentColor,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const VendorChatScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Create Promotion',
                Icons.local_offer,
                AppTheme.successColor,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CouponManagementScreen(),
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
                'My Catalog',
                Icons.auto_awesome_mosaic,
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VendorCatalogScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Lead Pipeline',
                Icons.view_kanban,
                Colors.indigo,
                () {
                  Navigator.pushNamed(context, '/vendor-lead-kanban');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentReviews(List<ServiceReview> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Reviews',
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
                    builder: (_) => const VendorReviewsScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "No reviews yet.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...reviews
              .take(3)
              .map(
                (r) => _buildReviewCard(
                  r.customerName ?? 'Anonymous',
                  r.comment ?? 'No comment',
                  r.rating,
                  DateFormat("yMMMd").format(r.createdAt),
                ),
              ),
      ],
    );
  }

  Widget _buildReviewCard(
    String name,
    String comment,
    int rating,
    String time,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0] : 'A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Icon(
                            Icons.star,
                            size: 16,
                            color:
                                index < rating
                                    ? Colors.amber
                                    : Colors.grey[300],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplaceStatus() {
    return Consumer<VendorNetworkingProvider>(
      builder: (context, networkingProvider, child) {
        final myItems = networkingProvider.myMarketplaceItems;
        final pendingItems =
            myItems
                .where((item) => item.status == MarketplaceItemStatus.pending)
                .toList();
        final activeItems =
            myItems
                .where((item) => item.status == MarketplaceItemStatus.active)
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Marketplace Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
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
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          'Pending',
                          pendingItems.length.toString(),
                          Icons.pending_actions,
                          AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCard(
                          'Active',
                          activeItems.length.toString(),
                          Icons.check_circle,
                          AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookings(dynamic vendor, List<Booking> bookings) {
    final recentBookings = List<Booking>.from(bookings)
      ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    final displayBookings = recentBookings.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Bookings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                if (vendor != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => VendorBookingManagementScreenFixed(
                            vendor: vendor,
                          ),
                    ),
                  );
                }
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (displayBookings.isEmpty)
          const Center(child: Text("No bookings yet"))
        else
          ...displayBookings.map((booking) => _buildBookingCard(booking)),
      ],
    );
  }

  Widget _buildBookingCard(Booking booking) {
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
                Text(
                  booking.packageName.isNotEmpty
                      ? booking.packageName
                      : booking.serviceName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(booking.bookingDate),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            'RM ${booking.amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveServicesSection(List<VendorServiceEnhanced> services) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Services',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                widget.onTabChange?.call(2); // Switch to Management tab
              },
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (services.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                const Text(
                  'No active services found',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => widget.onTabChange?.call(2),
                  child: const Text('Add Service'),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return _buildServiceSmallCard(service);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildServiceSmallCard(VendorServiceEnhanced service) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 16),
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child:
                service.images.isNotEmpty
                    ? Image.network(
                      service.images.first,
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            height: 80,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                    )
                    : Container(
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'RM ${service.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        service.isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    service.isActive ? 'Active' : 'Hidden',
                    style: TextStyle(
                      fontSize: 9,
                      color: service.isActive ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExhibitorPromoSection() {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/vendor-join-expo');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4F46E5).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.festival, color: Colors.white, size: 36),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join Bridal Fair 2026',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Register as an exhibitor, select your booth, and get specialty tags to connect with organizers!',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkingSection() {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/networking');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
        ),
        child: const Row(
          children: [
            Icon(Icons.people, color: AppTheme.primaryColor, size: 32),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vendor Networking',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Connect with other vendors for collaborations.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
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

  Widget _buildEventsTodaySection(List<Booking> bookings) {
    final today = DateTime.now();
    final eventsToday =
        bookings
            .where(
              (b) =>
                  (b.status == BookingStatus.confirmed ||
                      b.status == BookingStatus.completed) &&
                  b.bookingDate.year == today.year &&
                  b.bookingDate.month == today.month &&
                  b.bookingDate.day == today.day,
            )
            .toList();

    if (eventsToday.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.today, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text(
              'Events Today',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...eventsToday.map(
          (booking) => Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                booking.serviceName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${booking.customerName} • ${booking.location}'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Event Day Operations',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => VendorEventCheckinScreen(booking: booking),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}



// Helper widgets and logic continue...

