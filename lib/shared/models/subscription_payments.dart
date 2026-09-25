import 'package:equatable/equatable.dart';

class SubscriptionPayments extends Equatable {
  final String id;
  final String vendorId;
  final String tierId;
  final double amount;
  final String currency;
  final String paymentStatus;
  final String? paymentMethod;
  final String? transactionId;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionPayments({
    required this.id,
    required this.vendorId,
    required this.tierId,
    required this.amount,
    this.currency = 'USD',
    this.paymentStatus = 'pending',
    this.paymentMethod,
    this.transactionId,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPayments.fromJson(Map<String, dynamic> json) {
    return SubscriptionPayments(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      tierId: json['tier_id'] as String,
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      paymentStatus: json['payment_status'] ?? 'pending',
      paymentMethod: json['payment_method'] as String?,
      transactionId: json['transaction_id'] as String?,
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'tier_id': tierId,
      'amount': amount,
      'currency': currency,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SubscriptionPayments copyWith({
    String? id,
    String? vendorId,
    String? tierId,
    double? amount,
    String? currency,
    String? paymentStatus,
    String? paymentMethod,
    String? transactionId,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPayments(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      tierId: tierId ?? this.tierId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        tierId,
        amount,
        currency,
        paymentStatus,
        paymentMethod,
        transactionId,
        startDate,
        endDate,
        createdAt,
        updatedAt,
      ];
}
