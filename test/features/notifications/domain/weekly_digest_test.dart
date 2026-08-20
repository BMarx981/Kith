import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/features/contacts/domain/birthday.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/domain/upcoming_birthday.dart';
import 'package:kith/features/hangouts/domain/freshness.dart';
import 'package:kith/features/notifications/domain/weekly_digest.dart';
import 'package:kith/features/suggestions/engine/suggestion.dart';
import 'package:kith/l10n/gen/app_localizations_en.dart';

/// 2026-08-18, a Tuesday.
final _now = DateTime.utc(2026, 8, 18, 9);

Contact _contact(String name, {Birthday? birthday}) => Contact(
  id: 'cid-$name',
  name: name,
  relationshipTypeId: 'rid-1',
  cadence: Cadence.monthly,
  priority: ContactPriority.normal,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  birthday: birthday,
);

Suggestion _overdue(String name) {
  final contact = _contact(name);
  return Suggestion(
    contact: contact,
    freshness: Freshness.of(
      cadence: contact.cadence,
      lastSeenOn: DateTime.utc(2026, 6),
      now: _now,
    ),
    score: 2,
  );
}

List<UpcomingBirthday> _birthdays(Map<String, Birthday> people) =>
    upcomingBirthdays(
      contacts: [
        for (final MapEntry(key: name, value: birthday) in people.entries)
          _contact(name, birthday: birthday),
      ],
      now: _now,
      withinDays: WeeklyDigest.windowDays,
    );

void main() {
  final l10n = AppLocalizationsEn();

  group('isEmpty', () {
    test('is empty with nothing to say', () {
      expect(
        const WeeklyDigest(overdue: [], birthdays: []).isEmpty,
        isTrue,
      );
    });

    test('is not empty on an overdue contact alone', () {
      expect(
        WeeklyDigest(
          overdue: [_overdue('Marcus')],
          birthdays: const [],
        ).isEmpty,
        isFalse,
      );
    });

    test('is not empty on a birthday alone', () {
      expect(
        WeeklyDigest(
          overdue: const [],
          birthdays: _birthdays({'Ana': const Birthday(month: 8, day: 20)}),
        ).isEmpty,
        isFalse,
      );
    });
  });

  group('title', () {
    test('counts the overdue, singular and plural', () {
      expect(
        WeeklyDigest(
          overdue: [_overdue('Marcus')],
          birthdays: const [],
        ).title(l10n),
        '1 person is overdue',
      );
      expect(
        WeeklyDigest(
          overdue: [_overdue('Marcus'), _overdue('Ana'), _overdue('Ben')],
          birthdays: const [],
        ).title(l10n),
        '3 people are overdue',
      );
    });

    test('falls back to the birthdays when nobody is overdue', () {
      expect(
        WeeklyDigest(
          overdue: const [],
          birthdays: _birthdays({'Ana': const Birthday(month: 8, day: 20)}),
        ).title(l10n),
        '1 birthday this week',
      );
      expect(
        WeeklyDigest(
          overdue: const [],
          birthdays: _birthdays({
            'Ana': const Birthday(month: 8, day: 20),
            'Ben': const Birthday(month: 8, day: 21),
          }),
        ).title(l10n),
        '2 birthdays this week',
      );
    });

    test('leads with the overdue even when birthdays are there too', () {
      expect(
        WeeklyDigest(
          overdue: [_overdue('Marcus')],
          birthdays: _birthdays({'Ana': const Birthday(month: 8, day: 20)}),
        ).title(l10n),
        '1 person is overdue',
      );
    });

    test('is blank when there is nothing to report', () {
      expect(const WeeklyDigest(overdue: [], birthdays: []).title(l10n), '');
    });
  });

  group('body', () {
    test('names one, two and three people the way you would say them', () {
      expect(
        WeeklyDigest(
          overdue: [_overdue('Marcus')],
          birthdays: const [],
        ).body(l10n),
        'Marcus.',
      );
      expect(
        WeeklyDigest(
          overdue: [_overdue('Marcus'), _overdue('Ana')],
          birthdays: const [],
        ).body(l10n),
        'Marcus and Ana.',
      );
      expect(
        WeeklyDigest(
          overdue: [_overdue('Marcus'), _overdue('Ana'), _overdue('Ben')],
          birthdays: const [],
        ).body(l10n),
        'Marcus, Ana and Ben.',
      );
    });

    test('adds a single birthday in full', () {
      expect(
        WeeklyDigest(
          overdue: [_overdue('Marcus')],
          birthdays: _birthdays({'Ana': const Birthday(month: 8, day: 22)}),
        ).body(l10n),
        "Marcus. Ana's birthday is on Sat 22 Aug.",
      );
    });

    test('lists several birthdays by name', () {
      expect(
        WeeklyDigest(
          overdue: const [],
          birthdays: _birthdays({
            'Ana': const Birthday(month: 8, day: 20),
            'Ben': const Birthday(month: 8, day: 21),
          }),
        ).body(l10n),
        'Birthdays this week: Ana and Ben.',
      );
    });

    test('is blank with nothing to report', () {
      expect(const WeeklyDigest(overdue: [], birthdays: []).body(l10n), '');
    });
  });

  group('value semantics', () {
    test('equal digests compare and hash equal', () {
      final overdue = [_overdue('Marcus')];
      final birthdays = _birthdays({'Ana': const Birthday(month: 8, day: 20)});
      final a = WeeklyDigest(overdue: overdue, birthdays: birthdays);
      final b = WeeklyDigest(
        overdue: [_overdue('Marcus')],
        birthdays: _birthdays({'Ana': const Birthday(month: 8, day: 20)}),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(const WeeklyDigest(overdue: [], birthdays: [])),
      );
      expect(a.toString(), 'WeeklyDigest(overdue: 1, birthdays: 1)');
    });
  });
}
