import 'package:uuid/uuid.dart';

enum CollaboratorRole {
  coHost,
  planner,
  vendor,
  viewer;

  String get displayName {
    switch (this) {
      case CollaboratorRole.coHost:
        return 'Co-Host';
      case CollaboratorRole.planner:
        return 'Planner';
      case CollaboratorRole.vendor:
        return 'Vendor Coordinator';
      case CollaboratorRole.viewer:
        return 'Viewer';
    }
  }

  static CollaboratorRole fromString(String role) {
    return CollaboratorRole.values.firstWhere(
      (e) => e.name == role,
      orElse: () => CollaboratorRole.viewer,
    );
  }
}

enum CollaboratorStatus {
  pending,
  accepted,
  declined;

  String get displayName {
    switch (this) {
      case CollaboratorStatus.pending:
        return 'Pending';
      case CollaboratorStatus.accepted:
        return 'Accepted';
      case CollaboratorStatus.declined:
        return 'Declined';
    }
  }

  static CollaboratorStatus fromString(String status) {
    return CollaboratorStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => CollaboratorStatus.pending,
    );
  }
}

class EventCollaborator {
  final String id;
  final String eventId;
  final String? userId; // Null if invited by email/code but hasn't joined yet
  final String? email; // The email invited
  final CollaboratorRole role;
  final CollaboratorStatus status;
  final String? inviteCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventCollaborator({
    String? id,
    required this.eventId,
    this.userId,
    this.email,
    required this.role,
    this.status = CollaboratorStatus.pending,
    this.inviteCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  EventCollaborator copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? email,
    CollaboratorRole? role,
    CollaboratorStatus? status,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventCollaborator(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      inviteCode: inviteCode ?? this.inviteCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'email': email,
      'role': role.name,
      'status': status.name,
      'inviteCode': inviteCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EventCollaborator.fromJson(Map<String, dynamic> json) {
    return EventCollaborator(
      id: json['id'],
      eventId: json['eventId'],
      userId: json['userId'],
      email: json['email'],
      role: CollaboratorRole.fromString(json['role']),
      status: CollaboratorStatus.fromString(json['status']),
      inviteCode: json['inviteCode'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // Generate a random 6-character code
  static String generateCode() {
    final uuid = const Uuid().v4().replaceAll('-', '').substring(0, 6).toUpperCase();
    return uuid;
  }
}
