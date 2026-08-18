import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/services/calendar_sink.dart';
import 'package:kith/data/services/google_calendar_sink.dart';

void main() {
  // A real calendar id is an address, so it needs escaping in a path segment.
  const calendarId = 'kith@group.calendar.google.com';
  final day = DateTime.utc(2026, 8, 18);

  String eventBody({
    String id = 'evt_1',
    String? summary = 'Marcus',
    String? description,
    String? date = '2026-08-18',
    String? dateTime,
    String? status,
  }) => jsonEncode({
    'id': id,
    'summary': ?summary,
    'description': ?description,
    'start': {
      'date': ?date,
      'dateTime': ?dateTime,
    },
    'status': ?status,
  });

  String errorBody(int code, String message, {String? reason}) => jsonEncode({
    'error': {
      'code': code,
      'message': message,
      if (reason != null)
        'errors': [
          {'reason': reason, 'message': message},
        ],
    },
  });

  GoogleCalendarSink sinkThat(
    Future<http.Response> Function(http.Request request) handler, {
    String? token = 'tok_123',
  }) => GoogleCalendarSink(
    httpClient: MockClient(handler),
    accessToken: () async => token,
  );

  /// A sink whose transport fails the test if anything reaches it.
  GoogleCalendarSink sinkThatMustNotCall({String? token}) => sinkThat(
    (request) async => fail('no request should have been sent: ${request.url}'),
    token: token,
  );

  /// A sink answering every call with [body] and [status].
  GoogleCalendarSink sinkAnswering(String body, {int status = 200}) =>
      sinkThat((_) async => http.Response(body, status));

  group('createEvent', () {
    test('posts an all-day event to the named calendar', () async {
      late http.Request sent;
      final sink = sinkThat((request) async {
        sent = request;
        return http.Response(eventBody(), 200);
      });

      await sink.createEvent(
        calendarId: calendarId,
        title: 'Marcus',
        day: day,
        note: 'coffee',
      );

      expect(sent.method, 'POST');
      expect(sent.url.origin, 'https://www.googleapis.com');
      expect(sent.url.pathSegments, [
        'calendar',
        'v3',
        'calendars',
        calendarId,
        'events',
      ]);
      expect(sent.headers['Authorization'], 'Bearer tok_123');
      expect(sent.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(sent.body), {
        'summary': 'Marcus',
        'description': 'coffee',
        'start': {'date': '2026-08-18'},
        // Google's end date is exclusive, so a one-day event ends tomorrow.
        'end': {'date': '2026-08-19'},
      });
    });

    test('leaves the description out when the plan carries no note', () async {
      late http.Request sent;
      final sink = sinkThat((request) async {
        sent = request;
        return http.Response(eventBody(), 200);
      });

      await sink.createEvent(calendarId: calendarId, title: 'Marcus', day: day);

      expect(
        jsonDecode(sent.body) as Map<String, dynamic>,
        isNot(contains('description')),
      );
    });

    test('writes the calendar day of an instant, not the instant', () async {
      late http.Request sent;
      final sink = sinkThat((request) async {
        sent = request;
        return http.Response(eventBody(), 200);
      });

      await sink.createEvent(
        calendarId: calendarId,
        title: 'Marcus',
        // Late enough in the evening that a naive UTC shift would roll over.
        day: DateTime(2026, 8, 18, 23, 30),
      );

      final start = (jsonDecode(sent.body) as Map<String, dynamic>)['start'];
      expect((start! as Map<String, dynamic>)['date'], '2026-08-18');
    });

    test('reports an API refusal rather than inventing an event', () async {
      final sink = sinkAnswering(errorBody(500, 'Backend Error'), status: 500);

      final result = await sink.createEvent(
        calendarId: calendarId,
        title: 'Marcus',
        day: day,
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('returns the event the calendar created', () async {
      final sink = sinkAnswering(
        eventBody(id: 'evt_9', description: 'coffee'),
      );

      final result = await sink.createEvent(
        calendarId: calendarId,
        title: 'Marcus',
        day: day,
      );

      expect(
        result.valueOrNull,
        CalendarEvent(id: 'evt_9', title: 'Marcus', day: day, note: 'coffee'),
      );
    });
  });

  group('addressing', () {
    test(
      'keeps a calendar id in one path segment, separators and all',
      () async {
        late http.Request sent;
        final sink = sinkThat((request) async {
          sent = request;
          return http.Response(eventBody(), 200);
        });

        await sink.fetchEvent(calendarId: 'a/b#c', eventId: 'evt_1');

        expect(sent.url.pathSegments, [
          'calendar',
          'v3',
          'calendars',
          'a/b#c',
          'events',
          'evt_1',
        ]);
        expect(sent.url.toString(), contains('a%2Fb%23c'));
      },
    );
  });

  group('updateEvent', () {
    test('patches the named event and returns it as it now stands', () async {
      late http.Request sent;
      final sink = sinkThat((request) async {
        sent = request;
        return http.Response(
          eventBody(summary: 'Marcus & Ana'),
          200,
        );
      });

      final result = await sink.updateEvent(
        calendarId: calendarId,
        eventId: 'evt_1',
        title: 'Marcus & Ana',
        day: day,
      );

      expect(sent.method, 'PATCH');
      expect(sent.url.pathSegments, [
        'calendar',
        'v3',
        'calendars',
        calendarId,
        'events',
        'evt_1',
      ]);
      expect(result.valueOrNull?.title, 'Marcus & Ana');
    });

    test(
      'clears a removed note rather than leaving the old one behind',
      () async {
        late http.Request sent;
        final sink = sinkThat((request) async {
          sent = request;
          return http.Response(eventBody(), 200);
        });

        await sink.updateEvent(
          calendarId: calendarId,
          eventId: 'evt_1',
          title: 'Marcus',
          day: day,
        );

        expect(
          (jsonDecode(sent.body) as Map<String, dynamic>)['description'],
          '',
        );
      },
    );
  });

  group('fetchEvent', () {
    test('reads an all-day event back', () async {
      final sink = sinkAnswering(eventBody(description: 'coffee'));

      final result = await sink.fetchEvent(
        calendarId: calendarId,
        eventId: 'evt_1',
      );

      expect(
        result.valueOrNull,
        CalendarEvent(id: 'evt_1', title: 'Marcus', day: day, note: 'coffee'),
      );
    });

    test('reads a timed event as the day it falls on', () async {
      final sink = sinkAnswering(
        eventBody(date: null, dateTime: '2026-08-18T19:00:00Z'),
      );

      final result = await sink.fetchEvent(
        calendarId: calendarId,
        eventId: 'evt_1',
      );

      expect(result.valueOrNull?.day, day);
    });

    test('reads a missing summary as an untitled event', () async {
      final sink = sinkAnswering(eventBody(summary: null));

      final result = await sink.fetchEvent(
        calendarId: calendarId,
        eventId: 'evt_1',
      );

      expect(result.valueOrNull?.title, '');
      expect(result.valueOrNull?.note, isNull);
    });

    test(
      'reports an event deleted in Google Calendar as gone, not as an error',
      () async {
        final sink = sinkAnswering(eventBody(status: 'cancelled'));

        final result = await sink.fetchEvent(
          calendarId: calendarId,
          eventId: 'evt_1',
        );

        expect(result, const Ok<CalendarEvent?>(null));
      },
    );

    test(
      'reads a 404 the same way: the plan simply has no event now',
      () async {
        final sink = sinkAnswering(errorBody(404, 'Not Found'), status: 404);

        final result = await sink.fetchEvent(
          calendarId: calendarId,
          eventId: 'evt_1',
        );

        expect(result, const Ok<CalendarEvent?>(null));
      },
    );

    test('reads a 410 as gone as well', () async {
      final sink = sinkAnswering(errorBody(410, 'Deleted'), status: 410);

      final result = await sink.fetchEvent(
        calendarId: calendarId,
        eventId: 'evt_1',
      );

      expect(result, const Ok<CalendarEvent?>(null));
    });

    test('still reports a permission problem as one', () async {
      final sink = sinkAnswering(errorBody(403, 'Forbidden'), status: 403);

      final result = await sink.fetchEvent(
        calendarId: calendarId,
        eventId: 'evt_1',
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });

  group('deleteEvent', () {
    test('deletes the named event', () async {
      late http.Request sent;
      final sink = sinkThat((request) async {
        sent = request;
        return http.Response('', 204);
      });

      final result = await sink.deleteEvent(
        calendarId: calendarId,
        eventId: 'evt_1',
      );

      expect(sent.method, 'DELETE');
      expect(sent.url.pathSegments, [
        'calendar',
        'v3',
        'calendars',
        calendarId,
        'events',
        'evt_1',
      ]);
      expect(result.isOk, isTrue);
    });

    test('treats an event that is already gone as deleted', () async {
      for (final status in [404, 410]) {
        final sink = sinkAnswering(errorBody(status, 'Gone'), status: status);

        final result = await sink.deleteEvent(
          calendarId: calendarId,
          eventId: 'evt_1',
        );

        expect(result.isOk, isTrue, reason: '$status should read as deleted');
      }
    });
  });

  group('deleteEvent failures', () {
    test('reports a refused delete rather than claiming success', () async {
      final sink = sinkAnswering(errorBody(403, 'Forbidden'), status: 403);

      final result = await sink.deleteEvent(
        calendarId: calendarId,
        eventId: 'evt_1',
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });

  group('authorization', () {
    test('does not call the API at all without a token', () async {
      final sink = sinkThatMustNotCall();

      final result = await sink.createEvent(
        calendarId: calendarId,
        title: 'Marcus',
        day: day,
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
    });

    test(
      'asks for a token per call, so an expired one is not reused',
      () async {
        var asked = 0;
        final sink = GoogleCalendarSink(
          httpClient: MockClient((_) async => http.Response(eventBody(), 200)),
          accessToken: () async {
            asked++;
            return 'tok_$asked';
          },
        );

        await sink.fetchEvent(calendarId: calendarId, eventId: 'evt_1');
        await sink.fetchEvent(calendarId: calendarId, eventId: 'evt_1');

        expect(asked, 2);
      },
    );
  });

  group('calendarFailure', () {
    Failure failureFor(int status, {String? reason}) => calendarFailure(
      http.Response(errorBody(status, 'nope', reason: reason), status),
    );

    test('reads an expired or refused token as a permission problem', () {
      expect(failureFor(401), isA<PermissionFailure>());
      expect(failureFor(403), isA<PermissionFailure>());
    });

    test('reads a throttled 403 as retryable rather than as a refusal', () {
      expect(
        failureFor(403, reason: 'rateLimitExceeded'),
        isA<NetworkFailure>(),
      );
      expect(
        failureFor(403, reason: 'userRateLimitExceeded'),
        isA<NetworkFailure>(),
      );
    });

    test('reads a missing calendar or event as not found', () {
      expect(failureFor(404), isA<NotFoundFailure>());
      expect(failureFor(410), isA<NotFoundFailure>());
    });

    test('reads a duplicate write as a conflict', () {
      expect(failureFor(409), isA<ConflictFailure>());
    });

    test('reads throttling and outages as worth retrying', () {
      expect(failureFor(429), isA<NetworkFailure>());
      expect(failureFor(500), isA<NetworkFailure>());
      expect(failureFor(503), isA<NetworkFailure>());
    });

    test('reads a rejected request as unknown', () {
      expect(failureFor(400), isA<UnknownFailure>());
    });

    test("carries Google's message through for the log", () {
      expect(failureFor(400).message, contains('nope'));
    });

    test('falls back to the status line when the body is not error JSON', () {
      final failure = calendarFailure(http.Response('<html>502</html>', 502));

      expect(failure, isA<NetworkFailure>());
      expect(failure.message, contains('502'));
    });
  });

  group('transport failures', () {
    test('reads a dropped connection as a network failure', () async {
      final sink = sinkThat(
        (_) async => throw http.ClientException('connection closed'),
      );

      final result = await sink.fetchEvent(
        calendarId: calendarId,
        eventId: 'evt_1',
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('reads a timeout as a network failure', () async {
      final sink = sinkThat((_) async => throw TimeoutException('too slow'));

      final result = await sink.fetchEvent(
        calendarId: calendarId,
        eventId: 'evt_1',
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test(
      'reads an event with no start as unknown rather than crashing',
      () async {
        final sink = sinkAnswering(
          jsonEncode({'id': 'evt_1', 'summary': 'Marcus'}),
        );

        final result = await sink.fetchEvent(
          calendarId: calendarId,
          eventId: 'evt_1',
        );

        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );

    test(
      'reads a malformed success body as unknown rather than crashing',
      () async {
        final sink = sinkAnswering('not json');

        final result = await sink.fetchEvent(
          calendarId: calendarId,
          eventId: 'evt_1',
        );

        expect(result.failureOrNull, isA<UnknownFailure>());
      },
    );
  });
}
