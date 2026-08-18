import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/data/repositories/firestore_errors.dart';
import 'package:kith/data/repositories/hangout_repository.dart';
import 'package:kith/features/hangouts/domain/hangout_draft.dart';

/// [HangoutRepository] backed by Cloud Firestore.
///
/// Hangouts live under `households/{hid}/hangouts/{hgid}`, so membership in
/// the household is the whole read/write gate; the rules validate the shape
/// this class writes.
class FirestoreHangoutRepository implements HangoutRepository {
  /// The [Clock] is what makes the log and edit timestamps testable. It is
  /// positional because a named parameter cannot bind straight to a private
  /// field.
  const FirestoreHangoutRepository(
    this._firestore, [
    this._clock = const Clock(),
  ]);

  final FirebaseFirestore _firestore;
  final Clock _clock;

  /// Top-level households collection.
  static const householdsPath = 'households';

  /// Hangouts subcollection of a household.
  static const hangoutsPath = 'hangouts';

  @override
  Stream<List<Hangout>> watchHangouts(String householdId) =>
      FirestoreErrors.domainErrors(
        () => _hangouts(householdId)
            // Single-field ordering, so no composite index is needed. Two
            // hangouts on the same day come back in an order the server does
            // not define, which is what the client-side sort settles.
            .orderBy('occurredOn', descending: true)
            .snapshots()
            .map((snapshot) {
              final hangouts = [
                for (final doc in snapshot.docs) Hangout.fromMap(doc.data()),
              ];
              return hangouts..sort(_mostRecentFirst);
            }),
      );

  @override
  Future<Result<Hangout>> logHangout({
    required String householdId,
    required HangoutDraft draft,
    required String createdBy,
  }) async {
    if (createdBy.isEmpty) {
      return const Err(ValidationFailure('Sign in again to log a hangout.'));
    }
    final normalised = draft.normalised();
    final invalid = _validate(normalised);
    if (invalid != null) return Err(invalid);

    return FirestoreErrors.guard(() async {
      final now = _clock.now().toUtc();
      final document = _hangouts(householdId).doc();
      final hangout = normalised.toHangout(
        id: document.id,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );
      await document.set(hangout.toMap());
      return Ok(hangout);
    });
  }

  @override
  Future<Result<void>> updateHangout({
    required String householdId,
    required String hangoutId,
    required HangoutDraft draft,
  }) async {
    final normalised = draft.normalised();
    final invalid = _validate(normalised);
    if (invalid != null) return Err(invalid);

    return FirestoreErrors.guard(() async {
      // A partial update rather than a whole-document set: `id`, `createdBy`
      // and `createdAt` are not the form's to write, so an edit cannot
      // reassign a hangout to whoever happened to open it.
      final now = _clock.now().toUtc();
      final fields =
          normalised
              .toHangout(
                id: hangoutId,
                createdBy: '',
                createdAt: now,
                updatedAt: now,
              )
              .toMap()
            ..remove('id')
            ..remove('createdBy')
            ..remove('createdAt');
      await _hangouts(householdId).doc(hangoutId).update(fields);
      return const Ok(null);
    });
  }

  @override
  Future<Result<void>> deleteHangout({
    required String householdId,
    required String hangoutId,
  }) => FirestoreErrors.guard(() async {
    await _hangouts(householdId).doc(hangoutId).delete();
    return const Ok(null);
  });

  /// Most recent day first, then most recently logged, then by id.
  ///
  /// Total and stable, so the timeline never reshuffles two same-day entries
  /// between rebuilds.
  static int _mostRecentFirst(Hangout a, Hangout b) {
    final byDay = b.occurredOn.compareTo(a.occurredOn);
    if (byDay != 0) return byDay;
    final byLogged = b.createdAt.compareTo(a.createdAt);
    return byLogged != 0 ? byLogged : a.id.compareTo(b.id);
  }

  /// Why [draft] cannot be stored, or null when it can.
  ///
  /// Mirrors the bounds in `firestore.rules`, so a document the backend would
  /// refuse is caught before the round trip. The draft is expected to be
  /// normalised already.
  static Failure? _validate(HangoutDraft draft) {
    if (draft.contactIds.isEmpty) {
      return const ValidationFailure('Choose who you saw.');
    }
    if (draft.contactIds.length > Hangout.maxContacts) {
      return const ValidationFailure(
        'One hangout can name at most ${Hangout.maxContacts} people.',
      );
    }
    if (draft.attendeeIds.length > Hangout.maxAttendees) {
      return const ValidationFailure(
        'At most ${Hangout.maxAttendees} of you can be on one hangout.',
      );
    }
    if ((draft.note?.length ?? 0) > Hangout.maxNoteLength) {
      return const ValidationFailure(
        'Keep the note under ${Hangout.maxNoteLength} characters.',
      );
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>> _hangouts(String householdId) =>
      _firestore
          .collection(householdsPath)
          .doc(householdId)
          .collection(hangoutsPath);
}
