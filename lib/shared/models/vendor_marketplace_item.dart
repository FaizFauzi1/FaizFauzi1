import 'package:equatable/equatable.dart';

enum MarketplaceItemType {
  service,
  product,
  package,
  promotion,
}

enum MarketplaceItemStatus {
  active,
  inactive,
  pending,
  soldOut,
  expired,
}

class VendorMarketplaceItem extends Equatable {
  final String id;
  final String vendorId;
  final String vendorName;
  final MarketplaceItemType type;
  final String title;
  final String description;
  final double price;
  final String? discountedPrice;
  final List<String> images;
  final MarketplaceItemStatus status;
  final Map<String, dynamic> specifications; // Additional details based on type
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int viewCount;
  final int inquiryCount;
  final bool featured;
  final String? location; // For location-based services

  const VendorMarketplaceItem({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.type,
    required this.title,
    required this.description,
    required this.price,
    this.discountedPrice,
    required this.images,
    this.status = MarketplaceItemStatus.active,
    this.specifications = const {},
    this.tags = const [],
    required this.createdAt,
    this.expiresAt,
    this.viewCount = 0,
    this.inquiryCount = 0,
    this.featured = false,
    this.location,
  });

  // Copy with method
  VendorMarketplaceItem copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    MarketplaceItemType? type,
    String? title,
    String? description,
    double? price,
    String? discountedPrice,
    List<String>? images,
    MarketplaceItemStatus? status,
    Map<String, dynamic>? specifications,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? viewCount,
    int? inquiryCount,
    bool? featured,
    String? location,
  }) {
    return VendorMarketplaceItem(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      images: images ?? this.images,
      status: status ?? this.status,
      specifications: specifications ?? this.specifications,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewCount: viewCount ?? this.viewCount,
      inquiryCount: inquiryCount ?? this.inquiryCount,
      featured: featured ?? this.featured,
      location: location ?? this.location,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'price': price,
      'discountedPrice': discountedPrice,
      'images': images,
      'status': status.toString().split('.').last,
      'specifications': specifications,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'viewCount': viewCount,
      'inquiryCount': inquiryCount,
      'featured': featured,
      'location': location,
    };
  }

  factory VendorMarketplaceItem.fromJson(Map<String, dynamic> json) {
    return VendorMarketplaceItem(
      id: json['id'],
      vendorId: json['vendorId'],
      vendorName: json['vendorName'],
      type: MarketplaceItemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      title: json['title'],
      description: json['description'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discountedPrice: json['discountedPrice']?.toString(),
      images: List<String>.from(json['images'] ?? []),
      status: MarketplaceItemStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MarketplaceItemStatus.pending,
      ),
      specifications: Map<String, dynamic>.from(json['specifications'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      inquiryCount: (json['inquiryCount'] as num?)?.toInt() ?? 0,
      featured: json['featured'] ?? false,
      location: json['location'],
    );
  }

  // Helper methods
  bool get isActive => status == MarketplaceItemStatus.active;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get hasDiscount => discountedPrice != null;
  double get currentPrice => hasDiscount ? double.parse(discountedPrice!) : price;
  double get discountPercentage => hasDiscount ? ((price - currentPrice) / price) * 100 : 0;

  String get typeDisplayName {
    switch (type) {
      case MarketplaceItemType.service:
        return 'Service';
      case MarketplaceItemType.product:
        return 'Product';
      case MarketplaceItemType.package:
        return 'Package';
      case MarketplaceItemType.promotion:
        return 'Promotion';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case MarketplaceItemStatus.active:
        return 'Active';
      case MarketplaceItemStatus.inactive:
        return 'Inactive';
      case MarketplaceItemStatus.pending:
        return 'Pending Review';
      case MarketplaceItemStatus.soldOut:
        return 'Sold Out';
      case MarketplaceItemStatus.expired:
        return 'Expired';
    }
  }

  @override
  List<Object?> get props => [
    id,
    vendorId,
    vendorName,
    type,
    title,
    description,
    price,
    discountedPrice,
    images,
    status,
    specifications,
    tags,
    createdAt,
    expiresAt,
    viewCount,
    inquiryCount,
    featured,
    location,
  ];
}
