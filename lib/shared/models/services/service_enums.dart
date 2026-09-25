enum ApprovalStatus {
  pending,
  approved,
  rejected,
}

enum ServiceStatus {
  active,
  inactive,
  draft,
  maintenance,
  discontinued,
}

enum ServiceType {
  product,
  rental,
  package,
  consultation,
  service,
}

enum PricingTier {
  basic,
  standard,
  premium,
  enterprise,
}

enum PricingMode {
  flatRate,
  perPax,
  perHour,
  perDay,
  perItem,
  perSlot,
  perArea,
  custom,
  tiered,
  perEventType,
}

enum AvailabilityType {
  dateBased,
  timeSlot,
  alwaysAvailable,
}

enum DiscountType {
  flat,
  percentage,
}

enum RentalType {
  item,
  set,
  package,
}

extension PricingTierExtension on PricingTier {
  String get displayName {
    switch (this) {
      case PricingTier.basic:
        return 'Basic';
      case PricingTier.standard:
        return 'Standard';
      case PricingTier.premium:
        return 'Premium';
      case PricingTier.enterprise:
        return 'Enterprise';
      default:
        return 'Unknown';
    }
  }

  String get description {
    switch (this) {
      case PricingTier.basic:
        return 'Essential features for small events';
      case PricingTier.standard:
        return 'Standard package with additional features';
      case PricingTier.premium:
        return 'Premium experience with advanced options';
      case PricingTier.enterprise:
        return 'Full enterprise solution';
      default:
        return '';
    }
  }
}

enum VenueType {
  hotel,
  ballroom,
  garden,
  restaurant,
  cafe,
  conventionCenter,
  houseVilla,
  studio,
  office,
  outdoor,
  other,
}

extension VenueTypeExtension on VenueType {
  String get displayName {
    switch (this) {
      case VenueType.hotel: return 'Hotel';
      case VenueType.ballroom: return 'Hotel Ballroom';
      case VenueType.garden: return 'Garden / Park';
      case VenueType.restaurant: return 'Restaurant / Bar';
      case VenueType.cafe: return 'Café';
      case VenueType.conventionCenter: return 'Convention Center';
      case VenueType.houseVilla: return 'Private House / Villa';
      case VenueType.studio: return 'Studio / Space';
      case VenueType.office: return 'Office / Corporate';
      case VenueType.outdoor: return 'Outdoor / Field';
      case VenueType.other: return 'Other';
    }
  }
}
