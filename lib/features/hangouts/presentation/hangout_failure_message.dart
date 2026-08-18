import 'package:kith/core/result/failure.dart';

/// User-facing copy for [failure] from a hangout read or write.
///
/// The switch is exhaustive over [Failure], so a new failure type fails to
/// compile until it has copy here. `Failure.message` is for logs and is never
/// shown, with one exception: a [ValidationFailure] is written by the domain
/// as copy for exactly this form, and says more than a generic line could.
///
/// Separate from `contactFailureMessage` rather than shared, because the same
/// failure means something different here: a conflict on a contact write is a
/// duplicate label, and there is no such thing on a hangout.
String hangoutFailureMessage(Failure failure) => switch (failure) {
  NetworkFailure() =>
    'You appear to be offline. Try again once you are connected.',
  PermissionFailure() => 'You are not allowed to change this household.',
  NotFoundFailure() => 'That hangout is no longer there.',
  ValidationFailure(:final message) => message,
  ConflictFailure() => 'That hangout was changed somewhere else. Try again.',
  AuthFailure() => 'Sign in again to continue.',
  UnknownFailure() => 'Something went wrong. Try again.',
};
