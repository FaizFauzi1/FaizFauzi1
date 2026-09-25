import 'package:equatable/equatable.dart';

enum CustomerType { individual, corporate }

class CustomerUser extends Equatable {
  final String id;
  final String userId;
  final CustomerType customerType;
  final String? companyName;
  final String? companyRegistration;
  final String? contactPerson;
  final String? billingAddress;
  final String? shippingAddress;
  final String? taxId;
  final double totalSpent;
  final int totalBookings;
  final double averageRating;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerUser({
    required this.id,
    required this.userId,
    this.customerType = CustomerType.individual,
    this.companyName,
    this.companyRegistration,
    this.contactPerson,
    this.billingAddress,
    this.shippingAddress,
    this.taxId,
    this.totalSpent = 0.0,
    this.totalBookings = 0,
    this.averageRating = 0.0,
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerUser.fromJson(Map<String, dynamic> json) {
    return CustomerUser(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      customerType: CustomerType.values.firstWhere(
        (type) => type.name == json['customer_type'],
        orElse: () => CustomerType.individual,
      ),
      companyName: json['company_name'] as String?,
      companyRegistration: json['company_registration'] as String?,
      contactPerson: json['contact_person'] as String?,
      billingAddress: json['billing_address'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      taxId: json['tax_id'] as String?,
      totalSpent: (json['total_spent'] ?? 0).toDouble(),
      totalBookings: json['total_bookings'] ?? 0,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_type': customerType.name,
      'company_name': companyName,
      'company_registration': companyRegistration,
      'contact_person': contactPerson,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
      'tax_id': taxId,
      'total_spent': totalSpent,
      'total_bookings': totalBookings,
      'average_rating': averageRating,
      'preferences': preferences,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CustomerUser copyWith({
    String? id,
    String? userId,
    CustomerType? customerType,
    String? companyName,
    String? companyRegistration,
    String? contactPerson,
    String? billingAddress,
    String? shippingAddress,
    String? taxId,
    double? totalSpent,
    int? totalBookings,
    double? averageRating,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerUser(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerType: customerType ?? this.customerType,
      companyName: companyName ?? this.companyName,
      companyRegistration: companyRegistration ?? this.companyRegistration,
      contactPerson: contactPerson ?? this.contactPerson,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      taxId: taxId ?? this.taxId,
      totalSpent: totalSpent ?? this.totalSpent,
      totalBookings: totalBookings ?? this.totalBookings,
      averageRating: averageRating ?? this.averageRating,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        customerType,
        companyName,
        companyRegistration,
        contactPerson,
        billingAddress,
        shippingAddress,
        taxId,
        totalSpent,
        totalBookings,
        averageRating,
        preferences,
        createdAt,
        updatedAt,
      ];
}
