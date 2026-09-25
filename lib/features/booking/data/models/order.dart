import 'package:eventease/features/booking/data/providers/payment_provider.dart';
import 'package:eventease/shared/models/payment.dart';

enum OrderStatus {
  ordered,
  processing,
  shipped,
  delivered,
  completed,
  cancelled,
  refunded
}

enum OrderType {
  purchase, // From cart checkout
  appointment // Direct appointment booking
}

class OrderItem {
  final String id;
  final String serviceId;
  final String title;
  final String description;
  final String price;
  final String category;
  final String vendor;
  final String vendorId;
  final String imageUrl;
  final int quantity;
  final double totalPrice;

  OrderItem({
    required this.id,
    required this.serviceId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.vendor,
    required this.vendorId,
    required this.imageUrl,
    required this.quantity,
    required this.totalPrice,
  });

  double get priceValue => double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

  OrderItem copyWith({
    String? id,
    String? serviceId,
    String? title,
    String? description,
    String? price,
    String? category,
    String? vendor,
    String? vendorId,
    String? imageUrl,
    int? quantity,
    double? totalPrice,
  }) {
    return OrderItem(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      vendor: vendor ?? this.vendor,
      vendorId: vendorId ?? this.vendorId,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'vendor': vendor,
      'vendorId': vendorId,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      serviceId: json['serviceId'],
      title: json['title'],
      description: json['description'],
      price: json['price'],
      category: json['category'],
      vendor: json['vendor'],
      vendorId: json['vendorId'],
      imageUrl: json['imageUrl'],
      quantity: json['quantity'],
      totalPrice: json['totalPrice'],
    );
  }
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final OrderType type;
  final List<OrderItem> items;
  final double subtotal;
  final double serviceFee;
  final double totalAmount;
  final OrderStatus status;
  final PaymentStatus paymentStatus; // Added payment status
  final String? paymentTransactionId;
  final String? appointmentId;
  final String? bookingId;
  final String? shippingAddress;
  final String? notes;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final DateTime? completionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.type,
    required this.items,
    required this.subtotal,
    required this.serviceFee,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus, // Added required payment status
    this.paymentTransactionId,
    this.appointmentId,
    this.bookingId,
    this.shippingAddress,
    this.notes,
    required this.orderDate,
    this.deliveryDate,
    this.completionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Order copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerEmail,
    OrderType? type,
    List<OrderItem>? items,
    double? subtotal,
    double? serviceFee,
    double? totalAmount,
    OrderStatus? status,
    PaymentStatus? paymentStatus, // Added payment status to copyWith
    String? paymentTransactionId,
    String? appointmentId,
    String? bookingId,
    String? shippingAddress,
    String? notes,
    DateTime? orderDate,
    DateTime? deliveryDate,
    DateTime? completionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      type: type ?? this.type,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      serviceFee: serviceFee ?? this.serviceFee,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus, // Added payment status
      paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
      appointmentId: appointmentId ?? this.appointmentId,
      bookingId: bookingId ?? this.bookingId,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      notes: notes ?? this.notes,
      orderDate: orderDate ?? this.orderDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      completionDate: completionDate ?? this.completionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'type': type.toString(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'totalAmount': totalAmount,
      'status': status.toString(),
      'paymentStatus': paymentStatus.toString(), // Added payment status to JSON
      'paymentTransactionId': paymentTransactionId,
      'appointmentId': appointmentId,
      'bookingId': bookingId,
      'shippingAddress': shippingAddress,
      'notes': notes,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'completionDate': completionDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      customerEmail: json['customerEmail'],
      type: OrderType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => OrderType.purchase,
      ),
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      subtotal: json['subtotal'] ?? 0.0,
      serviceFee: json['serviceFee'] ?? 0.0,
      totalAmount: json['totalAmount'] ?? 0.0,
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => OrderStatus.ordered,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString() == json['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ), // Added payment status parsing
      paymentTransactionId: json['paymentTransactionId'],
      appointmentId: json['appointmentId'],
      bookingId: json['bookingId'],
      shippingAddress: json['shippingAddress'],
      notes: json['notes'],
      orderDate: DateTime.parse(json['orderDate']),
      deliveryDate: json['deliveryDate'] != null ? DateTime.parse(json['deliveryDate']) : null,
      completionDate: json['completionDate'] != null ? DateTime.parse(json['completionDate']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
