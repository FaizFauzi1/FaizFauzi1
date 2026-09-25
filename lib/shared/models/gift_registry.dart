class GiftRegistryItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final bool isPurchased;
  final String? purchasedBy;
  final DateTime? purchasedAt;
  final int quantity;
  final int remainingQuantity;

  const GiftRegistryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    required this.isPurchased,
    this.purchasedBy,
    this.purchasedAt,
    required this.quantity,
    required this.remainingQuantity,
  });

  GiftRegistryItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    bool? isPurchased,
    String? purchasedBy,
    DateTime? purchasedAt,
    int? quantity,
    int? remainingQuantity,
  }) {
    return GiftRegistryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isPurchased: isPurchased ?? this.isPurchased,
      purchasedBy: purchasedBy ?? this.purchasedBy,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      quantity: quantity ?? this.quantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isPurchased': isPurchased,
      'purchasedBy': purchasedBy,
      'purchasedAt': purchasedAt?.toIso8601String(),
      'quantity': quantity,
      'remainingQuantity': remainingQuantity,
    };
  }

  factory GiftRegistryItem.fromJson(Map<String, dynamic> json) {
    return GiftRegistryItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'] ?? 0.0,
      imageUrl: json['imageUrl'],
      category: json['category'],
      isPurchased: json['isPurchased'] ?? false,
      purchasedBy: json['purchasedBy'],
      purchasedAt: json['purchasedAt'] != null ? DateTime.parse(json['purchasedAt']) : null,
      quantity: json['quantity'] ?? 1,
      remainingQuantity: json['remainingQuantity'] ?? 1,
    );
  }
  // Supabase for GiftRegistryItem
  factory GiftRegistryItem.fromSupabase(Map<String, dynamic> json) {
    return GiftRegistryItem(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'],
      category: json['category'],
      isPurchased: json['is_purchased'] ?? false,
      purchasedBy: json['purchased_by'],
      purchasedAt: json['purchased_at'] != null ? DateTime.parse(json['purchased_at']) : null,
      quantity: json['quantity'] ?? 1,
      remainingQuantity: json['remaining_quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toSupabaseJson(String registryId) {
    return {
      'id': id,
      'registry_id': registryId, // Passed from parent
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'is_purchased': isPurchased,
      'purchased_by': purchasedBy,
      'purchased_at': purchasedAt?.toIso8601String(),
      'quantity': quantity,
      'remaining_quantity': remainingQuantity,
    };
  }
}

class GiftRegistry {
  final String id;
  final String eventId;
  final String title;
  final String description;
  final List<GiftRegistryItem> items;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GiftRegistry({
    required this.id,
    required this.eventId,
    required this.title,
    required this.description,
    required this.items,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  GiftRegistry copyWith({
    String? id,
    String? eventId,
    String? title,
    String? description,
    List<GiftRegistryItem>? items,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GiftRegistry(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      items: items ?? this.items,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'description': description,
      'items': items.map((item) => item.toJson()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GiftRegistry.fromJson(Map<String, dynamic> json) {
    return GiftRegistry(
      id: json['id'],
      eventId: json['eventId'],
      title: json['title'],
      description: json['description'],
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => GiftRegistryItem.fromJson(item))
          .toList() ?? [],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Supabase for GiftRegistry
  factory GiftRegistry.fromSupabase(Map<String, dynamic> json) {
    // Check if items are included in the response (snake_case table name usually)
    // The table name is 'gift_registry_items' based on the new schema
    var itemsList = json['gift_registry_items'] as List?;
    return GiftRegistry(
      id: json['id'],
      eventId: json['event_id'],
      title: json['title'],
      description: json['description'] ?? '',
      items: itemsList?.map((i) => GiftRegistryItem.fromSupabase(i)).toList() ?? [],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'event_id': eventId,
      'title': title,
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory GiftRegistry.sample() {
    return GiftRegistry(
      id: 'registry_1',
      eventId: 'event_1',
      title: 'Sarah & John\'s Wedding Registry',
      description: 'Help us start our new life together!',
      items: [
        GiftRegistryItem(
          id: 'item_1',
          name: 'Kitchen Blender',
          description: 'High-powered blender for smoothies and cooking',
          price: 299.99,
          imageUrl: 'https://via.placeholder.com/200x200?text=Blender',
          category: 'Kitchen',
          isPurchased: false,
          quantity: 1,
          remainingQuantity: 1,
        ),
        GiftRegistryItem(
          id: 'item_2',
          name: 'Coffee Maker',
          description: 'Programmable coffee maker with thermal carafe',
          price: 149.99,
          imageUrl: 'https://via.placeholder.com/200x200?text=Coffee+Maker',
          category: 'Kitchen',
          isPurchased: true,
          purchasedBy: 'Anonymous',
          purchasedAt: DateTime.now().subtract(const Duration(days: 5)),
          quantity: 1,
          remainingQuantity: 0,
        ),
      ],
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }
}
