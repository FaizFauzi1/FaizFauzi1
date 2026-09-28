import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/auth/presentation/login_screen.dart';
import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_dashboard_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_booking_management_screen_fixed.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_finance_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_payment_payout_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_analytics_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_profile_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_address_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_notifications_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_marketing_screen_fixed.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_ads_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_marketing_tools_screen.dart';
import 'package:eventease/features/vendor/presentation/views/coupon_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_shop_performance_screen_final.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_social_media_manager_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_chat_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_review_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_subscriptions_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_reports_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_settings_screen_enhanced.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_document_management_screen_enhanced.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_installment_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_installment_settings_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_catalog_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_join_exhibitor_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_networking_screen.dart';
import 'package:eventease/features/referral/presentation/views/referral_home_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/vendor_services_hub_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/vendor_packages_hub_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/vendor_unified_calendar_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/collaborative_package_builder_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_order_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/enhanced_service_creation_screen.dart';

/// One-stop drawer for all vendor screens — compact ExpansionTile groups.
class VendorDrawer {
  static Drawer build(BuildContext context) {
    return const Drawer(
      child: VendorSidebarContent(),
    );
  }
}

class VendorSidebarContent extends StatelessWidget {
  const VendorSidebarContent({super.key});

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);
    final currentVendor = vendorProvider.currentVendor;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildHeader(currentVendor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                _buildGroup('Core', [
                  _NavItem(Icons.dashboard, 'Dashboard', '/dashboard'),
                  _NavItem(Icons.book_online, 'Bookings', '/bookings'),
                  _NavItem(Icons.calendar_month, 'Calendar', '/calendar'),
                  _NavItem(Icons.chat_bubble_outline, 'Messages', '/messages'),
                  _NavItem(Icons.analytics_outlined, 'Analytics', '/analytics'),
                ]),

                _buildGroup('Catalog', [
                  _NavItem(Icons.business_center, 'Services', '/services-hub'),
                  _NavItem(Icons.add_business, 'Add Service', '/service-creation'),
                  _NavItem(Icons.all_inclusive, 'Packages', '/packages-hub'),
                  _NavItem(Icons.add_circle_outline, 'Create Package', '/create-package'),
                  _NavItem(Icons.auto_awesome_mosaic, 'My Catalog', '/catalog'),
                  _NavItem(Icons.shopping_bag_outlined, 'Orders', '/orders'),
                ]),

                _buildGroup('Growth', [
                  _NavItem(Icons.campaign, 'Marketing Hub', '/marketing'),
                  _NavItem(Icons.ad_units, 'Ads', '/ads'),
                  _NavItem(Icons.local_offer, 'Coupons', '/coupons'),
                  _NavItem(Icons.store, 'Shop Performance', '/shop-performance'),
                  _NavItem(Icons.handshake, 'Partners', '/networking'),
                  _NavItem(Icons.card_giftcard, 'Referrals', '/referrals'),
                  _NavItem(Icons.festival_outlined, 'Exhibitions', '/join-expo'),
                  _NavItem(Icons.share, 'Social Media', '/social-media'),
                  _NavItem(Icons.event, 'Marketing Tools', '/marketing-tools'),
                ]),

                _buildGroup('Account', [
                  _NavItem(Icons.person, 'Profile', '/profile'),
                  _NavItem(Icons.description, 'Documents', '/documents'),
                  _NavItem(Icons.location_on, 'Address', '/address'),
                  _NavItem(Icons.attach_money, 'Finance', '/finance'),
                  _NavItem(Icons.payment, 'Payouts', '/payments'),
                  _NavItem(Icons.rate_review, 'Reviews', '/reviews'),
                  _NavItem(Icons.request_page, 'Requests', '/requests'),
                  _NavItem(Icons.subscriptions, 'Subscriptions', '/subscriptions'),
                  _NavItem(Icons.assessment, 'Reports', '/reports'),
                  _NavItem(Icons.notifications, 'Notifications', '/notifications'),
                  _NavItem(Icons.qr_code_2, 'QR Codes', '/qr-codes'),
                  _NavItem(Icons.settings_applications, 'Installment Settings', '/installment-settings'),
                  _NavItem(Icons.payments, 'Installments', '/installments'),
                  _NavItem(Icons.settings, 'Settings', '/settings'),
                ]),

                const Divider(height: 24),
                if (AdminImpersonationService.instance.isImpersonating)
                  _buildImpersonationExit(context),
                _buildMenuItem(context, Icons.logout, 'Sign Out', () => _handleSignOut(context), isDestructive: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(String title, List<_NavItem> items) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: title == 'Core' || title == 'Catalog',
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: EdgeInsets.zero,
        title: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        children: items
            .map((item) => Builder(
                  builder: (context) => _buildMenuItem(
                    context,
                    item.icon,
                    item.label,
                    () => _navigateTo(context, item.route),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildHeader(dynamic currentVendor) {
    final isImpersonating = AdminImpersonationService.instance.isImpersonating;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isImpersonating
              ? [Colors.amber.shade800, Colors.deepOrange.shade700]
              : [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.business, color: Colors.white, size: 22),
              ),
              if (isImpersonating) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'IMPERSONATING',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            currentVendor?.name ?? 'Vendor Dashboard',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            currentVendor?.email ?? 'Manage your business',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImpersonationExit(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: ListTile(
        leading: Icon(Icons.exit_to_app, color: Colors.amber.shade900, size: 20),
        title: Text(
          'Exit Impersonation',
          style: TextStyle(
            color: Colors.amber.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        dense: true,
        onTap: () async {
          if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
            Navigator.pop(context);
          }
          await AdminImpersonationService.instance.endImpersonation();
          if (context.mounted) {
            Provider.of<VendorProvider>(context, listen: false).clearCurrentVendor();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Returned to Admin Control Panel'),
                backgroundColor: Colors.indigo,
              ),
            );
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      dense: true,
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
      onTap: () {
        if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
          Navigator.pop(context);
        }
        onTap();
      },
    );
  }

  void _navigateTo(BuildContext context, String route) {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final currentVendor = vendorProvider.currentVendor;

    void showVendorError() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor profile not loaded. Please wait or reload.')),
      );
    }

    switch (route) {
      case '/dashboard':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VendorDashboardScreen()));
        break;
      case '/bookings':
        if (currentVendor == null) { showVendorError(); return; }
        Navigator.push(context, MaterialPageRoute(builder: (_) => VendorBookingManagementScreenFixed(vendor: currentVendor)));
        break;
      case '/calendar':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorUnifiedCalendarScreen()));
        break;
      case '/services-hub':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorServicesHubScreen(initialTabIndex: 0)));
        break;
      case '/packages-hub':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorPackagesHubScreen(initialTabIndex: 0)));
        break;
      case '/create-package':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CollaborativePackageBuilderScreen()));
        break;
      case '/orders':
        if (currentVendor == null) { showVendorError(); return; }
        Navigator.push(context, MaterialPageRoute(builder: (_) => VendorOrderManagementScreen(vendorId: currentVendor.id)));
        break;
      case '/finance':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorFinanceScreen()));
        break;
      case '/payments':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorPaymentPayoutScreen()));
        break;
      case '/catalog':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorCatalogScreen()));
        break;
      case '/service-creation':
        if (currentVendor == null) { showVendorError(); return; }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EnhancedServiceCreationScreen(vendorId: currentVendor.id),
          ),
        );
        break;
      case '/documents':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorDocumentManagementScreenEnhanced()));
        break;
      case '/analytics':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorAnalyticsScreen()));
        break;
      case '/profile':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorProfileScreen()));
        break;
      case '/address':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorAddressManagementScreen()));
        break;
      case '/notifications':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorNotificationsScreen()));
        break;
      case '/messages':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorChatScreen()));
        break;
      case '/reviews':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorReviewsScreen()));
        break;
      case '/requests':
        if (currentVendor == null) { showVendorError(); return; }
        Navigator.pushNamed(context, '/vendor-request-management', arguments: {
          'vendorId': currentVendor.id,
          'vendorName': currentVendor.name,
        });
        break;
      case '/marketing':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorMarketingScreen()));
        break;
      case '/networking':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorNetworkingScreen()));
        break;
      case '/referrals':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralHomeScreen()));
        break;
      case '/join-expo':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorJoinExhibitorScreen()));
        break;
      case '/ads':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorAdsScreen()));
        break;
      case '/marketing-tools':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorMarketingToolsScreen()));
        break;
      case '/coupons':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponManagementScreen()));
        break;
      case '/shop-performance':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorShopPerformanceScreen()));
        break;
      case '/social-media':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorSocialMediaManagerScreen()));
        break;
      case '/qr-codes':
        Navigator.pushNamed(context, '/vendor-qr-codes');
        break;
      case '/subscriptions':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorSubscriptionsScreen()));
        break;
      case '/reports':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorReportsScreen()));
        break;
      case '/installment-settings':
        if (currentVendor == null) { showVendorError(); return; }
        Navigator.push(context, MaterialPageRoute(builder: (_) => VendorInstallmentSettingsScreen(vendorId: currentVendor.id)));
        break;
      case '/installments':
        if (currentVendor == null) { showVendorError(); return; }
        Navigator.push(context, MaterialPageRoute(builder: (_) => VendorInstallmentManagementScreen(vendorId: currentVendor.id)));
        break;
      case '/settings':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorSettingsScreen()));
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feature $route coming soon!')));
    }
  }

  void _handleSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign Out', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.label, this.route);
}
