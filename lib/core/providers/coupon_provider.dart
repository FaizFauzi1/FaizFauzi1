import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/vendor/models/service_coupon.dart';

class CouponProvider with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  List<ServiceCoupon> _vendorCoupons = [];
  List<ServiceCoupon> get vendorCoupons => _vendorCoupons;

  // Fetch all coupons for a vendor
  Future<void> fetchVendorCoupons(String vendorProfileId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _client
          .from('service_coupons')
          .select()
          .eq('vendor_id', vendorProfileId)
          .order('created_at', ascending: false);
      
      _vendorCoupons = (response as List).map((c) => ServiceCoupon.fromJson(c)).toList();
    } catch (e) {
      print('Error fetching vendor coupons: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create or Update Coupon
  Future<bool> saveCoupon(ServiceCoupon coupon) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (coupon.id == null) {
        await _client.from('service_coupons').insert(coupon.toJson());
      } else {
        await _client.from('service_coupons').update(coupon.toJson()).eq('id', coupon.id!);
      }
      return true;
    } catch (e) {
      print('Error saving coupon: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete Coupon
  Future<bool> deleteCoupon(String id) async {
    try {
      await _client.from('service_coupons').delete().eq('id', id);
      _vendorCoupons.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting coupon: $id, error: $e');
      return false;
    }
  }

  // Validate Coupon (for Customer)
  Future<ServiceCoupon?> validateCoupon({
    required String code,
    required String serviceId,
    required double orderAmount,
  }) async {
    try {
      // Fetch coupon matching code and serviceId (or global vendor-wide coupon)
      final response = await _client
          .from('service_coupons')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .or('service_id.eq.$serviceId,service_id.is.null')
          .maybeSingle();
      
      if (response == null) return null;
      
      final coupon = ServiceCoupon.fromJson(response);
      
      // Validation Logic
      final now = DateTime.now();
      if (coupon.expiryDate != null && coupon.expiryDate!.isBefore(now)) {
        throw 'Coupon expired';
      }
      
      if (coupon.usageLimit != null && coupon.currentUsage >= coupon.usageLimit!) {
        throw 'Coupon limit reached';
      }
      
      if (orderAmount < coupon.minSpend) {
        throw 'Minimum spend of RM ${coupon.minSpend.toStringAsFixed(2)} required';
      }
      
      return coupon;
    } catch (e) {
      print('Coupon validation error: $e');
      rethrow;
    }
  }

  // Use Coupon (increment count)
  Future<void> incrementCouponUsage(String couponId) async {
    try {
      await _client.rpc('increment_coupon_usage', params: {'coupon_id': couponId});
    } catch (e) {
      print('Error incrementing coupon via RPC: $e');
      // Fallback
      try {
        final current = await _client.from('service_coupons').select('current_usage').eq('id', couponId).single();
        final nextUsage = (current['current_usage'] as int) + 1;
        await _client.from('service_coupons').update({'current_usage': nextUsage}).eq('id', couponId);
      } catch (e2) {
        print('Error incrementing coupon fallback: $e2');
      }
    }
  }
}
