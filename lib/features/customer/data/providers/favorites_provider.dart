import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:eventease/core/database/repositories/favorites_repository.dart';

enum FavoriteType { service, vendor, venue }

class FavoriteItem {
  final String id;
  final DateTime dateAdded;
  final FavoriteType type;

  FavoriteItem({required this.id, required this.dateAdded, required this.type});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateAdded': dateAdded.toIso8601String(),
      'type': type.name,
    };
  }

  factory FavoriteItem.fromMap(Map<String, dynamic> map) {
    return FavoriteItem(
      id: map['id'],
      dateAdded: DateTime.parse(map['dateAdded']),
      type: FavoriteType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () =>
            FavoriteType.service, // Default for backward compatibility
      ),
    );
  }
}

class FavoritesProvider extends ChangeNotifier {
  final Map<String, FavoriteItem> _favoriteItems = <String, FavoriteItem>{};
  String? _userId;
  final FavoritesRepository _favoritesRepository = FavoritesRepository();

  String? get userId => _userId;

  FavoritesProvider({String? userId}) : _userId = userId {
    // Don't load favorites immediately - wait for user authentication
  }

  Set<String> get favoriteServiceIds => _favoriteItems.keys.toSet();

  List<FavoriteItem> get favoriteItems => _favoriteItems.values.toList();

  // Get favorites by type
  List<FavoriteItem> getFavoritesByType(FavoriteType type) =>
      _favoriteItems.values.where((item) => item.type == type).toList();

  bool isServiceFavorited(String serviceId) =>
      _favoriteItems.containsKey(serviceId);

  bool isFavorited(String itemId) => _favoriteItems.containsKey(itemId);

  DateTime? getFavoriteDate(String serviceId) =>
      _favoriteItems[serviceId]?.dateAdded;

  // New method to toggle favorites with type
  Future<void> toggleFavorite(String itemId, FavoriteType type) async {
    if (_userId == null) return;

    print('FavoritesProvider: Toggling $type $itemId');
    print('FavoritesProvider: Current favorites: $_favoriteItems');

    try {
      // Check database first to avoid duplicate key errors
      final isCurrentlyFavorited = await _favoritesRepository.isFavorite(
          _userId!, itemId, type.name);

      if (isCurrentlyFavorited) {
        await _favoritesRepository.removeFromFavorites(
            _userId!, itemId, type.name);
        _favoriteItems.remove(itemId);
        print('FavoritesProvider: Removed $itemId from favorites');
      } else {
        await _favoritesRepository.addToFavorites(_userId!, itemId, type.name);
        _favoriteItems[itemId] =
            FavoriteItem(id: itemId, dateAdded: DateTime.now(), type: type);
        print('FavoritesProvider: Added $itemId to favorites');
      }

      print('FavoritesProvider: Updated favorites: $_favoriteItems');
      notifyListeners();
    } catch (e) {
      print('Error toggling favorite: $e');
      // Re-sync local state with database on error
      await _loadFavoritesFromDatabase();
    }
  }

  // Keep backward compatibility for services
  Future<void> toggleService(String serviceId) async {
    await toggleFavorite(serviceId, FavoriteType.service);
  }

  Future<void> _loadFavoritesFromDatabase() async {
    if (_userId == null) return;

    try {
      print('FavoritesProvider: Loading favorites from database...');
      final favorites = await _favoritesRepository.getFavorites(_userId!);
      _favoriteItems.clear();
      for (final favorite in favorites) {
        final item = FavoriteItem(
          id: favorite['itemId'],
          dateAdded: favorite['createdAt'],
          type: FavoriteType.values.firstWhere(
            (e) => e.name == favorite['itemType'],
            orElse: () => FavoriteType.service,
          ),
        );
        _favoriteItems[item.id] = item;
      }
      print('FavoritesProvider: Updated favorites map: $_favoriteItems');
      notifyListeners();
      print('FavoritesProvider: Notified listeners after loading');
    } catch (e) {
      print('Error loading favorites from database: $e');
    }
  }

  Future<void> clearAllFavorites() async {
    if (_userId == null) return;

    try {
      // Clear from database
      final favorites = await _favoritesRepository.getFavorites(_userId!);
      for (final favorite in favorites) {
        await _favoritesRepository.removeFromFavorites(
            _userId!, favorite['itemId'], favorite['itemType']);
      }

      _favoriteItems.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }

  void updateUserId(String? userId) {
    _userId = userId;
    // Reload favorites for the new user
    if (userId != null) {
      _loadFavoritesFromDatabase();
    } else {
      _favoriteItems.clear();
      notifyListeners();
    }
  }

  // Ensure favorites are loaded when provider is initialized
  void ensureFavoritesLoaded() {
    if (_userId != null && _favoriteItems.isEmpty) {
      _loadFavoritesFromDatabase();
    }
  }

  // Keep backward compatibility method
  Future<void> loadFavoritesFromStorage() async {
    await _loadFavoritesFromDatabase();
  }
}
