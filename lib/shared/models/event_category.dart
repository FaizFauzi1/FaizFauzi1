import 'package:equatable/equatable.dart';

class EventCategory extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? iconUrl;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventCategory({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl,
    this.imageUrl,
    this.isActive = true,
    this.sortOrder = 0,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['icon_url'] as String?,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_url': iconUrl,
      'image_url': imageUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EventCategory copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    String? imageUrl,
    bool? isActive,
    int? sortOrder,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconUrl,
        imageUrl,
        isActive,
        sortOrder,
        metadata,
        createdAt,
        updatedAt,
      ];
}
