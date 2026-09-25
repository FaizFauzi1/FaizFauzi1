import 'package:equatable/equatable.dart';

class Refunds extends Equatable {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String currency;
  final String reason;
  final String status;
  final String? processedBy;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Refunds({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    this.currency = 'USD',
    required this.reason,
    this.status = 'pending',
    this.processedBy,
    required this.requestedAt,
    this.processedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Refunds.fromJson(Map<String, dynamic> json) {
    return Refunds(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'USD',
      reason: json['reason'] as String,
      status: json['status'] ?? 'pending',
      processedBy: json['processed_by'] as String?,
      requestedAt: DateTime.parse(json['requested_at']),
      processedAt: json['processed_at'] != null ? DateTime.parse(json['processed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'reason': reason,
      'status': status,
      'processed_by': processedBy,
      'requested_at': requestedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Refunds copyWith({
    String? id,
    String? bookingId,
    String? userId,
    double? amount,
    String? currency,
    String? reason,
    String? status,
    String? processedBy,
    DateTime? requestedAt,
    DateTime? processedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Refunds(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      processedBy: processedBy ?? this.processedBy,
      requestedAt: requestedAt ?? this.requestedAt,
      processedAt: processedAt ?? this.processedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        userId,
        amount,
        currency,
        reason,
        status,
        processedBy,
        requestedAt,
        processedAt,
        createdAt,
        updatedAt,
      ];
}
