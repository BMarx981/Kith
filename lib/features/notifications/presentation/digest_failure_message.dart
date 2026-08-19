import 'package:kith/core/result/failure.dart';

/// User-facing copy for [failure] from setting up the weekly digest.
///
/// The switch is exhaustive over [Failure], so a new failure type fails to
/// compile until it has copy here. `Failure.message` is for logs and is never
/// shown, with one exception: a [ValidationFailure] is written by the domain
/// as copy for exactly this surface.
///
/// Separate from the household copy rather than shared, because the digest
/// fails in two different places: storing the preference is a Firestore write
/// like any other, while scheduling it is the device's own notification
/// system, and "something went wrong saving that" would send somebody looking
/// in the wrong place for a phone that would not set a reminder.
String digestFailureMessage(Failure failure) => switch (failure) {
  NetworkFailure() =>
    'The digest setting could not be saved. Try again once you are connected.',
  PermissionFailure() =>
    'You are not allowed to change this household. Ask whoever set it up.',
  NotFoundFailure() => 'This household is no longer here.',
  ValidationFailure(:final message) => message,
  ConflictFailure() => 'That was changed somewhere else. Try again.',
  AuthFailure() => 'Sign in again to continue.',
  UnknownFailure() => 'The digest could not be set up on this device.',
};
