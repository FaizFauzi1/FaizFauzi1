import 'package:flutter/material.dart';
import 'package:eventease/shared/models/services/service_category.dart';

// Temporary compatibility layer for old ServiceCategory usage
// This provides backward compatibility while we migrate to the new model

extension ServiceCategoryCompat on ServiceCategory {
  // Stub for serviceCount - returns 0 as placeholder
  // TODO: Replace with actual database query
  int get serviceCount => 0;
  
  // Stub for subcategories - returns empty list
  // TODO: Fetch from event_type_categories table
  List<String> get subcategories => [];
}

// Helper class for CategoryData used in categories_screen
class CategoryData {
  final String id;
  final String name;
  final IconData icon;
  final List<String> subcategories;
  final int serviceCount;
  final String? description;

  CategoryData({
    required this.id,
    required this.name,
    required this.icon,
    this.subcategories = const [],
    this.serviceCount = 0,
    this.description,
  });
}

// Temporary replacement for getDefaultCategories
class ServiceCategoryHelper {
  static List<ServiceCategory> getDefaultCategories() {
    // Return empty list - should be fetched from database instead
    // TODO: Replace with CategoryProvider.loadCategories()
    return [];
  }
}
