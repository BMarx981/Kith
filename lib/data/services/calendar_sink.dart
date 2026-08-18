import 'package:flutter/foundation.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/core/time/calendar_day.dart';

/// One entry on the household's calendar, as Kith sees it.
///
/// Deliberately thinner than a calendar event can be: Kith writes a day, a
/// title and a line of note, so those are the fields a sink round-trips.
/// Anything else a household adds to the event in their own calendar app —
/// a time, guests, a location — is theirs, and is left alone rather than
/// modelled here and overwritten on the next sync.
@immutable
class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.title,
    required DateTime day,
    this.note,
  }) : day = CalendarDay.of(day);

  /// The calendar provider's id for this event. What a `PlannedHangout` keeps
  /// in `calendarEventId`.
  final String id;

  /// The event's one-line summary.
  final String title;

  /// The calendar day the event sits on, as midnight UTC. See [CalendarDay].
  ///
  /// A plan names a day, not an hour, so Kith writes all-day events. An event
  /// somebody has since given a time is read back as the day it falls on.
  final DateTime day;

  /// The event's description, when it has one.
  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          other.id == id &&
          other.title == title &&
          other.day == day &&
          other.note == note;

  @override
  int get hashCode => Object.hash(id, title, day, note);

  @override
  String toString() =>
      'CalendarEvent(id: $id, title: $title, day: $day, note: $note)';
}

/// Where Kith writes the plans a household has made.
///
/// Everything the app puts on a calendar goes through this interface, so a
/// second provider later is an added implementation rather than a rewrite.
/// The Skylight frame is downstream of it and not a sink of its own: the frame
/// subscribes to the Google Calendar this writes to. See `docs/SKYLIGHT.md`.
///
/// Implementations translate transport and API errors into domain failures
/// before returning; nothing above this interface sees an HTTP status.
/// The calendar id is passed per call rather than held by the sink, so
/// linking a household to a different calendar does not mean rebuilding one.
abstract interface class CalendarSink {
  /// Puts a new all-day event for [day] on [calendarId].
  ///
  /// Answers with the event as the provider stored it, whose id belongs on the
  /// `PlannedHangout` that asked for it.
  Future<Result<CalendarEvent>> createEvent({
    required String calendarId,
    required String title,
    required DateTime day,
    String? note,
  });

  /// Moves or retitles the event [eventId] to match a plan that has changed.
  ///
  /// Only the fields Kith owns are written, so a time, a location or guests
  /// added in a calendar app survive the update.
  Future<Result<CalendarEvent>> updateEvent({
    required String calendarId,
    required String eventId,
    required String title,
    required DateTime day,
    String? note,
  });

  /// Reads [eventId] back, for the poll that keeps a plan and its event in
  /// step without a webhook.
  ///
  /// An event deleted in a calendar app comes back as `Ok(null)` rather than
  /// as a failure: the household cancelling from the other end is an answer,
  /// not an error, and the plan follows it.
  Future<Result<CalendarEvent?>> fetchEvent({
    required String calendarId,
    required String eventId,
  });

  /// Removes [eventId] from [calendarId].
  ///
  /// Deleting an event that has already gone succeeds: both ends agree on
  /// where it ended up, which is what the caller was asking for.
  Future<Result<void>> deleteEvent({
    required String calendarId,
    required String eventId,
  });
}
