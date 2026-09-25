import '../../shared/models/event/event_category.dart';

/// Helper utility for working with event categories
class CategoryHelper {
  /// Get EventCategory from category ID string
  static EventCategory getEventCategoryFromId(String categoryId) {
    return EventCategory.values.firstWhere(
      (category) => category.id == categoryId,
      orElse: () => EventCategory.other, // Default fallback
    );
  }

  /// Get EventCategory from display name
  static EventCategory getEventCategoryFromDisplayName(String displayName) {
    return EventCategory.values.firstWhere(
      (category) => category.displayName == displayName,
      orElse: () => EventCategory.other, // Default fallback
    );
  }

  /// Get all category display names
  static List<String> getAllCategoryDisplayNames() {
    return EventCategory.values.map((category) => category.displayName).toList();
  }

  /// Check if category ID is valid
  static bool isValidCategoryId(String categoryId) {
    return EventCategory.values.any((category) => category.id == categoryId);
  }
}
