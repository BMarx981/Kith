import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/services/calendar_directory.dart';
import 'package:kith/data/services/google_calendar_directory.dart';

void main() {
  String listBody(List<Map<String, dynamic>> items, {String? nextPageToken}) =>
      jsonEncode({'items': items, 'nextPageToken': ?nextPageToken});

  Map<String, dynamic> entry(
    String id, {
    String? summary,
    String? summaryOverride,
    bool? primary,
  }) => {
    'id': id,
    'summary': ?summary,
    'summaryOverride': ?summaryOverride,
    'primary': ?primary,
  };

  GoogleCalendarDirectory directoryThat(
    Future<http.Response> Function(http.Request request) handler, {
    String? token = 'tok_123',
  }) => GoogleCalendarDirectory(
    httpClient: MockClient(handler),
    accessToken: () async => token,
  );

  GoogleCalendarDirectory directoryReturning(
    String body, {
    int status = 200,
  }) => directoryThat((_) async => http.Response(body, status));

  group('listCalendars', () {
    test('reads the account subscriptions into listings', () async {
      final directory = directoryReturning(
        listBody([
          entry('brian@example.com', summary: 'Brian', primary: true),
          entry('kith@group.calendar.google.com', summary: 'Hangouts'),
        ]),
      );

      final result = await directory.listCalendars();

      expect(result.valueOrNull, [
        const CalendarListing(
          id: 'brian@example.com',
          name: 'Brian',
          isPrimary: true,
        ),
        const CalendarListing(
          id: 'kith@group.calendar.google.com',
          name: 'Hangouts',
        ),
      ]);
    });

    test('asks the server for writable calendars only', () async {
      Uri? asked;
      final directory = directoryThat((request) async {
        asked = request.url;
        return http.Response(listBody([]), 200);
      });

      await directory.listCalendars();

      expect(asked?.path, endsWith('/calendar/v3/users/me/calendarList'));
      expect(asked?.queryParameters['minAccessRole'], 'writer');
      expect(
        asked?.queryParameters['maxResults'],
        '${GoogleCalendarDirectory.pageSize}',
      );
      expect(asked?.queryParameters.containsKey('pageToken'), isFalse);
    });

    test('sends the access token as a bearer credential', () async {
      String? authorization;
      final directory = directoryThat((request) async {
        authorization = request.headers['Authorization'];
        return http.Response(listBody([]), 200);
      });

      await directory.listCalendars();

      expect(authorization, 'Bearer tok_123');
    });

    test('prefers the name the account gave a subscription', () async {
      final directory = directoryReturning(
        listBody([
          entry('cal-1', summary: 'Shared events', summaryOverride: 'Family'),
        ]),
      );

      final result = await directory.listCalendars();

      expect(result.valueOrNull?.single.name, 'Family');
    });

    test('falls back to the id when a calendar has no name', () async {
      final directory = directoryReturning(listBody([entry('cal-1')]));

      final result = await directory.listCalendars();

      expect(result.valueOrNull?.single.name, 'cal-1');
    });

    test('drops an entry that names no calendar', () async {
      final directory = directoryReturning(
        listBody([
          {'summary': 'Nameless'},
          entry('cal-1', summary: 'Family'),
        ]),
      );

      final result = await directory.listCalendars();

      expect(result.valueOrNull?.map((c) => c.id), ['cal-1']);
    });

    test('puts the primary calendar first, then sorts by name', () async {
      final directory = directoryReturning(
        listBody([
          entry('cal-z', summary: 'Zoo trips'),
          entry('cal-a', summary: 'anniversaries'),
          entry('cal-me', summary: 'Brian', primary: true),
        ]),
      );

      final result = await directory.listCalendars();

      expect(result.valueOrNull?.map((c) => c.id), [
        'cal-me',
        'cal-a',
        'cal-z',
      ]);
    });

    test('orders two calendars sharing a name by id', () async {
      final directory = directoryReturning(
        listBody([
          entry('cal-b', summary: 'Family'),
          entry('cal-a', summary: 'Family'),
        ]),
      );

      final result = await directory.listCalendars();

      expect(result.valueOrNull?.map((c) => c.id), ['cal-a', 'cal-b']);
    });

    test('follows the pages the server hands back', () async {
      final tokens = <String?>[];
      var page = 0;
      final directory = directoryThat((request) async {
        tokens.add(request.url.queryParameters['pageToken']);
        page++;
        return http.Response(
          listBody(
            [entry('cal-$page', summary: 'Page $page')],
            nextPageToken: page < 3 ? 'page-$page' : null,
          ),
          200,
        );
      });

      final result = await directory.listCalendars();

      expect(tokens, [null, 'page-1', 'page-2']);
      expect(result.valueOrNull, hasLength(3));
    });

    test('stops following pages rather than spinning forever', () async {
      var requests = 0;
      final directory = directoryThat((_) async {
        requests++;
        return http.Response(
          listBody([entry('cal-$requests')], nextPageToken: 'more'),
          200,
        );
      });

      final result = await directory.listCalendars();

      expect(requests, GoogleCalendarDirectory.maxPages);
      expect(result.valueOrNull, hasLength(GoogleCalendarDirectory.maxPages));
    });

    test('reads an empty account as no calendars, not as an error', () async {
      final directory = directoryReturning(jsonEncode({}));

      final result = await directory.listCalendars();

      expect(result.valueOrNull, isEmpty);
    });

    test('translates a refused read into a domain failure', () async {
      final directory = directoryReturning(
        jsonEncode({
          'error': {'code': 403, 'message': 'insufficient scope'},
        }),
        status: 403,
      );

      final result = await directory.listCalendars();

      expect(result.failureOrNull, isA<PermissionFailure>());
    });

    test('refuses without any request when no scope was granted', () async {
      final directory = directoryThat(
        (request) async => fail('no request should have been sent'),
        token: null,
      );

      final result = await directory.listCalendars();

      expect(result.failureOrNull, isA<PermissionFailure>());
    });

    test('reads a dropped connection as a network failure', () async {
      final directory = directoryThat(
        (_) async => throw http.ClientException('connection closed'),
      );

      final result = await directory.listCalendars();

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('reads a body that is not the expected shape as unknown', () async {
      final directory = directoryReturning('<html>hello</html>');

      final result = await directory.listCalendars();

      expect(result.failureOrNull, isA<UnknownFailure>());
    });
  });
}
