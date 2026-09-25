enum ItemCondition {
  newCondition,
  likeNew,
  used
}

enum ItemListingStatus {
  active,
  sold,
  expired,
  pendingVerification
}

class ItemListing {
  final String id;
  final String customerId;
  final String category;
  final String itemName;
  final String description;
  final ItemCondition condition;
  final int quantity;
  final String? size;
  final String? brand;
  final double price;
  final List<String> images;
  final String location;
  final String deliveryOption; // 'delivery', 'pickup', 'both'
  final ItemListingStatus listingStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemListing({
    required this.id,
    required this.customerId,
    required this.category,
    required this.itemName,
    required this.description,
    required this.condition,
    required this.quantity,
    this.size,
    this.brand,
    required this.price,
    required this.images,
    required this.location,
    required this.deliveryOption,
    required this.listingStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ItemListing.fromMap(Map<String, dynamic> map) {
    return ItemListing(
      id: map['id'] ?? '',
      customerId: map['customer_id'] ?? '',
      category: map['category'] ?? '',
      itemName: map['item_name'] ?? '',
      description: map['description'] ?? '',
      condition: _parseCondition(map['condition']),
      quantity: map['quantity'] ?? 1,
      size: map['size'],
      brand: map['brand'],
      price: (map['price'] ?? 0.0).toDouble(),
      images: map['images'] is List 
          ? List<String>.from(map['images']) 
          : [],
      location: map['location'] ?? '',
      deliveryOption: map['delivery_option'] ?? 'both',
      listingStatus: _parseListingStatus(map['listing_status']),
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now() 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id.isEmpty ? null : id,
      'customer_id': customerId,
      'category': category,
      'item_name': itemName,
      'description': description,
      'condition': condition.name == 'newCondition' ? 'new' : condition.name == 'likeNew' ? 'like_new' : 'used',
      'quantity': quantity,
      'size': size,
      'brand': brand,
      'price': price,
      'images': images,
      'location': location,
      'delivery_option': deliveryOption,
      'listing_status': listingStatus.name == 'pendingVerification' ? 'pending_verification' : listingStatus.name,
    };
  }

  static ItemCondition _parseCondition(String? condition) {
    switch (condition) {
      case 'new':
      case 'newCondition':
        return ItemCondition.newCondition;
      case 'like_new':
      case 'likeNew':
        return ItemCondition.likeNew;
      case 'used':
      default:
        return ItemCondition.used;
    }
  }

  static ItemListingStatus _parseListingStatus(String? status) {
    switch (status) {
      case 'sold':
        return ItemListingStatus.sold;
      case 'expired':
        return ItemListingStatus.expired;
      case 'pending_verification':
      case 'pendingVerification':
        return ItemListingStatus.pendingVerification;
      case 'active':
      default:
        return ItemListingStatus.active;
    }
  }
}
