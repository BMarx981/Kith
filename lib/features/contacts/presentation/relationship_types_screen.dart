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
      appBar: AppBar(title: const Text('Relationship labels')),
      floatingActionButton: householdId == null
          ? null
          : FloatingActionButton(
              key: addKey,
              onPressed: () => _add(context, ref, householdId),
              tooltip: 'Add a label',
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
    final name = await _promptForName(context, title: 'Add a label');
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
        decoration: const InputDecoration(labelText: 'Label'),
        validator: ContactFieldValidator.labelName,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: RelationshipTypesScreen.confirmKey,
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          Navigator.of(context).pop(_controller.text);
        },
        child: const Text('Save'),
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
      AsyncError(:final error) => _Message(_messageFor(error)),
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.failure case final failure?)
            _Message(contactFailureMessage(failure)),
          Expanded(
            child: value.isEmpty
                ? const _Message(
                    'No labels yet. Add one, and contacts have somewhere '
                    'to go.',
                  )
                : _TypeList(householdId: householdId, types: value),
          ),
        ],
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  static String _messageFor(Object error) => switch (error) {
    final Failure failure => contactFailureMessage(failure),
    _ => 'Something went wrong. Try again.',
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
                tooltip: 'Rename ${type.name}',
              ),
              IconButton(
                onPressed: () => _delete(context, ref, type),
                icon: const Icon(KithIcons.delete),
                tooltip: 'Delete ${type.name}',
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
      title: 'Rename label',
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
        const SnackBar(
          content: Text('Keep at least one label for contacts to use.'),
        ),
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
    title: Text('Delete "${widget.doomed.name}"'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Move everyone filed under it to:'),
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
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: RelationshipTypesScreen.confirmKey,
        onPressed: () => Navigator.of(context).pop(_reassignToId),
        child: const Text('Delete'),
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
