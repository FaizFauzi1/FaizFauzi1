import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/shared/models/notification.dart';
import 'package:eventease/core/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;

class NotificationProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  NotificationSettings? _settings;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;
  NotificationSettings? get settings => _settings;

  StreamSubscription? _notificationSubscription;

  NotificationProvider() {
    debugPrint('FCM DEBUG: NotificationProvider constructor called');
    _initialize();
  }
  
  Future<void> _initialize() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _loadNotifications();
      await loadSettings(userId);
      _setupRealtimeSubscription();
      _initializeFCM();
    }
    
    // Listen for auth changes to re-init
    _supabase.auth.onAuthStateChange.listen((data) {
       debugPrint('FCM DEBUG: Auth state changed: ${data.event}');
       if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.tokenRefreshed) {
          if (data.session?.user != null) {
             _loadNotifications();
             loadSettings(data.session!.user.id);
             _setupRealtimeSubscription();
             _initializeFCM(); // Call FCM init here too!
          }
       }
    });
  }

  Future<void> initialize(String userId) async {
    debugPrint('FCM DEBUG: Manual initialize called for $userId');
    await _loadNotifications();
    await loadSettings(userId);
    _setupRealtimeSubscription();
    _initializeFCM();
  }

  Future<void> loadNotifications(String userId, {
    bool includeRead = true,
    bool includeArchived = false,
  }) async {
    await _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('FCM DEBUG: Cannot load notifications, userId is null');
        return;
      }

      debugPrint('FCM DEBUG: Loading notifications for $userId');
      final data = await _notificationService.getNotifications(userId);
      _notifications = data;
      _unreadCount = await _notificationService.getUnreadCount(userId);
      debugPrint('FCM DEBUG: Loaded ${_notifications.length} notifications');
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupRealtimeSubscription() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('FCM DEBUG: Stream setup skipped, userId is null');
      return;
    }
    
    debugPrint('FCM DEBUG: Setting up Realtime stream for user: $userId');
    _notificationSubscription?.cancel();

    _notificationSubscription = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen((data) {
           debugPrint('FCM DEBUG: Stream received ${data.length} notifications');
           // Sort locally to ensure descending order (newest first)
           final sortedData = List<Map<String, dynamic>>.from(data);
           sortedData.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
           
           _notifications = sortedData.map((json) => NotificationModel.fromJson(json)).toList();
           _unreadCount = _notifications.where((n) => !n.isRead).length;
           
           if (_notifications.isNotEmpty) {
             final latest = _notifications.first; 
             final diff = latest.createdAt.difference(DateTime.now()).inSeconds.abs();
             debugPrint('FCM DEBUG: Latest notification age: $diff seconds');
             
             if (diff < 10 && !latest.isRead) {
               debugPrint('FCM DEBUG: Triggering local popup for new DB record');
               // NOTE: We don't want to call createNotification here because it saves to DB again!
               // We only want to show the popup.
               _notificationService.showLocalPopup(latest);
             }
           }
           notifyListeners();
        });
  }
  
  // Settings Logic
  Future<void> loadSettings(String userId) async {
    try {
      _settings = await _notificationService.getNotificationSettings(userId);
      if (_settings == null) {
        _settings = NotificationSettings();
        await updateSettings(userId, _settings!);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> updateSettings(String userId, NotificationSettings settings) async {
    try {
      await _notificationService.updateNotificationSettings(userId, settings);
      _settings = settings;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
    }
  }

  Future<void> markAsRead(String userIdOrId, [String? id]) async {
    final targetId = id ?? userIdOrId;
    await _notificationService.markAsRead(targetId);
    // Local update handled by stream
  }

  Future<void> markAllAsRead([String? userId]) async {
    final targetUserId = userId ?? _supabase.auth.currentUser?.id;
    if (targetUserId == null) return;
    await _notificationService.markAllAsRead(targetUserId);
  }

  Future<void> deleteNotification(String userIdOrId, [String? id]) async {
    final targetId = id ?? userIdOrId;
    await _notificationService.deleteNotification(targetId);
  }

  List<NotificationModel> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  List<NotificationModel> getTodayNotifications() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _notifications.where((n) => n.createdAt.isAfter(startOfDay)).toList();
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    await _notificationService.createNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
    );
    // Stream will handle the reload
  }
  
  // ==========================================
  // FCM INTEGRATION (SCAFFOLDING)
  // ==========================================
  
  Future<void> _initializeFCM() async {
    debugPrint('FCM: >>> _initializeFCM process started');
    try {
      // 1. Request Permission
      debugPrint('FCM: Attempting to get FirebaseMessaging instance...');
      fcm.FirebaseMessaging messaging = fcm.FirebaseMessaging.instance;
      debugPrint('FCM: FirebaseMessaging instance obtained successfully');
      
      debugPrint('FCM: Requesting notification permissions from browser/OS...');
      fcm.NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('FCM: Permission request completed. Status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == fcm.AuthorizationStatus.authorized) {
        debugPrint('FCM: Permission GRANTED. Now attempting to fetch token...');
        
        // 2. Get Token
        try {
          debugPrint('FCM: Calling messaging.getToken() with VAPID key...');
          
          // Small delay for Web to ensure service worker is ready
          if (kIsWeb) {
            debugPrint('FCM: On Web - waiting 2 seconds for Service Worker sync...');
            await Future.delayed(const Duration(seconds: 2));
          }

          String? token = await messaging.getToken(
            vapidKey: "BMo73ktYpOtzqTzIjlou0ONo7H9ZAzpBNjjiKkFXr4UfvP2qMJDLSdFuQ30w9T5Fws2aGmFq7mQUOgwtnXQdvYI",
          );
          
          if (token != null) {
            debugPrint('FCM: SUCCESS! Token retrieved: $token');
            await _saveFCMToken(token);
          } else {
            debugPrint('FCM WARNING: getToken() returned null');
          }
        } catch (tokenError) {
          debugPrint('FCM CRITICAL ERROR (getToken): $tokenError');
          if (tokenError.toString().contains('service-worker-registration')) {
            debugPrint('FCM TIP: This usually means firebase-messaging-sw.js is missing or Chrome is blocking it.');
          }
        }
        
        // 3. Listen to foreground messages
        debugPrint('FCM: Setting up foreground message listener...');
        fcm.FirebaseMessaging.onMessage.listen((fcm.RemoteMessage message) {
          debugPrint('FCM: Foreground message received!');
          debugPrint('FCM Content: ${message.notification?.title} - ${message.notification?.body}');
          
          _notificationService.createNotification(
            userId: _supabase.auth.currentUser?.id ?? '',
            title: message.notification?.title ?? 'Notification',
            message: message.notification?.body ?? '',
            type: NotificationType.system, 
          );
        });

        // 4. Listen to token refresh
        messaging.onTokenRefresh.listen((newToken) {
          debugPrint('FCM: Token was refreshed dynamically: $newToken');
          _saveFCMToken(newToken);
        });
      } else {
        debugPrint('FCM ERROR: Permission was DENIED or NOT GRANTED. Status: ${settings.authorizationStatus}');
        debugPrint('FCM TIP: Check browser address bar to see if notifications are blocked.');
      }
    } catch (e) {
      debugPrint('FCM GLOBAL ERROR: $e');
    }
  }
  
  Future<void> _saveFCMToken(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      await _supabase.from('user_fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_type': kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'), 
        'last_used_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, token');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }
  
  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
