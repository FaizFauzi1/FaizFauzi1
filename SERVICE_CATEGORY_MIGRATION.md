// This file documents the breaking changes in ServiceCategory model
// and provides migration guidance for fixing compilation errors

## ServiceCategory Model Changes

### Removed Properties:
1. `subcategories` - No longer exists
2. `serviceCount` - No longer exists  
3. `getDefaultCategories()` - Static method removed

### Changed Methods:
1. `fromMap(Map<String, dynamic> map, String id)` → `fromMap(Map<String, dynamic> map)`
   - Now only takes one parameter (the map contains the ID)

### New Properties:
1. `slug` - Required field (unique identifier)
2. `categoryType` - enum: service, product, package, rental
3. `pricingModel` - enum: per_pax, per_day, per_session, fixed, per_hour
4. `isActive` - boolean flag
5. `isAdvanced` - boolean flag for vendor tier restrictions
6. `requiresVerification` - boolean flag
7. `minVendorTier` - enum: basic, verified, premium

## Migration Guide:

### 1. Fix fromMap calls:
```dart
// OLD:
ServiceCategory.fromMap(json, json['id'].toString())

// NEW:
ServiceCategory.fromMap(json)
```

### 2. Remove subcategories references:
```dart
// OLD:
category.subcategories
category.copyWith(subcategories: [...])

// NEW:
// Subcategories are now managed separately via event_type_categories table
// Use CategoryProvider to fetch categories for specific event types
```

### 3. Remove serviceCount references:
```dart
// OLD:
category.serviceCount
category.copyWith(serviceCount: count)

// NEW:
// Service counts should be calculated dynamically from vendor_services table
// Query: SELECT COUNT(*) FROM vendor_services WHERE category_id = ?
```

### 4. Replace getDefaultCategories():
```dart
// OLD:
ServiceCategory.getDefaultCategories()

// NEW:
// Use CategoryProvider to fetch from database:
final provider = Provider.of<CategoryProvider>(context);
await provider.loadCategories();
final categories = provider.categories;
```

### 5. Update ServiceCategory constructor calls:
```dart
// OLD:
ServiceCategory(
  id: '1',
  name: 'Catering',
  subcategories: ['Buffet', 'Plated'],
  serviceCount: 10,
)

// NEW:
ServiceCategory(
  id: '1',
  name: 'Catering',
  slug: 'catering',
  categoryType: 'service',
  pricingModel: 'per_pax',
  isActive: true,
  isAdvanced: false,
)
```

## Files Requiring Updates:

1. ✅ admin_provider.dart - FIXED
2. ✅ vendor_provider_updated.dart - FIXED
3. ❌ enhanced_service_creation_screen.dart - NEEDS FIX
4. ❌ categories_screen.dart - NEEDS FIX
5. ❌ booking_service_management_screen.dart - NEEDS FIX
