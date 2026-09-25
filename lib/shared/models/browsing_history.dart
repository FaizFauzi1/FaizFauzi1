import 'package:equatable/equatable.dart';

enum EntityType { vendor, service, product, event }

class BrowsingHistory extends Equatable {
  final String id;
  final String userId;
  final EntityType entityType;
  final String entityId;
  final int? viewDuration;
  final String? source;
  final String? deviceType;
  final DateTime createdAt;

  const BrowsingHistory({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    this.viewDuration,
    this.source,
    this.deviceType,
    required this.createdAt,
  });

  factory BrowsingHistory.fromJson(Map<String, dynamic> json) {
    return BrowsingHistory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      entityType: EntityType.values.firstWhere(
        (type) => type.name == json['entity_type'],
        orElse: () => EntityType.vendor,
      ),
      entityId: json['entity_id'] as String,
      viewDuration: json['view_duration'] as int?,
      source: json['source'] as String?,
      deviceType: json['device_type'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'entity_type': entityType.name,
      'entity_id': entityId,
      'view_duration': viewDuration,
      'source': source,
      'device_type': deviceType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BrowsingHistory copyWith({
    String? id,
    String? userId,
    EntityType? entityType,
    String? entityId,
    int? viewDuration,
    String? source,
    String? deviceType,
    DateTime? createdAt,
  }) {
    return BrowsingHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      viewDuration: viewDuration ?? this.viewDuration,
      source: source ?? this.source,
      deviceType: deviceType ?? this.deviceType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        entityType,
        entityId,
        viewDuration,
        source,
        deviceType,
        createdAt,
      ];
}
