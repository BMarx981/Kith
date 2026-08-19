import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';

/// Supplies an OAuth access token carrying the calendar scopes, or null when
/// the member has not authorised them.
///
/// A function rather than a stored string, and consulted on every call, so a
/// token that has expired between two writes is refreshed rather than reused.
typedef CalendarAccessTokenProvider = Future<String?> Function();

/// The transport the Google Calendar REST calls share.
///
/// Holds the three things every call needs — the base address, an authorised
/// header set, and the translation of anything thrown into a domain failure —
/// so the sink and the calendar directory state them once rather than each.
/// It returns [Result]s and never leaks an HTTP type.
class GoogleCalendarClient {
  const GoogleCalendarClient({
    required http.Client httpClient,
    required this._accessToken,
  }) : _http = httpClient;

  final http.Client _http;
  final CalendarAccessTokenProvider _accessToken;

  static final Uri _base = Uri.parse('https://www.googleapis.com/calendar/v3');

  /// The API address for [segments] under `calendar/v3`.
  ///
  /// Built through [Uri.replace] rather than by joining strings, so a calendar
  /// id — which is an email address — is escaped rather than splitting the
  /// path.
  Uri uri(List<String> segments, {Map<String, String>? query}) => _base.replace(
    pathSegments: [..._base.pathSegments, ...segments],
    queryParameters: query,
  );

  /// Reads [uri].
  Future<http.Response> get(Uri uri) =>
      _send((headers) => _http.get(uri, headers: headers));

  /// Posts [body], encoded as JSON, to [uri].
  Future<http.Response> post(Uri uri, Map<String, dynamic> body) => _send(
    (headers) => _http.post(uri, headers: headers, body: jsonEncode(body)),
  );

  /// Patches [uri] with [body], encoded as JSON.
  Future<http.Response> patch(Uri uri, Map<String, dynamic> body) => _send(
    (headers) => _http.patch(uri, headers: headers, body: jsonEncode(body)),
  );

  /// Deletes [uri].
  Future<http.Response> delete(Uri uri) =>
      _send((headers) => _http.delete(uri, headers: headers));

  /// Runs [body] with an authorised header set, or refuses without any I/O
  /// when no token is available.
  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) body,
  ) async {
    final token = await _accessToken();
    if (token == null) throw const CalendarUnauthorised();
    return body({
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=utf-8',
    });
  }

  /// Turns anything the transport throws into a domain failure, so no HTTP
  /// type leaves the calendar services.
  Future<Result<T>> guard<T>(Future<Result<T>> Function() body) async {
    try {
      return await body();
    } on CalendarUnauthorised {
      return const Err(
        PermissionFailure('No Google Calendar authorisation for this account.'),
      );
    } on http.ClientException catch (error) {
      return Err(NetworkFailure(error.message));
    } on TimeoutException catch (error) {
      return Err(NetworkFailure('Google Calendar timed out: $error'));
    } on Object catch (error) {
      return Err(UnknownFailure('Google Calendar call failed.', cause: error));
    }
  }

  /// Whether [status] says the call worked.
  static bool isSuccess(int status) => status >= 200 && status < 300;

  /// Whether [status] says the thing addressed is not there any more.
  static bool isGone(int status) => status == 404 || status == 410;
}

/// Thrown inside a calendar service when no access token is available, so the
/// refusal travels back through the same guard as every other failure.
class CalendarUnauthorised implements Exception {
  const CalendarUnauthorised();
}

/// Maps a failed Google Calendar response onto the domain failure that
/// describes it.
///
/// Exposed for its own tests: the status-to-failure table is the part of the
/// transport most worth pinning, and reaching it through every endpoint would
/// say the same thing many times over.
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
