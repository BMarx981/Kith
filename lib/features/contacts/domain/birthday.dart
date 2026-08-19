import 'package:flutter/foundation.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/core/time/calendar_day.dart';
import 'package:kith/features/hangouts/domain/day_label.dart';

/// The day of the year somebody was born, with the year itself optional.
///
/// Optional because that is how the fact is actually held: you know a friend's
/// birthday is the 14th of March long before you know they were born in 1988,
/// and a contact whose year had to be guessed to be stored would carry a
/// fabricated age forever. [year] is therefore nullable, and everything that
/// depends on it — [ageOn], [ageAtNextOccurrence] — answers null rather than
/// inventing one.
///
/// Not a `DateTime`: an instant names one day in history, and a birthday is a
/// day that comes round every year. What the app asks of it is "when is the
/// next one", which is [nextOccurrence] — a calendar day in the sense of
/// `CalendarDay`, midnight UTC, like every other day Kith stores.
///
/// The constructor is unguarded so the presets and tests can be `const`;
/// [parse] and [tryParse] are the checked ways in, and they are what every
/// value reaching Firestore has been through.
@immutable
class Birthday {
  /// A birthday on [day] of [month], in [year] when it is known.
  const Birthday({required this.month, required this.day, this.year});

  /// Month of the year, January being 1.
  final int month;

  /// Day of the month.
  final int day;

  /// Year of birth, or null when it was never recorded.
  final int? year;

  /// Earliest year of birth the editor accepts.
  static const minYear = 1900;

  /// Latest year of birth the editor accepts. Far enough out that no living
  /// contact is refused; near enough that a typo in the thousands is.
  static const maxYear = 2200;

  /// Longest a stored birthday can be, as a string: `-YYYY-MM-DD` is 10.
  /// Mirrors the bound in `firestore.rules`.
  static const maxWireLength = 10;

  /// Reads what someone typed into the birthday field.
  ///
  /// Accepts the stored forms (`1988-03-14`, `--03-14`) and the two written
  /// ones, with or without a year: `14 Mar 1988`, `14 March`, `Mar 14`,
  /// `March 14, 1988`.
  ///
  /// All-numeric slash forms are deliberately refused. `3/4/1988` is the 3rd
  /// of April to half the world and the 4th of March to the other half, and
  /// the app carries no locale to break the tie, so a wrong date silently
  /// stored is worse than a message asking for the month by name.
  static Result<Birthday> parse(String input) {
    final text = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) {
      return const Err(ValidationFailure('Enter a birthday.'));
    }

    final parsed = _readIso(text) ?? _readWritten(text);
    if (parsed == null) {
      return const Err(
        ValidationFailure('Write it like 14 Mar, or 14 Mar 1988.'),
      );
    }
    return _validate(parsed);
  }

  /// Reads a stored birthday, answering null for anything unreadable.
  ///
  /// Tolerant on the way in, the way every `fromMap` is: a document holding a
  /// birthday nobody can parse should render as a contact with no birthday,
  /// not take the whole list down.
  static Birthday? tryParse(String? input) =>
      input == null ? null : parse(input).valueOrNull;

  /// Whether the year of birth is known.
  bool get hasYear => year != null;

  /// How the birthday is stored: `1988-03-14`, or `--03-14` with no year.
  ///
  /// The year-less spelling is vCard's (RFC 6350), which keeps both forms
  /// sorting by month then day within themselves and stays readable in the
  /// Firestore console.
  String get wireValue =>
      '${year == null ? '-' : _pad(year!, 4)}'
      '-${_pad(month, 2)}-${_pad(day, 2)}';

  /// How the birthday is written in the UI: "14 Mar", or "14 Mar 1988".
  String get label {
    final head = '$day ${DayLabel.month(month)}';
    return year == null ? head : '$head $year';
  }

  /// The next calendar day this birthday lands on, counting [from]'s own day
  /// as the next one when it is the day.
  ///
  /// A 29th of February lands on the 28th in a common year rather than on the
  /// 1st of March: the birthday belongs to February, and pushing it into the
  /// next month would move it past a 1 March birthday that comes after it in
  /// every leap year.
  DateTime nextOccurrence({required DateTime from}) {
    final today = CalendarDay.of(from);
    final thisYear = _landingIn(today.year);
    return thisYear.isBefore(today) ? _landingIn(today.year + 1) : thisYear;
  }

  /// Whole days from [from] to [nextOccurrence], zero on the day itself.
  int daysUntil({required DateTime from}) =>
      CalendarDay.between(from, nextOccurrence(from: from));

  /// How old they are on [instant], or null when the year is unknown or
  /// [instant] falls before they were born.
  int? ageOn(DateTime instant) {
    if (year case final born?) {
      final on = CalendarDay.of(instant);
      final age = on.isBefore(_landingIn(on.year))
          ? on.year - born - 1
          : on.year - born;
      return age < 0 ? null : age;
    }
    return null;
  }

  /// The age they are turning at [nextOccurrence], or null with no year.
  int? ageAtNextOccurrence({required DateTime from}) =>
      year == null ? null : nextOccurrence(from: from).year - year!;

  /// Where this birthday lands in [year], February the 29th included.
  DateTime _landingIn(int year) {
    final last = _daysInMonth(month, year);
    return DateTime.utc(year, month, day <= last ? day : last);
  }

  static Result<Birthday> _validate(Birthday birthday) {
    if (birthday.month < 1 || birthday.month > 12) {
      return const Err(ValidationFailure('That is not a month.'));
    }
    if (birthday.year case final year?) {
      if (year < minYear || year > maxYear) {
        return const Err(
          ValidationFailure('Use a year between $minYear and $maxYear.'),
        );
      }
    }
    // With no year behind it, the 29th of February is a real birthday that
    // simply has no leap year to be checked against, so the month is measured
    // in a leap year and the day is allowed.
    final last = _daysInMonth(birthday.month, birthday.year ?? 2000);
    if (birthday.day < 1 || birthday.day > last) {
      return Err(
        ValidationFailure(
          '${DayLabel.month(birthday.month)} has no day ${birthday.day}.',
        ),
      );
    }
    return Ok(birthday);
  }

  /// Reads `1988-03-14` and `--03-14`.
  static Birthday? _readIso(String text) {
    final match = RegExp(r'^(\d{4}|-)-(\d{1,2})-(\d{1,2})$').firstMatch(text);
    if (match == null) return null;
    final year = match.group(1)!;
    return Birthday(
      month: int.parse(match.group(2)!),
      day: int.parse(match.group(3)!),
      year: year == '-' ? null : int.parse(year),
    );
  }

  /// Reads `14 Mar 1988`, `14 March`, `Mar 14` and `March 14, 1988`.
  static Birthday? _readWritten(String text) {
    const tail = r'(?:\s*,)?(?:\s+(\d{4}))?$';
    final dayFirst = RegExp(
      r'^(\d{1,2}) ([A-Za-z]+)' + tail,
    ).firstMatch(text);
    final monthFirst = RegExp(
      r'^([A-Za-z]+) (\d{1,2})' + tail,
    ).firstMatch(text);

    final match = dayFirst ?? monthFirst;
    if (match == null) return null;
    final name = (dayFirst != null ? match.group(2) : match.group(1))!;
    final day = (dayFirst != null ? match.group(1) : match.group(2))!;
    final month = _monthNumber(name);
    if (month == null) return null;
    return Birthday(
      month: month,
      day: int.parse(day),
      year: match.group(3) == null ? null : int.parse(match.group(3)!),
    );
  }

  /// The month [name] numbers, by full name or three-letter abbreviation.
  static int? _monthNumber(String name) {
    final wanted = name.toLowerCase();
    for (var index = 0; index < _monthNames.length; index++) {
      final full = _monthNames[index];
      if (wanted == full || wanted == full.substring(0, 3)) return index + 1;
    }
    return null;
  }

  static int _daysInMonth(int month, int year) =>
      month == 2 && _isLeapYear(year) ? 29 : _monthLengths[month - 1];

  static bool _isLeapYear(int year) =>
      year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);

  static String _pad(int value, int width) =>
      value.toString().padLeft(width, '0');

  static const _monthLengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  /// Full month names, for parsing only. The abbreviations the UI renders
  /// come from [DayLabel.month], so there is one table of those, not two.
  static const _monthNames = [
    'january',
    'february',
    'march',
    'april',
    'may',
    'june',
    'july',
    'august',
    'september',
    'october',
    'november',
    'december',
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Birthday &&
          other.month == month &&
          other.day == day &&
          other.year == year;

  @override
  int get hashCode => Object.hash(month, day, year);

  @override
  String toString() => 'Birthday($wireValue)';
}
