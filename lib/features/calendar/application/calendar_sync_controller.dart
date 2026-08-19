import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/calendar/application/calendar_providers.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';

/// Whether a reconciliation pass is running, and why the last one stopped.
@immutable
class CalendarSyncState {
  const CalendarSyncState({this.isSyncing = false, this.failure});

  /// Whether a pass is in flight.
  final bool isSyncing;

  /// Why the last pass could not finish, or null if it was clean or has not
  /// run. A permission failure here is the one worth showing: it means this
  /// member's grant no longer covers the household's calendar.
  final Failure? failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarSyncState &&
          other.isSyncing == isSyncing &&
          other.failure == failure;

  @override
  int get hashCode => Object.hash(isSyncing, failure);

  @override
  String toString() =>
      'CalendarSyncState(isSyncing: $isSyncing, failure: $failure)';
}

/// Runs the calendar poll, and holds what it found.
///
/// The poll is what stands in for a webhook: Google will not tell Kith that an
/// event was moved or deleted, so the app asks when it opens and when it comes
/// back to the foreground. Nothing else triggers it — a plan changed inside
/// Kith is written to the calendar there and then.
class CalendarSyncController extends Notifier<CalendarSyncState> {
  @override
  CalendarSyncState build() => const CalendarSyncState();

  /// Brings the household's plans into line with its calendar.
  ///
  /// Does nothing without a household, without a linked calendar, or while a
  /// pass is already running: resuming the app twice in a second should not
  /// mean two passes racing each other over the same plans.
  Future<void> syncNow() async {
    if (state.isSyncing) return;

    final householdId = ref.read(currentHouseholdIdProvider);
    if (householdId == null) return;
    final calendarId = ref.read(householdCalendarIdProvider(householdId));
    if (calendarId == null) return;
    final plans = ref.read(plannedHangoutsProvider(householdId)).value;
    if (plans == null) return;

    state = const CalendarSyncState(isSyncing: true);
    final report = await ref
        .read(calendarSyncServiceProvider)
        .reconcile(
          householdId: householdId,
          calendarId: calendarId,
          plans: plans,
          now: ref.read(clockProvider).now(),
        );
    state = CalendarSyncState(failure: report.failure);
  }
}

/// State of the calendar poll.
final calendarSyncControllerProvider =
    NotifierProvider<CalendarSyncController, CalendarSyncState>(
      CalendarSyncController.new,
    );
