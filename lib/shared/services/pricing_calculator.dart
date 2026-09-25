import 'package:eventease/shared/models/services/pricing_model.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';

/// Centralized pricing calculation engine for all service types
class PricingCalculator {
  /// Calculate total service price based on selections
  static double calculateServicePrice({
    required VendorService service,
    required List<String> selectedEventTypes,
    int paxCount = 0,
    int hours = 0,
    int days = 1,
    Map<String, int> selectedAddOns = const {},
    int crewCount = 0,
  }) {
    // 1. Calculate base price from pricing model
    final basePrice = _calculateBasePrice(
      service: service,
      selectedEventTypes: selectedEventTypes,
      paxCount: paxCount,
      hours: hours,
      days: days,
    );

    // 2. Apply day multiplier/discount
    final dayAdjustedPrice = _applyDayAdjustment(
      basePrice: basePrice,
      days: days,
      service: service,
      selectedEventTypes: selectedEventTypes,
    );

    // 3. Calculate add-ons
    final addOnTotal = _calculateAddOns(
      service: service,
      selectedEventTypes: selectedEventTypes,
      paxCount: paxCount,
      crewCount: crewCount,
      hours: hours,
      selectedAddOns: selectedAddOns,
    );

    return dayAdjustedPrice + addOnTotal;
  }

  /// Calculate base price based on pricing model type
  static double _calculateBasePrice({
    required VendorService service,
    required List<String> selectedEventTypes,
    required int paxCount,
    required int hours,
    required int days,
  }) {
    final pricingModel = service.pricingModel;
    if (pricingModel == null) {
      // Fallback to legacy pricing
      return service.price;
    }

    switch (pricingModel.type) {
      case PricingModelType.perEventType:
        return _findEventCombinationPrice(pricingModel, selectedEventTypes);

      case PricingModelType.perPax:
        return _calculatePaxPrice(pricingModel, paxCount);

      case PricingModelType.perHour:
        return _calculateHourlyPrice(pricingModel, hours, selectedEventTypes);

      case PricingModelType.perDay:
        return _calculateDailyPrice(pricingModel, days, selectedEventTypes);

      case PricingModelType.customCombination:
        // For packages, use event combination pricing
        return _findEventCombinationPrice(pricingModel, selectedEventTypes);
    }
  }

  /// Find price for specific event combination
  static double _findEventCombinationPrice(
    PricingModel pricingModel,
    List<String> eventTypes,
  ) {
    final price = pricingModel.findEventCombinationPrice(eventTypes);
    if (price != null) return price;

    // Fallback to base price if no combination found
    return pricingModel.basePrice ?? 0.0;
  }

  /// Calculate pax-based pricing with tier support
  static double _calculatePaxPrice(PricingModel pricingModel, int paxCount) {
    if (paxCount == 0) return pricingModel.basePrice ?? 0.0;

    // Check if pax tiers are defined
    if (pricingModel.paxTiers != null && pricingModel.paxTiers!.isNotEmpty) {
      final tier = pricingModel.findPaxTier(paxCount);
      if (tier != null) {
        return tier.pricePerPax * paxCount;
      }
    }

    // Fallback to simple per-pax pricing
    if (pricingModel.pricePerPax != null && pricingModel.pricePerPax! > 0) {
      return pricingModel.pricePerPax! * paxCount;
    }

    // fallback: if basePrice acts as the per-unit price
    return (pricingModel.basePrice ?? 0.0) * paxCount;
  }

  /// Calculate hourly pricing
  static double _calculateHourlyPrice(
    PricingModel pricingModel,
    int hours,
    List<String> eventTypes,
  ) {
    if (hours == 0) return pricingModel.basePrice ?? 0.0;

    // Check for event-specific hourly rates
    if (pricingModel.hourlyRates != null && eventTypes.isNotEmpty) {
      final eventType = eventTypes.first;
      final rate = pricingModel.hourlyRates![eventType];
      if (rate != null) {
        return rate * hours;
      }
    }

    // Fallback to base price as hourly rate
    return (pricingModel.basePrice ?? 0.0) * hours;
  }

  /// Calculate daily pricing
  static double _calculateDailyPrice(
    PricingModel pricingModel,
    int days,
    List<String> eventTypes,
  ) {
    if (days == 0) return pricingModel.basePrice ?? 0.0;

    // Check for event-specific daily rates
    if (pricingModel.dailyRates != null && eventTypes.isNotEmpty) {
      final eventType = eventTypes.first;
      final rate = pricingModel.dailyRates![eventType];
      if (rate != null) {
        return rate * days;
      }
    }

    // Fallback to base price as daily rate
    return (pricingModel.basePrice ?? 0.0) * days;
  }

  /// Apply day-based adjustments (same day discount, multi-day surcharge)
  static double _applyDayAdjustment({
    required double basePrice,
    required int days,
    required VendorService service,
    required List<String> selectedEventTypes,
  }) {
    double adjustedPrice = basePrice;

    // Same day multiple event discount
    if (days == 1 &&
        selectedEventTypes.length > 1 &&
        service.allowSameDayMultiEvent == true &&
        service.sameDayDiscount != null) {
      adjustedPrice -= service.sameDayDiscount!;
    }

    // Different day surcharge
    if (days > 1 && service.differentDaySurcharge != null) {
      adjustedPrice += service.differentDaySurcharge! * (days - 1);
    }

    return adjustedPrice > 0 ? adjustedPrice : 0;
  }

  /// Calculate total add-on costs
  static double _calculateAddOns({
    required VendorService service,
    required List<String> selectedEventTypes,
    required int paxCount,
    required int crewCount,
    required int hours,
    required Map<String, int> selectedAddOns,
  }) {
    if (service.addOns == null || service.addOns!.isEmpty) return 0.0;

    double total = 0.0;

    for (final entry in selectedAddOns.entries) {
      final addOnId = entry.key;
      final quantity = entry.value;

      // Find the add-on
      final addOn = service.addOns!.firstWhere(
        (a) => a.id == addOnId,
        orElse: () => ServiceAddOn(
          id: '',
          serviceId: '',
          name: '',
          pricingType: AddOnPricingType.fixed,
        ),
      );

      if (addOn.id.isEmpty) continue;

      // Calculate add-on price
      final addOnPrice = addOn.calculatePrice(
        eventTypes: selectedEventTypes,
        paxCount: paxCount,
        crewCount: crewCount,
        hours: hours,
        quantity: quantity,
      );

      total += addOnPrice;
    }

    return total;
  }

  /// Get price breakdown for display
  static Map<String, double> getPriceBreakdown({
    required VendorService service,
    required List<String> selectedEventTypes,
    int paxCount = 0,
    int hours = 0,
    int days = 1,
    Map<String, int> selectedAddOns = const {},
    int crewCount = 0,
  }) {
    final breakdown = <String, double>{};

    // Base price
    final basePrice = _calculateBasePrice(
      service: service,
      selectedEventTypes: selectedEventTypes,
      paxCount: paxCount,
      hours: hours,
      days: days,
    );
    breakdown['Base Price'] = basePrice;

    // Day adjustments
    if (days == 1 &&
        selectedEventTypes.length > 1 &&
        service.allowSameDayMultiEvent == true &&
        service.sameDayDiscount != null) {
      breakdown['Same Day Discount'] = -service.sameDayDiscount!;
    }

    if (days > 1 && service.differentDaySurcharge != null) {
      breakdown['Multi-Day Surcharge'] = service.differentDaySurcharge! * (days - 1);
    }

    // Add-ons
    if (service.addOns != null && selectedAddOns.isNotEmpty) {
      for (final entry in selectedAddOns.entries) {
        final addOnId = entry.key;
        final quantity = entry.value;

        final addOn = service.addOns!.firstWhere(
          (a) => a.id == addOnId,
          orElse: () => ServiceAddOn(
            id: '',
            serviceId: '',
            name: '',
            pricingType: AddOnPricingType.fixed,
          ),
        );

        if (addOn.id.isEmpty) continue;

        final addOnPrice = addOn.calculatePrice(
          eventTypes: selectedEventTypes,
          paxCount: paxCount,
          crewCount: crewCount,
          hours: hours,
          quantity: quantity,
        );

        final displayName = quantity > 1 ? '${addOn.name} (×$quantity)' : addOn.name;
        breakdown[displayName] = addOnPrice;
      }
    }

    return breakdown;
  }

  /// Get formatted price breakdown string
  static String getFormattedBreakdown({
    required VendorService service,
    required List<String> selectedEventTypes,
    int paxCount = 0,
    int hours = 0,
    int days = 1,
    Map<String, int> selectedAddOns = const {},
    int crewCount = 0,
  }) {
    final breakdown = getPriceBreakdown(
      service: service,
      selectedEventTypes: selectedEventTypes,
      paxCount: paxCount,
      hours: hours,
      days: days,
      selectedAddOns: selectedAddOns,
      crewCount: crewCount,
    );

    final buffer = StringBuffer();
    double total = 0.0;

    for (final entry in breakdown.entries) {
      final label = entry.key;
      final amount = entry.value;
      total += amount;

      final sign = amount >= 0 ? '' : '-';
      final absAmount = amount.abs();
      buffer.writeln('$label: ${sign}RM ${absAmount.toStringAsFixed(2)}');
    }

    buffer.writeln('─' * 40);
    buffer.writeln('Total: RM ${total.toStringAsFixed(2)}');

    return buffer.toString();
  }
}
