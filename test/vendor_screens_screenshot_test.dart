import 'dart:io';
import 'dart:ui' as ui;

import 'package:eventease/core/utils/app_routes.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/features/booking/data/providers/cart_provider.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:eventease/features/customer/data/providers/customer_provider.dart';
import 'package:eventease/features/customer/data/providers/favorites_provider.dart';
import 'package:eventease/features/customer/data/providers/save_for_later_provider.dart';
import 'package:eventease/features/customer/data/providers/compare_provider.dart';
import 'package:eventease/features/notifications/data/providers/notification_provider.dart';
import 'package:eventease/features/services/data/providers/shop_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/vendor/data/providers/vendor_networking_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_analytics_provider.dart';
import 'package:eventease/features/vendor/data/providers/subscription_provider.dart';
import 'package:eventease/core/providers/theme_provider.dart';
import 'package:eventease/core/providers/locale_provider.dart';
import 'package:eventease/core/providers/ad_provider.dart';
import 'package:eventease/core/providers/coupon_provider.dart';
import 'package:eventease/shared/providers/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Generates PNG screenshots of vendor routes using widget tests.
///
/// Run:
///   flutter test test/vendor_screens_screenshot_test.dart
///
/// Output:
///   screenshots/vendor_widget/<nn>_<route>.png
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    
    // Initialize dotenv for testing environment
    dotenv.testLoad(fileInput: '''
      SUPABASE_URL=https://mock.supabase.co
      SUPABASE_ANON_KEY=mock-key
    ''');

    // Many providers/screens touch Supabase during initialization. For screenshot
    // generation we just need Supabase.instance to be initialized.
    await SupabaseService.initialize();
  });

  const vendorRoutes = <String>[
    '/vendor-dashboard',
    '/vendor-services',
    '/vendor-booking-management',
    '/vendor-booking-status',
    '/vendor-finance',
    '/vendor-shop-performance',
    '/vendor-marketing',
    '/vendor-promotions',
    '/vendor-analytics',
    '/vendor-inventory',
    '/vendor-customers',
    '/crm-dashboard',
    '/vendor-loyalty',
    '/vendor-subscriptions',
    '/vendor-support',
    '/vendor-help',
    '/vendor-settings',
    '/vendor-payment-payout',
    '/vendor-social-media',
    '/vendor-qr-codes',
    '/vendor-availability-management',
    '/networking',
    '/find-partners',
    '/collaboration-requests',
    '/package-builder',
    '/vendor-groups',
    '/marketplace',
    '/product-service-demo',
  ];

  testWidgets('capture vendor route screenshots', (tester) async {
    final outDir = Directory('${Directory.current.path}/screenshots/vendor_widget');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);

    // Set a stable viewport for screenshots.
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repaintKey = GlobalKey();

    for (var i = 0; i < vendorRoutes.length; i++) {
      final route = vendorRoutes[i];

      await tester.pumpWidget(_TestApp(initialRoute: route, repaintKey: repaintKey));
      await tester.pump(); // first frame
      // Avoid pumpAndSettle: many screens have ongoing animations / async work.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 16));

      final fileSafeRoute = route.replaceAll('/', '_').replaceAll(RegExp(r'__+'), '_');
      final fileName = '${(i + 1).toString().padLeft(2, '0')}$fileSafeRoute.png';
      final outFile = File('${outDir.path}/$fileName');

      await tester.runAsync(() async {
        await _writeScreenshotPng(repaintKey, outFile);
      });

      expect(outFile.existsSync(), isTrue, reason: 'Screenshot not written: ${outFile.path}');
    }
  }, timeout: const Timeout(Duration(minutes: 15)));
}

class _TestApp extends StatelessWidget {
  final String initialRoute;
  final GlobalKey repaintKey;
  const _TestApp({required this.initialRoute, required this.repaintKey});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (context) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            return CartProvider(userId: auth.isAuthenticated ? auth.userId : null);
          },
          update: (context, auth, previous) {
            final userId = auth.isAuthenticated ? auth.userId : null;
            previous?.updateUserId(userId);
            return previous ?? CartProvider(userId: userId);
          },
        ),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProxyProvider2<BookingProvider, ChatProvider, CustomerProvider>(
          create: (context) {
            final booking = Provider.of<BookingProvider>(context, listen: false);
            final chat = Provider.of<ChatProvider>(context, listen: false);
            return CustomerProvider(booking, chat);
          },
          update: (context, booking, chat, previous) =>
              previous ?? CustomerProvider(booking, chat),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FavoritesProvider>(
          create: (context) {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            return FavoritesProvider(userId: auth.isAuthenticated ? auth.userId : null);
          },
          update: (context, auth, previous) {
            final userId = auth.isAuthenticated ? auth.userId : null;
            if (previous?.userId != userId) previous?.updateUserId(userId);
            return previous ?? FavoritesProvider(userId: userId);
          },
        ),
        ChangeNotifierProvider(create: (_) => CompareProvider()),
        ChangeNotifierProvider(create: (_) => SaveForLaterProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider<VendorProvider>(
          create: (_) {
            final p = VendorProvider();
            p.loadSampleVendors();
            return p;
          },
        ),
        ChangeNotifierProvider<VendorNetworkingProvider>(
          create: (_) {
            final p = VendorNetworkingProvider();
            p.loadSampleData();
            return p;
          },
        ),
        ChangeNotifierProvider(create: (_) => VendorProfileProvider()),
        ChangeNotifierProvider(create: (_) => VendorAnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => CouponProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: RepaintBoundary(
        key: repaintKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          routes: getAppRoutes(),
          initialRoute: initialRoute,
        ),
      ),
    );
  }
}

Future<void> _writeScreenshotPng(GlobalKey repaintKey, File outFile) async {
  final context = repaintKey.currentContext;
  if (context == null) {
    throw StateError('RepaintBoundary context not available.');
  }

  final renderObject = context.findRenderObject();
  if (renderObject is! RenderRepaintBoundary) {
    throw StateError('Expected RenderRepaintBoundary, got ${renderObject.runtimeType}.');
  }

  if (renderObject.debugNeedsPaint) {
    // Best-effort: the caller should have pumped, but some screens schedule
    // additional frames; we still try to capture what is currently rendered.
  }

  final ui.Image image = await renderObject.toImage(pixelRatio: 1.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Failed to encode screenshot PNG.');
  }
  await outFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
}

