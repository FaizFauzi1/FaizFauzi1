import 'package:equatable/equatable.dart';

class AdminRole extends Equatable {
  final String id;
  final String roleName;
  final String? description;
  final Map<String, dynamic> permissions;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminRole({
    required this.id,
    required this.roleName,
    this.description,
    this.permissions = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminRole.fromJson(Map<String, dynamic> json) {
    return AdminRole(
      id: json['id'] as String,
      roleName: json['role_name'] as String,
      description: json['description'] as String?,
      permissions: Map<String, dynamic>.from(json['permissions'] ?? {}),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_name': roleName,
      'description': description,
      'permissions': permissions,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AdminRole copyWith({
    String? id,
    String? roleName,
    String? description,
    Map<String, dynamic>? permissions,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminRole(
      id: id ?? this.id,
      roleName: roleName ?? this.roleName,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        roleName,
        description,
        permissions,
        isActive,
        createdAt,
        updatedAt,
      ];
}
