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
abstract final class ContactFieldValidator {
  /// Validates [input] as a contact's name.
  ///
  /// Returns the error to show under the field, or null when it is usable.
  static String? name(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return 'Give the contact a name.';
    if (value.length > Contact.maxNameLength) {
      return 'Keep it under ${Contact.maxNameLength} characters.';
    }
    return null;
  }

  /// Validates [input] as a relationship label.
  static String? labelName(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return 'Give the label a name.';
    if (value.length > RelationshipType.maxNameLength) {
      return 'Keep it under ${RelationshipType.maxNameLength} characters.';
    }
    return null;
  }

  /// Validates one of the optional single-line detail fields: a phone number,
  /// an address, a guardian's name. Blank is always allowed.
  static String? detail(String? input) {
    final value = input?.trim() ?? '';
    if (value.length > Contact.maxDetailLength) {
      return 'Keep it under ${Contact.maxDetailLength} characters.';
    }
    return null;
  }

  /// Validates the notes field. Blank is allowed.
  static String? notes(String? input) {
    final value = input?.trim() ?? '';
    if (value.length > Contact.maxNotesLength) {
      return 'Keep it under ${Contact.maxNotesLength} characters.';
    }
    return null;
  }

  /// Validates a custom cadence typed as a number of days.
  ///
  /// Defers to [Cadence.parse], whose refusals are written as copy for
  /// exactly this field.
  static String? customCadence(String? input) =>
      Cadence.parse(input ?? '').failureOrNull?.message;

  /// Validates the birthday field. Blank is allowed: most contacts will
  /// never have one, and a birthday is not worth blocking a save over.
  ///
  /// Defers to [Birthday.parse], whose refusals are written as copy for
  /// exactly this field.
  static String? birthday(String? input) {
    if ((input?.trim() ?? '').isEmpty) return null;
    return Birthday.parse(input!).failureOrNull?.message;
  }

  /// Reads the birthday field, answering null for blank and for anything
  /// [birthday] would have refused.
  static Birthday? parseBirthday(String? input) =>
      (input?.trim() ?? '').isEmpty ? null : Birthday.tryParse(input);

  /// Validates the comma-separated tag field.
  static String? tags(String? input) {
    final parsed = parseTags(input ?? '');
    if (parsed.length > Contact.maxTags) {
      return 'Use at most ${Contact.maxTags} tags.';
    }
    for (final tag in parsed) {
      if (tag.length > Contact.maxTagLength) {
        return 'Keep each tag under ${Contact.maxTagLength} characters.';
      }
    }
    return null;
  }

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
