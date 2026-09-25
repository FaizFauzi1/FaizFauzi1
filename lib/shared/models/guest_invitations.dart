import 'package:equatable/equatable.dart';

enum GuestInvitationRole { admin, vendor, customer }

enum GuestInvitationStatus { pending, accepted, expired }

class GuestInvitations extends Equatable {
  final String id;
  final String email;
  final String invitedBy;
  final GuestInvitationRole role;
  final GuestInvitationStatus status;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GuestInvitations({
    required this.id,
    required this.email,
    required this.invitedBy,
    required this.role,
    this.status = GuestInvitationStatus.pending,
    required this.expiresAt,
    this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GuestInvitations.fromJson(Map<String, dynamic> json) {
    return GuestInvitations(
      id: json['id'] as String,
      email: json['email'] as String,
      invitedBy: json['invited_by'] as String,
      role: GuestInvitationRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => GuestInvitationRole.customer,
      ),
      status: GuestInvitationStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => GuestInvitationStatus.pending,
      ),
      expiresAt: DateTime.parse(json['expires_at']),
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'invited_by': invitedBy,
      'role': role.name,
      'status': status.name,
      'expires_at': expiresAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GuestInvitations copyWith({
    String? id,
    String? email,
    String? invitedBy,
    GuestInvitationRole? role,
    GuestInvitationStatus? status,
    DateTime? expiresAt,
    DateTime? acceptedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GuestInvitations(
      id: id ?? this.id,
      email: email ?? this.email,
      invitedBy: invitedBy ?? this.invitedBy,
      role: role ?? this.role,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        invitedBy,
        role,
        status,
        expiresAt,
        acceptedAt,
        createdAt,
        updatedAt,
      ];
}
