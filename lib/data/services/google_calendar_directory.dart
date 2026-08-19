import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kith/core/result/result.dart';
import 'package:kith/data/services/calendar_directory.dart';
import 'package:kith/data/services/google_calendar_client.dart';

/// [CalendarDirectory] over the Google Calendar REST API.
///
/// Reads `users/me/calendarList`, which is the account's subscriptions rather
/// than every calendar in the world, and asks the server for the writable
/// ones only.
class GoogleCalendarDirectory implements CalendarDirectory {
  GoogleCalendarDirectory({
    required http.Client httpClient,
    required CalendarAccessTokenProvider accessToken,
  }) : _client = GoogleCalendarClient(
         httpClient: httpClient,
         accessToken: accessToken,
       );

  final GoogleCalendarClient _client;

  /// Calendars asked for per request. Google's own maximum for this endpoint.
  static const pageSize = 250;

  /// Pages followed before giving up.
  ///
  /// A bound rather than a loop that trusts the server: at [pageSize] per page
  /// this is far past any real account, and an endpoint that kept handing back
  /// page tokens would otherwise spin forever.
  static const maxPages = 10;

  @override
  Future<Result<List<CalendarListing>>> listCalendars() =>
      _client.guard(() async {
        final listings = <CalendarListing>[];
        String? pageToken;
        for (var page = 0; page < maxPages; page++) {
          final response = await _client.get(_listUri(pageToken));
          if (!GoogleCalendarClient.isSuccess(response.statusCode)) {
            return Err<List<CalendarListing>>(calendarFailure(response));
          }
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          for (final item in body['items'] as List<dynamic>? ?? const []) {
            final listing = _listingFrom(item as Map<String, dynamic>);
            if (listing != null) listings.add(listing);
          }
          pageToken = body['nextPageToken'] as String?;
          if (pageToken == null) break;
        }
        return Ok(listings..sort(_primaryFirst));
      });

  Uri _listUri(String? pageToken) => _client.uri(
    ['users', 'me', 'calendarList'],
    query: {
      // Kith writes events, so a calendar it could only read is not one the
      // household can link. Filtered by the server rather than by hand.
      'minAccessRole': 'writer',
      'maxResults': '$pageSize',
      'pageToken': ?pageToken,
    },
  );

  /// One entry, or null for one that names no calendar Kith could address.
  CalendarListing? _listingFrom(Map<String, dynamic> item) {
    final id = item['id'] as String?;
    if (id == null || id.isEmpty) return null;
    // A subscribed calendar can be renamed locally, and the local name is the
    // one the account holder recognises.
    final name =
        item['summaryOverride'] as String? ?? item['summary'] as String? ?? id;
    return CalendarListing(
      id: id,
      name: name.isEmpty ? id : name,
      isPrimary: item['primary'] == true,
    );
  }

  /// The account's own calendar first, then by name, then by id.
  ///
  /// Total and stable, so the picker does not reshuffle between openings.
  static int _primaryFirst(CalendarListing a, CalendarListing b) {
    if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return byName != 0 ? byName : a.id.compareTo(b.id);
  }
}
