enum AdjustmentType { extraCharge, refund, credit, discount }

enum AdjustmentPaymentStatus { pending, paid, refunded, cancelled }

class BookingPriceAdjustment {
  final String id;
  final String bookingId;
  final String? changeId;
  final double amount;
  final AdjustmentType adjustmentType;
  final AdjustmentPaymentStatus paymentStatus;
  final String? transactionId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingPriceAdjustment({
    required this.id,
    required this.bookingId,
    this.changeId,
    required this.amount,
    required this.adjustmentType,
    this.paymentStatus = AdjustmentPaymentStatus.pending,
    this.transactionId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingPriceAdjustment.fromSupabase(Map<String, dynamic> json) {
    return BookingPriceAdjustment(
      id: json['id'],
      bookingId: json['booking_id'],
      changeId: json['change_id'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      adjustmentType: _parseType(json['adjustment_type']),
      paymentStatus: _parseStatus(json['payment_status']),
      transactionId: json['transaction_id'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'booking_id': bookingId,
      'change_id': changeId,
      'amount': amount,
      'adjustment_type': adjustmentType.name.split('.').last.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), '_').toLowerCase(),
      'payment_status': paymentStatus.name,
      'transaction_id': transactionId,
      'notes': notes,
    };
  }

  static AdjustmentType _parseType(String type) {
    switch (type) {
      case 'extra_charge': return AdjustmentType.extraCharge;
      case 'refund': return AdjustmentType.refund;
      case 'credit': return AdjustmentType.credit;
      case 'discount': return AdjustmentType.discount;
      default: return AdjustmentType.extraCharge;
    }
  }

  static AdjustmentPaymentStatus _parseStatus(String status) {
    switch (status) {
      case 'pending': return AdjustmentPaymentStatus.pending;
      case 'paid': return AdjustmentPaymentStatus.paid;
      case 'refunded': return AdjustmentPaymentStatus.refunded;
      case 'cancelled': return AdjustmentPaymentStatus.cancelled;
      default: return AdjustmentPaymentStatus.pending;
    }
  }
}
