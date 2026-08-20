import 'package:kith/core/result/failure.dart';
import 'package:kith/features/household/domain/invite_code.dart';

/// Client-side checks on what the user typed into the create-or-join form.
///
/// These run before any network call so an obvious typo never costs a round
/// trip. The backend stays the authority: whatever the rules refuse comes back
/// as a `Failure` and is shown the same way.
///
/// Each check returns the [ValidationFailure] to translate and show under the
/// field, or null when the input is usable. The copy lives in the ARB files,
/// keyed by the failure's issue; the message here is for logs.
abstract final class HouseholdFieldValidator {
  /// Longest name the security rules will store, for either a household or a
  /// member. Mirrors `isBoundedString(..., 100)` in `firestore.rules`, so a
  /// name that would be refused server-side is caught under the field instead.
  static const maxNameLength = 100;

  /// Validates [input] as a household name.
  static ValidationFailure? name(String? input) => _boundedName(
    input,
    const ValidationFailure(
      'Give the household a name.',
      issue: ValidationIssue.householdNameEmpty,
    ),
  );

  /// Validates [input] as the name other members will see.
  static ValidationFailure? displayName(String? input) => _boundedName(
    input,
    const ValidationFailure(
      'Enter the name to show others.',
      issue: ValidationIssue.displayNameEmpty,
    ),
  );

  /// Validates [input] as an invite code.
  ///
  /// Defers to [InviteCode.parse], which normalises what was typed before
  /// judging it and knows which character is the problem. Its refusals are
  /// written as copy for exactly this field.
  static ValidationFailure? inviteCode(String? input) =>
      switch (InviteCode.parse(input ?? '').failureOrNull) {
        final ValidationFailure failure => failure,
        _ => null,
      };

  static ValidationFailure? _boundedName(
    String? input,
    ValidationFailure whenEmpty,
  ) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return whenEmpty;
    if (value.length > maxNameLength) {
      return const ValidationFailure(
        'Keep it under $maxNameLength characters.',
        issue: ValidationIssue.textTooLong,
        args: {'max': maxNameLength},
      );
    }
    return null;
  }
}
