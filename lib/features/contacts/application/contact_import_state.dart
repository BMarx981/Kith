import 'package:flutter/foundation.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/contacts/domain/contact_import.dart';

/// How far the import has got.
enum ContactImportStep {
  /// Nothing asked for yet: the screen is offering to look at the address
  /// book, and has not.
  idle,

  /// The permission prompt or the address book read is in flight.
  reading,

  /// The address book has been read and the list is on screen.
  ready,

  /// The chosen people are being written to the household.
  importing,

  /// They were written. The screen says how many, and offers no way back to
  /// the list: importing the same people twice is the mistake this step
  /// exists to prevent.
  done,

  /// The user declined the system prompt. Not a failure; a choice, and the
  /// screen says where to change their mind.
  permissionDenied,
}

/// What the contact import screen knows.
@immutable
class ContactImportState {
  const ContactImportState({
    this.step = ContactImportStep.idle,
    this.candidates = const [],
    this.selected = const {},
    this.importedCount = 0,
    this.failure,
  });

  /// Where the flow has got to.
  final ContactImportStep step;

  /// Everybody the address book offered, sorted, each marked with whether the
  /// household already has them.
  final List<ImportCandidate> candidates;

  /// Device ids of the people ticked for import.
  ///
  /// Ids rather than the rows themselves, so ticking somebody cannot quietly
  /// hold a stale copy of a row the list has since re-read.
  final Set<String> selected;

  /// How many contacts the last import wrote.
  final int importedCount;

  /// Why the last step could not finish, or null if none failed.
  final Failure? failure;

  /// Whether the screen should be inert.
  bool get isBusy =>
      step == ContactImportStep.reading || step == ContactImportStep.importing;

  /// The candidates that can actually be ticked: the ones not already here.
  List<ImportCandidate> get importable => [
    for (final candidate in candidates)
      if (!candidate.isAlreadyHere) candidate,
  ];

  /// Whether every importable candidate is ticked. False when there are none,
  /// so "select all" is never offered over an empty list.
  bool get isEverySelected =>
      importable.isNotEmpty && selected.length == importable.length;

  /// Returns a copy with the given fields replaced.
  ///
  /// The `clear` flag exists because passing null to a named parameter cannot
  /// be told apart from omitting it.
  ContactImportState copyWith({
    ContactImportStep? step,
    List<ImportCandidate>? candidates,
    Set<String>? selected,
    int? importedCount,
    Failure? failure,
    bool clearFailure = false,
  }) => ContactImportState(
    step: step ?? this.step,
    candidates: candidates ?? this.candidates,
    selected: selected ?? this.selected,
    importedCount: importedCount ?? this.importedCount,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactImportState &&
          other.step == step &&
          listEquals(other.candidates, candidates) &&
          setEquals(other.selected, selected) &&
          other.importedCount == importedCount &&
          other.failure == failure;

  @override
  int get hashCode => Object.hash(
    step,
    Object.hashAll(candidates),
    Object.hashAllUnordered(selected),
    importedCount,
    failure,
  );

  @override
  String toString() =>
      'ContactImportState(step: ${step.name}, '
      'candidates: ${candidates.length}, selected: ${selected.length}, '
      'imported: $importedCount, failure: $failure)';
}
