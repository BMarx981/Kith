import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/application/save_state.dart';
import 'package:kith/features/contacts/domain/contact_draft.dart';

/// Drives the add-or-edit contact form.
///
/// Owns the submission state and the failure to show; it never navigates. The
/// screen watches the returned bool to decide whether to close, so a refused
/// save leaves the form up with what was typed still in it.
class ContactEditorController extends Notifier<SaveState> {
  @override
  SaveState build() => const SaveState();

  /// Stores [draft] in [householdId].
  ///
  /// Creates a contact when [contactId] is null and edits that one when it is
  /// not. Returns whether the write succeeded.
  Future<bool> save({
    required String householdId,
    required ContactDraft draft,
    String? contactId,
  }) => _submit(() {
    final repository = ref.read(contactRepositoryProvider);
    return contactId == null
        ? repository.createContact(householdId: householdId, draft: draft)
        : repository.updateContact(
            householdId: householdId,
            contactId: contactId,
            draft: draft,
          );
  });

  /// Archives or restores [contactId], returning whether it worked.
  Future<bool> setArchived({
    required String householdId,
    required String contactId,
    required bool isArchived,
  }) => _submit(
    () => ref
        .read(contactRepositoryProvider)
        .setArchived(
          householdId: householdId,
          contactId: contactId,
          isArchived: isArchived,
        ),
  );

  /// Runs [attempt], holding the form inert until it settles so a double tap
  /// cannot store two copies of the same contact.
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

/// State of the add-or-edit contact form.
final contactEditorControllerProvider =
    NotifierProvider<ContactEditorController, SaveState>(
      ContactEditorController.new,
    );
