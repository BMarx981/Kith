/// The Google authorisation Kith asks a member for, and nothing more.
///
/// Two scopes rather than one. `events` is what the sink needs to put a plan
/// on a calendar and take it off again. `calendarlist.readonly` is what the
/// picker needs to show the household their own calendars, because the
/// account's subscription list is not readable under `events` alone — and
/// without it the only way to link a calendar would be to type its address.
/// Neither grants access to any calendar the household does not already have.
abstract final class CalendarScopes {
  /// Read and write events on the account's calendars.
  static const events = 'https://www.googleapis.com/auth/calendar.events';

  /// See which calendars the account subscribes to. Read-only.
  static const calendarList =
      'https://www.googleapis.com/auth/calendar.calendarlist.readonly';

  /// Everything the calendar feature asks for, in one grant.
  static const List<String> all = [events, calendarList];
}
