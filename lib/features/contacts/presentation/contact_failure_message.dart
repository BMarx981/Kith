import 'package:kith/core/result/failure.dart';

/// User-facing copy for [failure] from a contact or relationship type write.
///
/// The switch is exhaustive over [Failure], so a new failure type fails to
/// compile until it has copy here. `Failure.message` is for logs and is never
/// shown, with one exception: a [ValidationFailure] is written by the domain
/// as copy for exactly this field, and says more than a generic line could.
String contactFailureMessage(Failure failure) => switch (failure) {
  NetworkFailure() =>
    'You appear to be offline. Try again once you are connected.',
  PermissionFailure() => 'You are not allowed to change this household.',
  NotFoundFailure() => 'That is no longer there. Go back and try again.',
  ValidationFailure(:final message) => message,
  ConflictFailure() => 'That label already exists.',
  AuthFailure() => 'Sign in again to continue.',
  UnknownFailure() => 'Something went wrong. Try again.',
};
