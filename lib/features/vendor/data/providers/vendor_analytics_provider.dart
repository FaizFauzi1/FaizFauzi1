import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';

class VendorAnalyticsProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _analyticsData;
  List<Map<String, dynamic>> _revenueData = [];
  List<Map<String, dynamic>> _customerData = [];
  List<Map<String, dynamic>> _performanceMetrics = [];
  List<Map<String, dynamic>> _funnelStages = [];
  List<Map<String, dynamic>> _actionableInsights = [];
  Map<String, dynamic> _impressionsAndViews = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get analyticsData => _analyticsData;
  List<Map<String, dynamic>> get revenueData => _revenueData;
  List<Map<String, dynamic>> get customerData => _customerData;
  List<Map<String, dynamic>> get performanceMetrics => _performanceMetrics;
  List<Map<String, dynamic>> get funnelStages => _funnelStages;
  List<Map<String, dynamic>> get actionableInsights => _actionableInsights;
  Map<String, dynamic> get impressionsAndViews => _impressionsAndViews;

  String _selectedPeriod = 'Last 30 Days';
  String _selectedMetric = 'Revenue';

  String get selectedPeriod => _selectedPeriod;
  String get selectedMetric => _selectedMetric;

  void updatePeriod(String period) {
    _selectedPeriod = period;
    loadAnalyticsData();
  }

  void updateMetric(String metric) {
    _selectedMetric = metric;
    notifyListeners();
  }

  /// Load analytics data for current vendor or impersonated vendor
  Future<void> loadAnalyticsData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final effectiveTarget = AdminImpersonationService.instance.isImpersonating
          ? AdminImpersonationService.instance.impersonatingUserId
          : _supabase.auth.currentUser?.id;

      if (effectiveTarget == null) {
        _setDefaultData();
        return;
      }

      // Get vendor profile ID (try user_id first, then fallback to id)
      var vendorProfile = await _supabase
          .from('vendor_profiles')
          .select('id')
          .eq('user_id', effectiveTarget)
          .maybeSingle();

      if (vendorProfile == null) {
        vendorProfile = await _supabase
            .from('vendor_profiles')
            .select('id')
            .eq('id', effectiveTarget)
            .maybeSingle();
      }

      if (vendorProfile == null) {
        _setDefaultData();
        return;
      }

      final vendorId = vendorProfile['id'];

      // Calculate date range based on selected period
      final dateRange = _getDateRange(_selectedPeriod);
      final startDate = dateRange['start']!;
      final endDate = dateRange['end']!;

      // Load analytics data from database
      await _loadRevenueData(vendorId, startDate, endDate);
      await _loadCustomerData(vendorId, startDate, endDate);
      await _loadPerformanceMetrics(vendorId, startDate, endDate);

      // Aggregate analytics data
      _analyticsData = await _aggregateAnalyticsData(vendorId, startDate, endDate);

    } catch (e) {
      _error = 'Failed to load analytics data: $e';
      _setDefaultData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRevenueData(String vendorId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _supabase
          .from('vendor_analytics')
          .select('date, total_revenue, total_orders')
          .eq('vendor_id', vendorId)
          .gte('date', DateFormat('yyyy-MM-dd').format(startDate))
          .lte('date', DateFormat('yyyy-MM-dd').format(endDate))
          .order('date');

      if (response.isNotEmpty) {
        _revenueData = List<Map<String, dynamic>>.from(response.map((item) {
          final date = DateTime.parse(item['date']);
          return {
            'month': DateFormat('MMM').format(date),
            'revenue': item['total_revenue'] ?? 0,
            'bookings': item['total_orders'] ?? 0,
          };
        }));
        return;
      }

      // Fallback: Query bookings table directly from Supabase
      final bookingRows = await _supabase
          .from('bookings')
          .select('amount, created_at, status')
          .eq('vendor_id', vendorId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      if (bookingRows.isNotEmpty) {
        final Map<String, Map<String, dynamic>> monthlyAgg = {};
        for (final row in bookingRows) {
          final createdAt = DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now();
          final monthKey = DateFormat('MMM').format(createdAt);
          final amt = (row['amount'] as num?)?.toDouble() ?? 0.0;
          
          if (!monthlyAgg.containsKey(monthKey)) {
            monthlyAgg[monthKey] = {'month': monthKey, 'revenue': 0.0, 'bookings': 0};
          }
          monthlyAgg[monthKey]!['revenue'] = (monthlyAgg[monthKey]!['revenue'] as double) + amt;
          monthlyAgg[monthKey]!['bookings'] = (monthlyAgg[monthKey]!['bookings'] as int) + 1;
        }
        _revenueData = monthlyAgg.values.toList();
      } else {
        _revenueData = _generateEmptyRevenueData();
      }
    } catch (e) {
      _revenueData = _generateEmptyRevenueData();
    }
  }

  Future<void> _loadCustomerData(String vendorId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _supabase
          .from('vendor_analytics')
          .select('customer_segments')
          .eq('vendor_id', vendorId)
          .gte('date', DateFormat('yyyy-MM-dd').format(startDate))
          .lte('date', DateFormat('yyyy-MM-dd').format(endDate))
          .not('customer_segments', 'is', null);

      if (response.isNotEmpty) {
        final aggregatedSegments = <String, Map<String, dynamic>>{};
        for (final item in response) {
          final segments = item['customer_segments'] as List<dynamic>?;
          if (segments != null) {
            for (final segment in segments) {
              final segmentName = segment['segmentName'] ?? 'Unknown';
              if (!aggregatedSegments.containsKey(segmentName)) {
                aggregatedSegments[segmentName] = {
                  'segment': segmentName,
                  'count': 0,
                  'percentage': 0.0,
                };
              }
              aggregatedSegments[segmentName]!['count'] += segment['customerCount'] ?? 0;
            }
          }
        }
        final totalCustomers = aggregatedSegments.values.fold<int>(0, (sum, seg) => sum + (seg['count'] as int));
        _customerData = aggregatedSegments.values.map((seg) {
          return {
            'segment': seg['segment'],
            'count': seg['count'],
            'percentage': totalCustomers > 0 ? ((seg['count'] / totalCustomers) * 100) : 0.0,
          };
        }).toList();
        return;
      }

      // Fallback: Group bookings by customer IDs from Supabase
      final customerRows = await _supabase
          .from('bookings')
          .select('user_id, customer_name')
          .eq('vendor_id', vendorId);

      if (customerRows.isNotEmpty) {
        final total = customerRows.length;
        final uniqueCustomers = customerRows.map((r) => r['user_id'] ?? r['customer_name']).toSet().length;
        _customerData = [
          {'segment': 'New Clients', 'count': uniqueCustomers, 'percentage': (uniqueCustomers / total * 100).clamp(0, 100)},
          {'segment': 'Repeat Clients', 'count': total - uniqueCustomers, 'percentage': ((total - uniqueCustomers) / total * 100).clamp(0, 100)},
        ];
      } else {
        _customerData = _generateEmptyCustomerData();
      }
    } catch (e) {
      _customerData = _generateEmptyCustomerData();
    }
  }

  Future<void> _loadPerformanceMetrics(String vendorId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _supabase
          .from('vendor_performance_metrics')
          .select()
          .eq('vendor_id', vendorId)
          .gte('period_start', DateFormat('yyyy-MM-dd').format(startDate))
          .lte('period_end', DateFormat('yyyy-MM-dd').format(endDate))
          .order('period_end', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final metrics = response.first;
        _performanceMetrics = [
          {
            'title': 'Average Booking Value',
            'value': 'RM ${(metrics['average_order_value'] ?? 412).toStringAsFixed(0)}',
            'change': _calculateChange(metrics, 'average_order_value'),
            'trend': 'up',
            'icon': Icons.attach_money,
            'color': const Color(0xFF4CAF50),
          },
          {
            'title': 'Customer Satisfaction',
            'value': '${((metrics['customer_satisfaction'] ?? 4.8) * 20).toStringAsFixed(0)}/5',
            'change': '+${((metrics['customer_satisfaction'] ?? 4.8) * 2).toStringAsFixed(1)}',
            'trend': 'up',
            'icon': Icons.star,
            'color': const Color(0xFFFF9800),
          },
          {
            'title': 'Booking Conversion',
            'value': '${(metrics['conversion_rate'] ?? 24.5).toStringAsFixed(1)}%',
            'change': _calculateChange(metrics, 'conversion_rate', isPercentage: true),
            'trend': 'down',
            'icon': Icons.trending_up,
            'color': const Color(0xFF2196F3),
          },
          {
            'title': 'Repeat Business',
            'value': '${(metrics['repeat_business_rate'] ?? 68).toStringAsFixed(0)}%',
            'change': '+${(metrics['repeat_business_rate'] ?? 68) * 0.1}%',
            'trend': 'up',
            'icon': Icons.refresh,
            'color': const Color(0xFF9C27B0),
          },
        ];
        return;
      }

      // Calculate directly from Supabase bookings & reviews
      final bookings = await _supabase.from('bookings').select('amount, status').eq('vendor_id', vendorId);
      final reviews = await _supabase.from('service_reviews').select('rating').eq('vendor_id', vendorId);

      double avgOrderVal = 0.0;
      if (bookings.isNotEmpty) {
        final totalAmount = bookings.fold<double>(0, (sum, b) => sum + ((b['amount'] as num?)?.toDouble() ?? 0));
        avgOrderVal = totalAmount / bookings.length;
      }

      double avgRating = 4.8;
      if (reviews.isNotEmpty) {
        final totalRating = reviews.fold<double>(0, (sum, r) => sum + ((r['rating'] as num?)?.toDouble() ?? 5.0));
        avgRating = totalRating / reviews.length;
      }

      final confirmedCount = bookings.where((b) => b['status'] == 'confirmed' || b['status'] == 'completed').length;
      final conversionRate = bookings.isNotEmpty ? (confirmedCount / bookings.length * 100) : 0.0;

      _performanceMetrics = [
        {
          'title': 'Average Booking Value',
          'value': avgOrderVal > 0 ? 'RM ${avgOrderVal.toStringAsFixed(0)}' : '—',
          'change': bookings.isNotEmpty ? '${bookings.length} bookings total' : 'No bookings yet',
          'trend': 'up',
          'icon': Icons.attach_money,
          'color': const Color(0xFF4CAF50),
        },
        {
          'title': 'Customer Satisfaction',
          'value': reviews.isNotEmpty ? '${avgRating.toStringAsFixed(1)} / 5.0' : '—',
          'change': reviews.isNotEmpty ? 'Based on ${reviews.length} review${reviews.length == 1 ? '' : 's'}' : 'No reviews yet',
          'trend': 'up',
          'icon': Icons.star,
          'color': const Color(0xFFFF9800),
        },
        {
          'title': 'Booking Conversion',
          'value': bookings.isNotEmpty ? '${conversionRate.toStringAsFixed(1)}%' : '—',
          'change': bookings.isNotEmpty ? '$confirmedCount of ${bookings.length} confirmed' : 'No bookings yet',
          'trend': 'up',
          'icon': Icons.trending_up,
          'color': const Color(0xFF2196F3),
        },
        {
          'title': 'Total Bookings',
          'value': '${bookings.length}',
          'change': bookings.isNotEmpty ? 'All time' : 'No bookings yet',
          'trend': 'up',
          'icon': Icons.book_online,
          'color': const Color(0xFF9C27B0),
        },
      ];
    } catch (e) {
      _performanceMetrics = _generateEmptyPerformanceMetrics();
    }
  }

  Future<Map<String, dynamic>> _aggregateAnalyticsData(String vendorId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _supabase.rpc('get_vendor_analytics_aggregated', params: {
        'vendor_uuid': vendorId,
        'start_date': DateFormat('yyyy-MM-dd').format(startDate),
        'end_date': DateFormat('yyyy-MM-dd').format(endDate),
      });

      if (response != null) {
        return Map<String, dynamic>.from(response);
      }
    } catch (e) {
      // Aggregate from Supabase bookings table
      try {
        final bookingRows = await _supabase
            .from('bookings')
            .select('amount, user_id, status')
            .eq('vendor_id', vendorId);

        if (bookingRows.isNotEmpty) {
          double totalRevenue = 0;
          final uniqueCustomers = <String>{};
          for (final item in bookingRows) {
            totalRevenue += ((item['amount'] as num?)?.toDouble() ?? 0);
            if (item['user_id'] != null) {
              uniqueCustomers.add(item['user_id'].toString());
            }
          }
          return {
            'total_revenue': totalRevenue,
            'total_orders': bookingRows.length,
            'unique_customers': uniqueCustomers.length,
            'average_order_value': bookingRows.isNotEmpty ? totalRevenue / bookingRows.length : 0,
          };
        }
      } catch (_) {}
    }

    return _generateEmptyAggregatedData();
  }

  Map<String, DateTime> _getDateRange(String period) {
    final now = DateTime.now();
    DateTime startDate;

    switch (period) {
      case 'Last 7 Days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Last 30 Days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'Last 6 Months':
        startDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case 'Last Year':
        startDate = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        startDate = now.subtract(const Duration(days: 30));
    }

    return {'start': startDate, 'end': now};
  }

  String _calculateChange(Map<String, dynamic> metrics, String field, {bool isPercentage = false}) {
    // Simplified change calculation - in real app, compare with previous period
    final value = metrics[field] ?? 0;
    final change = value * 0.08; // 8% change for demo
    final sign = change >= 0 ? '+' : '';
    final formattedChange = isPercentage ? '${change.toStringAsFixed(1)}%' : change.toStringAsFixed(1);
    return '$sign$formattedChange';
  }

  List<Map<String, dynamic>> _generateEmptyRevenueData() {
    // Returns empty list — screens should show a "No data yet" empty state
    return [];
  }

  List<Map<String, dynamic>> _generateEmptyCustomerData() {
    // Returns empty list — screens should show a "No customer data yet" empty state
    return [];
  }

  List<Map<String, dynamic>> _generateEmptyPerformanceMetrics() {
    return [
      {
        'title': 'Average Booking Value',
        'value': '—',
        'change': 'No bookings yet',
        'trend': 'neutral',
        'icon': Icons.attach_money,
        'color': const Color(0xFF4CAF50),
      },
      {
        'title': 'Customer Rating',
        'value': '—',
        'change': 'No reviews yet',
        'trend': 'neutral',
        'icon': Icons.star,
        'color': const Color(0xFFFF9800),
      },
      {
        'title': 'Booking Conversion',
        'value': '—',
        'change': 'No bookings yet',
        'trend': 'neutral',
        'icon': Icons.trending_up,
        'color': const Color(0xFF2196F3),
      },
      {
        'title': 'Total Bookings',
        'value': '0',
        'change': 'No bookings yet',
        'trend': 'neutral',
        'icon': Icons.book_online,
        'color': const Color(0xFF9C27B0),
      },
    ];
  }

  List<Map<String, dynamic>> _generateEmptyFunnelStages() {
    // Returns empty list — screens should show an "Analytics data will appear here" empty state
    return [];
  }

  List<Map<String, dynamic>> _generateSampleActionableInsights() {
    return [
      {
        'title': 'Optimize Quote Response Time',
        'description': 'Quotes submitted within 2 hours have a 78% win rate compared to 34% after 24 hours.',
        'impact': 'High Impact (+44% win rate)',
        'actionLabel': 'Setup Quick Quote Templates',
        'icon': Icons.bolt,
        'color': Colors.amber,
      },
      {
        'title': 'Add Video to Photography Catalog',
        'description': 'Listings with short highlight reels receive 2.4x more inquiries and 38% longer profile view duration.',
        'impact': 'Medium Impact (+140% inquiries)',
        'actionLabel': 'Upload Video Clip',
        'icon': Icons.video_collection,
        'color': Colors.blue,
      },
      {
        'title': 'Enable Flash Deal for Off-Peak Days',
        'description': 'Your Tuesday & Thursday booking slots are 65% open for the upcoming quarter.',
        'impact': 'High Revenue Opportunity',
        'actionLabel': 'Create Flash Deal',
        'icon': Icons.local_offer,
        'color': Colors.green,
      },
    ];
  }

  Map<String, dynamic> _generateEmptyAggregatedData() {
    return {
      'total_revenue': 0.0,
      'total_orders': 0,
      'unique_customers': 0,
      'average_order_value': 0.0,
      'repeat_business_rate': 0.0,
    };
  }

  void _setDefaultData() {
    _revenueData = _generateEmptyRevenueData();
    _customerData = _generateEmptyCustomerData();
    _performanceMetrics = _generateEmptyPerformanceMetrics();
    _analyticsData = _generateEmptyAggregatedData();
    _funnelStages = _generateEmptyFunnelStages();
    _actionableInsights = _generateSampleActionableInsights();
    _impressionsAndViews = {
      'impressions': 0,
      'impressions_growth': '—',
      'profile_views': 0,
      'profile_views_growth': '—',
      'inquiries': 0,
      'inquiries_growth': '—',
      'quotes': 0,
      'quotes_growth': '—',
    };
  }

  /// Export analytics report
  Future<void> exportAnalyticsReport() async {
    // In a real implementation, this would generate a PDF or Excel report
    // For now, just show a message
    _error = 'Export functionality will be implemented soon';
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
