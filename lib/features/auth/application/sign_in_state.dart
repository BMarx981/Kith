import 'package:flutter/foundation.dart';
import 'package:kith/core/result/failure.dart';

/// Which form the sign-in screen is showing.
enum SignInMode {
  /// Signing into an existing account.
  signIn,

  /// Creating a new account.
  signUp,
}

/// Everything the sign-in screen renders that is not held by its text fields.
@immutable
class SignInState {
  const SignInState({
    this.mode = SignInMode.signIn,
    this.isSubmitting = false,
    this.failure,
    this.passwordResetSentTo,
  });

  /// Whether the form signs in or creates an account.
  final SignInMode mode;

  /// Whether a request is in flight; the form is inert while it is.
  final bool isSubmitting;

  /// Why the last attempt was refused, or null if none was.
  final AuthFailure? failure;

  /// Address the last password reset link went to, or null if none was sent.
  ///
  /// Holds the address rather than a flag so the confirmation can name it, and
  /// so sending to a second address is a state change the screen notices.
  final String? passwordResetSentTo;

  /// Returns a copy with the given fields replaced.
  ///
  /// The `clear` flags exist because passing null to a named parameter cannot
  /// be told apart from omitting it.
  SignInState copyWith({
    SignInMode? mode,
    bool? isSubmitting,
    AuthFailure? failure,
    String? passwordResetSentTo,
    bool clearFailure = false,
    bool clearPasswordResetSentTo = false,
  }) => SignInState(
    mode: mode ?? this.mode,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    failure: clearFailure ? null : failure ?? this.failure,
    passwordResetSentTo: clearPasswordResetSentTo
        ? null
        : passwordResetSentTo ?? this.passwordResetSentTo,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignInState &&
          other.mode == mode &&
          other.isSubmitting == isSubmitting &&
          other.failure == failure &&
          other.passwordResetSentTo == passwordResetSentTo;

  @override
  int get hashCode =>
      Object.hash(mode, isSubmitting, failure, passwordResetSentTo);

  @override
  String toString() =>
      'SignInState(mode: ${mode.name}, isSubmitting: $isSubmitting, '
      'failure: $failure, passwordResetSentTo: $passwordResetSentTo)';
}
