import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/household/presentation/household_failure_message.dart';
import 'package:kith/l10n/gen/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  /// Every failure a repository in this feature can return.
  const failures = <Failure>[
    NetworkFailure('log copy'),
    PermissionFailure('log copy'),
    NotFoundFailure('log copy'),
    ValidationFailure('log copy'),
    ConflictFailure('log copy'),
    AuthFailure(AuthFailureReason.unknown, 'log copy'),
    UnknownFailure('log copy'),
  ];

  test('every failure has copy of its own', () {
    for (final failure in failures) {
      final message = householdFailureMessage(l10n, failure);
      expect(message, isNotEmpty, reason: '${failure.name} has no copy');
      expect(
        message,
        isNot(contains('log copy')),
        reason: '${failure.name} leaks its log message',
      );
    }
  });

  test('a code that matched nothing says so', () {
    expect(
      householdFailureMessage(l10n, const NotFoundFailure('no such code')),
      contains('code'),
    );
  });

  test('being offline is distinguishable from anything else', () {
    expect(
      householdFailureMessage(l10n, const NetworkFailure('offline')),
      isNot(householdFailureMessage(l10n, const UnknownFailure('boom'))),
    );
  });
}
