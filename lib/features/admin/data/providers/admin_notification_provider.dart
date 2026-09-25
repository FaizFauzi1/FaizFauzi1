import 'dart:async';

import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/shared/models/admin_notification.dart';
import 'package:flutter/foundation.dart';

class AdminNotificationProvider with ChangeNotifier {
  List<AdminNotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSub;
  bool _listening = false;

  List<AdminNotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => n.status == AdminNotificationStatus.unread).length;

  // Categorized Getters
  List<AdminNotificationModel> get criticalNotifications =>
      _notifications.where((n) => n.severity == AdminNotificationSeverity.critical).toList();

  List<AdminNotificationModel> get operationNotifications =>
      _notifications
          .where((n) =>
              n.type == AdminNotificationType.booking ||
              n.type == AdminNotificationType.vendor ||
              n.type == AdminNotificationType.support)
          .toList();

  List<AdminNotificationModel> get onboardingNotifications =>
      _notifications.where((n) => n.type == AdminNotificationType.onboarding).toList();

  List<AdminNotificationModel> get riskNotifications =>
      _notifications.where((n) => n.type == AdminNotificationType.risk).toList();

  List<AdminNotificationModel> get systemNotifications =>
      _notifications.where((n) => n.type == AdminNotificationType.system || n.type == AdminNotificationType.health).toList();

  List<AdminNotificationModel> get businessNotifications =>
      _notifications.where((n) => n.type == AdminNotificationType.business).toList();

  Future<void> loadNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await SupabaseService.select(
        table: 'admin_notifications',
        orderBy: 'created_at',
        ascending: false,
      );

      _notifications = response.map((json) => AdminNotificationModel.fromJson(json)).toList();
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('PGRST205') || errStr.contains('Could not find the table')) {
        debugPrint('DEBUG: admin_notifications table not found. Run 20260917_fix_admin_notifications_and_vendor_expos.sql');
        _notifications = [];
      } else {
        debugPrint('Error loading admin notifications: $e');
        _error = 'Failed to load notifications';
      }
    } finally {
      _listenRealtime();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenRealtime() {
    if (_listening) return;
    _listening = true;
    _realtimeSub?.cancel();
    _realtimeSub = SupabaseService.client
        .from('admin_notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .listen(
      (rows) {
        _notifications = rows.map(AdminNotificationModel.fromJson).toList();
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Admin notification realtime error: $e');
        _listening = false;
      },
    );
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  Future<void> updateNotificationStatus(String id, AdminNotificationStatus status) async {
    try {
      await SupabaseService.update(
        table: 'admin_notifications',
        data: {'status': status.name},
        column: 'id',
        value: id,
      );

      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(status: status);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating admin notification status: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      for (final n in _notifications.where((n) => n.status == AdminNotificationStatus.unread)) {
        await updateNotificationStatus(n.id, AdminNotificationStatus.read);
      }
    } catch (e) {
      print('Error marking all admin notifications as read: $e');
    }
  }
}
