import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';

void main() {
  group('Failure subtypes', () {
    const cases = <(Failure, String)>[
      (NetworkFailure('offline'), 'NetworkFailure(offline)'),
      (PermissionFailure('not a member'), 'PermissionFailure(not a member)'),
      (NotFoundFailure('missing'), 'NotFoundFailure(missing)'),
      (ValidationFailure('bad code'), 'ValidationFailure(bad code)'),
      (ConflictFailure('code taken'), 'ConflictFailure(code taken)'),
      (UnknownFailure('boom'), 'UnknownFailure(boom)'),
    ];

    test('each exposes its message and a named toString', () {
      for (final (failure, expected) in cases) {
        expect(failure.toString(), expected);
        expect(failure.message, isNotEmpty);
      }
    });

    test('equality is by runtime type and message', () {
      expect(const NetworkFailure('a'), const NetworkFailure('a'));
      expect(
        const NetworkFailure('a').hashCode,
        const NetworkFailure('a').hashCode,
      );
      expect(const NetworkFailure('a'), isNot(const NetworkFailure('b')));
      expect(const NetworkFailure('a'), isNot(const UnknownFailure('a')));
    });

    test('UnknownFailure can carry the original cause for logging', () {
      final cause = StateError('underlying');
      final failure = UnknownFailure('boom', cause: cause);

      expect(failure.cause, cause);
      expect(const UnknownFailure('boom').cause, isNull);
    });
  });

  test('switch over the sealed type is exhaustive', () {
    String category(Failure failure) => switch (failure) {
      NetworkFailure() => 'retry',
      PermissionFailure() => 'denied',
      NotFoundFailure() => 'gone',
      ValidationFailure() => 'input',
      ConflictFailure() => 'conflict',
      UnknownFailure() => 'unknown',
    };

    expect(category(const NetworkFailure('x')), 'retry');
    expect(category(const PermissionFailure('x')), 'denied');
    expect(category(const NotFoundFailure('x')), 'gone');
    expect(category(const ValidationFailure('x')), 'input');
    expect(category(const ConflictFailure('x')), 'conflict');
    expect(category(const UnknownFailure('x')), 'unknown');
  });
}
