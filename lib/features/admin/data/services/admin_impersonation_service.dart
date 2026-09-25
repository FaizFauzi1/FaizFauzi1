import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Secure admin impersonation with audit logging and reactive state.
class AdminImpersonationService extends ChangeNotifier {
  static final AdminImpersonationService instance = AdminImpersonationService._internal();
  factory AdminImpersonationService() => instance;
  AdminImpersonationService._internal();

  static const _sessionKey = 'admin_impersonation_session';
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _impersonatingUserId;
  String? _impersonatingRole;
  String? _impersonatingVendorName;
  String? _originalAdminId;
  String? _originalAdminEmail;

  bool get isImpersonating => _impersonatingUserId != null;
  String? get impersonatingUserId => _impersonatingUserId;
  String? get impersonatingRole => _impersonatingRole;
  String? get impersonatingVendorName => _impersonatingVendorName;
  String? get originalAdminId => _originalAdminId;
  String? get originalAdminEmail => _originalAdminEmail;

  /// Returns the impersonated user ID if active, otherwise the logged-in Supabase user ID.
  String? get effectiveUserId => _impersonatingUserId ?? _supabase.auth.currentUser?.id;

  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _impersonatingUserId = prefs.getString('${_sessionKey}_target');
      _impersonatingRole = prefs.getString('${_sessionKey}_role');
      _impersonatingVendorName = prefs.getString('${_sessionKey}_vendor_name');
      _originalAdminId = prefs.getString('${_sessionKey}_admin');
      _originalAdminEmail = prefs.getString('${_sessionKey}_admin_email');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading impersonation session: $e');
    }
  }

  Future<bool> startImpersonation({
    required String adminId,
    required String targetUserId,
    required String targetRole,
    String? vendorName,
    String? adminEmail,
  }) async {
    try {
      await _logAction(
        adminId: adminId,
        targetUserId: targetUserId,
        targetRole: targetRole,
        action: 'start',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_sessionKey}_target', targetUserId);
      await prefs.setString('${_sessionKey}_role', targetRole);
      await prefs.setString('${_sessionKey}_admin', adminId);
      if (vendorName != null) {
        await prefs.setString('${_sessionKey}_vendor_name', vendorName);
      }
      if (adminEmail != null) {
        await prefs.setString('${_sessionKey}_admin_email', adminEmail);
      }

      _impersonatingUserId = targetUserId;
      _impersonatingRole = targetRole;
      _impersonatingVendorName = vendorName;
      _originalAdminId = adminId;
      _originalAdminEmail = adminEmail;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Impersonation start failed: $e');
      return false;
    }
  }

  Future<void> endImpersonation() async {
    if (_originalAdminId != null && _impersonatingUserId != null) {
      await _logAction(
        adminId: _originalAdminId!,
        targetUserId: _impersonatingUserId!,
        targetRole: _impersonatingRole ?? 'vendor',
        action: 'end',
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_sessionKey}_target');
      await prefs.remove('${_sessionKey}_role');
      await prefs.remove('${_sessionKey}_vendor_name');
      await prefs.remove('${_sessionKey}_admin');
      await prefs.remove('${_sessionKey}_admin_email');
    } catch (e) {
      debugPrint('Error clearing impersonation prefs: $e');
    }

    _impersonatingUserId = null;
    _impersonatingRole = null;
    _impersonatingVendorName = null;
    _originalAdminId = null;
    _originalAdminEmail = null;

    notifyListeners();
  }

  Future<void> _logAction({
    required String adminId,
    required String targetUserId,
    required String targetRole,
    required String action,
  }) async {
    try {
      await _supabase.from('admin_impersonation_log').insert({
        'admin_id': adminId,
        'target_user_id': targetUserId,
        'target_role': targetRole,
        'action': action,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Impersonation log failed (table may not exist yet): $e');
    }
  }
}
