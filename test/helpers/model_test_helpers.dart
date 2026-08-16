import 'package:flutter_test/flutter_test.dart';

/// One field's worth of `copyWith` coverage.
///
/// Every model test enumerates one of these per field, which is what makes
/// "copyWith covers every field" checkable rather than aspirational.
class CopyWithCase<T> {
  const CopyWithCase({
    required this.field,
    required this.mutate,
    required this.read,
    required this.expected,
  });

  /// Field name, used in failure messages.
  final String field;

  /// Calls `copyWith` on the sample, setting this field to a new value.
  final T Function(T sample) mutate;

  /// Reads this field back off the result.
  final Object? Function(T model) read;

  /// What [read] should return after [mutate].
  final Object? expected;
}

/// Asserts the map round-trip contract: `fromMap(toMap(x)) == x`.
void expectMapRoundTrip<T>({
  required T sample,
  required Map<String, dynamic> Function(T model) toMap,
  required T Function(Map<String, dynamic> map) fromMap,
}) {
  final map = toMap(sample);
  expect(
    fromMap(map),
    sample,
    reason: 'fromMap(toMap(x)) must reproduce x exactly',
  );
  expect(
    toMap(fromMap(map)),
    map,
    reason: 'toMap must be stable across a round trip',
  );
}

/// Asserts that `copyWith` reaches every field, and that the no-argument form
/// is an identity.
void expectCopyWithCoversEveryField<T>({
  required T sample,
  required T Function(T sample) copyWithNothing,
  required List<CopyWithCase<T>> cases,
}) {
  expect(
    copyWithNothing(sample),
    sample,
    reason: 'copyWith() with no arguments must return an equal model',
  );

  for (final testCase in cases) {
    final updated = testCase.mutate(sample);
    expect(
      testCase.read(updated),
      testCase.expected,
      reason: 'copyWith did not apply ${testCase.field}',
    );
    expect(
      updated,
      isNot(sample),
      reason: 'changing ${testCase.field} must change equality',
    );
  }
}

/// Asserts value semantics: equal models compare and hash equal, and each
/// entry in [others] differs.
void expectValueEquality<T>({
  required T sample,
  required T identical,
  required List<T> others,
}) {
  expect(identical, sample);
  expect(identical.hashCode, sample.hashCode);
  for (final other in others) {
    expect(other, isNot(sample));
  }
}
