import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/application/relationship_type_controller.dart';
import 'package:kith/features/contacts/domain/contact_field_validator.dart';
import 'package:kith/features/contacts/presentation/contact_failure_message.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/l10n/l10n.dart';
import 'package:kith/l10n/validation_messages.dart';

/// The household's relationship labels: add, rename, reorder, delete.
///
/// Deleting always moves the contacts filed under a label somewhere else, so
/// the dialog asks where before it will let the label go.
@RoutePage()
class RelationshipTypesScreen extends ConsumerWidget {
  const RelationshipTypesScreen({super.key});

  /// Identifies the add-a-label button to tests.
  static const addKey = Key('relationshipTypes.add');

  /// Identifies the name field inside the add and rename dialogs to tests.
  static const nameFieldKey = Key('relationshipTypes.name');

  /// Identifies the confirm button inside a dialog to tests.
  static const confirmKey = Key('relationshipTypes.confirm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdId = ref.watch(currentHouseholdIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.labelsTitle)),
      floatingActionButton: householdId == null
          ? null
          : FloatingActionButton(
              key: addKey,
              onPressed: () => _add(context, ref, householdId),
              tooltip: context.l10n.addLabelTooltip,
              child: const Icon(KithIcons.add),
            ),
      body: householdId == null
          ? const Center(child: CircularProgressIndicator())
          : _TypesBody(householdId: householdId),
    );
  }

  static Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    String householdId,
  ) async {
    final name = await _promptForName(
      context,
      title: context.l10n.addLabelTooltip,
    );
    if (name == null) return;
    await ref
        .read(relationshipTypeControllerProvider.notifier)
        .add(householdId: householdId, name: name);
  }
}

/// Asks for a label name, returning null if the dialog was dismissed.
Future<String?> _promptForName(
  BuildContext context, {
  required String title,
  String initial = '',
}) => showDialog<String>(
  context: context,
  builder: (context) => _NameDialog(title: title, initial: initial),
);

/// The add-and-rename dialog.
///
/// Stateful so that it owns its text controller: a controller disposed when
/// the future completes would still be attached to the field through the
/// dialog's exit animation.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Form(
      key: _formKey,
      child: TextFormField(
        key: RelationshipTypesScreen.nameFieldKey,
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: context.l10n.labelFieldLabel),
        validator: (input) => validationMessage(
          context.l10n,
          ContactFieldValidator.labelName(input),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancelButton),
      ),
      FilledButton(
        key: RelationshipTypesScreen.confirmKey,
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          Navigator.of(context).pop(_controller.text);
        },
        child: Text(context.l10n.saveButton),
      ),
    ],
  );
}

class _TypesBody extends ConsumerWidget {
  const _TypesBody({required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ref.watch(relationshipTypesProvider(householdId));
    final state = ref.watch(relationshipTypeControllerProvider);

    return switch (types) {
      AsyncError(:final error) => _Message(_messageFor(context.l10n, error)),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.failure case final failure?)
            _Message(contactFailureMessage(context.l10n, failure)),
          Expanded(
            child: value.isEmpty
                ? _Message(context.l10n.labelsEmpty)
                : _TypeList(householdId: householdId, types: value),
          ),
        ],
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  static String _messageFor(AppLocalizations l10n, Object error) =>
      switch (error) {
        final Failure failure => contactFailureMessage(l10n, failure),
        _ => l10n.errorGeneric,
      };
}

class _TypeList extends ConsumerWidget {
  const _TypeList({required this.householdId, required this.types});

  final String householdId;
  final List<RelationshipType> types;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: KithSpacing.xxl),
      buildDefaultDragHandles: false,
      itemCount: types.length,
      // onReorderItem rather than onReorder: it reports the index the row
      // lands on once it has been lifted out, which is the index this list
      // wants. onReorder reports it as if the row were still in place.
      onReorderItem: (oldIndex, newIndex) {
        final ordered = List.of(types);
        ordered.insert(newIndex, ordered.removeAt(oldIndex));
        unawaited(
          ref
              .read(relationshipTypeControllerProvider.notifier)
              .reorder(
                householdId: householdId,
                orderedIds: [for (final type in ordered) type.id],
              ),
        );
      },
      itemBuilder: (context, index) {
        final type = types[index];
        return ListTile(
          key: ValueKey(type.id),
          leading: ReorderableDragStartListener(
            index: index,
            child: Icon(
              KithIcons.reorder,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          title: Text(type.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _rename(context, ref, type),
                icon: const Icon(KithIcons.edit),
                tooltip: context.l10n.renameLabelTooltip(type.name),
              ),
              IconButton(
                onPressed: () => _delete(context, ref, type),
                icon: const Icon(KithIcons.delete),
                tooltip: context.l10n.deleteLabelTooltip(type.name),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    RelationshipType type,
  ) async {
    final name = await _promptForName(
      context,
      title: context.l10n.renameLabelTitle,
      initial: type.name,
    );
    if (name == null) return;
    await ref
        .read(relationshipTypeControllerProvider.notifier)
        .rename(householdId: householdId, typeId: type.id, name: name);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    RelationshipType type,
  ) async {
    final others = [
      for (final other in types)
        if (other.id != type.id) other,
    ];
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.keepOneLabel)),
      );
      return;
    }

    final reassignToId = await showDialog<String>(
      context: context,
      builder: (context) => _ReassignDialog(doomed: type, others: others),
    );
    if (reassignToId == null) return;
    await ref
        .read(relationshipTypeControllerProvider.notifier)
        .delete(
          householdId: householdId,
          typeId: type.id,
          reassignToId: reassignToId,
        );
  }
}

/// Asks where the contacts filed under a doomed label should go.
class _ReassignDialog extends StatefulWidget {
  const _ReassignDialog({required this.doomed, required this.others});

  final RelationshipType doomed;
  final List<RelationshipType> others;

  @override
  State<_ReassignDialog> createState() => _ReassignDialogState();
}

class _ReassignDialogState extends State<_ReassignDialog> {
  late String _reassignToId = widget.others.first.id;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.deleteLabelTitle(widget.doomed.name)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.reassignPrompt),
        const SizedBox(height: KithSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _reassignToId,
          items: [
            for (final other in widget.others)
              DropdownMenuItem(value: other.id, child: Text(other.name)),
          ],
          onChanged: (value) =>
              setState(() => _reassignToId = value ?? _reassignToId),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancelButton),
      ),
      FilledButton(
        key: RelationshipTypesScreen.confirmKey,
        onPressed: () => Navigator.of(context).pop(_reassignToId),
        child: Text(context.l10n.deleteButton),
      ),
    ],
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(KithSpacing.lg),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
