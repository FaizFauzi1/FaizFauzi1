import 'package:equatable/equatable.dart';

class SubscriptionTiers extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int durationDays;
  final List<String> features;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubscriptionTiers({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.durationDays,
    required this.features,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionTiers.fromJson(Map<String, dynamic> json) {
    return SubscriptionTiers(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] ?? 0).toDouble(),
      durationDays: json['duration_days'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration_days': durationDays,
      'features': features,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SubscriptionTiers copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? durationDays,
    List<String>? features,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionTiers(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationDays: durationDays ?? this.durationDays,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        durationDays,
        features,
        isActive,
        createdAt,
        updatedAt,
      ];
}
