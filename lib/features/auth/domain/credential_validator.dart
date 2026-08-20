import 'package:kith/core/result/failure.dart';

/// Client-side checks on what the user typed into the sign-in form.
///
/// These run before any network call so an obvious typo never costs a round
/// trip. The backend stays the authority: whatever it refuses comes back as an
/// `AuthFailure` and is shown the same way.
///
/// Each check returns the [ValidationFailure] to translate and show under the
/// field, or null when the input is usable. The copy lives in the ARB files,
/// keyed by the failure's issue; the message here is for logs.
abstract final class CredentialValidator {
  /// Shortest password a new account may use.
  ///
  /// Firebase enforces six; eight is the app's own floor, applied only when
  /// creating an account.
  static const minPasswordLength = 8;

  /// Deliberately loose: `something@something.tld`, no whitespace. Anything
  /// stricter starts rejecting addresses that really exist.
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s.]+(\.[^@\s.]+)+$');

  /// Validates [input] as an email address.
  static ValidationFailure? email(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) {
      return const ValidationFailure(
        'Enter your email address.',
        issue: ValidationIssue.emailEmpty,
      );
    }
    if (!_emailPattern.hasMatch(value)) {
      return const ValidationFailure(
        'That does not look like an email address.',
        issue: ValidationIssue.emailMalformed,
      );
    }
    return null;
  }

  /// Validates [input] as the password of an existing account.
  ///
  /// Only checks that there is something to send. An account made before the
  /// current strength rule still has to be able to sign in.
  static ValidationFailure? password(String? input) {
    if (input == null || input.isEmpty) {
      return const ValidationFailure(
        'Enter your password.',
        issue: ValidationIssue.passwordEmpty,
      );
    }
    return null;
  }

  /// Validates [input] as the password of an account being created.
  static ValidationFailure? newPassword(String? input) {
    final presence = password(input);
    if (presence != null) return presence;
    if (input!.length < minPasswordLength) {
      return const ValidationFailure(
        'Use at least $minPasswordLength characters.',
        issue: ValidationIssue.passwordTooShort,
        args: {'min': minPasswordLength},
      );
    }
    return null;
  }
}
