import 'package:equatable/equatable.dart';

class AdminRoleAssignment extends Equatable {
  final String id;
  final String adminUserId;
  final String roleId;
  final String assignedBy;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminRoleAssignment({
    required this.id,
    required this.adminUserId,
    required this.roleId,
    required this.assignedBy,
    this.expiresAt,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminRoleAssignment.fromJson(Map<String, dynamic> json) {
    return AdminRoleAssignment(
      id: json['id'] as String,
      adminUserId: json['admin_user_id'] as String,
      roleId: json['role_id'] as String,
      assignedBy: json['assigned_by'] as String,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_user_id': adminUserId,
      'role_id': roleId,
      'assigned_by': assignedBy,
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AdminRoleAssignment copyWith({
    String? id,
    String? adminUserId,
    String? roleId,
    String? assignedBy,
    DateTime? expiresAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminRoleAssignment(
      id: id ?? this.id,
      adminUserId: adminUserId ?? this.adminUserId,
      roleId: roleId ?? this.roleId,
      assignedBy: assignedBy ?? this.assignedBy,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        adminUserId,
        roleId,
        assignedBy,
        expiresAt,
        isActive,
        createdAt,
        updatedAt,
      ];
}
