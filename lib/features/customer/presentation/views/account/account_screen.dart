import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/auth/presentation/login_screen.dart';
import 'package:eventease/features/auth/presentation/sign_up_screen.dart';
import 'package:eventease/features/customer/presentation/views/user/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:eventease/features/customer/presentation/views/account/help_center_screen.dart';
import 'package:eventease/features/customer/presentation/views/account/about_screen.dart';
import 'package:eventease/features/customer/presentation/views/account/settings_screen.dart';
import 'package:eventease/features/customer/presentation/views/account/security_screen.dart';
import 'package:eventease/features/customer/presentation/views/account/payment_module_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/notifications_screen.dart';
import 'package:eventease/features/customer/presentation/views/account/preferences_screen.dart';
import 'package:eventease/features/event/presentation/views/calendar/calendar_integration_screen.dart';
import 'package:eventease/features/event/presentation/views/tentative_planner_screen.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/customer/presentation/views/customer/order_status_screen.dart';
import 'package:eventease/features/booking/data/providers/order_provider.dart';
import 'package:eventease/features/booking/data/models/order.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:eventease/features/customer/presentation/views/customer/chat_screen.dart' as customer_chat;
import 'package:eventease/features/customer/presentation/views/customer/customer_support_screen.dart';
import 'package:eventease/features/customer/data/providers/favorites_provider.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/features/customer/presentation/views/account/customer_subscription_screen.dart';
import 'package:eventease/features/customer/data/providers/customer_subscription_provider.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';
import 'package:eventease/shared/widgets/app_footer.dart';
import 'package:eventease/shared/widgets/app_footer.dart';
import 'package:eventease/shared/views/privacy_policy_screen.dart';
import 'package:eventease/shared/views/terms_of_service_screen.dart';


class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer5<AuthProvider, OrderProvider, FavoritesProvider, EventProvider, CustomerSubscriptionProvider>(
      builder: (context, authProvider, orderProvider, favoritesProvider, eventProvider, subscriptionProvider, child) {
        if (!authProvider.isAuthenticated) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Account',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      size: 100,
                      color: AppTheme.textSecondaryColor,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome to EventEase',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to manage your bookings, favorites, and more.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Login / Sign Up', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(initialRole: 'vendor'),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Register as Vendor', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // User data loading is handled by ProxyProviders in main.dart
        // do not call updateUserId or loadCustomerOrders here to avoid infinite loops
        // Assuming eventProvider has a similar method, if not, we'll use getUpcomingEvents() directly

        // Calculate dynamic stats
        final totalBookings = orderProvider.customerOrders.length;
        final favoriteVendors = favoritesProvider.favoriteItems.length;
        final upcomingEvents = eventProvider.getUpcomingEvents().length;

        final userData = {
          'name': authProvider.userName,
          'email': authProvider.userEmail,
          'phone': authProvider.userData['phone'] ?? '',
          'avatar': 'https://via.placeholder.com/100x100?text=${authProvider.userName.isNotEmpty ? authProvider.userName.split(' ').map((e) => e[0]).join() : 'U'}',
          'membership': subscriptionProvider.currentTier.toUpperCase(),
          'joinDate': 'January 2024',
          'totalBookings': totalBookings,
          'favoriteVendors': favoriteVendors,
          'upcomingEvents': upcomingEvents,
        };

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Account',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: AppTheme.textSecondaryColor),
                onPressed: _showSettings,
              ),
            ],
          ),
          body: ResponsiveWrapper(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              padding: ResponsiveUtils.getScreenPadding(context),
              child: Column(
                children: [
                  _buildProfileHeader(userData),
                  const SizedBox(height: 24),
                  _buildQuickStats(userData),
                  const SizedBox(height: 24),
                  _buildOrderStatusCard(),
                  const SizedBox(height: 24),
                  _buildFeaturesSection(),
                  const SizedBox(height: 24),
                  _buildAccountSections(),
                  const SizedBox(height: 24),
                  _buildSupportSection(authProvider),
                  const SizedBox(height: 32),
                  if (kIsWeb) const AppFooter(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(userData['avatar']),
                onBackgroundImageError: (exception, stackTrace) {
                  // Handle image error
                },
                child: Text(
                  userData['name'][0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData['name'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userData['email'],
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                         Navigator.pushNamed(context, '/customer-subscription');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // Wrap content
                          children: [
                            Text(
                              userData['membership'],
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 10, color: AppTheme.primaryColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editProfile(),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _viewProfile(userData),
                  icon: const Icon(Icons.person, size: 16),
                  label: const Text('View Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> userData) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Bookings',
            userData['totalBookings'].toString(),
            Icons.book_online,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Favorites',
            userData['favoriteVendors'].toString(),
            Icons.favorite,
            Colors.red,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Upcoming',
            userData['upcomingEvents'].toString(),
            Icons.event,
            AppTheme.secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
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

  Widget _buildFeaturesSection() {
    final features = [
      {'title': 'Smart Planner', 'desc': 'Coordinate your event timeline', 'icon': Icons.event_note, 'color': Colors.blue},
      {'title': 'Budget Tracker', 'desc': 'Stay on top of your spending', 'icon': Icons.account_balance_wallet, 'color': Colors.green},
      {'title': 'Direct Messaging', 'desc': 'Chat with vendors in real-time', 'icon': Icons.chat, 'color': Colors.purple},
      {'title': 'Guest List', 'desc': 'Manage RSVPs and invitations', 'icon': Icons.people, 'color': Colors.orange},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Features for You',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: (feature['color'] as Color).withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (feature['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(feature['icon'] as IconData, color: feature['color'] as Color, size: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['desc'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildAccountSectionItem(
          'Personal Information',
          'Manage your personal details',
          Icons.person,
          () => _editProfile(),
        ),
        _buildAccountSectionItem(
          'Security & Privacy',
          'Password, privacy settings',
          Icons.security,
          () => _navigateToSecurity(),
        ),
        _buildAccountSectionItem(
          'Payment Methods',
          'Credit cards, e-wallets',
          Icons.payment,
          () => _navigateToPayments(),
        ),
        _buildAccountSectionItem(
          'Notifications',
          'Email, push notifications',
          Icons.notifications,
          () => _navigateToNotifications(),
        ),
        _buildAccountSectionItem(
          'Calendar Sync',
          'External calendar integration',
          Icons.calendar_today,
          () => _navigateToCalendarSync(),
        ),
        _buildAccountSectionItem(
          'Preferences',
          'Language, theme, units',
          Icons.settings,
          () => _navigateToPreferences(),
        ),
        _buildAccountSectionItem(
          'My Requests',
          'Submit and manage event requests',
          Icons.request_page,
          () => _navigateToMyRequests(),
        ),
        _buildAccountSectionItem(
          'My Events',
          'Manage your events and guests',
          Icons.event,
          () => _navigateToMyEvents(),
        ),
        _buildAccountSectionItem(
          'Event Planner',
          'Plan your tentative events',
          Icons.event_note,
          () => _navigateToEventPlanner(),
        ),
        _buildAccountSectionItem(
          'Order Status',
          'Track your orders and purchases',
          Icons.shopping_cart,
          () => _navigateToOrderStatus(),
        ),
        _buildAccountSectionItem(
          'My Appointments',
          'Manage your bookings and appointments',
          Icons.calendar_month,
          () => _navigateToAppointments(),
        ),

      ],
    );
  }

  void _navigateToAppointments() {
    Navigator.pushNamed(context, '/appointments');
  }

  void _navigateToMyRequests() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Navigator.pushNamed(
      context,
      '/customer-request-management',
      arguments: {
        'customerId': authProvider.userId ?? '',
      },
    );
  }

  Widget _buildAccountSectionItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSupportSection(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Support & Help',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildSupportItem(
          'Help Center',
          'FAQs and guides',
          Icons.help,
          _showHelpCenter,
        ),
        _buildSupportItem(
          'Contact Support',
          'Get in touch with us',
          Icons.support_agent,
          _contactSupport,
        ),
        _buildSupportItem(
          'Report an Issue',
          'Report bugs or problems',
          Icons.bug_report,
          _reportIssue,
        ),
        _buildSupportItem(
          'Feedback',
          'Share your thoughts',
          Icons.feedback,
          _shareFeedback,
        ),
        _buildSupportItem(
          'Terms & Privacy',
          'Legal information',
          Icons.description,
          _showTermsPrivacy,
        ),
        _buildSupportItem(
          'About EventEase',
          'App version and info',
          Icons.info,
          _showAbout,
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout, color: AppTheme.errorColor, size: 24),
            ),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            subtitle: const Text(
              'Log out from your account',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
            onTap: () => _showSignOutDialog(authProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.secondaryColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
        onTap: onTap,
      ),
    );
  }

  void _editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EditProfileScreen(),
      ),
    );
  }

  void _viewProfile(Map<String, dynamic> userData) {
    // Show profile details in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${userData['name']}'),
            Text('Email: ${userData['email']}'),
            Text('Phone: ${userData['phone']}'),
            Text('Membership: ${userData['membership']}'),
            Text('Member since: ${userData['joinDate']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToCalendarSync() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CalendarIntegrationScreen(),
      ),
    );
  }

  // Navigation methods




  void _navigateToMyEvents() {
    // Navigate to event management screen where users can manage their events and guests
    Navigator.pushNamed(context, '/event-management');
  }

  void _showSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  // Route stubs for account subsections (replace with real screens as they exist)
  void _navigateToPayments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaymentModuleScreen()),
    );
  }

  void _navigateToSecurity() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SecurityScreen()),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerNotificationsScreen()),
    );
  }

  void _navigateToPreferences() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PreferencesScreen()),
    );
  }

  void _navigateToOrderStatus() {
    Navigator.pushNamed(context, '/orders');
  }

  void _navigateToEventPlanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TentativePlannerScreen()),
    );
  }

  void _showHelpCenter() {
    Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
              );
  }

  void _contactSupport() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent, color: AppTheme.primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text('Contact Support', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Get in touch with our support team via:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.chat, color: AppTheme.primaryColor),
              title: const Text('Live Chat'),
              onTap: () {
                Navigator.pop(context);
                _startLiveChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: AppTheme.primaryColor),
              title: const Text('Email'),
              subtitle: const Text('support@eventease.com'),
              onTap: () {
                Navigator.pop(context);
                _showFeatureDialog('Email Support', 'Email: support@eventease.com');
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: AppTheme.primaryColor),
              title: const Text('Call'),
              subtitle: const Text('+60 12-345 6789'),
              onTap: () {
                Navigator.pop(context);
                _showFeatureDialog('Call Support', 'Phone: +60 12-345 6789');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  void _reportIssue() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                const Text('Report an Issue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Describe the issue or bug you encountered:'),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your issue here...'
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showFeatureDialog('Thank you!', 'Your issue has been reported.');
                },
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareFeedback() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.feedback, color: AppTheme.secondaryColor, size: 28),
                const SizedBox(width: 12),
                const Text('Share Feedback', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('We value your feedback!'),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your feedback here...'
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showFeatureDialog('Thank you!', 'Your feedback has been submitted.');
                },
                child: const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsPrivacy() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: AppTheme.primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Legal',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Read our legal documents to understand your rights and obligations.',
              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.privacy_tip, color: AppTheme.primaryColor),
              ),
              title: const Text('Privacy Policy'),
              subtitle: const Text('How we handle your personal data'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.gavel, color: AppTheme.secondaryColor),
              ),
              title: const Text('Terms of Service'),
              subtitle: const Text('Your rights and obligations as a customer'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermsOfServiceScreen(initialTab: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showFeatureDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  void _showSignOutDialog(AuthProvider authProvider) {
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
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
              // Navigate to role selection and clear stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                'My Orders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToMyOrders(5), // 5 is 'All' tab
                child: const Row(
                  children: [
                    Text(
                      'View History',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textSecondaryColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOrderStatusButton('To Pay', Icons.payment_outlined, 0),
              _buildOrderStatusButton('To Ship', Icons.local_shipping_outlined, 1),
              _buildOrderStatusButton('To Receive', Icons.move_to_inbox_outlined, 2),
              _buildOrderStatusButton('To Review', Icons.rate_review_outlined, 3),
              _buildOrderStatusButton('Returns', Icons.assignment_return_outlined, 4), // Mapped to Cancelled/Refunded
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusButton(String label, IconData icon, int tabIndex) {
    return InkWell(
      onTap: () => _navigateToMyOrders(tabIndex),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Icon(icon, color: AppTheme.textPrimaryColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMyOrders(int initialIndex) {
    Navigator.pushNamed(
      context, 
      '/orders',
      arguments: {'initialIndex': initialIndex},
    );
  }

  Widget _buildOrderStatusItem(Order order) {
    Color statusColor;
    String statusText;

    switch (order.status) {
      case OrderStatus.ordered:
        statusColor = Colors.orange;
        statusText = 'Ordered';
        break;
      case OrderStatus.processing:
        statusColor = Colors.blue;
        statusText = 'Processing';
        break;
      case OrderStatus.shipped:
        statusColor = Colors.purple;
        statusText = 'Shipped';
        break;
      case OrderStatus.delivered:
        statusColor = Colors.teal;
        statusText = 'Delivered';
        break;
      case OrderStatus.completed:
        statusColor = Colors.green;
        statusText = 'Completed';
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
      case OrderStatus.refunded:
        statusColor = Colors.grey;
        statusText = 'Refunded';
        break;
      default:
        statusColor = AppTheme.textSecondaryColor;
        statusText = 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
            child: const Icon(
              Icons.shopping_cart,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RM ${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatOrderDate(order.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatOrderDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _startLiveChat() {
    // Navigate to dedicated Customer Support screen instead of mock chat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CustomerSupportScreen(autoStartLiveChat: true),
      ),
    );
  }
}

