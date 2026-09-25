import 'package:flutter/material.dart';

enum NotificationType {
  // --- Discovery & Inquiry ---
  inquiryReply,
  quoteUpdated,
  quotation,
  
  // --- Booking Lifecycle ---
  booking,
  bookingSubmitted,
  vendorConfirmed,
  vendorRejected,
  newBookingRequest,
  dateChangeRequest,
  packageChangeRequest,
  bookingRescheduled,
  bookingCancelled,
  requestExpired,
  slaBreachWarning,
  
  // --- Payment & Finance ---
  payment,
  paymentReceived,
  paymentFailed,
  paymentLinkCreated,
  depositReceived,
  depositSuccessful,
  installmentDue,
  installmentOverdue,
  finalBalanceReminder,
  balanceReminder,
  depositReminder,
  refundInitiated,
  refundCompleted,
  refundProcessed,
  invoiceGenerated,
  receiptAvailable,
  paymentSettlement,
  vendorPayout,
  payoutRequested,
  payoutApproved,
  
  // --- Logistics & Venue ---
  venueDetailsPending,
  venueDetailsUpdated,
  logisticsPriceChanged,
  dateBlocked,
  conflictDetected,
  
  // --- Event Day Operations ---
  vendorArrived,
  vendorDelayed,
  emergencyAlert,
  eventReminder30d,
  eventReminder7d,
  eventReminder1d,
  vendorArrivalReminder,
  vendorOnTheWay,
  vendorStarted,
  vendorServiceCompleted,
  
  // --- Post-Event & Trust ---
  review,
  reviewReceived,
  leaveReviewReminder,
  vendorRatingRequest,
  milestoneReached,
  profileIncomplete,
  slaWarning,
  
  // --- Chat & Messaging ---
  chat,
  message,
  newMessage,
  missedMessage,
  adminSupportReply,
  customerMessage,
  
  // --- General ---
  reminder,
  promotion,
  
  // --- Admin & System ---
  system,
  update,
  eventUpdate,
  vendorApproval,
  vendorRejection,
  vendorSuspension,
  vendorActivation,
  vendorMessage,
  vendorDocumentVerification,
  vendorServiceApproval,
  accountVerified,
  documentApproved,
  serviceApproved,
  serviceRejected,
  subscriptionExpiring,
  policyUpdate,
  maintenanceDowntime,
  systemUpdate,
  disputeOpened,
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() => '$hour:$minute';
}

enum NotificationSeverity {
  info,
  actionRequired,
  urgent,
  system,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

enum NotificationChannel {
  push,
  email,
  inapp,
  sms,
}

enum NotificationStatus {
  sent,
  delivered,
  read,
  failed,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final NotificationSeverity severity;
  final NotificationChannel channel;
  final NotificationStatus notificationStatus;
  final String? relatedId;
  final Map<String, dynamic>? data;
  final bool isRead;
  final bool isArchived;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? scheduledFor;
  final String? actionUrl;
  final String? imageUrl;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.severity = NotificationSeverity.info,
    this.channel = NotificationChannel.inapp,
    this.notificationStatus = NotificationStatus.delivered,
    this.relatedId,
    this.data,
    this.isRead = false,
    this.isArchived = false,
    this.isPinned = false,
    required this.createdAt,
    this.readAt,
    this.scheduledFor,
    this.actionUrl,
    this.imageUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.system,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      severity: NotificationSeverity.values.firstWhere(
        (e) => e.toString().split('.').last == json['severity'],
        orElse: () => NotificationSeverity.info,
      ),
      channel: NotificationChannel.values.firstWhere(
        (e) => e.toString().split('.').last == json['channel'],
        orElse: () => NotificationChannel.inapp,
      ),
      notificationStatus: NotificationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['notification_status'],
        orElse: () => NotificationStatus.delivered,
      ),
      relatedId: json['related_id'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] ?? false,
      isArchived: json['is_archived'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      scheduledFor: json['scheduled_for'] != null ? DateTime.parse(json['scheduled_for']) : null,
      actionUrl: json['action_url'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'channel': channel.toString().split('.').last,
      'notification_status': notificationStatus.toString().split('.').last,
      'related_id': relatedId,
      'data': data,
      'is_read': isRead,
      'is_archived': isArchived,
      // 'is_pinned': isPinned, // Disabled until column is added to database
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'scheduled_for': scheduledFor?.toIso8601String(),
      'action_url': actionUrl,
      'image_url': imageUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    NotificationSeverity? severity,
    NotificationChannel? channel,
    NotificationStatus? notificationStatus,
    String? relatedId,
    Map<String, dynamic>? data,
    bool? isRead,
    bool? isArchived,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? scheduledFor,
    String? actionUrl,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      severity: severity ?? this.severity,
      channel: channel ?? this.channel,
      notificationStatus: notificationStatus ?? this.notificationStatus,
      relatedId: relatedId ?? this.relatedId,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
}

class NotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final Set<NotificationType> enabledTypes;
  final Map<NotificationType, NotificationPriority> typePriorities;
  final bool quietHoursEnabled;
  final TimeOfDay? quietStartTime;
  final TimeOfDay? quietEndTime;
  final Set<int> workingDays; // 1 = Monday, 7 = Sunday

  NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    Set<NotificationType>? enabledTypes,
    Map<NotificationType, NotificationPriority>? typePriorities,
    this.quietHoursEnabled = false,
    this.quietStartTime,
    this.quietEndTime,
    Set<int>? workingDays,
  }) :
    enabledTypes = enabledTypes ?? NotificationType.values.toSet(),
    typePriorities = typePriorities ?? {
      NotificationType.booking: NotificationPriority.high,
      NotificationType.reminder: NotificationPriority.high,
      NotificationType.system: NotificationPriority.normal,
      NotificationType.message: NotificationPriority.normal,
      NotificationType.payment: NotificationPriority.high,
      NotificationType.promotion: NotificationPriority.low,
      NotificationType.review: NotificationPriority.normal,
      NotificationType.update: NotificationPriority.normal,
      NotificationType.eventUpdate: NotificationPriority.normal,
    },
    workingDays = workingDays ?? {1, 2, 3, 4, 5, 6, 7}; // All days

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushEnabled: json['push_enabled'] ?? true,
      emailEnabled: json['email_enabled'] ?? true,
      smsEnabled: json['sms_enabled'] ?? false,
      enabledTypes: (json['enabled_types'] as List<dynamic>?)
          ?.map((e) => NotificationType.values.firstWhere(
                (type) => type.toString().split('.').last == e,
                orElse: () => NotificationType.system,
              ))
          .toSet() ?? NotificationType.values.toSet(),
      typePriorities: (json['type_priorities'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(
          NotificationType.values.firstWhere(
            (type) => type.toString().split('.').last == key,
            orElse: () => NotificationType.system,
          ),
          NotificationPriority.values.firstWhere(
            (priority) => priority.toString().split('.').last == value,
            orElse: () => NotificationPriority.normal,
          ),
        ),
      ) ?? {},
      quietHoursEnabled: json['quiet_hours_enabled'] ?? false,
      quietStartTime: json['quiet_start_time'] != null
          ? TimeOfDay(
              hour: int.parse(json['quiet_start_time'].split(':')[0]),
              minute: int.parse(json['quiet_start_time'].split(':')[1]),
            )
          : null,
      quietEndTime: json['quiet_end_time'] != null
          ? TimeOfDay(
              hour: int.parse(json['quiet_end_time'].split(':')[0]),
              minute: int.parse(json['quiet_end_time'].split(':')[1]),
            )
          : null,
      workingDays: (json['working_days'] as List<dynamic>?)?.map((e) => e as int).toSet() ?? {1, 2, 3, 4, 5, 6, 7},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
      'sms_enabled': smsEnabled,
      'enabled_types': enabledTypes.map((e) => e.toString().split('.').last).toList(),
      'type_priorities': typePriorities.map(
        (key, value) => MapEntry(key.toString().split('.').last, value.toString().split('.').last),
      ),
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_start_time': quietStartTime != null ? '${quietStartTime!.hour}:${quietStartTime!.minute}' : null,
      'quiet_end_time': quietEndTime != null ? '${quietEndTime!.hour}:${quietEndTime!.minute}' : null,
      'working_days': workingDays.toList(),
    };
  }

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    Set<NotificationType>? enabledTypes,
    Map<NotificationType, NotificationPriority>? typePriorities,
    bool? quietHoursEnabled,
    TimeOfDay? quietStartTime,
    TimeOfDay? quietEndTime,
    Set<int>? workingDays,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      enabledTypes: enabledTypes ?? this.enabledTypes,
      typePriorities: typePriorities ?? this.typePriorities,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartTime: quietStartTime ?? this.quietStartTime,
      quietEndTime: quietEndTime ?? this.quietEndTime,
      workingDays: workingDays ?? this.workingDays,
    );
  }
}
