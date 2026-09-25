import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/shared/models/other/venue.dart';
import 'package:eventease/features/customer/presentation/views/customer/search_screen.dart';
import 'package:eventease/features/customer/presentation/views/categories/categories_screen.dart';
import 'package:eventease/features/chat/presentation/views/messages/messages_screen.dart';
import 'package:eventease/features/customer/presentation/views/account/account_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/bookings_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/planner_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/shop_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/wedding_marketplace_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/notifications_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/favorites_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/compare_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/saved_for_later_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/event_creation_screen.dart' as event_creation;
import 'package:eventease/features/customer/presentation/views/customer/event_management_screen.dart' as event_management;
import 'package:eventease/features/customer/presentation/views/customer/guest_list_screen.dart' as guest_list;
import 'package:eventease/features/customer/presentation/views/customer/group_creation_screen.dart' as group_creation;
import 'package:eventease/features/customer/presentation/views/customer/budget_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/order_status_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/customer_support_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/vendor_services_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/customer_installment_screen.dart';
import 'package:eventease/features/booking/presentation/views/appointments/appointments_screen.dart';
import 'package:eventease/features/event/presentation/views/tentative_planner_screen.dart';
import 'package:eventease/features/booking/data/providers/cart_provider.dart';
import 'package:eventease/features/customer/presentation/views/buyersnav_screens/cart_screen.dart';
import 'package:eventease/shared/widgets/payment_badge_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/features/event/data/models/event_type.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/core/utils/guest_utils.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'royal_wedding_package_screen.dart';
import 'package:intl/intl.dart';
import 'package:eventease/features/customer/presentation/widgets/home_skeleton_loading.dart';
import 'package:eventease/shared/providers/category_provider.dart';
import 'package:eventease/shared/widgets/app_footer.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/features/customer/presentation/views/customer/event_countdown_screen.dart';
import 'package:eventease/features/customer/presentation/widgets/wedding_team_builder.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:seo/seo.dart';
import 'package:eventease/features/customer/presentation/widgets/home_hero_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late List<Venue> _venues;
  late List<Venue> _featuredVenues;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _venues = [];
    _featuredVenues = [];
    _screens = [
      HomeContent(onNavigateToTab: _onItemTapped),
      const SearchScreen(),
      const CategoriesScreen(),
      const MessagesScreen(),
      const AccountScreen(),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
        GuestUtils.promptLogin(context, message: 'Please log in to access Messages.');
        return;
      }
    }
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildTopNavItem(String label, IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(bottom: BorderSide(color: AppTheme.primaryColor, width: 3))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ).showCursorOnHover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    // Seo.head injects a <title> and <meta description> tag into the hidden
    // HTML DOM tree that search engine crawlers read on Flutter Web.
    const seoTags = [
      MetaTag(name: 'title', content: 'EventEase — Find Vendors & Plan Your Event in Malaysia'),
      MetaTag(
        name: 'description',
        content:
            'Discover top-rated wedding and event vendors in Malaysia. '
            'Book photographers, caterers, venues and more on EventEase.',
      ),
    ];

    if (isDesktop) {
      return Seo.head(
        tags: seoTags,
        child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          toolbarHeight: 70,
          titleSpacing: 16,
          title: Row(
            children: [
              InkWell(
                onTap: () => _onItemTapped(0),
                child: const Text(
                  'EventEase',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTopNavItem('Home', Icons.home_outlined, 0),
                      _buildTopNavItem('Search', Icons.search_outlined, 1),
                      _buildTopNavItem('Categories', Icons.category_outlined, 2),
                      _buildTopNavItem('Messages', Icons.message_outlined, 3),
                      _buildTopNavItem('Account', Icons.person_outline, 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // We keep the generic actions here or let the child screens handle them.
            // For now, let the child screens (like HomeContent) handle their own specific AppBars for Cart/Notifications
            const SizedBox(width: 16),
          ],
        ),
        body: _screens[_currentIndex],
      ));
    }

    return Seo.head(
      tags: seoTags,
      child: Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    ));
  }
}


class HomeContent extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;
  const HomeContent({super.key, this.onNavigateToTab});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late List<Venue> _venues;
  late List<Venue> _featuredVenues;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _venues = [];
    _featuredVenues = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHomeData();
    });
  }

  Future<void> _loadHomeData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    try {
      final futures = <Future>[];
      if (authProvider.isAuthenticated && authProvider.userId != null) {
        futures.add(eventProvider.loadEvents(authProvider.userId!));
        futures.add(bookingProvider.loadCustomerBookings(authProvider.userId!));
      }
      if (vendorProvider.venues.isEmpty) {
        futures.add(vendorProvider.loadVenues());
      }
      if (vendorProvider.vendors.isEmpty) {
        futures.add(vendorProvider.loadVendors());
      }
      if (categoryProvider.allCategories.isEmpty) {
        futures.add(categoryProvider.fetchCategories());
      }
      await Future.wait(futures).timeout(const Duration(seconds: 3), onTimeout: () => []);
    } catch (e) {
      debugPrint('HomeScreen: Data load notice: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  String _parseCategories(dynamic categories) {
    if (categories == null) return 'N/A';

    try {
      if (categories is List) {
        return categories.join(', ');
      } else if (categories is String) {
        // Handle JSON string format like "[\"Catering\",\"Fashion\"]"
        if (categories.startsWith('[') && categories.endsWith(']')) {
          // Parse JSON string to list
          final List<dynamic> parsed = List<dynamic>.from(
            categories.substring(1, categories.length - 1)
                .split(',')
                .map((item) => item.trim().replaceAll('"', '').replaceAll("'", ''))
                .where((item) => item.isNotEmpty)
          );
          return parsed.join(', ');
        }
        return categories;
      }
      return 'N/A';
    } catch (e) {
      print('Error parsing categories: $e');
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = Provider.of<EventProvider>(context);
    final vendorProvider = Provider.of<VendorProvider>(context);

    if (_isInitialLoading && eventProvider.events.isEmpty && vendorProvider.vendors.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'EventEase',
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const HomeSkeletonLoading(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'EventEase',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // QR Scan Icon
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_outlined,
                color: AppTheme.textPrimaryColor),
            onPressed: () {
              Navigator.pushNamed(context, '/scan-qr');
            },
          ),
          // Cart Icon with Badge
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              final itemCount = cartProvider.itemCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: AppTheme.textPrimaryColor),
                    onPressed: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (!authProvider.isAuthenticated) {
                        GuestUtils.promptLogin(context, message: 'Please log in to view your cart.');
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          itemCount > 99 ? '99+' : itemCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Notification Icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppTheme.textPrimaryColor),
            onPressed: () {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              if (!authProvider.isAuthenticated) {
                GuestUtils.promptLogin(context, message: 'Please log in to view notifications.');
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CustomerNotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildCustomerDrawer(context),
      body: ResponsiveWrapper(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: ResponsiveUtils.getScreenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Disabled Features Banner
            Consumer<AdminProvider>(
              builder: (context, adminProvider, child) {
                final disabledFeatures = adminProvider.featureFlags.entries
                    .where((e) => !e.value)
                    .map((e) => e.key)
                    .toList();
                
                if (disabledFeatures.isEmpty) return const SizedBox.shrink();

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Notice: The following features are currently under maintenance: ${disabledFeatures.join(', ')}.',
                          style: TextStyle(color: Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // ── STATE-BASED PRIMARY HERO / ACTIVE EVENT SECTION ──
            _buildStateBasedHero(context),

            // ── CUSTOMER WITH UPCOMING BOOKINGS SECTION (IF ANY) ──
            _buildUpcomingBookingsSection(context),

            // ── COMPACT "HOW IT WORKS" LINK ──
            _buildHowItWorksLink(context),

            // ── VISUAL CATEGORY SHORTCUTS (EXPLORE 6-8 + SEE ALL CATEGORIES) ──
            _buildVisualCategoryShortcuts(context),
            const SizedBox(height: 20),

            // Event Team Builder Widget
            const EventTeamBuilderWidget(),

            const SizedBox(height: 24),
            _buildRecentlyAddedSection(context),

            const SizedBox(height: 24),
            // Royal Wedding Package Promo
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RoyalWeddingPage(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuD0LnxKEj--7_0Yz7Upkm_dkVsYs2k_sKBCmvrH46T0hkXwdKvSBZMiDxopoH26jD0KhyUfNxy6hnrJVqwsqER2sRx0cWBax2M1CCpeTtLRt-CgoFWiERiQuhdETV3RNSzOQkO6WgyEOfR87squGNfUaZ-g1PWmjllPlvpBbn1TWxHuwbkPlnAEhxVEe5NMIupRSg93-Tajef1otZrekS5qQbcoLHYWqQhJUt7e3XMKFz-OHwO1eCKRVf8sQGkib2a02-J3z19rPSr2"),
                    fit: BoxFit.cover,
                    opacity: 0.6,
                  ),
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'FEATURED PACKAGE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Royal Elegance Wedding',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'All-in-one premium wedding experience',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Text(
                          'Starting RM 42,500',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Featured Venues Section
            const Text(
              'Featured Venues',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            Consumer<VendorProvider>(
              builder: (context, vendorProvider, _) {
                final featuredVenues =
                    vendorProvider.venues.where((v) => v.isFeatured).toList();

                if (vendorProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (featuredVenues.isEmpty) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        'No featured venues available',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                    ),
                  );
                }

                return ResponsiveWrapper(
                  child: SizedBox(
                    height: ResponsiveUtils.isMobile(context) ? 300 : 360,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: featuredVenues.length,
                      itemBuilder: (context, index) {
                        final venue = featuredVenues[index];
                        return Container(
                          key: ValueKey('venue_${venue.id}'),
                          width: ResponsiveUtils.isMobile(context) ? 280 : 350,
                          margin: const EdgeInsets.only(right: 16),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 120,
                              width: double.infinity,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: venue.images.isNotEmpty
                                      ? venue.images.first
                                      : '',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Container(
                                    color: AppTheme.primaryColor
                                        .withOpacity(0.1),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: AppTheme.primaryColor
                                        .withOpacity(0.1),
                                    child: Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    venue.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    venue.description,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        venue.rating.toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'RM ${venue.pricePerPerson.toInt()}/person',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
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
                    },
                  ),
                ),
              );
            },
          ),

            const SizedBox(height: 24),

            // Featured Vendors Section
            const Text(
              'Featured Vendors',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            Consumer<VendorProvider>(
              builder: (context, vendorProvider, _) {
                final vendors = vendorProvider.vendors;

                if (vendorProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (vendors.isEmpty) {
                  return const Center(
                    child: Text(
                      'No vendors available',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  );
                }

                return ResponsiveWrapper(
                  child: SizedBox(
                    height: ResponsiveUtils.isMobile(context) ? 260 : 320,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: vendors.length,
                      itemBuilder: (context, index) {
                        final v = vendors[index];
                        final imageUrl = v.images.isNotEmpty ? v.images.first : v.imageUrl;
                        return GestureDetector(
                          key: ValueKey('vendor_${v.id}'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => VendorServicesScreen(
                                  vendorId: v.id,
                                  vendorName: v.name,
                                  vendorCategory: v.category,
                                  vendorDescription: v.description,
                                  vendorImage: imageUrl,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: ResponsiveUtils.isMobile(context) ? 280 : 350,
                            margin: const EdgeInsets.only(right: 16),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 100,
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl ?? '',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (context, url) => Container(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      child: const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      child: Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: AppTheme.primaryColor.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      v.description.isNotEmpty
                                          ? v.description
                                          : 'No description available',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Categories: ${v.category}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

            const SizedBox(height: 24),

            // Wedding Planners Section
            const Text(
              'Wedding Planners',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Plan your dream wedding with expert planners',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),

            Consumer<VendorProvider>(
              builder: (context, vendorProvider, _) {
                final weddingPlanners = vendorProvider.getWeddingPlannerVendors();

                if (vendorProvider.isLoading) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (weddingPlanners.isEmpty) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        'No wedding planners available at the moment',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: weddingPlanners.length,
                    itemBuilder: (context, index) {
                      final v = weddingPlanners[index];
                      final imageUrl = v.images.isNotEmpty ? v.images.first : v.imageUrl;
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VendorServicesScreen(
                                vendorId: v.id,
                                vendorName: v.name,
                                vendorCategory: v.category,
                                vendorDescription: v.description,
                                vendorImage: imageUrl,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 280,
                          margin: const EdgeInsets.only(right: 16),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 100,
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl ?? '',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (context, url) => Container(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      child: const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      child: Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: AppTheme.primaryColor.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      v.description.isNotEmpty
                                          ? v.description
                                          : 'Professional wedding & event planning',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          v.rating.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          v.category,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),



            const SizedBox(height: 32),

            // Event Tools Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Event Tools',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                   _buildToolCard(
                    context,
                    icon: Icons.hub_outlined,
                    title: 'Plan Hub',
                    color: AppTheme.primaryColor,
                    onTap: () => Navigator.pushNamed(context, '/planning-hub'),
                  ),
                  _buildToolCard(
                    context,
                    icon: Icons.checklist_outlined,
                    title: 'Checklist',
                    color: Colors.purple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerPlannerScreen(initialTab: 1))),
                  ),
                  _buildToolCard(
                    context,
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Budget',
                    color: Colors.green,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerPlannerScreen(initialTab: 2))),
                  ),
                  _buildToolCard(
                    context,
                    icon: Icons.people_outline,
                    title: 'Guests',
                    color: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const guest_list.GuestListScreen())),
                  ),
                  _buildToolCard(
                    context,
                    icon: Icons.favorite_outline,
                    title: 'Favorites',
                    color: Colors.red,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerFavoritesScreen())),
                  ),
                  _buildToolCard(
                    context,
                    icon: Icons.compare_arrows,
                    title: 'Compare',
                    color: Colors.indigo,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompareScreen())),
                  ),
                  _buildToolCard(
                    context,
                    icon: Icons.event_note,
                    title: 'Tentative',
                    color: Colors.teal,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TentativePlannerScreen())),
                  ),
                  _buildToolCard(
                    context,
                    icon: Icons.payment,
                    title: 'Payments',
                    color: Colors.amber,
                    onTap: () {
                      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
                      Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerInstallmentScreen(customerId: userId)));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions Section
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: ResponsiveUtils.getGridColumnCount(context, mobile: 2, tablet: 2, desktop: 4),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: ResponsiveUtils.isMobile(context) ? 0.95 : (ResponsiveUtils.isTablet(context) ? 1.4 : 1.2),
              children: [
                _buildQuickActionCard(
                  icon: Icons.calendar_today,
                  title: 'Book Venue',
                  subtitle: 'Find and book venues',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomerBookingsScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.message,
                  title: 'Contact Vendor',
                  subtitle: 'Chat with vendors',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MessagesScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.hub_rounded,
                  title: 'Planning Hub',
                  subtitle: 'All your tools in one place',
                  onTap: () {
                    Navigator.pushNamed(context, '/planning-hub');
                  },
                ),
                _buildQuickActionCard(
                  icon: Icons.shopping_cart,
                  title: 'Shop',
                  subtitle: 'Buy event supplies',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomerShopScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            if (kIsWeb) ...[
              const SizedBox(height: 32),
              const AppFooter(),
            ],
          ],
        ),
      ),
    ),
  );
}

  // ──────────────────────────────────────────────────────────────────────────
  // STATE-BASED HOME ARCHITECTURE (My Event / Planning CTA / Past Event)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildStateBasedHero(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);

    // 1. New customer (not logged in)
    if (!authProvider.isAuthenticated) {
      return _buildNewCustomerPlanningCta(context);
    }

    final now = DateTime.now();

    // 2. Customer with an upcoming / active event
    final upcomingEvents = eventProvider.events
        .where((e) =>
            e.date.isAfter(now.subtract(const Duration(days: 1))) ||
            e.status == EventStatus.ongoing ||
            e.status == EventStatus.published ||
            e.status == EventStatus.draft)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (upcomingEvents.isNotEmpty) {
      return _buildMyEventActiveCard(context, upcomingEvents.first);
    }

    // 3. Customer with a completed event (past events exist, no upcoming)
    final pastEvents = eventProvider.events
        .where((e) => e.date.isBefore(now.subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (pastEvents.isNotEmpty) {
      return _buildCompletedEventCard(context, pastEvents.first);
    }

    // 4. Logged-in customer without any events yet
    return _buildNewCustomerPlanningCta(context);
  }

  /// Active "My Event" card displayed at the top above generic content
  Widget _buildMyEventActiveCard(BuildContext context, Event activeEvent) {
    final eventProvider = Provider.of<EventProvider>(context);
    final checklists = eventProvider.getChecklistForEvent(activeEvent.id);

    int progressPercent = 0;
    if (checklists.isNotEmpty) {
      final doneCount = checklists.where((c) => c.isDone).length;
      progressPercent = ((doneCount / checklists.length) * 100).round();
    } else {
      progressPercent = 70; // Baseline planning setup progress
    }

    String nextTask = 'Confirm decoration package';
    final pendingTasks = checklists.where((c) => !c.isDone).toList();
    if (pendingTasks.isNotEmpty) {
      nextTask = pendingTasks.first.title;
    } else if (checklists.isEmpty) {
      if (activeEvent.type == EventType.wedding) {
        nextTask = 'Confirm decoration package';
      } else if (activeEvent.type == EventType.birthday) {
        nextTask = 'Order custom cake & balloon theme';
      } else {
        nextTask = 'Confirm venue package & catering';
      }
    } else {
      nextTask = 'All checklist tasks completed! 🎉';
    }

    String formattedDate = '';
    try {
      formattedDate = DateFormat('d MMMM yyyy').format(activeEvent.date);
    } catch (_) {
      formattedDate = '${activeEvent.date.day}/${activeEvent.date.month}/${activeEvent.date.year}';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF231656), Color(0xFF4C2279), Color(0xFF6B3FA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A2A82).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header: Badge + Event Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 14),
                    SizedBox(width: 5),
                    Text(
                      'ACTIVE EVENT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Event Title
          Text(
            activeEvent.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // Planning Progress Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Planning progress — $progressPercent%',
                style: const TextStyle(
                  color: Color(0xFFE2C4FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progressPercent * 1.0).clamp(0, 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (progressPercent / 100.0).clamp(0.05, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
            ),
          ),

          const SizedBox(height: 18),

          // Next Task Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00E5FF), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NEXT TASK',
                        style: TextStyle(
                          color: Color(0xFFE2C4FF),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextTask,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Upcoming Appointments for this Event (Per EventEase Lifecycle Model)
          Builder(
            builder: (context) {
              final workflowProvider = Provider.of<VendorWorkflowProvider>(context);
              final eventAppts = workflowProvider.appointments.where((a) =>
                  a.status != ServiceAppointmentStatus.cancelled &&
                  a.status != ServiceAppointmentStatus.declined).toList();

              if (eventAppts.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upcoming Appointments',
                        style: TextStyle(
                          color: Color(0xFFE2C4FF),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        '${eventAppts.length} Scheduled',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: eventAppts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final apt = eventAppts[idx];
                        final dateStr = DateFormat('dd MMM').format(apt.scheduledDate);

                        return Container(
                          width: 170,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.18)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    child: Icon(apt.purpose.iconData, size: 10, color: Colors.white),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      apt.appointmentTypeName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$dateStr · ${apt.scheduledTime}',
                                style: const TextStyle(
                                  color: Color(0xFFFACC15),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                apt.vendorName,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 10,
                                ),
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
            },
          ),

          const SizedBox(height: 18),

          // Action Buttons: [ Continue Planning ] & Countdown
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/planner',
                      arguments: {'eventId': activeEvent.id},
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text(
                    'Continue Planning',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2A1B6E),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Countdown & Details',
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/event-countdown',
                    arguments: {'event': activeEvent},
                  );
                },
                icon: const Icon(Icons.timer_outlined, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// CTA Card for a new customer without any events
  Widget _buildNewCustomerPlanningCta(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1B6E), Color(0xFF5A2A82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5A2A82).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start planning your event 🎉',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your event and keep vendors, bookings, guests and budget in one place.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleCreateEvent(context),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text(
                'Create an Event',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2A1B6E),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Already invited to an event? ',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/join-event');
                },
                child: const Text(
                  'Join an Event',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF00E5FF),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Completed event celebration card
  Widget _buildCompletedEventCard(BuildContext context, Event pastEvent) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
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
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMPLETED EVENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      pastEvent.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'We hope your celebration was magical! Rate your vendors and keep your memories alive.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CustomerBookingsScreen()),
                    );
                  },
                  icon: const Icon(Icons.star_outline_rounded, size: 16),
                  label: const Text('Rate Vendors', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleCreateEvent(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Plan Another', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Displays upcoming bookings when the customer has active bookings
  Widget _buildUpcomingBookingsSection(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final bookings = bookingProvider.customerBookings;
    if (bookings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Upcoming Bookings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
                letterSpacing: -0.3,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CustomerBookingsScreen()),
                );
              },
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: bookings.length > 5 ? 5 : bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Container(
                width: 260,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event_available, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            booking.vendorName.isNotEmpty ? booking.vendorName : 'Event Vendor',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            booking.serviceName.isNotEmpty ? booking.serviceName : 'Service Booking',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              booking.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Compact "How to Book or Buy" inline link that replaces the bulky 100-line box
  Widget _buildHowItWorksLink(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6B3FA0).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6B3FA0).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.help_outline_rounded,
              size: 16,
              color: Color(0xFF6B3FA0),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'New to EventEase?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          InkWell(
            onTap: () => _showHowItWorksModal(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See how it works',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B3FA0),
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Color(0xFF6B3FA0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHowItWorksModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppTheme.primaryColor, size: 24),
                SizedBox(width: 10),
                Text(
                  'How EventEase Works',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildHowToStepItem(
              number: '1',
              title: 'Book a vendor or venue',
              description:
                  'Explore curated categories, search verified vendors, view portfolios, and book service packages directly.',
            ),
            const SizedBox(height: 14),
            _buildHowToStepItem(
              number: '2',
              title: 'Buy from the shop',
              description:
                  'Browse event decorations, party items, cakes, and supplies. Add them to your cart and checkout easily.',
            ),
            const SizedBox(height: 14),
            _buildHowToStepItem(
              number: '3',
              title: 'Keep everything organized',
              description:
                  'Manage budget, checklist tasks, guest RSVPs, and vendor chats all in one unified dashboard.',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Got it!'),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToStepItem({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF6B3FA0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Color(0xFF6B3FA0),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Visual Category Shortcuts (6-8 key categories horizontally + "See all categories →")
  Widget _buildVisualCategoryShortcuts(BuildContext context) {
    final shortcuts = [
      {'name': 'Venues', 'emoji': '📍', 'keyword': 'Venue'},
      {'name': 'Photography', 'emoji': '📸', 'keyword': 'Photography'},
      {'name': 'Catering', 'emoji': '🍽', 'keyword': 'Catering'},
      {'name': 'Decoration', 'emoji': '🌸', 'keyword': 'Decoration'},
      {'name': 'Entertainment', 'emoji': '🎤', 'keyword': 'Entertainment'},
      {'name': 'Gifts', 'emoji': '🎁', 'keyword': 'Gifts'},
      {'name': 'Cakes', 'emoji': '🎂', 'keyword': 'Cakes'},
      {'name': 'Makeup', 'emoji': '💄', 'keyword': 'Makeup'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Explore',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
                letterSpacing: -0.3,
              ),
            ),
            InkWell(
              onTap: () {
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(2);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                  );
                }
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'See all categories',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 94,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: shortcuts.length,
            itemBuilder: (context, index) {
              final cat = shortcuts[index];
              return Container(
                width: 86,
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SearchScreen(
                          initialCategory: cat['keyword'] as String,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B3FA0).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cat['emoji'] as String,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat['name'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleCreateEvent(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      GuestUtils.promptLogin(context, message: 'Please log in to create and manage your event.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const event_creation.EventCreationScreen(),
      ),
    );
  }

  /// Vendors newest first (by profile `createdAt`).
  Widget _buildRecentlyAddedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recently added',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                );
              },
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'New vendors and services on EventEase',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 14),
        Consumer<VendorProvider>(
          builder: (context, vendorProvider, _) {
            if (vendorProvider.isLoading) {
              return const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final sorted = List<Vendor>.from(vendorProvider.vendors)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final recent = sorted.take(12).toList();
            if (recent.isEmpty) {
              return const SizedBox(
                height: 100,
                child: Center(
                  child: Text(
                    'No vendors yet — check back soon',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                ),
              );
            }
            return SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                itemBuilder: (context, index) {
                  final v = recent[index];
                  final imageUrl =
                      v.images.isNotEmpty ? v.images.first : v.imageUrl;
                  return Padding(
                    padding: EdgeInsets.only(right: index < recent.length - 1 ? 16 : 0),
                    child: _buildRecentVendorCard(context, v, imageUrl),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentVendorCard(
    BuildContext context,
    Vendor v,
    String? imageUrl,
  ) {
    return GestureDetector(
      key: ValueKey('recent_${v.id}'),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VendorServicesScreen(
              vendorId: v.id,
              vendorName: v.name,
              vendorCategory: v.category,
              vendorDescription: v.description,
              vendorImage: imageUrl,
            ),
          ),
        );
      },
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (context, url) => Container(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.storefront_outlined,
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    v.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    v.category.isNotEmpty ? v.category : 'Services',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap to view services & book',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool requiresAuth = true,
  }) {
    return GestureDetector(
      onTap: () {
        if (requiresAuth) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.isAuthenticated) {
            GuestUtils.promptLogin(context, message: 'Please log in to access $title.');
            return;
          }
        }
        onTap();
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool requiresAuth = true,
  }) {
    return GestureDetector(
      onTap: () {
        if (requiresAuth) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.isAuthenticated) {
            GuestUtils.promptLogin(context, message: 'Please log in to access $title.');
            return;
          }
        }
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Customer Drawer Widget
  Widget _buildCustomerDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppTheme.backgroundColor,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Drawer Header
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppTheme.primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to EventEase',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Plan & manage your events',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  // Payment Summary Badge
                  const DrawerPaymentSummary(),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Section: Event Planning Tools
            _buildDrawerSection(
              'Event Planning',
              [
                _buildDrawerItem(
                  icon: Icons.event,
                  label: 'Create Event',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const event_creation.EventCreationScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.event_available,
                  label: 'Join Event',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/join-event');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.manage_history,
                  label: 'Manage Events',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const event_management.EventManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.event_note,
                  label: 'Tentative Planner',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TentativePlannerScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  label: 'Guest List',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const guest_list.GuestListScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.groups,
                  label: 'Groups',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const group_creation.GroupCreationScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.attach_money,
                  label: 'Budget Planner',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomerBudgetScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const Divider(height: 24, indent: 16, endIndent: 16),
            
            // Section: Shopping & Booking
            _buildDrawerSection(
              'Shopping & Services',
              [
                _buildDrawerItem(
                  icon: Icons.shopping_cart,
                  label: 'Shop',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomerShopScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.storefront,
                  label: 'Wedding Resale Marketplace',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WeddingMarketplaceScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_today,
                  label: 'My Bookings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomerBookingsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_month,
                  label: 'My Appointments',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AppointmentsScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.payment,
                  label: 'My Payments',
                  onTap: () {
                    Navigator.pop(context);
                    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerInstallmentScreen(customerId: userId),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.search,
                  label: 'Search Services',
                  requiresAuth: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SearchScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            
            const Divider(height: 24, indent: 16, endIndent: 16),
            
            // Section: Preferences & Collections
            _buildDrawerSection(
              'Collections',
              [
                _buildDrawerItem(
                  icon: Icons.favorite,
                  label: 'Favorites',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomerFavoritesScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.bookmark,
                  label: 'Saved for Later',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SavedForLaterScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.compare_arrows,
                  label: 'Compare Services',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CompareScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.article_outlined,
                  label: 'Blog',
                  requiresAuth: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/blog');
                  },
                ),
              ],
            ),
            
            const Divider(height: 24, indent: 16, endIndent: 16),
            
            // Section: Account & Support
            _buildDrawerSection(
              'Account',
              [
                _buildDrawerItem(
                  icon: Icons.person,
                  label: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AccountScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.message,
                  label: 'Messages',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MessagesScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shopping_cart_checkout,
                  label: 'Order History',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OrderStatusScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help,
                  label: 'Support',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CustomerSupportScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.card_giftcard,
                  label: 'Refer & Earn',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/referrals');
                  },
                ),
              ],
            ),
            

            
            // Settings
            _buildDrawerItem(
              icon: Icons.settings,
              label: 'Settings',
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings
              },
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Helper method to build drawer sections
  Widget _buildDrawerSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool requiresAuth = true,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.textPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      onTap: () {
        if (requiresAuth) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.isAuthenticated) {
            GuestUtils.promptLogin(context, message: 'Please log in to access $label.');
            return;
          }
        }
        onTap();
      },
      hoverColor: AppTheme.primaryColor.withOpacity(0.1),
    );
  }
}
