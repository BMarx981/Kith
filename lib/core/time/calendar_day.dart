/// Calendar days, as opposed to instants.
///
/// A hangout happened on a *day*: "the 14th", not "09:22 on the 14th in
/// whatever zone the phone was in". Kith stores such a day as midnight UTC of
/// that date, which gives a value that is sortable, range-queryable and
/// storable as epoch milliseconds like every other timestamp in the app,
/// without dragging a timezone along with it.
///
/// The conversion reads the *components* of whatever it is handed. A local
/// instant contributes its local date, a UTC instant contributes its UTC
/// date, and a day built here reproduces itself. That is what keeps "today"
/// meaning the day the user is living in, and keeps a stored day from
/// drifting a square either way when it is read back somewhere else.
abstract final class CalendarDay {
  /// The calendar day [instant] falls on, as midnight UTC.
  static DateTime of(DateTime instant) =>
      DateTime.utc(instant.year, instant.month, instant.day);

  /// Whole days from [from] to [to], negative when [to] is the earlier one.
  ///
  /// Both ends are reduced to days first, so the answer counts date squares
  /// rather than 24-hour blocks and no daylight-saving hour can round it off
  /// by one.
  static int between(DateTime from, DateTime to) =>
      of(to).difference(of(from)).inDays;

  /// Whether [a] and [b] fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) => of(a) == of(b);
}
