import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/contacts/application/save_state.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/hangouts/domain/hangout_draft.dart';

/// Drives the quick-log form.
///
/// Owns the submission state and the failure to show; it never navigates. The
/// screen watches the returned bool to decide whether to close, so a refused
/// log leaves the form up with the selection still in it.
class HangoutEditorController extends Notifier<SaveState> {
  @override
  SaveState build() => const SaveState();

  /// Stores [draft] in [householdId].
  ///
  /// Logs a new hangout when [hangoutId] is null and edits that one when it
  /// is not. Returns whether the write succeeded.
  Future<bool> save({
    required String householdId,
    required HangoutDraft draft,
    String? hangoutId,
  }) => _submit(() {
    final repository = ref.read(hangoutRepositoryProvider);
    if (hangoutId != null) {
      return repository.updateHangout(
        householdId: householdId,
        hangoutId: hangoutId,
        draft: draft,
      );
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return Future.value(
        const Err<void>(
          AuthFailure(
            AuthFailureReason.unknown,
            'No signed-in user to credit the hangout to.',
          ),
        ),
      );
    }
    return repository.logHangout(
      householdId: householdId,
      draft: draft,
      createdBy: user.id,
    );
  });

  /// Removes [hangoutId], returning whether it worked.
  Future<bool> delete({
    required String householdId,
    required String hangoutId,
  }) => _submit(
    () => ref
        .read(hangoutRepositoryProvider)
        .deleteHangout(householdId: householdId, hangoutId: hangoutId),
  );

  /// Runs [attempt], holding the form inert until it settles so a double tap
  /// cannot log the same evening twice.
  Future<bool> _submit(Future<Result<Object?>> Function() attempt) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, clearFailure: true);
    final result = await attempt();
    if (result case Err(:final failure)) {
      state = state.copyWith(isSubmitting: false, failure: failure);
      return false;
    }
    state = const SaveState();
    return true;
  }
}

/// State of the quick-log form.
final hangoutEditorControllerProvider =
    NotifierProvider<HangoutEditorController, SaveState>(
      HangoutEditorController.new,
    );
