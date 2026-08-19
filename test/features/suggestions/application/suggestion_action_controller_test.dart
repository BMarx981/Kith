import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/models/planned_hangout_status.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/calendar/application/calendar_providers.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/suggestions/application/suggestion_action_controller.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';
import 'package:kith/features/suggestions/domain/snooze_horizon.dart';

import '../../../helpers/fake_calendar_sink.dart';
import '../../../helpers/fake_planned_hangout_repository.dart';

void main() {
  const householdId = 'hid-1';
  const user = AuthUser(id: 'uid-1', email: 'brian@example.com');
  final now = DateTime.utc(2026, 8, 18, 14);

  final contact = Contact(
    id: 'cid-1',
    name: 'Marcus Bell',
    relationshipTypeId: 'rid-1',
    cadence: Cadence.monthly,
    priority: ContactPriority.normal,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  late FakePlannedHangoutRepository repository;
  late FakeCalendarSink sink;

  setUp(() {
    repository = FakePlannedHangoutRepository();
    sink = FakeCalendarSink();
    addTearDown(repository.dispose);
  });

  /// A container whose household has no calendar linked unless [calendarId]
  /// says otherwise, which is the state every household starts in.
  ProviderContainer containerOf({
    AuthUser? signedIn = user,
    String? calendarId,
  }) {
    final container = ProviderContainer(
      overrides: [
        plannedHangoutRepositoryProvider.overrideWithValue(repository),
        currentUserProvider.overrideWithValue(signedIn),
        clockProvider.overrideWithValue(Clock.fixed(now)),
        calendarSinkProvider.overrideWithValue(sink),
        householdCalendarIdProvider(householdId).overrideWithValue(calendarId),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  SuggestionActionController controllerOf(ProviderContainer container) =>
      container.read(suggestionActionControllerProvider.notifier);

  /// A plan that is not on any calendar, for the cancels that never made one.
  PlannedHangout planFor(String id) => PlannedHangout(
    id: id,
    plannedFor: DateTime.utc(2026, 8, 25),
    contactIds: const ['cid-1'],
    status: PlannedHangoutStatus.proposed,
    createdBy: user.id,
    createdAt: now,
    updatedAt: now,
  );

  group('plan', () {
    test('stores an intent for the day given, credited to the member', ()
        async {
      final container = containerOf();

      final outcome = await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        title: 'Marcus Bell',
        plannedFor: DateTime.utc(2026, 8, 25),
      );

      expect(outcome?.plan.plannedFor, DateTime.utc(2026, 8, 25));
      expect(outcome?.plan.status, PlannedHangoutStatus.proposed);
      expect(repository.planCalls.single.createdBy, 'uid-1');
      expect(repository.planCalls.single.contactIds, ['cid-1']);
      expect(repository.planCalls.single.householdId, householdId);
    });

    test('comes back clean once the write lands', () async {
      final container = containerOf();

      await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        title: 'Marcus Bell',
        plannedFor: DateTime.utc(2026, 8, 25),
      );

      expect(
        container.read(suggestionActionControllerProvider).isSubmitting,
        isFalse,
      );
      expect(
        container.read(suggestionActionControllerProvider).failure,
        isNull,
      );
    });

    test('holds the failure and nothing else when the write is refused', ()
        async {
      final container = containerOf();
      repository.nextFailure = const NetworkFailure('offline');

      final outcome = await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        title: 'Marcus Bell',
        plannedFor: DateTime.utc(2026, 8, 25),
      );

      expect(outcome, isNull);
      expect(
        container.read(suggestionActionControllerProvider).failure,
        isA<NetworkFailure>(),
      );
      expect(
        container.read(suggestionActionControllerProvider).isSubmitting,
        isFalse,
      );
    });

    test('refuses to write with nobody signed in', () async {
      final container = containerOf(signedIn: null);

      final outcome = await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        title: 'Marcus Bell',
        plannedFor: DateTime.utc(2026, 8, 25),
      );

      expect(outcome, isNull);
      expect(repository.planCalls, isEmpty);
      expect(
        container.read(suggestionActionControllerProvider).failure,
        isA<AuthFailure>(),
      );
    });

    test('is inert while a write is in flight, so a double tap plans once', ()
        async {
      final container = containerOf();
      repository.gate = Completer<void>();

      final first = controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        title: 'Marcus Bell',
        plannedFor: DateTime.utc(2026, 8, 25),
      );
      await pumpEventQueue();
      expect(
        container.read(suggestionActionControllerProvider).isSubmitting,
        isTrue,
      );

      final second = await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        title: 'Marcus Bell',
        plannedFor: DateTime.utc(2026, 8, 25),
      );
      repository.gate!.complete();

      expect(second, isNull);
      expect((await first)?.plan, isA<PlannedHangout>());
      expect(repository.planCalls, hasLength(1));
    });

    test('writes nothing to a calendar the household has not linked', ()
        async {
      final container = containerOf();

      final outcome = await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        title: 'Marcus Bell',
        plannedFor: DateTime.utc(2026, 8, 25),
      );

      expect(outcome?.isOnCalendar, isFalse);
      expect(outcome?.calendarFailure, isNull);
      expect(sink.createCalls, isEmpty);
    });

    test('puts the plan on a linked calendar, named for the contact', ()
        async {
      final container = containerOf(calendarId: 'cal-1');

      final outcome = await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        title: 'Marcus Bell',
        plannedFor: DateTime.utc(2026, 8, 25),
      );

      expect(outcome?.isOnCalendar, isTrue);
      expect(sink.createCalls.single.calendarId, 'cal-1');
      expect(sink.createCalls.single.title, 'Marcus Bell');
      expect(sink.createCalls.single.day, DateTime.utc(2026, 8, 25));
      expect(
        repository.plans[outcome!.plan.id]?.status,
        PlannedHangoutStatus.confirmed,
      );
    });

    test('keeps the plan when the calendar refuses the event', () async {
      final container = containerOf(calendarId: 'cal-1');
      sink.createFailure = const PermissionFailure('no access');

      final outcome = await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        title: 'Marcus Bell',
        plannedFor: DateTime.utc(2026, 8, 25),
      );

      expect(outcome?.plan, isNotNull);
      expect(outcome?.isOnCalendar, isFalse);
      expect(outcome?.calendarFailure, isA<PermissionFailure>());
      expect(
        repository.plans[outcome!.plan.id]?.status,
        PlannedHangoutStatus.proposed,
      );
    });

    test('leaves the card clean when only the calendar failed', () async {
      final container = containerOf(calendarId: 'cal-1');
      sink.createFailure = const NetworkFailure('offline');

      await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        title: 'Marcus Bell',
        plannedFor: DateTime.utc(2026, 8, 25),
      );

      // The arrangement stands, so the card is not left holding an error
      // about it; what the calendar did is on the outcome instead.
      expect(
        container.read(suggestionActionControllerProvider).failure,
        isNull,
      );
    });
  });

  group('snooze', () {
    test('defers by a week off the clock, not off the plan date', () async {
      final container = containerOf();

      final plan = await controllerOf(container).snooze(
        householdId: householdId,
        contact: contact,
        horizon: SnoozeHorizon.week,
      );

      expect(plan?.plannedFor, DateTime.utc(2026, 8, 25));
      expect(plan?.status, PlannedHangoutStatus.snoozed);
      expect(repository.snoozeCalls.single.until, DateTime.utc(2026, 8, 25));
    });

    test("defers a dismissal by the contact's own cadence", () async {
      final container = containerOf();

      final plan = await controllerOf(container).snooze(
        householdId: householdId,
        contact: contact,
        horizon: SnoozeHorizon.fullCadence,
      );

      expect(plan?.plannedFor, DateTime.utc(2026, 9, 17));
    });

    test('reports a refusal without storing anything', () async {
      final container = containerOf();
      repository.nextFailure = const PermissionFailure('not a member');

      final plan = await controllerOf(container).snooze(
        householdId: householdId,
        contact: contact,
        horizon: SnoozeHorizon.week,
      );

      expect(plan, isNull);
      expect(repository.plans, isEmpty);
      expect(
        container.read(suggestionActionControllerProvider).failure,
        isA<PermissionFailure>(),
      );
    });
  });

  group('cancel', () {
    test('drops the plan and clears the state', () async {
      final container = containerOf();
      final outcome = await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        title: 'Marcus Bell',
        plannedFor: DateTime.utc(2026, 8, 25),
      );

      final undone = await controllerOf(container).cancel(
        householdId: householdId,
        plan: outcome!.plan,
      );

      expect(undone, isTrue);
      expect(repository.plans, isEmpty);
      expect(
        container.read(suggestionActionControllerProvider).failure,
        isNull,
      );
    });

    test('reports a refusal and keeps the failure', () async {
      final container = containerOf();
      repository.nextFailure = const NotFoundFailure('gone');

      final undone = await controllerOf(container).cancel(
        householdId: householdId,
        plan: planFor('pid-1'),
      );

      expect(undone, isFalse);
      expect(
        container.read(suggestionActionControllerProvider).failure,
        isA<NotFoundFailure>(),
      );
    });

    test('is inert while a write is in flight', () async {
      final container = containerOf();
      repository.gate = Completer<void>();
      final pending = controllerOf(container).cancel(
        householdId: householdId,
        plan: planFor('pid-1'),
      );
      await pumpEventQueue();

      final second = await controllerOf(container).cancel(
        householdId: householdId,
        plan: planFor('pid-1'),
      );
      repository.gate!.complete();
      await pending;

      expect(second, isFalse);
      expect(repository.cancelCalls, hasLength(1));
    });

    test('takes the event off the calendar before dropping the plan', ()
        async {
      final container = containerOf(calendarId: 'cal-1');
      final outcome = await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        title: 'Marcus Bell',
        plannedFor: DateTime.utc(2026, 8, 25),
      );

      final undone = await controllerOf(container).cancel(
        householdId: householdId,
        plan: repository.plans[outcome!.plan.id]!,
      );

      expect(undone, isTrue);
      expect(sink.events, isEmpty);
      expect(repository.plans, isEmpty);
    });

    test('still drops the plan when the event will not come off', () async {
      final container = containerOf(calendarId: 'cal-1');
      final outcome = await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        title: 'Marcus Bell',
        plannedFor: DateTime.utc(2026, 8, 25),
      );
      sink.deleteFailure = const NetworkFailure('offline');

      final undone = await controllerOf(container).cancel(
        householdId: householdId,
        plan: repository.plans[outcome!.plan.id]!,
      );

      expect(undone, isTrue);
      expect(repository.plans, isEmpty);
      // A plan that will not go away is worse than an event the household can
      // delete themselves, so the refusal is reported rather than obeyed.
      expect(
        container.read(suggestionActionControllerProvider).failure,
        isA<NetworkFailure>(),
      );
    });
  });
}
