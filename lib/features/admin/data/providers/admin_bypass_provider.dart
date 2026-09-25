import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BypassIncident {
  final String id;
  final String conversationId;
  final String? senderId;
  final String? senderRole;
  final List<String> flagTypes;
  final String severity;
  final String? originalMessage;
  final String status;
  final DateTime createdAt;

  const BypassIncident({
    required this.id,
    required this.conversationId,
    this.senderId,
    this.senderRole,
    required this.flagTypes,
    required this.severity,
    this.originalMessage,
    required this.status,
    required this.createdAt,
  });

  factory BypassIncident.fromJson(Map<String, dynamic> json) => BypassIncident(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        senderId: json['sender_id'] as String?,
        senderRole: json['sender_role'] as String?,
        flagTypes: List<String>.from(json['flag_types'] ?? []),
        severity: json['severity'] as String? ?? 'medium',
        originalMessage: json['original_message'] as String?,
        status: json['status'] as String? ?? 'flagged',
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class RepeatOffender {
  final String userId;
  final int incidentCount;
  final int warningCount;
  final String riskLevel;
  final DateTime? lastIncidentAt;

  const RepeatOffender({
    required this.userId,
    required this.incidentCount,
    required this.warningCount,
    required this.riskLevel,
    this.lastIncidentAt,
  });

  factory RepeatOffender.fromJson(Map<String, dynamic> json) => RepeatOffender(
        userId: json['user_id'] as String,
        incidentCount: json['incident_count'] as int? ?? 0,
        warningCount: json['warning_count'] as int? ?? 0,
        riskLevel: json['risk_level'] as String? ?? 'low',
        lastIncidentAt: json['last_incident_at'] != null
            ? DateTime.parse(json['last_incident_at'] as String)
            : null,
      );
}

/// Admin anti-bypass monitoring and enforcement.
class AdminBypassProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<BypassIncident> _incidents = [];
  List<RepeatOffender> _offenders = [];
  bool _isLoading = false;
  String? _error;

  List<BypassIncident> get incidents => _incidents;
  List<RepeatOffender> get offenders => _offenders;
  bool get isLoading => _isLoading;

  Map<String, int> get detectionStats {
    final stats = <String, int>{
      'phoneNumber': 0,
      'email': 0,
      'whatsapp': 0,
      'externalPayment': 0,
    };
    for (final i in _incidents) {
      for (final f in i.flagTypes) {
        stats[f] = (stats[f] ?? 0) + 1;
      }
    }
    return stats;
  }

  Future<void> fetchIncidents({String? statusFilter}) async {
    _isLoading = true;
    notifyListeners();
    try {
      var query = _supabase.from('bypass_incidents').select();
      if (statusFilter != null && statusFilter != 'all') {
        query = query.eq('status', statusFilter);
      }
      final response = await query.order('created_at', ascending: false).limit(100);
      _incidents = (response as List).map((e) => BypassIncident.fromJson(e)).toList();
      _error = null;
    } catch (e) {
      _incidents = _mockIncidents();
      _error = 'Using demo data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRepeatOffenders() async {
    try {
      final response = await _supabase
          .from('repeat_offender_scores')
          .select()
          .order('incident_count', ascending: false)
          .limit(50);
      _offenders = (response as List).map((e) => RepeatOffender.fromJson(e)).toList();
    } catch (e) {
      _offenders = [];
    }
    notifyListeners();
  }

  Future<void> reviewIncident(String incidentId, String newStatus) async {
    try {
      await _supabase.from('bypass_incidents').update({
        'status': newStatus,
        'reviewed_by': _supabase.auth.currentUser?.id,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', incidentId);
      await fetchIncidents();
    } catch (e) {
      final idx = _incidents.indexWhere((i) => i.id == incidentId);
      if (idx != -1) {
        _incidents[idx] = BypassIncident(
          id: _incidents[idx].id,
          conversationId: _incidents[idx].conversationId,
          senderId: _incidents[idx].senderId,
          senderRole: _incidents[idx].senderRole,
          flagTypes: _incidents[idx].flagTypes,
          severity: _incidents[idx].severity,
          originalMessage: _incidents[idx].originalMessage,
          status: newStatus,
          createdAt: _incidents[idx].createdAt,
        );
        notifyListeners();
      }
    }
  }

  Future<void> issueWarning({
    required String vendorId,
    required String incidentId,
    required String message,
  }) async {
    try {
      await _supabase.from('vendor_warnings').insert({
        'vendor_id': vendorId,
        'incident_id': incidentId,
        'warning_type': 'anti_bypass',
        'message': message,
        'issued_by': _supabase.auth.currentUser?.id,
      });
      await reviewIncident(incidentId, 'warned');
      await _incrementOffenderScore(vendorId);
    } catch (e) {
      debugPrint('Issue warning failed: $e');
    }
  }

  Future<void> _incrementOffenderScore(String userId) async {
    try {
      final existing = await _supabase
          .from('repeat_offender_scores')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        final count = (existing['incident_count'] as int? ?? 0) + 1;
        await _supabase.from('repeat_offender_scores').update({
          'incident_count': count,
          'warning_count': (existing['warning_count'] as int? ?? 0) + 1,
          'last_incident_at': DateTime.now().toIso8601String(),
          'risk_level': count >= 5 ? 'high' : count >= 3 ? 'medium' : 'low',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', userId);
      } else {
        await _supabase.from('repeat_offender_scores').insert({
          'user_id': userId,
          'incident_count': 1,
          'warning_count': 1,
          'last_incident_at': DateTime.now().toIso8601String(),
          'risk_level': 'low',
        });
      }
      await fetchRepeatOffenders();
    } catch (e) {
      debugPrint('Offender score update failed: $e');
    }
  }

  /// Record a bypass incident from chat (called when message is flagged).
  Future<void> recordIncident({
    required String conversationId,
    required String? senderId,
    required String? senderRole,
    required List<String> flagTypes,
    required String severity,
    required String originalMessage,
    required String maskedMessage,
    String? messageId,
  }) async {
    try {
      await _supabase.from('bypass_incidents').insert({
        'conversation_id': conversationId,
        'message_id': messageId,
        'sender_id': senderId,
        'sender_role': senderRole,
        'flag_types': flagTypes,
        'severity': severity,
        'original_message': originalMessage,
        'masked_message': maskedMessage,
        'status': 'flagged',
      });
      if (senderId != null) await _incrementOffenderScore(senderId);
    } catch (e) {
      debugPrint('Record bypass incident failed: $e');
    }
  }

  List<BypassIncident> _mockIncidents() => [
        BypassIncident(
          id: 'demo-1',
          conversationId: 'conv_001',
          senderId: 'vendor_demo',
          senderRole: 'vendor',
          flagTypes: ['phoneNumber', 'whatsapp'],
          severity: 'high',
          originalMessage: 'Contact me on WhatsApp +60123456789',
          status: 'flagged',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        BypassIncident(
          id: 'demo-2',
          conversationId: 'conv_002',
          senderId: 'vendor_demo2',
          senderRole: 'vendor',
          flagTypes: ['externalPayment'],
          severity: 'critical',
          originalMessage: 'Pay me directly via bank transfer',
          status: 'flagged',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ];
}
