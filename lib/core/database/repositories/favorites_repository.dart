import 'package:eventease/core/services/supabase_service.dart';

class FavoritesRepository {
  // Convert favorite data to Map for Supabase storage
  Map<String, dynamic> _favoriteToMap(
      String userId, String itemId, String itemType) {
    return {
      'user_id': userId,
      'item_id': itemId,
      'item_type': itemType,
    };
  }

  // Convert Map from Supabase to favorite data
  Map<String, dynamic> _mapToFavorite(Map<String, dynamic> map) {
    return {
      'id': map['id'],
      'userId': map['user_id'],
      'itemId': map['item_id'],
      'itemType': map['item_type'],
      'createdAt': DateTime.parse(map['created_at']),
    };
  }

  // CRUD Operations
  Future<List<Map<String, dynamic>>> addToFavorites(
      String userId, String itemId, String itemType) async {
    try {
      final data = _favoriteToMap(userId, itemId, itemType);
      final response = await SupabaseService.insert(
        table: 'favorites',
        data: data,
      );
      return response;
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFavorites(String userId) async {
    try {
      final response = await SupabaseService.select(
        table: 'favorites',
        filters: {'user_id': userId},
      );
      return response.map((map) => _mapToFavorite(map)).toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  Future<bool> isFavorite(String userId, String itemId, String itemType) async {
    try {
      final response = await SupabaseService.select(
        table: 'favorites',
        filters: {
          'user_id': userId,
          'item_id': itemId,
          'item_type': itemType,
        },
      );
      return response.isNotEmpty;
    } catch (e) {
      print('Error checking if favorite: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> removeFromFavorites(
      String userId, String itemId, String itemType) async {
    try {
      // Since SupabaseService.delete only supports single filter, we need to use a different approach
      // We'll use the Supabase client directly to perform a more complex delete operation
      final response = await SupabaseService.client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('item_id', itemId)
          .eq('item_type', itemType)
          .select();
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  // Additional helper methods
  Future<List<Map<String, dynamic>>> getFavoritesByType(
      String userId, String itemType) async {
    try {
      final response = await SupabaseService.select(
        table: 'favorites',
        filters: {
          'user_id': userId,
          'item_type': itemType,
        },
      );
      return response.map((map) => _mapToFavorite(map)).toList();
    } catch (e) {
      print('Error getting favorites by type: $e');
      return [];
    }
  }

  Future<List<String>> getFavoriteItemIds(
      String userId, String itemType) async {
    final favorites = await getFavoritesByType(userId, itemType);
    return favorites.map((favorite) => favorite['itemId'] as String).toList();
  }

  Future<int> getFavoriteCount(String userId) async {
    final favorites = await getFavorites(userId);
    return favorites.length;
  }

  Future<int> getFavoriteCountByType(String userId, String itemType) async {
    final favorites = await getFavoritesByType(userId, itemType);
    return favorites.length;
  }

  Future<void> toggleFavorite(
      String userId, String itemId, String itemType) async {
    final isFav = await isFavorite(userId, itemId, itemType);
    if (isFav) {
      await removeFromFavorites(userId, itemId, itemType);
    } else {
      await addToFavorites(userId, itemId, itemType);
    }
  }

  Future<List<Map<String, dynamic>>> getRecentFavorites(
      String userId, int limit) async {
    try {
      // Note: Supabase select doesn't have built-in ordering in the current service
      // This would need to be implemented with a more complex query or RPC function
      final allFavorites = await getFavorites(userId);
      allFavorites.sort((a, b) =>
          (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));
      return allFavorites.take(limit).toList();
    } catch (e) {
      print('Error getting recent favorites: $e');
      return [];
    }
  }
}
