import 'package:flutter/foundation.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';

class CompareProvider with ChangeNotifier {
  final List<VendorService> _compareList = [];
  static const int _maxCompareItems = 4;

  List<VendorService> get compareList => List.unmodifiable(_compareList);

  bool get isEmpty => _compareList.isEmpty;
  bool get isFull => _compareList.length >= _maxCompareItems;
  int get maxItems => _maxCompareItems;
  int get currentCount => _compareList.length;

  bool isInCompareList(String serviceId) {
    return _compareList.any((service) => service.id == serviceId);
  }

  bool canAddToCompare() {
    return _compareList.length < _maxCompareItems;
  }

  void addToCompare(VendorService service) {
    if (!isInCompareList(service.id) && canAddToCompare()) {
      _compareList.add(service);
      notifyListeners();
    }
  }

  void removeFromCompare(String serviceId) {
    _compareList.removeWhere((service) => service.id == serviceId);
    notifyListeners();
  }

  void clearCompareList() {
    _compareList.clear();
    notifyListeners();
  }

  void toggleCompare(VendorService service) {
    if (isInCompareList(service.id)) {
      removeFromCompare(service.id);
    } else if (canAddToCompare()) {
      addToCompare(service);
    }
  }

  // Get services by category for comparison
  List<VendorService> getServicesByCategory(String category) {
    return _compareList.where((service) =>
      service.category.name.toLowerCase() == category.toLowerCase()
    ).toList();
  }

  // Check if all services in compare list are from same category
  bool get areAllSameCategory {
    if (_compareList.isEmpty) return true;
    final firstCategory = _compareList.first.category.name.toLowerCase();
    return _compareList.every((service) =>
      service.category.name.toLowerCase() == firstCategory
    );
  }

  // Get common attributes for comparison
  Map<String, dynamic> getCommonAttributes() {
    if (_compareList.isEmpty) return {};

    final firstService = _compareList.first;
    final commonAttributes = <String, dynamic>{};

    // Price range
    final prices = _compareList.map((s) => s.price).toList();
    commonAttributes['priceRange'] = {
      'min': prices.reduce((a, b) => a < b ? a : b),
      'max': prices.reduce((a, b) => a > b ? a : b),
    };

    // Rating range (calculate from reviews if available)
    final ratings = _compareList.map((s) {
      if (s.reviews != null && s.reviews!.isNotEmpty) {
        final avgRating = s.reviews!.map((r) => r['rating'] as int).reduce((a, b) => a + b) / s.reviews!.length;
        return avgRating;
      }
      return 0.0;
    }).toList();
    commonAttributes['ratingRange'] = {
      'min': ratings.reduce((a, b) => a < b ? a : b),
      'max': ratings.reduce((a, b) => a > b ? a : b),
    };

    // Categories
    commonAttributes['categories'] = _compareList
        .map((s) => s.category.displayName ?? s.category.name)
        .toSet()
        .toList();

    return commonAttributes;
  }
}
