import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/calendar/application/calendar_providers.dart';
import 'package:kith/features/contacts/application/save_state.dart';
import 'package:kith/features/suggestions/application/plan_outcome.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';
import 'package:kith/features/suggestions/domain/snooze_horizon.dart';

/// Drives the three things a suggestion card can do.
///
/// Owns the submission state and the failure to show; it never navigates and
/// never shows a snackbar. Each write hands the plan it made back to the
/// screen, which is what lets the card offer to undo it.
class SuggestionActionController extends Notifier<SaveState> {
  @override
  SaveState build() {
    // Watched, not read on demand: the identity arrives over a stream, and a
    // card tapped before anything had subscribed would find nobody signed in
    // and refuse a plan the user is perfectly entitled to make. Watching here
    // keeps it live for as long as a card is on screen, and resets the state
    // if the signed-in member changes underneath it.
    ref.watch(currentUserProvider);
    return const SaveState();
  }

  /// Records an intent to see [contactId] on [plannedFor], and puts it on the
  /// household's calendar when one is linked.
  ///
  /// [title] is what the event is called, which is the contact's name: an
  /// event reading "Marcus" in a shared calendar says everything the household
  /// needs, and the frame shows it as-is.
  ///
  /// Returns what came of it, or null if the plan itself was refused. A plan
  /// that was stored but could not be published still comes back: the
  /// arrangement stands either way, and the card says which happened.
  Future<PlanOutcome?> plan({
    required String householdId,
    required String contactId,
    required String title,
    required DateTime plannedFor,
  }) async {
    final stored = await _submit(
      (createdBy) => ref.read(plannedHangoutRepositoryProvider).planHangout(
        householdId: householdId,
        contactIds: [contactId],
        plannedFor: plannedFor,
        createdBy: createdBy,
      ),
    );
    if (stored == null) return null;

    final calendarId = ref.read(householdCalendarIdProvider(householdId));
    if (calendarId == null) return PlanOutcome(plan: stored);

    final published = await ref
        .read(calendarSyncServiceProvider)
        .addPlanToCalendar(
          householdId: householdId,
          calendarId: calendarId,
          plan: stored,
          title: title,
        );
    return switch (published) {
      Ok() => PlanOutcome(plan: stored, isOnCalendar: true),
      Err(:final failure) => PlanOutcome(
        plan: stored,
        calendarFailure: failure,
      ),
    };
  }

  /// Stops suggesting [contact] for as long as [horizon] says.
  ///
  /// The contact rather than their id, because the longer horizon is a
  /// multiple of their own cadence. "Now" comes from the clock provider, so a
  /// test can pin the day the snooze runs to.
  Future<PlannedHangout?> snooze({
    required String householdId,
    required Contact contact,
    required SnoozeHorizon horizon,
  }) => _submit(
    (createdBy) => ref.read(plannedHangoutRepositoryProvider).snoozeContacts(
      householdId: householdId,
      contactIds: [contact.id],
      until: horizon.from(
        ref.read(clockProvider).now(),
        cadence: contact.cadence,
      ),
      createdBy: createdBy,
    ),
  );

  /// Drops [plan], which is how an undo is spelled.
  ///
  /// Takes the plan rather than its id because a plan on the calendar owns an
  /// event, and dropping one without the other would leave the household an
  /// arrangement nobody in the app can cancel.
  ///
  /// The event goes first and the plan goes second. Returns whether the plan
  /// was cancelled, which is what was asked for: an event that could not be
  /// removed leaves a failure in the state and a stray entry the household can
  /// delete in their own calendar, rather than a plan that will not go away.
  ///
  /// Takes no author: removing a plan is not an authored act, and either
  /// partner may undo the other's.
  Future<bool> cancel({
    required String householdId,
    required PlannedHangout plan,
  }) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, clearFailure: true);

    Failure? calendarFailure;
    final calendarId = ref.read(householdCalendarIdProvider(householdId));
    if (calendarId != null) {
      final removed = await ref
          .read(calendarSyncServiceProvider)
          .removePlanFromCalendar(calendarId: calendarId, plan: plan);
      calendarFailure = removed.failureOrNull;
    }

    final result = await ref
        .read(plannedHangoutRepositoryProvider)
        .cancelPlan(householdId: householdId, plannedHangoutId: plan.id);
    if (result case Err(:final failure)) {
      state = state.copyWith(isSubmitting: false, failure: failure);
      return false;
    }
    state = SaveState(failure: calendarFailure);
    return true;
  }

  /// Runs [write] as the signed-in member, holding the card inert until it
  /// settles so a double tap cannot make the same plan twice.
  Future<PlannedHangout?> _submit(
    Future<Result<PlannedHangout>> Function(String createdBy) write,
  ) async {
    if (state.isSubmitting) return null;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(
        failure: const AuthFailure(
          AuthFailureReason.unknown,
          'No signed-in user to credit the plan to.',
        ),
      );
      return null;
    }
    state = state.copyWith(isSubmitting: true, clearFailure: true);
    final result = await write(user.id);
    if (result case Err(:final failure)) {
      state = state.copyWith(isSubmitting: false, failure: failure);
      return null;
    }
    state = const SaveState();
    return result.valueOrNull;
  }
}

/// State of the suggestion card actions.
final suggestionActionControllerProvider =
    NotifierProvider<SuggestionActionController, SaveState>(
      SuggestionActionController.new,
    );
