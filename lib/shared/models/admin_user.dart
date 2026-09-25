import 'package:equatable/equatable.dart';

enum AdminRole { superAdmin, finance, support, moderator }

class AdminUser extends Equatable {
  final String id;
  final String userId;
  final String employeeId;
  final String department;
  final AdminRole role;
  final bool isActive;
  final String? managerId;
  final Map<String, dynamic> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminUser({
    required this.id,
    required this.userId,
    required this.employeeId,
    required this.department,
    required this.role,
    this.isActive = true,
    this.managerId,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      employeeId: json['employee_id'] as String,
      department: json['department'] as String,
      role: AdminRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => AdminRole.support,
      ),
      isActive: json['is_active'] ?? true,
      managerId: json['manager_id'] as String?,
      permissions: Map<String, dynamic>.from(json['permissions'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'employee_id': employeeId,
      'department': department,
      'role': role.name,
      'is_active': isActive,
      'manager_id': managerId,
      'permissions': permissions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AdminUser copyWith({
    String? id,
    String? userId,
    String? employeeId,
    String? department,
    AdminRole? role,
    bool? isActive,
    String? managerId,
    Map<String, dynamic>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      employeeId: employeeId ?? this.employeeId,
      department: department ?? this.department,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      managerId: managerId ?? this.managerId,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        employeeId,
        department,
        role,
        isActive,
        managerId,
        permissions,
        createdAt,
        updatedAt,
      ];
}
