import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/features/contacts/application/contact_import_controller.dart';
import 'package:kith/features/contacts/application/contact_import_state.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/domain/contact_import.dart';
import 'package:kith/features/contacts/presentation/contact_failure_message.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/l10n/l10n.dart';

/// Brings people over from the phone's address book.
///
/// One label and one cadence for the whole import rather than per person: an
/// address book row says nothing about how often you want to see somebody, and
/// asking twenty times is how an import stops being one. Both are editable
/// afterwards on the contact itself.
///
/// Nothing is ticked to begin with, and anybody the household already has is
/// shown greyed rather than hidden — somebody scrolling their address book
/// wants to know why their oldest friend is not on the list, and a silently
/// shortened list answers nothing.
@RoutePage()
class ContactImportScreen extends ConsumerWidget {
  const ContactImportScreen({super.key});

  /// Identifies the button that starts the address book read to tests.
  static const readKey = Key('contactImport.read');

  /// Identifies the select-all action to tests.
  static const selectAllKey = Key('contactImport.selectAll');

  /// Identifies the import action to tests.
  static const importKey = Key('contactImport.import');

  /// Identifies the label picker to tests.
  static const labelKey = Key('contactImport.label');

  /// Identifies the cadence picker to tests.
  static const cadenceKey = Key('contactImport.cadence');

  /// Identifies one candidate's row to tests.
  static Key rowKey(String deviceId) => Key('contactImport.row.$deviceId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdId = ref.watch(currentHouseholdIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.importContactsTitle)),
      body: householdId == null
          ? const Center(child: CircularProgressIndicator())
          : _ImportBody(householdId: householdId),
    );
  }
}

class _ImportBody extends ConsumerStatefulWidget {
  const _ImportBody({required this.householdId});

  final String householdId;

  @override
  ConsumerState<_ImportBody> createState() => _ImportBodyState();
}

class _ImportBodyState extends ConsumerState<_ImportBody> {
  String? _relationshipTypeId;
  Cadence _cadence = Cadence.monthly;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contactImportControllerProvider);
    final labels = ref.watch(relationshipTypesProvider(widget.householdId));
    // Watched, not read: the household's own contacts are what "already in
    // Kith" is measured against, and this screen is reachable without ever
    // having opened the list, so nothing else is holding that stream open.
    // Waiting for it here is what stops an import offering to add somebody
    // the household already has.
    final existing = ref.watch(contactsProvider(widget.householdId));

    return switch ((labels, existing)) {
      (AsyncError(:final error), _) ||
      (_, AsyncError(:final error)) => _Message(
        _messageFor(context.l10n, error),
      ),
      (AsyncData(value: final all), AsyncData()) when all.isEmpty =>
        _Message(context.l10n.importNeedsLabel),
      (AsyncData(value: final all), AsyncData()) => _body(state, all),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  Widget _body(ContactImportState state, List<RelationshipType> labels) =>
      switch (state.step) {
        ContactImportStep.idle ||
        ContactImportStep.reading => _Intro(state: state),
        ContactImportStep.permissionDenied => _Message(
          context.l10n.importPermissionDenied,
        ),
        ContactImportStep.done => _Message(
          context.l10n.importDone(state.importedCount),
        ),
        ContactImportStep.ready ||
        ContactImportStep.importing => _picker(state, labels),
      };

  Widget _picker(ContactImportState state, List<RelationshipType> labels) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final labelId = _resolvedLabelId(labels);

    if (state.candidates.isEmpty) {
      return _Message(l10n.importNobody);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KithSpacing.md,
            KithSpacing.md,
            KithSpacing.md,
            KithSpacing.xs,
          ),
          child: Row(
            spacing: KithSpacing.sm,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ContactImportScreen.labelKey,
                  initialValue: labelId,
                  // Both pickers share a row at phone width, where a long
                  // label ("Every 3 months", "Child's friend") is wider than
                  // half the screen. Expanding lets it ellipsize instead of
                  // overflowing the row.
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.importFileThemAs,
                  ),
                  items: [
                    for (final label in labels)
                      DropdownMenuItem(
                        value: label.id,
                        child: Text(
                          label.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: state.isBusy
                      ? null
                      : (picked) =>
                            setState(() => _relationshipTypeId = picked),
                ),
              ),
              Expanded(
                child: DropdownButtonFormField<int>(
                  key: ContactImportScreen.cadenceKey,
                  initialValue: _cadence.days,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.importSeeThem),
                  items: [
                    for (final preset in Cadence.presets)
                      DropdownMenuItem(
                        value: preset.days,
                        child: Text(
                          preset.label(l10n),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: state.isBusy
                      ? null
                      : (days) => setState(
                          () => _cadence = Cadence.fromDays(
                            days ?? _cadence.days,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KithSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.selected.isEmpty
                    ? l10n.importNobodyChosen
                    : l10n.importChosen(state.selected.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                key: ContactImportScreen.selectAllKey,
                onPressed: state.isBusy || state.importable.isEmpty
                    ? null
                    : ref
                          .read(contactImportControllerProvider.notifier)
                          .toggleAll,
                child: Text(
                  state.isEverySelected
                      ? l10n.importSelectNone
                      : l10n.importSelectAll,
                ),
              ),
            ],
          ),
        ),
        if (state.failure case final failure?)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: KithSpacing.md),
            child: Text(
              contactFailureMessage(l10n, failure),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: state.candidates.length,
            itemBuilder: (context, index) => _CandidateRow(
              candidate: state.candidates[index],
              isSelected: state.selected.contains(
                state.candidates[index].person.id,
              ),
              enabled: !state.isBusy,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(KithSpacing.md),
            child: FilledButton(
              key: ContactImportScreen.importKey,
              onPressed:
                  state.isBusy || state.selected.isEmpty || labelId == null
                  ? null
                  : () => unawaited(
                      ref
                          .read(contactImportControllerProvider.notifier)
                          .import(
                            householdId: widget.householdId,
                            relationshipTypeId: labelId,
                            cadence: _cadence,
                          ),
                    ),
              child: state.step == ContactImportStep.importing
                  ? const SizedBox.square(
                      dimension: KithSpacing.md,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.importButton(state.selected.length)),
            ),
          ),
        ),
      ],
    );
  }

  /// The chosen label, or the first one when nothing has been chosen or the
  /// chosen one has since been deleted.
  String? _resolvedLabelId(List<RelationshipType> labels) =>
      labels
          .where((label) => label.id == _relationshipTypeId)
          .firstOrNull
          ?.id ??
      labels.firstOrNull?.id;

  static String _messageFor(AppLocalizations l10n, Object error) =>
      switch (error) {
        final Failure failure => contactFailureMessage(l10n, failure),
        _ => l10n.errorGeneric,
      };
}

/// The step before the address book has been touched.
///
/// A screen of its own rather than reading straight away, because the system
/// permission prompt appears the moment the read is asked for, and a prompt
/// that arrives before the user has said what they came for is a prompt they
/// decline.
class _Intro extends ConsumerWidget {
  const _Intro({required this.state});

  final ContactImportState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final householdId = ref.watch(currentHouseholdIdProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KithSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              KithIcons.importContacts,
              size: KithSpacing.xxl,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: KithSpacing.md),
            Text(
              context.l10n.importIntro,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (state.failure case final failure?) ...[
              const SizedBox(height: KithSpacing.md),
              Text(
                contactFailureMessage(context.l10n, failure),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: KithSpacing.lg),
            FilledButton(
              key: ContactImportScreen.readKey,
              onPressed: state.isBusy || householdId == null
                  ? null
                  : () => unawaited(
                      ref
                          .read(contactImportControllerProvider.notifier)
                          .load(householdId),
                    ),
              child: state.step == ContactImportStep.reading
                  ? const SizedBox.square(
                      dimension: KithSpacing.md,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.l10n.importChooseButton),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateRow extends ConsumerWidget {
  const _CandidateRow({
    required this.candidate,
    required this.isSelected,
    required this.enabled,
  });

  final ImportCandidate candidate;
  final bool isSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = candidate.person;
    final detail = [
      person.phone,
      person.email,
    ].whereType<String>().firstOrNull;

    return CheckboxListTile(
      key: ContactImportScreen.rowKey(person.id),
      value: candidate.isAlreadyHere || isSelected,
      title: Text(person.name),
      subtitle: Text(
        candidate.isAlreadyHere
            ? context.l10n.importAlreadyHere
            : detail ?? context.l10n.importNoDetails,
      ),
      // Somebody already here is shown ticked and inert: on the list to
      // explain their absence from it, not to be imported twice.
      onChanged: !enabled || candidate.isAlreadyHere
          ? null
          : (_) => ref
                .read(contactImportControllerProvider.notifier)
                .toggle(person.id),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(KithSpacing.xl),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ),
  );
}
