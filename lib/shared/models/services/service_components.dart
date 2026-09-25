import 'service_enums.dart';

/// Represents a variation group for services (e.g., Size, Color, Theme)
class VariationGroup {
  final String id;
  final String name;
  final List<VariationOption> options;
  final bool required;
  final bool affectsPricing;

  const VariationGroup({
    required this.id,
    required this.name,
    required this.options,
    this.required = false,
    this.affectsPricing = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'options': options.map((o) => o.toJson()).toList(),
        'required': required,
        'affectsPricing': affectsPricing,
      };

  factory VariationGroup.fromJson(Map<String, dynamic> json) => VariationGroup(
        id: json['id'],
        name: json['name'],
        options: (json['options'] as List).map((o) => VariationOption.fromJson(o)).toList(),
        required: json['required'] ?? false,
        affectsPricing: json['affectsPricing'] ?? false,
      );
}

/// Represents an option within a variation group
class VariationOption {
  final String id;
  final String name;
  final double? priceAdjustment;
  final int? stock;
  final bool available;

  const VariationOption({
    required this.id,
    required this.name,
    this.priceAdjustment,
    this.stock,
    this.available = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'priceAdjustment': priceAdjustment,
        'stock': stock,
        'available': available,
      };

  factory VariationOption.fromJson(Map<String, dynamic> json) => VariationOption(
        id: json['id'],
        name: json['name'],
        priceAdjustment: json['priceAdjustment']?.toDouble(),
        stock: json['stock'],
        available: json['available'] ?? true,
      );
}

/// Represents an optional addon for services
class Addon {
  final String id;
  final String name;
  final String description;
  final double price;
  final bool required;
  final int? maxQuantity;
  final List<String>? compatibleServices; // IDs of services this can be bundled with

  const Addon({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.required = false,
    this.maxQuantity,
    this.compatibleServices,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'required': required,
        'maxQuantity': maxQuantity,
        'compatibleServices': compatibleServices,
      };

  factory Addon.fromJson(Map<String, dynamic> json) => Addon(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        price: json['price'].toDouble(),
        required: json['required'] ?? false,
        maxQuantity: json['maxQuantity'],
        compatibleServices: json['compatibleServices']?.cast<String>(),
      );
}

/// Represents included items/components in a service
class IncludedItem {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final bool customizable;

  const IncludedItem({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    this.customizable = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'quantity': quantity,
        'customizable': customizable,
      };

  factory IncludedItem.fromJson(Map<String, dynamic> json) => IncludedItem(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        quantity: json['quantity'],
        customizable: json['customizable'] ?? false,
      );
}

/// Represents a promotion/discount
class Promotion {
  final String id;
  final String name;
  final DiscountType type;
  final double value;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? code;
  final bool featured;
  final bool autoExpire;
  final int? maxRedemptions;
  final int currentRedemptions;

  const Promotion({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.startDate,
    this.endDate,
    this.code,
    this.featured = false,
    this.autoExpire = true,
    this.maxRedemptions,
    this.currentRedemptions = 0,
  });

  bool get isActive {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    if (maxRedemptions != null && currentRedemptions >= maxRedemptions!) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'value': value,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'code': code,
        'featured': featured,
        'autoExpire': autoExpire,
        'maxRedemptions': maxRedemptions,
        'currentRedemptions': currentRedemptions,
      };

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
        id: json['id'],
        name: json['name'],
        type: DiscountType.values.firstWhere((e) => e.name == json['type']),
        value: json['value'].toDouble(),
        startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
        code: json['code'],
        featured: json['featured'] ?? false,
        autoExpire: json['autoExpire'] ?? true,
        maxRedemptions: json['maxRedemptions'],
        currentRedemptions: json['currentRedemptions'] ?? 0,
      );
}

/// Represents analytics/tracking data
class ServiceAnalytics {
  final int totalViews;
  final int totalOrders;
  final int totalBookings;
  final double conversionRate;
  final double averageRating;
  final int reviewCount;
  final int freeClaimCount;
  final int promotionRedemptionCount;
  final Map<String, int> viewsByPeriod; // e.g., {'daily': 10, 'weekly': 70}
  final Map<String, int> ordersByPeriod;

  const ServiceAnalytics({
    this.totalViews = 0,
    this.totalOrders = 0,
    this.totalBookings = 0,
    this.conversionRate = 0.0,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.freeClaimCount = 0,
    this.promotionRedemptionCount = 0,
    this.viewsByPeriod = const {},
    this.ordersByPeriod = const {},
  });

  Map<String, dynamic> toJson() => {
        'totalViews': totalViews,
        'totalOrders': totalOrders,
        'totalBookings': totalBookings,
        'conversionRate': conversionRate,
        'averageRating': averageRating,
        'reviewCount': reviewCount,
        'freeClaimCount': freeClaimCount,
        'promotionRedemptionCount': promotionRedemptionCount,
        'viewsByPeriod': viewsByPeriod,
        'ordersByPeriod': ordersByPeriod,
      };

  factory ServiceAnalytics.fromJson(Map<String, dynamic> json) => ServiceAnalytics(
        totalViews: json['totalViews'] ?? 0,
        totalOrders: json['totalOrders'] ?? 0,
        totalBookings: json['totalBookings'] ?? 0,
        conversionRate: json['conversionRate']?.toDouble() ?? 0.0,
        averageRating: json['averageRating']?.toDouble() ?? 0.0,
        reviewCount: json['reviewCount'] ?? 0,
        freeClaimCount: json['freeClaimCount'] ?? 0,
        promotionRedemptionCount: json['promotionRedemptionCount'] ?? 0,
        viewsByPeriod: Map<String, int>.from(json['viewsByPeriod'] ?? {}),
        ordersByPeriod: Map<String, int>.from(json['ordersByPeriod'] ?? {}),
      );
}
