import 'package:equatable/equatable.dart';

enum PayoutStatus { pending, processing, completed, failed, cancelled }
enum PayoutMethod { bankTransfer, paypal, stripe, manual }

class Payout extends Equatable {
  final String id;
  final String vendorId;
  final double amount;
  final PayoutMethod payoutMethod;
  final PayoutStatus status;
  final String? bankAccountId;
  final String? paypalEmail;
  final String? transactionId;
  final String? failureReason;
  final Map<String, dynamic> payoutData;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime? completedAt;

  const Payout({
    required this.id,
    required this.vendorId,
    required this.amount,
    required this.payoutMethod,
    this.status = PayoutStatus.pending,
    this.bankAccountId,
    this.paypalEmail,
    this.transactionId,
    this.failureReason,
    required this.payoutData,
    required this.requestedAt,
    this.processedAt,
    this.completedAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      amount: (json['amount'] ?? 0).toDouble(),
      payoutMethod: PayoutMethod.values.firstWhere(
        (method) => method.name == json['payout_method'],
        orElse: () => PayoutMethod.bankTransfer,
      ),
      status: PayoutStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => PayoutStatus.pending,
      ),
      bankAccountId: json['bank_account_id'] as String?,
      paypalEmail: json['paypal_email'] as String?,
      transactionId: json['transaction_id'] as String?,
      failureReason: json['failure_reason'] as String?,
      payoutData: Map<String, dynamic>.from(json['payout_data'] ?? {}),
      requestedAt: DateTime.parse(json['requested_at']),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'amount': amount,
      'payout_method': payoutMethod.name,
      'status': status.name,
      'bank_account_id': bankAccountId,
      'paypal_email': paypalEmail,
      'transaction_id': transactionId,
      'failure_reason': failureReason,
      'payout_data': payoutData,
      'requested_at': requestedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Payout copyWith({
    String? id,
    String? vendorId,
    double? amount,
    PayoutMethod? payoutMethod,
    PayoutStatus? status,
    String? bankAccountId,
    String? paypalEmail,
    String? transactionId,
    String? failureReason,
    Map<String, dynamic>? payoutData,
    DateTime? requestedAt,
    DateTime? processedAt,
    DateTime? completedAt,
  }) {
    return Payout(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      amount: amount ?? this.amount,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      status: status ?? this.status,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      paypalEmail: paypalEmail ?? this.paypalEmail,
      transactionId: transactionId ?? this.transactionId,
      failureReason: failureReason ?? this.failureReason,
      payoutData: payoutData ?? this.payoutData,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        amount,
        payoutMethod,
        status,
        bankAccountId,
        paypalEmail,
        transactionId,
        failureReason,
        payoutData,
        requestedAt,
        processedAt,
        completedAt,
      ];
}
