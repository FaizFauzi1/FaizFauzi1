import 'package:equatable/equatable.dart';

class VendorDocuments extends Equatable {
  final String id;
  final String vendorId;
  final String documentType;
  final String documentUrl;
  final String documentName;
  final String status;
  final DateTime? uploadedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorDocuments({
    required this.id,
    required this.vendorId,
    required this.documentType,
    required this.documentUrl,
    required this.documentName,
    this.status = 'pending',
    this.uploadedAt,
    this.reviewedAt,
    this.reviewedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorDocuments.fromJson(Map<String, dynamic> json) {
    return VendorDocuments(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      documentType: json['document_type'] as String,
      documentUrl: json['document_url'] as String,
      documentName: json['document_name'] as String,
      status: json['status'] ?? 'pending',
      uploadedAt: json['uploaded_at'] != null ? DateTime.parse(json['uploaded_at']) : null,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      reviewedBy: json['reviewed_by'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'document_type': documentType,
      'document_url': documentUrl,
      'document_name': documentName,
      'status': status,
      'uploaded_at': uploadedAt?.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VendorDocuments copyWith({
    String? id,
    String? vendorId,
    String? documentType,
    String? documentUrl,
    String? documentName,
    String? status,
    DateTime? uploadedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorDocuments(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      documentType: documentType ?? this.documentType,
      documentUrl: documentUrl ?? this.documentUrl,
      documentName: documentName ?? this.documentName,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        documentType,
        documentUrl,
        documentName,
        status,
        uploadedAt,
        reviewedAt,
        reviewedBy,
        createdAt,
        updatedAt,
      ];
}
