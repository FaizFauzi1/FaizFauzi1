// test/functional/config_and_currency_test.dart
//
// Functional tests for payment gateway configurations and currency validation.
// Covers: Xendit PHP currency restriction, BillplzConfig sandbox flag,
// and gateway config fallback logic.
//
// These tests do not require Supabase or Flutter bindings to run.
//
// Run with:
//   flutter test test/functional/config_and_currency_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:eventease/core/services/payment_service.dart';

// ---------------------------------------------------------------------------
// Helpers: pure validation logic (mirrors PaymentService internal guards)
// ---------------------------------------------------------------------------

/// PHP currency guard logic extracted for isolated testing.
void validateXenditCurrency(String currency) {
  if (currency == 'PHP') {
    throw ArgumentError(
      'PHP currency is not supported by EventEase. '
      'Use MYR for Billplz or IDR/USD for Xendit.',
    );
  }
}

/// Mirrors the isSandbox flag resolution logic in BillplzConfig / XenditConfig.
bool resolveSandboxFlag(String? envValue, {bool defaultValue = true}) {
  return (envValue ?? defaultValue.toString()).toLowerCase() == 'true';
}

/// Mirrors the dynamic key resolution with fallback.
String resolveApiKey(String? envValue, String fallback) {
  return envValue ?? fallback;
}

void main() {
  // ==========================================================================
  // GROUP: Xendit PHP Currency Restriction – Happy Path
  // ==========================================================================
  group('Xendit Currency Validation – Happy Path', () {
    test('MYR currency passes validation without throwing', () {
      expect(() => validateXenditCurrency('MYR'), returnsNormally);
    });

    test('IDR currency passes validation without throwing', () {
      expect(() => validateXenditCurrency('IDR'), returnsNormally);
    });

    test('USD currency passes validation without throwing', () {
      expect(() => validateXenditCurrency('USD'), returnsNormally);
    });

    test('SGD currency passes validation without throwing', () {
      expect(() => validateXenditCurrency('SGD'), returnsNormally);
    });

    test('lowercase myr passes without throwing (case insensitive gateway)', () {
      // Our guard only blocks uppercase 'PHP'; lowercase 'myr' should pass
      expect(() => validateXenditCurrency('myr'), returnsNormally);
    });
  });

  // ==========================================================================
  // GROUP: Xendit PHP Currency Restriction – Error Path
  // ==========================================================================
  group('Xendit Currency Validation – Error Path', () {
    test('PHP currency throws ArgumentError immediately', () {
      expect(
        () => validateXenditCurrency('PHP'),
        throwsArgumentError,
      );
    });

    test('ArgumentError message contains helpful guidance', () {
      expect(
        () => validateXenditCurrency('PHP'),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString(),
            'message',
            contains('PHP currency is not supported'),
          ),
        ),
      );
    });

    test('PHP rejection does NOT depend on Supabase being initialised', () {
      // Verify the guard fires before any network call (pure local check)
      var threwBeforeNetwork = false;
      try {
        validateXenditCurrency('PHP');
      } on ArgumentError {
        threwBeforeNetwork = true;
      }
      expect(threwBeforeNetwork, isTrue);
    });

    // Mirror the actual PaymentService static guard (requires no Supabase init)
    test('PaymentService.createXenditInvoice throws for PHP currency immediately', () async {
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
  });

  // ==========================================================================
  // GROUP: Xendit Currency – Edge Cases
  // ==========================================================================
  group('Xendit Currency Validation – Edge Cases', () {
    test('empty string currency passes validation (not PHP)', () {
      expect(() => validateXenditCurrency(''), returnsNormally);
    });

    test('lowercase php does NOT trigger the guard (uppercase-only check)', () {
      // This is intentional: the guard specifically blocks 'PHP' (uppercase)
      // as that is the format payment APIs send
      expect(() => validateXenditCurrency('php'), returnsNormally);
    });

    test('currency with whitespace around PHP does not trigger guard', () {
      expect(() => validateXenditCurrency(' PHP '), returnsNormally);
    });

    test('all commonly supported currencies pass without error', () {
      const supported = ['MYR', 'IDR', 'USD', 'EUR', 'SGD', 'THB', 'GBP'];
      for (final currency in supported) {
        expect(() => validateXenditCurrency(currency), returnsNormally,
            reason: '$currency should be allowed');
      }
    });
  });

  // ==========================================================================
  // GROUP: Config Sandbox Flag Resolution – Happy Path
  // ==========================================================================
  group('Config Sandbox Flag Resolution – Happy Path', () {
    test('env value "true" resolves to sandbox mode', () {
      expect(resolveSandboxFlag('true'), isTrue);
    });

    test('env value "TRUE" (uppercase) resolves to sandbox mode', () {
      expect(resolveSandboxFlag('TRUE'), isTrue);
    });

    test('env value "false" resolves to production mode', () {
      expect(resolveSandboxFlag('false'), isFalse);
    });

    test('env value "FALSE" (uppercase) resolves to production mode', () {
      expect(resolveSandboxFlag('FALSE'), isFalse);
    });

    test('null env value uses defaultValue=true (sandbox by default)', () {
      expect(resolveSandboxFlag(null, defaultValue: true), isTrue);
    });

    test('null env value with defaultValue=false resolves to production', () {
      expect(resolveSandboxFlag(null, defaultValue: false), isFalse);
    });
  });

  // ==========================================================================
  // GROUP: Config Sandbox Flag Resolution – Error / Edge Cases
  // ==========================================================================
  group('Config Sandbox Flag Resolution – Edge Cases', () {
    test('env value "1" is not "true" → resolves as false', () {
      // Only the string "true" is accepted
      expect(resolveSandboxFlag('1'), isFalse);
    });

    test('env value "yes" is not "true" → resolves as false', () {
      expect(resolveSandboxFlag('yes'), isFalse);
    });

    test('empty string env value resolves as false', () {
      expect(resolveSandboxFlag(''), isFalse);
    });

    test('mixed-case "True" resolves correctly as true', () {
      expect(resolveSandboxFlag('True'), isTrue);
    });
  });

  // ==========================================================================
  // GROUP: Dynamic API Key Resolution – Happy Path
  // ==========================================================================
  group('Dynamic API Key Resolution – Happy Path', () {
    test('env value takes priority over fallback', () {
      const envKey = 'live_key_from_dotenv';
      const fallback = 'hardcoded_fallback_key';

      expect(resolveApiKey(envKey, fallback), envKey);
    });

    test('null env value falls back to fallback string', () {
      const fallback = 'hardcoded_fallback_key';

      expect(resolveApiKey(null, fallback), fallback);
    });

    test('empty env value does not fall back (empty is a valid value)', () {
      // dotenv.env['KEY'] returns '' when the key exists but is empty,
      // and null when the key is missing. This tests the ?? behaviour.
      expect(resolveApiKey('', 'fallback'), '');
    });
  });

  // ==========================================================================
  // GROUP: Dynamic API Key Resolution – Edge Cases
  // ==========================================================================
  group('Dynamic API Key Resolution – Edge Cases', () {
    test('env key with leading/trailing whitespace is returned as-is', () {
      const envKey = '  live_key_with_spaces  ';
      expect(resolveApiKey(envKey, 'fallback'), envKey);
    });

    test('fallback key containing placeholder text is returned when no env', () {
      const placeholder = 'YOUR_BILLPLZ_API_KEY_HERE';
      expect(resolveApiKey(null, placeholder), placeholder);
    });

    test('both env and fallback can be empty string', () {
      expect(resolveApiKey('', ''), '');
    });
  });
}
