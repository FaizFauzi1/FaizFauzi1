enum CollaborationRequestStatus {
  pending,
  accepted,
  rejected,
  expired,
}

enum CollaborationType {
  partnership, // Long-term partnership
  oneTime, // Single event collaboration
  referral, // Lead sharing
  package, // Joint package creation
}

class VendorCollaborationRequest {
  final String id;
  final String senderVendorId;
  final String receiverVendorId;
  final String senderVendorName;
  final String receiverVendorName;
  final CollaborationType type;
  final String message;
  final CollaborationRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? responseMessage;
  final Map<String, dynamic>? collaborationDetails; // Additional data based on type

  const VendorCollaborationRequest({
    required this.id,
    required this.senderVendorId,
    required this.receiverVendorId,
    required this.senderVendorName,
    required this.receiverVendorName,
    required this.type,
    required this.message,
    this.status = CollaborationRequestStatus.pending,
    required this.createdAt,
    this.respondedAt,
    this.responseMessage,
    this.collaborationDetails,
  });

  // Copy with method for state updates
  VendorCollaborationRequest copyWith({
    String? id,
    String? senderVendorId,
    String? receiverVendorId,
    String? senderVendorName,
    String? receiverVendorName,
    CollaborationType? type,
    String? message,
    CollaborationRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? responseMessage,
    Map<String, dynamic>? collaborationDetails,
  }) {
    return VendorCollaborationRequest(
      id: id ?? this.id,
      senderVendorId: senderVendorId ?? this.senderVendorId,
      receiverVendorId: receiverVendorId ?? this.receiverVendorId,
      senderVendorName: senderVendorName ?? this.senderVendorName,
      receiverVendorName: receiverVendorName ?? this.receiverVendorName,
      type: type ?? this.type,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      responseMessage: responseMessage ?? this.responseMessage,
      collaborationDetails: collaborationDetails ?? this.collaborationDetails,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderVendorId': senderVendorId,
      'receiverVendorId': receiverVendorId,
      'senderVendorName': senderVendorName,
      'receiverVendorName': receiverVendorName,
      'type': type.toString().split('.').last,
      'message': message,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'responseMessage': responseMessage,
      'collaborationDetails': collaborationDetails,
    };
  }

  factory VendorCollaborationRequest.fromJson(Map<String, dynamic> json) {
    return VendorCollaborationRequest(
      id: json['id'],
      senderVendorId: json['senderVendorId'],
      receiverVendorId: json['receiverVendorId'],
      senderVendorName: json['senderVendorName'],
      receiverVendorName: json['receiverVendorName'],
      type: CollaborationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      message: json['message'],
      status: CollaborationRequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
      responseMessage: json['responseMessage'],
      collaborationDetails: json['collaborationDetails'],
    );
  }

  // Helper methods
  bool get isPending => status == CollaborationRequestStatus.pending;
  bool get isAccepted => status == CollaborationRequestStatus.accepted;
  bool get isRejected => status == CollaborationRequestStatus.rejected;
  bool get isExpired => status == CollaborationRequestStatus.expired;

  String get typeDisplayName {
    switch (type) {
      case CollaborationType.partnership:
        return 'Partnership';
      case CollaborationType.oneTime:
        return 'One-time Collaboration';
      case CollaborationType.referral:
        return 'Referral Agreement';
      case CollaborationType.package:
        return 'Package Collaboration';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case CollaborationRequestStatus.pending:
        return 'Pending';
      case CollaborationRequestStatus.accepted:
        return 'Accepted';
      case CollaborationRequestStatus.rejected:
        return 'Rejected';
      case CollaborationRequestStatus.expired:
        return 'Expired';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VendorCollaborationRequest &&
        other.id == id &&
        other.senderVendorId == senderVendorId &&
        other.receiverVendorId == receiverVendorId &&
        other.senderVendorName == senderVendorName &&
        other.receiverVendorName == receiverVendorName &&
        other.type == type &&
        other.message == message &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.respondedAt == respondedAt &&
        other.responseMessage == responseMessage &&
        other.collaborationDetails == collaborationDetails;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        senderVendorId.hashCode ^
        receiverVendorId.hashCode ^
        senderVendorName.hashCode ^
        receiverVendorName.hashCode ^
        type.hashCode ^
        message.hashCode ^
        status.hashCode ^
        createdAt.hashCode ^
        respondedAt.hashCode ^
        responseMessage.hashCode ^
        collaborationDetails.hashCode;
  }
}
