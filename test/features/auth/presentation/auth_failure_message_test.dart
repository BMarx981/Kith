import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/auth/presentation/auth_failure_message.dart';
import 'package:kith/l10n/gen/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('authFailureMessage', () {
    test('has copy for every reason, and never leaks the log message', () {
      for (final reason in AuthFailureReason.values) {
        final message = authFailureMessage(
          l10n,
          AuthFailure(reason, 'FirebaseAuthException: internal-error'),
        );

        expect(message, isNotEmpty, reason: reason.name);
        expect(message, isNot(contains('Firebase')), reason: reason.name);
      }
    });

    test('says something different for each reason', () {
      final messages = AuthFailureReason.values
          .map((reason) => authFailureMessage(l10n, AuthFailure(reason, 'x')))
          .toSet();

      expect(messages, hasLength(AuthFailureReason.values.length));
    });

    test('names the actual problem for a wrong password', () {
      const failure = AuthFailure(
        AuthFailureReason.invalidCredentials,
        'wrong password',
      );

      expect(
        authFailureMessage(l10n, failure),
        'That email and password do not match an account.',
      );
    });
  });
}
