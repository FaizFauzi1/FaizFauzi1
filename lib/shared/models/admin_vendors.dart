import 'package:equatable/equatable.dart';

class AdminVendors extends Equatable {
  final String id;
  final String vendorId;
  final String adminId;
  final String status;
  final String? notes;
  final DateTime assignedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminVendors({
    required this.id,
    required this.vendorId,
    required this.adminId,
    this.status = 'active',
    this.notes,
    required this.assignedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminVendors.fromJson(Map<String, dynamic> json) {
    return AdminVendors(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      adminId: json['admin_id'] as String,
      status: json['status'] ?? 'active',
      notes: json['notes'] as String?,
      assignedAt: DateTime.parse(json['assigned_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'admin_id': adminId,
      'status': status,
      'notes': notes,
      'assigned_at': assignedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AdminVendors copyWith({
    String? id,
    String? vendorId,
    String? adminId,
    String? status,
    String? notes,
    DateTime? assignedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminVendors(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      adminId: adminId ?? this.adminId,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      assignedAt: assignedAt ?? this.assignedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        adminId,
        status,
        notes,
        assignedAt,
        createdAt,
        updatedAt,
      ];
}
