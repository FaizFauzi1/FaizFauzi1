import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:eventease/core/constants/app_config.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _isInitialized = false;

  /// Initialize PostHog Analytics SDK
  Future<void> init() async {
    if (_isInitialized) return;

    final apiKey = dotenv.env['POSTHOG_API_KEY'] ?? AppConfig.posthogApiKey;
    final host = dotenv.env['POSTHOG_HOST'] ?? AppConfig.posthogHost;

    if (apiKey.isEmpty || apiKey.contains('YOUR_POSTHOG_API_KEY')) {
      debugPrint('PostHog Analytics: Skipped initialization (API key not configured).');
      return;
    }

    try {
      final config = PostHogConfig(apiKey);
      config.host = host;
      config.captureApplicationLifecycleEvents = true;
      config.debug = kDebugMode;

      // Enable Session Replay
      config.sessionReplay = true;
      config.sessionReplayConfig.maskAllTexts = false;
      config.sessionReplayConfig.maskAllImages = false;
      config.sessionReplayConfig.throttleDelay = const Duration(milliseconds: 1000);

      await Posthog().setup(config);
      _isInitialized = true;
      debugPrint('PostHog Analytics initialized successfully.');

      // Send immediate test ping to verify connection in PostHog Web UI
      await Posthog().capture(
        eventName: 'app_initialized',
        properties: {
          'platform': defaultTargetPlatform.name,
          'environment': kDebugMode ? 'debug' : 'production',
        },
      );
      await Posthog().flush();
    } catch (e) {
      debugPrint('PostHog Analytics initialization failed: $e');
    }
  }

  /// Identify current user and assign properties/traits
  Future<void> identify({
    required String userId,
    String? email,
    String? name,
    String? userType,
    Map<String, Object>? additionalProperties,
  }) async {
    if (!_isInitialized) return;

    final properties = <String, Object>{
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (userType != null) 'user_type': userType,
      ...?additionalProperties,
    };

    try {
      await Posthog().identify(
        userId: userId,
        userProperties: properties,
      );
      await Posthog().flush();
      debugPrint('PostHog Identified user: $userId');
    } catch (e) {
      debugPrint('PostHog identify notice: $e');
    }
  }

  /// Reset identity upon logout
  Future<void> reset() async {
    if (!_isInitialized) return;
    try {
      await Posthog().reset();
      await Posthog().flush();
      debugPrint('PostHog session reset.');
    } catch (e) {
      debugPrint('PostHog reset notice: $e');
    }
  }

  /// Capture a custom analytics event
  Future<void> capture(String eventName, {Map<String, Object>? properties}) async {
    if (!_isInitialized) return;
    try {
      await Posthog().capture(
        eventName: eventName,
        properties: properties,
      );
      await Posthog().flush();
      debugPrint('PostHog Event Captured: $eventName ${properties ?? ''}');
    } catch (e) {
      debugPrint('PostHog capture notice ($eventName): $e');
    }
  }

  /// Screen view tracking
  Future<void> screen(String screenName, {Map<String, Object>? properties}) async {
    if (!_isInitialized) return;
    try {
      await Posthog().screen(
        screenName: screenName,
        properties: properties,
      );
      await Posthog().flush();
    } catch (e) {
      debugPrint('PostHog screen notice: $e');
    }
  }

  /// Flush queued events to server immediately
  Future<void> flush() async {
    if (!_isInitialized) return;
    try {
      await Posthog().flush();
      debugPrint('PostHog events manually flushed.');
    } catch (e) {
      debugPrint('PostHog flush notice: $e');
    }
  }

  // --------------------------------------------------------------------------
  // DOMAIN-SPECIFIC EVENT TRACKERS
  // --------------------------------------------------------------------------

  /// Track when a digital card or PDF invitation is shared
  void trackInvitationShared({
    required String eventId,
    required String format, // 'image_card', 'pdf', 'text_link'
    required String template, // 'weddingFloral', 'birthdayBash', 'custom_image', etc.
    String? guestName,
    bool hasCustomWebsite = false,
  }) {
    capture('invitation_shared', properties: {
      'event_id': eventId,
      'format': format,
      'template': template,
      'has_guest_name': guestName != null,
      'has_custom_website': hasCustomWebsite,
      'platform': 'whatsapp',
    });
  }

  /// Track event creation or edit
  void trackEventCreated({
    required String eventId,
    required String eventType,
    required int maxGuests,
  }) {
    capture('event_created', properties: {
      'event_id': eventId,
      'event_type': eventType,
      'max_guests': maxGuests,
    });
  }

  /// Track user login
  void trackLogin({required String userId, String method = 'email'}) {
    capture('user_login', properties: {
      'user_id': userId,
      'login_method': method,
    });
  }

  /// Track user registration / signup
  void trackSignUp({required String userId, required String userRole, String method = 'email'}) {
    capture('user_signup', properties: {
      'user_id': userId,
      'user_role': userRole,
      'signup_method': method,
    });
  }

  /// Track when a vendor profile is viewed
  void trackVendorViewed({
    required String vendorId,
    required String vendorName,
    String? category,
  }) {
    capture('vendor_viewed', properties: {
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      if (category != null) 'category': category,
    });
  }

  /// Track when a booking is created
  void trackBookingCreated({
    required String bookingId,
    required String vendorId,
    required double amount,
    String? status,
  }) {
    capture('booking_created', properties: {
      'booking_id': bookingId,
      'vendor_id': vendorId,
      'amount': amount,
      if (status != null) 'status': status,
    });
  }

  /// Track search queries
  void trackSearchQuery({required String query, String? category}) {
    capture('search_performed', properties: {
      'query': query,
      if (category != null) 'category': category,
    });
  }

  /// Track any button tap with an optional screen and extra properties
  void trackButtonTapped(String buttonName, {String? screen, Map<String, Object>? properties}) {
    capture('button_tapped', properties: {
      'button_name': buttonName,
      if (screen != null) 'screen': screen,
      ...?properties,
    });
  }

  /// Track bottom-navigation or tab bar changes
  void trackTabChanged({required String tabName, required int tabIndex, String? screen}) {
    capture('tab_changed', properties: {
      'tab_name': tabName,
      'tab_index': tabIndex,
      if (screen != null) 'screen': screen,
    });
  }
}

