import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/auth/presentation/auth_failure_message.dart';

void main() {
  group('authFailureMessage', () {
    test('has copy for every reason, and never leaks the log message', () {
      for (final reason in AuthFailureReason.values) {
        final message = authFailureMessage(
          AuthFailure(reason, 'FirebaseAuthException: internal-error'),
        );

        expect(message, isNotEmpty, reason: reason.name);
        expect(message, isNot(contains('Firebase')), reason: reason.name);
      }
    });

    test('says something different for each reason', () {
      final messages = AuthFailureReason.values
          .map((reason) => authFailureMessage(AuthFailure(reason, 'x')))
          .toSet();

      expect(messages, hasLength(AuthFailureReason.values.length));
    });

    test('names the actual problem for a wrong password', () {
      const failure = AuthFailure(
        AuthFailureReason.invalidCredentials,
        'wrong password',
      );

      expect(
        authFailureMessage(failure),
        'That email and password do not match an account.',
      );
    });
  });
}
