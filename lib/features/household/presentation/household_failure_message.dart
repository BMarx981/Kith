import 'package:kith/core/result/failure.dart';

/// User-facing copy for [failure] from the create-or-join flow.
///
/// The switch is exhaustive over [Failure], so a new failure type fails to
/// compile until it has copy here. `Failure.message` is for logs and is never
/// shown; what the user typed is judged under the field by
/// `HouseholdFieldValidator` before it ever gets this far.
String householdFailureMessage(Failure failure) => switch (failure) {
  NetworkFailure() =>
    'You appear to be offline. Try again once you are connected.',
  PermissionFailure() => 'Sign in again to continue.',
  NotFoundFailure() =>
    'That code does not match a household. Check it and try again.',
  ValidationFailure() => 'Check what you typed and try again.',
  ConflictFailure() => 'Something got in the way. Try that again.',
  AuthFailure() => 'Sign in again to continue.',
  UnknownFailure() => 'Something went wrong. Try again.',
};
