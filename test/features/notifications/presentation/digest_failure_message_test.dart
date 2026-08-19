import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/notifications/presentation/digest_failure_message.dart';

void main() {
  group('digestFailureMessage', () {
    const failures = <Failure>[
      NetworkFailure('offline'),
      PermissionFailure('denied'),
      NotFoundFailure('gone'),
      ConflictFailure('raced'),
      AuthFailure(AuthFailureReason.unknown, 'signed out'),
      UnknownFailure('boom'),
    ];

    test('gives every failure copy a user could act on', () {
      for (final failure in failures) {
        final message = digestFailureMessage(failure);
        expect(message, isNotEmpty, reason: failure.name);
        expect(message, endsWith('.'), reason: failure.name);
        expect(
          message,
          isNot(contains(failure.message)),
          reason: '${failure.name} must not leak its log text',
        );
      }
    });

    test('passes a validation failure through as written', () {
      expect(
        digestFailureMessage(const ValidationFailure('That is not a day.')),
        'That is not a day.',
      );
    });

    test('says where to look when the device refused', () {
      expect(
        digestFailureMessage(const UnknownFailure('no channel')),
        contains('this device'),
      );
    });
  });
}
