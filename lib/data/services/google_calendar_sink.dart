import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kith/core/result/result.dart';
import 'package:kith/core/time/calendar_day.dart';
import 'package:kith/data/services/calendar_sink.dart';
import 'package:kith/data/services/google_calendar_client.dart';

/// [CalendarSink] over the Google Calendar REST API.
///
/// Kith writes all-day events, so a plan for the 18th is written as the 18th
/// and reads back as the 18th wherever the household happens to be. Google's
/// end date is exclusive, which is the one place that shows.
class GoogleCalendarSink implements CalendarSink {
  GoogleCalendarSink({
    required http.Client httpClient,
    required CalendarAccessTokenProvider accessToken,
  }) : _client = GoogleCalendarClient(
         httpClient: httpClient,
         accessToken: accessToken,
       );

  final GoogleCalendarClient _client;

  @override
  Future<Result<CalendarEvent>> createEvent({
    required String calendarId,
    required String title,
    required DateTime day,
    String? note,
  }) => _client.guard(() async {
    final response = await _client.post(
      _eventsUri(calendarId),
      _eventPayload(title: title, day: day, note: note),
    );
    return _readEvent(response);
  });

  @override
  Future<Result<CalendarEvent>> updateEvent({
    required String calendarId,
    required String eventId,
    required String title,
    required DateTime day,
    String? note,
  }) => _client.guard(() async {
    final response = await _client.patch(
      _eventUri(calendarId, eventId),
      // A payload omitting the description would leave a note the household
      // has since removed standing on the event, so it is sent either way.
      _eventPayload(title: title, day: day, note: note ?? ''),
    );
    return _readEvent(response);
  });

  @override
  Future<Result<CalendarEvent?>> fetchEvent({
    required String calendarId,
    required String eventId,
  }) => _client.guard(() async {
    final response = await _client.get(_eventUri(calendarId, eventId));
    if (GoogleCalendarClient.isGone(response.statusCode)) {
      return const Ok<CalendarEvent?>(null);
    }
    if (!GoogleCalendarClient.isSuccess(response.statusCode)) {
      return Err<CalendarEvent?>(calendarFailure(response));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    // Google keeps a deleted event addressable for a while, marked cancelled.
    // Both spellings of gone mean the same thing to a plan.
    if (body['status'] == 'cancelled') return const Ok<CalendarEvent?>(null);
    return Ok<CalendarEvent?>(_eventFrom(body));
  });

  @override
  Future<Result<void>> deleteEvent({
    required String calendarId,
    required String eventId,
  }) => _client.guard(() async {
    final response = await _client.delete(_eventUri(calendarId, eventId));
    if (GoogleCalendarClient.isSuccess(response.statusCode) ||
        GoogleCalendarClient.isGone(response.statusCode)) {
      return const Ok(null);
    }
    return Err<void>(calendarFailure(response));
  });

  Result<CalendarEvent> _readEvent(http.Response response) {
    if (!GoogleCalendarClient.isSuccess(response.statusCode)) {
      return Err(calendarFailure(response));
    }
    return Ok(_eventFrom(jsonDecode(response.body) as Map<String, dynamic>));
  }

  Uri _eventsUri(String calendarId) =>
      _client.uri(['calendars', calendarId, 'events']);

  Uri _eventUri(String calendarId, String eventId) =>
      _client.uri(['calendars', calendarId, 'events', eventId]);

  Map<String, dynamic> _eventPayload({
    required String title,
    required DateTime day,
    String? note,
  }) {
    final start = CalendarDay.of(day);
    return {
      'summary': title,
      'description': ?note,
      'start': {'date': _dateOnly(start)},
      // Exclusive: a single-day event ends on the following day.
      'end': {'date': _dateOnly(start.add(const Duration(days: 1)))},
    };
  }

  CalendarEvent _eventFrom(Map<String, dynamic> body) {
    final note = body['description'] as String?;
    return CalendarEvent(
      id: body['id'] as String,
      // An event can legitimately have no summary; Kith's own always do.
      title: body['summary'] as String? ?? '',
      day: _dayFrom(body['start'] as Map<String, dynamic>?),
      note: (note == null || note.isEmpty) ? null : note,
    );
  }

  /// The day an event's start falls on.
  ///
  /// An all-day event names the day outright. One somebody has since given a
  /// time to is read as the day it shows up on locally, which is the square
  /// the household sees it in.
  DateTime _dayFrom(Map<String, dynamic>? start) {
    final date = start?['date'] as String?;
    if (date != null) return CalendarDay.of(DateTime.parse(date));
    final dateTime = start?['dateTime'] as String?;
    if (dateTime != null) {
      return CalendarDay.of(DateTime.parse(dateTime).toLocal());
    }
    throw const FormatException('Calendar event has no start date.');
  }

  String _dateOnly(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}
