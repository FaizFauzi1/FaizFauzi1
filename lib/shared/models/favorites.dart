import 'package:equatable/equatable.dart';

enum FavoriteItemType { vendor, service, product }

class Favorites extends Equatable {
  final String id;
  final String userId;
  final FavoriteItemType itemType;
  final String itemId;
  final String? notes;
  final DateTime createdAt;

  const Favorites({
    required this.id,
    required this.userId,
    required this.itemType,
    required this.itemId,
    this.notes,
    required this.createdAt,
  });

  factory Favorites.fromJson(Map<String, dynamic> json) {
    return Favorites(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      itemType: FavoriteItemType.values.firstWhere(
        (type) => type.name == json['item_type'],
        orElse: () => FavoriteItemType.vendor,
      ),
      itemId: json['item_id'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'item_type': itemType.name,
      'item_id': itemId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Favorites copyWith({
    String? id,
    String? userId,
    FavoriteItemType? itemType,
    String? itemId,
    String? notes,
    DateTime? createdAt,
  }) {
    return Favorites(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        itemType,
        itemId,
        notes,
        createdAt,
      ];
}
