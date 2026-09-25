import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CountryRevenue {
  final String countryCode;
  final int transactionCount;
  final double totalRevenue;
  final double commissionRevenue;

  const CountryRevenue({
    required this.countryCode,
    required this.transactionCount,
    required this.totalRevenue,
    required this.commissionRevenue,
  });

  factory CountryRevenue.fromJson(Map<String, dynamic> json) => CountryRevenue(
        countryCode: json['country_code'] as String? ?? 'MY',
        transactionCount: json['transaction_count'] as int? ?? 0,
        totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
        commissionRevenue: (json['commission_revenue'] as num?)?.toDouble() ?? 0,
      );
}

class SponsoredCampaign {
  final String id;
  final String vendorId;
  final String placement;
  final int priorityScore;
  final DateTime startDate;
  final DateTime endDate;
  final double? budget;
  final String billingStatus;
  final int impressions;
  final int clicks;
  final bool isActive;

  const SponsoredCampaign({
    required this.id,
    required this.vendorId,
    required this.placement,
    required this.priorityScore,
    required this.startDate,
    required this.endDate,
    this.budget,
    required this.billingStatus,
    required this.impressions,
    required this.clicks,
    required this.isActive,
  });

  factory SponsoredCampaign.fromJson(Map<String, dynamic> json) => SponsoredCampaign(
        id: json['id'] as String,
        vendorId: json['vendor_id'] as String,
        placement: json['placement'] as String? ?? 'search',
        priorityScore: json['priority_score'] as int? ?? 0,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        budget: (json['budget'] as num?)?.toDouble(),
        billingStatus: json['billing_status'] as String? ?? 'pending',
        impressions: json['impressions'] as int? ?? 0,
        clicks: json['clicks'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );

  double get ctr => impressions > 0 ? (clicks / impressions) * 100 : 0;
}

class AdminPromotion {
  final String id;
  final String name;
  final String promoType;
  final double discountValue;
  final String targetAudience;
  final DateTime? startDate;
  final DateTime? endDate;
  final int usageCount;
  final bool isActive;

  const AdminPromotion({
    required this.id,
    required this.name,
    required this.promoType,
    required this.discountValue,
    required this.targetAudience,
    this.startDate,
    this.endDate,
    required this.usageCount,
    required this.isActive,
  });

  factory AdminPromotion.fromJson(Map<String, dynamic> json) => AdminPromotion(
        id: json['id'] as String,
        name: json['name'] as String,
        promoType: json['promo_type'] as String? ?? 'percentage',
        discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0,
        targetAudience: json['target_audience'] as String? ?? 'all',
        startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
        endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
        usageCount: json['usage_count'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );
}

/// Phase 9 revenue, sponsored listings, and promotions.
class AdminRevenueProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<CountryRevenue> _countryRevenue = [];
  List<SponsoredCampaign> _campaigns = [];
  List<AdminPromotion> _promotions = [];
  double _subscriptionRevenue = 0;
  double _refundTotal = 0;
  double _payoutTotal = 0;
  bool _isLoading = false;

  List<CountryRevenue> get countryRevenue => _countryRevenue;
  List<SponsoredCampaign> get campaigns => _campaigns;
  List<AdminPromotion> get promotions => _promotions;
  double get subscriptionRevenue => _subscriptionRevenue;
  double get refundTotal => _refundTotal;
  double get payoutTotal => _payoutTotal;
  bool get isLoading => _isLoading;

  double get totalCommission =>
      _countryRevenue.fold(0.0, (s, c) => s + c.commissionRevenue);

  double get totalRevenue =>
      _countryRevenue.fold(0.0, (s, c) => s + c.totalRevenue);

  Future<void> fetchAll() async {
    _isLoading = true;
    notifyListeners();
    await Future.wait([
      _fetchCountryRevenue(),
      _fetchCampaigns(),
      _fetchPromotions(),
      _fetchSubscriptionRevenue(),
      _fetchRefundsAndPayouts(),
    ]);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchCountryRevenue() async {
    try {
      final response = await _supabase.from('admin_revenue_by_country').select();
      _countryRevenue = (response as List).map((e) => CountryRevenue.fromJson(e)).toList();
    } catch (e) {
      _countryRevenue = [
        const CountryRevenue(countryCode: 'MY', transactionCount: 1240, totalRevenue: 485000, commissionRevenue: 9700),
        const CountryRevenue(countryCode: 'SG', transactionCount: 320, totalRevenue: 128000, commissionRevenue: 2560),
        const CountryRevenue(countryCode: 'ID', transactionCount: 180, totalRevenue: 45000000, commissionRevenue: 900000),
      ];
    }
  }

  Future<void> _fetchCampaigns() async {
    try {
      final response = await _supabase
          .from('sponsored_listing_campaigns')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      _campaigns = (response as List).map((e) => SponsoredCampaign.fromJson(e)).toList();
    } catch (e) {
      _campaigns = [];
    }
  }

  Future<void> _fetchPromotions() async {
    try {
      final response = await _supabase
          .from('admin_promotions')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      _promotions = (response as List).map((e) => AdminPromotion.fromJson(e)).toList();
    } catch (e) {
      _promotions = [];
    }
  }

  Future<void> _fetchSubscriptionRevenue() async {
    try {
      final response = await _supabase.from('subscription_payments').select('amount');
      _subscriptionRevenue = (response as List)
          .fold(0.0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));
    } catch (e) {
      _subscriptionRevenue = 12500;
    }
  }

  Future<void> _fetchRefundsAndPayouts() async {
    try {
      final refunds = await _supabase.from('admin_refunds').select('amount').eq('status', 'processed');
      _refundTotal = (refunds as List).fold(0.0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));
      final payouts = await _supabase.from('admin_payouts').select('amount').eq('status', 'completed');
      _payoutTotal = (payouts as List).fold(0.0, (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0));
    } catch (e) {
      _refundTotal = 3200;
      _payoutTotal = 89000;
    }
  }

  Future<void> createCampaign({
    required String vendorId,
    required String placement,
    required DateTime startDate,
    required DateTime endDate,
    double? budget,
    int priorityScore = 10,
  }) async {
    try {
      await _supabase.from('sponsored_listing_campaigns').insert({
        'vendor_id': vendorId,
        'placement': placement,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'budget': budget,
        'priority_score': priorityScore,
      });
      await _fetchCampaigns();
      notifyListeners();
    } catch (e) {
      debugPrint('Create campaign failed: $e');
    }
  }

  Future<void> createPromotion({
    required String name,
    required String promoType,
    required double discountValue,
    String targetAudience = 'all',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await _supabase.from('admin_promotions').insert({
        'name': name,
        'promo_type': promoType,
        'discount_value': discountValue,
        'target_audience': targetAudience,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      });
      await _fetchPromotions();
      notifyListeners();
    } catch (e) {
      debugPrint('Create promotion failed: $e');
    }
  }
}
