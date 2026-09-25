import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';

/// Static helpers for referral RPC calls — usable without [ReferralProvider].
class ReferralService {
  static String? pendingReferralCode;

  static void setPendingCode(String? code) {
    pendingReferralCode = code?.trim().toUpperCase();
  }

  static Future<void> applyOnSignup(String userId) async {
    final code = pendingReferralCode;
    if (code == null || code.isEmpty) return;

    try {
      await SupabaseService.client.rpc('apply_referral_on_signup', params: {
        'p_referred_user_id': userId,
        'p_referral_code': code,
      });
      pendingReferralCode = null;
    } catch (e) {
      debugPrint('ReferralService.applyOnSignup error: $e');
    }
  }

  static Future<void> qualifyReferral(
    String referredUserId,
    String qualifyingEvent,
  ) async {
    try {
      await SupabaseService.client.rpc('qualify_referral', params: {
        'p_referred_user_id': referredUserId,
        'p_qualifying_event': qualifyingEvent,
      });
    } catch (e) {
      debugPrint('ReferralService.qualifyReferral error: $e');
    }
  }

  static Future<double> getServiceFeeRate({
    required String customerId,
    String? vendorId,
  }) async {
    try {
      final result = await SupabaseService.client.rpc(
        'get_customer_service_fee_rate',
        params: {
          'p_customer_id': customerId,
          'p_vendor_id': vendorId,
        },
      );
      if (result == null) return 0.02;
      return (result as num).toDouble();
    } catch (e) {
      debugPrint('ReferralService.getServiceFeeRate error: $e');
      return 0.02;
    }
  }

  static Future<double> calculateCartServiceFee({
    required String customerId,
    required Map<String, double> upfrontByVendorId,
  }) async {
    var totalFee = 0.0;
    for (final entry in upfrontByVendorId.entries) {
      if (entry.key.isEmpty || entry.key == 'unknown') {
        totalFee += entry.value * 0.02;
        continue;
      }
      final rate = await getServiceFeeRate(
        customerId: customerId,
        vendorId: entry.key,
      );
      totalFee += entry.value * rate;
    }
    return totalFee;
  }
}
