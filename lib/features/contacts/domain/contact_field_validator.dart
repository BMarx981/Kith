import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/features/contacts/domain/birthday.dart';
import 'package:kith/features/contacts/domain/cadence.dart';

/// Client-side checks on what the user typed into the contact editor and the
/// relationship type manager.
///
/// These run before any network call so an obvious slip never costs a round
/// trip. The repository stays the authority: it re-checks the same bounds on
/// the normalised draft, and the security rules re-check them again.
///
/// Each check returns the [ValidationFailure] to translate and show under the
/// field, or null when the input is usable. The copy lives in the ARB files,
/// keyed by the failure's issue; the message here is for logs.
abstract final class ContactFieldValidator {
  /// Validates [input] as a contact's name.
  static ValidationFailure? name(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) {
      return const ValidationFailure(
        'Give the contact a name.',
        issue: ValidationIssue.contactNameEmpty,
      );
    }
    return _bounded(value, Contact.maxNameLength);
  }

  /// Validates [input] as a relationship label.
  static ValidationFailure? labelName(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) {
      return const ValidationFailure(
        'Give the label a name.',
        issue: ValidationIssue.labelNameEmpty,
      );
    }
    return _bounded(value, RelationshipType.maxNameLength);
  }

  /// Validates one of the optional single-line detail fields: a phone number,
  /// an address, a guardian's name. Blank is always allowed.
  static ValidationFailure? detail(String? input) =>
      _bounded(input?.trim() ?? '', Contact.maxDetailLength);

  /// Validates the notes field. Blank is allowed.
  static ValidationFailure? notes(String? input) =>
      _bounded(input?.trim() ?? '', Contact.maxNotesLength);

  /// Validates a custom cadence typed as a number of days.
  ///
  /// Defers to [Cadence.parse], whose refusals are written as copy for
  /// exactly this field.
  static ValidationFailure? customCadence(String? input) =>
      _validationOnly(Cadence.parse(input ?? '').failureOrNull);

  /// Validates the birthday field. Blank is allowed: most contacts will
  /// never have one, and a birthday is not worth blocking a save over.
  ///
  /// Defers to [Birthday.parse], whose refusals are written as copy for
  /// exactly this field. [extraMonthNames] is passed through, so the field
  /// accepts the user's own language's month names.
  static ValidationFailure? birthday(
    String? input, {
    Map<String, int> extraMonthNames = const {},
  }) {
    if ((input?.trim() ?? '').isEmpty) return null;
    return _validationOnly(
      Birthday.parse(input!, extraMonthNames: extraMonthNames).failureOrNull,
    );
  }

  /// Reads the birthday field, answering null for blank and for anything
  /// [birthday] would have refused.
  static Birthday? parseBirthday(
    String? input, {
    Map<String, int> extraMonthNames = const {},
  }) => (input?.trim() ?? '').isEmpty
      ? null
      : Birthday.parse(input!, extraMonthNames: extraMonthNames).valueOrNull;

  /// Validates the comma-separated tag field.
  static ValidationFailure? tags(String? input) {
    final parsed = parseTags(input ?? '');
    if (parsed.length > Contact.maxTags) {
      return const ValidationFailure(
        'Use at most ${Contact.maxTags} tags.',
        issue: ValidationIssue.tooManyTags,
        args: {'max': Contact.maxTags},
      );
    }
    for (final tag in parsed) {
      if (tag.length > Contact.maxTagLength) {
        return const ValidationFailure(
          'Keep each tag under ${Contact.maxTagLength} characters.',
          issue: ValidationIssue.tagTooLong,
          args: {'max': Contact.maxTagLength},
        );
      }
    }
    return null;
  }

  /// The shared too-long refusal, or null when [value] fits under [max].
  static ValidationFailure? _bounded(String value, int max) =>
      value.length > max
      ? ValidationFailure(
          'Keep it under $max characters.',
          issue: ValidationIssue.textTooLong,
          args: {'max': max},
        )
      : null;

  /// [failure] as the [ValidationFailure] it is, or null. Parse seams return
  /// plain `Failure`; a field validator promises the translatable kind.
  static ValidationFailure? _validationOnly(Failure? failure) =>
      failure is ValidationFailure ? failure : null;

  /// Splits the comma-separated tag field into tags.
  ///
  /// Trimming and de-duplication are `ContactDraft.normalised`'s job, so this
  /// only has to decide where one tag ends and the next begins.
  static List<String> parseTags(String input) => [
    for (final part in input.split(','))
      if (part.trim().isNotEmpty) part.trim(),
  ];

  /// Renders [tags] back into the comma-separated form the field shows.
  static String formatTags(List<String> tags) => tags.join(', ');
}
