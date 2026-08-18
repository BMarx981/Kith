import 'package:kith/core/time/calendar_day.dart';

/// How a calendar day is written in the app.
///
/// Hand-rolled rather than reached for through `intl`, which the project does
/// not depend on: the app is English-only in v1, and one date format is not
/// worth a package plus a locale-loading step in every test. Pure and
/// table-testable, which a formatter that read the clock itself would not be.
abstract final class DayLabel {
  /// [day] written relative to [today]: "Today", "Yesterday", "Tue 12 Aug",
  /// or "Tue 12 Aug 2025" once it is outside [today]'s year.
  ///
  /// The year is dropped near-term because it is noise — everything in a
  /// timeline is this year until it is not — and shown once it is not, so a
  /// date is never ambiguous.
  static String of(DateTime day, {required DateTime today}) {
    final days = CalendarDay.between(today, day);
    if (days == 0) return 'Today';
    if (days == -1) return 'Yesterday';
    if (days == 1) return 'Tomorrow';
    return full(day, withYear: day.year != today.year);
  }

  /// [day] written out in full: "Tue 12 Aug", with the year when asked.
  static String full(DateTime day, {bool withYear = true}) {
    final head = '${weekday(day.weekday)} ${day.day} ${month(day.month)}';
    return withYear ? '$head ${day.year}' : head;
  }

  /// Three-letter name of the weekday [index], Monday being 1.
  static String weekday(int index) => _weekdays[(index - 1) % 7];

  /// Three-letter name of the month [index], January being 1.
  static String month(int index) => _months[(index - 1) % 12];

  static const _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}
