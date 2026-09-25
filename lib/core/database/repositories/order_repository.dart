import 'package:eventease/core/database/database_helper.dart';
import 'package:eventease/features/booking/data/models/order.dart';
import 'package:eventease/features/booking/data/models/cart_item.dart';
import 'package:eventease/features/booking/data/providers/payment_provider.dart';

class OrderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Convert Order model to Map for database storage
  Map<String, dynamic> _orderToMap(Order order) {
    return {
      'id': order.id,
      'customerId': order.customerId,
      'customerName': order.customerName,
      'customerEmail': order.customerEmail,
      'orderNumber': _generateOrderNumber(),
      'status': order.status.name,
      'totalAmount': order.totalAmount,
      'subtotal': order.subtotal,
      'serviceFee': order.serviceFee,
      'paymentStatus': order.paymentStatus.name,
      'paymentMethod': null, // Will be set during payment
      'paymentId': order.paymentTransactionId,
      'orderDate': order.orderDate.toIso8601String(),
      'deliveryDate': order.deliveryDate?.toIso8601String(),
      'notes': order.notes,
      'shippingAddress': order.shippingAddress,
      'billingAddress': null, // Not in current model
      'createdAt': order.createdAt.toIso8601String(),
      'updatedAt': order.updatedAt.toIso8601String(),
    };
  }

  // Convert Map from database to Order model
  Order _mapToOrder(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      customerId: map['customerId'],
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      type: OrderType.purchase, // Default type
      items: [], // Will be loaded separately
      subtotal: map['subtotal']?.toDouble() ?? 0.0,
      serviceFee: map['serviceFee']?.toDouble() ?? 0.0,
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.ordered,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentTransactionId: map['paymentId'],
      appointmentId: null,
      bookingId: null,
      shippingAddress: map['shippingAddress'],
      notes: map['notes'],
      orderDate: DateTime.parse(map['orderDate']),
      deliveryDate: map['deliveryDate'] != null
          ? DateTime.parse(map['deliveryDate'])
          : null,
      completionDate: null,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Convert CartItem to OrderItem for order items
  Map<String, dynamic> _cartItemToOrderItemMap(
      CartItem cartItem, String orderId) {
    return {
      'id': '${orderId}_${cartItem.id}',
      'orderId': orderId,
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
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  // Convert Map from database to OrderItem
  OrderItem _mapToOrderItem(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      serviceId: map['serviceId'],
      title: map['serviceName'],
      description: '', // Not stored
      price: 'RM ${map['unitPrice']}',
      category: '', // Not stored
      vendor: map['vendorName'],
      vendorId: map['vendorId'],
      imageUrl: '', // Not stored
      quantity: map['quantity'],
      totalPrice: map['totalPrice']?.toDouble() ?? 0.0,
    );
  }

  // Generate unique order number
  String _generateOrderNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'ORD-$timestamp$random';
  }

  // CRUD Operations
  Future<int> insertOrder(Order order) async {
    final orderId = await _dbHelper.insertOrder(_orderToMap(order));

    // Insert order items
    for (final item in order.items) {
      // Convert OrderItem to CartItem format for storage
      final cartItem = CartItem(
        id: item.id,
        serviceId: item.serviceId,
        title: item.title,
        description: item.description,
        price: item.price,
        category: item.category,
        vendor: item.vendor,
        vendorId: item.vendorId,
        vendorEmail: null,
        imageUrl: item.imageUrl,
        quantity: item.quantity,
      );
      await _dbHelper
          .insertOrderItem(_cartItemToOrderItemMap(cartItem, order.id));
    }

    return orderId;
  }

  Future<List<Order>> getAllOrders() async {
    final maps = await _dbHelper.getAllOrders();
    final orders = maps.map((map) => _mapToOrder(map)).toList();

    // Load order items for each order
    for (final order in orders) {
      // Note: Order.items is final, so we can't modify it directly
      // This is a limitation of the current Order model
    }

    return orders;
  }

  Future<Order?> getOrderById(String id) async {
    final map = await _dbHelper.getOrderById(id);
    if (map == null) return null;

    final order = _mapToOrder(map);
    // Note: Order.items is final, so we can't modify it directly
    return order;
  }

  Future<List<Order>> getOrdersByCustomer(String customerId) async {
    final maps = await _dbHelper.getOrdersByCustomer(customerId);
    final orders = maps.map((map) => _mapToOrder(map)).toList();

    // Load order items for each order
    for (final order in orders) {
      // Note: Order.items is final, so we can't modify it directly
      // This is a limitation of the current Order model
    }

    return orders;
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    final maps = await _dbHelper.getOrderItemsByOrder(orderId);
    return maps.map((map) => _mapToOrderItem(map)).toList();
  }

  Future<int> updateOrder(Order order) async {
    return await _dbHelper.updateOrder(order.id, _orderToMap(order));
  }

  Future<int> deleteOrder(String id) async {
    return await _dbHelper.deleteOrder(id);
  }

  // Enhanced Business Logic Methods

  // Create order from cart items
  Future<Order> createOrderFromCart({
    required String customerId,
    required String customerName,
    required String customerEmail,
    required List<CartItem> cartItems,
    String? shippingAddress,
    String? notes,
  }) async {
    final subtotal = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    const serviceFeeRate = 0.02; // 2% service fee
    final serviceFee = subtotal * serviceFeeRate;
    final totalAmount = subtotal + serviceFee;

    // Convert CartItems to OrderItems
    final orderItems = cartItems
        .map((cartItem) => OrderItem(
              id: cartItem.id,
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
            ))
        .toList();

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

    await insertOrder(order);
    return order;
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return false;

      final updatedOrder = order.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );

      await updateOrder(updatedOrder);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update payment status
  Future<bool> updatePaymentStatus(String orderId, PaymentStatus paymentStatus,
      {String? paymentMethod, String? paymentId}) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null) return false;

      final updatedOrder = order.copyWith(
        paymentStatus: paymentStatus,
        paymentTransactionId: paymentId ?? order.paymentTransactionId,
        updatedAt: DateTime.now(),
      );

      await updateOrder(updatedOrder);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get orders by status
  Future<List<Order>> getOrdersByStatus(OrderStatus status) async {
    final allOrders = await getAllOrders();
    return allOrders.where((order) => order.status == status).toList();
  }

  // Get orders by payment status
  Future<List<Order>> getOrdersByPaymentStatus(
      PaymentStatus paymentStatus) async {
    final allOrders = await getAllOrders();
    return allOrders
        .where((order) => order.paymentStatus == paymentStatus)
        .toList();
  }

  // Get orders by date range
  Future<List<Order>> getOrdersByDateRange(
      DateTime startDate, DateTime endDate) async {
    final allOrders = await getAllOrders();
    return allOrders.where((order) {
      return order.orderDate.isAfter(startDate) &&
          order.orderDate.isBefore(endDate);
    }).toList();
  }

  // Get today's orders
  Future<List<Order>> getTodaysOrders() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getOrdersByDateRange(startOfDay, endOfDay);
  }

  // Get pending orders (for vendors)
  Future<List<Order>> getPendingOrders() async {
    return getOrdersByStatus(OrderStatus.ordered);
  }

  // Get completed orders
  Future<List<Order>> getCompletedOrders() async {
    return getOrdersByStatus(OrderStatus.completed);
  }

  // Calculate total revenue
  Future<double> getTotalRevenue() async {
    final completedOrders = await getCompletedOrders();
    double total = 0.0;
    for (final order in completedOrders) {
      total += order.totalAmount;
    }
    return total;
  }

  // Calculate revenue by date range
  Future<double> getRevenueByDateRange(
      DateTime startDate, DateTime endDate) async {
    final orders = await getOrdersByDateRange(startDate, endDate);
    final completedOrders =
        orders.where((order) => order.status == OrderStatus.completed);
    double total = 0.0;
    for (final order in completedOrders) {
      total += order.totalAmount;
    }
    return total;
  }

  // Get customer order history
  Future<List<Order>> getCustomerOrderHistory(String customerId,
      {int? limit}) async {
    final orders = await getOrdersByCustomer(customerId);
    orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return limit != null ? orders.take(limit).toList() : orders;
  }

  // Get order statistics
  Future<Map<String, dynamic>> getOrderStatistics() async {
    final allOrders = await getAllOrders();
    final completedOrders =
        allOrders.where((o) => o.status == OrderStatus.completed).toList();
    final pendingOrders =
        allOrders.where((o) => o.status == OrderStatus.ordered).toList();

    final totalRevenue =
        completedOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
    final averageOrderValue = completedOrders.isNotEmpty
        ? totalRevenue / completedOrders.length
        : 0.0;

    return {
      'totalOrders': allOrders.length,
      'completedOrders': completedOrders.length,
      'pendingOrders': pendingOrders.length,
      'totalRevenue': totalRevenue,
      'averageOrderValue': averageOrderValue,
      'completionRate': allOrders.isNotEmpty
          ? completedOrders.length / allOrders.length
          : 0.0,
    };
  }

  // Search orders
  Future<List<Order>> searchOrders(String query) async {
    final allOrders = await getAllOrders();
    return allOrders.where((order) {
      return order.customerName.toLowerCase().contains(query.toLowerCase()) ||
          order.customerEmail.toLowerCase().contains(query.toLowerCase()) ||
          order.id.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get orders by vendor (through order items)
  Future<List<Order>> getOrdersByVendor(String vendorId) async {
    final allOrders = await getAllOrders();
    return allOrders.where((order) {
      return order.items.any((item) => item.vendorId == vendorId);
    }).toList();
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      final order = await getOrderById(orderId);
      if (order == null || order.status == OrderStatus.completed) return false;

      final cancelledOrder = order.copyWith(
        status: OrderStatus.cancelled,
        notes: '${order.notes ?? ''}\nCancelled: $reason',
        updatedAt: DateTime.now(),
      );

      await updateOrder(cancelledOrder);
      return true;
    } catch (e) {
      return false;
    }
  }
}
