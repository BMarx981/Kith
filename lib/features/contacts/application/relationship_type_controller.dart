import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/application/save_state.dart';

/// Drives the relationship type manager.
///
/// Every action is a single write that either lands or comes back as a
/// failure to show above the list; the screen stays put either way, because
/// the list it renders is a stream that updates itself.
class RelationshipTypeController extends Notifier<SaveState> {
  @override
  SaveState build() => const SaveState();

  /// Adds a label called [name] to the end of the household's list.
  Future<bool> add({required String householdId, required String name}) =>
      _submit(
        () => ref
            .read(relationshipTypeRepositoryProvider)
            .createRelationshipType(householdId: householdId, name: name),
      );

  /// Renames the label [typeId].
  Future<bool> rename({
    required String householdId,
    required String typeId,
    required String name,
  }) => _submit(
    () => ref
        .read(relationshipTypeRepositoryProvider)
        .renameRelationshipType(
          householdId: householdId,
          typeId: typeId,
          name: name,
        ),
  );

  /// Rearranges the labels to match [orderedIds], first to last.
  Future<bool> reorder({
    required String householdId,
    required List<String> orderedIds,
  }) => _submit(
    () => ref
        .read(relationshipTypeRepositoryProvider)
        .reorderRelationshipTypes(
          householdId: householdId,
          orderedIds: orderedIds,
        ),
  );

  /// Deletes [typeId], moving every contact filed under it to
  /// [reassignToId].
  Future<bool> delete({
    required String householdId,
    required String typeId,
    required String reassignToId,
  }) => _submit(
    () => ref
        .read(relationshipTypeRepositoryProvider)
        .deleteRelationshipType(
          householdId: householdId,
          typeId: typeId,
          reassignToId: reassignToId,
        ),
  );

  /// Drops the failure on show, for when the screen has acknowledged it.
  void clearFailure() => state = state.copyWith(clearFailure: true);

  /// Runs [attempt], holding the manager inert until it settles.
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

/// State of the relationship type manager.
final relationshipTypeControllerProvider =
    NotifierProvider<RelationshipTypeController, SaveState>(
      RelationshipTypeController.new,
    );
