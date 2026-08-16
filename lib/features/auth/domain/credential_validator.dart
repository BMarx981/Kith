/// Client-side checks on what the user typed into the sign-in form.
///
/// These run before any network call so an obvious typo never costs a round
/// trip. The backend stays the authority: whatever it refuses comes back as an
/// `AuthFailure` and is shown the same way.
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
  ///
  /// Returns the error to show under the field, or null when it is usable.
  static String? email(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return 'Enter your email address.';
    if (!_emailPattern.hasMatch(value)) {
      return 'That does not look like an email address.';
    }
    return null;
  }

  /// Validates [input] as the password of an existing account.
  ///
  /// Only checks that there is something to send. An account made before the
  /// current strength rule still has to be able to sign in.
  static String? password(String? input) {
    if (input == null || input.isEmpty) return 'Enter your password.';
    return null;
  }

  /// Validates [input] as the password of an account being created.
  static String? newPassword(String? input) {
    final presence = password(input);
    if (presence != null) return presence;
    if (input!.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters.';
    }
    return null;
  }
}
