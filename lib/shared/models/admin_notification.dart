enum AdminNotificationType {
  booking,
  payment,
  vendor,
  system,
  support,
  onboarding,
  risk,
  health,
  business,
}

enum AdminNotificationSeverity {
  low,
  medium,
  high,
  critical,
}

enum AdminNotificationStatus {
  unread,
  read,
  resolved,
}

class AdminNotificationModel {
  final String id;
  final AdminNotificationType type;
  final AdminNotificationSeverity severity;
  final String title;
  final String message;
  final String? relatedUserId;
  final String? relatedVendorId;
  final String? relatedBookingId;
  final AdminNotificationStatus status;
  final String? actionUrl;
  final DateTime createdAt;

  AdminNotificationModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.relatedUserId,
    this.relatedVendorId,
    this.relatedBookingId,
    this.status = AdminNotificationStatus.unread,
    this.actionUrl,
    required this.createdAt,
  });

  factory AdminNotificationModel.fromJson(Map<String, dynamic> json) {
    String enumTail(Object? value) =>
        value?.toString().split('.').last ?? '';

    DateTime parseCreatedAt(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return AdminNotificationModel(
      id: json['id']?.toString() ?? '',
      type: AdminNotificationType.values.firstWhere(
        (e) => e.name == enumTail(json['type']),
        orElse: () => AdminNotificationType.system,
      ),
      severity: AdminNotificationSeverity.values.firstWhere(
        (e) => e.name == enumTail(json['severity']),
        orElse: () => AdminNotificationSeverity.medium,
      ),
      title: json['title']?.toString() ?? 'Admin alert',
      message: json['message']?.toString() ?? '',
      relatedUserId: json['related_user_id']?.toString(),
      relatedVendorId: json['related_vendor_id']?.toString(),
      relatedBookingId: json['related_booking_id']?.toString(),
      status: AdminNotificationStatus.values.firstWhere(
        (e) => e.name == enumTail(json['status']),
        orElse: () => AdminNotificationStatus.unread,
      ),
      actionUrl: json['action_url']?.toString(),
      createdAt: parseCreatedAt(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'title': title,
      'message': message,
      'related_user_id': relatedUserId,
      'related_vendor_id': relatedVendorId,
      'related_booking_id': relatedBookingId,
      'status': status.toString().split('.').last,
      'action_url': actionUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AdminNotificationModel copyWith({
    String? id,
    AdminNotificationType? type,
    AdminNotificationSeverity? severity,
    String? title,
    String? message,
    String? relatedUserId,
    String? relatedVendorId,
    String? relatedBookingId,
    AdminNotificationStatus? status,
    String? actionUrl,
    DateTime? createdAt,
  }) {
    return AdminNotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      relatedVendorId: relatedVendorId ?? this.relatedVendorId,
      relatedBookingId: relatedBookingId ?? this.relatedBookingId,
      status: status ?? this.status,
      actionUrl: actionUrl ?? this.actionUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
