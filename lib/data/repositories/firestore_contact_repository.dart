import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/repositories/contact_repository.dart';
import 'package:kith/data/repositories/firestore_errors.dart';
import 'package:kith/features/contacts/domain/contact_draft.dart';

/// [ContactRepository] backed by Cloud Firestore.
///
/// Contacts live under `households/{hid}/contacts/{cid}`, so membership in the
/// household is the whole read/write gate; the rules validate the shape this
/// class writes.
class FirestoreContactRepository implements ContactRepository {
  /// The [Clock] is what makes creation and edit timestamps testable. It is
  /// positional because a named parameter cannot bind straight to a private
  /// field.
  const FirestoreContactRepository(
    this._firestore, [
    this._clock = const Clock(),
  ]);

  final FirebaseFirestore _firestore;
  final Clock _clock;

  /// Top-level households collection.
  static const householdsPath = 'households';

  /// Contacts subcollection of a household.
  static const contactsPath = 'contacts';

  @override
  Stream<List<Contact>> watchContacts(String householdId) =>
      FirestoreErrors.domainErrors(
        () => _contacts(householdId)
            // Ordered by when they were added, which is the only ordering the
            // stored data supports without a composite index. The list view
            // sorts what it renders; this is just a stable starting point.
            .orderBy('createdAt')
            .snapshots()
            .map(
              (snapshot) => snapshot.docs
                  .map((doc) => Contact.fromMap(doc.data()))
                  .toList(),
            ),
      );

  @override
  Future<Result<Contact>> createContact({
    required String householdId,
    required ContactDraft draft,
  }) async {
    final normalised = draft.normalised();
    final invalid = _validate(normalised);
    if (invalid != null) return Err(invalid);

    return FirestoreErrors.guard(() async {
      final now = _clock.now().toUtc();
      final document = _contacts(householdId).doc();
      final contact = normalised.toContact(
        id: document.id,
        createdAt: now,
        updatedAt: now,
      );
      await document.set(contact.toMap());
      return Ok(contact);
    });
  }

  @override
  Future<Result<void>> updateContact({
    required String householdId,
    required String contactId,
    required ContactDraft draft,
  }) async {
    final normalised = draft.normalised();
    final invalid = _validate(normalised);
    if (invalid != null) return Err(invalid);

    return FirestoreErrors.guard(() async {
      // A partial update rather than a whole-document set: `id`, `createdAt`
      // and `isArchived` are not the editor's to write, and leaving them out
      // means an edit cannot undo an archive that happened on another device
      // while the form was open.
      final now = _clock.now().toUtc();
      final fields =
          normalised
              .toContact(id: contactId, createdAt: now, updatedAt: now)
              .toMap()
            ..remove('id')
            ..remove('createdAt')
            ..remove('isArchived');
      await _contacts(householdId).doc(contactId).update(fields);
      return const Ok(null);
    });
  }

  @override
  Future<Result<void>> setArchived({
    required String householdId,
    required String contactId,
    required bool isArchived,
  }) => FirestoreErrors.guard(() async {
    await _contacts(householdId).doc(contactId).update({
      'isArchived': isArchived,
      'updatedAt': _clock.now().toUtc().millisecondsSinceEpoch,
    });
    return const Ok(null);
  });

  /// Why [draft] cannot be stored, or null when it can.
  ///
  /// Mirrors the bounds in `firestore.rules`, so a document the backend would
  /// refuse is caught before the round trip. The draft is expected to be
  /// normalised already; blank-but-present values read as missing.
  static Failure? _validate(ContactDraft draft) {
    if (draft.name.isEmpty) {
      return const ValidationFailure('Give the contact a name.');
    }
    if (draft.name.length > Contact.maxNameLength) {
      return const ValidationFailure(
        'Keep the name under ${Contact.maxNameLength} characters.',
      );
    }
    if (draft.relationshipTypeId.isEmpty) {
      return const ValidationFailure('Choose a relationship type.');
    }
    for (final detail in [
      draft.phone,
      draft.email,
      draft.address,
      draft.guardianName,
      draft.guardianPhone,
    ]) {
      if ((detail?.length ?? 0) > Contact.maxDetailLength) {
        return const ValidationFailure(
          'Keep each detail under ${Contact.maxDetailLength} characters.',
        );
      }
    }
    if ((draft.notes?.length ?? 0) > Contact.maxNotesLength) {
      return const ValidationFailure(
        'Keep the notes under ${Contact.maxNotesLength} characters.',
      );
    }
    if (draft.tags.length > Contact.maxTags) {
      return const ValidationFailure(
        'Use at most ${Contact.maxTags} tags.',
      );
    }
    for (final tag in draft.tags) {
      if (tag.length > Contact.maxTagLength) {
        return const ValidationFailure(
          'Keep each tag under ${Contact.maxTagLength} characters.',
        );
      }
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>> _contacts(String householdId) =>
      _firestore
          .collection(householdsPath)
          .doc(householdId)
          .collection(contactsPath);
}
