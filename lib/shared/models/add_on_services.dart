import 'package:equatable/equatable.dart';

class AddOnService extends Equatable {
  final String id;
  final String vendorId;
  final String? serviceId;
  final String name;
  final String? description;
  final double price;
  final String category;
  final bool isActive;
  final int? maxQuantity;
  final List<String> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AddOnService({
    required this.id,
    required this.vendorId,
    this.serviceId,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    this.isActive = true,
    this.maxQuantity,
    this.images = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory AddOnService.fromJson(Map<String, dynamic> json) {
    return AddOnService(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      serviceId: json['service_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      isActive: json['is_active'] ?? true,
      maxQuantity: json['max_quantity'] as int?,
      images: List<String>.from(json['images'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'service_id': serviceId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'is_active': isActive,
      'max_quantity': maxQuantity,
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AddOnService copyWith({
    String? id,
    String? vendorId,
    String? serviceId,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isActive,
    int? maxQuantity,
    List<String>? images,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AddOnService(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        serviceId,
        name,
        description,
        price,
        category,
        isActive,
        maxQuantity,
        images,
        createdAt,
        updatedAt,
      ];
}
