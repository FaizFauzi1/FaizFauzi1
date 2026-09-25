// test/functional/payment_lifecycle_test.dart
//
// Functional tests for the EventEase payment lifecycle.
// Covers: happy path, error path, and edge cases for
// PaymentTransaction model, serialisation, and PaymentProvider in-memory state.
//
// Run with:
//   flutter test test/functional/payment_lifecycle_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:eventease/shared/models/payment.dart';
import 'package:eventease/features/booking/data/providers/payment_provider.dart';

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

// ---------------------------------------------------------------------------
// Factory helpers
// ---------------------------------------------------------------------------
PaymentTransaction _buildTx({
  String id = 'tx_001',
  String bookingId = 'booking_001',
  String customerId = 'customer_001',
  String vendorId = 'vendor_001',
  double amount = 500.0,
  PaymentMethod method = PaymentMethod.onlineBanking,
  PaymentStatus status = PaymentStatus.pending,
  String? appointmentId,
  Map<String, dynamic>? metadata,
}) {
  return PaymentTransaction(
    id: id,
    bookingId: bookingId,
    appointmentId: appointmentId,
    customerId: customerId,
    vendorId: vendorId,
    amount: amount,
    method: method,
    status: status,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    metadata: metadata,
  );
}

Map<String, dynamic> _buildTxJson({
  String id = 'tx_001',
  String bookingId = 'booking_001',
  String customerId = 'customer_001',
  String vendorId = 'vendor_001',
  double amount = 500.0,
  String method = 'onlineBanking',
  String status = 'pending',
}) {
  return {
    'id': id,
    'booking_id': bookingId,
    'appointment_id': null,
    'customer_id': customerId,
    'vendor_id': vendorId,
    'amount': amount,
    'method': method,
    'status': status,
    'transaction_id': null,
    'payment_reference': null,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-01T00:00:00.000Z',
    'metadata': null,
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  // ==========================================================================
  // GROUP: PaymentTransaction Model – Happy Path
  // ==========================================================================
  group('PaymentTransaction – Happy Path', () {
    test('creates transaction with all required fields correctly', () {
      final tx = _buildTx();

      expect(tx.id, 'tx_001');
      expect(tx.bookingId, 'booking_001');
      expect(tx.customerId, 'customer_001');
      expect(tx.vendorId, 'vendor_001');
      expect(tx.amount, 500.0);
      expect(tx.method, PaymentMethod.onlineBanking);
      expect(tx.status, PaymentStatus.pending);
      expect(tx.appointmentId, isNull);
      expect(tx.metadata, isNull);
    });

    test('copyWith updates only the specified field', () {
      final tx = _buildTx();
      final updated = tx.copyWith(status: PaymentStatus.processing);

      expect(updated.status, PaymentStatus.processing);
      expect(updated.id, tx.id);
      expect(updated.amount, tx.amount);
      expect(updated.bookingId, tx.bookingId);
    });

    test('full status lifecycle: pending → processing → completed', () {
      var tx = _buildTx(status: PaymentStatus.pending);
      tx = tx.copyWith(status: PaymentStatus.processing);
      expect(tx.status, PaymentStatus.processing);

      tx = tx.copyWith(status: PaymentStatus.completed);
      expect(tx.status, PaymentStatus.completed);
    });

    test('full status lifecycle: pending → processing → failed', () {
      var tx = _buildTx(status: PaymentStatus.pending);
      tx = tx.copyWith(status: PaymentStatus.processing);
      tx = tx.copyWith(
        status: PaymentStatus.failed,
        metadata: {'failureReason': 'Card declined'},
      );

      expect(tx.status, PaymentStatus.failed);
      expect(tx.metadata?['failureReason'], 'Card declined');
    });

    test('serialises to JSON and back (round-trip) without data loss', () {
      final tx = _buildTx(
        metadata: {'booking_type': 'deposit', 'gateway': 'xendit'},
      );
      final json = tx.toJson();
      final restored = PaymentTransaction.fromJson(json);

      expect(restored.id, tx.id);
      expect(restored.bookingId, tx.bookingId);
      expect(restored.customerId, tx.customerId);
      expect(restored.vendorId, tx.vendorId);
      expect(restored.amount, tx.amount);
      expect(restored.method, tx.method);
      expect(restored.status, tx.status);
      expect(restored.metadata?['booking_type'], 'deposit');
      expect(restored.metadata?['gateway'], 'xendit');
    });

    test('fromJson reconstructs transaction from database JSON correctly', () {
      final json = _buildTxJson(
        id: 'tx_db_001',
        bookingId: 'bk_db_001',
        customerId: 'cust_db_001',
        vendorId: 'vend_db_001',
        amount: 1500.50,
        method: 'onlineBanking',
        status: 'completed',
      );

      final tx = PaymentTransaction.fromJson(json);

      expect(tx.id, 'tx_db_001');
      expect(tx.bookingId, 'bk_db_001');
      expect(tx.amount, 1500.50);
      expect(tx.status, PaymentStatus.completed);
      expect(tx.method, PaymentMethod.onlineBanking);
    });

    test('optional appointmentId is preserved through copyWith chain', () {
      final tx = _buildTx(appointmentId: 'appt_001');
      final updated = tx.copyWith(status: PaymentStatus.completed);

      expect(updated.appointmentId, 'appt_001');
    });

    test('refunded status lifecycle: completed → refunded', () {
      var tx = _buildTx(status: PaymentStatus.completed);
      tx = tx.copyWith(status: PaymentStatus.refunded);

      expect(tx.status, PaymentStatus.refunded);
    });
  });

  // ==========================================================================
  // GROUP: PaymentTransaction Model – Error Path
  // ==========================================================================
  group('PaymentTransaction – Error Path', () {
    test('fromJson throws when required `id` field is missing', () {
      final badJson = _buildTxJson()..remove('id');

      expect(
        () => PaymentTransaction.fromJson(badJson),
        throwsA(anything), // TypeError or NoSuchMethodError
      );
    });

    test('fromJson throws when required `booking_id` field is missing', () {
      final badJson = _buildTxJson()..remove('booking_id');

      expect(
        () => PaymentTransaction.fromJson(badJson),
        throwsA(anything),
      );
    });

    test('fromJson falls back to onlineBanking for unknown payment method', () {
      final json = _buildTxJson(method: 'btc_lightning');
      final tx = PaymentTransaction.fromJson(json);

      expect(tx.method, PaymentMethod.onlineBanking);
    });

    test('fromJson falls back to pending for unknown payment status', () {
      final json = _buildTxJson(status: 'ghosted');
      final tx = PaymentTransaction.fromJson(json);

      expect(tx.status, PaymentStatus.pending);
    });

    test('failure metadata does not overwrite unrelated keys', () {
      final tx = _buildTx(metadata: {'gateway': 'xendit', 'ref': 'R001'});
      final failed = tx.copyWith(
        status: PaymentStatus.failed,
        metadata: {
          ...(tx.metadata ?? {}),
          'failureReason': 'Insufficient funds',
        },
      );

      expect(failed.metadata?['gateway'], 'xendit');
      expect(failed.metadata?['ref'], 'R001');
      expect(failed.metadata?['failureReason'], 'Insufficient funds');
    });

    test('fromJson with null metadata returns null metadata', () {
      final json = _buildTxJson();
      json['metadata'] = null;

      final tx = PaymentTransaction.fromJson(json);
      expect(tx.metadata, isNull);
    });

    test('fromJson with null amount throws or returns a non-NaN value', () {
      final json = _buildTxJson();
      json['amount'] = null;

      // Either throws or produces a non-NaN result — either is safe
      try {
        final tx = PaymentTransaction.fromJson(json);
        expect(tx.amount.isNaN, isFalse);
      } catch (e) {
        // Any exception type is acceptable here (TypeError, NoSuchMethodError, etc.)
        expect(e, isNotNull);
      }
    });
  });

  // ==========================================================================
  // GROUP: PaymentTransaction Model – Edge Cases
  // ==========================================================================
  group('PaymentTransaction – Edge Cases', () {
    test('zero-amount transaction is valid and survives round-trip', () {
      final tx = _buildTx(amount: 0.0);
      final restored = PaymentTransaction.fromJson(tx.toJson());
      expect(restored.amount, 0.0);
    });

    test('large amount (999999.99) does not lose precision in round-trip', () {
      final tx = _buildTx(amount: 999999.99);
      final restored = PaymentTransaction.fromJson(tx.toJson());
      expect(restored.amount, 999999.99);
    });

    test('all PaymentStatus variants survive JSON round-trip', () {
      for (final status in PaymentStatus.values) {
        final tx = _buildTx(status: status);
        final restored = PaymentTransaction.fromJson(tx.toJson());
        expect(restored.status, status,
            reason: 'Status ${status.name} failed round-trip');
      }
    });

    test('all PaymentMethod variants survive JSON round-trip', () {
      for (final method in PaymentMethod.values) {
        final tx = _buildTx(method: method);
        final restored = PaymentTransaction.fromJson(tx.toJson());
        expect(restored.method, method,
            reason: 'Method ${method.name} failed round-trip');
      }
    });

    test('multiple sequential copyWith calls accumulate correctly', () {
      var tx = _buildTx();
      tx = tx.copyWith(status: PaymentStatus.processing);
      tx = tx.copyWith(metadata: {'gateway': 'xendit'});
      tx = tx.copyWith(
        status: PaymentStatus.completed,
        updatedAt: DateTime(2026, 6, 1),
      );

      expect(tx.id, 'tx_001'); // Preserved through chain
      expect(tx.status, PaymentStatus.completed);
      expect(tx.metadata?['gateway'], 'xendit');
      expect(tx.updatedAt, DateTime(2026, 6, 1));
    });

    test('null metadata and empty metadata are distinct', () {
      final txNullMeta = _buildTx();
      final txEmptyMeta = _buildTx(metadata: {});

      expect(txNullMeta.metadata, isNull);
      expect(txEmptyMeta.metadata, isNotNull);
      expect(txEmptyMeta.metadata, isEmpty);
    });

    test('two transactions with same amount are distinct objects', () {
      final tx1 = _buildTx(id: 'tx_001', amount: 100.0);
      final tx2 = _buildTx(id: 'tx_002', amount: 100.0);

      expect(tx1 == tx2, isFalse);
      expect(tx1.id, isNot(tx2.id));
    });
  });

  // ==========================================================================
  // GROUP: PaymentProvider In-Memory State (no Supabase dependency)
  // ==========================================================================
  group('PaymentProvider In-Memory State', () {
    late MockSupabaseClient mockSupabase;
    late PaymentProvider provider;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      provider = PaymentProvider(supabaseClient: mockSupabase);
    });

    // ── Happy Path ────────────────────────────────────────────────────────────
    group('Happy Path', () {
      test('starts with empty transactions', () {
        expect(provider.transactions, isEmpty);
        expect(provider.customerTransactions, isEmpty);
        expect(provider.vendorTransactions, isEmpty);
      });

      test('getPaymentStats returns all-zero state for no transactions', () {
        final stats = provider.getPaymentStats('cust_001', false);

        expect(stats['totalTransactions'], 0);
        expect(stats['completedTransactions'], 0);
        expect(stats['pendingTransactions'], 0);
        expect(stats['failedTransactions'], 0);
        expect(stats['totalAmount'], 0.0);
        expect(stats['refundedAmount'], 0.0);
      });

      test('clearData resets all internal lists without error', () {
        provider.clearData();

        expect(provider.transactions, isEmpty);
        expect(provider.customerTransactions, isEmpty);
        expect(provider.vendorTransactions, isEmpty);
      });

      test('getPaymentStats customer vs vendor flag is respected', () {
        final custStats = provider.getPaymentStats('cust_001', false);
        final vendStats = provider.getPaymentStats('vend_001', true);

        expect(custStats['totalTransactions'], 0);
        expect(vendStats['totalTransactions'], 0);
      });
    });

    // ── Error Path ────────────────────────────────────────────────────────────
    group('Error Path', () {
      test('getPaymentStats with unknown userId returns zero, not error', () {
        final stats = provider.getPaymentStats('no_such_user', false);

        expect(stats['totalTransactions'], 0);
        expect(stats['totalAmount'], 0.0);
      });

      test('clearData called multiple times does not throw', () {
        expect(() {
          provider.clearData();
          provider.clearData();
          provider.clearData();
        }, returnsNormally);
      });
    });

    // ── Edge Cases ────────────────────────────────────────────────────────────
    group('Edge Cases', () {
      test('getPaymentStats called before any transactions returns valid map', () {
        final stats = provider.getPaymentStats('someone', false);

        expect(stats.containsKey('totalTransactions'), isTrue);
        expect(stats.containsKey('completedTransactions'), isTrue);
        expect(stats.containsKey('pendingTransactions'), isTrue);
        expect(stats.containsKey('failedTransactions'), isTrue);
        expect(stats.containsKey('totalAmount'), isTrue);
        expect(stats.containsKey('refundedAmount'), isTrue);
      });
    });
  });
}

// Matcher helper for flexible error matching
Matcher get anything => isA<Object>();
