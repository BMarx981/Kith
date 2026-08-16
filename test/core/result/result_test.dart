import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';

void main() {
  const failure = NotFoundFailure('no such household');

  group('Ok', () {
    test('carries its value and reports success', () {
      const result = Ok(42);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.value, 42);
      expect(result.valueOrNull, 42);
      expect(result.failureOrNull, isNull);
    });

    test('equality is by value', () {
      expect(const Ok(1), const Ok(1));
      expect(const Ok(1).hashCode, const Ok(1).hashCode);
      expect(const Ok(1), isNot(const Ok(2)));
    });

    test('toString names the value', () {
      expect(const Ok(1).toString(), 'Ok(1)');
    });
  });

  group('Err', () {
    test('carries its failure and reports failure', () {
      const result = Err<int>(failure);

      expect(result.isOk, isFalse);
      expect(result.isErr, isTrue);
      expect(result.failure, failure);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, failure);
    });

    test('equality is by failure', () {
      expect(const Err<int>(failure), const Err<int>(failure));
      expect(
        const Err<int>(failure).hashCode,
        const Err<int>(failure).hashCode,
      );
      expect(
        const Err<int>(failure),
        isNot(const Err<int>(NetworkFailure('offline'))),
      );
    });

    test('toString names the failure', () {
      expect(
        const Err<int>(failure).toString(),
        'Err(NotFoundFailure(no such household))',
      );
    });
  });

  group('fold', () {
    test('takes the ok branch for a success', () {
      expect(
        const Ok(
          2,
        ).fold(onOk: (v) => 'ok $v', onErr: (f) => 'err ${f.message}'),
        'ok 2',
      );
    });

    test('takes the err branch for a failure', () {
      expect(
        const Err<int>(
          failure,
        ).fold(onOk: (v) => 'ok $v', onErr: (f) => 'err ${f.message}'),
        'err no such household',
      );
    });
  });

  group('map', () {
    test('transforms the value of a success', () {
      expect(const Ok(2).map((v) => v * 3), const Ok(6));
    });

    test('passes a failure through untouched', () {
      expect(
        const Err<int>(failure).map((v) => v * 3),
        const Err<int>(failure),
      );
    });
  });

  test('switch over the sealed type is exhaustive', () {
    String describe(Result<int> result) => switch (result) {
      Ok(value: final v) => 'ok $v',
      Err(failure: final f) => 'err ${f.message}',
    };

    expect(describe(const Ok(7)), 'ok 7');
    expect(describe(const Err(failure)), 'err no such household');
  });
}
