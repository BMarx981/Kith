import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/models/planned_hangout_status.dart';
import 'package:kith/data/services/calendar_sink.dart';
import 'package:kith/features/calendar/application/calendar_providers.dart';
import 'package:kith/features/calendar/application/calendar_sync_controller.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';

import '../../../helpers/fake_calendar_sink.dart';
import '../../../helpers/fake_planned_hangout_repository.dart';

void main() {
  const householdId = 'hid-1';
  final now = DateTime.utc(2026, 8, 18);
  final nextWeek = DateTime.utc(2026, 8, 25);

  late FakeCalendarSink sink;
  late FakePlannedHangoutRepository plans;

  setUp(() {
    sink = FakeCalendarSink();
    plans = FakePlannedHangoutRepository();
    addTearDown(plans.dispose);
  });

  void seedConfirmedPlan({String eventId = 'evt_1'}) => plans.seed(
    PlannedHangout(
      id: 'pid-1',
      plannedFor: nextWeek,
      contactIds: const ['cid-1'],
      status: PlannedHangoutStatus.confirmed,
      createdBy: 'uid-1',
      createdAt: now,
      updatedAt: now,
      calendarEventId: eventId,
    ),
  );

  /// A container whose plans have arrived, the way the screen's own listener
  /// waits for before it asks for a pass.
  Future<ProviderContainer> containerOf({
    String? household = householdId,
    String? calendarId = 'cal-1',
  }) async {
    final container = ProviderContainer(
      overrides: [
        plannedHangoutRepositoryProvider.overrideWithValue(plans),
        calendarSinkProvider.overrideWithValue(sink),
        currentHouseholdIdProvider.overrideWithValue(household),
        clockProvider.overrideWithValue(Clock.fixed(now)),
        if (household != null)
          householdCalendarIdProvider(household).overrideWithValue(calendarId),
      ],
    );
    addTearDown(container.dispose);
    if (household != null) {
      container.listen(plannedHangoutsProvider(household), (_, _) {});
      await container.read(plannedHangoutsProvider(household).future);
    }
    return container;
  }

  group('syncNow', () {
    test('reconciles the household plans against its calendar', () async {
      seedConfirmedPlan();
      final container = await containerOf();

      await container.read(calendarSyncControllerProvider.notifier).syncNow();

      expect(sink.fetchCalls.single.calendarId, 'cal-1');
      expect(plans.plans, isEmpty);
    });

    test('does nothing without a household', () async {
      seedConfirmedPlan();
      final container = await containerOf(household: null);

      await container.read(calendarSyncControllerProvider.notifier).syncNow();

      expect(sink.fetchCalls, isEmpty);
    });

    test('does nothing without a linked calendar', () async {
      seedConfirmedPlan();
      final container = await containerOf(calendarId: null);

      await container.read(calendarSyncControllerProvider.notifier).syncNow();

      expect(sink.fetchCalls, isEmpty);
    });

    test('holds what stopped the last pass', () async {
      seedConfirmedPlan();
      sink.fetchFailure = const NetworkFailure('offline');
      final container = await containerOf();

      await container.read(calendarSyncControllerProvider.notifier).syncNow();

      final state = container.read(calendarSyncControllerProvider);
      expect(state.failure, isA<NetworkFailure>());
      expect(state.isSyncing, isFalse);
    });

    test('clears the failure once a pass comes back clean', () async {
      seedConfirmedPlan();
      sink
        ..seed(CalendarEvent(id: 'evt_1', title: 'Marcus', day: nextWeek))
        ..fetchFailure = const NetworkFailure('offline');
      final container = await containerOf();
      final controller = container.read(
        calendarSyncControllerProvider.notifier,
      );
      await controller.syncNow();

      sink.fetchFailure = null;
      await controller.syncNow();

      expect(container.read(calendarSyncControllerProvider).failure, isNull);
    });

    test('will not run two passes over the same plans at once', () async {
      seedConfirmedPlan();
      final gate = Completer<void>();
      plans.gate = gate;
      final container = await containerOf();
      final controller = container.read(
        calendarSyncControllerProvider.notifier,
      );

      final first = controller.syncNow();
      await pumpEventQueue();
      expect(container.read(calendarSyncControllerProvider).isSyncing, isTrue);
      await controller.syncNow();
      gate.complete();
      await first;


      expect(sink.fetchCalls, hasLength(1));
    });
  });
}
