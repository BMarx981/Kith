import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/planned_hangout.dart';

/// Reads and writes a household's intents about meetups still to come.
///
/// Implementations translate backend errors into domain failures before
/// returning; nothing above this interface sees a `FirebaseException`.
///
/// The three writes are the three things the Reconnect section offers, rather
/// than a general create/update pair: a plan is never edited field by field in
/// M4, it is made, deferred, or dropped.
abstract interface class PlannedHangoutRepository {
  /// Every plan in [householdId], soonest day first.
  ///
  /// Past plans are streamed along with future ones rather than filtered
  /// server-side: what counts as spent depends on the household's "now", the
  /// list is small, and the suggestion engine is the one place that decides.
  Stream<List<PlannedHangout>> watchPlannedHangouts(String householdId);

  /// Records an intent to see [contactIds] on [plannedFor].
  ///
  /// Comes back as a `ValidationFailure` without any I/O for a plan naming
  /// nobody. Nothing stops two plans naming the same contact: two partners
  /// each arranging something is a thing that happens, and the engine reads
  /// whichever comes soonest.
  Future<Result<PlannedHangout>> planHangout({
    required String householdId,
    required List<String> contactIds,
    required DateTime plannedFor,
    required String createdBy,
    String? note,
  });

  /// Stops suggesting [contactIds] until [until].
  ///
  /// Stored as a plan with the snoozed status rather than as a flag on the
  /// contact, so that deferring somebody is a dated household act both
  /// partners can see rather than a hidden edit to a shared record.
  Future<Result<PlannedHangout>> snoozeContacts({
    required String householdId,
    required List<String> contactIds,
    required DateTime until,
    required String createdBy,
  });

  /// Drops the plan [plannedHangoutId] from [householdId].
  ///
  /// A hard delete, like a hangout's: an arrangement that is off, or a snooze
  /// somebody undid, is not history worth keeping, and nothing hangs off a
  /// plan while it has no calendar event.
  Future<Result<void>> cancelPlan({
    required String householdId,
    required String plannedHangoutId,
  });

  /// Records that [plannedHangoutId] now owns the calendar event
  /// [calendarEventId], and confirms it.
  ///
  /// Confirmed means exactly one thing in Kith: the plan is on the household's
  /// calendar. A plan that never made it there stays proposed, which is what
  /// makes the status worth storing rather than derivable.
  Future<Result<void>> linkCalendarEvent({
    required String householdId,
    required String plannedHangoutId,
    required String calendarEventId,
  });

  /// Forgets the calendar event [plannedHangoutId] owned, returning it to
  /// proposed.
  ///
  /// What the sync does when the event has been deleted from the calendar but
  /// the plan is worth keeping, and what unlinking a calendar leaves behind.
  Future<Result<void>> unlinkCalendarEvent({
    required String householdId,
    required String plannedHangoutId,
  });

  /// Moves [plannedHangoutId] to [plannedFor].
  ///
  /// The calendar half of a two-way sync: somebody dragging the event to
  /// another day in their calendar app is a change to the plan, and this is
  /// how it comes back. Kith itself offers no way to edit a plan's day.
  Future<Result<void>> reschedulePlan({
    required String householdId,
    required String plannedHangoutId,
    required DateTime plannedFor,
  });
}
