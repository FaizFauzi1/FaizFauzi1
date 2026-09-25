import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VendorChurnSnapshot {
  final String id;
  final String vendorId;
  final int profileViews;
  final int inquiries;
  final int bookings;
  final double revenue;
  final int daysInactive;
  final double riskScore;
  final String riskLevel;
  final String? retentionAction;
  final String outreachStatus;
  final DateTime snapshotDate;

  const VendorChurnSnapshot({
    required this.id,
    required this.vendorId,
    required this.profileViews,
    required this.inquiries,
    required this.bookings,
    required this.revenue,
    required this.daysInactive,
    required this.riskScore,
    required this.riskLevel,
    this.retentionAction,
    required this.outreachStatus,
    required this.snapshotDate,
  });

  factory VendorChurnSnapshot.fromJson(Map<String, dynamic> json) => VendorChurnSnapshot(
        id: json['id'] as String,
        vendorId: json['vendor_id'] as String,
        profileViews: json['profile_views'] as int? ?? 0,
        inquiries: json['inquiries'] as int? ?? 0,
        bookings: json['bookings'] as int? ?? 0,
        revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
        daysInactive: json['days_inactive'] as int? ?? 0,
        riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0,
        riskLevel: json['risk_level'] as String? ?? 'low',
        retentionAction: json['retention_action'] as String?,
        outreachStatus: json['outreach_status'] as String? ?? 'none',
        snapshotDate: DateTime.parse(json['snapshot_date'] as String),
      );
}

class AdminAnnouncement {
  final String id;
  final String? title;
  final String message;
  final String audience;
  final String channel;
  final bool pinned;
  final DateTime? scheduledAt;
  final String status;
  final DateTime createdAt;

  const AdminAnnouncement({
    required this.id,
    this.title,
    required this.message,
    required this.audience,
    required this.channel,
    required this.pinned,
    this.scheduledAt,
    required this.status,
    required this.createdAt,
  });

  factory AdminAnnouncement.fromJson(Map<String, dynamic> json) => AdminAnnouncement(
        id: json['id'] as String,
        title: json['title'] as String?,
        message: json['message'] as String,
        audience: json['audience'] as String? ?? 'all',
        channel: json['channel'] as String? ?? 'in_app',
        pinned: json['pinned'] as bool? ?? false,
        scheduledAt: json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at']) : null,
        status: json['status'] as String? ?? 'draft',
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Churn detection and broadcast scheduling for admin.
class AdminChurnProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<VendorChurnSnapshot> _atRiskVendors = [];
  List<AdminAnnouncement> _announcements = [];
  bool _isLoading = false;

  List<VendorChurnSnapshot> get atRiskVendors => _atRiskVendors;
  List<AdminAnnouncement> get announcements => _announcements;
  bool get isLoading => _isLoading;

  int get criticalCount => _atRiskVendors.where((v) => v.riskLevel == 'critical').length;
  int get highCount => _atRiskVendors.where((v) => v.riskLevel == 'high').length;

  Future<void> fetchAtRiskVendors() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('vendor_churn_snapshots')
          .select()
          .inFilter('risk_level', ['high', 'critical', 'medium'])
          .order('risk_score', ascending: false)
          .limit(50);
      _atRiskVendors = (response as List).map((e) => VendorChurnSnapshot.fromJson(e)).toList();
    } catch (e) {
      _atRiskVendors = _mockChurn();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAnnouncements() async {
    try {
      final response = await _supabase
          .from('admin_announcements')
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      _announcements = (response as List).map((e) => AdminAnnouncement.fromJson(e)).toList();
    } catch (e) {
      _announcements = [];
    }
    notifyListeners();
  }

  Future<void> applyRetentionAction(String snapshotId, String action) async {
    try {
      await _supabase.from('vendor_churn_snapshots').update({
        'retention_action': action,
        'outreach_status': 'contacted',
      }).eq('id', snapshotId);
      await fetchAtRiskVendors();
    } catch (e) {
      debugPrint('Retention action failed: $e');
    }
  }

  Future<void> scheduleAnnouncement({
    required String message,
    required String audience,
    String channel = 'in_app',
    String? title,
    DateTime? scheduledAt,
    bool sendNow = false,
  }) async {
    try {
      await _supabase.from('admin_announcements').insert({
        'title': title,
        'message': message,
        'audience': audience,
        'channel': channel,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'status': sendNow ? 'sent' : (scheduledAt != null ? 'scheduled' : 'draft'),
        'sent_at': sendNow ? DateTime.now().toIso8601String() : null,
        'created_by': _supabase.auth.currentUser?.id,
      });
      await fetchAnnouncements();
    } catch (e) {
      debugPrint('Schedule announcement failed: $e');
    }
  }

  List<VendorChurnSnapshot> _mockChurn() => [
        VendorChurnSnapshot(
          id: 'c1',
          vendorId: 'vendor_001',
          profileViews: 12,
          inquiries: 0,
          bookings: 0,
          revenue: 0,
          daysInactive: 45,
          riskScore: 85,
          riskLevel: 'critical',
          outreachStatus: 'none',
          snapshotDate: DateTime.now(),
        ),
        VendorChurnSnapshot(
          id: 'c2',
          vendorId: 'vendor_002',
          profileViews: 80,
          inquiries: 2,
          bookings: 0,
          revenue: 0,
          daysInactive: 21,
          riskScore: 62,
          riskLevel: 'high',
          retentionAction: 'Profile boost offered',
          outreachStatus: 'contacted',
          snapshotDate: DateTime.now(),
        ),
      ];
}
