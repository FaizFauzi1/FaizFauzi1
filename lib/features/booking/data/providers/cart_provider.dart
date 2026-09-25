import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:eventease/core/database/repositories/cart_repository_supabase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection/collection.dart';
import 'package:eventease/core/services/shipping_service.dart';
import '../models/cart_item.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final Set<String> _selectedItemIds = {};
  String? _userId;
  final CartRepositorySupabase _cartRepository = CartRepositorySupabase();
  
  // Shipping State (Per Vendor)
  final Map<String, ShippingRate?> _selectedShippingRates = {};
  final Map<String, List<ShippingRate>> _availableShippingRates = {};
  final Map<String, bool> _isLoadingShipping = {};
  String _currentPostalCode = '50000'; // Default KL postal code

  CartProvider({String? userId}) {
    _initializeUserId();
  }

  // Initialize user ID from Supabase auth
  Future<void> _initializeUserId() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      _userId = user?.id;
      if (_userId != null) {
        await _loadCartFromDatabase();
      }
    } catch (e) {
      debugPrint('Error initializing user ID: $e');
    }
  }

  List<CartItem> get items => List.unmodifiable(_items);

  List<CartItem> get selectedItems =>
      _items.where((item) => _selectedItemIds.contains(item.serviceId)).toList();

  int get itemCount => _items.length;

  int get totalQuantity =>
      selectedItems.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      selectedItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get shippingCost {
    // Sum of all selected shipping rates for vendors that have items selected in the cart
    final selectedVendors = selectedItems.map((item) => item.vendor).toSet();
    return selectedVendors.fold(0.0, (sum, vendor) {
      return sum + (_selectedShippingRates[vendor]?.cost ?? 0.0);
    });
  }

  double get serviceFee => subtotal * 0.02; // 2% service fee

  double get total => subtotal + shippingCost + serviceFee;
  
  String get currentPostalCode => _currentPostalCode;
  
  ShippingRate? getSelectedShippingRate(String vendorName) => _selectedShippingRates[vendorName];
  List<ShippingRate> getAvailableShippingRates(String vendorName) => _availableShippingRates[vendorName] ?? [];
  bool isLoadingShipping(String vendorName) => _isLoadingShipping[vendorName] ?? false;

  bool get isEmpty => _items.isEmpty;

  // Load cart items from database
  Future<void> _loadCartFromDatabase() async {
    if (_userId == null) return;

    try {
      _items.clear();
      final dbItems = await _cartRepository.getCartItems(_userId!);
      _items.addAll(dbItems);
      
      // Default all items to selected when loaded
      for (var item in dbItems) {
        _selectedItemIds.add(item.serviceId);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart from database: $e');
    }
  }

  // Add item to cart
  Future<void> addItem(CartItem item) async {
    if (_userId == null) return;

    final existingIndex =
        _items.indexWhere((cartItem) => cartItem.serviceId == item.serviceId);
    if (existingIndex != -1) {
      // Item already exists, increase quantity
      await updateQuantity(
          item.serviceId, _items[existingIndex].quantity + item.quantity);
    } else {
      // Add new item
      await _cartRepository.addToCart(item, _userId!);
      _items.add(item);
      _selectedItemIds.add(item.serviceId); // Default to selected
      notifyListeners();
    }
  }

  // Enhanced add item with validation and feedback
  Future<Map<String, dynamic>> addItemWithFeedback(CartItem item) async {
    if (_userId == null) {
      return {
        'success': false,
        'message': 'Please log in to add items to cart',
      };
    }

    // Validate item
    if (item.priceValue <= 0) {
      return {
        'success': false,
        'message': 'Invalid price for this item',
      };
    }

    final existingIndex =
        _items.indexWhere((cartItem) => cartItem.serviceId == item.serviceId);
    
    if (existingIndex != -1) {
      // Check max quantity limit
      final newQuantity = _items[existingIndex].quantity + item.quantity;
      if (newQuantity > 10) {
        return {
          'success': false,
          'message': 'Maximum quantity (10) reached for this item',
        };
      }
      
      await updateQuantity(item.serviceId, newQuantity);
      return {
        'success': true,
        'message': 'Item quantity updated in cart',
        'isUpdate': true,
      };
    } else {
      // Add new item
      try {
        await _cartRepository.addToCart(item, _userId!);
        _items.add(item);
        notifyListeners();
        return {
          'success': true,
          'message': 'Item added to cart successfully',
          'isUpdate': false,
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Failed to add item: ${e.toString()}',
        };
      }
    }
  }


  // Remove item from cart
  Future<void> removeItem(String serviceId) async {
    if (_userId == null) return;

    final item = _items.firstWhere((item) => item.serviceId == serviceId);
    await _cartRepository.removeFromCart(item.id);
    _items.removeWhere((item) => item.serviceId == serviceId);
    _selectedItemIds.remove(serviceId); // Remove from selection
    notifyListeners();
  }

  // Update quantity of an item
  Future<void> updateQuantity(String serviceId, int quantity) async {
    if (_userId == null) return;

    if (quantity <= 0) {
      await removeItem(serviceId);
      return;
    }

    final index = _items.indexWhere((item) => item.serviceId == serviceId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      await _cartRepository.updateCartItem(_items[index], _userId!);
      notifyListeners();
    }
  }

  // Check if item is in cart
  bool isInCart(String serviceId) {
    return _items.any((item) => item.serviceId == serviceId);
  }

  // Get item by service ID
  CartItem? getItem(String serviceId) {
    try {
      return _items.firstWhere((item) => item.serviceId == serviceId);
    } catch (e) {
      return null;
    }
  }

  // Get quantity of specific item
  int getItemQuantity(String serviceId) {
    final item = getItem(serviceId);
    return item?.quantity ?? 0;
  }

  // Clear entire cart
  Future<void> clearCart() async {
    if (_userId == null) return;

    await _cartRepository.clearCart(_userId!);
    _items.clear();
    _selectedItemIds.clear();
    notifyListeners();
  }

  // --- Selection Logic ---

  bool isSelected(String serviceId) {
    return _selectedItemIds.contains(serviceId);
  }

  void toggleSelection(String serviceId) {
    if (_selectedItemIds.contains(serviceId)) {
      _selectedItemIds.remove(serviceId);
    } else {
      _selectedItemIds.add(serviceId);
    }
    notifyListeners();
  }

  void toggleAll(bool selected) {
    if (selected) {
      _selectedItemIds.addAll(_items.map((item) => item.serviceId));
    } else {
      _selectedItemIds.clear();
    }
    notifyListeners();
  }
  
  void toggleVendorSelection(String vendorName, bool selected) {
    final vendorItems = _items.where((item) => item.vendor == vendorName);
    for (var item in vendorItems) {
      if (selected) {
        _selectedItemIds.add(item.serviceId);
      } else {
        _selectedItemIds.remove(item.serviceId);
      }
    }
    notifyListeners();
  }

  bool isVendorSelected(String vendorName) {
    final vendorItems = _items.where((item) => item.vendor == vendorName);
    if (vendorItems.isEmpty) return false;
    return vendorItems.every((item) => _selectedItemIds.contains(item.serviceId));
  }

  // --- Date Logic ---

  // Update event date of an item
  Future<void> updateEventDate(String serviceId, DateTime eventDate) async {
    if (_userId == null) return;

    final index = _items.indexWhere((item) => item.serviceId == serviceId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(eventDate: eventDate);
      await _cartRepository.updateCartItem(_items[index], _userId!);
      notifyListeners();
    }
  }

  // --- Shipping Logic ---

  Future<void> updateShippingRatesForVendor(String vendorName, String postalCode) async {
    _currentPostalCode = postalCode;
    _isLoadingShipping[vendorName] = true;
    notifyListeners();

    try {
      final vendorItems = _items.where((item) => item.vendor == vendorName).toList();
      final totalWeight = vendorItems.length * 1.0; // Assume 1kg per item for now
      
      final rates = await ShippingService.calculateShippingRates(
        weightKg: totalWeight,
        dimensions: {'width': 30.0, 'height': 20.0, 'length': 40.0},
        originPostalCode: '50000', // Default origin
        destinationPostalCode: postalCode,
        country: 'Malaysia',
      );

      _availableShippingRates[vendorName] = rates;

      if (rates.isNotEmpty) {
        // Keep current provider if possible, otherwise first available
        final current = _selectedShippingRates[vendorName];
        if (current != null) {
          final stillAvailable = rates.firstWhereOrNull(
            (r) => r.provider == current.provider && r.type == current.type
          );
          _selectedShippingRates[vendorName] = stillAvailable ?? rates.first;
        } else {
          _selectedShippingRates[vendorName] = rates.first;
        }
      }
    } catch (e) {
      debugPrint('Error updating shipping rates for $vendorName: $e');
    } finally {
      _isLoadingShipping[vendorName] = false;
      notifyListeners();
    }
  }

  void setSelectedShippingRate(String vendorName, ShippingRate? rate) {
    _selectedShippingRates[vendorName] = rate;
    notifyListeners();
  }

  // Get items by vendor
  List<CartItem> getItemsByVendor(String vendorId) {
    return _items.where((item) => item.vendorId == vendorId).toList();
  }

  // Get items by category
  List<CartItem> getItemsByCategory(String category) {
    return _items
        .where((item) => item.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  // Toggle item in cart (add if not present, remove if present)
  Future<void> toggleItem(CartItem item) async {
    if (isInCart(item.serviceId)) {
      await removeItem(item.serviceId);
    } else {
      await addItem(item);
    }
  }

  // Add item from product details
  Future<void> addFromProductDetails({
    required String serviceId,
    required String title,
    required String description,
    required String price,
    required String category,
    required String vendor,
    String? vendorId,
    String? vendorEmail,
    required String imageUrl,
    int quantity = 1,
    DateTime? eventDate,
    DateTime? readyDate,
    DateTime? rentalEndDate,
  }) async {
    final item = CartItem(
      id: '${serviceId}_${DateTime.now().millisecondsSinceEpoch}',
      serviceId: serviceId,
      title: title,
      description: description,
      price: price,
      category: category,
      vendor: vendor,
      vendorId: vendorId,
      vendorEmail: vendorEmail,
      imageUrl: imageUrl,
      quantity: quantity,
      eventDate: eventDate,
      readyDate: readyDate,
      rentalEndDate: rentalEndDate,
    );
    await addItem(item);
  }

  // Get cart summary
  Map<String, dynamic> getCartSummary() {
    return {
      'itemCount': itemCount,
      'totalQuantity': totalQuantity,
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'total': total,
      'items': _items
          .map((item) => {
                'title': item.title,
                'vendor': item.vendor,
                'quantity': item.quantity,
                'price': item.price,
                'totalPrice': item.totalPrice,
              })
          .toList(),
    };
  }

  // Validate cart before checkout
  bool validateCart() {
    if (_items.isEmpty) return false;

    // Check if all items have valid prices
    for (final item in _items) {
      if (item.priceValue <= 0) return false;
    }

    return true;
  }

  // Update user ID and reload cart data
  void updateUserId(String? userId) {
    if (_userId == userId) return;

    // Clear current cart data
    _items.clear();

    // Update user ID
    _userId = userId;

    // Load cart data for new user
    _loadCartFromDatabase();
  }

  // Clear all items from cart
  Future<void> clearAll() async {
    await clearCart();
  }
}
