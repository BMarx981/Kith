import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/freshness_gauge.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/time/calendar_day.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/hangouts/domain/day_label.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/suggestions/application/suggestion_action_controller.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';
import 'package:kith/features/suggestions/domain/snooze_horizon.dart';
import 'package:kith/features/suggestions/engine/suggestion.dart';
import 'package:kith/features/suggestions/presentation/suggestion_failure_message.dart';
import 'package:kith/routing/app_router.dart';

/// The landing screen: who to reconnect with, ranked.
///
/// The list is the suggestion engine's output and nothing else — no filters, no
/// search, no sort. A prompt you have to operate is not a prompt; the contact
/// list is one screen away for everything else.
@RoutePage()
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Identifies the household action to tests.
  static const householdKey = Key('home.household');

  /// Identifies the contacts action to tests.
  static const contactsKey = Key('home.contacts');

  /// Identifies the hangouts action to tests.
  static const hangoutsKey = Key('home.hangouts');

  /// Identifies one suggestion's card to tests.
  static Key cardKey(String contactId) => Key('home.suggestion.$contactId');

  /// Identifies one suggestion's "plan it" action to tests.
  static Key planKey(String contactId) => Key('home.plan.$contactId');

  /// Identifies one suggestion's deferral action to tests.
  static Key snoozeKey(String contactId, SnoozeHorizon horizon) =>
      Key('home.${horizon.name}.$contactId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdId = ref.watch(currentHouseholdIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reconnect'),
        actions: [
          IconButton(
            key: hangoutsKey,
            onPressed: () => context.router.push(HangoutsRoute()),
            icon: const Icon(KithIcons.hangout),
            tooltip: 'Hangouts',
          ),
          IconButton(
            key: contactsKey,
            onPressed: () => context.router.push(const ContactsRoute()),
            icon: const Icon(KithIcons.people),
            tooltip: 'Contacts',
          ),
          IconButton(
            key: householdKey,
            onPressed: () => context.router.push(const HouseholdRoute()),
            icon: const Icon(KithIcons.household),
            tooltip: 'Household',
          ),
        ],
      ),
      // Null only in the beat between the guard letting the user through and
      // this screen building, or just after they were removed from the
      // household.
      body: householdId == null
          ? const Center(child: CircularProgressIndicator())
          : _ReconnectBody(householdId: householdId),
    );
  }
}

class _ReconnectBody extends ConsumerWidget {
  const _ReconnectBody({required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider(householdId));
    // The timeline and the plans are watched here, not for what they hold, but
    // so the section can tell "nothing to do" from "not loaded yet": the
    // ranking reads both through providers that fall back to empty, and an
    // empty Reconnect section shown too early is a claim rather than a wait.
    final hangouts = ref.watch(hangoutsProvider(householdId));
    final plans = ref.watch(plannedHangoutsProvider(householdId));

    return switch ((contacts, hangouts, plans)) {
      (AsyncError(:final error), _, _) ||
      (_, AsyncError(:final error), _) ||
      (_, _, AsyncError(:final error)) => _Message(_messageFor(error)),
      (AsyncData(value: final all), AsyncData(), AsyncData()) => _Suggestions(
        householdId: householdId,
        suggestions: ref.watch(suggestionsProvider(householdId)),
        hasAnyContact: all.any((contact) => !contact.isArchived),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }

  /// Streams surface domain failures; anything else is a bug rather than a
  /// condition the user can act on, and reads as the generic message.
  static String _messageFor(Object error) => switch (error) {
    final Failure failure => suggestionFailureMessage(failure),
    _ => 'Something went wrong. Try again.',
  };
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({
    required this.householdId,
    required this.suggestions,
    required this.hasAnyContact,
  });

  final String householdId;
  final List<Suggestion> suggestions;
  final bool hasAnyContact;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return _Empty(hasAnyContact: hasAnyContact);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        KithSpacing.md,
        KithSpacing.md,
        KithSpacing.md,
        KithSpacing.xxl,
      ),
      itemCount: suggestions.length,
      itemBuilder: (context, index) => _SuggestionCard(
        householdId: householdId,
        suggestion: suggestions[index],
      ),
    );
  }
}

/// One person put forward, why, and the three answers to it.
///
/// A hairline card rather than a list row: the actions make it a thing you do
/// something with, and a row of buttons under a `ListTile` reads as a mistake.
class _SuggestionCard extends ConsumerWidget {
  const _SuggestionCard({required this.householdId, required this.suggestion});

  final String householdId;
  final Suggestion suggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final contact = suggestion.contact;
    final plan = suggestion.plan;
    final busy = ref.watch(suggestionActionControllerProvider).isSubmitting;

    return Card(
      key: HomeScreen.cardKey(contact.id),
      margin: const EdgeInsets.only(bottom: KithSpacing.sm),
      child: InkWell(
        borderRadius: KithRadius.surfaceBorder,
        onTap: () =>
            context.router.push(HangoutsRoute(contactId: contact.id)),
        child: Padding(
          padding: const EdgeInsets.all(KithSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                spacing: KithSpacing.md,
                children: [
                  FreshnessGauge(
                    freshness: suggestion.freshness,
                    child: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      child: Text(_initialOf(contact.name)),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(contact.name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: KithSpacing.xxs),
                        Text(
                          suggestion.reason,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (plan != null) ...[
                const SizedBox(height: KithSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _PlanChip(plan: plan),
                ),
              ],
              const SizedBox(height: KithSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: KithSpacing.xs,
                children: [
                  for (final horizon in SnoozeHorizon.values)
                    TextButton(
                      key: HomeScreen.snoozeKey(contact.id, horizon),
                      onPressed: busy
                          ? null
                          : () => _defer(context, ref, horizon),
                      child: Text(horizon.label),
                    ),
                  FilledButton(
                    key: HomeScreen.planKey(contact.id),
                    onPressed: busy ? null : () => _plan(context, ref),
                    child: const Text('Plan it'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Asks which day, then records the intent.
  ///
  /// A day is asked for rather than assumed: an arrangement with no date is
  /// not an arrangement, and the picker opens a week out so that agreeing with
  /// it is still one tap.
  Future<void> _plan(BuildContext context, WidgetRef ref) async {
    final today = CalendarDay.of(ref.read(clockProvider).now());
    final picked = await showDatePicker(
      context: context,
      initialDate: today.add(
        const Duration(days: SnoozeHorizon.weekDays),
      ),
      // A plan is something ahead of you, so yesterday is not offered; a year
      // is as far out as an intention to see someone means anything.
      firstDate: today,
      lastDate: DateTime.utc(today.year + 1, today.month, today.day),
    );
    if (picked == null || !context.mounted) return;

    final plan = await ref
        .read(suggestionActionControllerProvider.notifier)
        .plan(
          householdId: householdId,
          contactId: suggestion.contact.id,
          plannedFor: CalendarDay.of(picked),
        );
    if (!context.mounted) return;
    _report(
      context,
      ref,
      plan: plan,
      done:
          'Planned with ${suggestion.contact.name} for '
          '${DayLabel.of(CalendarDay.of(picked), today: today)}.',
    );
  }

  /// Defers the suggestion for as long as [horizon] says.
  Future<void> _defer(
    BuildContext context,
    WidgetRef ref,
    SnoozeHorizon horizon,
  ) async {
    final today = CalendarDay.of(ref.read(clockProvider).now());
    final plan = await ref
        .read(suggestionActionControllerProvider.notifier)
        .snooze(
          householdId: householdId,
          contact: suggestion.contact,
          horizon: horizon,
        );
    if (!context.mounted) return;
    _report(
      context,
      ref,
      plan: plan,
      done: plan == null
          ? ''
          : 'Not asking about ${suggestion.contact.name} until '
                '${DayLabel.of(plan.plannedFor, today: today)}.',
    );
  }

  /// Says what happened, and offers to take it back.
  ///
  /// The undo is the whole reason the controller hands the stored plan back:
  /// deferring somebody by a tap you did not mean to make should cost one tap
  /// to reverse, not a trip through a screen that does not exist yet.
  ///
  /// The notifier is taken out of the ref here, before the snackbar is built,
  /// because acting on a suggestion is what removes it: by the time anyone
  /// reaches for Undo this card is gone, and a closure holding its `ref` would
  /// be holding a dead widget. The notifier outlives the card.
  void _report(
    BuildContext context,
    WidgetRef ref, {
    required PlannedHangout? plan,
    required String done,
  }) {
    final controller = ref.read(suggestionActionControllerProvider.notifier);
    final failure = ref.read(suggestionActionControllerProvider).failure;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (plan == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            failure == null
                ? 'Something went wrong. Try again.'
                : suggestionFailureMessage(failure),
          ),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(done),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            unawaited(
              controller.cancel(
                householdId: householdId,
                plannedHangoutId: plan.id,
              ),
            );
          },
        ),
      ),
    );
  }

  /// First character of [name], for the avatar. Falls back to a placeholder
  /// rather than throwing on a name that is somehow empty.
  static String _initialOf(String name) =>
      name.isEmpty ? '?' : name.characters.first.toUpperCase();
}

/// The arrangement already standing, said plainly on the card.
class _PlanChip extends ConsumerWidget {
  const _PlanChip({required this.plan});

  final PlannedHangout plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = CalendarDay.of(ref.watch(nowProvider));
    return Chip(
      label: Text('Planned ${DayLabel.of(plan.plannedFor, today: today)}'),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.hasAnyContact});

  final bool hasAnyContact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (text, action) = hasAnyContact
        ? (
            'Nobody is overdue. Everyone you track has been seen inside the '
                'cadence you set for them.',
            null,
          )
        : (
            'Nobody here yet. Add the people you want to keep up with and '
                'they will show up here when it has been a while.',
            TextButton(
              onPressed: () => context.router.push(const ContactsRoute()),
              child: const Text('Add contacts'),
            ),
          );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KithSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              KithIcons.reconnect,
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
