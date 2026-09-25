import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import 'package:eventease/shared/models/payment.dart';
import 'payment_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/features/vendor/data/models/vendor_installment_settings.dart';
import 'package:eventease/features/booking/data/providers/payment_provider.dart' as booking_payment;
import 'package:eventease/features/referral/data/referral_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  List<Order> _customerOrders = [];
  List<Order> _vendorOrders = [];

  /// Newest orders first (shop / cart checkout lists).
  void _sortOrdersNewestFirst(List<Order> list) {
    list.sort((a, b) {
      final byDate = b.orderDate.compareTo(a.orderDate);
      if (byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  List<Order> get orders => _orders;
  List<Order> get customerOrders => _customerOrders;
  List<Order> get vendorOrders => _vendorOrders;

  OrderProvider() {
    // Initial fetch handled by external calls or login state
  }

  // Load orders from Supabase for a specific customer
  Future<void> loadCustomerOrders(String customerId) async {
    try {
      final response = await Supabase.instance.client
          .from('shop_orders')
          .select('*, items:shop_order_items(*)')
          .eq('customer_id', customerId)
          .order('order_date', ascending: false);

      _customerOrders = response.map((json) {
        // Map Supabase JSON to Order object
        final items = (json['items'] as List<dynamic>).map((itemJson) => OrderItem(
          id: itemJson['id'],
          serviceId: itemJson['service_id'] ?? '',
          title: itemJson['title'],
          description: itemJson['description'] ?? '',
          price: itemJson['price'],
          category: itemJson['category'] ?? '',
          vendor: itemJson['vendor'],
          vendorId: itemJson['vendor_id'] ?? '',
          imageUrl: itemJson['image_url'] ?? '',
          quantity: itemJson['quantity'],
          totalPrice: double.tryParse(itemJson['total_price'].toString()) ?? 0.0,
        )).toList();

        return Order(
          id: json['id'],
          customerId: json['customer_id'] ?? '',
          customerName: json['customer_name'] ?? '',
          customerEmail: json['customer_email'] ?? '',
          type: OrderType.values.firstWhere((e) => e.toString().split('.').last == json['type'], orElse: () => OrderType.purchase),
          items: items,
          subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
          serviceFee: double.tryParse(json['service_fee'].toString()) ?? 0.0,
          totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
          status: OrderStatus.values.firstWhere((e) => e.toString().split('.').last == json['status'], orElse: () => OrderStatus.ordered),
          paymentStatus: PaymentStatus.values.firstWhere((e) => e.toString().split('.').last == json['payment_status'], orElse: () => PaymentStatus.pending),
          paymentTransactionId: json['payment_transaction_id'],
          appointmentId: json['appointment_id'],
          shippingAddress: json['shipping_address'],
          notes: json['notes'],
          orderDate: DateTime.parse(json['order_date']),
          deliveryDate: json['delivery_date'] != null ? DateTime.parse(json['delivery_date']) : null,
          completionDate: json['completion_date'] != null ? DateTime.parse(json['completion_date']) : null,
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
        );
      }).toList();
      _sortOrdersNewestFirst(_customerOrders);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading customer orders from Supabase: $e');
    }
  }

  // Load orders from Supabase for a specific vendor
  Future<void> loadVendorOrders(String vendorId) async {
    try {
      final response = await Supabase.instance.client
          .from('shop_orders')
          .select('*, items:shop_order_items!inner(*)')
          .eq('items.vendor_id', vendorId)
          .order('order_date', ascending: false);

      _vendorOrders = response.map((json) {
        // Map Supabase JSON to Order object
        final items = (json['items'] as List<dynamic>).map((itemJson) => OrderItem(
          id: itemJson['id'],
          serviceId: itemJson['service_id'] ?? '',
          title: itemJson['title'],
          description: itemJson['description'] ?? '',
          price: itemJson['price'],
          category: itemJson['category'] ?? '',
          vendor: itemJson['vendor'],
          vendorId: itemJson['vendor_id'] ?? '',
          imageUrl: itemJson['image_url'] ?? '',
          quantity: itemJson['quantity'],
          totalPrice: double.tryParse(itemJson['total_price'].toString()) ?? 0.0,
        )).toList();

        return Order(
          id: json['id'],
          customerId: json['customer_id'] ?? '',
          customerName: json['customer_name'] ?? '',
          customerEmail: json['customer_email'] ?? '',
          type: OrderType.values.firstWhere((e) => e.toString().split('.').last == json['type'], orElse: () => OrderType.purchase),
          items: items,
          subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
          serviceFee: double.tryParse(json['service_fee'].toString()) ?? 0.0,
          totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
          status: OrderStatus.values.firstWhere((e) => e.toString().split('.').last == json['status'], orElse: () => OrderStatus.ordered),
          paymentStatus: PaymentStatus.values.firstWhere((e) => e.toString().split('.').last == json['payment_status'], orElse: () => PaymentStatus.pending),
          paymentTransactionId: json['payment_transaction_id'],
          appointmentId: json['appointment_id'],
          shippingAddress: json['shipping_address'],
          notes: json['notes'],
          orderDate: DateTime.parse(json['order_date']),
          deliveryDate: json['delivery_date'] != null ? DateTime.parse(json['delivery_date']) : null,
          completionDate: json['completion_date'] != null ? DateTime.parse(json['completion_date']) : null,
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
        );
      }).toList();
      _sortOrdersNewestFirst(_vendorOrders);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading vendor orders from Supabase: $e');
    }
  }

  // Add a new order
  Future<void> addOrder(Order order) async {
    try {
      // 1. Insert order into shop_orders table
      final orderData = {
        // Exclude ID to let Supabase generate UUID, OR if using generated string, map it
        'customer_id': order.customerId == 'customer_demo_id' ? Supabase.instance.client.auth.currentUser?.id : order.customerId,
        'customer_name': order.customerName,
        'customer_email': order.customerEmail,
        'type': order.type.toString().split('.').last,
        'subtotal': order.subtotal,
        'service_fee': order.serviceFee,
        'total_amount': order.totalAmount,
        'status': order.status.toString().split('.').last,
        'payment_status': order.paymentStatus.toString().split('.').last,
        'payment_transaction_id': order.paymentTransactionId,
        'appointment_id': order.appointmentId,
        'shipping_address': order.shippingAddress,
        'notes': order.notes,
        'order_date': order.orderDate.toIso8601String(),
      };

      final insertedOrder = await Supabase.instance.client
          .from('shop_orders')
          .insert(orderData)
          .select('id')
          .single();

      final dbOrderId = insertedOrder['id'];

      // 2. Insert items into shop_order_items table
      final itemsData = order.items.map((item) => {
        'order_id': dbOrderId,
        'service_id': item.serviceId,
        'title': item.title,
        'description': item.description,
        'price': item.price,
        'category': item.category,
        'vendor': item.vendor,
        'vendor_id': item.vendorId,
        'image_url': item.imageUrl,
        'quantity': item.quantity,
        'total_price': item.totalPrice,
      }).toList();

      await Supabase.instance.client.from('shop_order_items').insert(itemsData);

      // Reload to ensure state matches DB exactly
      await loadCustomerOrders(order.customerId);
      
    } catch (e) {
      debugPrint('Error adding order to Supabase: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final updates = {
        'status': status.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (status == OrderStatus.completed) {
        updates['completion_date'] = DateTime.now().toIso8601String();
      }

      await Supabase.instance.client
          .from('shop_orders')
          .update(updates)
          .eq('id', orderId);

      // Update local state
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = _orders[index].copyWith(
          status: status,
          updatedAt: DateTime.now(),
          completionDate: status == OrderStatus.completed ? DateTime.now() : null,
        );
      }

      final customerIndex = _customerOrders.indexWhere((o) => o.id == orderId);
      if (customerIndex != -1) {
        _customerOrders[customerIndex] = _customerOrders[customerIndex].copyWith(
          status: status,
          updatedAt: DateTime.now(),
          completionDate: status == OrderStatus.completed ? DateTime.now() : null,
        );
      }

      final vendorIndex = _vendorOrders.indexWhere((o) => o.id == orderId);
      if (vendorIndex != -1) {
        _vendorOrders[vendorIndex] = _vendorOrders[vendorIndex].copyWith(
          status: status,
          updatedAt: DateTime.now(),
          completionDate: status == OrderStatus.completed ? DateTime.now() : null,
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating order status in Supabase: $e');
      rethrow;
    }
  }

  // Update payment status
  void updatePaymentStatus(String orderId, PaymentStatus paymentStatus) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final updatedOrder = _orders[index].copyWith(
        paymentStatus: paymentStatus,
        updatedAt: DateTime.now(),
      );
      _orders[index] = updatedOrder;

      // Update in customer orders
      final customerIndex = _customerOrders.indexWhere((o) => o.id == orderId);
      if (customerIndex != -1) {
        _customerOrders[customerIndex] = updatedOrder;
      }

      // Update in vendor orders
      final vendorIndex = _vendorOrders.indexWhere((o) => o.id == orderId);
      if (vendorIndex != -1) {
        _vendorOrders[vendorIndex] = updatedOrder;
      }

      notifyListeners();
    }
  }

  // Get order by ID
  Order? getOrderById(String orderId) {
    return _orders.firstWhere((order) => order.id == orderId);
  }

  // Get orders by status
  List<Order> getOrdersByStatus(OrderStatus status) {
    return _orders.where((order) => order.status == status).toList();
  }

  // Get orders by payment status
  List<Order> getOrdersByPaymentStatus(PaymentStatus paymentStatus) {
    return _orders.where((order) => order.paymentStatus == paymentStatus).toList();
  }

  // Get orders by type
  List<Order> getOrdersByType(OrderType type) {
    return _orders.where((order) => order.type == type).toList();
  }

  Future<Order> createOrderFromCart({
    required String customerId,
    required String customerName,
    required String customerEmail,
    required List<CartItem> cartItems,
    required booking_payment.PaymentProvider paymentProvider,
    Map<String, bool>? installmentSelections,
    Map<String, VendorInstallmentSettings>? vendorSettings,
    String? shippingAddress,
    String? notes,
  }) async {
    final orderItems = cartItems.map((cartItem) {
      return OrderItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}_${cartItem.serviceId}',
        serviceId: cartItem.serviceId,
        title: cartItem.title,
        description: cartItem.description,
        price: cartItem.price,
        category: cartItem.category,
        vendor: cartItem.vendor,
        vendorId: cartItem.vendorId ?? '',
        imageUrl: cartItem.imageUrl,
        quantity: cartItem.quantity,
        totalPrice: cartItem.totalPrice,
      );
    }).toList();

    final subtotal = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    
    // Calculate Upfront Total per vendor (for referral-adjusted service fee)
    double totalToPayUpfront = 0;
    final upfrontByVendor = <String, double>{};
    for (var cartItem in cartItems) {
      final vendorId = cartItem.vendorId ?? '';
      double itemUpfront;
      if (installmentSelections != null &&
          installmentSelections[vendorId] == true &&
          vendorSettings != null &&
          vendorSettings.containsKey(vendorId)) {
        final settings = vendorSettings[vendorId]!;
        itemUpfront =
            cartItem.totalPrice * (settings.depositPercentage / 100);
      } else {
        itemUpfront = cartItem.totalPrice;
      }
      totalToPayUpfront += itemUpfront;
      upfrontByVendor[vendorId] =
          (upfrontByVendor[vendorId] ?? 0) + itemUpfront;
    }

    final serviceFee = await ReferralService.calculateCartServiceFee(
      customerId: customerId,
      upfrontByVendorId: upfrontByVendor,
    );
    final totalAmount = subtotal + serviceFee; // Total value of order
    final upfrontAmount = totalToPayUpfront + serviceFee; // What is paid now (excluding shipping for simplicity in this example, or add it)

    final order = Order(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      type: OrderType.purchase,
      items: orderItems,
      subtotal: subtotal,
      serviceFee: serviceFee,
      totalAmount: totalAmount,
      status: OrderStatus.ordered,
      paymentStatus: PaymentStatus.pending,
      shippingAddress: shippingAddress,
      notes: notes,
      orderDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Process payment for UPFRONT amount
    final paymentUrl = await paymentProvider.processPayment(
      bookingId: order.id,
      customerId: customerId,
      vendorId: orderItems.first.vendorId, // Primary vendor
      amount: upfrontAmount,
      method: PaymentMethod.onlineBanking,
      email: customerEmail,
      mobile: '0123456789',
      name: customerName,
      description: 'Order Upfront Payment #${order.id}',
    );

    if (paymentUrl != null) {
      final updatedOrder = order.copyWith(
        paymentStatus: PaymentStatus.processing,
        paymentTransactionId: paymentProvider.transactions.last.id,
      );
      await addOrder(updatedOrder);

      // Handle Installment Plans if selected
      if (installmentSelections != null && vendorSettings != null) {
        for (var entry in installmentSelections.entries) {
          final vendorId = entry.key;
          final isSelected = entry.value;
          
          if (isSelected && vendorSettings.containsKey(vendorId)) {
            final settings = vendorSettings[vendorId]!;
            final vendorItemsTotal = cartItems
                .where((item) => item.vendorId == vendorId)
                .fold(0.0, (sum, item) => sum + item.totalPrice);
            
            final deposit = vendorItemsTotal * (settings.depositPercentage / 100);
            final remaining = vendorItemsTotal - deposit;

            // We need a way to create installment plans for orders
            // For now, we can use the existing SupabaseService.insert
            // but we might need to update the table schema to support shop_order_id
            
            try {
              final planResponse = await Supabase.instance.client
                  .from('installment_plans')
                  .insert({
                    'shop_order_id': updatedOrder.id, // We need to make sure this column exists
                    'vendor_id': vendorId,
                    'total_amount': vendorItemsTotal,
                    'deposit_amount': deposit,
                    'remaining_balance': remaining,
                    'number_of_installments': settings.maxInstallments,
                    'status': 'active',
                  })
                  .select('id')
                  .single();

              final planId = planResponse['id'];

              // Create schedule
              final installmentAmount = remaining / settings.maxInstallments;
              for (int i = 1; i <= settings.maxInstallments; i++) {
                await Supabase.instance.client.from('installment_payments').insert({
                  'plan_id': planId,
                  'amount': installmentAmount,
                  'due_date': DateTime.now().add(Duration(days: 30 * i)).toIso8601String(),
                  'status': 'pending',
                });
              }
            } catch (e) {
              debugPrint('Error creating installment plan for vendor $vendorId: $e');
            }
          }
        }
      }

      return updatedOrder;
    } else {
      final updatedOrder = order.copyWith(
        paymentStatus: PaymentStatus.failed,
      );
      await addOrder(updatedOrder);
      return updatedOrder;
    }
  }

  // Create order from appointment
  void createOrderFromAppointment({
    required String appointmentId,
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String vendorId,
    required String serviceId,
    required String serviceTitle,
    required double amount,
    required PaymentProvider paymentProvider,
  }) {
    final orderItem = OrderItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}_$serviceId',
      serviceId: serviceId,
      title: serviceTitle,
      description: 'Appointment booking',
      price: 'RM ${amount.toStringAsFixed(2)}',
      category: 'Appointment',
      vendor: 'Vendor', // Should be fetched from vendor data
      vendorId: vendorId,
      imageUrl: '', // Default image
      quantity: 1,
      totalPrice: amount,
    );

    final order = Order(
      id: 'order_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      type: OrderType.appointment,
      items: [orderItem],
      subtotal: amount,
      serviceFee: 0.0, // No service fee for appointments
      totalAmount: amount,
      status: OrderStatus.ordered,
      paymentStatus: PaymentStatus.pending,
      appointmentId: appointmentId,
      orderDate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    addOrder(order);
  }

  // Cancel order
  void cancelOrder(String orderId) {
    updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  // Get order statistics
  Map<String, dynamic> getOrderStats(String userId, bool isVendor) {
    final userOrders = isVendor
      ? _orders.where((o) => o.items.any((item) => item.vendorId == userId)).toList()
      : _orders.where((o) => o.customerId == userId).toList();

    final totalRevenue = userOrders
        .where((o) => o.paymentStatus == PaymentStatus.completed)
        .fold(0.0, (sum, o) => sum + o.totalAmount);

    return {
      'totalOrders': userOrders.length,
      'pendingOrders': userOrders.where((o) => o.status == OrderStatus.ordered || o.status == OrderStatus.processing).length,
      'completedOrders': userOrders.where((o) => o.status == OrderStatus.completed).length,
      'cancelledOrders': userOrders.where((o) => o.status == OrderStatus.cancelled).length,
      'totalRevenue': totalRevenue,
      'pendingPayments': userOrders.where((o) => o.paymentStatus == PaymentStatus.pending).length,
      'failedPayments': userOrders.where((o) => o.paymentStatus == PaymentStatus.failed).length,
    };
  }

  // Clear all data (for logout)
  void clearData() {
    _orders.clear();
    _customerOrders.clear();
    _vendorOrders.clear();
    notifyListeners();
  }
}
