import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/auth/presentation/login_screen.dart';

import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';

// Import all screens for navigation
import 'package:eventease/features/vendor/presentation/views/vendor_dashboard_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_booking_management_screen_fixed.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_finance_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_payment_payout_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_service_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_analytics_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_profile_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_address_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_notifications_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_marketing_screen_fixed.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_ads_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_marketing_tools_screen.dart';
import 'package:eventease/features/vendor/presentation/views/coupon_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_loyalty_programs_screen.dart';
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
import 'package:eventease/features/booking/presentation/views/appointments/appointment_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_networking_screen.dart';
import 'package:eventease/features/referral/presentation/views/referral_home_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/vendor_services_hub_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/vendor_packages_hub_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/vendor_unified_calendar_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/vendor_service_creator_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/collaborative_package_builder_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_order_management_screen.dart';

/// One-stop drawer for all vendor screens
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
              padding: EdgeInsets.zero,
              children: [
                _buildSectionTitle('CORE NAVIGATION'),
                _buildMenuItem(context, Icons.dashboard, 'Dashboard', () => _navigateTo(context, '/dashboard')),
                _buildMenuItem(context, Icons.book_online, 'Bookings', () => _navigateTo(context, '/bookings')),
                _buildMenuItem(context, Icons.calendar_month, 'Calendar (Unified)', () => _navigateTo(context, '/calendar')),
                _buildMenuItem(context, Icons.business_center, 'Services', () => _navigateTo(context, '/services-hub')),
                _buildMenuItem(context, Icons.all_inclusive, 'Packages', () => _navigateTo(context, '/packages-hub')),
                _buildMenuItem(context, Icons.shopping_bag_outlined, 'Orders', () => _navigateTo(context, '/orders')),
                _buildMenuItem(context, Icons.chat_bubble, 'Messages', () => _navigateTo(context, '/messages')),
                _buildMenuItem(context, Icons.attach_money, 'Finance', () => _navigateTo(context, '/finance')),
                _buildMenuItem(context, Icons.trending_up, 'Growth', () => _navigateTo(context, '/marketing')),
                _buildMenuItem(context, Icons.analytics, 'Analytics', () => _navigateTo(context, '/analytics')),
                _buildMenuItem(context, Icons.person, 'Profile', () => _navigateTo(context, '/profile')),
                
                _buildSectionTitle('SERVICES & APPOINTMENTS'),
                _buildMenuItem(context, Icons.list_alt, 'My Services', () => _navigateTo(context, '/services-hub')),
                _buildMenuItem(context, Icons.add_business, 'Add Service', () => _navigateTo(context, '/service-creation')),
                _buildMenuItem(context, Icons.inventory_2_outlined, 'Service Packages', () => _navigateTo(context, '/service-packages')),
                _buildMenuItem(context, Icons.access_time, 'Availability', () => _navigateTo(context, '/service-availability')),
                _buildMenuItem(context, Icons.event_available, 'Appointments', () => _navigateTo(context, '/service-appointments')),

                _buildSectionTitle('PACKAGES & COLLABORATION'),
                _buildMenuItem(context, Icons.collections_bookmark_outlined, 'My Packages', () => _navigateTo(context, '/packages-hub')),
                _buildMenuItem(context, Icons.add_circle_outline, 'Create Package', () => _navigateTo(context, '/create-package')),
                _buildMenuItem(context, Icons.handshake_outlined, 'Collaborative Packages', () => _navigateTo(context, '/collaborative-packages')),
                _buildMenuItem(context, Icons.mail_outline, 'Package Invitations', () => _navigateTo(context, '/package-invitations')),
                _buildMenuItem(context, Icons.send_outlined, 'Collaboration Requests', () => _navigateTo(context, '/collaboration-requests')),

                _buildSectionTitle('MANAGEMENT & TOOLS'),
                _buildMenuItem(context, Icons.auto_awesome_mosaic, 'My Catalog', () => _navigateTo(context, '/catalog')),
                _buildMenuItem(context, Icons.payment, 'Payments & Payouts', () => _navigateTo(context, '/payments')),
                _buildMenuItem(context, Icons.description, 'Documents', () => _navigateTo(context, '/documents')),
                _buildMenuItem(context, Icons.location_on, 'Business Address', () => _navigateTo(context, '/address')),
                
                _buildSectionTitle('CUSTOMER SERVICE'),
                _buildMenuItem(context, Icons.chat_bubble, 'Messages', () => _navigateTo(context, '/messages')),
                _buildMenuItem(context, Icons.rate_review, 'Reviews', () => _navigateTo(context, '/reviews')),
                _buildMenuItem(context, Icons.request_page, 'Customer Requests', () => _navigateTo(context, '/requests')),
                
                _buildSectionTitle('GROWTH & MARKETING'),
                _buildMenuItem(context, Icons.campaign, 'Marketing Hub', () => _navigateTo(context, '/marketing')),
                _buildMenuItem(context, Icons.handshake, 'Collaboration & Partners', () => _navigateTo(context, '/networking')),
                _buildMenuItem(context, Icons.card_giftcard, 'Referral & Loyalty Program', () => _navigateTo(context, '/referrals')),
                _buildMenuItem(context, Icons.festival_outlined, 'Events & Exhibitions', () => _navigateTo(context, '/join-expo')),
                _buildMenuItem(context, Icons.ad_units, 'Ads', () => _navigateTo(context, '/ads')),
                _buildMenuItem(context, Icons.local_offer, 'Coupons & Flash Deals', () => _navigateTo(context, '/coupons')),
                _buildMenuItem(context, Icons.store, 'Shop Performance', () => _navigateTo(context, '/shop-performance')),
                _buildMenuItem(context, Icons.share, 'Social Media Manager', () => _navigateTo(context, '/social-media')),
                _buildMenuItem(context, Icons.event, 'Marketing Tools', () => _navigateTo(context, '/marketing-tools')),
                
                _buildSectionTitle('TOOLS'),
                _buildMenuItem(context, Icons.qr_code_2, 'QR Codes', () => _navigateTo(context, '/qr-codes')),
                _buildMenuItem(context, Icons.subscriptions, 'Subscriptions', () => _navigateTo(context, '/subscriptions')),
                _buildMenuItem(context, Icons.assessment, 'Reports', () => _navigateTo(context, '/reports')),
                _buildMenuItem(context, Icons.notifications, 'Notifications', () => _navigateTo(context, '/notifications')),
                _buildMenuItem(context, Icons.settings_applications, 'Installment Settings', () => _navigateTo(context, '/installment-settings')),
                _buildMenuItem(context, Icons.payments, 'Installment Tracker', () => _navigateTo(context, '/installments')),

                const Divider(),
                if (AdminImpersonationService.instance.isImpersonating)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.exit_to_app, color: Colors.amber.shade900),
                      title: Text(
                        'Exit Impersonation (Admin)',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: const Text(
                        'Return to Admin Control Panel',
                        style: TextStyle(fontSize: 11),
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
                  ),
                _buildMenuItem(context, Icons.settings, 'Settings', () => _navigateTo(context, '/settings')),
                _buildMenuItem(context, Icons.logout, 'Sign Out', () => _handleSignOut(context), isDestructive: true),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic currentVendor) {
    final isImpersonating = AdminImpersonationService.instance.isImpersonating;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.business, color: Colors.white, size: 28),
              ),
              if (isImpersonating)
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
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentVendor?.name ?? 'Vendor Dashboard',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currentVendor?.email ?? 'Manage your business',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
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
      case '/service-packages':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorServicesHubScreen(initialTabIndex: 2)));
        break;
      case '/service-availability':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorServicesHubScreen(initialTabIndex: 3)));
        break;
      case '/service-appointments':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorServicesHubScreen(initialTabIndex: 4)));
        break;
      case '/packages-hub':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorPackagesHubScreen(initialTabIndex: 0)));
        break;
      case '/create-package':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CollaborativePackageBuilderScreen()));
        break;
      case '/collaborative-packages':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorPackagesHubScreen(initialTabIndex: 2)));
        break;
      case '/package-invitations':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorPackagesHubScreen(initialTabIndex: 3)));
        break;
      case '/collaboration-requests':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorPackagesHubScreen(initialTabIndex: 4)));
        break;
      case '/orders':
        if (currentVendor == null) { showVendorError(); return; }
        Navigator.push(context, MaterialPageRoute(builder: (_) => VendorOrderManagementScreen(vendorId: currentVendor.id)));
        break;
      case '/appointments':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorUnifiedCalendarScreen()));
        break;
      case '/finance':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorFinanceScreen()));
        break;
      case '/payments':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorPaymentPayoutScreen()));
        break;
      case '/services':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorServicesHubScreen()));
        break;
      case '/catalog':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorCatalogScreen()));
        break;
      case '/service-creation':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorServiceCreatorScreen()));
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
      case '/loyalty':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorLoyaltyProgramsScreen()));
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
              Navigator.pop(context); // Close dialog
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
