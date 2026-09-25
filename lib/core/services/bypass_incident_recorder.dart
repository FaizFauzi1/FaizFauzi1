import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Records bypass incidents from chat without admin UI dependency.
class BypassIncidentRecorder {
  BypassIncidentRecorder._();

  static Future<void> record({
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
      await Supabase.instance.client.from('bypass_incidents').insert({
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
    } catch (e) {
      debugPrint('BypassIncidentRecorder: $e');
    }
  }
}

/// Logs vendor verification events for audit history.
class VerificationEventLogger {
  VerificationEventLogger._();

  static Future<void> log({
    required String vendorId,
    required String eventType,
    String? documentId,
    String? documentType,
    String? notes,
  }) async {
    try {
      await Supabase.instance.client.from('vendor_verification_events').insert({
        'vendor_id': vendorId,
        'document_id': documentId,
        'event_type': eventType,
        'document_type': documentType,
        'notes': notes,
        'performed_by': Supabase.instance.client.auth.currentUser?.id,
      });
    } catch (e) {
      debugPrint('VerificationEventLogger: $e');
    }
  }
}
