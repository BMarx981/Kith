import 'package:flutter/foundation.dart';
import 'package:kith/core/time/calendar_day.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/features/contacts/domain/birthday.dart';
import 'package:kith/features/hangouts/domain/day_label.dart';
import 'package:kith/l10n/gen/app_localizations.dart';

/// A birthday that is coming up, and whose it is.
///
/// Carries the day it lands on and the age being turned rather than only the
/// contact, so a card and a notification digest read the same reading instead
/// of each recomputing it against their own idea of "now".
@immutable
class UpcomingBirthday {
  const UpcomingBirthday({
    required this.contact,
    required this.birthday,
    required this.on,
    required this.daysUntil,
    required this.turningAge,
  });

  /// Whose birthday it is.
  final Contact contact;

  /// The recorded birthday, year included when it is known.
  final Birthday birthday;

  /// The calendar day the next one falls on, as midnight UTC.
  final DateTime on;

  /// Whole days from the ranking's "now" to [on]; zero on the day itself.
  final int daysUntil;

  /// The age they are turning, or null when no year was recorded.
  final int? turningAge;

  /// Whether it is today.
  bool get isToday => daysUntil == 0;

  /// The birthday in one line, name included, so the same sentence works on a
  /// card that already shows the name and in a digest that does not.
  String headline(AppLocalizations l10n) {
    final when = switch (daysUntil) {
      0 => l10n.whenToday,
      1 => l10n.whenTomorrow,
      _ => l10n.whenOnDay(
        DayLabel.full(on, l10n: l10n, withYear: on.year != _fromYear),
      ),
    };
    return turningAge == null
        ? l10n.birthdayHeadline(contact.name, when)
        : l10n.birthdayHeadlineTurning(contact.name, turningAge!, when);
  }

  /// The year the reading was taken in, recovered from [on] and [daysUntil].
  ///
  /// Kept rather than storing "now" alongside it: the only thing the sentence
  /// needs the year for is deciding whether to print [on]'s, and a birthday
  /// that has rolled into next year is exactly the case where it should.
  int get _fromYear => on.subtract(Duration(days: daysUntil)).year;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpcomingBirthday &&
          other.contact == contact &&
          other.birthday == birthday &&
          other.on == on &&
          other.daysUntil == daysUntil &&
          other.turningAge == turningAge;

  @override
  int get hashCode => Object.hash(contact, birthday, on, daysUntil, turningAge);

  @override
  String toString() =>
      'UpcomingBirthday(${contact.name}, on: $on, in: $daysUntil days, '
      'turning: $turningAge)';
}

/// How far ahead the app looks for birthdays by default: a month, which is
/// long enough to buy a card and short enough that the list stays a prompt
/// rather than a calendar.
const defaultBirthdayWindowDays = 30;

/// The birthdays landing within [withinDays] of [now], soonest first.
///
/// Pure and clock-free, like the suggestion engine: [now] is passed in so the
/// ordering is reproducible in a test rather than a function of when it ran.
///
/// Archived contacts are left out for the same reason they are left out of the
/// suggestions — archiving is Kith's removal, and a removed person is not
/// somebody to be prompted about. Ties break on name and then id, so the order
/// is total and never reshuffles between rebuilds.
List<UpcomingBirthday> upcomingBirthdays({
  required List<Contact> contacts,
  required DateTime now,
  int withinDays = defaultBirthdayWindowDays,
}) {
  final found = <UpcomingBirthday>[];
  for (final contact in contacts) {
    if (contact.isArchived) continue;
    if (contact.birthday case final birthday?) {
      final on = birthday.nextOccurrence(from: now);
      final daysUntil = CalendarDay.between(now, on);
      if (daysUntil > withinDays) continue;
      found.add(
        UpcomingBirthday(
          contact: contact,
          birthday: birthday,
          on: on,
          daysUntil: daysUntil,
          turningAge: birthday.ageAtNextOccurrence(from: now),
        ),
      );
    }
  }

  found.sort((a, b) {
    final byDay = a.daysUntil.compareTo(b.daysUntil);
    if (byDay != 0) return byDay;
    final byName = a.contact.name.toLowerCase().compareTo(
      b.contact.name.toLowerCase(),
    );
    return byName != 0 ? byName : a.contact.id.compareTo(b.contact.id);
  });
  return List.unmodifiable(found);
}
