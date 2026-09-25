import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/features/guest/data/models/event_wish.dart';

class EventWishProvider with ChangeNotifier {
  final List<EventWish> _wishes = [];
  bool _isLoading = false;
  String? _error;

  List<EventWish> get wishes => List.unmodifiable(_wishes);
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _supabase = Supabase.instance.client;

  Future<void> loadWishesForEvent(String eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('event_wishes')
          .select()
          .eq('event_id', eventId)
          .order('created_at', ascending: false);

      _wishes.clear();
      if (response != null) {
        for (final item in response) {
          _wishes.add(EventWish.fromSupabase(item));
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWish(EventWish wish) async {
    try {
      final response = await _supabase
          .from('event_wishes')
          .insert(wish.toSupabaseJson())
          .select()
          .single();

      _wishes.insert(0, EventWish.fromSupabase(response));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void addWishLocally(EventWish wish) {
    _wishes.insert(0, wish);
    notifyListeners();
  }
}
