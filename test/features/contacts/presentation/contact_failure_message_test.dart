import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/contacts/presentation/contact_failure_message.dart';

void main() {
  // The log messages are deliberately unlike any copy, so the "never leaks"
  // test below cannot pass by coincidence.
  const failures = <Failure>[
    NetworkFailure('grpc unavailable 0x14'),
    PermissionFailure('rules rejected write 0x14'),
    NotFoundFailure('doc missing 0x14'),
    ValidationFailure('Give the contact a name.'),
    ConflictFailure('index collision 0x14'),
    AuthFailure(AuthFailureReason.unknown, 'token expired 0x14'),
    UnknownFailure('unhandled 0x14'),
  ];

  group('contactFailureMessage', () {
    test('says something for every failure type', () {
      for (final failure in failures) {
        final message = contactFailureMessage(failure);
        expect(message, isNotEmpty, reason: failure.name);
        expect(message, endsWith('.'), reason: failure.name);
      }
    });

    test(
      'passes a validation message through, because it is written as copy',
      () {
        expect(
          contactFailureMessage(
            const ValidationFailure('Give the contact a name.'),
          ),
          'Give the contact a name.',
        );
      },
    );

    test('never leaks a log message the user cannot act on', () {
      for (final failure in failures) {
        if (failure is ValidationFailure) continue;
        expect(
          contactFailureMessage(failure),
          isNot(contains(failure.message)),
          reason: failure.name,
        );
      }
    });
  });
}
