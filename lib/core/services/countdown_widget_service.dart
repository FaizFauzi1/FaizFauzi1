import 'package:home_widget/home_widget.dart';
import 'package:eventease/features/event/data/models/event.dart';

/// Service that bridges Flutter event data → Android home-screen widget
/// using the [home_widget] package.
///
/// The Android [EventCountdownWidget] reads these values from
/// SharedPreferences (prefixed with "flutter." by home_widget internally).
class CountdownWidgetService {
  static const String _appGroupId = 'group.com.example.eventease_new';
  static const String _qualifiedWidgetName =
      'com.example.eventease_new.EventCountdownWidget';

  /// Call once at app startup (or when events change) to initialise.
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// Saves the nearest upcoming event and triggers a widget refresh.
  /// Pass [null] to clear the widget (shows "No upcoming events").
  static Future<void> saveAndUpdate(Event? event) async {
    if (event == null) {
      await HomeWidget.saveWidgetData<String>('event_title', null);
      await HomeWidget.saveWidgetData<int>('event_time_ms', null);
    } else {
      await HomeWidget.saveWidgetData<String>('event_title', event.title);
      await HomeWidget.saveWidgetData<int>(
        'event_time_ms',
        event.startTime.millisecondsSinceEpoch,
      );
    }
    // Tell Android to redraw all instances of the widget
    await HomeWidget.updateWidget(
      name: _qualifiedWidgetName,
      iOSName: 'EventCountdownWidget', // iOS placeholder, not used yet
    );
  }

  /// Find the nearest future event from a list and save it.
  static Future<void> saveNearestEvent(List<Event> events) async {
    final now = DateTime.now();
    final upcoming = events
        .where((e) => e.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    await saveAndUpdate(upcoming.isEmpty ? null : upcoming.first);
  }
}
