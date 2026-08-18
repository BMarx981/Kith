import 'package:flutter_test/flutter_test.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/hangouts/domain/freshness.dart';

void main() {
  final now = DateTime.utc(2026, 8, 18);

  Freshness at(int daysAgo, {Cadence cadence = Cadence.monthly}) =>
      Freshness.of(
        cadence: cadence,
        lastSeenOn: now.subtract(Duration(days: daysAgo)),
        now: now,
      );

  group('states', () {
    // The boundaries belong to `due` at both ends, as docs/PLAN.md writes
    // them: fresh < 0.75 <= due <= 1.25 < overdue. Against a 100-day cadence
    // a day is one hundredth, so each case lands exactly where it says.
    const cadence = Cadence.custom(100);

    final cases = <(int, FreshnessState)>[
      (0, FreshnessState.fresh),
      (1, FreshnessState.fresh),
      (74, FreshnessState.fresh),
      (75, FreshnessState.due),
      (100, FreshnessState.due),
      (125, FreshnessState.due),
      (126, FreshnessState.overdue),
      (400, FreshnessState.overdue),
    ];

    for (final (daysAgo, expected) in cases) {
      test('$daysAgo days into a 100-day cadence is ${expected.name}', () {
        expect(at(daysAgo, cadence: cadence).state, expected);
      });
    }

    test('a contact with nothing logged is never, not overdue', () {
      final freshness = Freshness.of(
        cadence: Cadence.weekly,
        lastSeenOn: null,
        now: now,
      );

      expect(freshness.state, FreshnessState.never);
      expect(freshness.ratio, isNull);
      expect(freshness.daysSince, isNull);
      expect(freshness.lastSeenOn, isNull);
      expect(freshness.isMeasured, isFalse);
    });

    test('the same absence of days reads differently per cadence', () {
      expect(at(10, cadence: Cadence.weekly).state, FreshnessState.overdue);
      expect(at(10).state, FreshnessState.fresh);
    });
  });

  group('ratio', () {
    test('is days since over cadence days', () {
      expect(at(15).ratio, 0.5);
      expect(at(30).ratio, 1);
      expect(at(90).ratio, 3);
    });

    test('is not capped, so the engine can rank badly overdue contacts', () {
      expect(at(300).ratio, 10);
    });

    test('reads a day in the future as zero rather than as negative', () {
      final freshness = Freshness.of(
        cadence: Cadence.monthly,
        lastSeenOn: now.add(const Duration(days: 5)),
        now: now,
      );

      expect(freshness.daysSince, 0);
      expect(freshness.ratio, 0);
      expect(freshness.state, FreshnessState.fresh);
    });

    test('ignores the time of day on either side', () {
      final freshness = Freshness.of(
        cadence: Cadence.monthly,
        lastSeenOn: DateTime.utc(2026, 8, 3, 23, 30),
        now: DateTime.utc(2026, 8, 18, 0, 30),
      );

      expect(freshness.daysSince, 15);
    });
  });

  group('sweep', () {
    test('tracks the ratio while it is under a full ring', () {
      expect(at(15).sweep, 0.5);
    });

    test('caps at a full ring, so being overdue cannot look fresh', () {
      expect(at(30).sweep, 1);
      expect(at(300).sweep, 1);
    });

    test('is zero for a contact with nothing logged', () {
      expect(const Freshness.never().sweep, 0);
    });
  });

  group('lastSeenLabel', () {
    final cases = <(int?, String)>[
      (null, 'Never logged'),
      (0, 'Seen today'),
      (1, 'Seen yesterday'),
      (3, 'Seen 3 days ago'),
      (6, 'Seen 6 days ago'),
      (7, 'Seen last week'),
      (13, 'Seen last week'),
      (14, 'Seen 2 weeks ago'),
      (59, 'Seen 8 weeks ago'),
      (60, 'Seen 2 months ago'),
      (364, 'Seen 12 months ago'),
      (365, 'Seen 1+ years ago'),
      (900, 'Seen 2+ years ago'),
    ];

    for (final (daysAgo, expected) in cases) {
      test('${daysAgo ?? 'no'} days ago reads "$expected"', () {
        final freshness = daysAgo == null
            ? const Freshness.never()
            : at(daysAgo, cadence: const Cadence.custom(Cadence.maxDays));

        expect(freshness.lastSeenLabel, expected);
      });
    }
  });

  group('elapsedLabel', () {
    final cases = <(int?, String?)>[
      (null, null),
      (0, 'less than a day'),
      (1, 'a day'),
      (3, '3 days'),
      (6, '6 days'),
      (7, 'a week'),
      (13, 'a week'),
      (14, '2 weeks'),
      (42, '6 weeks'),
      (59, '8 weeks'),
      (60, '2 months'),
      (364, '12 months'),
      (365, '1+ years'),
      (900, '2+ years'),
    ];

    for (final (daysAgo, expected) in cases) {
      test('${daysAgo ?? 'no'} days ago reads "${expected ?? 'nothing'}"', () {
        final freshness = daysAgo == null
            ? const Freshness.never()
            : at(daysAgo, cadence: const Cadence.custom(Cadence.maxDays));

        expect(freshness.elapsedLabel, expected);
      });
    }

    test('is the span the last-seen label is built from', () {
      final freshness = at(
        42,
        cadence: const Cadence.custom(Cadence.maxDays),
      );

      expect(freshness.lastSeenLabel, 'Seen ${freshness.elapsedLabel} ago');
    });
  });

  group('value semantics', () {
    test('two readings of the same day and cadence are equal', () {
      expect(at(10), at(10));
      expect(at(10).hashCode, at(10).hashCode);
    });

    test('readings that differ compare unequal', () {
      expect(at(10), isNot(at(11)));
      expect(at(10), isNot(const Freshness.never()));
    });

    test('two never readings are equal', () {
      expect(const Freshness.never(), const Freshness.never());
    });

    test('toString names the state and the ratio', () {
      expect(at(15).toString(), contains('fresh'));
      expect(at(15).toString(), contains('0.5'));
    });
  });

  test('lastSeenOn comes back as the day, not the instant it was given', () {
    final freshness = Freshness.of(
      cadence: Cadence.monthly,
      lastSeenOn: DateTime.utc(2026, 8, 3, 18),
      now: now,
    );

    expect(freshness.lastSeenOn, DateTime.utc(2026, 8, 3));
  });
}
