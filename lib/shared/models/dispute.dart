import 'package:equatable/equatable.dart';

enum DisputeStatus { open, investigating, resolved, closed }
enum DisputePriority { low, medium, high, urgent }

class Dispute extends Equatable {
  final String id;
  final String bookingId;
  final String initiatorId;
  final String respondentId;
  final String title;
  final String description;
  final DisputeStatus status;
  final DisputePriority priority;
  final String? resolution;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final List<String> evidenceUrls;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Dispute({
    required this.id,
    required this.bookingId,
    required this.initiatorId,
    required this.respondentId,
    required this.title,
    required this.description,
    this.status = DisputeStatus.open,
    this.priority = DisputePriority.medium,
    this.resolution,
    this.resolvedBy,
    this.resolvedAt,
    required this.evidenceUrls,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) {
    return Dispute(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      initiatorId: json['initiator_id'] as String,
      respondentId: json['respondent_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: DisputeStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => DisputeStatus.open,
      ),
      priority: DisputePriority.values.firstWhere(
        (priority) => priority.name == json['priority'],
        orElse: () => DisputePriority.medium,
      ),
      resolution: json['resolution'] as String?,
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      evidenceUrls: List<String>.from(json['evidence_urls'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'initiator_id': initiatorId,
      'respondent_id': respondentId,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'resolution': resolution,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'evidence_urls': evidenceUrls,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Dispute copyWith({
    String? id,
    String? bookingId,
    String? initiatorId,
    String? respondentId,
    String? title,
    String? description,
    DisputeStatus? status,
    DisputePriority? priority,
    String? resolution,
    String? resolvedBy,
    DateTime? resolvedAt,
    List<String>? evidenceUrls,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Dispute(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      initiatorId: initiatorId ?? this.initiatorId,
      respondentId: respondentId ?? this.respondentId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      resolution: resolution ?? this.resolution,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      evidenceUrls: evidenceUrls ?? this.evidenceUrls,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        initiatorId,
        respondentId,
        title,
        description,
        status,
        priority,
        resolution,
        resolvedBy,
        resolvedAt,
        evidenceUrls,
        metadata,
        createdAt,
        updatedAt,
      ];
}
