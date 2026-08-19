import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/household.dart';
import 'package:kith/data/services/calendar_directory.dart';
import 'package:kith/features/calendar/application/calendar_link_controller.dart';
import 'package:kith/features/calendar/presentation/calendar_failure_message.dart';
import 'package:kith/features/household/application/household_providers.dart';

/// Where a household points Kith at the calendar its plans belong on.
///
/// Two decisions on one screen, in the order they have to happen: this member
/// grants Kith access to their Google account, then the household picks which
/// of that account's calendars to write to. The grant is personal and the pick
/// is shared, so a partner arriving later sees the linked calendar named but
/// still has to connect their own account before they can change it.
@RoutePage()
class CalendarSettingsScreen extends ConsumerStatefulWidget {
  const CalendarSettingsScreen({super.key});

  /// Identifies the connect action to tests.
  static const connectKey = Key('calendar.connect');

  /// Identifies the unlink action to tests.
  static const unlinkKey = Key('calendar.unlink');

  /// Identifies one calendar's row to tests.
  static Key calendarKey(String calendarId) => Key('calendar.pick.$calendarId');

  @override
  ConsumerState<CalendarSettingsScreen> createState() =>
      _CalendarSettingsScreenState();
}

class _CalendarSettingsScreenState
    extends ConsumerState<CalendarSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Reads what this member has already granted, and asks for nothing:
    // opening a settings screen is not consent.
    unawaited(
      Future.microtask(
        () => ref.read(calendarLinkControllerProvider.notifier).load(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final householdId = ref.watch(currentHouseholdIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      // Null only in the beat between the guard letting the user through and
      // this screen building, or just after they were removed from it.
      body: householdId == null
          ? const Center(child: CircularProgressIndicator())
          : _CalendarBody(householdId: householdId),
    );
  }
}

class _CalendarBody extends ConsumerWidget {
  const _CalendarBody({required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider(householdId)).value;
    final state = ref.watch(calendarLinkControllerProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: KithSpacing.xxl),
      children: [
        _LinkedCard(householdId: householdId, household: household),
        if (state.failure case final failure?) _Message(failure),
        const Divider(height: KithSpacing.xl),
        if (!state.isAuthorised)
          _Connect(isBusy: state.isBusy)
        else
          _Picker(
            householdId: householdId,
            calendars: state.calendars,
            linkedId: household?.calendarId,
            isBusy: state.isBusy,
          ),
      ],
    );
  }
}

/// What the household writes to today, if anything.
class _LinkedCard extends ConsumerWidget {
  const _LinkedCard({required this.householdId, required this.household});

  final String householdId;
  final Household? household;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = household?.calendarName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KithSpacing.md,
        KithSpacing.md,
        KithSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Household calendar', style: theme.textTheme.titleMedium),
          const SizedBox(height: KithSpacing.xxs),
          Text(
            name == null
                ? 'No calendar linked. Plans are kept in Kith and go nowhere '
                      'else.'
                : 'Plans go on "$name". Anything subscribed to that calendar, '
                      'the frame included, shows them too.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (name != null) ...[
            const SizedBox(height: KithSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: CalendarSettingsScreen.unlinkKey,
                onPressed: () => _unlink(context, ref),
                child: const Text('Unlink'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Stops writing to the calendar, leaving the events already on it alone.
  Future<void> _unlink(BuildContext context, WidgetRef ref) async {
    final done = await ref
        .read(calendarLinkControllerProvider.notifier)
        .unlink(householdId: householdId);
    if (!context.mounted || !done) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Calendar unlinked. Events already on it were left where they '
            'are.',
          ),
        ),
      );
  }
}

/// The step before there is anything to pick from.
class _Connect extends ConsumerWidget {
  const _Connect({required this.isBusy});

  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KithSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect your Google account to choose a calendar. Kith reads the '
            'list of calendars you already have, and writes only the plans '
            'you make here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: KithSpacing.sm),
          FilledButton(
            key: CalendarSettingsScreen.connectKey,
            onPressed: isBusy
                ? null
                : () => unawaited(
                    ref
                        .read(calendarLinkControllerProvider.notifier)
                        .connect(),
                  ),
            child: const Text('Connect Google Calendar'),
          ),
        ],
      ),
    );
  }
}

/// The account's writable calendars, with the linked one marked.
class _Picker extends ConsumerWidget {
  const _Picker({
    required this.householdId,
    required this.calendars,
    required this.linkedId,
    required this.isBusy,
  });

  final String householdId;
  final List<CalendarListing> calendars;
  final String? linkedId;
  final bool isBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (calendars.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: KithSpacing.md),
        child: Text(
          'This account has no calendar Kith can write to. Make one in Google '
          'Calendar, or ask whoever owns the household calendar to share it '
          'with you.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KithSpacing.md),
          child: Text(
            'Your calendars',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: KithSpacing.xs),
        for (final calendar in calendars)
          ListTile(
            key: CalendarSettingsScreen.calendarKey(calendar.id),
            leading: const Icon(KithIcons.calendar),
            title: Text(calendar.name),
            subtitle: calendar.isPrimary
                ? const Text('Your own calendar')
                : null,
            trailing: calendar.id == linkedId
                ? const Chip(label: Text('Linked'))
                : null,
            enabled: !isBusy,
            // The linked one is not dimmed, only inert: it is the answer
            // rather than an option that has been taken away.
            onTap: calendar.id == linkedId
                ? null
                : () => _link(context, ref, calendar),
          ),
      ],
    );
  }

  /// Points the household at [calendar].
  Future<void> _link(
    BuildContext context,
    WidgetRef ref,
    CalendarListing calendar,
  ) async {
    final done = await ref
        .read(calendarLinkControllerProvider.notifier)
        .link(householdId: householdId, calendar: calendar);
    if (!context.mounted || !done) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Plans now go on "${calendar.name}".'),
        ),
      );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.failure);

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KithSpacing.md,
        KithSpacing.sm,
        KithSpacing.md,
        0,
      ),
      child: Text(
        calendarFailureMessage(failure),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
