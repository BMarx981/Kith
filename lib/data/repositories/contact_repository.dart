import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/features/contacts/domain/contact_draft.dart';

/// Reads and writes the people a household tracks.
///
/// Implementations translate backend errors into domain failures before
/// returning; nothing above this interface sees a `FirebaseException`.
abstract interface class ContactRepository {
  /// Every contact in [householdId], archived ones included.
  ///
  /// Archived contacts are streamed rather than filtered out server-side
  /// because the list view offers to show them, and a household's contact
  /// list is small enough that one query answers both questions.
  Stream<List<Contact>> watchContacts(String householdId);

  /// Adds [draft] to [householdId], assigning it an id and its timestamps.
  ///
  /// The draft is normalised first, then checked: an empty name or a missing
  /// relationship type comes back as a `ValidationFailure` without any I/O.
  Future<Result<Contact>> createContact({
    required String householdId,
    required ContactDraft draft,
  });

  /// Applies [draft] to the contact [contactId] in [householdId].
  ///
  /// Touches only the fields a draft carries, so the archived flag and the
  /// creation timestamp survive an edit. Fails with a `NotFoundFailure` if
  /// the contact was deleted from under the editor.
  Future<Result<void>> updateContact({
    required String householdId,
    required String contactId,
    required ContactDraft draft,
  });

  /// Archives or restores the contact [contactId] in [householdId].
  ///
  /// Archiving is the only removal Kith offers: a contact's hangouts are the
  /// household's history, and deleting the person would take that with it.
  Future<Result<void>> setArchived({
    required String householdId,
    required String contactId,
    required bool isArchived,
  });
}
