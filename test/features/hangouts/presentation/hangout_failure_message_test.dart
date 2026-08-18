import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/hangouts/presentation/hangout_failure_message.dart';

void main() {
  test('every failure type has copy of its own', () {
    const failures = <Failure>[
      NetworkFailure('offline'),
      PermissionFailure('nope'),
      NotFoundFailure('gone'),
      ValidationFailure('Choose who you saw.'),
      ConflictFailure('clash'),
      AuthFailure(AuthFailureReason.unknown, 'signed out'),
      UnknownFailure('boom'),
    ];

    final messages = [
      for (final failure in failures) hangoutFailureMessage(failure),
    ];

    expect(messages.toSet(), hasLength(failures.length));
    for (final message in messages) {
      expect(message, isNotEmpty);
    }
  });

  test('a validation failure is shown as the domain wrote it', () {
    expect(
      hangoutFailureMessage(const ValidationFailure('Choose who you saw.')),
      'Choose who you saw.',
    );
  });

  test('a log-only message is never leaked for the other failures', () {
    for (final failure in const <Failure>[
      NetworkFailure('socket closed'),
      PermissionFailure('missing or insufficient permissions'),
      UnknownFailure('null check operator on a null value'),
    ]) {
      expect(hangoutFailureMessage(failure), isNot(contains(failure.message)));
    }
  });
}
