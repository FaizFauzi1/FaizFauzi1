import 'package:eventease/features/organizer/data/organizer_demo_store.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Demo = in-app sample data (offline preview). Live = Supabase tables/views.
enum OrganizerDataSource { demo, live }

class OrganizerDataMode {
  OrganizerDataMode._();

  static const _prefsKey = 'organizer_data_source';

  static Future<OrganizerDataSource> get() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_prefsKey);
    return value == 'demo' ? OrganizerDataSource.demo : OrganizerDataSource.live;
  }

  static Future<bool> get isDemo async => (await get()) == OrganizerDataSource.demo;

  static Future<void> set(OrganizerDataSource source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      source == OrganizerDataSource.live ? 'live' : 'demo',
    );
  }
}

/// Notifies organizer screens to reload when demo/live mode changes.
class OrganizerDataModeController extends ChangeNotifier {
  OrganizerDataModeController._();

  static final OrganizerDataModeController instance = OrganizerDataModeController._();

  OrganizerDataSource _source = OrganizerDataSource.live;
  bool _loaded = false;

  OrganizerDataSource get source => _source;
  bool get isDemo => _source == OrganizerDataSource.demo;
  bool get isLive => _source == OrganizerDataSource.live;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _source = await OrganizerDataMode.get();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setSource(OrganizerDataSource source) async {
    if (_source == source) return;
    await OrganizerDataMode.set(source);
    _source = source;
    if (source == OrganizerDataSource.demo) {
      OrganizerDemoStore.instance.reset();
    }
    notifyListeners();
  }
}
