import 'package:equatable/equatable.dart';

enum SecuritySeverity { low, medium, high, critical }

class SecurityEvents extends Equatable {
  final String id;
  final String? userId;
  final String eventType;
  final SecuritySeverity severity;
  final String? ipAddress;
  final String? userAgent;
  final String? description;
  final Map<String, dynamic>? metadata;
  final bool resolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  const SecurityEvents({
    required this.id,
    this.userId,
    required this.eventType,
    this.severity = SecuritySeverity.medium,
    this.ipAddress,
    this.userAgent,
    this.description,
    this.metadata,
    this.resolved = false,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
  });

  factory SecurityEvents.fromJson(Map<String, dynamic> json) {
    return SecurityEvents(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      eventType: json['event_type'] as String,
      severity: SecuritySeverity.values.firstWhere(
        (severity) => severity.name == json['severity'],
        orElse: () => SecuritySeverity.medium,
      ),
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      resolved: json['resolved'] ?? false,
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_type': eventType,
      'severity': severity.name,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'description': description,
      'metadata': metadata,
      'resolved': resolved,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  SecurityEvents copyWith({
    String? id,
    String? userId,
    String? eventType,
    SecuritySeverity? severity,
    String? ipAddress,
    String? userAgent,
    String? description,
    Map<String, dynamic>? metadata,
    bool? resolved,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) {
    return SecurityEvents(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventType: eventType ?? this.eventType,
      severity: severity ?? this.severity,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      resolved: resolved ?? this.resolved,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        eventType,
        severity,
        ipAddress,
        userAgent,
        description,
        metadata,
        resolved,
        resolvedBy,
        resolvedAt,
        createdAt,
      ];
}
