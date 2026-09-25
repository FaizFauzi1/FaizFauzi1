import 'package:equatable/equatable.dart';

class AdminVendorDocuments extends Equatable {
  final String id;
  final String adminVendorId;
  final String documentType;
  final String documentUrl;
  final String documentName;
  final DateTime uploadedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdminVendorDocuments({
    required this.id,
    required this.adminVendorId,
    required this.documentType,
    required this.documentUrl,
    required this.documentName,
    required this.uploadedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminVendorDocuments.fromJson(Map<String, dynamic> json) {
    return AdminVendorDocuments(
      id: json['id'] as String,
      adminVendorId: json['admin_vendor_id'] as String,
      documentType: json['document_type'] as String,
      documentUrl: json['document_url'] as String,
      documentName: json['document_name'] as String,
      uploadedAt: DateTime.parse(json['uploaded_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admin_vendor_id': adminVendorId,
      'document_type': documentType,
      'document_url': documentUrl,
      'document_name': documentName,
      'uploaded_at': uploadedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AdminVendorDocuments copyWith({
    String? id,
    String? adminVendorId,
    String? documentType,
    String? documentUrl,
    String? documentName,
    DateTime? uploadedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminVendorDocuments(
      id: id ?? this.id,
      adminVendorId: adminVendorId ?? this.adminVendorId,
      documentType: documentType ?? this.documentType,
      documentUrl: documentUrl ?? this.documentUrl,
      documentName: documentName ?? this.documentName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        adminVendorId,
        documentType,
        documentUrl,
        documentName,
        uploadedAt,
        createdAt,
        updatedAt,
      ];
}
