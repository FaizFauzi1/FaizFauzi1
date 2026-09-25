// Stub implementation for non-web platforms.
// All methods are no-ops so it's safe to call everywhere.
class SeoService {
  SeoService._();

  static void setPage({required String title, String description = ''}) {
    // No-op on mobile/desktop
  }
}
