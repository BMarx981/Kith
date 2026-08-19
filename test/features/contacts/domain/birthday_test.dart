import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/contacts/domain/birthday.dart';

void main() {
  group('parse', () {
    const cases = <String, Birthday>{
      '1988-03-14': Birthday(month: 3, day: 14, year: 1988),
      '--03-14': Birthday(month: 3, day: 14),
      '14 Mar 1988': Birthday(month: 3, day: 14, year: 1988),
      '14 March 1988': Birthday(month: 3, day: 14, year: 1988),
      '14 Mar': Birthday(month: 3, day: 14),
      'Mar 14': Birthday(month: 3, day: 14),
      'March 14, 1988': Birthday(month: 3, day: 14, year: 1988),
      '  14   mar   1988  ': Birthday(month: 3, day: 14, year: 1988),
      '1 Jan': Birthday(month: 1, day: 1),
      '29 Feb': Birthday(month: 2, day: 29),
      '2024-02-29': Birthday(month: 2, day: 29, year: 2024),
      '2000-12-31': Birthday(month: 12, day: 31, year: 2000),
    };

    for (final MapEntry(key: input, value: expected) in cases.entries) {
      test('reads "$input" as $expected', () {
        expect(Birthday.parse(input).valueOrNull, expected);
      });
    }

    const rejected = <String>[
      '',
      '   ',
      'sometime in March',
      '14',
      'Mar',
      '2024-13-01',
      '2024-00-01',
      '2024-03-00',
      '2024-03-32',
      '31 Feb',
      '31 Apr',
      '2023-02-29',
      '1899-01-01',
      '2201-01-01',
      '14/3/1988',
      '3/14/1988',
    ];

    for (final input in rejected) {
      test('refuses "$input"', () {
        final result = Birthday.parse(input);
        expect(result.isErr, isTrue, reason: 'expected "$input" to be refused');
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(result.failureOrNull!.message, isNotEmpty);
      });
    }

    test('29 Feb is allowed without a year but not in a common year', () {
      expect(Birthday.parse('29 Feb').isOk, isTrue);
      expect(Birthday.parse('2024-02-29').isOk, isTrue);
      expect(Birthday.parse('2023-02-29').isErr, isTrue);
    });
  });

  group('tryParse', () {
    test('reads a stored value', () {
      expect(
        Birthday.tryParse('1988-03-14'),
        const Birthday(month: 3, day: 14, year: 1988),
      );
    });

    test('answers null for null, blank and nonsense', () {
      expect(Birthday.tryParse(null), isNull);
      expect(Birthday.tryParse(''), isNull);
      expect(Birthday.tryParse('not a date'), isNull);
    });
  });

  group('wireValue', () {
    test('writes a known year as an ISO date', () {
      expect(
        const Birthday(month: 3, day: 14, year: 1988).wireValue,
        '1988-03-14',
      );
    });

    test('writes an unknown year as the year-less form', () {
      expect(const Birthday(month: 3, day: 14).wireValue, '--03-14');
    });

    test('pads single digits', () {
      expect(
        const Birthday(month: 1, day: 2, year: 2001).wireValue,
        '2001-01-02',
      );
      expect(const Birthday(month: 1, day: 2).wireValue, '--01-02');
    });

    test('round-trips through parse', () {
      for (final birthday in [
        const Birthday(month: 3, day: 14, year: 1988),
        const Birthday(month: 12, day: 31),
        const Birthday(month: 2, day: 29),
      ]) {
        expect(Birthday.parse(birthday.wireValue).valueOrNull, birthday);
      }
    });
  });

  group('label', () {
    test('names the day, and the year when it is known', () {
      expect(
        const Birthday(month: 3, day: 14, year: 1988).label,
        '14 Mar 1988',
      );
      expect(const Birthday(month: 3, day: 14).label, '14 Mar');
    });
  });

  group('hasYear', () {
    test('is true only with a year behind it', () {
      expect(const Birthday(month: 3, day: 14, year: 1988).hasYear, isTrue);
      expect(const Birthday(month: 3, day: 14).hasYear, isFalse);
    });
  });

  group('nextOccurrence', () {
    const birthday = Birthday(month: 3, day: 14, year: 1988);

    test('is today when today is the day', () {
      expect(
        birthday.nextOccurrence(from: DateTime.utc(2026, 3, 14)),
        DateTime.utc(2026, 3, 14),
      );
    });

    test('is later this year when the day is still ahead', () {
      expect(
        birthday.nextOccurrence(from: DateTime.utc(2026)),
        DateTime.utc(2026, 3, 14),
      );
    });

    test('rolls into next year once the day has gone by', () {
      expect(
        birthday.nextOccurrence(from: DateTime.utc(2026, 3, 15)),
        DateTime.utc(2027, 3, 14),
      );
    });

    test('reads the components of a local instant, not its UTC date', () {
      expect(
        birthday.nextOccurrence(from: DateTime(2026, 3, 14, 23, 30)),
        DateTime.utc(2026, 3, 14),
      );
    });

    test('lands 29 Feb on 28 Feb in a common year', () {
      const leapling = Birthday(month: 2, day: 29);
      expect(
        leapling.nextOccurrence(from: DateTime.utc(2026)),
        DateTime.utc(2026, 2, 28),
      );
      expect(
        leapling.nextOccurrence(from: DateTime.utc(2028)),
        DateTime.utc(2028, 2, 29),
      );
    });

    test('rolls a 29 Feb past its common-year landing', () {
      const leapling = Birthday(month: 2, day: 29);
      expect(
        leapling.nextOccurrence(from: DateTime.utc(2026, 3, 5)),
        DateTime.utc(2027, 2, 28),
      );
    });
  });

  group('daysUntil', () {
    test('counts date squares, today being zero', () {
      const birthday = Birthday(month: 3, day: 14);
      expect(birthday.daysUntil(from: DateTime.utc(2026, 3, 14)), 0);
      expect(birthday.daysUntil(from: DateTime.utc(2026, 3, 13)), 1);
      expect(birthday.daysUntil(from: DateTime.utc(2026, 3, 15)), 364);
    });
  });

  group('ageOn', () {
    const birthday = Birthday(month: 3, day: 14, year: 1988);

    test('is null without a year', () {
      expect(
        const Birthday(month: 3, day: 14).ageOn(DateTime.utc(2026)),
        isNull,
      );
    });

    test('counts completed years', () {
      expect(birthday.ageOn(DateTime.utc(2026, 3, 13)), 37);
      expect(birthday.ageOn(DateTime.utc(2026, 3, 14)), 38);
      expect(birthday.ageOn(DateTime.utc(2026, 3, 15)), 38);
    });

    test('is zero on the day of birth', () {
      expect(birthday.ageOn(DateTime.utc(1988, 3, 14)), 0);
    });

    test('is null before the birth date', () {
      expect(birthday.ageOn(DateTime.utc(1988, 3, 13)), isNull);
    });
  });

  group('ageAtNextOccurrence', () {
    test('is the age they are turning', () {
      const birthday = Birthday(month: 3, day: 14, year: 1988);
      expect(birthday.ageAtNextOccurrence(from: DateTime.utc(2026)), 38);
      expect(birthday.ageAtNextOccurrence(from: DateTime.utc(2026, 3, 14)), 38);
      expect(birthday.ageAtNextOccurrence(from: DateTime.utc(2026, 3, 15)), 39);
    });

    test('is null without a year', () {
      expect(
        const Birthday(month: 3, day: 14).ageAtNextOccurrence(
          from: DateTime.utc(2026),
        ),
        isNull,
      );
    });
  });

  group('value semantics', () {
    test('equal birthdays compare and hash equal', () {
      expect(
        const Birthday(month: 3, day: 14, year: 1988),
        const Birthday(month: 3, day: 14, year: 1988),
      );
      expect(
        const Birthday(month: 3, day: 14, year: 1988).hashCode,
        const Birthday(month: 3, day: 14, year: 1988).hashCode,
      );
    });

    test('a known year differs from an unknown one', () {
      expect(
        const Birthday(month: 3, day: 14),
        isNot(const Birthday(month: 3, day: 14, year: 1988)),
      );
    });

    test('differs on month and on day', () {
      expect(
        const Birthday(month: 3, day: 14),
        isNot(const Birthday(month: 4, day: 14)),
      );
      expect(
        const Birthday(month: 3, day: 14),
        isNot(const Birthday(month: 3, day: 15)),
      );
    });

    test('toString names the value', () {
      expect(
        const Birthday(month: 3, day: 14, year: 1988).toString(),
        'Birthday(1988-03-14)',
      );
      expect(const Birthday(month: 3, day: 14).toString(), 'Birthday(--03-14)');
    });
  });
}
