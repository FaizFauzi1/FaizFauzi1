import 'package:equatable/equatable.dart';

enum PortfolioItemType { image, video, document }

class VendorPortfolio extends Equatable {
  final String id;
  final String vendorId;
  final PortfolioItemType itemType;
  final String title;
  final String? description;
  final String fileUrl;
  final String? thumbnailUrl;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorPortfolio({
    required this.id,
    required this.vendorId,
    required this.itemType,
    required this.title,
    this.description,
    required this.fileUrl,
    this.thumbnailUrl,
    this.displayOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorPortfolio.fromJson(Map<String, dynamic> json) {
    return VendorPortfolio(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      itemType: PortfolioItemType.values.firstWhere(
        (type) => type.name == json['item_type'],
        orElse: () => PortfolioItemType.image,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      displayOrder: json['display_order'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'item_type': itemType.name,
      'title': title,
      'description': description,
      'file_url': fileUrl,
      'thumbnail_url': thumbnailUrl,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VendorPortfolio copyWith({
    String? id,
    String? vendorId,
    PortfolioItemType? itemType,
    String? title,
    String? description,
    String? fileUrl,
    String? thumbnailUrl,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorPortfolio(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      itemType: itemType ?? this.itemType,
      title: title ?? this.title,
      description: description ?? this.description,
      fileUrl: fileUrl ?? this.fileUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        itemType,
        title,
        description,
        fileUrl,
        thumbnailUrl,
        displayOrder,
        isActive,
        createdAt,
        updatedAt,
      ];
}
