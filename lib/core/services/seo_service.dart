/// Platform-safe SEO utility.
///
/// On **web**: updates the live `<title>` and `<meta>` tags via dart:js so
/// search engines see the correct metadata for each route.
/// On **mobile / desktop**: all methods are no-ops.
///
/// Usage (call from `initState`):
/// ```dart
/// SeoService.setPage(
///   title: 'Top Wedding Venues KL 2026 | EventEase Blog',
///   description: 'Discover the most breathtaking venues...',
/// );
/// ```
export 'seo_service_stub.dart'
    if (dart.library.js) 'seo_service_web.dart';
