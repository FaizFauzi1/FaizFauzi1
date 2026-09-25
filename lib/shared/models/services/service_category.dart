import 'package:flutter/material.dart';

// Category Type Enum
enum CategoryType {
  service('service', 'Service'),
  product('product', 'Product'),
  package('package', 'Package'),
  rental('rental', 'Rental');

  const CategoryType(this.value, this.displayName);
  final String value;
  final String displayName;

  static CategoryType fromString(String value) {
    return CategoryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CategoryType.service,
    );
  }
}

// Pricing Model Enum
enum PricingModel {
  perPax('per_pax', 'Per Person', 'pax'),
  perDay('per_day', 'Per Day', 'day'),
  perSession('per_session', 'Per Session', 'session'),
  fixed('fixed', 'Fixed Price', 'fixed'),
  perHour('per_hour', 'Per Hour', 'hour'),
  perTrip('per_trip', 'Per Trip', 'trip');

  const PricingModel(this.value, this.displayName, this.unit);
  final String value;
  final String displayName;
  final String unit;

  static PricingModel fromString(String value) {
    return PricingModel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PricingModel.fixed,
    );
  }

  String formatPrice(double price, {int? quantity}) {
    if (quantity != null && quantity > 0) {
      final total = price * quantity;
      return 'RM ${total.toStringAsFixed(2)} ($quantity $unit)';
    }
    return 'RM ${price.toStringAsFixed(2)}/$unit';
  }
}

// Vendor Tier Enum
enum VendorTier {
  basic('basic', 'Basic'),
  verified('verified', 'Verified'),
  premium('premium', 'Premium');

  const VendorTier(this.value, this.displayName);
  final String value;
  final String displayName;

  static VendorTier fromString(String value) {
    return VendorTier.values.firstWhere(
      (e) => e.value == value,
      orElse: () => VendorTier.basic,
    );
  }
}

class ServiceCategory {
  final String id;
  final String name;
  final String slug;
  final String description;
  final CategoryType categoryType;
  final PricingModel pricingModel;
  final bool isActive;
  final bool isAdvanced;
  final bool requiresVerification;
  final VendorTier minVendorTier;
  final IconData icon;
  final Color color;
  final int displayOrder;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.categoryType,
    required this.pricingModel,
    this.isActive = true,
    this.isAdvanced = false,
    this.requiresVerification = false,
    this.minVendorTier = VendorTier.basic,
    required this.icon,
    required this.color,
    this.displayOrder = 0,
    this.metadata = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ServiceCategory.fromMap(Map<String, dynamic> map) {
    try {
      return ServiceCategory(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        slug: map['slug'] ?? '',
        description: map['description'] ?? '',
        categoryType: CategoryType.fromString(map['category_type'] ?? 'service'),
        pricingModel: PricingModel.fromString(map['pricing_model'] ?? 'fixed'),
        isActive: map['is_active'] ?? true,
        isAdvanced: map['is_advanced'] ?? false,
        requiresVerification: map['requires_verification'] ?? false,
        minVendorTier: VendorTier.fromString(map['min_vendor_tier'] ?? 'basic'),
        icon: _parseIcon(map),
        color: _parseColor(map),
        displayOrder: map['display_order'] ?? 0,
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
        createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      print('Error parsing ServiceCategory fromMap: $e');
      return ServiceCategory(
        id: map['id'] ?? '',
        name: map['name'] ?? 'Error',
        slug: map['slug'] ?? 'error',
        description: '',
        categoryType: CategoryType.service,
        pricingModel: PricingModel.fixed,
        icon: Icons.error,
        color: Colors.red,
      );
    }
  }

  static IconData _parseIcon(Map<String, dynamic> map) {
    final iconCode = map['icon_code'];
    if (iconCode != null && iconCode is int) {
      // Use const IconData for tree-shaking compatibility
      return const IconData(0xe0c8, fontFamily: 'MaterialIcons'); // Icons.category fallback
    }
    
    // Fallback to icon name mapping
    final iconName = map['icon_name']?.toString().toLowerCase() ?? 'category';
    return _getIconFromName(iconName);
  }

  static Color _parseColor(Map<String, dynamic> map) {
    final colorHex = map['color_hex']?.toString();
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } catch (e) {
        return Colors.blue;
      }
    }
    return Colors.blue;
  }

  static IconData _getIconFromName(String name) {
    final iconMap = {
      'location_on': Icons.location_on,
      'restaurant': Icons.restaurant,
      'camera_alt': Icons.camera_alt,
      'videocam': Icons.videocam,
      'live_tv': Icons.live_tv,
      'mic': Icons.mic,
      'speaker': Icons.speaker,
      'lightbulb': Icons.lightbulb,
      'tv': Icons.tv,
      'celebration': Icons.celebration,
      'local_florist': Icons.local_florist,
      'directions_car': Icons.directions_car,
      'security': Icons.security,
      'event': Icons.event,
      'card_giftcard': Icons.card_giftcard,
      'checkroom': Icons.checkroom,
      'face': Icons.face,
      'brush': Icons.brush,
      'cake': Icons.cake,
      'music_note': Icons.music_note,
      'business': Icons.business,
      'school': Icons.school,
      'store': Icons.store,
      'sports': Icons.sports,
      'mosque': Icons.mosque,
      'category': Icons.category,
    };
    return iconMap[name] ?? Icons.category;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'category_type': categoryType.value,
      'pricing_model': pricingModel.value,
      'is_active': isActive,
      'is_advanced': isAdvanced,
      'requires_verification': requiresVerification,
      'min_vendor_tier': minVendorTier.value,
      'icon_code': icon.codePoint,
      'icon_name': _getIconName(icon),
      'color_hex': '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
      'display_order': displayOrder,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String _getIconName(IconData icon) {
    // Reverse lookup for icon name
    if (icon == Icons.location_on) return 'location_on';
    if (icon == Icons.restaurant) return 'restaurant';
    if (icon == Icons.camera_alt) return 'camera_alt';
    if (icon == Icons.videocam) return 'videocam';
    if (icon == Icons.celebration) return 'celebration';
    return 'category';
  }

  ServiceCategory copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    CategoryType? categoryType,
    PricingModel? pricingModel,
    bool? isActive,
    bool? isAdvanced,
    bool? requiresVerification,
    VendorTier? minVendorTier,
    IconData? icon,
    Color? color,
    int? displayOrder,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      categoryType: categoryType ?? this.categoryType,
      pricingModel: pricingModel ?? this.pricingModel,
      isActive: isActive ?? this.isActive,
      isAdvanced: isAdvanced ?? this.isAdvanced,
      requiresVerification: requiresVerification ?? this.requiresVerification,
      minVendorTier: minVendorTier ?? this.minVendorTier,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      displayOrder: displayOrder ?? this.displayOrder,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if vendor can access this category
  bool canVendorAccess({
    required bool isVerified,
    required VendorTier vendorTier,
    String? verificationStatus,
  }) {
    if (!isActive) return false;

    if (isAdvanced && !isVerified) return false;

    if (requiresVerification && verificationStatus != 'approved') {
      return false;
    }

    // Check tier requirement
    final tierLevel = {
      VendorTier.basic: 0,
      VendorTier.verified: 1,
      VendorTier.premium: 2,
    };

    return (tierLevel[vendorTier] ?? 0) >= (tierLevel[minVendorTier] ?? 0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ServiceCategory(id: $id, name: $name, type: ${categoryType.displayName}, pricing: ${pricingModel.displayName})';
  }
}