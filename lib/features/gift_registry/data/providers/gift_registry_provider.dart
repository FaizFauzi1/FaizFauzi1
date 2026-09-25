import 'package:flutter/material.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/shared/models/gift_registry.dart';

class GiftRegistryProvider with ChangeNotifier {
  List<GiftRegistry> _registries = [];
  bool _isLoading = false;
  String? _error;

  List<GiftRegistry> get registries => List.unmodifiable(_registries);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch registry for an event
  Future<void> loadRegistryForEvent(String eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await SupabaseService.select(
        table: 'gift_registries',
        columns: '*, gift_registry_items(*)',
        filters: {'event_id': eventId},
      );

      _registries = data.map((json) => GiftRegistry.fromSupabase(json)).toList();
    } catch (e) {
      print('Error loading registry: $e');
      _error = 'Failed to load registry';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new registry
  Future<void> createRegistry(GiftRegistry registry) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Insert Registry
      final registryData = registry.toSupabaseJson();
      // Ensure we don't send nested items here, they go to separate table
      final response = await SupabaseService.insert(
        table: 'gift_registries',
        data: registryData,
      );

      if (response.isNotEmpty) {
        // 2. Insert Items if any
        if (registry.items.isNotEmpty) {
           for (var item in registry.items) {
             await SupabaseService.insert(
               table: 'gift_registry_items',
               data: item.toSupabaseJson(registry.id),
             );
           }
        }
        
        // Reload to get fresh state with IDs
        await loadRegistryForEvent(registry.eventId);
      }
    } catch (e) {
      print('Error creating registry: $e');
      _error = 'Failed to create registry';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add Item
  Future<void> addItem(String registryId, GiftRegistryItem item) async {
    try {
      await SupabaseService.insert(
        table: 'gift_registry_items',
        data: item.toSupabaseJson(registryId),
      );
      
      // Update local state
      final index = _registries.indexWhere((r) => r.id == registryId);
      if (index != -1) {
        final currentRegistry = _registries[index];
        final updatedItems = List<GiftRegistryItem>.from(currentRegistry.items)..add(item);
        _registries[index] = currentRegistry.copyWith(items: updatedItems);
        notifyListeners();
      }
    } catch (e) {
      print('Error adding item: $e');
      _error = 'Failed to add item';
      notifyListeners();
    }
  }

  // Update Item
  Future<void> updateItem(String registryId, GiftRegistryItem item) async {
    try {
      await SupabaseService.update(
        table: 'gift_registry_items',
        data: item.toSupabaseJson(registryId),
        column: 'id',
        value: item.id,
      );

      // Update local state
      final index = _registries.indexWhere((r) => r.id == registryId);
      if (index != -1) {
        final currentRegistry = _registries[index];
        final items = List<GiftRegistryItem>.from(currentRegistry.items);
        final itemIndex = items.indexWhere((i) => i.id == item.id);
        if (itemIndex != -1) {
          items[itemIndex] = item;
          _registries[index] = currentRegistry.copyWith(items: items);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error updating item: $e');
      _error = 'Failed to update item';
      notifyListeners();
    }
  }

  // Delete Item
  Future<void> deleteItem(String registryId, String itemId) async {
    try {
      await SupabaseService.delete(
        table: 'gift_registry_items',
        column: 'id',
        value: itemId,
      );

       // Update local state
      final index = _registries.indexWhere((r) => r.id == registryId);
      if (index != -1) {
        final currentRegistry = _registries[index];
        final items = List<GiftRegistryItem>.from(currentRegistry.items)..removeWhere((i) => i.id == itemId);
        _registries[index] = currentRegistry.copyWith(items: items);
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting item: $e');
       _error = 'Failed to delete item';
      notifyListeners();
    }
  }
  
  // Purchase Item (Guest)
  Future<void> purchaseItem(String registryId, String itemId, int quantityPurchased, String? purchaserName) async {
    // This requires a more complex update (decrement remaining, maybe add transaction record)
    // For now, simpler update:
    try {
       final index = _registries.indexWhere((r) => r.id == registryId);
       if (index == -1) return;
       
       final item = _registries[index].items.firstWhere((i) => i.id == itemId);
       final newRemaining = item.remainingQuantity - quantityPurchased;
       
       final updatedItem = item.copyWith(
         remainingQuantity: newRemaining < 0 ? 0 : newRemaining,
         isPurchased: newRemaining <= 0, // Simplified logic
         purchasedBy: purchaserName ?? item.purchasedBy, // Naive, assumes one purchaser or overwrite
         purchasedAt: DateTime.now(),
       );
       
       await updateItem(registryId, updatedItem);
       
    } catch (e) {
      print('Error purchasing item: $e');
      _error = 'Failed to purchase item';
      notifyListeners();
    }
  }
}
