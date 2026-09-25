import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/shared/models/admin_notification.dart';
import 'package:eventease/features/support/data/models/support_ticket.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class AdminNotificationService {
  static final AdminNotificationService _instance = AdminNotificationService._internal();
  factory AdminNotificationService() => _instance;
  AdminNotificationService._internal();

  static String? _sanitizeRelatedId(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'null') return null;
    return trimmed;
  }

  Future<void> createAdminNotification({
    required AdminNotificationType type,
    required AdminNotificationSeverity severity,
    required String title,
    required String message,
    String? relatedUserId,
    String? relatedVendorId,
    String? relatedBookingId,
    String? actionUrl,
  }) async {
    final payload = <String, dynamic>{
      'id': const Uuid().v4(),
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'message': message,
      'status': AdminNotificationStatus.unread.name,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    final userId = _sanitizeRelatedId(relatedUserId);
    final vendorId = _sanitizeRelatedId(relatedVendorId);
    final bookingId = _sanitizeRelatedId(relatedBookingId);
    final url = _sanitizeRelatedId(actionUrl);
    if (userId != null) payload['related_user_id'] = userId;
    if (vendorId != null) payload['related_vendor_id'] = vendorId;
    if (bookingId != null) payload['related_booking_id'] = bookingId;
    if (url != null) payload['action_url'] = url;

    try {
      if (kDebugMode) {
        debugPrint('DEBUG: Attempting to insert admin notification: "$title"');
        debugPrint('DEBUG: Data: $payload');
      }
      // Insert without .select() so vendors/customers can write even if they
      // cannot read admin_notifications (RLS).
      await SupabaseService.client.from('admin_notifications').insert(payload);
      if (kDebugMode) debugPrint('DEBUG: Notification insert successful');
    } catch (e) {
      if (kDebugMode) debugPrint('DEBUG: Notification insert FAILED: $e');
      final err = e.toString();
      if (err.contains('PGRST205') || err.contains('Could not find the table')) {
        debugPrint('Skipped admin notification — run 20260917_fix_admin_notifications_and_vendor_expos.sql');
        return;
      }
      // Retry without related IDs if FK / type mismatch blocked the insert.
      if (payload.containsKey('related_user_id') ||
          payload.containsKey('related_vendor_id') ||
          payload.containsKey('related_booking_id')) {
        try {
          payload
            ..remove('related_user_id')
            ..remove('related_vendor_id')
            ..remove('related_booking_id');
          await SupabaseService.client.from('admin_notifications').insert(payload);
          if (kDebugMode) debugPrint('DEBUG: Notification insert succeeded after stripping related IDs');
          return;
        } catch (retryError) {
          debugPrint('Error creating admin notification (retry): $retryError');
        }
      }
      debugPrint('Error creating admin notification: $e');
    }
  }

  // Trigger: Any New Booking (Handles high-value alerts too)
  Future<void> notifyNewBooking(String bookingId, double amount, String customerName, String vendorName) async {
    final bool isHighValue = amount >= 5000;
    
    await createAdminNotification(
      type: AdminNotificationType.booking,
      severity: isHighValue ? AdminNotificationSeverity.high : AdminNotificationSeverity.low,
      title: isHighValue ? '🔥 High Value Booking Alert' : 'New Booking Created',
      message: isHighValue 
        ? 'URGENT: $customerName created a HIGH VALUE booking with $vendorName for RM ${amount.toStringAsFixed(2)}!'
        : '$customerName created a booking with $vendorName for RM ${amount.toStringAsFixed(2)}.',
      relatedBookingId: bookingId,
    );
  }

  // Sample Trigger: Vendor Onboarding
  Future<void> notifyNewVendorRegistration(String vendorId, String vendorName) async {
    await createAdminNotification(
      type: AdminNotificationType.onboarding,
      severity: AdminNotificationSeverity.medium,
      title: 'New Vendor Registration',
      message: 'A new vendor, $vendorName, has registered and is awaiting document verification.',
      relatedVendorId: vendorId,
    );
  }

  // Trigger: Payment Failure
  Future<void> notifyPaymentFailure(String bookingId, String customerName, String reason) async {
    await createAdminNotification(
      type: AdminNotificationType.risk,
      severity: AdminNotificationSeverity.high,
      title: 'Payment Failed',
      message: 'Payment for booking #$bookingId by $customerName failed. Reason: $reason',
      relatedBookingId: bookingId,
    );
  }

  // Trigger: Service Creation or Edit
  Future<void> notifyServiceUpdate({
    required String vendorId,
    required String vendorName,
    required String serviceName,
    required String serviceId,
    required bool isNew,
  }) async {
    await createAdminNotification(
      type: AdminNotificationType.vendor,
      severity: isNew ? AdminNotificationSeverity.medium : AdminNotificationSeverity.low,
      title: isNew ? 'New Service Created' : 'Service Updated',
      message: isNew 
          ? 'Vendor "$vendorName" created a new service: "$serviceName". Awaiting review.'
          : 'Vendor "$vendorName" updated their service: "$serviceName". Awaiting review.',
      relatedVendorId: vendorId,
      actionUrl: '/admin/services/$serviceId',
    );
  }

  // Trigger: New Support Ticket
  Future<void> notifyNewSupportTicket(SupportTicket ticket) async {
    final bool isLiveChat = ticket.subject == 'Live Support Session';
    
    await createAdminNotification(
      type: AdminNotificationType.support,
      severity: isLiveChat 
          ? AdminNotificationSeverity.critical 
          : (ticket.priority == TicketPriority.urgent || ticket.priority == TicketPriority.high
              ? AdminNotificationSeverity.high
              : AdminNotificationSeverity.medium),
      title: isLiveChat ? '🔴 LIVE CHAT REQUEST' : 'New Support Ticket: ${ticket.subject}',
      message: isLiveChat
          ? 'URGENT: ${ticket.customerName} is waiting for a LIVE CHAT session. Please respond immediately.'
          : 'User "${ticket.customerName}" has opened a new support ticket in the ${ticket.category.toString().split('.').last} category.',
      relatedUserId: ticket.customerId,
      actionUrl: '/admin/support/${ticket.id}',
    );
  }

  // Trigger: New Message in Support Ticket
  Future<void> notifyNewSupportMessage({
    required String ticketId,
    required String customerName,
    required String messageSnippet,
  }) async {
    await createAdminNotification(
      type: AdminNotificationType.support,
      severity: AdminNotificationSeverity.low,
      title: 'New Support Message from $customerName',
      message: 'Reply in ticket #$ticketId: ${messageSnippet.length > 50 ? "${messageSnippet.substring(0, 47)}..." : messageSnippet}',
      relatedUserId: null, 
      actionUrl: '/admin/support/$ticketId',
    );
  }

  // Stream admin notifications in real-time
  Stream<List<AdminNotificationModel>> adminNotificationsStream() {
    return SupabaseService.client
        .from('admin_notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => AdminNotificationModel.fromJson(json)).toList());
  }

  // Fetch admin notifications
  Future<List<AdminNotificationModel>> getAdminNotifications() async {
    try {
      final response = await SupabaseService.client
          .from('admin_notifications')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => AdminNotificationModel.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching admin notifications: $e');
      return [];
    }
  }

  // Mark admin notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await SupabaseService.client
          .from('admin_notifications')
          .update({'status': 'read'})
          .eq('id', notificationId);
    } catch (e) {
      print('Error marking admin notification as read: $e');
    }
  }
}
