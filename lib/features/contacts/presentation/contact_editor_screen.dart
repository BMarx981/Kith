import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/centered_form_shell.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/features/contacts/application/contact_editor_controller.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/domain/contact_draft.dart';
import 'package:kith/features/contacts/domain/contact_field_validator.dart';
import 'package:kith/features/contacts/presentation/contact_failure_message.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/routing/app_router.dart';

/// Adds a contact, or edits one that already exists.
///
/// The same screen for both: [contactId] is null when adding. Everything the
/// form collects becomes a `ContactDraft`, which is the only shape the
/// repository accepts, so creating and editing cannot drift apart.
///
/// A save that lands closes the page. That is a pop rather than a typed
/// route, because the editor does not know or care what it was opened from.
@RoutePage()
class ContactEditorScreen extends ConsumerWidget {
  const ContactEditorScreen({
    @PathParam('contactId') this.contactId,
    super.key,
  });

  /// The contact being edited, or null when adding a new one.
  final String? contactId;

  /// Identifies the save button to tests.
  static const saveKey = Key('contactEditor.save');

  /// Identifies the archive-or-restore action to tests.
  static const archiveKey = Key('contactEditor.archive');

  /// Identifies the way through to this contact's hangouts to tests.
  static const historyKey = Key('contactEditor.history');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdId = ref.watch(currentHouseholdIdProvider);
    final types = householdId == null
        ? const AsyncLoading<List<RelationshipType>>()
        : ref.watch(relationshipTypesProvider(householdId));
    final contacts = householdId == null
        ? const AsyncLoading<List<Contact>>()
        : ref.watch(contactsProvider(householdId));

    return Scaffold(
      appBar: AppBar(
        title: Text(contactId == null ? 'Add a contact' : 'Edit contact'),
      ),
      body: switch ((types, contacts)) {
        (AsyncError(:final error), _) ||
        (_, AsyncError(:final error)) => _Message(_messageFor(error)),
        (AsyncData(value: final labels), AsyncData(value: final all)) =>
          _resolve(householdId!, labels, all),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  /// Picks the form to show, or the reason there is none.
  ///
  /// A household with no labels cannot file a contact anywhere, and a contact
  /// that was deleted while the editor was open has nothing left to edit.
  Widget _resolve(
    String householdId,
    List<RelationshipType> labels,
    List<Contact> all,
  ) {
    if (labels.isEmpty) {
      return const _Message(
        'Add a relationship label first, so contacts have somewhere to go.',
      );
    }
    final existing = contactId == null
        ? null
        : all.where((contact) => contact.id == contactId).firstOrNull;
    if (contactId != null && existing == null) {
      return const _Message('That contact is no longer here.');
    }
    return _ContactForm(
      householdId: householdId,
      labels: labels,
      existing: existing,
    );
  }

  static String _messageFor(Object error) => switch (error) {
    final Failure failure => contactFailureMessage(failure),
    _ => 'Something went wrong. Try again.',
  };
}

class _ContactForm extends ConsumerStatefulWidget {
  const _ContactForm({
    required this.householdId,
    required this.labels,
    required this.existing,
  });

  final String householdId;
  final List<RelationshipType> labels;
  final Contact? existing;

  @override
  ConsumerState<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends ConsumerState<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _guardianName;
  late final TextEditingController _guardianPhone;
  late final TextEditingController _notes;
  late final TextEditingController _tags;
  late final TextEditingController _customCadence;

  late String _relationshipTypeId;
  late ContactPriority _priority;

  /// Whether the cadence is being typed in days rather than picked.
  late bool _isCustomCadence;
  late Cadence _cadence;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _phone = TextEditingController(text: existing?.phone ?? '');
    _email = TextEditingController(text: existing?.email ?? '');
    _address = TextEditingController(text: existing?.address ?? '');
    _guardianName = TextEditingController(text: existing?.guardianName ?? '');
    _guardianPhone = TextEditingController(text: existing?.guardianPhone ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _tags = TextEditingController(
      text: ContactFieldValidator.formatTags(existing?.tags ?? const []),
    );
    _cadence = existing?.cadence ?? Cadence.monthly;
    _isCustomCadence = !_cadence.isPreset;
    _customCadence = TextEditingController(text: '${_cadence.days}');
    _priority = existing?.priority ?? ContactPriority.normal;
    // A contact whose label was deleted falls back to the first one rather
    // than leaving the dropdown on a value it cannot render.
    _relationshipTypeId =
        widget.labels
            .where((label) => label.id == existing?.relationshipTypeId)
            .firstOrNull
            ?.id ??
        widget.labels.first.id;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _phone,
      _email,
      _address,
      _guardianName,
      _guardianPhone,
      _notes,
      _tags,
      _customCadence,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final saved = await ref
        .read(contactEditorControllerProvider.notifier)
        .save(
          householdId: widget.householdId,
          contactId: widget.existing?.id,
          draft: ContactDraft(
            name: _name.text,
            relationshipTypeId: _relationshipTypeId,
            cadence: _isCustomCadence
                ? Cadence.parse(_customCadence.text).valueOrNull ?? _cadence
                : _cadence,
            priority: _priority,
            phone: _phone.text,
            email: _email.text,
            address: _address.text,
            guardianName: _guardianName.text,
            guardianPhone: _guardianPhone.text,
            notes: _notes.text,
            tags: ContactFieldValidator.parseTags(_tags.text),
          ),
        );
    if (saved && mounted) await Navigator.of(context).maybePop();
  }

  Future<void> _toggleArchived() async {
    final existing = widget.existing;
    if (existing == null) return;

    final done = await ref
        .read(contactEditorControllerProvider.notifier)
        .setArchived(
          householdId: widget.householdId,
          contactId: existing.id,
          isArchived: !existing.isArchived,
        );
    if (done && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(contactEditorControllerProvider);
    final existing = widget.existing;

    return CenteredFormBody(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              enabled: !state.isSubmitting,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: ContactFieldValidator.name,
            ),
            const SizedBox(height: KithSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _relationshipTypeId,
              decoration: const InputDecoration(labelText: 'Relationship'),
              items: [
                for (final label in widget.labels)
                  DropdownMenuItem(value: label.id, child: Text(label.name)),
              ],
              onChanged: state.isSubmitting
                  ? null
                  : (value) => setState(
                      () => _relationshipTypeId = value ?? _relationshipTypeId,
                    ),
            ),
            const SizedBox(height: KithSpacing.lg),
            const _SectionLabel('How often you want to see them'),
            const SizedBox(height: KithSpacing.xs),
            _CadenceChoice(
              cadence: _cadence,
              isCustom: _isCustomCadence,
              enabled: !state.isSubmitting,
              onChanged: ({required cadence, required isCustom}) =>
                  setState(() {
                    _cadence = cadence;
                    _isCustomCadence = isCustom;
                  }),
            ),
            if (_isCustomCadence) ...[
              const SizedBox(height: KithSpacing.sm),
              TextFormField(
                controller: _customCadence,
                enabled: !state.isSubmitting,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Every how many days',
                ),
                validator: ContactFieldValidator.customCadence,
              ),
            ],
            const SizedBox(height: KithSpacing.lg),
            const _SectionLabel('Priority'),
            const SizedBox(height: KithSpacing.xs),
            Row(
              spacing: KithSpacing.xs,
              children: [
                for (final priority in ContactPriority.values)
                  ChoiceChip(
                    label: Text(priority.label),
                    selected: _priority == priority,
                    onSelected: state.isSubmitting
                        ? null
                        : (_) => setState(() => _priority = priority),
                  ),
              ],
            ),
            const SizedBox(height: KithSpacing.lg),
            const _SectionLabel('How to reach them'),
            const SizedBox(height: KithSpacing.xs),
            _DetailField(
              controller: _phone,
              label: 'Phone',
              enabled: !state.isSubmitting,
              keyboardType: TextInputType.phone,
            ),
            _DetailField(
              controller: _email,
              label: 'Email',
              enabled: !state.isSubmitting,
              keyboardType: TextInputType.emailAddress,
            ),
            _DetailField(
              controller: _address,
              label: 'Address',
              enabled: !state.isSubmitting,
            ),
            const SizedBox(height: KithSpacing.lg),
            const _SectionLabel('Parent or guardian'),
            const SizedBox(height: KithSpacing.xxs),
            Text(
              "For a kid's friend, the person you actually text.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KithSpacing.xs),
            _DetailField(
              controller: _guardianName,
              label: 'Guardian name',
              enabled: !state.isSubmitting,
              textCapitalization: TextCapitalization.words,
            ),
            _DetailField(
              controller: _guardianPhone,
              label: 'Guardian phone',
              enabled: !state.isSubmitting,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: KithSpacing.lg),
            TextFormField(
              controller: _tags,
              enabled: !state.isSubmitting,
              decoration: const InputDecoration(
                labelText: 'Tags',
                helperText: 'Separate tags with commas.',
              ),
              validator: ContactFieldValidator.tags,
            ),
            const SizedBox(height: KithSpacing.md),
            TextFormField(
              controller: _notes,
              enabled: !state.isSubmitting,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Notes'),
              validator: ContactFieldValidator.notes,
            ),
            if (state.failure case final failure?) ...[
              const SizedBox(height: KithSpacing.md),
              Text(
                contactFailureMessage(failure),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: KithSpacing.lg),
            FilledButton(
              key: ContactEditorScreen.saveKey,
              onPressed: state.isSubmitting ? null : _save,
              child: state.isSubmitting
                  ? const SizedBox.square(
                      dimension: KithSpacing.md,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
            if (existing != null) ...[
              const SizedBox(height: KithSpacing.xs),
              TextButton.icon(
                key: ContactEditorScreen.historyKey,
                onPressed: state.isSubmitting
                    ? null
                    : () => context.router.push(
                        HangoutsRoute(contactId: existing.id),
                      ),
                icon: const Icon(KithIcons.history),
                label: const Text('See their hangouts'),
              ),
              TextButton(
                key: ContactEditorScreen.archiveKey,
                onPressed: state.isSubmitting ? null : _toggleArchived,
                child: Text(
                  existing.isArchived ? 'Restore contact' : 'Archive contact',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One optional single-line detail, spaced the way the others are.
class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: KithSpacing.md),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(labelText: label),
      validator: ContactFieldValidator.detail,
    ),
  );
}

/// The cadence presets, plus the escape hatch to type a number of days.
class _CadenceChoice extends StatelessWidget {
  const _CadenceChoice({
    required this.cadence,
    required this.isCustom,
    required this.enabled,
    required this.onChanged,
  });

  final Cadence cadence;
  final bool isCustom;
  final bool enabled;
  final void Function({required Cadence cadence, required bool isCustom})
  onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: KithSpacing.xs,
    runSpacing: KithSpacing.xs,
    children: [
      for (final preset in Cadence.presets)
        ChoiceChip(
          label: Text(preset.label),
          selected: !isCustom && cadence == preset,
          onSelected: enabled
              ? (_) => onChanged(cadence: preset, isCustom: false)
              : null,
        ),
      ChoiceChip(
        label: const Text('Custom'),
        selected: isCustom,
        onSelected: enabled
            ? (_) => onChanged(cadence: cadence, isCustom: true)
            : null,
      ),
    ],
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KithSpacing.lg),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
