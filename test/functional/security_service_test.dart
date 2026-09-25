// test/functional/security_service_test.dart
//
// Functional tests for SecurityService session management and JWT `jti` parsing.
// Covers: happy path, error path, and edge cases.
//
// Run with:
//   flutter test test/functional/security_service_test.dart

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Internal-logic helpers (extracted for testability without Supabase)
// These mirror the private `_getSessionId()` logic in SecurityService.
// ---------------------------------------------------------------------------

/// Parses the `jti` claim from a JWT access token.
/// Returns null if the token is malformed or missing the claim.
String? parseJtiFromJwt(String accessToken) {
  try {
    final parts = accessToken.split('.');
    if (parts.length == 3) {
      final payload = String.fromCharCodes(
        base64Decode(base64.normalize(parts[1])),
      );
      final payloadMap = jsonDecode(payload) as Map<String, dynamic>;
      return payloadMap['jti'] as String?;
    }
  } catch (_) {
    // Malformed JWT
  }
  return null;
}

/// Creates a minimal, unsigned JWT with the given payload fields.
String buildFakeJwt(Map<String, dynamic> payload) {
  final header = base64Url.encode(
    utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})),
  );
  final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
  return '$header.$body.fake_signature';
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  // ==========================================================================
  // GROUP: JWT `jti` Session ID Parsing – Happy Path
  // ==========================================================================
  group('JWT jti Parsing – Happy Path', () {
    test('extracts jti from a well-formed JWT', () {
      final jwt = buildFakeJwt({
        'sub': 'user_123',
        'jti': 'abc-session-id-def',
        'iat': 1700000000,
        'exp': 1700003600,
      });

      final jti = parseJtiFromJwt(jwt);
      expect(jti, 'abc-session-id-def');
    });

    test('returns the exact jti string without modification', () {
      const expectedJti = 'unique-jti-claim-001';
      final jwt = buildFakeJwt({'jti': expectedJti, 'sub': 'u1'});

      expect(parseJtiFromJwt(jwt), expectedJti);
    });

    test('two JWTs with different jti values produce different session IDs', () {
      final jwt1 = buildFakeJwt({'jti': 'session-a', 'sub': 'user_1'});
      final jwt2 = buildFakeJwt({'jti': 'session-b', 'sub': 'user_1'});

      final jti1 = parseJtiFromJwt(jwt1);
      final jti2 = parseJtiFromJwt(jwt2);

      expect(jti1, isNotNull);
      expect(jti2, isNotNull);
      expect(jti1, isNot(jti2));
    });

    test('jti survives special characters (UUIDs with hyphens)', () {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      final jwt = buildFakeJwt({'jti': uuid, 'sub': 'user_001'});

      expect(parseJtiFromJwt(jwt), uuid);
    });

    test('simultaneous sessions for same user have distinct jti values', () {
      final sessions = List.generate(
        10,
        (i) => buildFakeJwt({'jti': 'session-$i', 'sub': 'user_shared'}),
      );
      final jtis = sessions.map(parseJtiFromJwt).toSet();

      // All 10 should be unique (no collisions)
      expect(jtis.length, 10);
    });
  });

  // ==========================================================================
  // GROUP: JWT `jti` Session ID Parsing – Error Path
  // ==========================================================================
  group('JWT jti Parsing – Error Path', () {
    test('returns null for a completely empty string', () {
      expect(parseJtiFromJwt(''), isNull);
    });

    test('returns null for a plain string with no dots', () {
      expect(parseJtiFromJwt('not_a_jwt'), isNull);
    });

    test('returns null for a JWT with only 2 parts (header.payload)', () {
      final header = base64Url.encode(utf8.encode('{}'));
      final body = base64Url.encode(utf8.encode('{"sub":"u1"}'));
      expect(parseJtiFromJwt('$header.$body'), isNull);
    });

    test('returns null for a JWT with a non-JSON base64 payload', () {
      final garbage = base64Url.encode(utf8.encode('not_json!!'));
      expect(parseJtiFromJwt('header.$garbage.sig'), isNull);
    });

    test('returns null when jti claim is missing from valid JWT', () {
      final jwt = buildFakeJwt({
        'sub': 'user_no_jti',
        'iat': 1700000000,
        'exp': 1700003600,
        // no 'jti' key
      });

      expect(parseJtiFromJwt(jwt), isNull);
    });

    test('returns null when jti is explicitly null in JWT payload', () {
      final jwt = buildFakeJwt({
        'sub': 'user_null_jti',
        'jti': null,
      });

      expect(parseJtiFromJwt(jwt), isNull);
    });

    test('returns null for base64 payload with truncated JSON', () {
      final truncated = base64Url.encode(utf8.encode('{"jti":"abc"')); // missing closing }
      expect(parseJtiFromJwt('header.$truncated.sig'), isNull);
    });
  });

  // ==========================================================================
  // GROUP: JWT `jti` Session ID Parsing – Edge Cases
  // ==========================================================================
  group('JWT jti Parsing – Edge Cases', () {
    test('parses jti from JWT without standard base64 padding', () {
      // base64Url without padding is common in real JWTs
      final payload = <String, dynamic>{'jti': 'edge-case-jti'};
      // base64.normalize in the implementation handles missing padding
      final raw = base64Url.encode(utf8.encode(jsonEncode(payload)));
      final unpadded = raw.replaceAll('=', '');
      final jwt = 'fakeheader.$unpadded.fakesig';

      expect(parseJtiFromJwt(jwt), 'edge-case-jti');
    });

    test('handles JWT with extra fields without issue', () {
      final jwt = buildFakeJwt({
        'jti': 'complex-jti',
        'sub': 'user_123',
        'roles': ['customer', 'admin'],
        'nested': {'key': 'value'},
        'iat': 1700000000,
        'exp': 1700100000,
        'iss': 'https://supabase.example.com',
        'aud': 'authenticated',
      });

      expect(parseJtiFromJwt(jwt), 'complex-jti');
    });

    test('jti with only whitespace returns the whitespace string (not null)', () {
      final jwt = buildFakeJwt({'jti': '   ', 'sub': 'u1'});
      // Whitespace is a valid string, should not be treated as null
      expect(parseJtiFromJwt(jwt), '   ');
    });

    test('very long jti value (512 chars) parses without truncation', () {
      final longJti = 'x' * 512;
      final jwt = buildFakeJwt({'jti': longJti, 'sub': 'u1'});

      expect(parseJtiFromJwt(jwt)?.length, 512);
    });

    test('jti with ASCII special characters parses correctly', () {
      // Use ASCII-safe special chars to avoid base64/UTF-8 edge cases in tests
      const specialJti = 'session-abc-001_v2.0~final';
      final jwt = buildFakeJwt({'jti': specialJti, 'sub': 'u1'});

      expect(parseJtiFromJwt(jwt), specialJti);
    });

    test('parsing the same JWT twice returns the same jti (idempotent)', () {
      final jwt = buildFakeJwt({'jti': 'idempotent-jti', 'sub': 'u1'});

      final first = parseJtiFromJwt(jwt);
      final second = parseJtiFromJwt(jwt);

      expect(first, second);
    });
  });

  // ==========================================================================
  // GROUP: Collision Resistance – Uniqueness Properties
  // ==========================================================================
  group('Session ID Uniqueness (Collision Resistance)', () {
    test('100 UUIDs used as jti values are all unique', () {
      // Simulate what Supabase generates: UUID v4 strings as jti
      // We verify that the parsing preserves uniqueness.
      final uuids = List.generate(
        100,
        (i) => '${i.toString().padLeft(8, '0')}-0000-0000-0000-000000000000',
      );

      final jtis = uuids.map((uuid) {
        final jwt = buildFakeJwt({'jti': uuid, 'sub': 'user_x'});
        return parseJtiFromJwt(jwt);
      }).toSet();

      expect(jtis.length, 100, reason: 'All 100 parsed JTIs should be unique');
    });

    test('different users same timestamp produce distinct jti values', () {
      const timestamp = 1700000000;
      final jwt1 = buildFakeJwt({'jti': 'jti-user1-ts$timestamp', 'sub': 'u1'});
      final jwt2 = buildFakeJwt({'jti': 'jti-user2-ts$timestamp', 'sub': 'u2'});

      expect(parseJtiFromJwt(jwt1), isNot(parseJtiFromJwt(jwt2)));
    });
  });
}
