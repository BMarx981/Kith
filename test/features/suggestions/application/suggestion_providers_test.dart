import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/models/planned_hangout_status.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';

import '../../../helpers/fake_contact_repository.dart';
import '../../../helpers/fake_hangout_repository.dart';
import '../../../helpers/fake_planned_hangout_repository.dart';

void main() {
  const householdId = 'hid-1';
  final now = DateTime.utc(2026, 8, 18);

  late FakeContactRepository contacts;
  late FakeHangoutRepository hangouts;
  late FakePlannedHangoutRepository plans;

  setUp(() {
    contacts = FakeContactRepository();
    addTearDown(contacts.dispose);
    hangouts = FakeHangoutRepository();
    addTearDown(hangouts.dispose);
    plans = FakePlannedHangoutRepository();
    addTearDown(plans.dispose);
  });

  ProviderContainer containerOf() {
    final container = ProviderContainer(
      overrides: [
        contactRepositoryProvider.overrideWithValue(contacts),
        hangoutRepositoryProvider.overrideWithValue(hangouts),
        plannedHangoutRepositoryProvider.overrideWithValue(plans),
        clockProvider.overrideWithValue(Clock.fixed(now)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Lets the fakes' streams deliver into the providers before they are read.
  Future<void> settle() => pumpEventQueue();

  /// Keeps every stream the ranking derives from alive for the test's
  /// duration. A stream provider only runs while something listens.
  void listenAll(ProviderContainer container) {
    for (final subscription in [
      container.listen(contactsProvider(householdId), (_, _) {}),
      container.listen(hangoutsProvider(householdId), (_, _) {}),
      container.listen(plannedHangoutsProvider(householdId), (_, _) {}),
      container.listen(suggestionsProvider(householdId), (_, _) {}),
    ]) {
      addTearDown(subscription.close);
    }
  }

  Contact person(String id, {Cadence cadence = Cadence.monthly}) => Contact(
    id: id,
    name: id.toUpperCase(),
    relationshipTypeId: 'rid-1',
    cadence: cadence,
    priority: ContactPriority.normal,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  void seenDaysAgo(String contactId, int days) => hangouts.seed(
    Hangout(
      id: 'hgid-$contactId',
      occurredOn: now.subtract(Duration(days: days)),
      contactIds: [contactId],
      attendeeIds: const ['uid-1'],
      createdBy: 'uid-1',
      createdAt: now,
      updatedAt: now,
    ),
  );

  PlannedHangout plan(
    String id, {
    required List<String> contactIds,
    required int inDays,
    PlannedHangoutStatus status = PlannedHangoutStatus.proposed,
  }) => PlannedHangout(
    id: id,
    plannedFor: now.add(Duration(days: inDays)),
    contactIds: contactIds,
    status: status,
    createdBy: 'uid-1',
    createdAt: now,
    updatedAt: now,
  );

  group('plannedHangoutRepositoryProvider', () {
    test('throws until the composition root overrides it', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(plannedHangoutRepositoryProvider),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.exception,
            'exception',
            isA<UnimplementedError>(),
          ),
        ),
      );
    });
  });

  group('plannedHangoutsProvider', () {
    test('emits the household plans', () async {
      plans.seed(plan('pid-1', contactIds: const ['cid-1'], inDays: 3));
      final container = containerOf();
      listenAll(container);
      await settle();

      expect(
        container.read(plannedHangoutsProvider(householdId)).value,
        hasLength(1),
      );
    });
  });

  group('contactPlansProvider', () {
    test('narrows the list to one contact', () async {
      plans
        ..seed(plan('pid-1', contactIds: const ['cid-1', 'cid-2'], inDays: 3))
        ..seed(plan('pid-2', contactIds: const ['cid-2'], inDays: 9));
      final container = containerOf();
      listenAll(container);
      await settle();

      expect(
        container
            .read(
              contactPlansProvider((
                householdId: householdId,
                contactId: 'cid-1',
              )),
            )
            .map((plan) => plan.id),
        ['pid-1'],
      );
    });

    test('is empty while the plans are still loading', () {
      final container = containerOf();

      expect(
        container.read(
          contactPlansProvider((
            householdId: householdId,
            contactId: 'cid-1',
          )),
        ),
        isEmpty,
      );
    });
  });

  group('suggestionsProvider', () {
    test('ranks the household against the pinned clock', () async {
      contacts
        ..seed(person('cid-overdue'))
        ..seed(person('cid-fresh'))
        ..seed(person('cid-never'));
      seenDaysAgo('cid-overdue', 60);
      seenDaysAgo('cid-fresh', 2);
      final container = containerOf();
      listenAll(container);
      await settle();

      final suggestions = container.read(suggestionsProvider(householdId));

      expect(
        suggestions.map((s) => s.contact.id),
        orderedEquals(<String>['cid-overdue', 'cid-never']),
      );
      expect(suggestions.first.score, 2);
    });

    test('is empty until every stream it derives from has arrived', () {
      contacts.seed(person('cid-1'));
      final container = containerOf();

      expect(container.read(suggestionsProvider(householdId)), isEmpty);
    });

    test('re-ranks when a hangout is logged', () async {
      contacts.seed(person('cid-1'));
      seenDaysAgo('cid-1', 60);
      final container = containerOf();
      listenAll(container);
      await settle();
      expect(container.read(suggestionsProvider(householdId)), hasLength(1));

      hangouts.seed(
        Hangout(
          id: 'hgid-fresh',
          occurredOn: now,
          contactIds: const ['cid-1'],
          attendeeIds: const ['uid-1'],
          createdBy: 'uid-1',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await settle();

      expect(container.read(suggestionsProvider(householdId)), isEmpty);
    });

    test('re-ranks when the other partner makes a plan', () async {
      contacts.seed(person('cid-1'));
      seenDaysAgo('cid-1', 60);
      final container = containerOf();
      listenAll(container);
      await settle();

      plans.seed(
        plan(
          'pid-1',
          contactIds: const ['cid-1'],
          inDays: 5,
          status: PlannedHangoutStatus.snoozed,
        ),
      );
      await settle();

      expect(container.read(suggestionsProvider(householdId)), isEmpty);
    });
  });
}
