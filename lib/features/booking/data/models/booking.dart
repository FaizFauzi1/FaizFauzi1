import 'package:eventease/features/booking/data/models/installment_plan.dart';
import 'package:flutter/material.dart';

enum BookingStatus {
  pendingVendor,   // Initial request from user
  awaitingPayment, // Vendor accepted, waiting for user deposit
  confirmed,       // Deposit/Full payment paid
  inProgress,      // Event is happening
  completed,       // Event finished
  cancelledByUser,
  cancelledByVendor,
  rejected,
  expired,
  pending,         // Legacy/Fallback
  cancelled,       // Legacy/Fallback
  
  // Amendment Flow Statuses
  changeRequested,   // Customer requested a change
  changeApproved,    // Vendor approved, awaiting finalization or payment
  changeRejected,    // Vendor rejected the change
  awaitingAdjustmentPayment, // Change causes price increase, waiting for user to pay difference
}

enum BookingPaymentStatus {
  unpaid,
  depositPaid,
  partiallyPaid,
  fullyPaid,
  refunded,
}

class Booking {
  final String id;
  final String vendorId;
  final String vendorName; // Added field
  final String customerId; // Added field
  final String serviceId;
  final String serviceName; // Added field
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final DateTime bookingDate;
  final TimeOfDay bookingTime;
  final String duration;
  final String packageName;
  final double amount;
  final String location;
  final String notes;
  final int guestCount; // Added field
  final String? eventType; // Added field
  final BookingStatus status;
  final BookingPaymentStatus paymentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final InstallmentPlan? installmentPlan;
  final Map<String, dynamic>? selectedOptions;

  Booking({
    required this.id,
    required this.vendorId,
    this.vendorName = '', // Added field
    required this.customerId,
    required this.serviceId,
    required this.serviceName,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.bookingDate,
    required this.bookingTime,
    required this.duration,
    required this.packageName,
    required this.amount,
    required this.location,
    required this.notes,
    this.guestCount = 1,
    this.eventType,
    required this.status,
    this.paymentStatus = BookingPaymentStatus.unpaid,
    required this.createdAt,
    required this.updatedAt,
    this.installmentPlan,
    this.selectedOptions,
  });

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] ?? '',
      vendorId: map['vendorId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      customerId: map['customerId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      bookingDate: DateTime.tryParse(map['bookingDate'] ?? '') ?? DateTime.now(),
      bookingTime: _parseTimeOfDay(map['bookingTime'] ?? '10:00'),
      duration: map['duration'] ?? '1 hour',
      packageName: map['packageName'] ?? 'Base Package',
      amount: (map['amount'] ?? 0.0).toDouble(),
      location: map['location'] ?? '',
      notes: map['notes'] ?? '',
      guestCount: map['guestCount'] ?? 1,
      eventType: map['eventType'],
      status: _parseBookingStatus(map['status'] ?? 'pending'),
      paymentStatus: _parseBookingPaymentStatus(map['paymentStatus'] ?? 'unpaid'),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      selectedOptions: map['selectedOptions'] != null ? Map<String, dynamic>.from(map['selectedOptions']) : null,
    );
  }

  // Supabase Integration
  factory Booking.fromSupabase(Map<String, dynamic> json) {
    // Handle join with customer_user if available
    var customerData = json['customer_user'];
    if (customerData is List && customerData.isNotEmpty) {
      customerData = customerData.first; // Handle case where it returns a list
    } else if (customerData is! Map) {
      customerData = {};
    }

    // Handle join with vendor_services if available
    var serviceData = json['vendor_services'];
    if (serviceData is List && serviceData.isNotEmpty) {
      serviceData = serviceData.first;
    } else if (serviceData is! Map) {
      serviceData = {};
    }
    
    // Safely handle booking_details
    Map<String, dynamic> detailsMap = {};
    if (json['booking_details'] is Map) {
      detailsMap = Map<String, dynamic>.from(json['booking_details']);
    }

    // Handle join with vendor_profiles if available
    var vendorProfileData = json['vendor_profiles'];
    if (vendorProfileData is List && vendorProfileData.isNotEmpty) {
      vendorProfileData = vendorProfileData.first;
    } else if (vendorProfileData is! Map) {
      vendorProfileData = {};
    }

    return Booking(
      id: json['id'],
      vendorId: json['vendor_id'],
      vendorName: vendorProfileData['business_name']?.toString() ?? detailsMap['vendorName']?.toString() ?? '',
      customerId: json['customer_id'],
      serviceId: json['service_id'] ?? '',
      serviceName: serviceData['name']?.toString() ?? detailsMap['service']?.toString() ?? 'Unknown Service',
      customerName: customerData['name']?.toString() ?? detailsMap['customerName']?.toString() ?? 'Unknown Customer',
      customerPhone: customerData['phone']?.toString() ?? detailsMap['customerPhone']?.toString() ?? '',
      customerEmail: customerData['email']?.toString() ?? detailsMap['customerEmail']?.toString() ?? '',
      bookingDate: DateTime.parse(json['booking_date']),
      bookingTime: _parseTimeOfDay(json['booking_time'] ?? '00:00:00'),
      duration: json['duration'] ?? '',
      packageName: json['package_name'] ?? '',
      amount: (json['total_amount'] ?? 0.0).toDouble(),
      location: json['location'] ?? '',
      notes: json['notes'] ?? '',
      guestCount: json['guest_count'] ?? detailsMap['guestCount'] ?? 1,
      eventType: json['event_type'],
      status: _parseBookingStatus(json['status'] ?? 'pending_vendor'),
      paymentStatus: _parseBookingPaymentStatus(json['payment_status'] ?? 'unpaid'),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      installmentPlan: (json['installment_plans'] != null && 
                        (json['installment_plans'] is! List || json['installment_plans'].isNotEmpty))
          ? InstallmentPlan.fromSupabase(json['installment_plans'] is List 
              ? json['installment_plans'].first 
              : json['installment_plans']) 
          : null,
      selectedOptions: json['selected_options'] != null ? Map<String, dynamic>.from(json['selected_options']) : null,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'customer_id': customerId,
      'service_id': serviceId.isNotEmpty ? serviceId : null,
      'booking_date': bookingDate.toIso8601String().split('T')[0], // DATE type
      'booking_time': '${bookingTime.hour.toString().padLeft(2, '0')}:${bookingTime.minute.toString().padLeft(2, '0')}:00',
      'duration': duration,
      'package_name': packageName,
      'total_amount': amount,
      'location': location,
      'notes': notes,
      'guest_count': guestCount,
      'event_type': eventType,
      'status': _statusToString(status),
      'payment_status': _bookingPaymentStatusToString(paymentStatus),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'selected_options': selectedOptions,
    };
  }

  String _statusToString(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingVendor: return 'pending_vendor';
      case BookingStatus.awaitingPayment: return 'awaiting_payment';
      case BookingStatus.confirmed: return 'confirmed';
      case BookingStatus.inProgress: return 'in_progress';
      case BookingStatus.completed: return 'completed';
      case BookingStatus.cancelledByUser: return 'cancelled_by_user';
      case BookingStatus.cancelledByVendor: return 'cancelled_by_vendor';
      case BookingStatus.rejected: return 'rejected';
      case BookingStatus.expired: return 'expired';
      case BookingStatus.pending: return 'pending';
      case BookingStatus.cancelled: return 'cancelled';
      case BookingStatus.changeRequested: return 'change_requested';
      case BookingStatus.changeApproved: return 'change_approved';
      case BookingStatus.changeRejected: return 'change_rejected';
      case BookingStatus.awaitingAdjustmentPayment: return 'awaiting_adjustment_payment';
    }
  }

  String _bookingPaymentStatusToString(BookingPaymentStatus status) {
    switch (status) {
      case BookingPaymentStatus.unpaid: return 'unpaid';
      case BookingPaymentStatus.depositPaid: return 'deposit_paid';
      case BookingPaymentStatus.partiallyPaid: return 'partially_paid';
      case BookingPaymentStatus.fullyPaid: return 'fully_paid';
      case BookingPaymentStatus.refunded: return 'refunded';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'customerId': customerId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'bookingDate': bookingDate.toIso8601String(),
      'bookingTime': '${bookingTime.hour.toString().padLeft(2, '0')}:${bookingTime.minute.toString().padLeft(2, '0')}',
      'duration': duration,
      'packageName': packageName,
      'amount': amount,
      'location': location,
      'notes': notes,
      'guestCount': guestCount,
      'eventType': eventType,
      'status': status.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'selectedOptions': selectedOptions,
    };
  }

  Booking copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    String? customerId,
    String? serviceId,
    String? serviceName,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    DateTime? bookingDate,
    TimeOfDay? bookingTime,
    String? duration,
    String? packageName,
    double? amount,
    String? location,
    String? notes,
    int? guestCount,
    String? eventType,
    BookingStatus? status,
    BookingPaymentStatus? paymentStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    InstallmentPlan? installmentPlan,
  }) {
    return Booking(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      customerId: customerId ?? this.customerId,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingTime: bookingTime ?? this.bookingTime,
      duration: duration ?? this.duration,
      packageName: packageName ?? this.packageName,
      amount: amount ?? this.amount,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      guestCount: guestCount ?? this.guestCount,
      eventType: eventType ?? this.eventType,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      installmentPlan: installmentPlan ?? this.installmentPlan,
      selectedOptions: selectedOptions ?? this.selectedOptions,
    );
  }

  static TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 10;
        final minute = int.tryParse(parts[1]) ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // ignore
    }
    return const TimeOfDay(hour: 10, minute: 0);
  }

  static BookingStatus _parseBookingStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'pending_vendor':
        return BookingStatus.pendingVendor;
      case 'awaiting_payment':
        return BookingStatus.awaitingPayment;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
      case 'inprogress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled_by_user':
        return BookingStatus.cancelledByUser;
      case 'cancelled_by_vendor':
        return BookingStatus.cancelledByVendor;
      case 'rejected':
        return BookingStatus.rejected;
      case 'expired':
        return BookingStatus.expired;
      case 'pending':
        return BookingStatus.pending;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'change_requested':
        return BookingStatus.changeRequested;
      case 'change_approved':
        return BookingStatus.changeApproved;
      case 'change_rejected':
        return BookingStatus.changeRejected;
      case 'awaiting_adjustment_payment':
      case 'awaitingadjustmentpayment':
        return BookingStatus.awaitingAdjustmentPayment;
      default:
        return BookingStatus.pendingVendor;
    }
  }

  static BookingPaymentStatus _parseBookingPaymentStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'unpaid':
        return BookingPaymentStatus.unpaid;
      case 'deposit_paid':
        return BookingPaymentStatus.depositPaid;
      case 'partially_paid':
        return BookingPaymentStatus.partiallyPaid;
      case 'fully_paid':
        return BookingPaymentStatus.fullyPaid;
      case 'refunded':
        return BookingPaymentStatus.refunded;
      default:
        return BookingPaymentStatus.unpaid;
    }
  }


}
