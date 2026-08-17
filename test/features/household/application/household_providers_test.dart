import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/household.dart';
import 'package:kith/data/repositories/firestore_household_repository.dart';
import 'package:kith/data/services/auth_service.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_auth_service.dart';

class _MockAuthService extends Mock implements AuthService {}

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

  ProviderContainer harness({AuthService? auth}) {
    final container = ProviderContainer(
      overrides: [
        householdRepositoryProvider.overrideWithValue(repository),
        if (auth != null) authServiceProvider.overrideWithValue(auth),
      ],
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

  group('householdIdsProvider', () {
    /// A signed-in session for [user], torn down with the test.
    FakeAuthService signedInAs(AuthUser user) {
      final auth = FakeAuthService(initialUser: user);
      addTearDown(auth.dispose);
      return auth;
    }

    test('emits the household the signed-in user belongs to', () async {
      final household = await seedHousehold();
      final container = harness(auth: signedInAs(owner));

      await expectLater(
        firstValueOf(container, householdIdsProvider),
        completion([household.id]),
      );
    });

    test('emits an empty list for a user in no household', () async {
      await seedHousehold();
      final container = harness(
        auth: signedInAs(const AuthUser(id: 'uid-new', email: 'new@x.com')),
      );

      await expectLater(
        firstValueOf(container, householdIdsProvider),
        completion(isEmpty),
      );
    });

    test('emits an empty list when nobody is signed in', () async {
      await seedHousehold();
      final auth = FakeAuthService();
      addTearDown(auth.dispose);
      final container = harness(auth: auth);

      await expectLater(
        firstValueOf(container, householdIdsProvider),
        completion(isEmpty),
      );
    });

    test('stays loading until auth has reported', () async {
      // The distinction the household guard depends on: "not known yet" must
      // not read as "belongs to no household", or a cold start with a stored
      // session would land the user in onboarding.
      final auth = _MockAuthService();
      final controller = StreamController<AuthUser?>();
      addTearDown(controller.close);
      when(auth.authStateChanges).thenAnswer((_) => controller.stream);
      final container = harness(auth: auth);

      final subscription = container.listen(householdIdsProvider, (_, _) {});
      addTearDown(subscription.close);
      await pumpEventQueue();

      expect(container.read(householdIdsProvider).isLoading, isTrue);

      // Let auth report before the container goes away, so the provider is
      // not still mid-await when the test tears down.
      controller.add(null);
      await pumpEventQueue();
    });

    test('follows the user who signs in', () async {
      final household = await seedHousehold();
      final auth = FakeAuthService();
      addTearDown(auth.dispose);
      auth.seedAccount(email: 'brian@example.com', password: 'hunter2hunter2');
      final container = harness(auth: auth);

      expect(await firstValueOf(container, householdIdsProvider), isEmpty);

      // The seeded account gets its own uid, so the membership that belongs to
      // it is written after the fact.
      final signedIn = await auth.signInWithEmail(
        email: 'brian@example.com',
        password: 'hunter2hunter2',
      );
      await repository.joinWithInviteCode(
        code: household.inviteCode!.value,
        user: signedIn.valueOrNull!,
        displayName: 'Brian',
      );
      await pumpEventQueue();

      await expectLater(
        container.read(householdIdsProvider.future),
        completion([household.id]),
      );
    });
  });

  group('currentHouseholdIdProvider', () {
    test('is the household the user belongs to', () async {
      final household = await seedHousehold();
      final auth = FakeAuthService(initialUser: owner);
      addTearDown(auth.dispose);
      final container = harness(auth: auth);
      await firstValueOf(container, householdIdsProvider);

      expect(container.read(currentHouseholdIdProvider), household.id);
    });

    test('is null while the membership is still unknown', () async {
      final auth = FakeAuthService(initialUser: owner);
      addTearDown(auth.dispose);
      final container = harness(auth: auth);

      expect(container.read(currentHouseholdIdProvider), isNull);

      await pumpEventQueue();
    });

    test('is null for a user in no household', () async {
      final auth = FakeAuthService(initialUser: owner);
      addTearDown(auth.dispose);
      final container = harness(auth: auth);
      await firstValueOf(container, householdIdsProvider);

      expect(container.read(currentHouseholdIdProvider), isNull);
    });
  });
}
