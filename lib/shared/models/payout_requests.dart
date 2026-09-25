import 'package:equatable/equatable.dart';

enum PayoutRequestStatus { pending, approved, rejected, processed }

class PayoutRequests extends Equatable {
  final String id;
  final String vendorId;
  final double amount;
  final String currency;
  final PayoutRequestStatus status;
  final String? bankAccountId;
  final String? notes;
  final String? processedBy;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PayoutRequests({
    required this.id,
    required this.vendorId,
    required this.amount,
    this.currency = 'USD',
    this.status = PayoutRequestStatus.pending,
    this.bankAccountId,
    this.notes,
    this.processedBy,
    this.processedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PayoutRequests.fromJson(Map<String, dynamic> json) {
    return PayoutRequests(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'USD',
      status: PayoutRequestStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => PayoutRequestStatus.pending,
      ),
      bankAccountId: json['bank_account_id'] as String?,
      notes: json['notes'] as String?,
      processedBy: json['processed_by'] as String?,
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'bank_account_id': bankAccountId,
      'notes': notes,
      'processed_by': processedBy,
      'processed_at': processedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PayoutRequests copyWith({
    String? id,
    String? vendorId,
    double? amount,
    String? currency,
    PayoutRequestStatus? status,
    String? bankAccountId,
    String? notes,
    String? processedBy,
    DateTime? processedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PayoutRequests(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      bankAccountId: bankAccountId ?? this.bankAccountId,
      notes: notes ?? this.notes,
      processedBy: processedBy ?? this.processedBy,
      processedAt: processedAt ?? this.processedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        amount,
        currency,
        status,
        bankAccountId,
        notes,
        processedBy,
        processedAt,
        createdAt,
        updatedAt,
      ];
}
