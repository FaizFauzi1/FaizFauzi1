import 'package:equatable/equatable.dart';

class ServicePackageItem extends Equatable {
  final String id;
  final String packageId;
  final String name;
  final String description;
  final int quantity;
  final List<String> galleryUrls;
  final String? pdfUrl;
  final String? optionalServiceId;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServicePackageItem({
    required this.id,
    required this.packageId,
    required this.name,
    required this.description,
    this.quantity = 1,
    this.galleryUrls = const [],
    this.pdfUrl,
    this.optionalServiceId,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServicePackageItem.fromJson(Map<String, dynamic> json) {
    return ServicePackageItem(
      id: json['id'] as String,
      packageId: json['package_id'] as String,
      name: json['name'] as String,
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 1,
      galleryUrls: List<String>.from(json['gallery_urls'] ?? []),
      pdfUrl: json['pdf_url'],
      optionalServiceId: json['optional_service_id'],
      displayOrder: json['display_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'package_id': packageId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'gallery_urls': galleryUrls,
      'pdf_url': pdfUrl,
      'optional_service_id': optionalServiceId,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ServicePackageItem copyWith({
    String? id,
    String? packageId,
    String? name,
    String? description,
    int? quantity,
    List<String>? galleryUrls,
    String? pdfUrl,
    String? optionalServiceId,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServicePackageItem(
      id: id ?? this.id,
      packageId: packageId ?? this.packageId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      optionalServiceId: optionalServiceId ?? this.optionalServiceId,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        packageId,
        name,
        description,
        quantity,
        galleryUrls,
        pdfUrl,
        optionalServiceId,
        displayOrder,
        createdAt,
        updatedAt,
      ];
}
