import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TentativeEvent {
  final String id;
  String title;
  DateTime date;
  String? location;
  String? notes;

  TentativeEvent({
    required this.id,
    required this.title,
    required this.date,
    this.location,
    this.notes,
  });

  factory TentativeEvent.fromMap(Map<String, dynamic> m) => TentativeEvent(
        id: m['id'] as String,
        title: m['title'] as String,
        date: DateTime.parse(m['date'] as String),
        location: m['location'] as String?,
        notes: m['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'location': location,
        'notes': notes,
      };
}

class TentativePlannerProvider extends ChangeNotifier {
  static const _storageKey = 'tentative_events_v1';

  final List<TentativeEvent> _events = [];
  bool _loaded = false;

  List<TentativeEvent> get events => List.unmodifiable(_events);
  bool get isLoaded => _loaded;

  TentativePlannerProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
        _events.clear();
        _events.addAll(decoded
            .map((e) => TentativeEvent.fromMap(e as Map<String, dynamic>)));
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('TentativePlanner: load error: $e');
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = json.encode(_events.map((e) => e.toMap()).toList());
      await prefs.setString(_storageKey, raw);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('TentativePlanner: save error: $e');
      }
    }
  }

  Future<void> addEvent(TentativeEvent e) async {
    _events.add(e);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> updateEvent(TentativeEvent e) async {
    final idx = _events.indexWhere((x) => x.id == e.id);
    if (idx != -1) {
      _events[idx] = e;
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    await _saveToStorage();
    notifyListeners();
  }

  TentativeEvent? getById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAll() async {
    _events.clear();
    await _saveToStorage();
    notifyListeners();
  }
}
