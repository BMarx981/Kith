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
import 'package:kith/l10n/l10n.dart';

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
      appBar: AppBar(title: Text(context.l10n.calendarTitle)),
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
    final l10n = context.l10n;
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
          Text(l10n.householdCalendarTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: KithSpacing.xxs),
          Text(
            name == null
                ? l10n.calendarNoneLinkedBody
                : l10n.calendarLinkedBody(name),
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
                child: Text(l10n.unlinkButton),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Stops writing to the calendar, leaving the events already on it alone.
  Future<void> _unlink(BuildContext context, WidgetRef ref) async {
    final message = context.l10n.calendarUnlinked;
    final done = await ref
        .read(calendarLinkControllerProvider.notifier)
        .unlink(householdId: householdId);
    if (!context.mounted || !done) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
            context.l10n.calendarConnectBody,
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
            child: Text(context.l10n.calendarConnectButton),
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
          context.l10n.calendarNoneWritable,
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
            context.l10n.yourCalendars,
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
                ? Text(context.l10n.calendarPrimary)
                : null,
            trailing: calendar.id == linkedId
                ? Chip(label: Text(context.l10n.linkedChip))
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
    final message = context.l10n.calendarNowLinked(calendar.name);
    final done = await ref
        .read(calendarLinkControllerProvider.notifier)
        .link(householdId: householdId, calendar: calendar);
    if (!context.mounted || !done) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
        calendarFailureMessage(context.l10n, failure),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
