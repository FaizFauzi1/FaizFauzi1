import 'package:eventease/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:convert';

class SecurityService {
  static final SupabaseClient _client = SupabaseService.client;

  // --- Auth & Password ---

  /// Updates the user's password using Supabase Auth
  static Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      await logSecurityEvent(
        eventType: 'password_change',
        description: 'User successfully changed their password',
      );
    } catch (e) {
      debugPrint('Error updating password: $e');
      rethrow;
    }
  }

  /// Performs a soft delete by setting deleted_at and logging out
  static Future<void> softDeleteAccount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // 1. Mark as deleted in users table
      await _client.from('users').update({
        'deleted_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      // 2. Log security event
      await logSecurityEvent(
        eventType: 'account_deleted',
        description: 'User performed a soft delete of their account',
      );

      // Call privileged edge function to completely delete auth record
      try {
        await _client.functions.invoke('delete-user-auth');
        debugPrint('Auth record successfully deleted via edge function.');
      } catch (e) {
        debugPrint('Failed to delete auth record via edge function: $e');
      }

      // 3. Log out everywhere
      await _client.auth.signOut(scope: SignOutScope.global);
    } catch (e) {
      debugPrint('Error performing soft delete: $e');
      rethrow;
    }
  }

  // --- Session Management ---

  /// Tracks the current device session in the database
  static Future<void> recordCurrentSession({
    String? deviceName,
    String? platform,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      final deviceInfo = await _getDeviceInfo();
      final finalDeviceName = deviceName ?? deviceInfo['name'] ?? 'Unknown Device';
      final finalPlatform = platform ?? deviceInfo['platform'] ?? 'Unknown Platform';

      final sessionId = _getSessionId();
      if (sessionId == null) {
        debugPrint('Cannot record session: sessionId is null');
        return;
      }

      await _client.from('user_sessions').upsert({
        'user_id': user.id,
        'device_name': finalDeviceName,
        'platform': finalPlatform,
        'session_id': sessionId,
        'last_active_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, session_id');
      
      await logSecurityEvent(
        eventType: 'login_session',
        description: 'New login session recorded on $finalDeviceName ($finalPlatform)',
      );
    } catch (e) {
      debugPrint('Error recording session: $e');
    }
  }

  /// Helper to get device information
  static Future<Map<String, String>> _getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    String name = 'Unknown';
    String platform = 'Unknown';

    try {
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        name = webInfo.browserName.name;
        platform = 'Web';
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        name = androidInfo.model;
        platform = 'Android';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        name = iosInfo.name;
        platform = 'iOS';
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        name = windowsInfo.computerName;
        platform = 'Windows';
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    return {'name': name, 'platform': platform};
  }

  /// Fetches all active sessions for the current user
  static Future<List<Map<String, dynamic>>> getActiveSessions() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      return await _client
          .from('user_sessions')
          .select('*')
          .eq('user_id', user.id)
          .order('last_active_at', ascending: false);
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      return [];
    }
  }

  /// Logs out from all other devices
  static Future<void> logoutOtherDevices() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // 1. Perform Global Sign Out with others scope
      await _client.auth.signOut(scope: SignOutScope.others);

      // 2. Clean up user_sessions table (remove all but current)
      final currentSessionId = _getSessionId();
      await _client
          .from('user_sessions')
          .delete()
          .eq('user_id', user.id)
          .neq('session_id', currentSessionId ?? '');

      await logSecurityEvent(
        eventType: 'global_logout',
        description: 'User logged out from all other devices',
      );
    } catch (e) {
      debugPrint('Error logging out others: $e');
      rethrow;
    }
  }

  // --- Privacy & Logs ---

  /// Logs a security event to the audit trail
  static Future<void> logSecurityEvent({
    required String eventType,
    String? description,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client.from('security_logs').insert({
        'user_id': user.id,
        'event_type': eventType,
        'description': description,
        'ip_address': ipAddress,
        'user_agent': userAgent,
      });
    } catch (e) {
      debugPrint('Error logging security event: $e');
    }
  }

  /// Fetch recent security logs
  static Future<List<Map<String, dynamic>>> getRecentLogs({int limit = 10}) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      return await _client
          .from('security_logs')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);
    } catch (e) {
      debugPrint('Error fetching security logs: $e');
      return [];
    }
  }
  /// Updates a privacy setting in the user's preferences
  static Future<void> updatePrivacySetting(String key, dynamic value) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // 1. Fetch current preferences
      final response = await _client
          .from('users')
          .select('preferences')
          .eq('id', user.id)
          .single();
      
      final Map<String, dynamic> preferences = Map<String, dynamic>.from(response['preferences'] ?? {});
      
      // 2. Update the specific key
      preferences[key] = value;

      // 3. Save back to database
      await _client.from('users').update({
        'preferences': preferences,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      await logSecurityEvent(
        eventType: 'privacy_update',
        description: 'Updated privacy setting: $key to $value',
      );
    } catch (e) {
      debugPrint('Error updating privacy setting: $e');
      rethrow;
    }
  }

  /// Helper to get collision-safe session ID from JWT jti claim
  static String? _getSessionId() {
    final session = _client.auth.currentSession;
    if (session == null) return null;
    
    try {
      final parts = session.accessToken.split('.');
      if (parts.length == 3) {
        final payload = String.fromCharCodes(
          base64Decode(base64.normalize(parts[1])),
        );
        final payloadMap = jsonDecode(payload) as Map<String, dynamic>;
        final jti = payloadMap['jti'] as String?;
        if (jti != null && jti.isNotEmpty) {
          return jti;
        }
      }
    } catch (e) {
      debugPrint('Error parsing session JWT jti: $e');
    }
    
    return session.accessToken.hashCode.toString(); // Fallback
  }
}
