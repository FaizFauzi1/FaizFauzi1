import 'package:equatable/equatable.dart';

enum ContentType { review, message, profile, serviceDescription, portfolio }
enum ModerationStatus { pending, underReview, approved, rejected, escalated }
enum Priority { low, medium, high, urgent }

class ModerationQueue extends Equatable {
  final String id;
  final ContentType contentType;
  final String contentId;
  final String reportedBy;
  final String reason;
  final String? description;
  final ModerationStatus status;
  final Priority priority;
  final String? assignedTo;
  final DateTime? reviewedAt;
  final String? actionTaken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ModerationQueue({
    required this.id,
    required this.contentType,
    required this.contentId,
    required this.reportedBy,
    required this.reason,
    this.description,
    this.status = ModerationStatus.pending,
    this.priority = Priority.medium,
    this.assignedTo,
    this.reviewedAt,
    this.actionTaken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ModerationQueue.fromJson(Map<String, dynamic> json) {
    return ModerationQueue(
      id: json['id'] as String,
      contentType: ContentType.values.firstWhere(
        (type) => type.name == json['content_type'],
        orElse: () => ContentType.review,
      ),
      contentId: json['content_id'] as String,
      reportedBy: json['reported_by'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: ModerationStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ModerationStatus.pending,
      ),
      priority: Priority.values.firstWhere(
        (priority) => priority.name == json['priority'],
        orElse: () => Priority.medium,
      ),
      assignedTo: json['assigned_to'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      actionTaken: json['action_taken'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_type': contentType.name,
      'content_id': contentId,
      'reported_by': reportedBy,
      'reason': reason,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'assigned_to': assignedTo,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'action_taken': actionTaken,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ModerationQueue copyWith({
    String? id,
    ContentType? contentType,
    String? contentId,
    String? reportedBy,
    String? reason,
    String? description,
    ModerationStatus? status,
    Priority? priority,
    String? assignedTo,
    DateTime? reviewedAt,
    String? actionTaken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModerationQueue(
      id: id ?? this.id,
      contentType: contentType ?? this.contentType,
      contentId: contentId ?? this.contentId,
      reportedBy: reportedBy ?? this.reportedBy,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      actionTaken: actionTaken ?? this.actionTaken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contentType,
        contentId,
        reportedBy,
        reason,
        description,
        status,
        priority,
        assignedTo,
        reviewedAt,
        actionTaken,
        createdAt,
        updatedAt,
      ];
}
