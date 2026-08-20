import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/features/contacts/domain/birthday.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/domain/upcoming_birthday.dart';
import 'package:kith/l10n/gen/app_localizations_en.dart';

/// 2026-03-01, a Sunday, well clear of any month boundary the tests lean on.
final _now = DateTime.utc(2026, 3, 1, 9, 30);

Contact _contact({
  required String id,
  required String name,
  Birthday? birthday,
  bool isArchived = false,
}) => Contact(
  id: id,
  name: name,
  relationshipTypeId: 'friend',
  cadence: Cadence.monthly,
  priority: ContactPriority.normal,
  createdAt: DateTime.utc(2025),
  updatedAt: DateTime.utc(2025),
  birthday: birthday,
  isArchived: isArchived,
);

void main() {
  final l10n = AppLocalizationsEn();

  group('upcomingBirthdays', () {
    test('is empty when nobody has a birthday recorded', () {
      expect(
        upcomingBirthdays(
          contacts: [_contact(id: 'a', name: 'Ana')],
          now: _now,
        ),
        isEmpty,
      );
    });

    test('leaves out a birthday past the window', () {
      final found = upcomingBirthdays(
        contacts: [
          _contact(
            id: 'a',
            name: 'Ana',
            birthday: const Birthday(month: 6, day: 1),
          ),
        ],
        now: _now,
      );
      expect(found, isEmpty);
    });

    test('keeps one exactly on the window edge', () {
      final found = upcomingBirthdays(
        contacts: [
          _contact(
            id: 'a',
            name: 'Ana',
            birthday: const Birthday(month: 3, day: 31),
          ),
        ],
        now: _now,
      );
      expect(found.single.daysUntil, defaultBirthdayWindowDays);
    });

    test('keeps today', () {
      final found = upcomingBirthdays(
        contacts: [
          _contact(
            id: 'a',
            name: 'Ana',
            birthday: const Birthday(month: 3, day: 1),
          ),
        ],
        now: _now,
      );
      expect(found.single.daysUntil, 0);
      expect(found.single.on, DateTime.utc(2026, 3));
    });

    test('leaves out archived contacts', () {
      expect(
        upcomingBirthdays(
          contacts: [
            _contact(
              id: 'a',
              name: 'Ana',
              birthday: const Birthday(month: 3, day: 2),
              isArchived: true,
            ),
          ],
          now: _now,
        ),
        isEmpty,
      );
    });

    test('sorts soonest first', () {
      final found = upcomingBirthdays(
        contacts: [
          _contact(
            id: 'c',
            name: 'Cara',
            birthday: const Birthday(month: 3, day: 20),
          ),
          _contact(
            id: 'a',
            name: 'Ana',
            birthday: const Birthday(month: 3, day: 3),
          ),
          _contact(
            id: 'b',
            name: 'Ben',
            birthday: const Birthday(month: 3, day: 10),
          ),
        ],
        now: _now,
      );
      expect(found.map((b) => b.contact.name), ['Ana', 'Ben', 'Cara']);
    });

    test('breaks a tie on name, then id', () {
      final found = upcomingBirthdays(
        contacts: [
          _contact(
            id: 'z',
            name: 'ana',
            birthday: const Birthday(month: 3, day: 5),
          ),
          _contact(
            id: 'a',
            name: 'Ana',
            birthday: const Birthday(month: 3, day: 5),
          ),
          _contact(
            id: 'b',
            name: 'Abe',
            birthday: const Birthday(month: 3, day: 5),
          ),
        ],
        now: _now,
      );
      expect(found.map((b) => b.contact.id), ['b', 'a', 'z']);
    });

    test('rolls a birthday that has just gone by into next year', () {
      final found = upcomingBirthdays(
        contacts: [
          _contact(
            id: 'a',
            name: 'Ana',
            birthday: const Birthday(month: 2, day: 28),
          ),
        ],
        now: _now,
        withinDays: 400,
      );
      expect(found.single.on, DateTime.utc(2027, 2, 28));
    });

    test('carries the age they are turning, and null without a year', () {
      final found = upcomingBirthdays(
        contacts: [
          _contact(
            id: 'a',
            name: 'Ana',
            birthday: const Birthday(month: 3, day: 14, year: 1988),
          ),
          _contact(
            id: 'b',
            name: 'Ben',
            birthday: const Birthday(month: 3, day: 15),
          ),
        ],
        now: _now,
      );
      expect(found[0].turningAge, 38);
      expect(found[1].turningAge, isNull);
    });
  });

  group('headline', () {
    UpcomingBirthday only(Birthday birthday, {DateTime? now}) =>
        upcomingBirthdays(
          contacts: [_contact(id: 'a', name: 'Ana', birthday: birthday)],
          now: now ?? _now,
          withinDays: 400,
        ).single;

    test('says today, tomorrow, or the date', () {
      expect(
        only(const Birthday(month: 3, day: 1)).headline(l10n),
        "Ana's birthday is today.",
      );
      expect(
        only(const Birthday(month: 3, day: 2)).headline(l10n),
        "Ana's birthday is tomorrow.",
      );
      expect(
        only(const Birthday(month: 3, day: 14)).headline(l10n),
        "Ana's birthday is on Sat 14 Mar.",
      );
    });

    test('names the age when the year is known', () {
      expect(
        only(const Birthday(month: 3, day: 14, year: 1988)).headline(l10n),
        'Ana turns 38 on Sat 14 Mar.',
      );
      expect(
        only(const Birthday(month: 3, day: 1, year: 1988)).headline(l10n),
        'Ana turns 38 today.',
      );
    });

    test('shows the year once the date leaves this one', () {
      expect(
        only(const Birthday(month: 2, day: 28)).headline(l10n),
        "Ana's birthday is on Sun 28 Feb 2027.",
      );
    });
  });

  group('value semantics', () {
    test('equal readings compare and hash equal', () {
      final contacts = [
        _contact(
          id: 'a',
          name: 'Ana',
          birthday: const Birthday(month: 3, day: 14),
        ),
      ];
      final a = upcomingBirthdays(contacts: contacts, now: _now).single;
      final b = upcomingBirthdays(contacts: contacts, now: _now).single;
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('Ana'));
    });
  });
}
