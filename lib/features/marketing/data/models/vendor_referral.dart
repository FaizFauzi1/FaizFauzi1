enum ReferralStatus {
  pending, // Referral sent, awaiting response
  accepted, // Referral accepted by receiving vendor
  completed, // Referral led to successful booking
  rejected, // Referral rejected by receiving vendor
  expired, // Referral expired without action
}

enum ReferralType {
  leadSharing, // Sharing a potential customer lead
  capacity, // Referring due to being fully booked
  specialization, // Referring to vendor with better specialization
  location, // Referring to vendor in different location
  partnership, // Referral through partnership agreement
}

class VendorReferral {
  final String id;
  final String senderVendorId; // Vendor sending the referral
  final String senderVendorName;
  final String receiverVendorId; // Vendor receiving the referral
  final String receiverVendorName;
  final ReferralType type;
  final ReferralStatus status;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String eventDetails; // Description of the event/requirement
  final double estimatedValue; // Estimated booking value
  final DateTime referralDate;
  final DateTime? responseDate;
  final DateTime? completionDate;
  final String? notes; // Additional notes from sender
  final String? responseNotes; // Notes from receiver
  final double? commissionEarned; // Commission earned from successful referral
  final Map<String, dynamic> metadata; // Additional referral data

  const VendorReferral({
    required this.id,
    required this.senderVendorId,
    required this.senderVendorName,
    required this.receiverVendorId,
    required this.receiverVendorName,
    required this.type,
    this.status = ReferralStatus.pending,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.eventDetails,
    required this.estimatedValue,
    required this.referralDate,
    this.responseDate,
    this.completionDate,
    this.notes,
    this.responseNotes,
    this.commissionEarned,
    this.metadata = const {},
  });

  // Copy with method
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
    String? notes,
    String? responseNotes,
    double? commissionEarned,
    Map<String, dynamic>? metadata,
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
      notes: notes ?? this.notes,
      responseNotes: responseNotes ?? this.responseNotes,
      commissionEarned: commissionEarned ?? this.commissionEarned,
      metadata: metadata ?? this.metadata,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderVendorId': senderVendorId,
      'senderVendorName': senderVendorName,
      'receiverVendorId': receiverVendorId,
      'receiverVendorName': receiverVendorName,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'eventDetails': eventDetails,
      'estimatedValue': estimatedValue,
      'referralDate': referralDate.toIso8601String(),
      'responseDate': responseDate?.toIso8601String(),
      'completionDate': completionDate?.toIso8601String(),
      'notes': notes,
      'responseNotes': responseNotes,
      'commissionEarned': commissionEarned,
      'metadata': metadata,
    };
  }

  factory VendorReferral.fromJson(Map<String, dynamic> json) {
    return VendorReferral(
      id: json['id'],
      senderVendorId: json['senderVendorId'],
      senderVendorName: json['senderVendorName'],
      receiverVendorId: json['receiverVendorId'],
      receiverVendorName: json['receiverVendorName'],
      type: ReferralType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      status: ReferralStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      customerEmail: json['customerEmail'],
      eventDetails: json['eventDetails'],
      estimatedValue: (json['estimatedValue'] ?? 0.0).toDouble(),
      referralDate: DateTime.parse(json['referralDate']),
      responseDate: json['responseDate'] != null ? DateTime.parse(json['responseDate']) : null,
      completionDate: json['completionDate'] != null ? DateTime.parse(json['completionDate']) : null,
      notes: json['notes'],
      responseNotes: json['responseNotes'],
      commissionEarned: json['commissionEarned']?.toDouble(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  // Helper methods
  bool get isPending => status == ReferralStatus.pending;
  bool get isAccepted => status == ReferralStatus.accepted;
  bool get isCompleted => status == ReferralStatus.completed;
  bool get isRejected => status == ReferralStatus.rejected;
  bool get isExpired => status == ReferralStatus.expired;

  bool get hasCommission => commissionEarned != null && commissionEarned! > 0;

  String get typeDisplayName {
    switch (type) {
      case ReferralType.leadSharing:
        return 'Lead Sharing';
      case ReferralType.capacity:
        return 'Capacity Issue';
      case ReferralType.specialization:
        return 'Specialization';
      case ReferralType.location:
        return 'Location';
      case ReferralType.partnership:
        return 'Partnership';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case ReferralStatus.pending:
        return 'Pending';
      case ReferralStatus.accepted:
        return 'Accepted';
      case ReferralStatus.completed:
        return 'Completed';
      case ReferralStatus.rejected:
        return 'Rejected';
      case ReferralStatus.expired:
        return 'Expired';
    }
  }

  // Check if referral is from a specific vendor
  bool isFromVendor(String vendorId) {
    return senderVendorId == vendorId;
  }

  // Check if referral is to a specific vendor
  bool isToVendor(String vendorId) {
    return receiverVendorId == vendorId;
  }

  // Check if vendor is involved in this referral
  bool involvesVendor(String vendorId) {
    return isFromVendor(vendorId) || isToVendor(vendorId);
  }

  // Get formatted customer contact info
  String get customerContactInfo {
    return '$customerName\n$customerPhone\n$customerEmail';
  }

  // Calculate days since referral
  int get daysSinceReferral {
    return DateTime.now().difference(referralDate).inDays;
  }

  // Check if referral is expired (more than 30 days old and still pending)
  bool get isExpiredByTime {
    return isPending && daysSinceReferral > 30;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VendorReferral &&
        other.id == id &&
        other.senderVendorId == senderVendorId &&
        other.senderVendorName == senderVendorName &&
        other.receiverVendorId == receiverVendorId &&
        other.receiverVendorName == receiverVendorName &&
        other.type == type &&
        other.status == status &&
        other.customerName == customerName &&
        other.customerPhone == customerPhone &&
        other.customerEmail == customerEmail &&
        other.eventDetails == eventDetails &&
        other.estimatedValue == estimatedValue &&
        other.referralDate == referralDate &&
        other.responseDate == responseDate &&
        other.completionDate == completionDate &&
        other.notes == notes &&
        other.responseNotes == responseNotes &&
        other.commissionEarned == commissionEarned &&
        other.metadata == metadata;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        senderVendorId.hashCode ^
        senderVendorName.hashCode ^
        receiverVendorId.hashCode ^
        receiverVendorName.hashCode ^
        type.hashCode ^
        status.hashCode ^
        customerName.hashCode ^
        customerPhone.hashCode ^
        customerEmail.hashCode ^
        eventDetails.hashCode ^
        estimatedValue.hashCode ^
        referralDate.hashCode ^
        responseDate.hashCode ^
        completionDate.hashCode ^
        notes.hashCode ^
        responseNotes.hashCode ^
        commissionEarned.hashCode ^
        metadata.hashCode;
  }
}
