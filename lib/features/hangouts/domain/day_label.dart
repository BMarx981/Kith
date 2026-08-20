import 'package:kith/core/time/calendar_day.dart';
import 'package:kith/l10n/gen/app_localizations.dart';

/// How a calendar day is written in the app.
///
/// Localized through the ARB files rather than through `intl`'s `DateFormat`:
/// the messages carry the weekday and month names and the order they compose
/// in, so a locale can reorder the parts, and nothing here needs the locale
/// data initialisation `DateFormat` would demand of every test. Pure and
/// table-testable, which a formatter that read the clock itself would not be.
abstract final class DayLabel {
  /// [day] written relative to [today]: "Today", "Yesterday", "Tue 12 Aug",
  /// or "Tue 12 Aug 2025" once it is outside [today]'s year.
  ///
  /// The year is dropped near-term because it is noise — everything in a
  /// timeline is this year until it is not — and shown once it is not, so a
  /// date is never ambiguous.
  static String of(
    DateTime day, {
    required DateTime today,
    required AppLocalizations l10n,
  }) {
    final days = CalendarDay.between(today, day);
    if (days == 0) return l10n.dayToday;
    if (days == -1) return l10n.dayYesterday;
    if (days == 1) return l10n.dayTomorrow;
    return full(day, l10n: l10n, withYear: day.year != today.year);
  }

  /// [day] written out in full: "Tue 12 Aug", with the year when asked.
  static String full(
    DateTime day, {
    required AppLocalizations l10n,
    bool withYear = true,
  }) {
    final head = l10n.dayFull(
      weekday(day.weekday, l10n),
      day.day,
      month(day.month, l10n),
    );
    return withYear ? l10n.dayFullWithYear(head, day.year) : head;
  }

  /// Short name of the weekday [index], Monday being 1.
  static String weekday(int index, AppLocalizations l10n) =>
      switch ((index - 1) % 7) {
        0 => l10n.weekdayMon,
        1 => l10n.weekdayTue,
        2 => l10n.weekdayWed,
        3 => l10n.weekdayThu,
        4 => l10n.weekdayFri,
        5 => l10n.weekdaySat,
        _ => l10n.weekdaySun,
      };

  /// Short name of the month [index], January being 1.
  static String month(int index, AppLocalizations l10n) =>
      switch ((index - 1) % 12) {
        0 => l10n.monthJan,
        1 => l10n.monthFeb,
        2 => l10n.monthMar,
        3 => l10n.monthApr,
        4 => l10n.monthMay,
        5 => l10n.monthJun,
        6 => l10n.monthJul,
        7 => l10n.monthAug,
        8 => l10n.monthSep,
        9 => l10n.monthOct,
        10 => l10n.monthNov,
        _ => l10n.monthDec,
      };
}
