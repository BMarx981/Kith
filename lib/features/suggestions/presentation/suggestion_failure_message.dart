import 'package:kith/core/result/failure.dart';

/// User-facing copy for [failure] from a plan read or write.
///
/// The switch is exhaustive over [Failure], so a new failure type fails to
/// compile until it has copy here. `Failure.message` is for logs and is never
/// shown, with one exception: a [ValidationFailure] is written by the domain as
/// copy for exactly this surface, and says more than a generic line could.
///
/// Separate from the contact and hangout messages rather than shared, because
/// the same failure means something different here: a plan that is no longer
/// there has usually just been kept or dropped by the other partner, which is
/// not an error worth alarming anyone about.
String suggestionFailureMessage(Failure failure) => switch (failure) {
  NetworkFailure() =>
    'You appear to be offline. Try again once you are connected.',
  PermissionFailure() => 'You are not allowed to change this household.',
  NotFoundFailure() => 'That plan is no longer there.',
  ValidationFailure(:final message) => message,
  ConflictFailure() => 'That plan was changed somewhere else. Try again.',
  AuthFailure() => 'Sign in again to continue.',
  UnknownFailure() => 'Something went wrong. Try again.',
};
