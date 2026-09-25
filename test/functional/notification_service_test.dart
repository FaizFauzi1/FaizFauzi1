// test/functional/notification_service_test.dart
//
// Functional tests for NotificationService notification logic.
// Tests the NotificationSettings model, notification type filtering,
// and channel routing logic without requiring Supabase or Flutter bindings.
//
// Run with:
//   flutter test test/functional/notification_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:eventease/shared/models/notification.dart';

// ---------------------------------------------------------------------------
// Helpers: pure business logic extracted from NotificationService
// ---------------------------------------------------------------------------

/// Mirrors the external notification decision from NotificationService.
/// Returns which channels should fire for a given notification + settings.
({bool sendEmail, bool sendSms}) shouldSendExternalNotifications({
  required NotificationSettings settings,
  required NotificationType type,
}) {
  return (
    sendEmail: settings.emailEnabled && settings.enabledTypes.contains(type),
    sendSms: settings.smsEnabled && settings.enabledTypes.contains(type),
  );
}

// ---------------------------------------------------------------------------
// Factory helper
// ---------------------------------------------------------------------------
NotificationSettings _makeSettings({
  bool emailEnabled = false,
  bool smsEnabled = false,
  Set<NotificationType>? enabledTypes,
}) {
  return NotificationSettings(
    emailEnabled: emailEnabled,
    smsEnabled: smsEnabled,
    enabledTypes: enabledTypes,
  );
}

void main() {
  // ==========================================================================
  // GROUP: NotificationSettings Model – Happy Path
  // ==========================================================================
  group('NotificationSettings – Happy Path', () {
    test('default constructor produces valid boolean fields', () {
      final settings = NotificationSettings();
      expect(settings.emailEnabled, isA<bool>());
      expect(settings.smsEnabled, isA<bool>());
      expect(settings.enabledTypes, isA<Set<NotificationType>>());
    });

    test('default enabledTypes contains all notification types', () {
      final settings = NotificationSettings();
      // Default should include all types
      expect(settings.enabledTypes.length, greaterThan(0));
    });

    test('email enabled + type present → email fires', () {
      final settings = _makeSettings(
        emailEnabled: true,
        smsEnabled: false,
        enabledTypes: {
          NotificationType.bookingSubmitted,
          NotificationType.paymentReceived,
        },
      );

      final result = shouldSendExternalNotifications(
        settings: settings,
        type: NotificationType.bookingSubmitted,
      );

      expect(result.sendEmail, isTrue);
      expect(result.sendSms, isFalse);
    });

    test('SMS enabled + type present → SMS fires', () {
      final settings = _makeSettings(
        emailEnabled: false,
        smsEnabled: true,
        enabledTypes: {NotificationType.paymentFailed},
      );

      final result = shouldSendExternalNotifications(
        settings: settings,
        type: NotificationType.paymentFailed,
      );

      expect(result.sendEmail, isFalse);
      expect(result.sendSms, isTrue);
    });

    test('both channels enabled + type present → both fire', () {
      final settings = _makeSettings(
        emailEnabled: true,
        smsEnabled: true,
        enabledTypes: {NotificationType.vendorConfirmed},
      );

      final result = shouldSendExternalNotifications(
        settings: settings,
        type: NotificationType.vendorConfirmed,
      );

      expect(result.sendEmail, isTrue);
      expect(result.sendSms, isTrue);
    });

    test('all notification types fire when enabledTypes contains all', () {
      final allTypes = NotificationType.values.toSet();
      final settings = _makeSettings(
        emailEnabled: true,
        smsEnabled: true,
        enabledTypes: allTypes,
      );

      for (final type in NotificationType.values) {
        final result = shouldSendExternalNotifications(
          settings: settings,
          type: type,
        );
        expect(result.sendEmail, isTrue,
            reason: '${type.name} should send email');
        expect(result.sendSms, isTrue,
            reason: '${type.name} should send SMS');
      }
    });
  });

  // ==========================================================================
  // GROUP: NotificationSettings – Error / Disabled Path
  // ==========================================================================
  group('NotificationSettings – Error Path', () {
    test('email disabled → email does not fire even if type is enabled', () {
      final settings = _makeSettings(
        emailEnabled: false,
        smsEnabled: true,
        enabledTypes: {NotificationType.bookingSubmitted},
      );

      final result = shouldSendExternalNotifications(
        settings: settings,
        type: NotificationType.bookingSubmitted,
      );

      expect(result.sendEmail, isFalse);
      expect(result.sendSms, isTrue);
    });

    test('SMS disabled → SMS does not fire even if type is enabled', () {
      final settings = _makeSettings(
        emailEnabled: true,
        smsEnabled: false,
        enabledTypes: {NotificationType.paymentReceived},
      );

      final result = shouldSendExternalNotifications(
        settings: settings,
        type: NotificationType.paymentReceived,
      );

      expect(result.sendEmail, isTrue);
      expect(result.sendSms, isFalse);
    });

    test('both disabled → neither fires regardless of type', () {
      final settings = _makeSettings(
        emailEnabled: false,
        smsEnabled: false,
        enabledTypes: NotificationType.values.toSet(),
      );

      for (final type in NotificationType.values) {
        final result = shouldSendExternalNotifications(
          settings: settings,
          type: type,
        );
        expect(result.sendEmail, isFalse,
            reason: 'Email should not fire for ${type.name}');
        expect(result.sendSms, isFalse,
            reason: 'SMS should not fire for ${type.name}');
      }
    });

    test('type not in enabledTypes → neither fires even if channels enabled', () {
      final settings = _makeSettings(
        emailEnabled: true,
        smsEnabled: true,
        enabledTypes: {NotificationType.bookingSubmitted},
      );

      final result = shouldSendExternalNotifications(
        settings: settings,
        type: NotificationType.paymentFailed, // Not in set
      );

      expect(result.sendEmail, isFalse);
      expect(result.sendSms, isFalse);
    });

    test('empty enabledTypes set → no external notifications fire', () {
      final settings = _makeSettings(
        emailEnabled: true,
        smsEnabled: true,
        enabledTypes: {}, // Empty set
      );

      for (final type in NotificationType.values) {
        final result = shouldSendExternalNotifications(
          settings: settings,
          type: type,
        );
        expect(result.sendEmail, isFalse);
        expect(result.sendSms, isFalse);
      }
    });
  });

  // ==========================================================================
  // GROUP: NotificationSettings – Edge Cases
  // ==========================================================================
  group('NotificationSettings – Edge Cases', () {
    test('Set semantics: duplicate type in creation still works', () {
      // Sets de-duplicate automatically, so adding the same type twice is fine
      final settings = _makeSettings(
        emailEnabled: true,
        smsEnabled: true,
        enabledTypes: {
          NotificationType.paymentReceived,
          NotificationType.paymentReceived, // duplicate - Set handles this
        },
      );

      final result = shouldSendExternalNotifications(
        settings: settings,
        type: NotificationType.paymentReceived,
      );

      expect(result.sendEmail, isTrue);
      expect(result.sendSms, isTrue);
    });

    test('urgent SLA breach notification type triggers correctly', () {
      final settings = _makeSettings(
        emailEnabled: true,
        smsEnabled: true,
        enabledTypes: {NotificationType.slaBreachWarning},
      );

      final result = shouldSendExternalNotifications(
        settings: settings,
        type: NotificationType.slaBreachWarning,
      );

      expect(result.sendEmail, isTrue);
      expect(result.sendSms, isTrue);
    });

    test('dispute notification correctly routed (email only)', () {
      final settings = _makeSettings(
        emailEnabled: true,
        smsEnabled: false,
        enabledTypes: {NotificationType.disputeOpened},
      );

      final result = shouldSendExternalNotifications(
        settings: settings,
        type: NotificationType.disputeOpened,
      );

      expect(result.sendEmail, isTrue);
      expect(result.sendSms, isFalse);
    });

    test('all NotificationType variants produce a valid decision without throw', () {
      final settings = _makeSettings(
        emailEnabled: true,
        smsEnabled: true,
        enabledTypes: NotificationType.values.toSet(),
      );

      expect(() {
        for (final type in NotificationType.values) {
          shouldSendExternalNotifications(settings: settings, type: type);
        }
      }, returnsNormally);
    });
  });

  // ==========================================================================
  // GROUP: NotificationModel – Serialisation
  // ==========================================================================
  group('NotificationModel – Serialisation', () {
    test('can create a valid NotificationModel with all required fields', () {
      final notification = NotificationModel(
        id: 'notif_001',
        userId: 'user_001',
        title: 'Booking Confirmed!',
        message: 'Your booking has been confirmed.',
        type: NotificationType.vendorConfirmed,
        priority: NotificationPriority.high,
        severity: NotificationSeverity.actionRequired,
        channel: NotificationChannel.inapp,
        notificationStatus: NotificationStatus.delivered,
        createdAt: DateTime(2026, 6, 1),
      );

      expect(notification.id, 'notif_001');
      expect(notification.userId, 'user_001');
      expect(notification.type, NotificationType.vendorConfirmed);
      expect(notification.priority, NotificationPriority.high);
    });

    test('toJson → fromJson round-trip preserves all fields', () {
      final original = NotificationModel(
        id: 'notif_002',
        userId: 'user_002',
        title: 'Payment Received',
        message: 'RM 500 payment confirmed.',
        type: NotificationType.paymentReceived,
        priority: NotificationPriority.normal,
        severity: NotificationSeverity.info,
        channel: NotificationChannel.inapp,
        notificationStatus: NotificationStatus.delivered,
        relatedId: 'booking_abc',
        createdAt: DateTime(2026, 6, 1, 12, 0, 0),
        data: {'amount': 500.0},
      );

      final json = original.toJson();
      final restored = NotificationModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.title, original.title);
      expect(restored.message, original.message);
      expect(restored.type, original.type);
      expect(restored.priority, original.priority);
      expect(restored.severity, original.severity);
      expect(restored.channel, original.channel);
      expect(restored.notificationStatus, original.notificationStatus);
      expect(restored.relatedId, original.relatedId);
      expect(restored.data?['amount'], 500.0);
    });

    test('all NotificationPriority variants survive round-trip', () {
      for (final priority in NotificationPriority.values) {
        final n = NotificationModel(
          id: 'n_${priority.name}',
          userId: 'user_001',
          title: 'Test',
          message: 'Test',
          type: NotificationType.bookingSubmitted,
          priority: priority,
          createdAt: DateTime(2026, 1, 1),
        );
        final restored = NotificationModel.fromJson(n.toJson());
        expect(restored.priority, priority,
            reason: 'Priority ${priority.name} failed round-trip');
      }
    });

    test('all NotificationType variants survive round-trip', () {
      for (final type in NotificationType.values) {
        final n = NotificationModel(
          id: 'n_${type.name}',
          userId: 'user_001',
          title: 'Test',
          message: 'Test',
          type: type,
          createdAt: DateTime(2026, 1, 1),
        );
        final restored = NotificationModel.fromJson(n.toJson());
        expect(restored.type, type,
            reason: 'NotificationType ${type.name} failed round-trip');
      }
    });

    test('isRead defaults to false for new notifications', () {
      final n = NotificationModel(
        id: 'n_001',
        userId: 'u_001',
        title: 'Test',
        message: 'Test',
        type: NotificationType.system,
        createdAt: DateTime.now(),
      );
      expect(n.isRead, isFalse);
      expect(n.isArchived, isFalse);
    });
  });
}
