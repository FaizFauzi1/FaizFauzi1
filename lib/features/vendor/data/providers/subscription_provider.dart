import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<SubscriptionTierModel> _tiers = [];
  SubscriptionTierModel? _currentTier;
  List<SubscriptionPayment> _payments = [];
  int _servicesCount = 0;
  int _bookingsCount = 0;
  String _visibilityLevel = 'Standard';
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
      // 1. Load Tiers
      final tiersData = await _supabase
          .from('subscription_tiers')
          .select()
          .eq('is_active', true)
          .eq('target_audience', 'vendor')
          .order('sort_order');
      _tiers = (tiersData as List).map((json) => SubscriptionTierModel.fromJson(json)).toList();

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
      String tierName = vendorData['subscription_tier'] ?? 'Starter';
      
      if (latestPaid != null) {
        // Find tier by ID
        final latestTier = _tiers.firstWhereOrNull((t) => t.id == latestPaid.tierId);
        if (latestTier != null && latestTier.name.toLowerCase() != tierName.toLowerCase()) {
          // Sync database because webhook couldn't do it
          tierName = latestTier.name;
          await _supabase.from('vendor_profiles').update({'subscription_tier': tierName}).eq('id', vendorId);
        }
      }

      _currentTier = _tiers.firstWhere(
        (t) => t.name.toLowerCase() == tierName.toLowerCase(),
        orElse: () => _tiers.isNotEmpty ? _tiers.first : _getDefaultFreeTier(),
      );

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
      final activeTierName = _currentTier?.name.toLowerCase() ?? 'starter';
      if (activeTierName == 'business') {
        _visibilityLevel = 'Highest (Top Priority)';
      } else if (activeTierName == 'pro') {
        _visibilityLevel = 'High (Featured)';
      } else {
        _visibilityLevel = 'Standard';
      }

    } catch (e) {
      print('Error loading subscription data: $e');
      _error = 'Failed to load subscription information';
      // Fallback if tiers failed to load
      if (_tiers.isEmpty) {
        _tiers = _getFallbackTiers();
      }
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

  SubscriptionTierModel _getDefaultFreeTier() {
    return SubscriptionTierModel(
      id: 'starter_id',
      name: 'Starter',
      displayName: 'Starter Plan',
      price: 0,
      billingCycle: 'Monthly',
      features: ['List 3 services/packages', 'Basic vendor profile', 'Standard search ranking', '12% Commission'],
      limits: {'listings': 3},
    );
  }

  List<SubscriptionTierModel> _getFallbackTiers() {
    return [
      _getDefaultFreeTier(),
      SubscriptionTierModel(
        id: 'pro_id',
        name: 'Pro',
        displayName: 'Pro Vendor',
        price: 49.0,
        billingCycle: 'Monthly',
        features: ['List 10 services/packages', 'Featured occasionally', 'Full portfolio gallery', 'Customer analytics', 'Promotion tools', '10% Commission'],
        limits: {'listings': 10},
        isPopular: true,
      ),
      SubscriptionTierModel(
        id: 'business_id',
        name: 'Business',
        displayName: 'Business Class',
        price: 149.0,
        billingCycle: 'Monthly',
        features: ['Unlimited listings', 'Priority "Top Rated" ranking', 'Dedicated account manager', 'CRM (Lead handling)', 'Export lead data', '7% Commission'],
        limits: {'listings': -1}, // -1 indicates unlimited
      ),
    ];
  }

  // --- Feature Gates based on Tier ---

  int get maxListings {
    if (_currentTier == null) return 3;
    
    // Check DB limits first
    if (_currentTier!.limits.containsKey('listings')) {
      final dbLimit = _currentTier!.limits['listings'];
      if (dbLimit != null) {
        if (dbLimit is int) return dbLimit;
        if (dbLimit is String && int.tryParse(dbLimit) != null) return int.parse(dbLimit);
      }
    }

    // Fallback to name/id heuristics if DB limits are missing or misconfigured
    final name = _currentTier!.name.toLowerCase();
    final id = _currentTier!.id.toLowerCase();
    
    if (name.contains('business') || name.contains('enterprise') || name.contains('premium') || 
        id.contains('business') || id.contains('enterprise') || id.contains('premium')) {
      return -1; // Unlimited
    }
    
    if (name.contains('pro') || name.contains('professional') || 
        id.contains('pro') || id.contains('professional')) {
      return 10;
    }
    
    return 3; // Default for starter/free
  }

  bool get canUsePromoTools {
    final name = _currentTier?.name.toLowerCase() ?? 'starter';
    final id = _currentTier?.id.toLowerCase() ?? 'starter';
    return name.contains('pro') || name.contains('professional') || name.contains('business') || name.contains('premium') || name.contains('enterprise') ||
           id.contains('pro') || id.contains('professional') || id.contains('business') || id.contains('premium') || id.contains('enterprise');
  }

  bool get canAccessAnalytics {
    return canUsePromoTools; // Same requirements
  }

  bool get canExportLeads {
    final name = _currentTier?.name.toLowerCase() ?? 'starter';
    final id = _currentTier?.id.toLowerCase() ?? 'starter';
    return name.contains('business') || name.contains('premium') || name.contains('enterprise') ||
           id.contains('business') || id.contains('premium') || id.contains('enterprise');
  }

  double get commissionRate {
    final name = _currentTier?.name.toLowerCase() ?? 'starter';
    final id = _currentTier?.id.toLowerCase() ?? 'starter';
    
    if (name.contains('business') || name.contains('premium') || name.contains('enterprise') ||
        id.contains('business') || id.contains('premium') || id.contains('enterprise')) {
      return 0.07;
    }
    
    if (name.contains('pro') || name.contains('professional') ||
        id.contains('pro') || id.contains('professional')) {
      return 0.10;
    }
    
    return 0.12; // Starter default
  }
}
