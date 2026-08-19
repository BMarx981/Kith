import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/household.dart';
import 'package:kith/data/models/member.dart';
import 'package:kith/data/models/member_role.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/household/presentation/household_failure_message.dart';
import 'package:kith/features/notifications/application/digest_controller.dart';
import 'package:kith/features/notifications/application/notification_providers.dart';
import 'package:kith/features/notifications/domain/digest_schedule.dart';
import 'package:kith/features/notifications/presentation/digest_failure_message.dart';
import 'package:kith/routing/app_router.dart';

/// The household's members, and the code that invites more of them.
///
/// Reachable only behind the household guard, so there is always a household
/// to show; the id comes from the membership the guard resolved.
@RoutePage()
class HouseholdScreen extends ConsumerWidget {
  const HouseholdScreen({super.key});

  /// Identifies the invite code's copy button to tests.
  static const copyCodeKey = Key('household.copyCode');

  /// Identifies the sign-out action to tests.
  static const signOutKey = Key('household.signOut');

  /// Identifies the way through to the calendar settings to tests.
  static const calendarKey = Key('household.calendar');

  /// Identifies the weekly-digest switch to tests.
  static const digestKey = Key('household.digest');

  /// Identifies the digest's day picker to tests.
  static const digestDayKey = Key('household.digest.day');

  /// Identifies the digest's hour picker to tests.
  static const digestHourKey = Key('household.digest.hour');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdId = ref.watch(currentHouseholdIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Household'),
        actions: [
          IconButton(
            key: signOutKey,
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(KithIcons.signOut),
            tooltip: 'Sign out',
          ),
        ],
      ),
      // Null only in the beat between the guard letting the user through and
      // this screen building, or just after they were removed from it.
      body: householdId == null
          ? const Center(child: CircularProgressIndicator())
          : _HouseholdBody(householdId: householdId),
    );
  }
}

class _HouseholdBody extends ConsumerWidget {
  const _HouseholdBody({required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(householdProvider(householdId));
    final members = ref.watch(householdMembersProvider(householdId));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: KithSpacing.xs),
      children: [
        switch (household) {
          AsyncData(value: final value?) => _InviteCard(household: value),
          AsyncData() => const _Message('This household no longer exists.'),
          AsyncError(:final error) => _Message(_messageFor(error)),
          _ => const _Loading(),
        },
        const Divider(height: KithSpacing.xl),
        _CalendarRow(householdId: householdId),
        const Divider(height: KithSpacing.xl),
        _DigestSection(householdId: householdId),
        const Divider(height: KithSpacing.xl),
        switch (members) {
          AsyncData(:final value) => _MemberList(members: value),
          AsyncError(:final error) => _Message(_messageFor(error)),
          _ => const _Loading(),
        },
      ],
    );
  }

  /// Streams surface domain failures; anything else is a bug rather than a
  /// condition the user can act on, and reads as the generic message.
  static String _messageFor(Object error) => switch (error) {
    final Failure failure => householdFailureMessage(failure),
    _ => 'Something went wrong. Try again.',
  };
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.household});

  final Household household;

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invite code copied.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = household.inviteCode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: KithSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(household.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: KithSpacing.md),
          if (code == null)
            Text(
              'This household has no invite code right now.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Card(
              child: ListTile(
                title: Text(
                  code.formatted,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 2,
                  ),
                ),
                subtitle: const Text('Share this to add someone.'),
                trailing: IconButton(
                  key: HouseholdScreen.copyCodeKey,
                  onPressed: () => _copy(context, code.value),
                  icon: const Icon(KithIcons.copy),
                  tooltip: 'Copy invite code',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The way through to the household's calendar link, and what it says today.
class _CalendarRow extends ConsumerWidget {
  const _CalendarRow({required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref
        .watch(householdProvider(householdId))
        .value
        ?.calendarName;

    return ListTile(
      key: HouseholdScreen.calendarKey,
      leading: const Icon(KithIcons.calendar),
      title: const Text('Calendar'),
      subtitle: Text(
        name == null ? 'Not linked' : 'Plans go on "$name"',
      ),
      onTap: () => context.router.push(const CalendarSettingsRoute()),
    );
  }
}

/// The member's own weekly digest: whether they want one, and when.
///
/// On the household screen rather than a settings page of its own because it
/// is one switch and two pickers, and because this is already where the app
/// keeps the things you set up once. The preference is personal even though it
/// lives here: one partner may want the nudge and the other may not, so the
/// row reads off *this* member's document and writes only to it.
class _DigestSection extends ConsumerWidget {
  const _DigestSection({required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final member = ref.watch(currentMemberProvider(householdId));
    final state = ref.watch(digestControllerProvider);
    final day = member?.digestDay;
    final hour = member?.digestHour ?? DigestSchedule.defaultHour;

    void set({int? day, int? hour}) => unawaited(
      ref
          .read(digestControllerProvider.notifier)
          .setPreference(day: day, hour: hour ?? DigestSchedule.defaultHour),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          key: HouseholdScreen.digestKey,
          secondary: const Icon(KithIcons.digest),
          title: const Text('Weekly digest'),
          subtitle: Text(
            day == null
                ? 'Off'
                : '${DigestSchedule.dayLabel(day)} at '
                      '${DigestSchedule.hourLabel(hour)}',
          ),
          value: day != null,
          // Inert until the roster has arrived: a switch that reads "off"
          // because the document has not loaded would store "off" if tapped.
          onChanged: member == null || state.isBusy
              ? null
              : (wanted) => set(
                  day: wanted ? DateTime.sunday : null,
                  hour: hour,
                ),
        ),
        if (day != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KithSpacing.md,
              0,
              KithSpacing.md,
              KithSpacing.sm,
            ),
            child: Row(
              spacing: KithSpacing.sm,
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: HouseholdScreen.digestDayKey,
                    initialValue: day,
                    // The two pickers share a row at phone width, where
                    // "Wednesday" is wider than half the screen. Expanding
                    // lets it ellipsize instead of overflowing the row.
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Day'),
                    items: [
                      for (var weekday = DateTime.monday;
                          weekday <= DateTime.sunday;
                          weekday++)
                        DropdownMenuItem(
                          value: weekday,
                          child: Text(DigestSchedule.dayLabel(weekday)),
                        ),
                    ],
                    onChanged: state.isBusy
                        ? null
                        : (picked) => set(day: picked ?? day, hour: hour),
                  ),
                ),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: HouseholdScreen.digestHourKey,
                    initialValue: hour,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Time'),
                    items: [
                      for (var at = DigestSchedule.minHour;
                          at <= DigestSchedule.maxHour;
                          at++)
                        DropdownMenuItem(
                          value: at,
                          child: Text(DigestSchedule.hourLabel(at)),
                        ),
                    ],
                    onChanged: state.isBusy
                        ? null
                        : (picked) => set(day: day, hour: picked ?? hour),
                  ),
                ),
              ],
            ),
          ),
        if (state.isPermissionDenied)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KithSpacing.md,
              0,
              KithSpacing.md,
              KithSpacing.sm,
            ),
            child: Text(
              'Notifications are switched off for Kith. Turn them on in your '
              'phone settings, then try again.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        if (state.failure case final failure?)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              KithSpacing.md,
              0,
              KithSpacing.md,
              KithSpacing.sm,
            ),
            child: Text(
              digestFailureMessage(failure),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

class _MemberList extends StatelessWidget {
  const _MemberList({required this.members});

  final List<Member> members;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: KithSpacing.md),
          child: Text(
            members.length == 1 ? '1 member' : '${members.length} members',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: KithSpacing.xs),
        for (final member in members)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              child: Text(_initialOf(member.displayName)),
            ),
            title: Text(member.displayName),
            subtitle: Text(member.email),
            trailing: member.role == MemberRole.owner
                ? const Chip(label: Text('Owner'))
                : null,
          ),
      ],
    );
  }

  /// First character of [name], for the avatar. Falls back to a placeholder
  /// rather than throwing on a name that is somehow empty.
  static String _initialOf(String name) =>
      name.isEmpty ? '?' : name.characters.first.toUpperCase();
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: KithSpacing.lg),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KithSpacing.md,
        vertical: KithSpacing.lg,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}
