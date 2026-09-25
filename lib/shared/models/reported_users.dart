import 'package:equatable/equatable.dart';

enum ReportedUserStatus { pending, investigating, resolved, dismissed }

class ReportedUsers extends Equatable {
  final String id;
  final String reportedUserId;
  final String reportedBy;
  final String reason;
  final String? description;
  final ReportedUserStatus status;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReportedUsers({
    required this.id,
    required this.reportedUserId,
    required this.reportedBy,
    required this.reason,
    this.description,
    this.status = ReportedUserStatus.pending,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReportedUsers.fromJson(Map<String, dynamic> json) {
    return ReportedUsers(
      id: json['id'] as String,
      reportedUserId: json['reported_user_id'] as String,
      reportedBy: json['reported_by'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: ReportedUserStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ReportedUserStatus.pending,
      ),
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reported_user_id': reportedUserId,
      'reported_by': reportedBy,
      'reason': reason,
      'description': description,
      'status': status.name,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReportedUsers copyWith({
    String? id,
    String? reportedUserId,
    String? reportedBy,
    String? reason,
    String? description,
    ReportedUserStatus? status,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReportedUsers(
      id: id ?? this.id,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reportedBy: reportedBy ?? this.reportedBy,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      status: status ?? this.status,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        reportedUserId,
        reportedBy,
        reason,
        description,
        status,
        resolvedBy,
        resolvedAt,
        createdAt,
        updatedAt,
      ];
}
