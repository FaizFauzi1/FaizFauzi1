import 'package:equatable/equatable.dart';

enum ReferralType {
  leadSharing,
  capacity,
  expertise,
  partnership,
}

enum ReferralStatus {
  pending,
  accepted,
  rejected,
  completed,
  cancelled,
}

class VendorReferral extends Equatable {
  final String id;
  final String senderVendorId;
  final String senderVendorName;
  final String receiverVendorId;
  final String receiverVendorName;
  final ReferralType type;
  final ReferralStatus status;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String eventDetails;
  final double estimatedValue;
  final DateTime referralDate;
  final DateTime? responseDate;
  final DateTime? completionDate;
  final double? commissionEarned;

  const VendorReferral({
    required this.id,
    required this.senderVendorId,
    required this.senderVendorName,
    required this.receiverVendorId,
    required this.receiverVendorName,
    required this.type,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.eventDetails,
    required this.estimatedValue,
    required this.referralDate,
    this.responseDate,
    this.completionDate,
    this.commissionEarned,
  });

  bool get isCompleted => status == ReferralStatus.completed;

  VendorReferral copyWith({
    String? id,
    String? senderVendorId,
    String? senderVendorName,
    String? receiverVendorId,
    String? receiverVendorName,
    ReferralType? type,
    ReferralStatus? status,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? eventDetails,
    double? estimatedValue,
    DateTime? referralDate,
    DateTime? responseDate,
    DateTime? completionDate,
    double? commissionEarned,
  }) {
    return VendorReferral(
      id: id ?? this.id,
      senderVendorId: senderVendorId ?? this.senderVendorId,
      senderVendorName: senderVendorName ?? this.senderVendorName,
      receiverVendorId: receiverVendorId ?? this.receiverVendorId,
      receiverVendorName: receiverVendorName ?? this.receiverVendorName,
      type: type ?? this.type,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      eventDetails: eventDetails ?? this.eventDetails,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      referralDate: referralDate ?? this.referralDate,
      responseDate: responseDate ?? this.responseDate,
      completionDate: completionDate ?? this.completionDate,
      commissionEarned: commissionEarned ?? this.commissionEarned,
    );
  }

  @override
  List<Object?> get props => [
        id,
        senderVendorId,
        senderVendorName,
        receiverVendorId,
        receiverVendorName,
        type,
        status,
        customerName,
        customerPhone,
        customerEmail,
        eventDetails,
        estimatedValue,
        referralDate,
        responseDate,
        completionDate,
        commissionEarned,
      ];
}
