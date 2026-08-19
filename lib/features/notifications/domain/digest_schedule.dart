/// When the weekly digest next fires.
///
/// Pure and clock-free: "now" is passed in, so the answer is reproducible in a
/// test rather than a function of when it ran.
///
/// Everything here is *local wall time*. A digest is an appointment with the
/// user — "Sunday at 9" — not an instant, so the day and hour are what get
/// stored and the zone is whatever the phone is in when it fires. Passing a
/// UTC instant in as `from` would compare a wall time against an instant and
/// answer for the wrong day either side of midnight.
abstract final class DigestSchedule {
  /// Default hour for a digest nobody has picked a time for: 9am, which is
  /// after the morning has started and before the week has taken it over.
  static const defaultHour = 9;

  /// Earliest hour the picker offers.
  static const minHour = 0;

  /// Latest hour the picker offers.
  static const maxHour = 23;

  /// The next local instant [weekday] falls at [hour], strictly after [from].
  ///
  /// Strictly after, so a digest that has just fired schedules the following
  /// week rather than firing again. [weekday] is Dart's own numbering, Monday
  /// being 1.
  static DateTime next({
    required int weekday,
    required int hour,
    required DateTime from,
  }) {
    final today = DateTime(from.year, from.month, from.day, hour);
    // Dart's % is non-negative for a positive divisor, so a weekday already
    // behind wraps to the tail of this week rather than going backwards.
    final ahead = (weekday - today.weekday) % 7;
    final candidate = ahead == 0
        ? today
        : DateTime(from.year, from.month, from.day + ahead, hour);
    return candidate.isAfter(from)
        ? candidate
        : DateTime(
            candidate.year,
            candidate.month,
            candidate.day + 7,
            hour,
          );
  }

  /// [weekday] written out, Monday being 1.
  static String dayLabel(int weekday) => _days[(weekday - 1) % 7];

  /// [hour] on a 12-hour clock: "9am", "12pm", "11pm".
  ///
  /// Hand-rolled for the same reason `DayLabel` is: the app is English-only in
  /// v1, and one time format is not worth a package and a locale-loading step
  /// in every test.
  static String hourLabel(int hour) {
    final wrapped = hour % 24;
    final suffix = wrapped < 12 ? 'am' : 'pm';
    final twelve = wrapped % 12 == 0 ? 12 : wrapped % 12;
    return '$twelve$suffix';
  }

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
}
