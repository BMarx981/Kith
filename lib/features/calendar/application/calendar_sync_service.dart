import 'package:flutter/foundation.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/repositories/planned_hangout_repository.dart';
import 'package:kith/data/services/calendar_sink.dart';

/// What one reconciliation pass did.
///
/// Counts rather than a list of plans: nothing on screen names the plans that
/// moved, and the numbers are what the tests assert on. [failure] holds the
/// first thing that went wrong, if anything did; a pass keeps going after one
/// plan fails, because one unreachable event should not strand the rest.
@immutable
class CalendarSyncReport {
  const CalendarSyncReport({
    this.checked = 0,
    this.rescheduled = 0,
    this.dropped = 0,
    this.failure,
  });

  /// Plans that had an event to compare against.
  final int checked;

  /// Plans moved to the day their event now sits on.
  final int rescheduled;

  /// Plans dropped because their event had been deleted.
  final int dropped;

  /// The first failure met, or null if the pass was clean.
  final Failure? failure;

  /// Whether anything changed on this side.
  bool get changedAnything => rescheduled > 0 || dropped > 0;

  @override
  String toString() =>
      'CalendarSyncReport(checked: $checked, rescheduled: $rescheduled, '
      'dropped: $dropped, failure: $failure)';
}

/// Keeps a household's plans and their calendar events saying the same thing.
///
/// Two directions, neither of them a webhook. Kith to the calendar is
/// immediate: confirming a plan writes an event, cancelling one removes it.
/// The calendar back to Kith is a poll — [reconcile] runs when the app opens —
/// because a household edits an event in their own calendar app and Kith only
/// finds out by asking.
///
/// Plain Dart, holding a sink and a repository: the ordering rules here are
/// the part worth testing, and they are easier to test without a widget tree
/// around them.
class CalendarSyncService {
  const CalendarSyncService({required this._sink, required this._plans});

  final CalendarSink _sink;
  final PlannedHangoutRepository _plans;

  /// Puts [plan] on [calendarId] as [title], and confirms it.
  ///
  /// The event is written first and recorded second, so a failure leaves a
  /// plan that is simply not on the calendar rather than a plan pointing at an
  /// event that was never created. The reverse order could strand a plan
  /// holding the id of nothing.
  Future<Result<CalendarEvent>> addPlanToCalendar({
    required String householdId,
    required String calendarId,
    required PlannedHangout plan,
    required String title,
  }) async {
    final created = await _sink.createEvent(
      calendarId: calendarId,
      title: title,
      day: plan.plannedFor,
      note: plan.note,
    );
    if (created case Err(:final failure)) return Err(failure);

    final event = created.valueOrNull!;
    final linked = await _plans.linkCalendarEvent(
      householdId: householdId,
      plannedHangoutId: plan.id,
      calendarEventId: event.id,
    );
    if (linked case Err(:final failure)) {
      // The event exists but nothing in Kith owns it. Taking it back off is
      // the honest end: an event nobody can cancel from the app is worse than
      // no event at all.
      await _sink.deleteEvent(calendarId: calendarId, eventId: event.id);
      return Err(failure);
    }
    return Ok(event);
  }

  /// Takes [plan]'s event off [calendarId], if it has one.
  ///
  /// A plan that never made it onto the calendar is nothing to do, and
  /// deleting an event that has already gone counts as done — both are the
  /// state the caller was asking for.
  Future<Result<void>> removePlanFromCalendar({
    required String calendarId,
    required PlannedHangout plan,
  }) async {
    final eventId = plan.calendarEventId;
    if (eventId == null) return const Ok(null);
    return _sink.deleteEvent(calendarId: calendarId, eventId: eventId);
  }

  /// Brings [plans] into line with what [calendarId] now says.
  ///
  /// Only plans that are on the calendar and still have a day ahead of them
  /// are asked about: a spent plan is about to stop counting anyway, and
  /// polling it would spend a round trip to learn nothing.
  ///
  /// An event that has been deleted takes its plan with it — cancelling from
  /// the calendar is the same intent as cancelling in the app — and an event
  /// that has been moved moves the plan to match.
  Future<CalendarSyncReport> reconcile({
    required String householdId,
    required String calendarId,
    required List<PlannedHangout> plans,
    required DateTime now,
  }) async {
    var checked = 0;
    var rescheduled = 0;
    var dropped = 0;
    Failure? firstFailure;

    for (final plan in plans) {
      final eventId = plan.calendarEventId;
      if (eventId == null || !plan.isActiveOn(now)) continue;

      checked++;
      final fetched = await _sink.fetchEvent(
        calendarId: calendarId,
        eventId: eventId,
      );
      switch (fetched) {
        case Err(:final failure):
          firstFailure ??= failure;
        case Ok(value: null):
          final cancelled = await _plans.cancelPlan(
            householdId: householdId,
            plannedHangoutId: plan.id,
          );
          if (cancelled case Err(:final failure)) {
            firstFailure ??= failure;
          } else {
            dropped++;
          }
        case Ok(value: final event?):
          if (event.day == plan.plannedFor) continue;
          final moved = await _plans.reschedulePlan(
            householdId: householdId,
            plannedHangoutId: plan.id,
            plannedFor: event.day,
          );
          if (moved case Err(:final failure)) {
            firstFailure ??= failure;
          } else {
            rescheduled++;
          }
      }
    }

    return CalendarSyncReport(
      checked: checked,
      rescheduled: rescheduled,
      dropped: dropped,
      failure: firstFailure,
    );
  }
}
