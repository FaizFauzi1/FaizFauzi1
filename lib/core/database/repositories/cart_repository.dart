import 'package:eventease/core/database/database_helper.dart';
import 'package:eventease/features/booking/data/models/cart_item.dart';

class CartRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Convert CartItem model to Map for database storage
  Map<String, dynamic> _cartItemToMap(CartItem cartItem, String customerId) {
    return {
      'id': cartItem.id,
      'customerId': customerId,
      'serviceId': cartItem.serviceId,
      'serviceName': cartItem.title,
      'quantity': cartItem.quantity,
      'unitPrice': cartItem.priceValue,
      'totalPrice': cartItem.totalPrice,
      'vendorId': cartItem.vendorId ?? '',
      'vendorName': cartItem.vendor,
      'serviceType': 'service',
      'options': '{}',
      'requirements': '{}',
      'addedAt': cartItem.addedAt.toIso8601String(),
    };
  }

  // Convert Map from database to CartItem model
  CartItem _mapToCartItem(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      serviceId: map['serviceId'],
      title: map['serviceName'],
      description: '', // Not stored in database
      price: 'RM ${map['unitPrice']}',
      category: '', // Not stored in database
      vendor: map['vendorName'],
      vendorId: map['vendorId'],
      vendorEmail: null, // Not stored in database
      imageUrl: '', // Not stored in database
      quantity: map['quantity'],
      addedAt: DateTime.parse(map['addedAt']),
    );
  }

  // Basic CRUD Operations
  Future<int> addToCart(CartItem cartItem, String customerId) async {
    // Check if item already exists in cart
    final existingItem =
        await getCartItemByService(customerId, cartItem.serviceId);
    if (existingItem != null) {
      // Update quantity instead of adding new item
      return await updateQuantity(existingItem.id,
          existingItem.quantity + cartItem.quantity, customerId);
    }

    final cartItemMap = _cartItemToMap(cartItem, customerId);
    return await _dbHelper.insertCartItem(cartItemMap);
  }

  Future<List<CartItem>> getCartItems(String customerId) async {
    final maps = await _dbHelper.getCartItemsByCustomer(customerId);
    return maps.map((map) => _mapToCartItem(map)).toList();
  }

  Future<int> updateCartItem(CartItem cartItem, String customerId) async {
    final cartItemMap = _cartItemToMap(cartItem, customerId);
    return await _dbHelper.updateCartItem(cartItem.id, cartItemMap);
  }

  Future<int> removeFromCart(String cartItemId) async {
    return await _dbHelper.deleteCartItem(cartItemId);
  }

  Future<int> clearCart(String customerId) async {
    return await _dbHelper.clearCart(customerId);
  }

  // Enhanced Business Logic Methods

  // Get cart item count
  Future<int> getCartItemCount(String customerId) async {
    final cartItems = await getCartItems(customerId);
    int total = 0;
    for (final item in cartItems) {
      total += item.quantity;
    }
    return total;
  }

  // Get cart total
  Future<double> getCartTotal(String customerId) async {
    final cartItems = await getCartItems(customerId);
    double total = 0.0;
    for (final item in cartItems) {
      total += item.totalPrice;
    }
    return total;
  }

  // Get cart subtotal (before service fee)
  Future<double> getCartSubtotal(String customerId) async {
    return await getCartTotal(customerId);
  }

  // Calculate service fee (2% of subtotal)
  Future<double> getServiceFee(String customerId) async {
    final subtotal = await getCartSubtotal(customerId);
    return subtotal * 0.02;
  }

  // Get cart total with service fee
  Future<double> getCartTotalWithFees(String customerId) async {
    final subtotal = await getCartSubtotal(customerId);
    final serviceFee = await getServiceFee(customerId);
    return subtotal + serviceFee;
  }

  // Check if item is in cart
  Future<bool> isItemInCart(String customerId, String serviceId) async {
    final cartItems = await getCartItems(customerId);
    return cartItems.any((item) => item.serviceId == serviceId);
  }

  // Get specific cart item by service ID
  Future<CartItem?> getCartItemByService(
      String customerId, String serviceId) async {
    final cartItems = await getCartItems(customerId);
    try {
      return cartItems.firstWhere((item) => item.serviceId == serviceId);
    } catch (e) {
      return null;
    }
  }

  // Get cart items by vendor
  Future<List<CartItem>> getCartItemsByVendor(
      String customerId, String vendorId) async {
    final cartItems = await getCartItems(customerId);
    return cartItems.where((item) => item.vendorId == vendorId).toList();
  }

  // Update quantity of specific item
  Future<int> updateQuantity(
      String cartItemId, int quantity, String customerId) async {
    if (quantity <= 0) {
      return await removeFromCart(cartItemId);
    }

    final cartItem = await _getCartItemById(cartItemId);
    if (cartItem != null) {
      final updatedItem = cartItem.copyWith(quantity: quantity);
      return await updateCartItem(updatedItem, customerId);
    }
    return 0;
  }

  // Increase quantity by 1
  Future<int> incrementQuantity(String cartItemId, String customerId) async {
    final cartItem = await _getCartItemById(cartItemId);
    if (cartItem != null) {
      return await updateQuantity(
          cartItemId, cartItem.quantity + 1, customerId);
    }
    return 0;
  }

  // Decrease quantity by 1
  Future<int> decrementQuantity(String cartItemId, String customerId) async {
    final cartItem = await _getCartItemById(cartItemId);
    if (cartItem != null) {
      if (cartItem.quantity <= 1) {
        return await removeFromCart(cartItemId);
      } else {
        return await updateQuantity(
            cartItemId, cartItem.quantity - 1, customerId);
      }
    }
    return 0;
  }

  // Toggle item in cart (add if not present, remove if present)
  Future<bool> toggleItemInCart(CartItem cartItem, String customerId) async {
    final isInCart = await isItemInCart(customerId, cartItem.serviceId);
    if (isInCart) {
      final existingItem =
          await getCartItemByService(customerId, cartItem.serviceId);
      if (existingItem != null) {
        await removeFromCart(existingItem.id);
      }
      return false; // Removed
    } else {
      await addToCart(cartItem, customerId);
      return true; // Added
    }
  }

  // Get cart summary with detailed breakdown
  Future<Map<String, dynamic>> getCartSummary(String customerId) async {
    final cartItems = await getCartItems(customerId);
    final subtotal = await getCartSubtotal(customerId);
    final serviceFee = await getServiceFee(customerId);
    final total = await getCartTotalWithFees(customerId);
    final itemCount = await getCartItemCount(customerId);

    // Group items by vendor
    final Map<String, List<CartItem>> itemsByVendor = {};
    for (final item in cartItems) {
      final vendorId = item.vendorId ?? 'unknown';
      if (!itemsByVendor.containsKey(vendorId)) {
        itemsByVendor[vendorId] = [];
      }
      itemsByVendor[vendorId]!.add(item);
    }

    // Calculate vendor totals
    final Map<String, double> vendorTotals = {};
    for (final entry in itemsByVendor.entries) {
      vendorTotals[entry.key] =
          entry.value.fold(0.0, (sum, item) => sum + item.totalPrice);
    }

    return {
      'itemCount': itemCount,
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'total': total,
      'items': cartItems
          .map((item) => {
                'id': item.id,
                'serviceId': item.serviceId,
                'title': item.title,
                'vendor': item.vendor,
                'quantity': item.quantity,
                'unitPrice': item.priceValue,
                'totalPrice': item.totalPrice,
              })
          .toList(),
      'itemsByVendor':
          itemsByVendor.map((vendorId, items) => MapEntry(vendorId, {
                'vendorName': items.first.vendor,
                'itemCount': items.length,
                'total': vendorTotals[vendorId] ?? 0.0,
                'items': items
                    .map((item) => {
                          'id': item.id,
                          'title': item.title,
                          'quantity': item.quantity,
                          'totalPrice': item.totalPrice,
                        })
                    .toList(),
              })),
      'vendorTotals': vendorTotals,
    };
  }

  // Validate cart before checkout
  Future<Map<String, dynamic>> validateCart(String customerId) async {
    final cartItems = await getCartItems(customerId);
    final issues = <String>[];

    if (cartItems.isEmpty) {
      issues.add('Cart is empty');
      return {'isValid': false, 'issues': issues};
    }

    // Check for items with invalid prices
    for (final item in cartItems) {
      if (item.priceValue <= 0) {
        issues.add('Item "${item.title}" has invalid price');
      }
      if (item.quantity <= 0) {
        issues.add('Item "${item.title}" has invalid quantity');
      }
    }

    // Check for items from different vendors (might need separate orders)
    final vendorIds = cartItems.map((item) => item.vendorId).toSet();
    if (vendorIds.length > 1) {
      issues.add(
          'Cart contains items from multiple vendors. Consider splitting into separate orders.');
    }

    return {
      'isValid': issues.isEmpty,
      'issues': issues,
      'itemCount': cartItems.length,
      'vendorCount': vendorIds.length,
    };
  }

  // Get cart items older than specified days (for cleanup)
  Future<List<CartItem>> getOldCartItems(String customerId, int daysOld) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final cartItems = await getCartItems(customerId);
    return cartItems
        .where((item) => item.addedAt.isBefore(cutoffDate))
        .toList();
  }

  // Clean up old cart items
  Future<int> cleanupOldCartItems(String customerId, int daysOld) async {
    final oldItems = await getOldCartItems(customerId, daysOld);
    int removedCount = 0;

    for (final item in oldItems) {
      await removeFromCart(item.id);
      removedCount++;
    }

    return removedCount;
  }

  // Get cart statistics
  Future<Map<String, dynamic>> getCartStatistics(String customerId) async {
    final cartItems = await getCartItems(customerId);
    final subtotal = await getCartSubtotal(customerId);
    final serviceFee = await getServiceFee(customerId);
    final total = await getCartTotalWithFees(customerId);

    // Calculate average item price
    final averageItemPrice =
        cartItems.isNotEmpty ? subtotal / cartItems.length : 0.0;

    // Find most expensive item
    CartItem? mostExpensiveItem;
    if (cartItems.isNotEmpty) {
      mostExpensiveItem =
          cartItems.reduce((a, b) => a.totalPrice > b.totalPrice ? a : b);
    }

    // Group by vendor
    final Map<String, int> vendorItemCounts = {};
    for (final item in cartItems) {
      final vendorId = item.vendorId ?? 'unknown';
      vendorItemCounts[vendorId] = (vendorItemCounts[vendorId] ?? 0) + 1;
    }

    return {
      'totalItems': cartItems.length,
      'totalQuantity': cartItems.fold(0, (sum, item) => sum + item.quantity),
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'total': total,
      'averageItemPrice': averageItemPrice,
      'mostExpensiveItem': mostExpensiveItem != null
          ? {
              'title': mostExpensiveItem.title,
              'price': mostExpensiveItem.totalPrice,
            }
          : null,
      'vendorCount': vendorItemCounts.length,
      'vendorBreakdown': vendorItemCounts,
    };
  }

  // Helper method to get cart item by ID
  Future<CartItem?> _getCartItemById(String cartItemId) async {
    // This is a helper method to get a single cart item by ID
    // Since we don't have a direct method in DatabaseHelper, we'll get all items and filter
    final allMaps =
        await _dbHelper.getCartItemsByCustomer(''); // Empty string to get all
    try {
      final map = allMaps.firstWhere((m) => m['id'] == cartItemId);
      return _mapToCartItem(map);
    } catch (e) {
      return null;
    }
  }

  // Duplicate cart for another customer (useful for sharing carts)
  Future<bool> duplicateCart(String fromCustomerId, String toCustomerId) async {
    try {
      final sourceItems = await getCartItems(fromCustomerId);
      for (final item in sourceItems) {
        await addToCart(item, toCustomerId);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get cart items by category (if category was stored)
  Future<List<CartItem>> getCartItemsByCategory(
      String customerId, String category) async {
    final cartItems = await getCartItems(customerId);
    return cartItems
        .where((item) => item.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  // Check if cart has items from specific vendor
  Future<bool> hasItemsFromVendor(String customerId, String vendorId) async {
    final cartItems = await getCartItems(customerId);
    return cartItems.any((item) => item.vendorId == vendorId);
  }

  // Get all unique vendors in cart
  Future<List<String>> getCartVendors(String customerId) async {
    final cartItems = await getCartItems(customerId);
    return cartItems
        .map((item) => item.vendorId)
        .where((id) => id != null)
        .cast<String>()
        .toSet()
        .toList();
  }
}
