import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:eventease/core/constants/app_config.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  StreamSubscription<Uri>? _appLinksSubscription;
  final _appLinks = AppLinks();
  GlobalKey<NavigatorState>? _navigatorKey;
  Uri? _pendingUri;
  bool isInitialized = false;
  Uri? _lastProcessedUri;
  DateTime? _lastProcessTime;

  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    isInitialized = true;
    
    // 1. Listen for all incoming links using app_links (works for 3rd party scanners)
    _appLinksSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('DEEP LINK (AppLinks): Received link: $uri');
      _handleDeepLink(uri);
    });

    // 3. Check for initial link (if the app was opened via a link)
    _checkInitialLink();
  }

  Future<void> _checkInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('DEEP LINK (Initial): Received link: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('DEEP LINK ERROR: Failed to get initial link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('DEEP LINK: Processing URI: $uri');
    
    // Prevent duplicate processing of the same link within a short timeframe
    final now = DateTime.now();
    if (_lastProcessedUri == uri && _lastProcessTime != null && now.difference(_lastProcessTime!).inSeconds < 2) {
      debugPrint('DEEP LINK: Skipping duplicate link within 2 seconds');
      return;
    }
    _lastProcessedUri = uri;
    _lastProcessTime = now;

    final segments = uri.pathSegments;

    // Standard robust parsing logic
    String? vendorId;
    String? serviceId;

    // Support both eventease:// and https:// patterns
    if (uri.scheme == 'eventease') {
      if (uri.host == 'vendor') {
        vendorId = segments.isNotEmpty ? segments.first : null;
        if (vendorId == null || vendorId.isEmpty) {
           vendorId = uri.path.replaceAll('/', '');
        }
      } else if (uri.host == 'service') {
        serviceId = segments.isNotEmpty ? segments.first : null;
        if (serviceId == null || serviceId.isEmpty) {
           serviceId = uri.path.replaceAll('/', '');
        }
      }
    } else if (AppConfig.supportedDomains.any((domain) => uri.host == domain) || uri.path.contains('/vendor/') || uri.path.contains('/service/')) {
      // Find vendor keyword (support singular or plural)
      final vendorIndex = segments.indexWhere((s) => s == 'vendor' || s == 'vendors');
      if (vendorIndex != -1 && vendorIndex + 1 < segments.length) {
        vendorId = segments[vendorIndex + 1];
      }
      
      // Find service keyword (support singular or plural)
      final serviceIndex = segments.indexWhere((s) => s == 'service' || s == 'services');
      if (serviceIndex != -1 && serviceIndex + 1 < segments.length) {
        serviceId = segments[serviceIndex + 1];
      }

      // Find invitation/join keyword
      final joinIndex = segments.indexWhere((s) => s == 'join' || s == 'invitation' || s == 'invite' || s == 'rsvp');
      if (joinIndex != -1 && joinIndex + 1 < segments.length) {
        final invitationCode = segments[joinIndex + 1];
        debugPrint('DEEP LINK: Found invitation code: $invitationCode');
        _pendingUri = uri;
        _navigateTo('/invitation', {'invitationCode': invitationCode});
        return;
      }
    }

    // Support eventease://rsvp/CODE or eventease://invite/CODE
    if (uri.scheme == 'eventease' && (uri.host == 'join' || uri.host == 'invitation' || uri.host == 'invite' || uri.host == 'rsvp')) {
      final invitationCode = segments.isNotEmpty ? segments.first : null;
      if (invitationCode != null && invitationCode.isNotEmpty) {
        debugPrint('DEEP LINK: Found invitation code: $invitationCode');
        _pendingUri = uri;
        _navigateTo('/invitation', {'invitationCode': invitationCode});
        return;
      }
    }

    // Final sanitization
    vendorId = vendorId?.replaceAll('/', '')?.trim();
    serviceId = serviceId?.replaceAll('/', '')?.trim();

    // If this is a cold start, we might want to let the SplashScreen handle it
    // But for now, we follow the existing pattern of navigation
    if (vendorId != null && vendorId.isNotEmpty) {
      debugPrint('DEEP LINK: Found vendor: $vendorId');
      _pendingUri = uri; // Store it as pending
      _navigateTo('/vendor-profile', {'vendorId': vendorId});
    } else if (serviceId != null && serviceId.isNotEmpty) {
      debugPrint('DEEP LINK: Found service: $serviceId');
      _pendingUri = uri; // Store it as pending
      _navigateTo('/product-detail', {'serviceId': serviceId});
    }
  }

  bool get hasPendingDeepLink => _pendingUri != null;

  Uri? consumePendingUri() {
    final uri = _pendingUri;
    _pendingUri = null;
    return uri;
  }

  void _navigateTo(String routeName, Map<String, dynamic> arguments) {
    if (_navigatorKey?.currentState == null) {
      debugPrint('DEEP LINK: Navigator state is null, delaying navigation');
      Future.delayed(const Duration(milliseconds: 800), () => _navigateTo(routeName, arguments));
      return;
    }

    _navigatorKey!.currentState!.pushNamed(
      routeName,
      arguments: arguments,
    );
  }

  void dispose() {
    _appLinksSubscription?.cancel();
  }
}
