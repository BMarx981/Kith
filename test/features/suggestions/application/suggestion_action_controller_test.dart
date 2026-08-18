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
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/suggestions/application/suggestion_action_controller.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';
import 'package:kith/features/suggestions/domain/snooze_horizon.dart';

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

  setUp(() {
    repository = FakePlannedHangoutRepository();
    addTearDown(repository.dispose);
  });

  ProviderContainer containerOf({AuthUser? signedIn = user}) {
    final container = ProviderContainer(
      overrides: [
        plannedHangoutRepositoryProvider.overrideWithValue(repository),
        currentUserProvider.overrideWithValue(signedIn),
        clockProvider.overrideWithValue(Clock.fixed(now)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  SuggestionActionController controllerOf(ProviderContainer container) =>
      container.read(suggestionActionControllerProvider.notifier);

  group('plan', () {
    test('stores an intent for the day given, credited to the member', ()
        async {
      final container = containerOf();

      final plan = await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        plannedFor: DateTime.utc(2026, 8, 25),
      );

      expect(plan?.plannedFor, DateTime.utc(2026, 8, 25));
      expect(plan?.status, PlannedHangoutStatus.proposed);
      expect(repository.planCalls.single.createdBy, 'uid-1');
      expect(repository.planCalls.single.contactIds, ['cid-1']);
      expect(repository.planCalls.single.householdId, householdId);
    });

    test('comes back clean once the write lands', () async {
      final container = containerOf();

      await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
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

      final plan = await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        plannedFor: DateTime.utc(2026, 8, 25),
      );

      expect(plan, isNull);
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

      final plan = await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        plannedFor: DateTime.utc(2026, 8, 25),
      );

      expect(plan, isNull);
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
        plannedFor: DateTime.utc(2026, 8, 25),
      );
      repository.gate!.complete();

      expect(second, isNull);
      expect(await first, isA<PlannedHangout>());
      expect(repository.planCalls, hasLength(1));
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
      final plan = await controllerOf(container).plan(
        householdId: householdId,
        contactId: 'cid-1',
        plannedFor: DateTime.utc(2026, 8, 25),
      );

      final undone = await controllerOf(container).cancel(
        householdId: householdId,
        plannedHangoutId: plan!.id,
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
        plannedHangoutId: 'pid-1',
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
        plannedHangoutId: 'pid-1',
      );
      await pumpEventQueue();

      final second = await controllerOf(container).cancel(
        householdId: householdId,
        plannedHangoutId: 'pid-1',
      );
      repository.gate!.complete();
      await pending;

      expect(second, isFalse);
      expect(repository.cancelCalls, hasLength(1));
    });
  });
}
