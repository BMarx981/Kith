import 'package:kith/core/result/failure.dart';

/// User-facing copy for [failure].
///
/// The switch is exhaustive over [AuthFailureReason], so adding a reason to
/// the enum fails to compile until it has copy here. `Failure.message` is for
/// logs and is never shown.
String authFailureMessage(AuthFailure failure) => switch (failure.reason) {
  AuthFailureReason.invalidCredentials =>
    'That email and password do not match an account.',
  AuthFailureReason.emailAlreadyInUse =>
    'That address already has an account. Try signing in instead.',
  AuthFailureReason.weakPassword =>
    'That password is too easy to guess. Pick a longer one.',
  AuthFailureReason.invalidEmail => 'That does not look like an email address.',
  AuthFailureReason.userDisabled => 'That account has been disabled.',
  AuthFailureReason.tooManyRequests =>
    'Too many attempts. Wait a minute, then try again.',
  AuthFailureReason.providerUnavailable =>
    'That way of signing in is not available yet.',
  AuthFailureReason.cancelled => 'Sign-in was cancelled.',
  AuthFailureReason.unknown => 'Something went wrong. Try again.',
};
