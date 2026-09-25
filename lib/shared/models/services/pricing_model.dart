/// Pricing model types for vendor services
enum PricingModelType {
  perEventType('per_event_type', 'Per Event Type'),
  perPax('per_pax', 'Per Pax'),
  perHour('per_hour', 'Per Hour'),
  perDay('per_day', 'Per Day'),
  customCombination('custom_combination', 'Custom Combination');

  const PricingModelType(this.id, this.displayName);

  final String id;
  final String displayName;

  static PricingModelType fromId(String id) {
    return PricingModelType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => PricingModelType.perEventType,
    );
  }
}

/// Add-on pricing types
enum AddOnPricingType {
  fixed('fixed', 'Fixed Price'),
  perEvent('per_event', 'Per Event'),
  perPax('per_pax', 'Per Pax'),
  perCrew('per_crew', 'Per Crew'),
  perHour('per_hour', 'Per Hour'),
  conditionalByEvent('conditional_by_event', 'Conditional by Event Combination');

  const AddOnPricingType(this.id, this.displayName);

  final String id;
  final String displayName;

  static AddOnPricingType fromId(String id) {
    return AddOnPricingType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => AddOnPricingType.fixed,
    );
  }
}

/// Represents a combination of event types with associated pricing
class EventTypeCombination {
  final String id;
  final List<String> eventTypes; // e.g., ['akad', 'sanding']
  final double price;
  final String? displayName; // e.g., "Akad + Sanding"
  final String? description;

  EventTypeCombination({
    required this.id,
    required this.eventTypes,
    required this.price,
    this.displayName,
    this.description,
  });

  factory EventTypeCombination.fromJson(Map<String, dynamic> json) {
    return EventTypeCombination(
      id: json['id'] ?? '',
      eventTypes: (json['event_types'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      displayName: json['display_name'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_types': eventTypes,
      'price': price,
      'display_name': displayName,
      'description': description,
    };
  }

  /// Generate display name from event types if not provided
  String getDisplayName() {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    if (eventTypes.isEmpty) return 'No events';
    if (eventTypes.length == 1) return eventTypes.first;
    return eventTypes.join(' + ');
  }

  /// Create a unique key for this combination (sorted event types)
  String getCombinationKey() {
    final sorted = List<String>.from(eventTypes)..sort();
    return sorted.join('_');
  }
}

/// Pax-based pricing tier
class PaxTierPricing {
  final int minPax;
  final int? maxPax;
  final double pricePerPax;

  PaxTierPricing({
    required this.minPax,
    this.maxPax,
    required this.pricePerPax,
  });

  factory PaxTierPricing.fromJson(Map<String, dynamic> json) {
    return PaxTierPricing(
      minPax: json['min_pax'] ?? 0,
      maxPax: json['max_pax'],
      pricePerPax: (json['price_per_pax'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min_pax': minPax,
      'max_pax': maxPax,
      'price_per_pax': pricePerPax,
    };
  }

  /// Check if a pax count falls within this tier
  bool appliesToPax(int pax) {
    if (pax < minPax) return false;
    if (maxPax == null) return true;
    return pax <= maxPax!;
  }
}

/// Main pricing model for a service
class PricingModel {
  final PricingModelType type;
  final double? basePrice;
  final int? minPax;
  final double? pricePerPax;
  final List<PaxTierPricing>? paxTiers;
  final List<EventTypeCombination>? eventCombinations;
  final Map<String, double>? hourlyRates;
  final Map<String, double>? dailyRates;

  PricingModel({
    required this.type,
    this.basePrice,
    this.minPax,
    this.pricePerPax,
    this.paxTiers,
    this.eventCombinations,
    this.hourlyRates,
    this.dailyRates,
  });

  factory PricingModel.fromJson(Map<String, dynamic> json) {
    return PricingModel(
      type: PricingModelType.fromId(json['pricing_type'] ?? 'per_event_type'),
      basePrice: (json['base_price'] as num?)?.toDouble(),
      minPax: json['min_pax'],
      pricePerPax: (json['price_per_pax'] as num?)?.toDouble(),
      paxTiers: (json['pax_tiers'] as List?)
          ?.map((e) => PaxTierPricing.fromJson(e))
          .toList(),
      eventCombinations: (json['event_combinations'] as List?)
          ?.map((e) => EventTypeCombination.fromJson(e))
          .toList(),
      hourlyRates: (json['hourly_rates'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      ),
      dailyRates: (json['daily_rates'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pricing_type': type.id,
      'base_price': basePrice,
      'min_pax': minPax,
      'price_per_pax': pricePerPax,
      'pax_tiers': paxTiers?.map((e) => e.toJson()).toList(),
      'event_combinations': eventCombinations?.map((e) => e.toJson()).toList(),
      'hourly_rates': hourlyRates,
      'daily_rates': dailyRates,
    };
  }

  /// Find the price for a specific event combination
  double? findEventCombinationPrice(List<String> eventTypes) {
    if (eventCombinations == null) return null;

    final key = EventTypeCombination(
      id: '',
      eventTypes: eventTypes,
      price: 0,
    ).getCombinationKey();

    for (final combo in eventCombinations!) {
      if (combo.getCombinationKey() == key) {
        return combo.price;
      }
    }
    return null;
  }

  /// Find the appropriate pax tier for a given pax count
  PaxTierPricing? findPaxTier(int pax) {
    if (paxTiers == null || paxTiers!.isEmpty) return null;

    for (final tier in paxTiers!) {
      if (tier.appliesToPax(pax)) {
        return tier;
      }
    }
    return null;
  }
}

/// Service add-on with flexible pricing
class ServiceAddOn {
  final String id;
  final String serviceId;
  final String name;
  final String? description;
  final AddOnPricingType pricingType;
  final double? fixedPrice;
  final Map<String, double>? priceByEventCombination;
  final double? pricePerUnit; // for per-pax, per-crew, per-hour
  final bool isOptional;
  final int? maxQuantity;
  final int defaultQuantity;

  ServiceAddOn({
    required this.id,
    required this.serviceId,
    required this.name,
    this.description,
    required this.pricingType,
    this.fixedPrice,
    this.priceByEventCombination,
    this.pricePerUnit,
    this.isOptional = true,
    this.maxQuantity,
    this.defaultQuantity = 1,
  });

  factory ServiceAddOn.fromJson(Map<String, dynamic> json) {
    return ServiceAddOn(
      id: json['id'] ?? '',
      serviceId: json['service_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      pricingType: AddOnPricingType.fromId(json['pricing_type'] ?? 'fixed'),
      fixedPrice: (json['fixed_price'] as num?)?.toDouble(),
      priceByEventCombination: (json['price_by_event_combination'] as Map?)
          ?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble(),
      isOptional: json['is_optional'] ?? true,
      maxQuantity: json['max_quantity'],
      defaultQuantity: json['default_quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_id': serviceId,
      'name': name,
      'description': description,
      'pricing_type': pricingType.id,
      'fixed_price': fixedPrice,
      'price_by_event_combination': priceByEventCombination,
      'price_per_unit': pricePerUnit,
      'is_optional': isOptional,
      'max_quantity': maxQuantity,
      'default_quantity': defaultQuantity,
    };
  }

  /// Get formatted price string for display
  String get formattedPrice {
    if (fixedPrice != null && fixedPrice! > 0) {
      return 'RM ${fixedPrice!.toStringAsFixed(2)}';
    }
    if (pricePerUnit != null && pricePerUnit! > 0) {
      if (pricingType == AddOnPricingType.perPax) return 'RM ${pricePerUnit!.toStringAsFixed(2)} / pax';
      if (pricingType == AddOnPricingType.perHour) return 'RM ${pricePerUnit!.toStringAsFixed(2)} / hour';
      if (pricingType == AddOnPricingType.perCrew) return 'RM ${pricePerUnit!.toStringAsFixed(2)} / crew';
      if (pricingType == AddOnPricingType.perEvent) return 'RM ${pricePerUnit!.toStringAsFixed(2)} / event';
    }
    return 'Price Varies';
  }

  /// Calculate add-on price based on context
  double calculatePrice({
    List<String>? eventTypes,
    int? paxCount,
    int? crewCount,
    int? hours,
    int quantity = 1,
  }) {
    switch (pricingType) {
      case AddOnPricingType.fixed:
        return (fixedPrice ?? 0) * quantity;

      case AddOnPricingType.perEvent:
        final eventCount = eventTypes?.length ?? 1;
        return (pricePerUnit ?? 0) * eventCount * quantity;

      case AddOnPricingType.perPax:
        return (pricePerUnit ?? 0) * (paxCount ?? 0) * quantity;

      case AddOnPricingType.perCrew:
        return (pricePerUnit ?? 0) * (crewCount ?? 0) * quantity;

      case AddOnPricingType.perHour:
        return (pricePerUnit ?? 0) * (hours ?? 0) * quantity;

      case AddOnPricingType.conditionalByEvent:
        if (eventTypes == null || priceByEventCombination == null) return 0;
        final key = EventTypeCombination(
          id: '',
          eventTypes: eventTypes,
          price: 0,
        ).getCombinationKey();
        return (priceByEventCombination![key] ?? 0) * quantity;
    }
  }
}

/// Tiered pricing for bulk quantities (e.g. products, rentals)
class BulkPricingTier {
  final int minQty;
  final int? maxQty;
  final double pricePerUnit;

  BulkPricingTier({
    required this.minQty,
    this.maxQty,
    required this.pricePerUnit,
  });

  factory BulkPricingTier.fromJson(Map<String, dynamic> json) {
    return BulkPricingTier(
      minQty: (json['min_qty'] as num?)?.toInt() ?? 1,
      maxQty: (json['max_qty'] as num?)?.toInt(),
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min_qty': minQty,
      'max_qty': maxQty,
      'price_per_unit': pricePerUnit,
    };
  }
}

/// Represents a product variation (e.g. Size, Color)
class ProductVariation {
  final String id;
  final String name;
  final List<String> options;
  final Map<String, double> optionPrices; // Price delta for each option
  final Map<String, int>? optionStock;   // Optional stock for each option

  ProductVariation({
    required this.id,
    required this.name,
    required this.options,
    this.optionPrices = const {},
    this.optionStock,
  });

  factory ProductVariation.fromJson(Map<String, dynamic> json) {
    return ProductVariation(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      options: (json['options'] as List?)?.map((e) => e.toString()).toList() ?? [],
      optionPrices: (json['prices'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          ) ??
          const {},
      optionStock: (json['stock'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'options': options,
      'prices': optionPrices,
      if (optionStock != null) 'stock': optionStock,
    };
  }
}
