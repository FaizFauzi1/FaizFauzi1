// ignore_for_file: unused_import

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/support_agent_dashboard.dart';
import 'package:eventease/shared/widgets/theme_toggle_widget.dart';
import 'package:eventease/features/admin/presentation/views/admin/admin_dashboard_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/event_command_center_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/admin_organizer_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/admin_expo_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin_ads_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/approvals_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/booking_service_management_screen.dart'
    hide AdminBookingServiceManagementScreen;
import 'package:eventease/features/admin/presentation/views/admin/modules/comms_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/content_marketing_screen.dart'
    hide AdminContentMarketingScreen;
import 'package:eventease/features/admin/presentation/views/admin/modules/dispute_review_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/campaign_manager_screen.dart';

import 'package:eventease/features/admin/presentation/views/admin/modules/commission_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/notifications_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/planning_oversight_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/reports_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/settings_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/system_security_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/user_guest_management_screen.dart'
    hide AdminUserGuestManagementScreen;
import 'package:eventease/features/admin/presentation/views/admin/modules/vendor_management_screen.dart'
    hide AdminVendorManagementScreen;
import 'package:eventease/features/admin/presentation/views/admin/modules/region_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/admin_request_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/admin_service_approval_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/admin_catalog_monitor_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/admin_category_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin_installment_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/subscription_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/referral_management_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/anti_bypass_dashboard_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/admin_revenue_dashboard_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/admin_churn_dashboard_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/admin_broadcast_screen.dart';

import 'package:flutter/material.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/financial_management_screen.dart';
import 'package:eventease/features/auth/presentation/login_screen.dart';

Drawer adminDrawer(BuildContext context) {
  return Drawer(child: adminDrawerContent(context));
}

Widget adminDrawerContent(BuildContext context) {
  final isDesktop = MediaQuery.of(context).size.width >= 1024;
  return ListView(
    padding: EdgeInsets.zero,
    children: [
      DrawerHeader(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'Administrator',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              SizedBox(height: 6),
              Text(
                'Control Panel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      ListTile(
        leading: const Icon(Icons.dashboard, color: AppTheme.primaryColor),
        title: const Text('Dashboard'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminDashboardScreen(initialIndex: 0),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.satellite_alt, color: AppTheme.primaryColor),
        title: const Text('Event Command Center'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const EventCommandCenterScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.people, color: AppTheme.primaryColor),
        title: const Text('Users'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminDashboardScreen(initialIndex: 1),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.business, color: AppTheme.primaryColor),
        title: const Text('Vendors'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminDashboardScreen(initialIndex: 2),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.payment, color: AppTheme.primaryColor),
        title: const Text('Transactions'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminDashboardScreen(initialIndex: 3),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.analytics, color: AppTheme.primaryColor),
        title: const Text('Analytics'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminDashboardScreen(initialIndex: 4),
            ),
          );
        },
      ),
      const Divider(),
      ListTile(
        leading: const Icon(
          Icons.store_mall_directory,
          color: AppTheme.primaryColor,
        ),
        title: const Text('Vendor Management'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const VendorManagementScreen()),
          );
        },
      ),
      ListTile(
        leading: const Icon(
          Icons.festival,
          color: AppTheme.primaryColor,
        ),
        title: const Text('Organizer Management'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminOrganizerManagementScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(
          Icons.event_seat,
          color: AppTheme.primaryColor,
        ),
        title: const Text('Expo & Event Oversight'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminExpoManagementScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
        title: const Text('Region Management'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegionManagementScreen()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.people_alt, color: AppTheme.primaryColor),
        title: const Text('Users & Guests'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UserGuestManagementScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(
          Icons.record_voice_over,
          color: AppTheme.primaryColor,
        ),
        title: const Text('Customer Requests'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminRequestManagementScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.category, color: AppTheme.primaryColor),
        title: const Text('Category Management'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminCategoryManagementScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(
          Icons.event_available,
          color: AppTheme.primaryColor,
        ),
        title: const Text('Bookings & Services'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BookingServiceManagementScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.fact_check, color: AppTheme.primaryColor),
        title: const Text('Service Approval'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminServiceApprovalScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.auto_awesome_mosaic, color: AppTheme.primaryColor),
        title: const Text('Catalog Monitor'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminCatalogMonitorScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(
          Icons.account_balance,
          color: AppTheme.primaryColor,
        ),
        title: const Text('Financial Management'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FinancialManagementScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.attach_money, color: AppTheme.primaryColor),
        title: const Text('Commission Management'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CommissionManagementScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.card_giftcard, color: AppTheme.primaryColor),
        title: const Text('Referral Management'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ReferralManagementScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(
          Icons.account_balance_wallet,
          color: AppTheme.primaryColor,
        ),
        title: const Text('Installment Management'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminInstallmentManagementScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.ads_click, color: AppTheme.primaryColor),
        title: const Text('Advertisements'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminAdsManagementScreen()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.stars, color: AppTheme.primaryColor),
        title: const Text('Subscription Management'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SubscriptionManagementScreen(),
            ),
          );
        },
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.event, color: AppTheme.primaryColor),
        title: const Text('Support Agent Dashboard'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SupportAgentDashboard()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.auto_graph, color: AppTheme.primaryColor),
        title: const Text('Campaign Manager'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminCampaignManagerScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.campaign, color: AppTheme.primaryColor),
        title: const Text('Content & Marketing'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContentMarketingScreen()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.event_note, color: AppTheme.primaryColor),
        title: const Text('Planning Oversight'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminPlanningOversightScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.gavel, color: AppTheme.primaryColor),
        title: const Text('Disputes & Reviews'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminDisputeReviewManagementScreen(),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.shield, color: AppTheme.errorColor),
        title: const Text('Anti-Bypass Center'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AntiBypassDashboardScreen()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.attach_money, color: AppTheme.primaryColor),
        title: const Text('Revenue Dashboard'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminRevenueDashboardScreen()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.trending_down, color: Colors.orange),
        title: const Text('Churn & Retention'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminChurnDashboardScreen()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.campaign, color: AppTheme.primaryColor),
        title: const Text('Broadcast Center'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminBroadcastScreen()),
          );
        },
      ),
      ListTile(
        leading: const Icon(
          Icons.notifications_active,
          color: AppTheme.primaryColor,
        ),
        title: const Text('Notifications & Comms'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminCommsScreen()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.security, color: AppTheme.primaryColor),
        title: const Text('System & Security'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SystemSecurityScreen()),
          );
        },
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.settings, color: AppTheme.primaryColor),
        title: const Text('Settings'),
        onTap: () {
          if (!isDesktop) Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminSettingsScreen()),
          );
        },
      ),
      const Divider(),
      const ThemeToggleWidget(),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.logout, color: AppTheme.errorColor),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: AppTheme.errorColor),
        ),
        onTap: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      ),
    ],
  );
}
