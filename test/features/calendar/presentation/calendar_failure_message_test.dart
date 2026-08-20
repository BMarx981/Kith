import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/calendar/presentation/calendar_failure_message.dart';
import 'package:kith/l10n/gen/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('every failure type has copy of its own', () {
    const failures = <Failure>[
      NetworkFailure('offline'),
      PermissionFailure('insufficient scope'),
      NotFoundFailure('gone'),
      ValidationFailure('Choose a calendar to write plans to.'),
      ConflictFailure('clash'),
      AuthFailure(AuthFailureReason.unknown, 'signed out'),
      UnknownFailure('boom'),
    ];

    final messages = [
      for (final failure in failures) calendarFailureMessage(l10n, failure),
    ];

    expect(messages.toSet(), hasLength(failures.length));
    for (final message in messages) {
      expect(message, isNotEmpty);
    }
  });

  test('a validation failure is shown as the domain wrote it', () {
    expect(
      calendarFailureMessage(
        l10n,
        const ValidationFailure('Choose a calendar to write plans to.'),
      ),
      'Choose a calendar to write plans to.',
    );
  });

  test('a permission problem points at Google, not at the household', () {
    final message = calendarFailureMessage(
      l10n,
      const PermissionFailure('insufficient scope'),
    );

    expect(message, contains('Google account'));
    expect(message, isNot(contains('household')));
  });
}
