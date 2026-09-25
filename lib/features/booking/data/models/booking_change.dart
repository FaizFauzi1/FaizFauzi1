import 'dart:convert';

enum BookingChangeType { date, package, pax, addOn, other }

enum BookingChangeStatus { pending, approved, rejected, completed, cancelled }

class BookingChange {
  final String id;
  final String bookingId;
  final String requestedBy;
  final BookingChangeType type;
  final Map<String, dynamic> oldValue;
  final Map<String, dynamic> newValue;
  final double priceDiff;
  final BookingChangeStatus status;
  final String? vendorNotes;
  final String? customerNotes;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookingChange({
    required this.id,
    required this.bookingId,
    required this.requestedBy,
    required this.type,
    required this.oldValue,
    required this.newValue,
    this.priceDiff = 0.0,
    this.status = BookingChangeStatus.pending,
    this.vendorNotes,
    this.customerNotes,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingChange.fromSupabase(Map<String, dynamic> json) {
    return BookingChange(
      id: json['id'],
      bookingId: json['booking_id'],
      requestedBy: json['requested_by'],
      type: _parseType(json['change_type']),
      oldValue: json['old_value'] ?? {},
      newValue: json['new_value'] ?? {},
      priceDiff: (json['price_diff'] ?? 0.0).toDouble(),
      status: _parseStatus(json['status']),
      vendorNotes: json['vendor_notes'],
      customerNotes: json['customer_notes'],
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'booking_id': bookingId,
      'requested_by': requestedBy,
      'change_type': type.name,
      'old_value': oldValue,
      'new_value': newValue,
      'price_diff': priceDiff,
      'status': status.name,
      'vendor_notes': vendorNotes,
      'customer_notes': customerNotes,
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  static BookingChangeType _parseType(String type) {
    switch (type) {
      case 'date': return BookingChangeType.date;
      case 'package': return BookingChangeType.package;
      case 'pax': return BookingChangeType.pax;
      case 'add_on': return BookingChangeType.addOn;
      default: return BookingChangeType.other;
    }
  }

  static BookingChangeStatus _parseStatus(String status) {
    switch (status) {
      case 'pending': return BookingChangeStatus.pending;
      case 'approved': return BookingChangeStatus.approved;
      case 'rejected': return BookingChangeStatus.rejected;
      case 'completed': return BookingChangeStatus.completed;
      case 'cancelled': return BookingChangeStatus.cancelled;
      default: return BookingChangeStatus.pending;
    }
  }
}
