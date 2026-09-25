import 'package:equatable/equatable.dart';

enum BookingStatus { pending, confirmed, inProgress, completed, cancelled, refunded }

class Booking extends Equatable {
  final String id;
  final String customerId;
  final String vendorId;
  final String serviceId;
  final DateTime eventDate;
  final DateTime? startTime;
  final DateTime? endTime;
  final int guestCount;
  final double totalAmount;
  final double? depositAmount;
  final BookingStatus status;
  final String? specialRequests;
  final String? paymentId;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final Map<String, dynamic> bookingDetails;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Booking({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.serviceId,
    required this.eventDate,
    this.startTime,
    this.endTime,
    required this.guestCount,
    required this.totalAmount,
    this.depositAmount,
    this.status = BookingStatus.pending,
    this.specialRequests,
    this.paymentId,
    this.cancellationReason,
    this.cancelledAt,
    required this.bookingDetails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      vendorId: json['vendor_id'] as String,
      serviceId: json['service_id'] as String,
      eventDate: DateTime.parse(json['event_date']),
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      guestCount: json['guest_count'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      depositAmount: json['deposit_amount']?.toDouble(),
      status: BookingStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      specialRequests: json['special_requests'] as String?,
      paymentId: json['payment_id'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']) : null,
      bookingDetails: Map<String, dynamic>.from(json['booking_details'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'vendor_id': vendorId,
      'service_id': serviceId,
      'event_date': eventDate.toIso8601String(),
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'guest_count': guestCount,
      'total_amount': totalAmount,
      'deposit_amount': depositAmount,
      'status': status.name,
      'special_requests': specialRequests,
      'payment_id': paymentId,
      'cancellation_reason': cancellationReason,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'booking_details': bookingDetails,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Booking copyWith({
    String? id,
    String? customerId,
    String? vendorId,
    String? serviceId,
    DateTime? eventDate,
    DateTime? startTime,
    DateTime? endTime,
    int? guestCount,
    double? totalAmount,
    double? depositAmount,
    BookingStatus? status,
    String? specialRequests,
    String? paymentId,
    String? cancellationReason,
    DateTime? cancelledAt,
    Map<String, dynamic>? bookingDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      vendorId: vendorId ?? this.vendorId,
      serviceId: serviceId ?? this.serviceId,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      guestCount: guestCount ?? this.guestCount,
      totalAmount: totalAmount ?? this.totalAmount,
      depositAmount: depositAmount ?? this.depositAmount,
      status: status ?? this.status,
      specialRequests: specialRequests ?? this.specialRequests,
      paymentId: paymentId ?? this.paymentId,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      bookingDetails: bookingDetails ?? this.bookingDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        vendorId,
        serviceId,
        eventDate,
        startTime,
        endTime,
        guestCount,
        totalAmount,
        depositAmount,
        status,
        specialRequests,
        paymentId,
        cancellationReason,
        cancelledAt,
        bookingDetails,
        createdAt,
        updatedAt,
      ];
}
