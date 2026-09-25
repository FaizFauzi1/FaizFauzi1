import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DisputeEvidence {
  final String id;
  final String evidenceType;
  final String title;
  final String? content;
  final DateTime createdAt;

  const DisputeEvidence({
    required this.id,
    required this.evidenceType,
    required this.title,
    this.content,
    required this.createdAt,
  });

  factory DisputeEvidence.fromJson(Map<String, dynamic> json) => DisputeEvidence(
        id: json['id'] as String,
        evidenceType: json['evidence_type'] as String,
        title: json['title'] as String,
        content: json['content'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class AdminDispute {
  final String id;
  final String caseId;
  final String parties;
  final String status;
  final String severity;
  final String? comments;
  final String? notes;
  final String? adminDecision;
  final double? refundAmount;
  final String? refundStatus;
  final DateTime createdAt;
  final List<DisputeEvidence> evidence;

  const AdminDispute({
    required this.id,
    required this.caseId,
    required this.parties,
    required this.status,
    required this.severity,
    this.comments,
    this.notes,
    this.adminDecision,
    this.refundAmount,
    this.refundStatus,
    required this.createdAt,
    this.evidence = const [],
  });

  factory AdminDispute.fromJson(Map<String, dynamic> json) => AdminDispute(
        id: json['id'] as String,
        caseId: json['case_id'] as String,
        parties: json['parties_involved'] as String,
        status: json['status'] as String? ?? 'open',
        severity: json['severity'] as String? ?? 'medium',
        comments: json['comments'] as String?,
        notes: json['notes'] as String?,
        adminDecision: json['admin_decision'] as String?,
        refundAmount: (json['refund_amount'] as num?)?.toDouble(),
        refundStatus: json['refund_status'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Admin dispute management with evidence and refunds.
class AdminDisputesProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<AdminDispute> _disputes = [];
  AdminDispute? _selected;
  bool _isLoading = false;

  List<AdminDispute> get disputes => _disputes;
  AdminDispute? get selected => _selected;
  bool get isLoading => _isLoading;

  Future<void> fetchDisputes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('admin_disputes')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      _disputes = (response as List).map((e) => AdminDispute.fromJson(e)).toList();
    } catch (e) {
      _disputes = _mockDisputes();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDisputeDetail(String disputeId) async {
    try {
      var dispute = await _supabase
          .from('admin_disputes')
          .select()
          .eq('id', disputeId)
          .maybeSingle();
      dispute ??= await _supabase
          .from('admin_disputes')
          .select()
          .eq('case_id', disputeId)
          .maybeSingle();
      if (dispute == null) throw Exception('Not found');

      final id = dispute['id'] as String;
      final evidence = await _supabase
          .from('dispute_evidence')
          .select()
          .eq('dispute_id', id)
          .order('created_at');
      _selected = AdminDispute.fromJson(dispute).copyWithEvidence(
        (evidence as List).map((e) => DisputeEvidence.fromJson(e)).toList(),
      );
    } catch (e) {
      _selected = _disputes
              .where((d) => d.id == disputeId || d.caseId == disputeId)
              .firstOrNull ??
          _mockDisputes().first;
    }
    notifyListeners();
  }

  Future<void> createDispute({
    required String parties,
    required String disputeType,
    String severity = 'medium',
    String? comments,
    String? customerId,
    String? vendorId,
  }) async {
    final caseId = 'D-${DateTime.now().millisecondsSinceEpoch}';
    try {
      await _supabase.from('admin_disputes').insert({
        'case_id': caseId,
        'parties_involved': parties,
        'dispute_type': disputeType,
        'severity': severity,
        'comments': comments,
        'customer_id': customerId,
        'vendor_id': vendorId,
        'status': 'open',
      });
      await fetchDisputes();
    } catch (e) {
      _disputes.insert(0, AdminDispute(
        id: caseId,
        caseId: caseId,
        parties: parties,
        status: 'open',
        severity: severity,
        comments: comments,
        createdAt: DateTime.now(),
      ));
      notifyListeners();
    }
  }

  Future<void> resolveDispute(String disputeId, {String? decision, double? refundAmount}) async {
    try {
      await _supabase.from('admin_disputes').update({
        'status': 'resolved',
        'admin_decision': decision,
        'refund_amount': refundAmount,
        'refund_status': refundAmount != null ? 'pending' : 'none',
        'resolved_by': _supabase.auth.currentUser?.id,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', disputeId);

      if (refundAmount != null && refundAmount > 0) {
        await _supabase.from('admin_refunds').insert({
          'dispute_id': disputeId,
          'amount': refundAmount,
          'status': 'pending',
          'reason': decision,
        });
      }
      await fetchDisputes();
    } catch (e) {
      debugPrint('Resolve dispute failed: $e');
    }
  }

  Future<void> addEvidence(String disputeId, String type, String title, String content) async {
    try {
      await _supabase.from('dispute_evidence').insert({
        'dispute_id': disputeId,
        'evidence_type': type,
        'title': title,
        'content': content,
      });
      await loadDisputeDetail(disputeId);
    } catch (e) {
      debugPrint('Add evidence failed: $e');
    }
  }

  Future<void> processRefund(String refundId) async {
    try {
      await _supabase.from('admin_refunds').update({
        'status': 'processed',
        'processed_by': _supabase.auth.currentUser?.id,
        'processed_at': DateTime.now().toIso8601String(),
      }).eq('id', refundId);
    } catch (e) {
      debugPrint('Process refund failed: $e');
    }
  }

  List<AdminDispute> _mockDisputes() => [
        AdminDispute(
          id: 'mock-1',
          caseId: 'D-001',
          parties: 'Sarah (Customer) vs Lumina Studio (Vendor)',
          status: 'open',
          severity: 'high',
          comments: 'Vendor no-show at wedding',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          evidence: [
            DisputeEvidence(
              id: 'e1',
              evidenceType: 'chat',
              title: 'Chat transcript excerpt',
              content: 'Customer: Where are you? It\'s 2pm...',
              createdAt: DateTime.now().subtract(const Duration(hours: 20)),
            ),
            DisputeEvidence(
              id: 'e2',
              evidenceType: 'payment',
              title: 'Deposit payment',
              content: 'RM 3,000 deposit paid on 2026-01-15',
              createdAt: DateTime.now().subtract(const Duration(hours: 18)),
            ),
          ],
        ),
      ];
}

extension _AdminDisputeCopy on AdminDispute {
  AdminDispute copyWithEvidence(List<DisputeEvidence> evidence) => AdminDispute(
        id: id,
        caseId: caseId,
        parties: parties,
        status: status,
        severity: severity,
        comments: comments,
        notes: notes,
        adminDecision: adminDecision,
        refundAmount: refundAmount,
        refundStatus: refundStatus,
        createdAt: createdAt,
        evidence: evidence,
      );
}
