import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/features/household/domain/invite_code.dart';

void main() {
  group('InviteCode.alphabet', () {
    test('is 32 unambiguous uppercase characters', () {
      expect(InviteCode.alphabet, hasLength(32));
      expect(InviteCode.alphabet, InviteCode.alphabet.toUpperCase());
      expect(
        InviteCode.alphabet.split('').toSet(),
        hasLength(InviteCode.alphabet.length),
        reason: 'no duplicates',
      );
    });

    test('omits the letters that collide with digits or each other', () {
      for (final excluded in ['I', 'L', 'O', 'U']) {
        expect(
          InviteCode.alphabet,
          isNot(contains(excluded)),
          reason: '$excluded is confusable',
        );
      }
    });
  });

  group('generate', () {
    test('produces a code of the declared length', () {
      final code = InviteCode.generate(Random(1));

      expect(code.value, hasLength(InviteCode.length));
    });

    test('draws only from the alphabet', () {
      for (var seed = 0; seed < 50; seed++) {
        final code = InviteCode.generate(Random(seed));
        for (final char in code.value.split('')) {
          expect(InviteCode.alphabet, contains(char));
        }
      }
    });

    test('is deterministic for a given seed', () {
      expect(InviteCode.generate(Random(7)), InviteCode.generate(Random(7)));
    });

    test('differs across seeds', () {
      final codes = {
        for (var seed = 0; seed < 25; seed++)
          InviteCode.generate(Random(seed)).value,
      };

      expect(codes.length, greaterThan(20), reason: 'not obviously degenerate');
    });

    test('always parses back as valid', () {
      for (var seed = 0; seed < 25; seed++) {
        expect(
          InviteCode.parse(InviteCode.generate(Random(seed)).value).isOk,
          isTrue,
        );
      }
    });
  });

  group('parse', () {
    test('accepts a well-formed code', () {
      final result = InviteCode.parse('KH7RQ2');

      expect(result, isA<Ok<InviteCode>>());
      expect(result.valueOrNull?.value, 'KH7RQ2');
    });

    test('uppercases lowercase input', () {
      expect(InviteCode.parse('kh7rq2').valueOrNull?.value, 'KH7RQ2');
    });

    test('strips surrounding whitespace and internal separators', () {
      expect(InviteCode.parse('  KH7-RQ2 ').valueOrNull?.value, 'KH7RQ2');
      expect(InviteCode.parse('KH7 RQ2').valueOrNull?.value, 'KH7RQ2');
    });

    test('maps confusable characters onto their intended twins', () {
      expect(InviteCode.parse('KHIRQ2').valueOrNull?.value, 'KH1RQ2');
      expect(InviteCode.parse('KHORQ2').valueOrNull?.value, 'KH0RQ2');
    });

    test('rejects the empty string', () {
      final result = InviteCode.parse('');

      expect(result, isA<Err<InviteCode>>());
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('rejects codes of the wrong length', () {
      expect(InviteCode.parse('KH7RQ').isErr, isTrue);
      expect(InviteCode.parse('KH7RQ22').isErr, isTrue);
    });

    test('rejects characters outside the alphabet', () {
      final result = InviteCode.parse('KH7RQ*');

      expect(result.isErr, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('failure messages name the problem', () {
      expect(
        InviteCode.parse('KH7RQ').failureOrNull?.message,
        contains('${InviteCode.length}'),
      );
    });
  });

  group('value semantics', () {
    test('equal codes compare equal', () {
      final a = InviteCode.parse('KH7RQ2').valueOrNull!;
      final b = InviteCode.parse('kh7 rq2').valueOrNull!;

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different codes compare unequal', () {
      expect(
        InviteCode.parse('KH7RQ2').valueOrNull,
        isNot(InviteCode.parse('KH7RQ3').valueOrNull),
      );
    });

    test('toString shows the code', () {
      expect(
        InviteCode.parse('KH7RQ2').valueOrNull.toString(),
        'InviteCode(KH7RQ2)',
      );
    });

    test('formatted inserts a separator for display', () {
      expect(InviteCode.parse('KH7RQ2').valueOrNull?.formatted, 'KH7-RQ2');
    });
  });
}
