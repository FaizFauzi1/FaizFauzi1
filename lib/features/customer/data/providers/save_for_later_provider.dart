import 'package:flutter/material.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';

class SaveForLaterProvider extends ChangeNotifier {
  static const String _savedKey = 'saved_service_ids';
  final List<String> _savedServiceIds = [];

  List<String> get savedServiceIds => _savedServiceIds;

  bool isServiceSaved(String serviceId) {
    return _savedServiceIds.contains(serviceId);
  }

  void toggleService(String serviceId) {
    if (isServiceSaved(serviceId)) {
      _savedServiceIds.remove(serviceId);
    } else {
      _savedServiceIds.add(serviceId);
    }
    notifyListeners();
    // In a real app, you would persist this to local storage or backend
    _persistSavedServices();
  }

  void addService(String serviceId) {
    if (!_savedServiceIds.contains(serviceId)) {
      _savedServiceIds.add(serviceId);
      notifyListeners();
      _persistSavedServices();
    }
  }

  void removeService(String serviceId) {
    _savedServiceIds.remove(serviceId);
    notifyListeners();
    _persistSavedServices();
  }

  void clearAll() {
    _savedServiceIds.clear();
    notifyListeners();
    _persistSavedServices();
  }

  int get savedCount => _savedServiceIds.length;

  // Mock persistence - in a real app, use SharedPreferences or similar
  void _persistSavedServices() {
    // For now, just print. In production, save to local storage
    debugPrint('Saved services: $_savedServiceIds');
  }

  // Load saved services on initialization
  void loadSavedServices() {
    // In a real app, load from SharedPreferences
    // For demo purposes, we'll leave this empty
  }
}
