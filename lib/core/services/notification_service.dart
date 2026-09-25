import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/shared/models/notification.dart';
import 'package:eventease/core/services/admin_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = SupabaseService.client;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    final payload = response.payload;
    if (payload != null) {
      final data = json.decode(payload);
      // Navigate to appropriate screen based on notification type
      _handleNotificationAction(data);
    }
  }

  void _handleNotificationAction(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final actionUrl = data['action_url'] as String?;

    if (actionUrl != null) {
      // Handle deep linking or navigation
      print('Navigate to: $actionUrl');
    }
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    NotificationSeverity severity = NotificationSeverity.info,
    NotificationChannel channel = NotificationChannel.inapp,
    NotificationStatus notificationStatus = NotificationStatus.delivered,
    String? relatedId,
    Map<String, dynamic>? data,
    DateTime? scheduledFor,
    String? actionUrl,
    String? imageUrl,
  }) async {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      message: message,
      type: type,
      priority: priority,
      severity: severity,
      channel: channel,
      notificationStatus: notificationStatus,
      relatedId: relatedId,
      data: data,
      createdAt: DateTime.now(),
      scheduledFor: scheduledFor,
      actionUrl: actionUrl,
      imageUrl: imageUrl,
    );

    // Save to database
    await _saveNotificationToDatabase(notification);

    // Send push notification if not scheduled
    if (scheduledFor == null) {
      await _sendPushNotification(notification);
    } else {
      // Schedule notification
      await _scheduleNotification(notification);
    }

    // Send email/SMS based on user settings
    await _sendExternalNotifications(notification);
  }

  // --- Helper to resolve vendor profile ID to user ID ---
  Future<String?> _resolveVendorUserId(String vendorProfileId) async {
    try {
      final response = await _supabase
          .from('vendor_profiles')
          .select('user_id')
          .eq('id', vendorProfileId)
          .maybeSingle();
      if (response != null && response['user_id'] != null) {
        return response['user_id'].toString();
      }
    } catch (e) {
      print('DEBUG: Error resolving vendor profile ID to user ID: $e');
    }
    return null;
  }

  // --- Specific Notification Triggers ---

  Future<void> sendBookingSubmittedNotification({
    required String customerId,
    required String vendorId,
    required String bookingId,
    required String serviceName,
    required DateTime bookingDate,
  }) async {
    final dateStr = "${bookingDate.day}/${bookingDate.month}/${bookingDate.year}";
    
    // Notify Customer
    await createNotification(
      userId: customerId,
      title: 'Booking Submitted',
      message: 'Your booking for $serviceName on $dateStr has been submitted. Waiting for vendor confirmation.',
      type: NotificationType.bookingSubmitted,
      priority: NotificationPriority.normal,
      severity: NotificationSeverity.info,
      relatedId: bookingId,
    );

    final resolvedVendorId = await _resolveVendorUserId(vendorId) ?? vendorId;

    // Notify Vendor
    await createNotification(
      userId: resolvedVendorId,
      title: 'New Booking Request',
      message: 'You have a new booking request for $serviceName on $dateStr.',
      type: NotificationType.newBookingRequest,
      priority: NotificationPriority.high,
      severity: NotificationSeverity.actionRequired,
      relatedId: bookingId,
    );
  }

  Future<void> sendVendorConfirmedNotification({
    required String customerId,
    required String bookingId,
    required String serviceName,
  }) async {
    await createNotification(
      userId: customerId,
      title: 'Booking Confirmed!',
      message: 'The vendor has confirmed your booking for $serviceName. Please proceed with the deposit payment.',
      type: NotificationType.vendorConfirmed,
      priority: NotificationPriority.high,
      severity: NotificationSeverity.actionRequired,
      relatedId: bookingId,
    );
  }

  Future<void> sendServiceApprovedNotification({
    required String vendorId,
    required String serviceId,
    required String serviceName,
  }) async {
    final resolvedVendorId = await _resolveVendorUserId(vendorId) ?? vendorId;

    await createNotification(
      userId: resolvedVendorId,
      title: 'Service Approved!',
      message: 'Your service "$serviceName" has been approved by the admin and is now live.',
      type: NotificationType.serviceApproved,
      priority: NotificationPriority.high,
      severity: NotificationSeverity.actionRequired,
      relatedId: serviceId,
    );
  }

  Future<void> sendServiceRejectedNotification({
    required String vendorId,
    required String serviceId,
    required String serviceName,
    required String reason,
  }) async {
    final resolvedVendorId = await _resolveVendorUserId(vendorId) ?? vendorId;

    await createNotification(
      userId: resolvedVendorId,
      title: 'Service Rejected',
      message: 'Your service "$serviceName" was not approved. Reason: $reason',
      type: NotificationType.serviceRejected,
      priority: NotificationPriority.high,
      severity: NotificationSeverity.actionRequired,
      relatedId: serviceId,
    );
  }

  /// Notify customer when vendor updates their event-day check-in status.
  Future<void> sendVendorCheckinNotification({
    required String customerId,
    required String bookingId,
    required String vendorName,
    required String serviceName,
    required String status, // 'on_the_way' | 'arrived' | 'started' | 'completed'
  }) async {
    String title;
    String message;
    NotificationType type;
    NotificationPriority priority;

    switch (status) {
      case 'on_the_way':
        title = '🚗 Vendor On The Way';
        message = '$vendorName is on the way to your venue for "$serviceName".';
        type = NotificationType.vendorOnTheWay;
        priority = NotificationPriority.high;
        break;
      case 'arrived':
        title = '📍 Vendor Has Arrived';
        message = '$vendorName has arrived at your venue!';
        type = NotificationType.vendorArrived;
        priority = NotificationPriority.high;
        break;
      case 'started':
        title = '✅ Service Started';
        message = '$vendorName has started "$serviceName". Everything is underway!';
        type = NotificationType.vendorStarted;
        priority = NotificationPriority.normal;
        break;
      case 'completed':
        title = '🎉 Service Completed';
        message = '"$serviceName" by $vendorName is complete. Please leave a review!';
        type = NotificationType.vendorServiceCompleted;
        priority = NotificationPriority.normal;
        break;
      default:
        return;
    }

    await createNotification(
      userId: customerId,
      title: title,
      message: message,
      type: type,
      priority: priority,
      severity: NotificationSeverity.info,
      relatedId: bookingId,
      data: {'booking_id': bookingId, 'status': status},
    );
  }


  Future<void> sendPaymentReceivedNotification({
    required String customerId,
    required String vendorId,
    required String bookingId,
    required double amount,
    required String paymentType, // 'Deposit' or 'Full'
  }) async {
    final amountStr = "RM ${amount.toStringAsFixed(2)}";

    // Notify Customer
    await createNotification(
      userId: customerId,
      title: 'Payment Successful',
      message: 'Your $paymentType payment of $amountStr for booking #$bookingId was successful.',
      type: NotificationType.paymentReceived,
      priority: NotificationPriority.normal,
      severity: NotificationSeverity.info,
      relatedId: bookingId,
    );

    final resolvedVendorId = await _resolveVendorUserId(vendorId) ?? vendorId;

    // Notify Vendor
    await createNotification(
      userId: resolvedVendorId,
      title: 'Payment Received',
      message: 'You have received a $paymentType payment of $amountStr for booking #$bookingId.',
      type: NotificationType.paymentReceived,
      priority: NotificationPriority.high,
      severity: NotificationSeverity.actionRequired,
      relatedId: bookingId,
    );
  }

  // --- Extended Matrix Triggers ---

  Future<void> sendSlaBreachWarning({
    required String vendorId,
    required String bookingId,
    required int hoursElapsed,
  }) async {
    final resolvedVendorId = await _resolveVendorUserId(vendorId) ?? vendorId;

    await createNotification(
      userId: resolvedVendorId,
      title: 'Pending Booking Request',
      message: 'You have a pending booking request that requires your attention.',
      type: NotificationType.slaBreachWarning,
      priority: NotificationPriority.urgent,
      severity: NotificationSeverity.urgent,
      relatedId: bookingId,
    );
  }

  Future<void> sendRequestExpiredNotification({
    required String customerId,
    required String vendorId,
    required String adminId,
    required String bookingId,
  }) async {
    // Notify Customer
    await createNotification(
      userId: customerId,
      title: 'Booking Request Expired',
      message: 'Your booking request expired due to no vendor response.',
      type: NotificationType.requestExpired,
      priority: NotificationPriority.normal,
      severity: NotificationSeverity.info,
      relatedId: bookingId,
    );

    final resolvedVendorId = await _resolveVendorUserId(vendorId) ?? vendorId;

    // Notify Vendor (in-app only)
    await createNotification(
      userId: resolvedVendorId,
      title: 'Booking Request Expired',
      message: 'A booking request has expired due to no response.',
      type: NotificationType.requestExpired,
      priority: NotificationPriority.normal,
      severity: NotificationSeverity.info,
      relatedId: bookingId,
    );

    // Notify Admin (in-app only)
    await createNotification(
      userId: adminId,
      title: 'Booking Request Expired',
      message: 'Booking #$bookingId expired due to vendor inactivity.',
      type: NotificationType.requestExpired,
      priority: NotificationPriority.normal,
      severity: NotificationSeverity.system,
      relatedId: bookingId,
    );
  }

  Future<void> sendPaymentFailedNotification({
    required String customerId,
    required String adminId,
    required String bookingId,
    required String reason,
  }) async {
    // Notify Customer
    await createNotification(
      userId: customerId,
      title: 'Payment Failed',
      message: 'Payment failed. Please retry. Reason: $reason',
      type: NotificationType.paymentFailed,
      priority: NotificationPriority.high,
      severity: NotificationSeverity.urgent,
      relatedId: bookingId,
    );

    // Notify Admin
    await createNotification(
      userId: adminId,
      title: 'Payment Failure',
      message: 'Payment failed for booking #$bookingId.',
      type: NotificationType.paymentFailed,
      priority: NotificationPriority.normal,
      severity: NotificationSeverity.system,
      relatedId: bookingId,
    );

    // Also notify via AdminNotificationService
    await AdminNotificationService().notifyPaymentFailure(
      bookingId,
      'Customer', // Ideally we'd pass customer name, but Customer is a good fallback
      reason,
    );
  }

  Future<void> sendVenueDetailsUpdatedNotification({
    required String vendorId,
    required String bookingId,
    required String venueName,
  }) async {
    final resolvedVendorId = await _resolveVendorUserId(vendorId) ?? vendorId;

    await createNotification(
      userId: resolvedVendorId,
      title: 'Venue Details Updated',
      message: 'Customer has updated the venue to: $venueName',
      type: NotificationType.venueDetailsUpdated,
      priority: NotificationPriority.high,
      severity: NotificationSeverity.actionRequired,
      relatedId: bookingId,
    );
  }

  Future<void> sendLogisticsPriceChangedNotification({
    required String customerId,
    required String vendorId,
    required String adminId,
    required String bookingId,
    required double newPrice,
  }) async {
    final priceStr = "RM ${newPrice.toStringAsFixed(2)}";

    // Notify Customer
    await createNotification(
      userId: customerId,
      title: 'Price Updated',
      message: 'Logistics price has been recalculated to $priceStr.',
      type: NotificationType.logisticsPriceChanged,
      priority: NotificationPriority.high,
      severity: NotificationSeverity.actionRequired,
      relatedId: bookingId,
    );

    final resolvedVendorId = await _resolveVendorUserId(vendorId) ?? vendorId;

    // Notify Vendor (in-app)
    await createNotification(
      userId: resolvedVendorId,
      title: 'Price Updated',
      message: 'Logistics price updated to $priceStr for booking #$bookingId.',
      type: NotificationType.logisticsPriceChanged,
      priority: NotificationPriority.normal,
      severity: NotificationSeverity.info,
      relatedId: bookingId,
    );

    // Notify Admin (in-app)
    await createNotification(
      userId: adminId,
      title: 'Price Updated',
      message: 'Logistics price changed for booking #$bookingId.',
      type: NotificationType.logisticsPriceChanged,
      priority: NotificationPriority.normal,
      severity: NotificationSeverity.system,
      relatedId: bookingId,
    );
  }

  Future<void> sendPayoutRequestedNotification({
    required String adminId,
    required String vendorId,
    required String payoutId,
    required double amount,
  }) async {
    await createNotification(
      userId: adminId,
      title: 'Payout Requested',
      message: 'Vendor has requested payout of RM ${amount.toStringAsFixed(2)}.',
      type: NotificationType.payoutRequested,
      priority: NotificationPriority.high,
      severity: NotificationSeverity.actionRequired,
      relatedId: payoutId,
    );
  }

  Future<void> sendPayoutApprovedNotification({
    required String vendorId,
    required String payoutId,
    required double amount,
  }) async {
    final resolvedVendorId = await _resolveVendorUserId(vendorId) ?? vendorId;

    await createNotification(
      userId: resolvedVendorId,
      title: 'Payout Approved',
      message: 'Your payout of RM ${amount.toStringAsFixed(2)} has been processed.',
      type: NotificationType.payoutApproved,
      priority: NotificationPriority.high,
      severity: NotificationSeverity.actionRequired,
      relatedId: payoutId,
    );
  }

  Future<void> sendDisputeOpenedNotification({
    required String vendorId,
    required String adminId,
    required String customerId,
    required String disputeId,
    required String bookingId,
  }) async {
    final resolvedVendorId = await _resolveVendorUserId(vendorId) ?? vendorId;

    // Notify Vendor
    await createNotification(
      userId: resolvedVendorId,
      title: 'Dispute Raised',
      message: 'A customer has opened a dispute for booking #$bookingId.',
      type: NotificationType.disputeOpened,
      priority: NotificationPriority.urgent,
      severity: NotificationSeverity.urgent,
      relatedId: disputeId,
    );

    // Notify Admin
    await createNotification(
      userId: adminId,
      title: 'Dispute Raised',
      message: 'A dispute has been opened for booking #$bookingId.',
      type: NotificationType.disputeOpened,
      priority: NotificationPriority.urgent,
      severity: NotificationSeverity.urgent,
      relatedId: disputeId,
    );

    // Notify Customer (in-app confirmation)
    await createNotification(
      userId: customerId,
      title: 'Dispute Submitted',
      message: 'Your dispute has been submitted and is under review.',
      type: NotificationType.disputeOpened,
      priority: NotificationPriority.normal,
      severity: NotificationSeverity.info,
      relatedId: disputeId,
    );
  }

  Future<void> sendVendorDelayedNotification({
    required String customerId,
    required String adminId,
    required String bookingId,
    required int delayMinutes,
  }) async {
    // Notify Customer
    await createNotification(
      userId: customerId,
      title: 'Vendor Running Late',
      message: 'Your vendor is running approximately $delayMinutes minutes late.',
      type: NotificationType.vendorDelayed,
      priority: NotificationPriority.urgent,
      severity: NotificationSeverity.urgent,
      relatedId: bookingId,
    );

    // Notify Admin
    await createNotification(
      userId: adminId,
      title: 'Vendor Delayed',
      message: 'Vendor is delayed for booking #$bookingId.',
      type: NotificationType.vendorDelayed,
      priority: NotificationPriority.urgent,
      severity: NotificationSeverity.urgent,
      relatedId: bookingId,
    );
  }

  Future<void> _saveNotificationToDatabase(NotificationModel notification) async {
    try {
      final data = notification.toJson();
      print('DEBUG: Saving notification to database: $data');
      final response = await _supabase.from('notifications').insert(data);
      // print('DEBUG: Notification saved successfully: $response');
    } catch (e) {
      if (e is PostgrestException) {
        if (e.code == '23503') {
           print('DEBUG: Skipped saving notification due to missing user in auth.users (FK constraint): ${notification.userId}');
           return;
        } else if (e.code == 'PGRST205') {
           print('DEBUG: Skipped saving notification, ${e.message}');
           return;
        }
      }
      print('DEBUG WARNING: Error saving notification to database: $e');
    }
  }

  Future<void> _sendPushNotification(NotificationModel notification) async {
    await showLocalPopup(notification);
  }

  Future<void> showLocalPopup(NotificationModel notification) async {
    if (!_isInitialized) return;

    final androidDetails = AndroidNotificationDetails(
      'eventease_channel',
      'EventEase Notifications',
      channelDescription: 'Notifications for EventEase app',
      importance: _getImportance(notification.priority),
      priority: _getPriority(notification.priority),
      styleInformation: BigTextStyleInformation(notification.message),
    );

    const iOSDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      notification.id.hashCode,
      notification.title,
      notification.message,
      details,
      payload: json.encode(notification.toJson()),
    );
  }

  Future<void> _scheduleNotification(NotificationModel notification) async {
    if (!_isInitialized || notification.scheduledFor == null) return;

    final androidDetails = AndroidNotificationDetails(
      'eventease_scheduled_channel',
      'EventEase Scheduled Notifications',
      channelDescription: 'Scheduled notifications for EventEase app',
      importance: _getImportance(notification.priority),
      priority: _getPriority(notification.priority),
    );

    const iOSDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notification.id.hashCode,
      notification.title,
      notification.message,
      tz.TZDateTime.from(notification.scheduledFor!, tz.local),
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: json.encode(notification.toJson()),
    );
  }

  Future<void> _sendExternalNotifications(NotificationModel notification) async {
    // Get user settings
    final settings = await getNotificationSettings(notification.userId);
    if (settings == null) return;

    // Send email if enabled
    if (settings.emailEnabled && settings.enabledTypes.contains(notification.type)) {
      await _sendEmail(notification);
    }

    // Send SMS if enabled
    if (settings.smsEnabled && settings.enabledTypes.contains(notification.type)) {
      await _sendSMS(notification);
    }
  }

  Future<void> _sendEmail(NotificationModel notification) async {
    try {
      print('DEBUG: Sending email notification via Edge Function: ${notification.title}');
      final response = await _supabase.functions.invoke(
        'send-email',
        body: {
          'userId': notification.userId,
          'subject': notification.title,
          'body': notification.message,
          'notificationType': notification.type.name,
          'notificationId': notification.id,
        },
      );

      if (response.status == 200) {
        print('DEBUG: Email sent successfully for notification ${notification.id}');
      } else {
        print('DEBUG WARNING: Email Edge Function returned status ${response.status}: ${response.data}');
      }
    } catch (e) {
      // Non-fatal: external notification failure should not crash the main flow
      print('DEBUG WARNING: Failed to send email notification: $e');
    }
  }

  Future<void> _sendSMS(NotificationModel notification) async {
    try {
      print('DEBUG: Sending SMS notification via Edge Function: ${notification.title}');
      final response = await _supabase.functions.invoke(
        'send-sms',
        body: {
          'userId': notification.userId,
          'message': '${notification.title}: ${notification.message}',
          'notificationType': notification.type.name,
          'notificationId': notification.id,
        },
      );

      if (response.status == 200) {
        print('DEBUG: SMS sent successfully for notification ${notification.id}');
      } else {
        print('DEBUG WARNING: SMS Edge Function returned status ${response.status}: ${response.data}');
      }
    } catch (e) {
      // Non-fatal: external notification failure should not crash the main flow
      print('DEBUG WARNING: Failed to send SMS notification: $e');
    }
  }

  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }

  Priority _getPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.urgent:
        return Priority.max;
    }
  }

  // Get notifications for user
  Future<List<NotificationModel>> getNotifications(String userId, {
    bool includeRead = true,
    bool includeArchived = false,
    int limit = 50,
  }) async {
    try {
      dynamic query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId);

      if (!includeRead) {
        query = query.eq('is_read', false);
      }

      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }

      query = query
          .order('created_at', ascending: false)
          .limit(limit);

      final response = await query;
      return (response as List<dynamic>)
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for user
  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Archive notification
  Future<void> archiveNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_archived': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Error archiving notification: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Get notification settings
  Future<NotificationSettings?> getNotificationSettings(String userId) async {
    try {
      final response = await _supabase
          .from('notification_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        print('DEBUG: No notification settings found for user: $userId. Returning default settings.');
        return NotificationSettings(); // Return default settings
      }

      return NotificationSettings.fromJson(response);
    } catch (e) {
      print('DEBUG ERROR: Error fetching notification settings for user $userId: $e');
      return NotificationSettings(); // Fallback to defaults on error
    }
  }

  // Update notification settings
  Future<void> updateNotificationSettings(String userId, NotificationSettings settings) async {
    try {
      await _supabase
          .from('notification_settings')
          .upsert({
            'user_id': userId,
            ...settings.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      print('Error updating notification settings: $e');
    }
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .eq('is_archived', false);

      return (response as List).length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
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
    final notifications = userIds.map((userId) => NotificationModel(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      message: message,
      type: type,
      priority: priority,
      data: data,
      createdAt: DateTime.now(),
      actionUrl: actionUrl,
      imageUrl: imageUrl,
    )).toList();

    // Save to database in batch
    final jsonData = notifications.map((n) => n.toJson()).toList();
    try {
      await _supabase.from('notifications').insert(jsonData);
    } catch (e) {
      print('Error saving bulk notifications: $e');
    }

    // Send push notifications
    for (final notification in notifications) {
      await _sendPushNotification(notification);
      await _sendExternalNotifications(notification);
    }
  }

  // Cancel scheduled notification
  Future<void> cancelScheduledNotification(String notificationId) async {
    if (!_isInitialized) return;

    await _flutterLocalNotificationsPlugin.cancel(notificationId.hashCode);
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    if (!_isInitialized) return false;

    final androidGranted = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final iOSGranted = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    return (androidGranted ?? false) || (iOSGranted ?? false);
  }
}
