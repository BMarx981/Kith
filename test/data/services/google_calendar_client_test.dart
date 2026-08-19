import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/services/google_calendar_client.dart';

void main() {
  String errorBody(int code, String message, {String? reason}) => jsonEncode({
    'error': {
      'code': code,
      'message': message,
      if (reason != null)
        'errors': [
          {'reason': reason, 'message': message},
        ],
    },
  });

  group('calendarFailure', () {
    Failure failureFor(int status, {String? reason}) => calendarFailure(
      http.Response(errorBody(status, 'nope', reason: reason), status),
    );

    test('reads an expired or refused token as a permission problem', () {
      expect(failureFor(401), isA<PermissionFailure>());
      expect(failureFor(403), isA<PermissionFailure>());
    });

    test('reads a throttled 403 as retryable rather than as a refusal', () {
      expect(
        failureFor(403, reason: 'rateLimitExceeded'),
        isA<NetworkFailure>(),
      );
      expect(
        failureFor(403, reason: 'userRateLimitExceeded'),
        isA<NetworkFailure>(),
      );
    });

    test('reads a missing calendar or event as not found', () {
      expect(failureFor(404), isA<NotFoundFailure>());
      expect(failureFor(410), isA<NotFoundFailure>());
    });

    test('reads a duplicate write as a conflict', () {
      expect(failureFor(409), isA<ConflictFailure>());
    });

    test('reads throttling and outages as worth retrying', () {
      expect(failureFor(429), isA<NetworkFailure>());
      expect(failureFor(500), isA<NetworkFailure>());
      expect(failureFor(503), isA<NetworkFailure>());
    });

    test('reads a rejected request as unknown', () {
      expect(failureFor(400), isA<UnknownFailure>());
    });

    test("carries Google's message through for the log", () {
      expect(failureFor(400).message, contains('nope'));
    });

    test('falls back to the status line when the body is not error JSON', () {
      final failure = calendarFailure(http.Response('<html>502</html>', 502));

      expect(failure, isA<NetworkFailure>());
      expect(failure.message, contains('502'));
    });
  });
}
