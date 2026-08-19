import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/services/device_contact_directory.dart';
import 'package:kith/features/contacts/application/contact_import_state.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/domain/contact_import.dart';

/// The app's [DeviceContactDirectory].
///
/// Deliberately has no default: the composition root overrides it with the
/// plugin-backed implementation and tests override it with a fake, so reading
/// it unoverridden throws rather than quietly talking to nothing.
final deviceContactDirectoryProvider = Provider<DeviceContactDirectory>((ref) {
  throw UnimplementedError(
    'deviceContactDirectoryProvider must be overridden with a '
    'DeviceContactDirectory implementation before it is read.',
  );
});

/// Drives the import-from-the-address-book flow.
///
/// Owns the permission ask, the read, what is ticked and the write. It never
/// navigates: the screen watches the step and decides what to show, so a
/// refused import leaves the list up with the ticks still on it.
class ContactImportController extends Notifier<ContactImportState> {
  @override
  ContactImportState build() => const ContactImportState();

  /// Asks for permission if it is needed, reads the address book, and marks
  /// everybody the household already has.
  ///
  /// Nothing is ticked to begin with. An address book runs to hundreds of
  /// people, most of whom are a dentist rather than a friend, so importing
  /// starts from nobody and the household chooses.
  Future<void> load(String householdId) async {
    if (state.isBusy) return;
    state = const ContactImportState(step: ContactImportStep.reading);

    final directory = ref.read(deviceContactDirectoryProvider);
    final permitted = await directory.requestPermission();
    switch (permitted) {
      case Err(:final failure):
        state = ContactImportState(failure: failure);
        return;
      case Ok(value: false):
        state = const ContactImportState(
          step: ContactImportStep.permissionDenied,
        );
        return;
      case Ok():
        break;
    }

    final read = await directory.readContacts();
    if (read case Err(:final failure)) {
      state = ContactImportState(failure: failure);
      return;
    }

    state = ContactImportState(
      step: ContactImportStep.ready,
      candidates: importCandidates(
        device: read.valueOrNull ?? const [],
        existing: ref.read(contactsProvider(householdId)).value ?? const [],
      ),
    );
  }

  /// Ticks or unticks the candidate with device id [id].
  ///
  /// Somebody the household already has cannot be ticked at all: they are on
  /// the list to explain their absence from it, not to be imported twice.
  void toggle(String id) {
    if (state.step != ContactImportStep.ready) return;
    if (!state.importable.any((candidate) => candidate.person.id == id)) return;

    final selected = {...state.selected};
    if (!selected.remove(id)) selected.add(id);
    state = state.copyWith(selected: selected);
  }

  /// Ticks every importable candidate, or unticks them all if they already
  /// are.
  void toggleAll() {
    if (state.step != ContactImportStep.ready) return;
    state = state.copyWith(
      selected: state.isEverySelected
          ? const {}
          : {for (final candidate in state.importable) candidate.person.id},
    );
  }

  /// Writes the ticked people into [householdId], filed under
  /// [relationshipTypeId] at [cadence].
  ///
  /// One write per contact rather than a batch, because the repository's
  /// create is what validates a draft and mints an id, and a batch that
  /// bypassed it would be a second way to make a contact. The count that
  /// lands is reported either way: an import that fails on the fourteenth
  /// person has still added thirteen, and saying so is what stops the
  /// household from running it again and getting duplicates.
  Future<void> import({
    required String householdId,
    required String relationshipTypeId,
    required Cadence cadence,
  }) async {
    if (state.step != ContactImportStep.ready || state.selected.isEmpty) return;

    final chosen = [
      for (final candidate in state.importable)
        if (state.selected.contains(candidate.person.id)) candidate.person,
    ];
    state = state.copyWith(
      step: ContactImportStep.importing,
      clearFailure: true,
    );

    final repository = ref.read(contactRepositoryProvider);
    var written = 0;
    Failure? stopped;
    for (final person in chosen) {
      final created = await repository.createContact(
        householdId: householdId,
        draft: draftFor(
          person,
          relationshipTypeId: relationshipTypeId,
          cadence: cadence,
        ),
      );
      if (created case Err(:final failure)) {
        stopped = failure;
        break;
      }
      written++;
    }

    state = state.copyWith(
      step: stopped == null
          ? ContactImportStep.done
          : ContactImportStep.ready,
      importedCount: written,
      failure: stopped,
      clearFailure: stopped == null,
    );
  }
}

/// State of the import-from-the-address-book flow.
final contactImportControllerProvider =
    NotifierProvider<ContactImportController, ContactImportState>(
      ContactImportController.new,
    );
