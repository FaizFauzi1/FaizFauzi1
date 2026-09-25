import 'package:equatable/equatable.dart';

class VendorUser extends Equatable {
  final String id;
  final String userId;
  final String vendorProfileId;
  final String role;
  final bool isPrimary;
  final Map<String, dynamic> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorUser({
    required this.id,
    required this.userId,
    required this.vendorProfileId,
    required this.role,
    this.isPrimary = false,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorUser.fromJson(Map<String, dynamic> json) {
    return VendorUser(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vendorProfileId: json['vendor_profile_id'] as String,
      role: json['role'] as String,
      isPrimary: json['is_primary'] ?? false,
      permissions: Map<String, dynamic>.from(json['permissions'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vendor_profile_id': vendorProfileId,
      'role': role,
      'is_primary': isPrimary,
      'permissions': permissions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VendorUser copyWith({
    String? id,
    String? userId,
    String? vendorProfileId,
    String? role,
    bool? isPrimary,
    Map<String, dynamic>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorUser(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vendorProfileId: vendorProfileId ?? this.vendorProfileId,
      role: role ?? this.role,
      isPrimary: isPrimary ?? this.isPrimary,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        vendorProfileId,
        role,
        isPrimary,
        permissions,
        createdAt,
        updatedAt,
      ];
}
