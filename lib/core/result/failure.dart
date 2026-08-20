import 'package:flutter/foundation.dart';

/// Domain-level error types.
///
/// Repositories translate infrastructure errors (`FirebaseException`, socket
/// errors, malformed documents) into these before returning. Nothing above the
/// repository layer ever sees a Firebase type.
@immutable
sealed class Failure {
  const Failure(this.message);

  /// Human-readable description, safe to log. Not user-facing copy.
  final String message;

  /// Stable type name for logs. Spelled out rather than derived from
  /// `runtimeType`, which is not reliable once the build is obfuscated.
  String get name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          other.runtimeType == runtimeType &&
          other.message == message;

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => '$name($message)';
}

/// The device is offline, or the backend was unreachable. Worth retrying.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);

  @override
  String get name => 'NetworkFailure';
}

/// Security rules rejected the operation, e.g. the user is not a member of
/// the household they addressed.
final class PermissionFailure extends Failure {
  const PermissionFailure(super.message);

  @override
  String get name => 'PermissionFailure';
}

/// The addressed document does not exist, e.g. an invite code that matches no
/// household.
final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);

  @override
  String get name => 'NotFoundFailure';
}

/// What a field refused, in terms the UI can translate.
///
/// One flat enum across every field the app validates, because the mapping to
/// copy lives in one place (`validationMessage` in `lib/l10n/`) and a flat
/// switch there is exhaustive: adding a case here fails to compile until it
/// has copy in every locale's ARB file.
enum ValidationIssue {
  /// The email field was left empty.
  emailEmpty,

  /// The email field holds something that is not an address.
  emailMalformed,

  /// The password field was left empty.
  passwordEmpty,

  /// A new account's password is shorter than the app's floor.
  passwordTooShort,

  /// The contact name field was left empty.
  contactNameEmpty,

  /// A relationship label was left empty.
  labelNameEmpty,

  /// A household name was left empty.
  householdNameEmpty,

  /// The member display name was left empty.
  displayNameEmpty,

  /// A bounded text field exceeds its maximum length. `args['max']` is the
  /// bound.
  textTooLong,

  /// More tags than a contact may carry. `args['max']` is the bound.
  tooManyTags,

  /// One tag is longer than allowed. `args['max']` is the bound.
  tagTooLong,

  /// The custom cadence field was left empty.
  cadenceEmpty,

  /// The custom cadence is not a whole number.
  cadenceNotANumber,

  /// The custom cadence is below the minimum. `args['min']` is the bound.
  cadenceTooShort,

  /// The custom cadence is above the maximum. `args['max']` is the bound.
  cadenceTooLong,

  /// The birthday field was left empty where a value was required.
  birthdayEmpty,

  /// The birthday could not be read in any accepted form.
  birthdayUnreadable,

  /// The birthday names a month that does not exist.
  birthdayBadMonth,

  /// The birth year is outside the accepted range. `args['min']` and
  /// `args['max']` are the bounds.
  birthdayYearOutOfRange,

  /// The day does not exist in that month. `args['month']` is the month
  /// number, `args['day']` the day.
  birthdayNoSuchDay,

  /// The invite code field was left empty.
  inviteCodeEmpty,

  /// The invite code is the wrong length. `args['length']` is the expected
  /// length.
  inviteCodeWrongLength,

  /// The invite code holds a character outside the alphabet. `args['char']`
  /// is the offending character.
  inviteCodeBadCharacter,
}

/// Input failed a domain rule before any I/O was attempted.
///
/// [issue] is what the UI translates into copy; [message] stays English and is
/// for logs, like every other failure's. A validation failure raised by a
/// repository rather than a field check may carry no issue.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.issue, this.args = const {}});

  /// Which rule was broken, or null for a repository-side refusal that no
  /// field maps to.
  final ValidationIssue? issue;

  /// The numbers and characters the copy for [issue] interpolates.
  final Map<String, Object> args;

  @override
  String get name => 'ValidationFailure';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationFailure &&
          other.message == message &&
          other.issue == issue &&
          mapEquals(other.args, args);

  @override
  int get hashCode =>
      Object.hash(ValidationFailure, message, issue, Object.hashAll(args.keys));
}

/// The write collided with existing state, e.g. a regenerated invite code that
/// is already in use.
final class ConflictFailure extends Failure {
  const ConflictFailure(super.message);

  @override
  String get name => 'ConflictFailure';
}

/// Why a sign-in, sign-up or sign-out attempt failed.
///
/// The service layer maps provider-specific error codes onto these so the UI
/// can branch on intent ("that password is wrong") without knowing which
/// backend produced the error.
enum AuthFailureReason {
  /// Email/password pair did not match an account.
  invalidCredentials,

  /// Sign-up used an address that already has an account.
  emailAlreadyInUse,

  /// Sign-up password did not meet the backend's strength rule.
  weakPassword,

  /// The address is not a well-formed email.
  invalidEmail,

  /// The account exists but has been disabled.
  userDisabled,

  /// Too many attempts in too short a window; the backend is throttling.
  tooManyRequests,

  /// The backend could not be reached at all. Worth retrying as-is, and
  /// distinct from [unknown]: nothing about the attempt itself was wrong.
  network,

  /// This sign-in method is switched off in the Firebase console, or is not
  /// wired up in this build.
  providerUnavailable,

  /// The user dismissed a federated sign-in sheet. Not an error to report.
  cancelled,

  /// The address already has an account created through a different provider.
  /// Signing in the original way is the fix, so this is worth saying plainly
  /// rather than collapsing into [invalidCredentials].
  accountExistsWithDifferentCredential,

  /// The provider rejected the attempt for a reason not listed above.
  unknown,
}

/// Authentication was refused. [reason] carries the actionable detail.
final class AuthFailure extends Failure {
  const AuthFailure(this.reason, super.message);

  /// What went wrong, in terms the UI can branch on.
  final AuthFailureReason reason;

  @override
  String get name => 'AuthFailure';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthFailure &&
          other.message == message &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(AuthFailure, message, reason);

  @override
  String toString() => '$name(${reason.name}: $message)';
}

/// Anything not covered above. Carries the original error for logging.
final class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {this.cause});

  /// The underlying error, kept for diagnostics. Never surfaced to the UI.
  final Object? cause;

  @override
  String get name => 'UnknownFailure';
}
