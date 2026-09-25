import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/features/booking/data/models/cart_item.dart';

class CartRepositorySupabase {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Add item to cart
  Future<void> addToCart(CartItem cartItem, String customerId) async {
    try {
      // Check if item already exists
      final existing = await _supabase
          .from('cart_items')
          .select()
          .eq('customer_id', customerId)
          .eq('service_id', cartItem.serviceId)
          .maybeSingle();

      if (existing != null) {
        // Update quantity
        final newQuantity = (existing['quantity'] as int) + cartItem.quantity;
        await _supabase
            .from('cart_items')
            .update({
              'quantity': newQuantity,
              'total_price': cartItem.priceValue * newQuantity,
            })
            .eq('id', existing['id']);
      } else {
        // Insert new item
        await _supabase.from('cart_items').insert({
          'customer_id': customerId,
          'service_id': cartItem.serviceId,
          'service_name': cartItem.title,
          'quantity': cartItem.quantity,
          'unit_price': cartItem.priceValue,
          'total_price': cartItem.totalPrice,
          'vendor_id': cartItem.vendorId ?? '',
          'vendor_name': cartItem.vendor,
          'service_type': 'service',
          'options': {},
          'requirements': {},
        });
      }
    } catch (e) {
      throw Exception('Failed to add to cart: $e');
    }
  }

  // Get cart items
  Future<List<CartItem>> getCartItems(String customerId) async {
    try {
      final response = await _supabase
          .from('cart_items')
          .select()
          .eq('customer_id', customerId)
          .order('added_at', ascending: false);

      return (response as List).map((item) => _mapToCartItem(item)).toList();
    } catch (e) {
      throw Exception('Failed to get cart items: $e');
    }
  }

  // Update cart item
  Future<void> updateCartItem(CartItem cartItem, String customerId) async {
    try {
      await _supabase.from('cart_items').update({
        'quantity': cartItem.quantity,
        'total_price': cartItem.totalPrice,
      }).eq('service_id', cartItem.serviceId).eq('customer_id', customerId);
    } catch (e) {
      throw Exception('Failed to update cart item: $e');
    }
  }

  // Remove from cart
  Future<void> removeFromCart(String cartItemId) async {
    try {
      await _supabase.from('cart_items').delete().eq('id', cartItemId);
    } catch (e) {
      throw Exception('Failed to remove from cart: $e');
    }
  }

  // Clear cart
  Future<void> clearCart(String customerId) async {
    try {
      await _supabase.from('cart_items').delete().eq('customer_id', customerId);
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  // Get cart item by service
  Future<CartItem?> getCartItemByService(
      String customerId, String serviceId) async {
    try {
      final response = await _supabase
          .from('cart_items')
          .select()
          .eq('customer_id', customerId)
          .eq('service_id', serviceId)
          .maybeSingle();

      if (response == null) return null;
      return _mapToCartItem(response);
    } catch (e) {
      return null;
    }
  }

  // Update quantity
  Future<void> updateQuantity(
      String cartItemId, int quantity, String customerId) async {
    if (quantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    try {
      final item = await _supabase
          .from('cart_items')
          .select()
          .eq('id', cartItemId)
          .single();

      final unitPrice = item['unit_price'] as num;
      await _supabase.from('cart_items').update({
        'quantity': quantity,
        'total_price': unitPrice * quantity,
      }).eq('id', cartItemId);
    } catch (e) {
      throw Exception('Failed to update quantity: $e');
    }
  }

  // Check if item is in cart
  Future<bool> isItemInCart(String customerId, String serviceId) async {
    try {
      final response = await _supabase
          .from('cart_items')
          .select('id')
          .eq('customer_id', customerId)
          .eq('service_id', serviceId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Get cart items by vendor
  Future<List<CartItem>> getCartItemsByVendor(
      String customerId, String vendorId) async {
    try {
      final response = await _supabase
          .from('cart_items')
          .select()
          .eq('customer_id', customerId)
          .eq('vendor_id', vendorId);

      return (response as List).map((item) => _mapToCartItem(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // Convert Supabase map to CartItem
  CartItem _mapToCartItem(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'].toString(),
      serviceId: map['service_id'],
      title: map['service_name'],
      description: '',
      price: 'RM ${map['unit_price']}',
      category: '',
      vendor: map['vendor_name'] ?? '',
      vendorId: map['vendor_id'],
      vendorEmail: null,
      imageUrl: '',
      quantity: map['quantity'],
      addedAt: DateTime.parse(map['added_at']),
    );
  }

  // Get cart summary
  Future<Map<String, dynamic>> getCartSummary(String customerId) async {
    try {
      final items = await getCartItems(customerId);
      final subtotal = items.fold<double>(
          0.0, (sum, item) => sum + item.totalPrice);
      final serviceFee = subtotal * 0.02;
      final total = subtotal + serviceFee;

      return {
        'itemCount': items.length,
        'totalQuantity': items.fold<int>(0, (sum, item) => sum + item.quantity),
        'subtotal': subtotal,
        'serviceFee': serviceFee,
        'total': total,
        'items': items
            .map((item) => {
                  'title': item.title,
                  'vendor': item.vendor,
                  'quantity': item.quantity,
                  'price': item.price,
                  'totalPrice': item.totalPrice,
                })
            .toList(),
      };
    } catch (e) {
      return {
        'itemCount': 0,
        'totalQuantity': 0,
        'subtotal': 0.0,
        'serviceFee': 0.0,
        'total': 0.0,
        'items': [],
      };
    }
  }
}
