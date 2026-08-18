import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/core/time/calendar_day.dart';
import 'package:kith/data/services/calendar_sink.dart';

/// Supplies an OAuth access token carrying the calendar scope, or null when
/// the household has not authorised one.
///
/// A function rather than a stored string, and consulted on every call, so a
/// token that has expired between two writes is refreshed rather than reused.
typedef CalendarAccessTokenProvider = Future<String?> Function();

/// [CalendarSink] over the Google Calendar REST API.
///
/// Kith writes all-day events, so a plan for the 18th is written as the 18th
/// and reads back as the 18th wherever the household happens to be. Google's
/// end date is exclusive, which is the one place that shows.
class GoogleCalendarSink implements CalendarSink {
  const GoogleCalendarSink({
    required http.Client httpClient,
    required this._accessToken,
  }) : _http = httpClient;

  final http.Client _http;
  final CalendarAccessTokenProvider _accessToken;

  static final Uri _base = Uri.parse('https://www.googleapis.com/calendar/v3');

  @override
  Future<Result<CalendarEvent>> createEvent({
    required String calendarId,
    required String title,
    required DateTime day,
    String? note,
  }) => _guard(() async {
    final response = await _send(
      (headers) => _http.post(
        _eventsUri(calendarId),
        headers: headers,
        body: jsonEncode(_eventPayload(title: title, day: day, note: note)),
      ),
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
  }) => _guard(() async {
    final response = await _send(
      (headers) => _http.patch(
        _eventUri(calendarId, eventId),
        headers: headers,
        // A patch omitting the description would leave a note the household
        // has since removed standing on the event, so it is sent either way.
        body: jsonEncode(
          _eventPayload(title: title, day: day, note: note ?? ''),
        ),
      ),
    );
    return _readEvent(response);
  });

  @override
  Future<Result<CalendarEvent?>> fetchEvent({
    required String calendarId,
    required String eventId,
  }) => _guard(() async {
    final response = await _send(
      (headers) => _http.get(_eventUri(calendarId, eventId), headers: headers),
    );
    if (_isGone(response.statusCode)) return const Ok<CalendarEvent?>(null);
    if (!_isSuccess(response.statusCode)) {
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
  }) => _guard(() async {
    final response = await _send(
      (headers) =>
          _http.delete(_eventUri(calendarId, eventId), headers: headers),
    );
    if (_isSuccess(response.statusCode) || _isGone(response.statusCode)) {
      return const Ok(null);
    }
    return Err<void>(calendarFailure(response));
  });

  /// Runs [body] with an authorised header set, or refuses without any I/O
  /// when no token is available.
  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) body,
  ) async {
    final token = await _accessToken();
    if (token == null) throw const _Unauthorised();
    return body({
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
    });
  }

  /// Turns anything the transport throws into a domain failure, so no HTTP
  /// type leaves this class.
  Future<Result<T>> _guard<T>(Future<Result<T>> Function() body) async {
    try {
      return await body();
    } on _Unauthorised {
      return const Err(
        PermissionFailure('No Google Calendar authorisation for this account.'),
      );
    } on http.ClientException catch (error) {
      return Err(NetworkFailure(error.message));
    } on TimeoutException catch (error) {
      return Err(NetworkFailure('Google Calendar timed out: $error'));
    } on Object catch (error) {
      return Err(
        UnknownFailure('Google Calendar call failed.', cause: error),
      );
    }
  }

  Result<CalendarEvent> _readEvent(http.Response response) {
    if (!_isSuccess(response.statusCode)) {
      return Err(calendarFailure(response));
    }
    return Ok(_eventFrom(jsonDecode(response.body) as Map<String, dynamic>));
  }

  Uri _eventsUri(String calendarId) => _base.replace(
    pathSegments: [..._base.pathSegments, 'calendars', calendarId, 'events'],
  );

  Uri _eventUri(String calendarId, String eventId) => _base.replace(
    pathSegments: [
      ..._base.pathSegments,
      'calendars',
      calendarId,
      'events',
      eventId,
    ],
  );

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
  /// An all-day event names the day outright. One somebody has given a time
  /// to is read as the day it shows up on locally, which is the square the
  /// household sees it in.
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

  static bool _isSuccess(int status) => status >= 200 && status < 300;

  static bool _isGone(int status) => status == 404 || status == 410;
}

/// Maps a failed Google Calendar response onto the domain failure that
/// describes it.
///
/// Exposed for its own tests: the status-to-failure table is the part of the
/// sink most worth pinning, and reaching it through four endpoints would say
/// the same thing four times.
Failure calendarFailure(http.Response response) {
  final error = _errorDetail(response);
  final message = error.message ?? 'HTTP ${response.statusCode}';
  return switch (response.statusCode) {
    // Throttling arrives as a 403 with a usage-limit reason, and is a wait
    // rather than a refusal.
    403 when _isRateLimit(error.reason) => NetworkFailure(message),
    401 || 403 => PermissionFailure(message),
    404 || 410 => NotFoundFailure(message),
    409 => ConflictFailure(message),
    429 => NetworkFailure(message),
    >= 500 && < 600 => NetworkFailure(message),
    _ => UnknownFailure(message),
  };
}

bool _isRateLimit(String? reason) =>
    reason == 'rateLimitExceeded' || reason == 'userRateLimitExceeded';

/// The message and first reason out of Google's error envelope, if the body
/// is one. A proxy's HTML error page is not, and falls back to the status.
({String? message, String? reason}) _errorDetail(http.Response response) {
  try {
    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) return (message: null, reason: null);
    final error = body['error'];
    if (error is! Map<String, dynamic>) return (message: null, reason: null);
    final reasons = error['errors'];
    final first = (reasons is List && reasons.isNotEmpty)
        ? reasons.first
        : null;
    return (
      message: error['message'] as String?,
      reason: first is Map<String, dynamic> ? first['reason'] as String? : null,
    );
  } on FormatException {
    return (message: null, reason: null);
  }
}

/// Thrown inside the sink when no access token is available, so the refusal
/// travels back through the same guard as every other failure.
class _Unauthorised implements Exception {
  const _Unauthorised();
}
