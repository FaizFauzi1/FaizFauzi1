import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final String id;
  final String key;
  final String value;
  final String? description;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppSettings({
    required this.id,
    required this.key,
    required this.value,
    this.description,
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      id: json['id'] as String,
      key: json['key'] as String,
      value: json['value'] as String,
      description: json['description'] as String?,
      isPublic: json['is_public'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'description': description,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AppSettings copyWith({
    String? id,
    String? key,
    String? value,
    String? description,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        key,
        value,
        description,
        isPublic,
        createdAt,
        updatedAt,
      ];
}
