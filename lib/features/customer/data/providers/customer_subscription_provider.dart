import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/core/services/payment_service.dart';
import 'package:eventease/core/config/billplz_config.dart';
import 'package:eventease/shared/models/payment.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eventease/features/customer/data/models/customer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerSubscriptionProvider extends ChangeNotifier {
  String? _userId;
  String _currentTier = 'free';
  DateTime? _expiryDate;
  bool _isLoading = false;

  String get currentTier => _currentTier;
  DateTime? get expiryDate => _expiryDate;
  bool get isLoading => _isLoading;
  bool get isPremium => _currentTier != 'free';

  // Fallback defaults, will be overwritten by DB fetch if available
  Map<String, dynamic> _plans = {
    'free': {
      'name': 'Free Member',
      'price': 0.0,
      'currency': 'RM',
      'duration': 'Forever',
      'benefits': [
        'Browse and favorite items',
        'Book standard packages',
        'Chat with vendors (Standard response time)',
      ]
    },
    'wedding_pass': {
      'name': 'Wedding Planner Pass',
      'price': 99.00,
      'currency': 'RM',
      'duration': 'One-time fee (Lifetime access)',
      'benefits': [
        'Advanced Planning Tools (Budget tracker, Checklist, Seating chart)',
        'Tentative Booking (Hold dates for 72h)',
        'Exclusive Discounts (10% off selected vendors/packages)',
        'Priority Matchmaking (Get quotes faster)',
        'Priority Matchmaking (Get quotes faster)',
        'Premium Support',
      ]
    },
    'wedding_pass_trial': {
      'name': 'Wedding Planner Pass (7-Day Trial)',
      'price': 0.0,
      'currency': 'RM',
      'duration': '7 Days',
      'benefits': [
        'All Wedding Planner Pass benefits for 7 days',
        'Advanced Planning Tools',
        'Tentative Booking',
        'Exclusive Discounts',
      ]
    }
  };

  Map<String, dynamic> get plans => _plans;

  CustomerSubscriptionProvider() {
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    try {
      final response = await SupabaseService.select(
        table: 'subscription_tiers',
        filters: {'target_audience': 'customer', 'is_active': true},
      );
      
      for (final tier in response) {
        final nameId = tier['name'] as String;
        _plans[nameId] = {
          'name': tier['display_name'] ?? nameId,
          'price': (tier['price'] as num).toDouble(),
          'currency': 'RM',
          'duration': tier['billing_cycle'] ?? 'Lifetime',
          'benefits': List<String>.from(tier['features'] ?? []),
        };
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching customer plans: $e');
    }
  }
  
  // Explicit getter for checking access
  bool get hasWeddingPass => _currentTier == 'wedding_pass' || _currentTier == 'wedding_pass_trial';
  bool get isTrial => _currentTier == 'wedding_pass_trial';

  void updateUserId(String? userId) {
    _userId = userId;
    if (_userId != null) {
      loadSubscription();
    } else {
      _currentTier = 'free';
      _expiryDate = null;
      notifyListeners();
    }
  }

  Future<void> loadSubscription() async {
    if (_userId == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();

      // Check customer_user table
      final response = await SupabaseService.select(
        table: 'customer_user',
        filters: {'id': _userId},
        columns: 'subscription_tier, subscription_expiry',
      );

      if (response.isNotEmpty) {
        final data = response.first;
        _currentTier = data['subscription_tier'] ?? 'free';
        _expiryDate = data['subscription_expiry'] != null 
          ? DateTime.parse(data['subscription_expiry']) 
          : null;
        
        // Check expiry
        if (_expiryDate != null && DateTime.now().isAfter(_expiryDate!)) {
          _currentTier = 'free'; // Downgrade if expired
          // Ideally update DB here too, but for UI sync this is enough
        }
      }
    } catch (e) {
      debugPrint('Error loading subscription: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> upgradeSubscription(
    String tier, {
    PaymentGatewayProvider gateway = PaymentGatewayProvider.xendit,
    String currency = 'MYR',
  }) async {
    if (_userId == null) return null;
    
    try {
      _isLoading = true;
      notifyListeners();

      // Get plan details
      final planDetails = _plans[tier];
      if (planDetails == null) throw Exception('Invalid billing tier');
      
      final price = planDetails['price'] as double;
      // Free plans don't need payment processing
      if (price == 0.0) {
          // Free plan logic if downgrading
          await SupabaseService.update(
            table: 'customer_user', 
            data: {
              'subscription_tier': tier,
              'subscription_expiry': null,
              'updated_at': DateTime.now().toIso8601String(),
            },
            column: 'id',
            value: _userId,
          );
          _currentTier = tier;
          _expiryDate = null;
          return "success";
      }

      // Fetch user email/details for the payment gateway
      final userResponse = await SupabaseService.select(
        table: 'customer_user',
        filters: {'id': _userId},
        columns: 'email, name',
      );
      
      final String email = userResponse.isNotEmpty ? (userResponse.first['email'] ?? 'customer@example.com') : 'customer@example.com';
      final String name = userResponse.isNotEmpty ? (userResponse.first['name'] ?? 'Customer') : 'Customer';

      final String? paymentUrl;

      if (gateway == PaymentGatewayProvider.xendit) {
        final String callbackConfig = dotenv.env['PAYMENT_CALLBACK_URL'] ?? 'https://eventease-web.netlify.app/payment/callback';
        final String redirectUrl = kIsWeb ? Uri.base.toString() : callbackConfig;
        final result = await PaymentService.createXenditInvoice(
          email: email,
          name: name,
          amount: price,
          currency: currency,
          externalId: 'cust_${_userId}_${DateTime.now().millisecondsSinceEpoch}',
          description: 'Membership Upgrade to ${planDetails['name']}',
          redirectUrl: redirectUrl,
          metadata: {
            'type': 'membership_upgrade',
            'customer_id': _userId,
            'tier': tier,
          },
        );
        paymentUrl = result['invoice_url'] ?? result['url'];
      } else {
        // Generate Payment URL using existing PaymentService which routes to Billplz Edge Function
        final String callbackConfig = dotenv.env['PAYMENT_CALLBACK_URL'] ?? 'https://eventease-web.netlify.app/payment/callback';
        final result = await PaymentService.createBill(
           collectionId: BillplzConfig.collectionId, // Using the configured Billplz collection ID
           email: email,
           mobile: '0123456789', // Replace if you store customer phone numbers
           name: name,
           amount: price,
           callbackUrl: callbackConfig,
           description: 'Membership Upgrade to ${planDetails['name']}',
           metadata: {
             'type': 'membership_upgrade',
             'customer_id': _userId,
             'tier': tier,
           }
        );
        paymentUrl = result['url'];
      }

      return paymentUrl;
      
    } catch (e) {
      debugPrint('Error upgrading subscription: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startFreeTrial() async {
    if (_userId == null) return false;
    
    try {
      _isLoading = true;
      notifyListeners();

      // Check if user already used a trial (could implement a check table later)
      // For now, just allow if currently 'free'
      if (_currentTier != 'free') return false;

      final expiryDate = DateTime.now().add(const Duration(days: 7));
      
      await SupabaseService.update(
        table: 'customer_user', 
        data: {
          'subscription_tier': 'wedding_pass_trial',
          'subscription_expiry': expiryDate.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        column: 'id',
        value: _userId,
      );

      _currentTier = 'wedding_pass_trial';
      _expiryDate = expiryDate;
      return true;
      
    } catch (e) {
      debugPrint('Error starting trial: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Poll Billplz or Xendit for payment status (useful when returning from external browser)
  void startPollingBill(String billId, String tier, {PaymentGatewayProvider gateway = PaymentGatewayProvider.xendit}) async {
    if (_userId == null) return;
    
    int attempts = 0;
    const maxAttempts = 20; // Poll for about 1 minute (every 3s)
    
    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(seconds: 3));
      attempts++;
      
      try {
        bool isPaid = false;
        bool isFailed = false;

        if (gateway == PaymentGatewayProvider.xendit) {
          final invoiceDetails = await PaymentService.getXenditInvoice(billId);
          final status = invoiceDetails['status'] as String?;
          if (status == 'PAID' || status == 'SETTLED') {
            isPaid = true;
          } else if (status == 'EXPIRED') {
            isFailed = true;
          }
        } else {
          final billDetails = await PaymentService.getBill(billId);
          isPaid = billDetails['paid'] == true;
          if (billDetails['state'] == 'deleted' || billDetails['state'] == 'canceled') {
            isFailed = true;
          }
        }
        
        if (isPaid) {
          // Update database
          await SupabaseService.update(
            table: 'customer_user', 
            data: {
              'subscription_tier': tier,
              'subscription_expiry': null,
              'updated_at': DateTime.now().toIso8601String(),
            },
            column: 'id',
            value: _userId,
          );
          
          // Update local state
          _currentTier = tier;
          _expiryDate = null;
          notifyListeners();
          
          debugPrint('Payment successful! Membership updated to $tier');
          break; // Stop polling
        } else if (isFailed) {
           debugPrint('Payment was canceled or failed.');
           break;
        }
      } catch (e) {
        debugPrint('Error polling bill: $e');
      }
    }
  }
}
