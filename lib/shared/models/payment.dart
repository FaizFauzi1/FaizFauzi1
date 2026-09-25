import 'package:equatable/equatable.dart';

enum PaymentStatus { pending, processing, paid, failed, refunded, cancelled, completed }
enum PaymentGatewayProvider { stripe, billplz, senangpay, toyyibpay, manual, xendit }

enum PaymentMethod { 
  cash, 
  bankTransfer, 
  creditCard, 
  debitCard, 
  onlinePayment, 
  check,
  onlineBanking,
  eWallet,
  cashOnDelivery 
}

class Payment extends Equatable {
  final String id;
  final String userId;
  final String? bookingId;
  final double amount;
  final PaymentGatewayProvider paymentProvider;
  final String? paymentMethod;
  final String? transactionId;
  final PaymentStatus status;
  final String? receiptUrl;
  final Map<String, dynamic> paymentData;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Payment({
    required this.id,
    required this.userId,
    this.bookingId,
    required this.amount,
    required this.paymentProvider,
    this.paymentMethod,
    this.transactionId,
    this.status = PaymentStatus.pending,
    this.receiptUrl,
    required this.paymentData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bookingId: json['booking_id'] as String?,
      amount: (json['amount'] ?? 0).toDouble(),
      paymentProvider: PaymentGatewayProvider.values.firstWhere(
        (provider) => provider.name == json['payment_provider'],
        orElse: () => PaymentGatewayProvider.manual,
      ),
      paymentMethod: json['payment_method'] as String?,
      transactionId: json['transaction_id'] as String?,
      status: PaymentStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      receiptUrl: json['receipt_url'] as String?,
      paymentData: Map<String, dynamic>.from(json['payment_data'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'booking_id': bookingId,
      'amount': amount,
      'payment_provider': paymentProvider.name,
      'payment_method': paymentMethod,
      'transaction_id': transactionId,
      'status': status.name,
      'receipt_url': receiptUrl,
      'payment_data': paymentData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? userId,
    String? bookingId,
    double? amount,
    PaymentGatewayProvider? paymentProvider,
    String? paymentMethod,
    String? transactionId,
    PaymentStatus? status,
    String? receiptUrl,
    Map<String, dynamic>? paymentData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookingId: bookingId ?? this.bookingId,
      amount: amount ?? this.amount,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      paymentData: paymentData ?? this.paymentData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        bookingId,
        amount,
        paymentProvider,
        paymentMethod,
        transactionId,
        status,
        receiptUrl,
        paymentData,
        createdAt,
        updatedAt,
      ];
}
