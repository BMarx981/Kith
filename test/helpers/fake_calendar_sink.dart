import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/core/time/calendar_day.dart';
import 'package:kith/data/services/calendar_sink.dart';

/// An in-memory [CalendarSink] standing in for a Google Calendar.
///
/// Holds events in a map, so a create followed by a fetch behaves the way the
/// API does without any HTTP. Each verb has its own failure hook, because the
/// orderings worth testing are the ones where one half works and the other
/// does not.
class FakeCalendarSink implements CalendarSink {
  /// Events by id, standing for what the calendar holds.
  final events = <String, CalendarEvent>{};

  /// Arguments of every [createEvent] call, oldest first.
  final createCalls =
      <
        ({String calendarId, String title, DateTime day, String? note})
      >[];

  /// Arguments of every [deleteEvent] call, oldest first.
  final deleteCalls = <({String calendarId, String eventId})>[];

  /// Arguments of every [fetchEvent] call, oldest first.
  final fetchCalls = <({String calendarId, String eventId})>[];

  /// Failure returned by [createEvent] instead of writing, when set.
  Failure? createFailure;

  /// Failure returned by [updateEvent] instead of writing, when set.
  Failure? updateFailure;

  /// Failure returned by [fetchEvent] instead of reading, when set.
  Failure? fetchFailure;

  /// Failure returned by [deleteEvent] instead of removing, when set.
  Failure? deleteFailure;

  var _nextId = 0;

  @override
  Future<Result<CalendarEvent>> createEvent({
    required String calendarId,
    required String title,
    required DateTime day,
    String? note,
  }) async {
    createCalls.add((
      calendarId: calendarId,
      title: title,
      day: day,
      note: note,
    ));
    final failure = createFailure;
    if (failure != null) return Err(failure);

    final event = CalendarEvent(
      id: 'evt_${++_nextId}',
      title: title,
      day: CalendarDay.of(day),
      note: note,
    );
    events[event.id] = event;
    return Ok(event);
  }

  @override
  Future<Result<CalendarEvent>> updateEvent({
    required String calendarId,
    required String eventId,
    required String title,
    required DateTime day,
    String? note,
  }) async {
    final failure = updateFailure;
    if (failure != null) return Err(failure);
    if (!events.containsKey(eventId)) {
      return const Err(NotFoundFailure('No such event.'));
    }

    final event = CalendarEvent(
      id: eventId,
      title: title,
      day: CalendarDay.of(day),
      note: note,
    );
    events[eventId] = event;
    return Ok(event);
  }

  @override
  Future<Result<CalendarEvent?>> fetchEvent({
    required String calendarId,
    required String eventId,
  }) async {
    fetchCalls.add((calendarId: calendarId, eventId: eventId));
    final failure = fetchFailure;
    if (failure != null) return Err(failure);
    return Ok(events[eventId]);
  }

  @override
  Future<Result<void>> deleteEvent({
    required String calendarId,
    required String eventId,
  }) async {
    deleteCalls.add((calendarId: calendarId, eventId: eventId));
    final failure = deleteFailure;
    if (failure != null) return Err(failure);
    // Deleting an event that has already gone succeeds, the way the sink
    // contract says it does.
    events.remove(eventId);
    return const Ok(null);
  }

  /// Puts [event] in the calendar without going through a write, for seeding
  /// what somebody else's calendar app already holds.
  void seed(CalendarEvent event) => events[event.id] = event;
}
