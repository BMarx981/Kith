import 'package:kith/features/household/domain/invite_code.dart';

/// Client-side checks on what the user typed into the create-or-join form.
///
/// These run before any network call so an obvious typo never costs a round
/// trip. The backend stays the authority: whatever the rules refuse comes back
/// as a `Failure` and is shown the same way.
abstract final class HouseholdFieldValidator {
  /// Longest name the security rules will store, for either a household or a
  /// member. Mirrors `isBoundedString(..., 100)` in `firestore.rules`, so a
  /// name that would be refused server-side is caught under the field instead.
  static const maxNameLength = 100;

  /// Validates [input] as a household name.
  ///
  /// Returns the error to show under the field, or null when it is usable.
  static String? name(String? input) =>
      _boundedName(input, 'Give the household a name.');

  /// Validates [input] as the name other members will see.
  static String? displayName(String? input) =>
      _boundedName(input, 'Enter the name to show others.');

  /// Validates [input] as an invite code.
  ///
  /// Defers to [InviteCode.parse], which normalises what was typed before
  /// judging it and knows which character is the problem. Its refusals are
  /// written as copy for exactly this field.
  static String? inviteCode(String? input) =>
      InviteCode.parse(input ?? '').failureOrNull?.message;

  static String? _boundedName(String? input, String whenEmpty) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return whenEmpty;
    if (value.length > maxNameLength) {
      return 'Keep it under $maxNameLength characters.';
    }
    return null;
  }
}
