import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/contacts/application/save_state.dart';
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

  /// Records an intent to see [contactId] on [plannedFor].
  ///
  /// Returns the stored plan, or null if the write was refused.
  Future<PlannedHangout?> plan({
    required String householdId,
    required String contactId,
    required DateTime plannedFor,
  }) => _submit(
    (createdBy) => ref.read(plannedHangoutRepositoryProvider).planHangout(
      householdId: householdId,
      contactIds: [contactId],
      plannedFor: plannedFor,
      createdBy: createdBy,
    ),
  );

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

  /// Drops the plan [plannedHangoutId], which is how an undo is spelled.
  ///
  /// Returns whether it worked. Takes no author: removing a plan is not an
  /// authored act, and either partner may undo the other's.
  Future<bool> cancel({
    required String householdId,
    required String plannedHangoutId,
  }) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, clearFailure: true);
    final result = await ref
        .read(plannedHangoutRepositoryProvider)
        .cancelPlan(
          householdId: householdId,
          plannedHangoutId: plannedHangoutId,
        );
    if (result case Err(:final failure)) {
      state = state.copyWith(isSubmitting: false, failure: failure);
      return false;
    }
    state = const SaveState();
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
