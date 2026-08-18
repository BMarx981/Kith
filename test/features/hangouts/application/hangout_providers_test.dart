import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/hangouts/domain/freshness.dart';
import 'package:kith/features/hangouts/domain/freshness_index.dart';

import '../../../helpers/fake_hangout_repository.dart';

void main() {
  const householdId = 'hid-1';
  final now = DateTime.utc(2026, 8, 18);

  late FakeHangoutRepository repository;

  setUp(() {
    repository = FakeHangoutRepository();
    addTearDown(repository.dispose);
  });

  ProviderContainer containerOf() {
    final container = ProviderContainer(
      overrides: [
        hangoutRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(Clock.fixed(now)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Lets the fake's stream deliver into the provider before it is read.
  Future<void> settle() => pumpEventQueue();

  /// Subscribes before awaiting the first value. A stream provider only runs
  /// while something listens to it, so reading `.future` on its own would
  /// wait forever.
  Future<List<Hangout>> firstTimelineOf(ProviderContainer container) {
    final subscription = container.listen(
      hangoutsProvider(householdId),
      (_, _) {},
    );
    addTearDown(subscription.close);
    return container.read(hangoutsProvider(householdId).future);
  }

  Hangout hangout(String id, DateTime on, List<String> contactIds) => Hangout(
    id: id,
    occurredOn: on,
    contactIds: contactIds,
    attendeeIds: const ['uid-1'],
    createdBy: 'uid-1',
    createdAt: now,
    updatedAt: now,
  );

  Contact contact(String id, {Cadence cadence = Cadence.monthly}) => Contact(
    id: id,
    name: id,
    relationshipTypeId: 'rid-1',
    cadence: cadence,
    priority: ContactPriority.normal,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  test('hangoutRepositoryProvider throws until it is overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(hangoutRepositoryProvider),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.exception,
          'exception',
          isUnimplementedError,
        ),
      ),
    );
  });

  group('hangoutsProvider', () {
    test('streams the household timeline', () async {
      repository.seed(hangout('hgid-1', DateTime.utc(2026, 8, 12), ['cid-1']));
      final container = containerOf();

      final timeline = await firstTimelineOf(container);

      expect(timeline, hasLength(1));
      expect(timeline.single.id, 'hgid-1');
    });

    test('surfaces a stream failure as an AsyncError', () async {
      repository.streamFailure = const PermissionFailure('nope');
      final container = containerOf();
      final subscription = container.listen(
        hangoutsProvider(householdId),
        (_, _) {},
      );
      addTearDown(subscription.close);

      await settle();

      expect(subscription.read().error, isA<PermissionFailure>());
    });
  });

  group('contactHangoutsProvider', () {
    test('keeps only the hangouts naming that contact', () async {
      repository
        ..seed(hangout('hgid-1', DateTime.utc(2026, 8, 12), ['cid-1', 'cid-2']))
        ..seed(hangout('hgid-2', DateTime.utc(2026, 8, 4), ['cid-2']));
      final container = containerOf();
      await firstTimelineOf(container);

      final history = container.read(
        contactHangoutsProvider((householdId: householdId, contactId: 'cid-1')),
      );

      expect([for (final h in history) h.id], ['hgid-1']);
    });

    test('is empty while the timeline is still loading', () {
      final container = containerOf();

      expect(
        container.read(
          contactHangoutsProvider((
            householdId: householdId,
            contactId: 'cid-1',
          )),
        ),
        isEmpty,
      );
    });
  });

  group('freshnessIndexProvider', () {
    test('is the empty index while the timeline is still loading', () {
      final container = containerOf();

      expect(
        container.read(freshnessIndexProvider(householdId)),
        FreshnessIndex.empty,
      );
    });

    test('measures every contact against the pinned clock', () async {
      repository.seed(hangout('hgid-1', DateTime.utc(2026, 8, 11), ['cid-1']));
      final container = containerOf();
      await firstTimelineOf(container);

      final index = container.read(freshnessIndexProvider(householdId));

      expect(index.now, now);
      expect(index.of(contact('cid-1')).daysSince, 7);
      expect(
        index.of(contact('cid-1', cadence: Cadence.weekly)).state,
        FreshnessState.due,
      );
    });

    test('moves when a hangout is logged', () async {
      final container = containerOf();
      final subscription = container.listen(
        freshnessIndexProvider(householdId),
        (_, _) {},
      );
      addTearDown(subscription.close);
      await settle();
      expect(
        subscription.read().of(contact('cid-1')).state,
        FreshnessState.never,
      );

      repository.seed(hangout('hgid-1', DateTime.utc(2026, 8, 17), ['cid-1']));
      await settle();

      expect(
        subscription.read().of(contact('cid-1')).state,
        FreshnessState.fresh,
      );
    });
  });
}
