import 'package:flutter_test/flutter_test.dart';
import 'package:eventease/core/services/payment_service.dart';

void main() {
  group('Xendit Currency Validation Tests', () {
    test('PHP currency should throw ArgumentError immediately', () async {
      expect(
        () => PaymentService.createXenditInvoice(
          email: 'test@example.com',
          name: 'Test Payer',
          amount: 100.0,
          currency: 'PHP',
          externalId: 'test_ext_id',
          description: 'Test invoice',
          redirectUrl: 'https://example.com',
        ),
        throwsArgumentError,
      );
    });

    test('IDR currency should pass local validation (and attempt function invocation)', () async {
      try {
        await PaymentService.createXenditInvoice(
          email: 'test@example.com',
          name: 'Test Payer',
          amount: 100.0,
          currency: 'IDR',
          externalId: 'test_ext_id',
          description: 'Test invoice',
          redirectUrl: 'https://example.com',
        );
      } catch (e) {
        // It should pass local PHP validation, and fail on the uninitialized Supabase/Network calls
        expect(e.toString().contains('PHP currency is not supported'), isFalse);
      }
    });
  });
}
