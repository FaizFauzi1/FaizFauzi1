import 'package:flutter/material.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/shared/models/services/service_review.dart';

class ReviewProvider with ChangeNotifier {
  final Map<String, List<ServiceReview>> _serviceReviews = {};
  final Map<String, List<ServiceReview>> _vendorReviews = {};
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ServiceReview> getReviewsForService(String serviceId) {
    return _serviceReviews[serviceId] ?? [];
  }

  List<ServiceReview> getReviewsForVendor(String vendorId) {
    return _vendorReviews[vendorId] ?? [];
  }

  Future<void> loadReviewsForService(String serviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      
      // 1. Fetch reviews (no embedded join — customer_id FK points to auth.users, not customer_user)
      final response = await client
          .from('service_reviews')
          .select()
          .eq('service_id', serviceId)
          .order('created_at', ascending: false);

      // 2. Collect unique customer IDs to batch-fetch names
      final customerIds = response
          .map((r) => r['customer_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      // 3. Fetch customer names in one go
      Map<String, String> customerNames = {};
      if (customerIds.isNotEmpty) {
        try {
          final customers = await client
              .from('customer_user')
              .select('id, full_name, name')
              .inFilter('id', customerIds);
          for (final c in customers) {
            final id = c['id'] as String;
            customerNames[id] = c['full_name'] ?? c['name'] ?? 'Anonymous';
          }
        } catch (_) {
          // If customer_user lookup fails, just use 'Anonymous'
        }
      }

      // 4. Build review models with customer names attached
      final reviews = response.map((data) {
        final Map<String, dynamic> modifiedData = Map.from(data);
        modifiedData['customer_name'] = customerNames[data['customer_id']] ?? 'Anonymous';
        return ServiceReview.fromJson(modifiedData);
      }).toList();

      _serviceReviews[serviceId] = reviews;
    } catch (e) {
      print('Error loading reviews: $e');
      _error = 'Failed to load reviews';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadReviewsForVendor(String vendorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      
      // 1. Fetch reviews for all services belonging to this vendor
      // We join with the services table to filter by vendor_id
      final response = await client
          .from('service_reviews')
          .select('*, vendor_services!inner(vendor_id)')
          .eq('vendor_services.vendor_id', vendorId)
          .order('created_at', ascending: false);

      // 2. Collect unique customer IDs to batch-fetch names
      final customerIds = (response as List)
          .map((r) => r['customer_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      // 3. Fetch customer names in one go
      Map<String, String> customerNames = {};
      if (customerIds.isNotEmpty) {
        try {
          final customers = await client
              .from('customer_user')
              .select('id, full_name, name')
              .inFilter('id', customerIds);
          for (final c in customers) {
            final id = c['id'] as String;
            customerNames[id] = c['full_name'] ?? c['name'] ?? 'Anonymous';
          }
        } catch (_) {
          // If customer_user lookup fails, just use 'Anonymous'
        }
      }

      // 4. Build review models with customer names attached
      final reviews = (response as List).map((data) {
        final Map<String, dynamic> modifiedData = Map.from(data);
        modifiedData['customer_name'] = customerNames[data['customer_id']] ?? 'Anonymous';
        return ServiceReview.fromJson(modifiedData);
      }).toList();

      _vendorReviews[vendorId] = reviews;
    } catch (e) {
      print('Error loading vendor reviews: $e');
      _error = 'Failed to load reviews';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addReview({
    required String serviceId,
    required String customerId,
    required int rating,
    required String comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      final response = await client.from('service_reviews').insert({
        'service_id': serviceId,
        'customer_id': customerId,
        'rating': rating,
        'comment': comment,
      }).select().single();

      if (response != null) {
        // Reload reviews to get the new one with customer info
        await loadReviewsForService(serviceId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding review: $e');
      _error = 'Failed to submit review: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double getAverageRating(String serviceId) {
    final reviews = getReviewsForService(serviceId);
    if (reviews.isEmpty) return 0.0;
    final total = reviews.fold<int>(0, (sum, item) => sum + item.rating);
    return total / reviews.length;
  }
}
