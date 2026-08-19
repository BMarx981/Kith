import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/models/planned_hangout_status.dart';
import 'package:kith/data/services/calendar_sink.dart';
import 'package:kith/features/calendar/application/calendar_sync_service.dart';

import '../../../helpers/fake_calendar_sink.dart';
import '../../../helpers/fake_planned_hangout_repository.dart';

void main() {
  const householdId = 'hid-1';
  const calendarId = 'kith@group.calendar.google.com';
  final now = DateTime.utc(2026, 8, 18);
  final nextWeek = DateTime.utc(2026, 8, 25);

  late FakeCalendarSink sink;
  late FakePlannedHangoutRepository plans;
  late CalendarSyncService service;

  setUp(() {
    sink = FakeCalendarSink();
    plans = FakePlannedHangoutRepository();
    service = CalendarSyncService(sink: sink, plans: plans);
    addTearDown(plans.dispose);
  });

  PlannedHangout seedPlan({
    String id = 'pid-1',
    DateTime? plannedFor,
    String? calendarEventId,
    String? note,
    PlannedHangoutStatus status = PlannedHangoutStatus.proposed,
  }) {
    final plan = PlannedHangout(
      id: id,
      plannedFor: plannedFor ?? nextWeek,
      contactIds: const ['cid-1'],
      status: status,
      createdBy: 'uid-1',
      createdAt: now,
      updatedAt: now,
      note: note,
      calendarEventId: calendarEventId,
    );
    plans.seed(plan);
    return plan;
  }

  group('CalendarSyncReport', () {
    test('a clean pass changed nothing', () {
      const report = CalendarSyncReport(checked: 3);

      expect(report.changedAnything, isFalse);
      expect(report.failure, isNull);
    });

    test('counts either kind of change', () {
      expect(
        const CalendarSyncReport(rescheduled: 1).changedAnything,
        isTrue,
      );
      expect(const CalendarSyncReport(dropped: 1).changedAnything, isTrue);
    });

    test('toString names what the pass did', () {
      const report = CalendarSyncReport(
        checked: 2,
        rescheduled: 1,
        dropped: 1,
        failure: NetworkFailure('offline'),
      );

      expect(report.toString(), contains('checked: 2'));
      expect(report.toString(), contains('rescheduled: 1'));
      expect(report.toString(), contains('dropped: 1'));
      expect(report.toString(), contains('offline'));
    });
  });

  group('addPlanToCalendar', () {
    test('writes an all-day event for the day the plan names', () async {
      final plan = seedPlan(note: 'Dinner at ours');

      final result = await service.addPlanToCalendar(
        householdId: householdId,
        calendarId: calendarId,
        plan: plan,
        title: 'Marcus',
      );

      expect(result.valueOrNull?.title, 'Marcus');
      expect(sink.createCalls.single.calendarId, calendarId);
      expect(sink.createCalls.single.day, nextWeek);
      expect(sink.createCalls.single.note, 'Dinner at ours');
    });

    test('confirms the plan against the event it created', () async {
      final plan = seedPlan();

      await service.addPlanToCalendar(
        householdId: householdId,
        calendarId: calendarId,
        plan: plan,
        title: 'Marcus',
      );

      final stored = plans.plans[plan.id]!;
      expect(stored.status, PlannedHangoutStatus.confirmed);
      expect(stored.calendarEventId, sink.events.keys.single);
    });

    test('leaves the plan alone when the calendar refuses the write', () async {
      final plan = seedPlan();
      sink.createFailure = const PermissionFailure('no access');

      final result = await service.addPlanToCalendar(
        householdId: householdId,
        calendarId: calendarId,
        plan: plan,
        title: 'Marcus',
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(plans.plans[plan.id]?.status, PlannedHangoutStatus.proposed);
      expect(plans.plans[plan.id]?.calendarEventId, isNull);
    });

    test('takes the event back off when the plan cannot record it', () async {
      final plan = seedPlan();
      plans.nextFailure = const NetworkFailure('offline');

      final result = await service.addPlanToCalendar(
        householdId: householdId,
        calendarId: calendarId,
        plan: plan,
        title: 'Marcus',
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(sink.events, isEmpty);
      expect(sink.deleteCalls, hasLength(1));
    });
  });

  group('removePlanFromCalendar', () {
    test('takes the event off the calendar', () async {
      final plan = seedPlan(calendarEventId: 'evt_1');
      sink.seed(CalendarEvent(id: 'evt_1', title: 'Marcus', day: nextWeek));

      final result = await service.removePlanFromCalendar(
        calendarId: calendarId,
        plan: plan,
      );

      expect(result.isOk, isTrue);
      expect(sink.events, isEmpty);
    });

    test('has nothing to do for a plan that never reached one', () async {
      final plan = seedPlan();

      final result = await service.removePlanFromCalendar(
        calendarId: calendarId,
        plan: plan,
      );

      expect(result.isOk, isTrue);
      expect(sink.deleteCalls, isEmpty);
    });

    test('reports a refused delete', () async {
      final plan = seedPlan(calendarEventId: 'evt_1');
      sink.deleteFailure = const PermissionFailure('no access');

      final result = await service.removePlanFromCalendar(
        calendarId: calendarId,
        plan: plan,
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });

  group('reconcile', () {
    Future<CalendarSyncReport> reconcile() => service.reconcile(
      householdId: householdId,
      calendarId: calendarId,
      plans: plans.plans.values.toList(),
      now: now,
    );

    test('leaves a plan whose event still says the same day', () async {
      final plan = seedPlan(calendarEventId: 'evt_1');
      sink.seed(CalendarEvent(id: 'evt_1', title: 'Marcus', day: nextWeek));

      final report = await reconcile();

      expect(report.checked, 1);
      expect(report.changedAnything, isFalse);
      expect(plans.plans[plan.id], plan);
    });

    test('moves a plan whose event was dragged to another day', () async {
      final plan = seedPlan(calendarEventId: 'evt_1');
      sink.seed(
        CalendarEvent(
          id: 'evt_1',
          title: 'Marcus',
          day: DateTime.utc(2026, 8, 27),
        ),
      );

      final report = await reconcile();

      expect(report.rescheduled, 1);
      expect(plans.plans[plan.id]?.plannedFor, DateTime.utc(2026, 8, 27));
      expect(
        plans.rescheduleCalls.single.plannedFor,
        DateTime.utc(2026, 8, 27),
      );
    });

    test('drops a plan whose event was deleted from the calendar', () async {
      final plan = seedPlan(calendarEventId: 'evt_gone');

      final report = await reconcile();

      expect(report.dropped, 1);
      expect(plans.plans, isNot(contains(plan.id)));
    });

    test('ignores a plan that never went onto the calendar', () async {
      seedPlan();

      final report = await reconcile();

      expect(report.checked, 0);
      expect(sink.fetchCalls, isEmpty);
    });

    test('ignores a plan whose day has already gone by', () async {
      seedPlan(
        plannedFor: DateTime.utc(2026, 8, 17),
        calendarEventId: 'evt_1',
      );

      final report = await reconcile();

      expect(report.checked, 0);
      expect(sink.fetchCalls, isEmpty);
    });

    test('still checks a plan for today', () async {
      seedPlan(plannedFor: now, calendarEventId: 'evt_1');
      sink.seed(CalendarEvent(id: 'evt_1', title: 'Marcus', day: now));

      final report = await reconcile();

      expect(report.checked, 1);
    });

    test('keeps going after one event cannot be read', () async {
      seedPlan(calendarEventId: 'evt_1');
      seedPlan(id: 'pid-2', calendarEventId: 'evt_2');
      sink.fetchFailure = const NetworkFailure('offline');

      final report = await reconcile();

      expect(report.checked, 2);
      expect(report.failure, isA<NetworkFailure>());
    });

    test('reports the first failure and changes nothing on it', () async {
      seedPlan(calendarEventId: 'evt_1');
      sink.fetchFailure = const PermissionFailure('no access');

      final report = await reconcile();

      expect(report.failure, isA<PermissionFailure>());
      expect(report.changedAnything, isFalse);
    });

    test('reports a plan the household cannot be written to', () async {
      seedPlan(calendarEventId: 'evt_gone');
      plans.nextFailure = const PermissionFailure('not a member');

      final report = await reconcile();

      expect(report.dropped, 0);
      expect(report.failure, isA<PermissionFailure>());
    });

    test('asks about every plan on the calendar in one pass', () async {
      seedPlan(calendarEventId: 'evt_1');
      seedPlan(id: 'pid-2', calendarEventId: 'evt_2');
      seedPlan(id: 'pid-3');
      sink
        ..seed(CalendarEvent(id: 'evt_1', title: 'Marcus', day: nextWeek))
        ..seed(CalendarEvent(id: 'evt_2', title: 'Priya', day: nextWeek));

      final report = await reconcile();

      expect(report.checked, 2);
      expect(sink.fetchCalls.map((call) => call.eventId), [
        'evt_1',
        'evt_2',
      ]);
    });
  });
}
