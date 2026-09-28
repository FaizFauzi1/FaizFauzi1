import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:seo/seo.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_skill/flutter_skill.dart';
import 'package:eventease/l10n/app_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/features/admin/data/providers/admin_bypass_provider.dart';
import 'package:eventease/features/admin/data/providers/admin_disputes_provider.dart';
import 'package:eventease/features/admin/data/providers/admin_revenue_provider.dart';
import 'package:eventease/features/admin/data/providers/admin_churn_provider.dart';
import 'package:eventease/features/admin/data/providers/admin_notification_provider.dart';
import 'package:eventease/features/admin/data/providers/admin_marketplace_provider.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/blog/data/providers/blog_provider.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/features/booking/data/providers/cart_provider.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:eventease/features/finance/data/providers/commission_provider.dart';
import 'package:eventease/features/customer/data/providers/customer_subscription_provider.dart';
import 'package:eventease/features/customer/data/providers/compare_provider.dart';
import 'package:eventease/features/customer/data/providers/customer_provider.dart';
import 'package:eventease/features/customer/data/providers/save_for_later_provider.dart';
import 'package:eventease/features/customer/data/providers/review_provider.dart';
import 'package:eventease/features/customer/data/providers/marketplace_provider.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/features/customer/data/providers/favorites_provider.dart';
import 'package:eventease/features/notifications/data/providers/notification_provider.dart';
import 'package:eventease/features/guest/data/providers/guest_provider.dart';
import 'package:eventease/features/event/data/providers/invitation_provider.dart';
import 'package:eventease/features/guest/data/providers/event_wish_provider.dart';
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
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_analytics_provider.dart';
import 'package:eventease/features/vendor/data/providers/subscription_provider.dart';
import 'package:eventease/features/location/data/providers/location_provider.dart';
import 'package:eventease/features/budget/data/providers/budget_provider.dart';
import 'package:eventease/features/booking/data/providers/appointment_provider.dart';
import 'package:eventease/shared/providers/category_provider.dart';
import 'package:eventease/core/providers/coupon_provider.dart';
import 'package:eventease/features/referral/data/referral_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/app_routes.dart';
import 'package:eventease/shared/views/splash_screen.dart';
import 'package:eventease/core/database/platform_database_service.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/features/gift_registry/data/providers/gift_registry_provider.dart';
import 'package:eventease/core/providers/country_provider.dart';
import 'package:eventease/core/utils/currency_formatter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eventease/firebase_options.dart';
import 'package:eventease/core/services/deep_link_service.dart';
import 'package:eventease/core/services/analytics_service.dart';

// Global navigator key for deep linking
final GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Initialize database factory for desktop and web platforms BEFORE ANYTHING ELSE
  PlatformDatabaseService.initializeDatabaseFactory();

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize CurrencyFormatter
  try {
    await CurrencyFormatter.init();
    print('✅ CurrencyFormatter initialized successfully!');
  } catch (e) {
    print('❌ CurrencyFormatter initialization failed: $e');
  }

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded.');
  } catch (e) {
    print('⚠️ Could not load .env file. Ensure it exists. Error: $e');
  }

  // Initialize PostHog Analytics
  try {
    await AnalyticsService().init();
  } catch (e) {
    print('⚠️ PostHog Analytics initialization failed: $e');
  }

  // Enables flutter_skill (AI agent UI control) when running in debug mode.
  if (kDebugMode) {
    FlutterSkillBinding.ensureInitialized();
  }
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully!');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
  }

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
    print('✅ Supabase initialized successfully!');
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
  }

  // Initialize database BEFORE creating providers (native platforms only; web uses IndexedDB)
  if (!kIsWeb) {
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

      // Show counts including services and packages
      if (testResult['platform'] == 'mobile') {
        print(
            '   Users: ${testResult['users']}, Vendors: ${testResult['vendors']}, Customers: ${testResult['customers']}, Services: ${testResult['services']}, Packages: ${testResult['packages']}');
      }
    } catch (e) {
      print('❌ Database initialization failed: $e');
    }
  } else {
    print('✅ Web platform — skipping sqflite init, using cloud storage.');
  }

  // Initialize DeepLinkService
  DeepLinkService().initialize(mainNavigatorKey);

  // Setup Global Overflow Detector
  if (kDebugMode) {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final String exceptionString = details.exceptionAsString();
      if (exceptionString.contains('overflowed by')) {
        // Extract pixel count using Regex
        final pixelMatch = RegExp(r'overflowed by ([\d\.]+) pixels').firstMatch(exceptionString);
        final sideMatch = RegExp(r'on the (\w+)').firstMatch(exceptionString);
        
        final String pixels = pixelMatch?.group(1) ?? 'unknown';
        final String side = sideMatch?.group(1) ?? 'unknown';
        
        String? currentScreen = 'Unknown Screen';
        try {
          if (mainNavigatorKey.currentState != null) {
            mainNavigatorKey.currentState!.popUntil((route) {
              currentScreen = route.settings.name;
              if (currentScreen == null && route is MaterialPageRoute) {
                currentScreen = route.builder.runtimeType.toString();
              }
              currentScreen ??= route.runtimeType.toString();
              return true;
            });
          }
        } catch (_) {}
        
        // Log to console with detailed styling
        debugPrint('\n🚨 OVERFLOW DETECTED 🚨');
        debugPrint('Amount: $pixels pixels');
        debugPrint('Side:   $side');
        debugPrint('Screen: $currentScreen');
        debugPrint('Location: ${details.library}');
        debugPrint('Context: ${details.context}');
        debugPrint('─────────────────────────\n');
        
        // Show a detailed snackbar
        if (mainNavigatorKey.currentState != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(mainNavigatorKey.currentContext!).showSnackBar(
              SnackBar(
                content: Text('⚠️ Overflow on $currentScreen: $pixels px on the $side!'),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'DETAILS',
                  textColor: Colors.white,
                  onPressed: () {
                    showDialog(
                      context: mainNavigatorKey.currentContext!,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Overflow Details'),
                        content: SingleChildScrollView(
                          child: Text(exceptionString, style: const TextStyle(fontSize: 12)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('CLOSE'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          });
        }
      }
      oldOnError?.call(details);
    };
  }

  runApp(const EventEaseApp());
}

class EventEaseApp extends StatelessWidget {
  const EventEaseApp({super.key});

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
        ChangeNotifierProvider(create: (_) => CountryProvider()..init()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => TentativePlannerProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => AdminBypassProvider()),
        ChangeNotifierProvider(create: (_) => AdminDisputesProvider()),
        ChangeNotifierProvider(create: (_) => AdminRevenueProvider()),
        ChangeNotifierProvider(create: (_) => AdminChurnProvider()),
        ChangeNotifierProvider(create: (_) => AdminNotificationProvider()),
        ChangeNotifierProvider(create: (_) => AdminMarketplaceProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => GuestProvider()),
        ChangeNotifierProvider(create: (_) => InvitationProvider()),
        ChangeNotifierProvider(create: (_) => GiftRegistryProvider()),
        ChangeNotifierProvider(create: (_) => EventWishProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
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
        ChangeNotifierProxyProvider<CustomerProvider, BudgetProvider>(
          create: (context) {
            final customerProvider =
                Provider.of<CustomerProvider>(context, listen: false);
            return BudgetProvider(customerProvider);
          },
          update: (context, customerProvider, previous) {
            return previous ?? BudgetProvider(customerProvider);
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
            return FavoritesProvider(userId: userId);
          },
          update: (context, authProvider, previous) {
            final userId =
                authProvider.isAuthenticated ? authProvider.userId : null;
            if (previous?.userId != userId) {
              previous?.updateUserId(userId);
            }
            return previous ?? FavoritesProvider(userId: userId);
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, CustomerSubscriptionProvider>(
          create: (_) => CustomerSubscriptionProvider(),
          update: (_, auth, prev) => 
            (prev ?? CustomerSubscriptionProvider())..updateUserId(auth.userId),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider(), lazy: false),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(),
          update: (context, authProvider, previous) {
            final provider = previous ?? OrderProvider();
            if (authProvider.isAuthenticated && authProvider.userId != null) {
              provider.loadCustomerOrders(authProvider.userId!);
            }
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => RequestProvider()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
        ChangeNotifierProvider(create: (_) => MarketingProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider<VendorProvider>(
          create: (_) {
            final vendorProvider = VendorProvider();
            vendorProvider.loadSampleVendors();
            return vendorProvider;
          },
        ),
        ChangeNotifierProvider<VendorNetworkingProvider>(
          create: (_) => VendorNetworkingProvider(),
        ),
        ChangeNotifierProvider(create: (_) => VendorWorkflowProvider()),
        ChangeNotifierProvider(create: (_) => VendorProfileProvider()),
        ChangeNotifierProvider(create: (_) => VendorAnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => CouponProvider()),
        ChangeNotifierProvider(create: (_) => ReferralProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => BlogProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => MarketplaceProvider()),
      ],
      child: PostHogWidget(
        child: Consumer2<ThemeProvider, LocaleProvider>(
          builder: (context, themeProvider, localeProvider, child) {
            return SeoController(
              // Only enable SEO tree on web; no-op on mobile/desktop.
              enabled: kIsWeb,
              tree: WidgetTree(context: context),
              child: MaterialApp(
                navigatorKey: mainNavigatorKey,
                navigatorObservers: [PosthogObserver()],
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
              ),
            );
          },
        ),
      ),
    );
  }
}
