import 'dart:math';

import 'package:clock/clock.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/household.dart';
import 'package:kith/data/repositories/firestore_household_repository.dart';
import 'package:kith/features/household/application/household_providers.dart';

void main() {
  const owner = AuthUser(id: 'uid-owner', email: 'brian@example.com');
  final now = DateTime.utc(2026, 8, 16, 12);

  late FakeFirebaseFirestore firestore;
  late FirestoreHouseholdRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreHouseholdRepository(
      firestore,
      Random(1),
      Clock.fixed(now),
    );
  });

  ProviderContainer harness() {
    final container = ProviderContainer(
      overrides: [householdRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Subscribes before awaiting the first value. A stream provider only runs
  /// while something listens to it, so reading `.future` on its own would
  /// wait forever.
  Future<T> firstValueOf<T>(
    ProviderContainer container,
    StreamProvider<T> provider,
  ) {
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    return container.read(provider.future);
  }

  Future<Household> seedHousehold() async {
    final result = await repository.createHousehold(
      name: 'The Marx house',
      owner: owner,
      displayName: 'Brian',
    );
    return result.valueOrNull!;
  }

  group('householdRepositoryProvider', () {
    test('throws when read without an override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(householdRepositoryProvider),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.exception,
            'exception',
            isA<UnimplementedError>(),
          ),
        ),
      );
    });

    test('yields the overridden repository', () {
      final container = harness();

      expect(container.read(householdRepositoryProvider), same(repository));
    });
  });

  group('householdProvider', () {
    test('emits the household it is asked for', () async {
      final household = await seedHousehold();
      final container = harness();

      await expectLater(
        firstValueOf(container, householdProvider(household.id)),
        completion(household),
      );
    });

    test('emits null for a household that does not exist', () async {
      final container = harness();

      await expectLater(
        firstValueOf(container, householdProvider('nope')),
        completion(isNull),
      );
    });
  });

  group('householdMembersProvider', () {
    test('emits the household members', () async {
      final household = await seedHousehold();
      final container = harness();

      final members = await firstValueOf(
        container,
        householdMembersProvider(household.id),
      );

      expect(members.map((member) => member.id), [owner.id]);
    });

    test('emits an empty list for a household with no members', () async {
      final container = harness();

      await expectLater(
        firstValueOf(container, householdMembersProvider('nope')),
        completion(isEmpty),
      );
    });
  });
}
