import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/freshness_gauge.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/features/contacts/application/contact_list_controller.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/contact_view.dart';
import 'package:kith/features/contacts/presentation/contact_failure_message.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/hangouts/domain/freshness.dart';
import 'package:kith/features/hangouts/domain/freshness_index.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/routing/app_router.dart';

/// The household's contact list, with search, a label filter and a sort.
///
/// Reachable only behind the household guard, so there is always a household
/// to show; the id comes from the membership the guard resolved.
@RoutePage()
class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  /// Identifies the search field to tests.
  static const searchKey = Key('contacts.search');

  /// Identifies the sort menu to tests.
  static const sortKey = Key('contacts.sort');

  /// Identifies the way through to the relationship labels to tests.
  static const labelsKey = Key('contacts.labels');

  /// Identifies the way through to the address book import to tests.
  static const importKey = Key('contacts.import');

  /// Identifies the add-a-contact button to tests.
  static const addKey = Key('contacts.add');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdId = ref.watch(currentHouseholdIdProvider);
    final view = ref.watch(contactListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          PopupMenuButton<ContactSort>(
            key: sortKey,
            icon: const Icon(KithIcons.sort),
            tooltip: 'Sort',
            initialValue: view.sort,
            onSelected: ref.read(contactListControllerProvider.notifier).sortBy,
            itemBuilder: (context) => [
              for (final sort in ContactSort.values)
                PopupMenuItem(value: sort, child: Text(sort.label)),
            ],
          ),
          IconButton(
            key: importKey,
            onPressed: () => context.router.push(const ContactImportRoute()),
            icon: const Icon(KithIcons.importContacts),
            tooltip: 'Import from contacts',
          ),
          IconButton(
            key: labelsKey,
            onPressed: () =>
                context.router.push(const RelationshipTypesRoute()),
            icon: const Icon(KithIcons.label),
            tooltip: 'Relationship labels',
          ),
        ],
      ),
      floatingActionButton: householdId == null
          ? null
          : FloatingActionButton(
              key: addKey,
              onPressed: () => context.router.push(ContactEditorRoute()),
              tooltip: 'Add a contact',
              child: const Icon(KithIcons.add),
            ),
      // Null only in the beat between the guard letting the user through and
      // this screen building, or just after they were removed from the
      // household.
      body: householdId == null
          ? const Center(child: CircularProgressIndicator())
          : _ContactsBody(householdId: householdId),
    );
  }
}

class _ContactsBody extends ConsumerWidget {
  const _ContactsBody({required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider(householdId));
    final types = ref.watch(relationshipTypesProvider(householdId));
    final view = ref.watch(contactListControllerProvider);
    // Watched here rather than per row, so one pass over the timeline serves
    // the sort and every gauge on screen.
    final freshness = ref.watch(freshnessIndexProvider(householdId));

    return switch ((contacts, types)) {
      (AsyncError(:final error), _) ||
      (_, AsyncError(:final error)) => _Message(_messageFor(error)),
      (AsyncData(value: final all), AsyncData(value: final labels)) =>
        _ContactList(
          householdId: householdId,
          contacts: view.apply(all, freshness: freshness),
          labels: {for (final label in labels) label.id: label},
          freshness: freshness,
          hasAnyContact: all.isNotEmpty,
          view: view,
        ),
      _ => const _Loading(),
    };
  }

  /// Streams surface domain failures; anything else is a bug rather than a
  /// condition the user can act on, and reads as the generic message.
  static String _messageFor(Object error) => switch (error) {
    final Failure failure => contactFailureMessage(failure),
    _ => 'Something went wrong. Try again.',
  };
}

class _ContactList extends ConsumerWidget {
  const _ContactList({
    required this.householdId,
    required this.contacts,
    required this.labels,
    required this.freshness,
    required this.hasAnyContact,
    required this.view,
  });

  final String householdId;
  final List<Contact> contacts;
  final Map<String, RelationshipType> labels;
  final FreshnessIndex freshness;
  final bool hasAnyContact;
  final ContactView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(contactListControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            KithSpacing.md,
            KithSpacing.xs,
            KithSpacing.md,
            KithSpacing.xs,
          ),
          child: TextField(
            key: ContactsScreen.searchKey,
            onChanged: controller.search,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search names, tags or a guardian',
              prefixIcon: Icon(KithIcons.search),
            ),
          ),
        ),
        _FilterChips(labels: labels.values.toList(), view: view),
        const Divider(height: KithSpacing.md),
        Expanded(
          child: contacts.isEmpty
              ? _EmptyState(
                  hasAnyContact: hasAnyContact,
                  hasAnyLabel: labels.isNotEmpty,
                  isFiltered: view.isFiltered,
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: KithSpacing.xxl),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) => _ContactRow(
                    contact: contacts[index],
                    label: labels[contacts[index].relationshipTypeId],
                    freshness: freshness.of(contacts[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.labels, required this.view});

  final List<RelationshipType> labels;
  final ContactView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(contactListControllerProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: KithSpacing.md),
      child: Row(
        spacing: KithSpacing.xs,
        children: [
          FilterChip(
            label: const Text('All'),
            selected: view.relationshipTypeId == null,
            onSelected: (_) => controller.filterByType(null),
          ),
          for (final label in labels)
            FilterChip(
              label: Text(label.name),
              selected: view.relationshipTypeId == label.id,
              onSelected: (selected) =>
                  controller.filterByType(selected ? label.id : null),
            ),
          FilterChip(
            label: const Text('Archived'),
            selected: view.showArchived,
            onSelected: (selected) => controller.showArchived(show: selected),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.label,
    required this.freshness,
  });

  final Contact contact;

  /// The contact's relationship label, or null if it was deleted from under
  /// them, which reassignment is meant to prevent but a stale stream can show.
  final RelationshipType? label;

  /// Where they sit against their cadence, drawn as the ring round the
  /// avatar.
  final Freshness freshness;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: () =>
          context.router.push(ContactEditorRoute(contactId: contact.id)),
      leading: FreshnessGauge(
        freshness: freshness,
        child: CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          child: Text(_initialOf(contact.name)),
        ),
      ),
      title: Text(contact.name),
      subtitle: Text(
        [
          label?.name ?? 'No label',
          contact.cadence.label,
          freshness.lastSeenLabel,
        ].join('  ·  '),
      ),
      trailing: contact.isArchived ? const Chip(label: Text('Archived')) : null,
    );
  }

  /// First character of [name], for the avatar. Falls back to a placeholder
  /// rather than throwing on a name that is somehow empty.
  static String _initialOf(String name) =>
      name.isEmpty ? '?' : name.characters.first.toUpperCase();
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState({
    required this.hasAnyContact,
    required this.hasAnyLabel,
    required this.isFiltered,
  });

  final bool hasAnyContact;
  final bool hasAnyLabel;
  final bool isFiltered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final (text, action) = switch ((hasAnyLabel, hasAnyContact, isFiltered)) {
      (false, _, _) => (
        'Add a relationship label first, so contacts have somewhere to go.',
        TextButton(
          onPressed: () => context.router.push(const RelationshipTypesRoute()),
          child: const Text('Manage labels'),
        ),
      ),
      (_, false, _) => ('Nobody here yet. Add the first contact.', null),
      (_, _, true) => (
        'Nothing matches what you are looking for.',
        TextButton(
          onPressed: ref
              .read(contactListControllerProvider.notifier)
              .clearFilters,
          child: const Text('Clear filters'),
        ),
      ),
      _ => ('Nobody here yet. Add the first contact.', null),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KithSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              KithIcons.people,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: KithSpacing.sm),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: KithSpacing.xs),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
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
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}
