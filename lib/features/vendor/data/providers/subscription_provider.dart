import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/core/services/payment_service.dart';
import 'package:eventease/core/config/billplz_config.dart';
import 'package:eventease/shared/models/payment.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection/collection.dart';
import '../models/subscription_model.dart';
import '../models/vendor.dart';
import 'package:eventease/features/referral/data/referral_service.dart';

class SubscriptionProvider with ChangeNotifier {
  static const _tiersCacheKey = 'vendor_subscription_tiers';

  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<SubscriptionTierModel> _tiers = [];
  SubscriptionTierModel? _currentTier;
  List<SubscriptionPayment> _payments = [];
  int _servicesCount = 0;
  int _bookingsCount = 0;
  String _visibilityLevel = '';
  DateTime? _expiryDate;
  bool _isLoading = false;
  String? _error;

  List<SubscriptionTierModel> get tiers => _tiers;
  SubscriptionTierModel? get currentTier => _currentTier;
  List<SubscriptionPayment> get payments => _payments;
  int get servicesCount => _servicesCount;
  int get bookingsCount => _bookingsCount;
  String get visibilityLevel => _visibilityLevel;
  DateTime? get expiryDate => _expiryDate;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSubscriptionData(String vendorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _restoreCachedTiers();

      // 1. Load Tiers
      final tiersData = await _supabase
          .from('subscription_tiers')
          .select()
          .eq('is_active', true)
          .eq('target_audience', 'vendor')
          .order('sort_order');
      _tiers = (tiersData as List).map((json) => SubscriptionTierModel.fromJson(json)).toList();
          await _cacheTiers();

      // 2. Load Current Vendor Profile to see their tier
      final vendorData = await _supabase
          .from('vendor_profiles')
          .select('subscription_tier')
          .eq('id', vendorId)
          .single();
      
      // 3. Load Payments
      final paymentsData = await _supabase
          .from('subscription_payments')
          .select()
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false)
          .limit(10);
      _payments = (paymentsData as List).map((json) => SubscriptionPayment.fromJson(json)).toList();

      // Check if latest payment is completed but tier is outdated
      final latestPaid = _payments.firstWhereOrNull((p) => p.status.toLowerCase() == 'completed' || p.status.toLowerCase() == 'succeeded');
        String? tierName =
          vendorData['subscription_tier']?.toString() ?? _tiers.firstOrNull?.name;
      
      if (latestPaid != null) {
        // Find tier by ID
        final latestTier = _tiers.firstWhereOrNull((t) => t.id == latestPaid.tierId);
        if (latestTier != null &&
          latestTier.name.toLowerCase() != tierName?.toLowerCase()) {
          // Sync database because webhook couldn't do it
          tierName = latestTier.name;
          await _supabase.from('vendor_profiles').update({'subscription_tier': tierName}).eq('id', vendorId);
        }
      }

      _currentTier = _tiers.firstWhereOrNull(
            (tier) => tier.name.toLowerCase() == tierName?.toLowerCase(),
          ) ??
          _tiers.firstOrNull;

      // 4. Calculate Expiry Date from latest successful payment
      _expiryDate = latestPaid?.periodEnd;

      // 5. Load Real Metrics
      // Get service count
      final servicesResponse = await _supabase
          .from('vendor_services')
          .select('id')
          .eq('vendor_id', vendorId);
      _servicesCount = (servicesResponse as List).length;

      final bookingsResponse = await _supabase
          .from('bookings')
          .select('id')
          .eq('vendor_id', vendorId)
          .inFilter('status', ['confirmed', 'completed']);
      _bookingsCount = (bookingsResponse as List).length;

      // 6. Set Visibility Level
      _visibilityLevel =
          _currentTier?.limits['visibility_level']?.toString() ?? '';

    } catch (e) {
      print('Error loading subscription data: $e');
      _error = 'Failed to load subscription information';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> upgradeSubscription(
    String vendorId, 
    SubscriptionTierModel newTier, {
    PaymentGatewayProvider gateway = PaymentGatewayProvider.xendit,
    String currency = 'MYR',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch vendor details for the payment gateway
      final vendorProfile = await _supabase
          .from('vendor_profiles')
          .select()
          .eq('id', vendorId)
          .single();
          
      final authUser = _supabase.auth.currentUser;
      final email = authUser?.email ?? 'vendor@example.com';
      final name = vendorProfile['business_name'] ?? 'Vendor';

      final String? paymentUrl;
      final String? transactionId;

      if (gateway == PaymentGatewayProvider.xendit) {
        // Generate Xendit Invoice URL
        final String callbackConfig = dotenv.env['PAYMENT_CALLBACK_URL'] ?? 'https://eventease-web.netlify.app/payment/callback';
        final String redirectUrl = kIsWeb ? Uri.base.toString() : callbackConfig;
        final result = await PaymentService.createXenditInvoice(
          email: email,
          name: name,
          amount: newTier.price,
          currency: currency,
          externalId: 'sub_${vendorId}_${DateTime.now().millisecondsSinceEpoch}',
          description: 'Vendor Subscription Upgrade: ${newTier.name}',
          redirectUrl: redirectUrl,
          metadata: {
            'type': 'vendor_subscription',
            'vendor_id': vendorId,
            'tier_id': newTier.id,
            'tier_name': newTier.name,
          },
        );
        paymentUrl = result['invoice_url'] ?? result['url'];
        transactionId = result['external_id'] ?? result['id'];
      } else {
        // Generate Billplz Payment URL using PaymentService
        final String functionUrl = '${SupabaseService.supabaseUrl}/functions/v1/payment-webhook';
        final result = await PaymentService.createBill(
           collectionId: BillplzConfig.collectionId,
           email: email,
           mobile: '0123456789', 
           name: name,
           amount: newTier.price,
           callbackUrl: functionUrl, // Point to dynamic Edge Function URL
           description: 'Vendor Subscription Upgrade: ${newTier.name}',
           metadata: {
             'type': 'vendor_subscription',
             'vendor_id': vendorId,
             'tier_id': newTier.id,
             'tier_name': newTier.name,
           }
        );
        paymentUrl = result['url'];
        transactionId = result['id'];
      }

      if (transactionId != null) {
        // 3. Save a pending record in subscription_payments
        // This allows the webhook to match it later
        await _supabase.from('subscription_payments').insert({
          'vendor_id': vendorId,
          'tier_id': newTier.id,
          'amount': newTier.price,
          'payment_status': 'pending',
          'transaction_id': transactionId, 
          'start_date': DateTime.now().toIso8601String(),
          'end_date': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        });
      }

      return paymentUrl;
      
    } catch (e) {
      print('Error upgrading subscription: $e');
      _error = 'Upgrade failed. Please try again.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Poll Billplz for payment status (useful for immediate UI updates when returning from external browser)
  void startPollingBill(String billId, String vendorId, SubscriptionTierModel newTier) async {
    int attempts = 0;
    const maxAttempts = 20; // Poll for about 1 minute (every 3s)
    
    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 3));
      attempts++;
      
      try {
        // Poll the database instead of Billplz API directly to avoid Web CORS issues!
        // The webhook handles updating this table.
        final paymentRecord = await _supabase
            .from('subscription_payments')
            .select('payment_status')
            .eq('transaction_id', billId)
            .maybeSingle();
            
        if (paymentRecord != null) {
          final status = paymentRecord['payment_status'];
          
          if (status == 'completed') {
            _currentTier = newTier;
            
            // Explicitly sync the database here
            await _supabase.from('vendor_profiles').update({'subscription_tier': newTier.name}).eq('id', vendorId);

            final vendorProfile = await _supabase
                .from('vendor_profiles')
                .select('user_id')
                .eq('id', vendorId)
                .maybeSingle();
            final vendorUserId = vendorProfile?['user_id'] as String?;
            if (vendorUserId != null) {
              await ReferralService.qualifyReferral(
                vendorUserId,
                'vendor_subscription',
              );
            }
            
            // Also fetch updated payments list
            final paymentsData = await _supabase
                .from('subscription_payments')
                .select()
                .eq('vendor_id', vendorId)
                .order('created_at', ascending: false);
            
            if (paymentsData != null) {
                _payments = (paymentsData as List).map((json) => SubscriptionPayment.fromJson(json)).toList();
            }
            
            notifyListeners();
            debugPrint('Vendor Payment successful! Local state updated to ${newTier.name}');
            break; // Stop polling
          } else if (status == 'failed' || status == 'canceled') {
             debugPrint('Vendor Payment was failed or canceled.');
             break;
          }
        }
      } catch (e) {
        debugPrint('Error polling vendor bill from DB: $e');
      }
    }
  }

  Future<void> _restoreCachedTiers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedTiers = prefs.getString(_tiersCacheKey);
      if (cachedTiers == null) return;

      _tiers = (jsonDecode(cachedTiers) as List)
          .map((json) => SubscriptionTierModel.fromJson(
                Map<String, dynamic>.from(json as Map),
              ))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to restore subscription tier cache: $e');
    }
  }

  Future<void> _cacheTiers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _tiersCacheKey,
        jsonEncode(_tiers.map((tier) => tier.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Failed to cache subscription tiers: $e');
    }
  }

  // --- Feature Gates based on Tier ---

  int get maxListings {
    final limit = _currentTier?.limits['max_listings'] ??
        _currentTier?.limits['listings'];
    if (limit is num) return limit.toInt();
    return int.tryParse(limit?.toString() ?? '') ?? 0;
  }

  bool get canUsePromoTools {
    return _currentTier?.limits['promo_tools'] == true;
  }

  bool get canAccessAnalytics {
    return _currentTier?.limits['analytics'] == true;
  }

  bool get canExportLeads {
    return _currentTier?.limits['export_leads'] == true;
  }

  double get commissionRate {
    final rate = _currentTier?.limits['commission_rate_percent'];
    if (rate is num) return rate / 100;
    return double.tryParse(rate?.toString() ?? '') != null
        ? double.parse(rate.toString()) / 100
        : 0.0;
  }
}
