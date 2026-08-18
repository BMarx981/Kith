import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/centered_form_shell.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/time/calendar_day.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/data/models/member.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/contact_view.dart';
import 'package:kith/features/hangouts/application/hangout_editor_controller.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/hangouts/domain/day_label.dart';
import 'package:kith/features/hangouts/domain/hangout_draft.dart';
import 'package:kith/features/hangouts/presentation/hangout_failure_message.dart';
import 'package:kith/features/household/application/household_providers.dart';

/// The quick log: who you saw, when, and a note if there is one to make.
///
/// The same screen logs a new hangout and edits an existing one; [hangoutId]
/// is null when logging. It is built to be finished in ten seconds — the date
/// is already today and the person who opened it is already down as having
/// been there — so the only unavoidable act is tapping who you saw.
///
/// A save that lands closes the page. That is a pop rather than a typed
/// route, because the form does not know or care what it was opened from.
@RoutePage()
class HangoutEditorScreen extends ConsumerWidget {
  const HangoutEditorScreen({
    @PathParam('hangoutId') this.hangoutId,
    @QueryParam('contact') this.prefilledContactId,
    super.key,
  });

  /// The hangout being edited, or null when logging a new one.
  final String? hangoutId;

  /// A contact to start with already chosen, set when the form is opened from
  /// that contact's own history. Ignored when editing.
  final String? prefilledContactId;

  /// Identifies the date control to tests.
  static const dateKey = Key('hangoutEditor.date');

  /// Identifies the note field to tests.
  static const noteKey = Key('hangoutEditor.note');

  /// Identifies the contact search field to tests.
  static const searchKey = Key('hangoutEditor.search');

  /// Identifies the save button to tests.
  static const saveKey = Key('hangoutEditor.save');

  /// Identifies the delete action to tests.
  static const deleteKey = Key('hangoutEditor.delete');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdId = ref.watch(currentHouseholdIdProvider);
    // Watched rather than read: the form pre-ticks whoever opened it as an
    // attendee, and the controller credits them with the entry, so the
    // identity has to stay resolved for as long as the form is up.
    final user = ref.watch(currentUserProvider);
    final contacts = householdId == null
        ? const AsyncLoading<List<Contact>>()
        : ref.watch(contactsProvider(householdId));
    final members = householdId == null
        ? const AsyncLoading<List<Member>>()
        : ref.watch(householdMembersProvider(householdId));
    final hangouts = householdId == null
        ? const AsyncLoading<List<Hangout>>()
        : ref.watch(hangoutsProvider(householdId));

    return Scaffold(
      appBar: AppBar(
        title: Text(hangoutId == null ? 'Log a hangout' : 'Edit hangout'),
      ),
      body: switch ((contacts, members, hangouts)) {
        (AsyncError(:final error), _, _) ||
        (_, AsyncError(:final error), _) ||
        (_, _, AsyncError(:final error)) => _Message(_messageFor(error)),
        (
          AsyncData(value: final people),
          AsyncData(value: final household),
          AsyncData(value: final logged),
        ) =>
          _resolve(ref, householdId!, people, household, logged, user),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  /// Picks the form to show, or the reason there is none.
  Widget _resolve(
    WidgetRef ref,
    String householdId,
    List<Contact> contacts,
    List<Member> members,
    List<Hangout> hangouts,
    AuthUser? user,
  ) {
    final active = [
      for (final contact in contacts)
        if (!contact.isArchived) contact,
    ];
    final existing = hangoutId == null
        ? null
        : hangouts.where((hangout) => hangout.id == hangoutId).firstOrNull;
    if (hangoutId != null && existing == null) {
      return const _Message('That hangout is no longer here.');
    }
    if (existing == null && active.isEmpty) {
      return const _Message(
        'Add a contact first, so there is somebody to have seen.',
      );
    }

    // An edit shows every contact the hangout names, archived ones included,
    // so opening an old entry cannot silently drop somebody off it.
    final selectable = existing == null
        ? active
        : [
            ...active,
            for (final contact in contacts)
              if (contact.isArchived && existing.includes(contact.id)) contact,
          ];

    return _HangoutForm(
      householdId: householdId,
      contacts: selectable,
      members: members,
      existing: existing,
      initialDraft: existing == null
          ? HangoutDraft(
              occurredOn: CalendarDay.of(ref.read(clockProvider).now()),
              contactIds: [
                if (prefilledContactId != null &&
                    active.any((c) => c.id == prefilledContactId))
                  prefilledContactId!,
              ],
              attendeeIds: [
                if (ref.read(currentUserProvider) case final user?) user.id,
              ],
            )
          : HangoutDraft.from(existing),
    );
  }

  static String _messageFor(Object error) => switch (error) {
    final Failure failure => hangoutFailureMessage(failure),
    _ => 'Something went wrong. Try again.',
  };
}

class _HangoutForm extends ConsumerStatefulWidget {
  const _HangoutForm({
    required this.householdId,
    required this.contacts,
    required this.members,
    required this.existing,
    required this.initialDraft,
  });

  final String householdId;
  final List<Contact> contacts;
  final List<Member> members;
  final Hangout? existing;
  final HangoutDraft initialDraft;

  @override
  ConsumerState<_HangoutForm> createState() => _HangoutFormState();
}

class _HangoutFormState extends ConsumerState<_HangoutForm> {
  late final TextEditingController _note;
  late final TextEditingController _search;

  late DateTime _occurredOn;
  late Set<String> _contactIds;
  late Set<String> _attendeeIds;

  /// Set once save has been tried, so "choose who you saw" appears in answer
  /// to a tap rather than greeting an empty form.
  var _showSelectionError = false;

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.initialDraft.note ?? '');
    _search = TextEditingController();
    _search.addListener(() => setState(() {}));
    _occurredOn = widget.initialDraft.occurredOn;
    _contactIds = widget.initialDraft.contactIds.toSet();
    _attendeeIds = widget.initialDraft.attendeeIds.toSet();
  }

  @override
  void dispose() {
    _note.dispose();
    _search.dispose();
    super.dispose();
  }

  /// The contacts offered as chips: everyone chosen, then everyone the search
  /// matches.
  ///
  /// Chosen contacts stay on screen whatever is typed, so a selection can
  /// always be reviewed and undone without first clearing the search.
  List<Contact> get _offered {
    final chosen = [
      for (final contact in widget.contacts)
        if (_contactIds.contains(contact.id)) contact,
    ];
    final matches = ContactView(
      query: _search.text,
      showArchived: true,
    ).apply(widget.contacts);
    return [
      ...chosen,
      for (final contact in matches)
        if (!_contactIds.contains(contact.id)) contact,
    ];
  }

  Future<void> _pickDate() async {
    final today = CalendarDay.of(ref.read(clockProvider).now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredOn.isAfter(today) ? today : _occurredOn,
      // Nothing before Kith could have been logged in it, and a hangout is
      // something that happened, so the future is not offered.
      firstDate: DateTime.utc(today.year - 10),
      lastDate: today,
    );
    if (picked != null) setState(() => _occurredOn = CalendarDay.of(picked));
  }

  Future<void> _save() async {
    if (_contactIds.isEmpty) {
      setState(() => _showSelectionError = true);
      return;
    }

    final saved = await ref
        .read(hangoutEditorControllerProvider.notifier)
        .save(
          householdId: widget.householdId,
          hangoutId: widget.existing?.id,
          draft: HangoutDraft(
            occurredOn: _occurredOn,
            // Written in the order the contacts are listed rather than in tap
            // order, so two logs of the same evening store the same document.
            contactIds: [
              for (final contact in widget.contacts)
                if (_contactIds.contains(contact.id)) contact.id,
            ],
            attendeeIds: [
              for (final member in widget.members)
                if (_attendeeIds.contains(member.id)) member.id,
            ],
            note: _note.text,
          ),
        );
    if (saved && mounted) await Navigator.of(context).maybePop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    final done = await ref
        .read(hangoutEditorControllerProvider.notifier)
        .delete(householdId: widget.householdId, hangoutId: existing.id);
    if (done && mounted) await Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(hangoutEditorControllerProvider);
    final today = CalendarDay.of(ref.watch(nowProvider));
    final offered = _offered;

    return CenteredFormBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('When'),
          const SizedBox(height: KithSpacing.xs),
          OutlinedButton.icon(
            key: HangoutEditorScreen.dateKey,
            onPressed: state.isSubmitting ? null : _pickDate,
            icon: const Icon(KithIcons.date),
            label: Text(DayLabel.of(_occurredOn, today: today)),
          ),
          const SizedBox(height: KithSpacing.lg),
          const _SectionLabel('Who you saw'),
          const SizedBox(height: KithSpacing.xs),
          if (widget.contacts.length > _searchFrom) ...[
            TextField(
              key: HangoutEditorScreen.searchKey,
              controller: _search,
              enabled: !state.isSubmitting,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search contacts',
                prefixIcon: Icon(KithIcons.search),
              ),
            ),
            const SizedBox(height: KithSpacing.sm),
          ],
          if (offered.isEmpty)
            Text(
              'Nobody matches what you are looking for.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: KithSpacing.xs,
              runSpacing: KithSpacing.xs,
              children: [
                for (final contact in offered)
                  FilterChip(
                    label: Text(contact.name),
                    selected: _contactIds.contains(contact.id),
                    onSelected: state.isSubmitting
                        ? null
                        : (selected) => setState(() {
                            _showSelectionError = false;
                            if (selected) {
                              _contactIds.add(contact.id);
                            } else {
                              _contactIds.remove(contact.id);
                            }
                          }),
                  ),
              ],
            ),
          if (_showSelectionError) ...[
            const SizedBox(height: KithSpacing.xs),
            Text(
              'Choose who you saw.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (widget.members.isNotEmpty) ...[
            const SizedBox(height: KithSpacing.lg),
            const _SectionLabel('Who from the house was there'),
            const SizedBox(height: KithSpacing.xs),
            Wrap(
              spacing: KithSpacing.xs,
              runSpacing: KithSpacing.xs,
              children: [
                for (final member in widget.members)
                  FilterChip(
                    label: Text(member.displayName),
                    selected: _attendeeIds.contains(member.id),
                    onSelected: state.isSubmitting
                        ? null
                        : (selected) => setState(() {
                            if (selected) {
                              _attendeeIds.add(member.id);
                            } else {
                              _attendeeIds.remove(member.id);
                            }
                          }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: KithSpacing.lg),
          TextField(
            key: HangoutEditorScreen.noteKey,
            controller: _note,
            enabled: !state.isSubmitting,
            minLines: 2,
            maxLines: 5,
            maxLength: Hangout.maxNoteLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Note',
              helperText: 'Optional. What made it worth remembering.',
              // The cap is a backstop against a paste, not a target: a
              // counter next to a one-line note would be noise, and it
              // crowds the helper text off the end of its own line.
              counterText: '',
            ),
          ),
          if (state.failure case final failure?) ...[
            const SizedBox(height: KithSpacing.xs),
            Text(
              hangoutFailureMessage(failure),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: KithSpacing.lg),
          FilledButton(
            key: HangoutEditorScreen.saveKey,
            onPressed: state.isSubmitting ? null : _save,
            child: state.isSubmitting
                ? const SizedBox.square(
                    dimension: KithSpacing.md,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.existing == null ? 'Log it' : 'Save'),
          ),
          if (widget.existing != null) ...[
            const SizedBox(height: KithSpacing.xs),
            TextButton(
              key: HangoutEditorScreen.deleteKey,
              onPressed: state.isSubmitting ? null : _delete,
              child: const Text('Delete hangout'),
            ),
          ],
        ],
      ),
    );
  }

  /// How many contacts a household needs before the chips get a search field
  /// above them. Below this they all fit on screen and the field is one more
  /// thing between the user and a ten-second log.
  static const _searchFrom = 8;
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
