enum MarketplaceItemStatus {
  active,
  inactive,
  pending,
  soldOut,
  expired,
}

enum MarketplaceItemType {
  service,
  product,
  rental,
  package,
  promotion,
}

class VendorMarketplaceItem {
  final String id;
  final String vendorId;
  final String vendorName;
  final String title;
  final String description;
  final MarketplaceItemType type;
  final MarketplaceItemStatus status;
  final List<String> images;
  final double price;
  final double? discountPrice;
  final bool featured;
  final int viewCount;
  final int inquiryCount;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  VendorMarketplaceItem({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.images = const [],
    required this.price,
    this.discountPrice,
    this.featured = false,
    this.viewCount = 0,
    this.inquiryCount = 0,
    this.location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  String get statusDisplayName {
    switch (status) {
      case MarketplaceItemStatus.active:
        return 'Active';
      case MarketplaceItemStatus.inactive:
        return 'Inactive';
      case MarketplaceItemStatus.pending:
        return 'Pending';
      case MarketplaceItemStatus.soldOut:
        return 'Sold Out';
      case MarketplaceItemStatus.expired:
        return 'Expired';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case MarketplaceItemType.service:
        return 'Service';
      case MarketplaceItemType.product:
        return 'Product';
      case MarketplaceItemType.rental:
        return 'Rental';
      case MarketplaceItemType.package:
        return 'Package';
      case MarketplaceItemType.promotion:
        return 'Promotion';
    }
  }

  double get currentPrice => discountPrice ?? price;

  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  // Sample data for testing
  static List<VendorMarketplaceItem> getSampleItems() {
    return [
      VendorMarketplaceItem(
        id: '1',
        vendorId: 'vendor1',
        vendorName: 'ABC Photography',
        title: 'Wedding Photography Package',
        description: 'Complete wedding photography package including pre-wedding shoot, ceremony, and reception coverage.',
        type: MarketplaceItemType.service,
        status: MarketplaceItemStatus.active,
        images: ['https://via.placeholder.com/300x200'],
        price: 2500.0,
        discountPrice: 2000.0,
        featured: true,
        viewCount: 150,
        inquiryCount: 12,
        location: 'Kuala Lumpur',
      ),
      VendorMarketplaceItem(
        id: '2',
        vendorId: 'vendor2',
        vendorName: 'Elegant Catering',
        title: 'Buffet Catering for 50 People',
        description: 'Delicious buffet catering with variety of dishes for corporate events and celebrations.',
        type: MarketplaceItemType.service,
        status: MarketplaceItemStatus.active,
        images: ['https://via.placeholder.com/300x200'],
        price: 150.0,
        viewCount: 89,
        inquiryCount: 8,
        location: 'Petaling Jaya',
      ),
      VendorMarketplaceItem(
        id: '3',
        vendorId: 'vendor3',
        vendorName: 'Venue Masters',
        title: 'Grand Ballroom Rental',
        description: 'Spacious ballroom perfect for weddings, corporate events, and large gatherings.',
        type: MarketplaceItemType.rental,
        status: MarketplaceItemStatus.pending,
        images: ['https://via.placeholder.com/300x200'],
        price: 5000.0,
        discountPrice: 4500.0,
        viewCount: 200,
        inquiryCount: 15,
        location: 'Shah Alam',
      ),
    ];
  }
}