import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/features/booking/data/providers/cart_provider.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:eventease/features/finance/data/providers/commission_provider.dart';
import 'package:eventease/features/customer/data/providers/compare_provider.dart';
import 'package:eventease/features/customer/data/providers/customer_provider.dart';
import 'package:eventease/features/customer/data/providers/save_for_later_provider.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/features/customer/data/providers/favorites_provider.dart';
import 'package:eventease/features/guest/data/providers/guest_provider.dart';
import 'package:eventease/features/event/data/providers/invitation_provider.dart';
import 'package:eventease/features/marketing/data/providers/marketing_provider.dart';
import 'package:eventease/features/booking/data/providers/order_provider.dart';
import 'package:eventease/features/booking/data/providers/payment_provider.dart';
import 'package:eventease/features/support/data/providers/request_provider.dart';
import 'package:eventease/features/support/data/providers/support_provider.dart';
import 'package:eventease/features/finance/data/providers/finance_provider.dart';
import 'package:eventease/features/services/data/providers/shop_provider.dart';
import 'package:eventease/core/providers/theme_provider.dart';
import 'package:eventease/core/providers/locale_provider.dart';
import 'package:eventease/core/providers/ad_provider.dart';
import 'package:eventease/features/event/data/providers/tentative_planner_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/vendor/data/providers/vendor_networking_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_analytics_provider.dart';
import 'package:eventease/core/providers/coupon_provider.dart';
import 'package:eventease/features/referral/data/referral_provider.dart';
import 'package:eventease/features/customer/data/providers/marketplace_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/app_routes.dart';
import 'package:eventease/shared/views/splash_screen.dart';
import 'package:eventease/core/database/platform_database_service.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:eventease/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
    print('✅ Supabase initialized successfully!');
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
  }

  // Initialize database
  try {
    final dbService = PlatformDatabaseService();
    await dbService.initializeDatabase();
    print('✅ Database initialized successfully!');

    // Test database
    final testResult = await dbService.testDatabase();
    print('📊 Database test: ${testResult['message']}');
    if (testResult['platform'] == 'mobile') {
      print(
          '   Users: ${testResult['users']}, Vendors: ${testResult['vendors']}, Customers: ${testResult['customers']}');
    }

    // Show database info
    final dbInfo = await dbService.getDatabaseInfo();
    print('📁 Database location: ${dbInfo['path']}');
    print('   Platform: ${dbInfo['platform']}');
    print('   Size: ${dbInfo['sizeKB']} KB');
  } catch (e) {
    print('❌ Database initialization failed: $e');
  }

  runApp(const EventEaseCustomerVendorApp());
}

class EventEaseCustomerVendorApp extends StatelessWidget {
  const EventEaseCustomerVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => TentativePlannerProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => GuestProvider()),
        ChangeNotifierProvider(create: (_) => InvitationProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (context) {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final userId =
                authProvider.isAuthenticated ? authProvider.userId : null;
            return CartProvider(userId: userId);
          },
          update: (context, authProvider, previous) {
            final userId =
                authProvider.isAuthenticated ? authProvider.userId : null;
            previous?.updateUserId(userId);
            return previous ?? CartProvider(userId: userId);
          },
        ),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProxyProvider2<BookingProvider, ChatProvider,
            CustomerProvider>(
          create: (context) {
            final bookingProvider =
                Provider.of<BookingProvider>(context, listen: false);
            final chatProvider =
                Provider.of<ChatProvider>(context, listen: false);
            return CustomerProvider(bookingProvider, chatProvider);
          },
          update: (context, bookingProvider, chatProvider, previous) {
            return previous ?? CustomerProvider(bookingProvider, chatProvider);
          },
        ),
        ChangeNotifierProvider(create: (_) => CommissionProvider()),
        ChangeNotifierProvider(create: (_) => CompareProvider()),
        ChangeNotifierProvider(create: (_) => SaveForLaterProvider()),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (context) {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final userId =
                authProvider.isAuthenticated ? authProvider.userId : null;
            final provider = FavoritesProvider(userId: userId);
            provider.loadFavoritesFromStorage();
            return provider;
          },
          update: (context, authProvider, previous) {
            final userId =
                authProvider.isAuthenticated ? authProvider.userId : null;
            if (previous?.userId != userId) {
              previous?.updateUserId(userId);
            }
            // Ensure favorites are loaded after user authentication
            if (userId != null) {
              previous?.ensureFavoritesLoaded();
            }
            return previous ?? FavoritesProvider(userId: userId);
          },
        ),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
        ChangeNotifierProvider(create: (_) => MarketingProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider<VendorProvider>(
          create: (_) {
            final vendorProvider = VendorProvider();
            // Load sample vendors after provider is created
            vendorProvider.loadSampleVendors();
            return vendorProvider;
          },
        ),
        ChangeNotifierProvider<VendorNetworkingProvider>(
          create: (_) => VendorNetworkingProvider(),
        ),
        ChangeNotifierProvider(create: (_) => VendorProfileProvider()),
        ChangeNotifierProvider(create: (_) => VendorAnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => CouponProvider()),
        ChangeNotifierProvider(create: (_) => ReferralProvider()),
        ChangeNotifierProvider(create: (_) => MarketplaceProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'EventEase',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              ...AppLocalizations.localizationsDelegates,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SplashScreen(),
            routes: getAppRoutes(),
          );
        },
      ),
    );
  }
}
