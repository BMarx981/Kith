import 'package:kith/core/result/failure.dart';

/// User-facing copy for [failure] from linking or reading a calendar.
///
/// The switch is exhaustive over [Failure], so a new failure type fails to
/// compile until it has copy here. `Failure.message` is for logs and is never
/// shown, with one exception: a [ValidationFailure] is written by the domain as
/// copy for exactly this surface.
///
/// Separate from the household and suggestion messages rather than shared,
/// because the same failure means something different here: a permission
/// problem is almost always Google's rather than Kith's, and telling somebody
/// they are not allowed to change this household would send them looking in
/// the wrong place.
String calendarFailureMessage(Failure failure) => switch (failure) {
  NetworkFailure() =>
    'Google Calendar could not be reached. Try again once you are connected.',
  PermissionFailure() =>
    'Kith is not allowed to use that calendar. Connect the Google account '
        'again, and pick a calendar you can write to.',
  NotFoundFailure() => 'That calendar is no longer there.',
  ValidationFailure(:final message) => message,
  ConflictFailure() => 'That calendar was changed somewhere else. Try again.',
  AuthFailure() => 'Sign in again to continue.',
  UnknownFailure() => 'Something went wrong with the calendar. Try again.',
};
