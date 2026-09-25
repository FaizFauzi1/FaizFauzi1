import 'package:intl/intl.dart';

enum InstallmentPlanStatus {
  active,
  completed,
  cancelled,
}

enum InstallmentPaymentStatus {
  pending,
  paid,
  late,
  cancelled,
}

class InstallmentPlan {
  final String id;
  final String bookingId;
  final double totalAmount;
  final double depositAmount;
  final double remainingBalance;
  final int numberOfInstallments;
  final InstallmentPlanStatus status;
  final List<InstallmentPayment> payments;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get totalInstallments => numberOfInstallments;

  InstallmentPlan({
    required this.id,
    required this.bookingId,
    required this.totalAmount,
    required this.depositAmount,
    required this.remainingBalance,
    required this.numberOfInstallments,
    required this.status,
    this.payments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstallmentPlan.fromSupabase(Map<String, dynamic> json) {
    return InstallmentPlan(
      id: json['id'],
      bookingId: json['booking_id'],
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      depositAmount: (json['deposit_amount'] ?? 0.0).toDouble(),
      remainingBalance: (json['remaining_balance'] ?? 0.0).toDouble(),
      numberOfInstallments: json['number_of_installments'] ?? 0,
      status: _parsePlanStatus(json['status'] ?? 'active'),
      payments: (json['installment_payments'] as List? ?? [])
          .map((p) => InstallmentPayment.fromSupabase(p))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'booking_id': bookingId,
      'total_amount': totalAmount,
      'deposit_amount': depositAmount,
      'remaining_balance': remainingBalance,
      'number_of_installments': numberOfInstallments,
      'status': status.name,
    };
  }

  static InstallmentPlanStatus _parsePlanStatus(String status) {
    return InstallmentPlanStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => InstallmentPlanStatus.active,
    );
  }
}

class InstallmentPayment {
  final String id;
  final String planId;
  final double amount;
  final DateTime dueDate;
  final InstallmentPaymentStatus status;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  InstallmentPayment({
    required this.id,
    required this.planId,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paymentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstallmentPayment.fromSupabase(Map<String, dynamic> json) {
    return InstallmentPayment(
      id: json['id'],
      planId: json['plan_id'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      dueDate: DateTime.parse(json['due_date']),
      status: _parsePaymentStatus(json['status'] ?? 'pending'),
      paymentId: json['payment_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'plan_id': planId,
      'amount': amount,
      'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
      'status': status.name,
      'payment_id': paymentId,
    };
  }

  static InstallmentPaymentStatus _parsePaymentStatus(String status) {
    return InstallmentPaymentStatus.values.firstWhere(
      (e) => e.name == status.toLowerCase(),
      orElse: () => InstallmentPaymentStatus.pending,
    );
  }
}
