import 'package:shared_preferences/shared_preferences.dart';

/// Persists the organizer's active expo for screens that are not route-scoped.
class OrganizerScope {
  OrganizerScope._();

  static const _activeExpoKey = 'organizer_active_expo_id';

  static Future<String?> getActiveExpoId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeExpoKey);
  }

  static Future<void> setActiveExpoId(String? expoId) async {
    final prefs = await SharedPreferences.getInstance();
    if (expoId == null || expoId.isEmpty) {
      await prefs.remove(_activeExpoKey);
    } else {
      await prefs.setString(_activeExpoKey, expoId);
    }
  }
}
