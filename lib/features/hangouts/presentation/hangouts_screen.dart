import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/freshness_gauge.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/time/calendar_day.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/data/models/member.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/hangouts/domain/day_label.dart';
import 'package:kith/features/hangouts/domain/freshness_index.dart';
import 'package:kith/features/hangouts/presentation/hangout_failure_message.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/l10n/l10n.dart';
import 'package:kith/routing/app_router.dart';

/// The household's hangouts, most recent first.
///
/// One screen for both of M3's history views: with no [contactId] it is the
/// household timeline, and with one it is that contact's history, headed by
/// their gauge so the effect of logging something is visible on the same
/// screen that logged it.
@RoutePage()
class HangoutsScreen extends ConsumerWidget {
  const HangoutsScreen({@PathParam('contactId') this.contactId, super.key});

  /// The contact whose history this is, or null for the whole household.
  final String? contactId;

  /// Identifies the log-a-hangout button to tests.
  static const logKey = Key('hangouts.log');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdId = ref.watch(currentHouseholdIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: contactId == null || householdId == null
            ? Text(context.l10n.hangoutsTitle)
            : _Title(householdId: householdId, contactId: contactId!),
      ),
      floatingActionButton: householdId == null
          ? null
          : FloatingActionButton(
              key: logKey,
              onPressed: () => context.router.push(
                HangoutEditorRoute(prefilledContactId: contactId),
              ),
              tooltip: context.l10n.logHangoutTitle,
              child: const Icon(KithIcons.add),
            ),
      // Null only in the beat between the guard letting the user through and
      // this screen building, or just after they were removed from the
      // household.
      body: householdId == null
          ? const Center(child: CircularProgressIndicator())
          : _HangoutsBody(householdId: householdId, contactId: contactId),
    );
  }
}

/// Names whose history is on screen, once their name is known.
///
/// Falls back to the plain word while the contacts are still loading, so the
/// app bar does not flash a name in and out on the way to the same screen.
class _Title extends ConsumerWidget {
  const _Title({required this.householdId, required this.contactId});

  final String householdId;
  final String contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref
        .watch(contactsProvider(householdId))
        .value
        ?.where((contact) => contact.id == contactId)
        .firstOrNull
        ?.name;

    return Text(
      name == null
          ? context.l10n.hangoutsTitle
          : context.l10n.hangoutsWithTitle(name),
    );
  }
}

class _HangoutsBody extends ConsumerWidget {
  const _HangoutsBody({required this.householdId, required this.contactId});

  final String householdId;
  final String? contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hangouts = ref.watch(hangoutsProvider(householdId));
    final contacts = ref.watch(contactsProvider(householdId));
    final members = ref.watch(householdMembersProvider(householdId));

    return switch ((hangouts, contacts)) {
      (AsyncError(:final error), _) ||
      (_, AsyncError(:final error)) => _Message(
        _messageFor(context.l10n, error),
      ),
      (AsyncData(value: final logged), AsyncData(value: final people)) =>
        _Timeline(
          householdId: householdId,
          contactId: contactId,
          hangouts: contactId == null
              ? logged
              : [
                  for (final hangout in logged)
                    if (hangout.includes(contactId!)) hangout,
                ],
          contacts: {for (final contact in people) contact.id: contact},
          members: {
            for (final member in members.value ?? const <Member>[])
              member.id: member,
          },
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  /// Streams surface domain failures; anything else is a bug rather than a
  /// condition the user can act on, and reads as the generic message.
  static String _messageFor(AppLocalizations l10n, Object error) =>
      switch (error) {
        final Failure failure => hangoutFailureMessage(l10n, failure),
        _ => l10n.errorGeneric,
      };
}

class _Timeline extends ConsumerWidget {
  const _Timeline({
    required this.householdId,
    required this.contactId,
    required this.hangouts,
    required this.contacts,
    required this.members,
  });

  final String householdId;
  final String? contactId;
  final List<Hangout> hangouts;
  final Map<String, Contact> contacts;
  final Map<String, Member> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = CalendarDay.of(ref.watch(nowProvider));
    final subject = contactId == null ? null : contacts[contactId];

    if (hangouts.isEmpty) {
      return Column(
        children: [
          if (subject != null) _ContactHeader(contact: subject),
          Expanded(
            child: _Empty(
              text: subject == null
                  ? context.l10n.hangoutsEmpty
                  : context.l10n.reasonNothingLogged(subject.name),
            ),
          ),
        ],
      );
    }

    // Day headers are worked out once here rather than per row, so the list
    // builder stays a lookup and cannot disagree with itself while scrolling.
    final startsDay = [
      for (final (index, hangout) in hangouts.indexed)
        index == 0 || hangouts[index - 1].occurredOn != hangout.occurredOn,
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: KithSpacing.xxl),
      itemCount: hangouts.length + (subject == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (subject != null && index == 0) {
          return _ContactHeader(contact: subject);
        }
        final at = subject == null ? index : index - 1;
        final hangout = hangouts[at];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (startsDay[at])
              _DayHeader(
                label: DayLabel.of(
                  hangout.occurredOn,
                  today: today,
                  l10n: context.l10n,
                ),
              ),
            _HangoutRow(
              hangout: hangout,
              contacts: contacts,
              members: members,
              // A contact's own history need not repeat their name on every
              // row; the household timeline is the view where it matters.
              omitContactId: contactId,
            ),
          ],
        );
      },
    );
  }
}

/// The contact a history is about, with the gauge their hangouts drive.
class _ContactHeader extends ConsumerWidget {
  const _ContactHeader({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final householdId = ref.watch(currentHouseholdIdProvider);
    final freshness = householdId == null
        ? FreshnessIndex.empty.of(contact)
        : ref.watch(freshnessIndexProvider(householdId)).of(contact);

    return Padding(
      padding: const EdgeInsets.all(KithSpacing.md),
      child: Row(
        spacing: KithSpacing.md,
        children: [
          FreshnessGauge(freshness: freshness, diameter: 56),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name, style: theme.textTheme.titleMedium),
                Text(
                  '${freshness.lastSeenLabel(context.l10n)}  ·  '
                  '${contact.cadence.label(context.l10n)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KithSpacing.md,
        KithSpacing.md,
        KithSpacing.md,
        KithSpacing.xxs,
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _HangoutRow extends StatelessWidget {
  const _HangoutRow({
    required this.hangout,
    required this.contacts,
    required this.members,
    required this.omitContactId,
  });

  final Hangout hangout;
  final Map<String, Contact> contacts;
  final Map<String, Member> members;
  final String? omitContactId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final names = [
      for (final id in hangout.contactIds)
        if (id != omitContactId)
          contacts[id]?.name ?? l10n.someoneSinceRemoved,
    ];
    final attendees = [
      for (final id in hangout.attendeeIds) ?members[id]?.displayName,
    ];
    final detail = [
      if (attendees.isNotEmpty) l10n.withAttendees(_joined(l10n, attendees)),
      ?hangout.note,
    ].join('  ·  ');

    return ListTile(
      onTap: () =>
          context.router.push(HangoutEditorRoute(hangoutId: hangout.id)),
      leading: Icon(KithIcons.hangout, color: theme.colorScheme.outline),
      title: Text(
        names.isEmpty ? l10n.justTheTwoOfYou : _joined(l10n, names),
      ),
      subtitle: detail.isEmpty ? null : Text(detail),
      isThreeLine: false,
    );
  }

  /// "Ana", "Ana and Bo", "Ana, Bo and Cass" — the way a person lists people.
  static String _joined(AppLocalizations l10n, List<String> names) =>
      switch (names.length) {
        0 => '',
        1 => names.first,
        _ => l10n.nameListPair(
          names.sublist(0, names.length - 1).join(l10n.nameListSeparator),
          names.last,
        ),
      };
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KithSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(KithIcons.hangout, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: KithSpacing.sm),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
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
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }
}
