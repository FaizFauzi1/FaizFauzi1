import 'package:equatable/equatable.dart';

class Documents extends Equatable {
  final String id;
  final String userId;
  final String fileName;
  final String filePath;
  final int? fileSize;
  final String? mimeType;
  final DateTime uploadedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Documents({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.filePath,
    this.fileSize,
    this.mimeType,
    required this.uploadedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Documents.fromJson(Map<String, dynamic> json) {
    return Documents(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileSize: json['file_size'] as int?,
      mimeType: json['mime_type'] as String?,
      uploadedAt: DateTime.parse(json['uploaded_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'mime_type': mimeType,
      'uploaded_at': uploadedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Documents copyWith({
    String? id,
    String? userId,
    String? fileName,
    String? filePath,
    int? fileSize,
    String? mimeType,
    DateTime? uploadedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Documents(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        fileName,
        filePath,
        fileSize,
        mimeType,
        uploadedAt,
        createdAt,
        updatedAt,
      ];
}
