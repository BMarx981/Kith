import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/core/time/calendar_day.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/models/planned_hangout_status.dart';
import 'package:kith/data/repositories/firestore_errors.dart';
import 'package:kith/data/repositories/planned_hangout_repository.dart';

/// [PlannedHangoutRepository] backed by Cloud Firestore.
///
/// Plans live under `households/{hid}/plannedHangouts/{pid}`, so membership in
/// the household is the whole read/write gate; the rules validate the shape
/// this class writes.
class FirestorePlannedHangoutRepository implements PlannedHangoutRepository {
  /// The [Clock] is what makes the plan timestamps testable. It is positional
  /// because a named parameter cannot bind straight to a private field.
  const FirestorePlannedHangoutRepository(
    this._firestore, [
    this._clock = const Clock(),
  ]);

  final FirebaseFirestore _firestore;
  final Clock _clock;

  /// Top-level households collection.
  static const householdsPath = 'households';

  /// Planned hangouts subcollection of a household.
  static const plannedHangoutsPath = 'plannedHangouts';

  @override
  Stream<List<PlannedHangout>> watchPlannedHangouts(String householdId) =>
      FirestoreErrors.domainErrors(
        () => _plans(householdId)
            // Single-field ordering, so no composite index is needed. Two
            // plans on the same day come back in an order the server does not
            // define, which is what the client-side sort settles.
            .orderBy('plannedFor')
            .snapshots()
            .map((snapshot) {
              final plans = [
                for (final doc in snapshot.docs)
                  PlannedHangout.fromMap(doc.data()),
              ];
              return plans..sort(_soonestFirst);
            }),
      );

  @override
  Future<Result<PlannedHangout>> planHangout({
    required String householdId,
    required List<String> contactIds,
    required DateTime plannedFor,
    required String createdBy,
    String? note,
  }) => _create(
    householdId: householdId,
    contactIds: contactIds,
    day: plannedFor,
    status: PlannedHangoutStatus.proposed,
    createdBy: createdBy,
    note: note,
  );

  @override
  Future<Result<PlannedHangout>> snoozeContacts({
    required String householdId,
    required List<String> contactIds,
    required DateTime until,
    required String createdBy,
  }) => _create(
    householdId: householdId,
    contactIds: contactIds,
    day: until,
    status: PlannedHangoutStatus.snoozed,
    createdBy: createdBy,
    note: null,
  );

  @override
  Future<Result<void>> cancelPlan({
    required String householdId,
    required String plannedHangoutId,
  }) => FirestoreErrors.guard(() async {
    await _plans(householdId).doc(plannedHangoutId).delete();
    return const Ok(null);
  });

  @override
  Future<Result<void>> linkCalendarEvent({
    required String householdId,
    required String plannedHangoutId,
    required String calendarEventId,
  }) {
    final eventId = calendarEventId.trim();
    if (eventId.isEmpty ||
        eventId.length > PlannedHangout.maxCalendarEventIdLength) {
      return Future.value(
        const Err(ValidationFailure('That calendar event cannot be stored.')),
      );
    }
    return _patch(householdId, plannedHangoutId, {
      'status': PlannedHangoutStatus.confirmed.wireName,
      'calendarEventId': eventId,
    });
  }

  @override
  Future<Result<void>> unlinkCalendarEvent({
    required String householdId,
    required String plannedHangoutId,
  }) => _patch(householdId, plannedHangoutId, {
    'status': PlannedHangoutStatus.proposed.wireName,
    'calendarEventId': null,
  });

  @override
  Future<Result<void>> reschedulePlan({
    required String householdId,
    required String plannedHangoutId,
    required DateTime plannedFor,
  }) => _patch(householdId, plannedHangoutId, {
    // Normalised the way the constructor would: a plan names a day, and the
    // day is what is stored. See CalendarDay.
    'plannedFor': CalendarDay.of(plannedFor).millisecondsSinceEpoch,
  });

  /// Writes [fields] over an existing plan, stamping it as changed.
  ///
  /// A partial update rather than a whole document, so the fields the rules
  /// pin — id, createdBy, createdAt — are never sent at all, and two members
  /// changing different halves of a plan do not overwrite each other.
  Future<Result<void>> _patch(
    String householdId,
    String plannedHangoutId,
    Map<String, dynamic> fields,
  ) => FirestoreErrors.guard(() async {
    await _plans(householdId).doc(plannedHangoutId).update({
      ...fields,
      'updatedAt': _clock.now().toUtc().millisecondsSinceEpoch,
    });
    return const Ok(null);
  });

  /// Writes one plan, whichever of the two intents it records.
  ///
  /// Both writes differ only in the status and whether a note is offered, so
  /// the normalising, the validation and the timestamps live here once.
  Future<Result<PlannedHangout>> _create({
    required String householdId,
    required List<String> contactIds,
    required DateTime day,
    required PlannedHangoutStatus status,
    required String createdBy,
    required String? note,
  }) async {
    if (createdBy.isEmpty) {
      return const Err(ValidationFailure('Sign in again to make a plan.'));
    }
    final ids = _distinct(contactIds);
    final trimmed = note?.trim() ?? '';
    final invalid = _validate(ids, trimmed);
    if (invalid != null) return Err(invalid);

    return FirestoreErrors.guard(() async {
      final now = _clock.now().toUtc();
      final document = _plans(householdId).doc();
      final plan = PlannedHangout(
        id: document.id,
        plannedFor: day,
        contactIds: ids,
        status: status,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
        note: trimmed.isEmpty ? null : trimmed,
      );
      await document.set(plan.toMap());
      return Ok(plan);
    });
  }

  /// Soonest day first, then most recently made, then by id.
  ///
  /// Total and stable, so two plans for the same day never swap places
  /// between rebuilds.
  static int _soonestFirst(PlannedHangout a, PlannedHangout b) {
    final byDay = a.plannedFor.compareTo(b.plannedFor);
    if (byDay != 0) return byDay;
    final byMade = b.createdAt.compareTo(a.createdAt);
    return byMade != 0 ? byMade : a.id.compareTo(b.id);
  }

  /// [ids] with the blanks dropped and the first of any repeat kept, so the
  /// order the caller gave survives.
  static List<String> _distinct(List<String> ids) {
    final seen = <String>{};
    return [
      for (final id in ids)
        if (id.trim().isNotEmpty && seen.add(id.trim())) id.trim(),
    ];
  }

  /// Why a plan over [contactIds] with [note] cannot be stored, or null when
  /// it can.
  ///
  /// Mirrors the bounds in `firestore.rules`, so a document the backend would
  /// refuse is caught before the round trip.
  static Failure? _validate(List<String> contactIds, String note) {
    if (contactIds.isEmpty) {
      return const ValidationFailure('Choose who the plan is with.');
    }
    if (contactIds.length > PlannedHangout.maxContacts) {
      return const ValidationFailure(
        'One plan can name at most ${PlannedHangout.maxContacts} people.',
      );
    }
    if (note.length > PlannedHangout.maxNoteLength) {
      return const ValidationFailure(
        'Keep the note under ${PlannedHangout.maxNoteLength} characters.',
      );
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>> _plans(String householdId) =>
      _firestore
          .collection(householdsPath)
          .doc(householdId)
          .collection(plannedHangoutsPath);
}
