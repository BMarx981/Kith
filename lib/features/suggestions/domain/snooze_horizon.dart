import 'package:kith/core/time/calendar_day.dart';
import 'package:kith/features/contacts/domain/cadence.dart';

/// How long a deferred suggestion stays quiet.
///
/// Two horizons, because "not this week" and "not for now" are different
/// answers, and both are honest: there is no "never suggest again", since a
/// contact you never want prompted about is a contact to archive. Dismissing
/// therefore defers rather than deletes, by one whole cadence — long enough
/// that the prompt does not nag, short enough that the person does not vanish.
///
/// Pure: each horizon is a function of a day and a cadence, with no clock of
/// its own.
enum SnoozeHorizon {
  /// Ask again in a week, whatever the cadence.
  week('Snooze'),

  /// Ask again one full cadence from today.
  fullCadence('Dismiss');

  const SnoozeHorizon(this.label);

  /// How the choice is written on the card.
  ///
  /// Short, because it sits on a button: how long the deferral actually runs
  /// is said back in the confirmation, where there is room for a date.
  final String label;

  /// Days a week's snooze lasts.
  static const weekDays = 7;

  /// The day a suggestion deferred on [now] becomes suggestible again, as
  /// midnight UTC.
  ///
  /// The contact stays quiet up to but not including this day, so a week's
  /// snooze taken on a Tuesday is back the Tuesday after.
  DateTime from(DateTime now, {required Cadence cadence}) => CalendarDay.of(
    now,
  ).add(Duration(days: this == SnoozeHorizon.week ? weekDays : cadence.days));
}
