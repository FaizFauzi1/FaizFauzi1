import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/shared/models/services/service_category.dart';

class CategoryProvider with ChangeNotifier {
  static const _categoriesCacheKey = 'search_filter_categories';
  static const _eventTypesCacheKey = 'search_filter_event_types';

  final SupabaseClient _supabase = Supabase.instance.client;

  List<ServiceCategory> _allCategories = [];
  List<ServiceCategory> _filteredCategories = [];
  List<String> _eventTypes = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ServiceCategory> get allCategories => _allCategories;
  List<ServiceCategory> get filteredCategories => _filteredCategories;
  List<String> get eventTypes => _eventTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSearchFilterOptions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await _restoreSearchFilterCache();
    notifyListeners();

    try {
      final response = await _supabase
          .from('service_categories')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      _allCategories = (response as List)
          .map((json) => ServiceCategory.fromMap(json))
          .toList();
      _filteredCategories = _allCategories;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _categoriesCacheKey,
        jsonEncode(_allCategories.map((category) => category.toMap()).toList()),
      );
    } catch (e) {
      _error = 'Failed to fetch categories: $e';
      debugPrint(_error);
    }

    try {
      final response = await _supabase
          .from('event_types')
          .select()
          .order('display_order', ascending: true);

      final eventTypes = <String>{};
      for (final row in response as List) {
        final isEnabled = row['is_enabled'] ?? row['is_active'] ?? true;
        final name = (row['display_name'] ?? row['name'] ?? '').toString().trim();
        if (isEnabled == true && name.isNotEmpty) {
          eventTypes.add(name);
        }
      }
      _eventTypes = eventTypes.toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_eventTypesCacheKey, jsonEncode(_eventTypes));
    } catch (e) {
      _error ??= 'Failed to fetch event types: $e';
      debugPrint('Failed to fetch search event types: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _restoreSearchFilterCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedCategories = prefs.getString(_categoriesCacheKey);
      if (_allCategories.isEmpty && cachedCategories != null) {
        _allCategories = (jsonDecode(cachedCategories) as List)
            .map((json) => ServiceCategory.fromMap(
                  Map<String, dynamic>.from(json as Map),
                ))
            .toList();
        _filteredCategories = _allCategories;
      }

      final cachedEventTypes = prefs.getString(_eventTypesCacheKey);
      if (_eventTypes.isEmpty && cachedEventTypes != null) {
        _eventTypes = (jsonDecode(cachedEventTypes) as List)
            .map((name) => name.toString())
            .toList();
      }
    } catch (e) {
      debugPrint('Failed to restore search filter cache: $e');
    }
  }

  /// Fetch all categories from Supabase
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('service_categories')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      _allCategories = (response as List)
          .map((json) => ServiceCategory.fromMap(json))
          .toList();

      _filteredCategories = _allCategories;

      debugPrint('Fetched ${_allCategories.length} categories');
    } catch (e) {
      _error = 'Failed to fetch categories: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get categories for specific event types
  Future<List<ServiceCategory>> getCategoriesForEventTypes(
    List<String> eventTypeSlugs, {
    bool primaryOnly = false,
  }) async {
    try {
      // 1. Resolve Slugs to UUIDs
      // The 'category' column in event_types table holds the slug (e.g., 'wedding')
      final eventTypesResponse = await _supabase
          .from('event_types')
          .select('id')
          .inFilter('category', eventTypeSlugs);

      final List<String> uuidList = (eventTypesResponse as List)
          .map((e) => e['id'] as String)
          .toList();

      if (uuidList.isEmpty) {
        debugPrint('No event types found for slugs: $eventTypeSlugs');
        return [];
      }

      // 2. Query event_type_categories junction table using UUIDs
      var query = _supabase
          .from('event_type_categories')
          .select('category_id, is_primary, service_categories(*)')
          .inFilter('event_type_id', uuidList);

      if (primaryOnly) {
        query = query.eq('is_primary', true);
      }

      final response = await query.order('display_order', ascending: true);

      final categories = <ServiceCategory>[];
      final seenIds = <String>{};

      for (final item in response as List) {
        final categoryData = item['service_categories'];
        if (categoryData != null) {
          final category = ServiceCategory.fromMap(categoryData);
          
          // Avoid duplicates
          if (!seenIds.contains(category.id)) {
            categories.add(category);
            seenIds.add(category.id);
          }
        }
      }

      debugPrint('Found ${categories.length} categories for event types: $eventTypeSlugs');
      return categories;
    } catch (e) {
      debugPrint('Error fetching categories for event types: $e');
      return [];
    }
  }

  /// Get primary categories for event types (first 5-8 to show)
  Future<List<ServiceCategory>> getPrimaryCategoriesForEventTypes(
    List<String> eventTypeIds,
  ) async {
    return getCategoriesForEventTypes(eventTypeIds, primaryOnly: true);
  }

  /// Get secondary categories for event types (shown after "Show More")
  Future<List<ServiceCategory>> getSecondaryCategoriesForEventTypes(
    List<String> eventTypeIds,
  ) async {
    try {
      final allCategories = await getCategoriesForEventTypes(eventTypeIds);
      final primaryCategories = await getPrimaryCategoriesForEventTypes(eventTypeIds);
      
      final primaryIds = primaryCategories.map((c) => c.id).toSet();
      return allCategories.where((c) => !primaryIds.contains(c.id)).toList();
    } catch (e) {
      debugPrint('Error fetching secondary categories: $e');
      return [];
    }
  }

  /// Filter categories by vendor access level
  List<ServiceCategory> filterByVendorAccess({
    required bool isVerified,
    required VendorTier vendorTier,
    String? verificationStatus,
  }) {
    return _allCategories.where((category) {
      return category.canVendorAccess(
        isVerified: isVerified,
        vendorTier: vendorTier,
        verificationStatus: verificationStatus,
      );
    }).toList();
  }

  /// Search categories by name
  void searchCategories(String query) {
    if (query.isEmpty) {
      _filteredCategories = _allCategories;
    } else {
      _filteredCategories = _allCategories.where((category) {
        return category.name.toLowerCase().contains(query.toLowerCase()) ||
            category.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  /// Get category by ID
  ServiceCategory? getCategoryById(String id) {
    try {
      return _allCategories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get category by slug
  ServiceCategory? getCategoryBySlug(String slug) {
    try {
      return _allCategories.firstWhere((c) => c.slug == slug);
    } catch (e) {
      return null;
    }
  }

  /// Get categories by type
  List<ServiceCategory> getCategoriesByType(CategoryType type) {
    return _allCategories.where((c) => c.categoryType == type).toList();
  }

  /// Get categories by pricing model
  List<ServiceCategory> getCategoriesByPricingModel(PricingModel model) {
    return _allCategories.where((c) => c.pricingModel == model).toList();
  }

  /// Get advanced categories (requires verification)
  List<ServiceCategory> getAdvancedCategories() {
    return _allCategories.where((c) => c.isAdvanced).toList();
  }

  /// Get basic categories (no verification required)
  List<ServiceCategory> getBasicCategories() {
    return _allCategories.where((c) => !c.isAdvanced).toList();
  }

  /// Clear filters
  void clearFilters() {
    _filteredCategories = _allCategories;
    notifyListeners();
  }

  /// Refresh categories
  Future<void> refresh() async {
    await fetchCategories();
  }
}
