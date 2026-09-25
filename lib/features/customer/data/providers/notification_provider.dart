import 'package:flutter/material.dart';
import 'package:eventease/core/services/notification_service.dart';
import 'package:eventease/shared/models/notification.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  NotificationSettings? _settings;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  NotificationSettings? get settings => _settings;

  // Initialize the provider
  Future<void> initialize(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _notificationService.initialize();
      await loadNotifications(userId);
      await loadSettings(userId);
    } catch (e) {
      print('Error initializing notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load notifications for user
  Future<void> loadNotifications(String userId, {
    bool includeRead = true,
    bool includeArchived = false,
  }) async {
    try {
      _notifications = await _notificationService.getNotifications(
        userId,
        includeRead: includeRead,
        includeArchived: includeArchived,
      );
      _unreadCount = await _notificationService.getUnreadCount(userId);
      notifyListeners();
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  // Load notification settings
  Future<void> loadSettings(String userId) async {
    try {
      _settings = await _notificationService.getNotificationSettings(userId);
      if (_settings == null) {
        // Create default settings if none exist
        _settings = NotificationSettings();
        await updateSettings(userId, _settings!);
      }
      notifyListeners();
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  // Update notification settings
  Future<void> updateSettings(String userId, NotificationSettings settings) async {
    try {
      await _notificationService.updateNotificationSettings(userId, settings);
      _settings = settings;
      notifyListeners();
    } catch (e) {
      print('Error updating notification settings: $e');
    }
  }

  // Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    DateTime? scheduledFor,
    String? actionUrl,
    String? imageUrl,
  }) async {
    try {
      await _notificationService.createNotification(
        userId: userId,
        title: title,
        message: message,
        type: type,
        priority: priority,
        data: data,
        scheduledFor: scheduledFor,
        actionUrl: actionUrl,
        imageUrl: imageUrl,
      );

      // Reload notifications to include the new one
      await loadNotifications(userId);
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        notifyListeners();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);

      // Update local state
      for (var i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Archive notification
  Future<void> archiveNotification(String userId, String notificationId) async {
    try {
      await _notificationService.archiveNotification(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isArchived: true);
        notifyListeners();
      }
    } catch (e) {
      print('Error archiving notification: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      // Update local state
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  // Get unread notifications
  List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  // Get notifications for today
  List<NotificationModel> getTodayNotifications() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _notifications.where((n) =>
      n.createdAt.isAfter(startOfDay) && n.createdAt.isBefore(endOfDay)
    ).toList();
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    return await _notificationService.requestPermissions();
  }

  // Send bulk notifications
  Future<void> sendBulkNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? imageUrl,
  }) async {
    try {
      await _notificationService.sendBulkNotifications(
        userIds: userIds,
        title: title,
        message: message,
        type: type,
        priority: priority,
        data: data,
        actionUrl: actionUrl,
        imageUrl: imageUrl,
      );
    } catch (e) {
      print('Error sending bulk notifications: $e');
    }
  }

  // Clear all notifications (for testing/debugging)
  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }
}
