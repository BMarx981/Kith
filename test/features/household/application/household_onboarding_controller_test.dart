import 'dart:math';

import 'package:clock/clock.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/household.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/data/repositories/firestore_household_repository.dart';
import 'package:kith/data/repositories/firestore_relationship_type_repository.dart';
import 'package:kith/data/repositories/household_repository.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/household/application/household_onboarding_controller.dart';
import 'package:kith/features/household/application/household_onboarding_state.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/fake_relationship_type_repository.dart';

class _MockHouseholdRepository extends Mock implements HouseholdRepository {}

void main() {
  const user = AuthUser(id: 'uid-owner', email: 'brian@example.com');
  final now = DateTime.utc(2026, 8, 17, 12);
  final household = Household(
    id: 'hid-1',
    name: 'The Marx house',
    inviteCode: null,
    createdAt: now,
    createdBy: user.id,
  );

  late _MockHouseholdRepository repository;
  late FakeRelationshipTypeRepository labels;
  late FakeAuthService auth;

  setUp(() {
    repository = _MockHouseholdRepository();
    labels = FakeRelationshipTypeRepository();
    addTearDown(labels.dispose);
    auth = FakeAuthService(initialUser: user);
    addTearDown(auth.dispose);
    when(() => repository.watchHouseholdIdsFor(any())).thenAnswer(
      (_) => Stream.value(const []),
    );
  });

  ProviderContainer harness() {
    final container = ProviderContainer(
      overrides: [
        householdRepositoryProvider.overrideWithValue(repository),
        relationshipTypeRepositoryProvider.overrideWithValue(labels),
        authServiceProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  HouseholdOnboardingController controllerOf(ProviderContainer container) {
    final subscription = container.listen(
      householdOnboardingControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    return container.read(householdOnboardingControllerProvider.notifier);
  }

  HouseholdOnboardingState stateOf(ProviderContainer container) =>
      container.read(householdOnboardingControllerProvider);

  void whenCreateReturns(Result<Household> result) {
    when(
      () => repository.createHousehold(
        name: any(named: 'name'),
        owner: any(named: 'owner'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => result);
  }

  void whenJoinReturns(Result<Household> result) {
    when(
      () => repository.joinWithInviteCode(
        code: any(named: 'code'),
        user: any(named: 'user'),
        displayName: any(named: 'displayName'),
      ),
    ).thenAnswer((_) async => result);
  }

  setUpAll(() {
    registerFallbackValue(user);
  });

  group('initial state', () {
    test('starts on the create form, idle', () {
      final container = harness();

      expect(stateOf(container), const HouseholdOnboardingState());
      expect(stateOf(container).mode, HouseholdOnboardingMode.create);
      expect(stateOf(container).isSubmitting, isFalse);
      expect(stateOf(container).failure, isNull);
    });
  });

  group('setMode', () {
    test('switches form and drops the previous failure', () async {
      whenCreateReturns(const Err(ValidationFailure('nope')));
      final container = harness();
      final controller = controllerOf(container);
      await controller.createHousehold(name: 'x', displayName: 'Brian');

      expect(stateOf(container).failure, isNotNull);

      controller.setMode(HouseholdOnboardingMode.join);

      expect(stateOf(container).mode, HouseholdOnboardingMode.join);
      expect(stateOf(container).failure, isNull);
    });

    test('ignores a switch to the mode already showing', () {
      final container = harness();

      controllerOf(container).setMode(HouseholdOnboardingMode.create);

      expect(stateOf(container).mode, HouseholdOnboardingMode.create);
    });
  });

  group('createHousehold', () {
    test('creates it for the signed-in user', () async {
      whenCreateReturns(Ok(household));
      final container = harness();

      await controllerOf(
        container,
      ).createHousehold(name: 'The Marx house', displayName: 'Brian');

      verify(
        () => repository.createHousehold(
          name: 'The Marx house',
          owner: user,
          displayName: 'Brian',
        ),
      ).called(1);
      expect(stateOf(container).isSubmitting, isFalse);
      expect(stateOf(container).failure, isNull);
    });

    test('surfaces a refusal and stays on the form', () async {
      whenCreateReturns(const Err(ConflictFailure('no codes left')));
      final container = harness();

      await controllerOf(
        container,
      ).createHousehold(name: 'The Marx house', displayName: 'Brian');

      expect(
        stateOf(container).failure,
        const ConflictFailure('no codes left'),
      );
      expect(stateOf(container).isSubmitting, isFalse);
    });

    test('ignores a second submit while one is in flight', () async {
      whenCreateReturns(Ok(household));
      final container = harness();
      final controller = controllerOf(container);

      await Future.wait([
        controller.createHousehold(name: 'A', displayName: 'Brian'),
        controller.createHousehold(name: 'B', displayName: 'Brian'),
      ]);

      verify(
        () => repository.createHousehold(
          name: any(named: 'name'),
          owner: any(named: 'owner'),
          displayName: any(named: 'displayName'),
        ),
      ).called(1);
    });

    test('refuses when nobody is signed in', () async {
      await auth.signOut();
      final container = harness();

      await controllerOf(
        container,
      ).createHousehold(name: 'The Marx house', displayName: 'Brian');

      expect(stateOf(container).failure, isA<Failure>());
      verifyNever(
        () => repository.createHousehold(
          name: any(named: 'name'),
          owner: any(named: 'owner'),
          displayName: any(named: 'displayName'),
        ),
      );
    });
  });

  group('joinHousehold', () {
    test('joins with the code as typed', () async {
      whenJoinReturns(Ok(household));
      final container = harness();

      await controllerOf(
        container,
      ).joinHousehold(code: 'ABC123', displayName: 'Partner');

      verify(
        () => repository.joinWithInviteCode(
          code: 'ABC123',
          user: user,
          displayName: 'Partner',
        ),
      ).called(1);
      expect(stateOf(container).failure, isNull);
    });

    test('surfaces a code that matches no household', () async {
      whenJoinReturns(const Err(NotFoundFailure('no such code')));
      final container = harness();

      await controllerOf(
        container,
      ).joinHousehold(code: 'ABC123', displayName: 'Partner');

      expect(stateOf(container).failure, const NotFoundFailure('no such code'));
      expect(stateOf(container).isSubmitting, isFalse);
    });

    test('ignores a second submit while one is in flight', () async {
      whenJoinReturns(Ok(household));
      final container = harness();
      final controller = controllerOf(container);

      await Future.wait([
        controller.joinHousehold(code: 'ABC123', displayName: 'Partner'),
        controller.joinHousehold(code: 'ABC123', displayName: 'Partner'),
      ]);

      verify(
        () => repository.joinWithInviteCode(
          code: any(named: 'code'),
          user: any(named: 'user'),
          displayName: any(named: 'displayName'),
        ),
      ).called(1);
    });
  });

  group('membership after success', () {
    test('the new household is visible to the guard', () async {
      // The whole point of the flow: once this returns, the household guard
      // must see a membership. Runs against the Firestore-backed repository
      // because that is what makes the membership real.
      final firestore = FakeFirebaseFirestore();
      final real = FirestoreHouseholdRepository(
        firestore,
        Random(1),
        Clock.fixed(now),
      );
      final container = ProviderContainer(
        overrides: [
          householdRepositoryProvider.overrideWithValue(real),
          relationshipTypeRepositoryProvider.overrideWithValue(
            FirestoreRelationshipTypeRepository(firestore, Clock.fixed(now)),
          ),
          authServiceProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(householdIdsProvider, (_, _) {});
      addTearDown(subscription.close);
      expect(await container.read(householdIdsProvider.future), isEmpty);

      await controllerOf(
        container,
      ).createHousehold(name: 'The Marx house', displayName: 'Brian');
      await pumpEventQueue();

      expect(await container.read(householdIdsProvider.future), hasLength(1));
    });

    test('a new household starts with the starter labels', () async {
      final firestore = FakeFirebaseFirestore();
      final labelRepository = FirestoreRelationshipTypeRepository(
        firestore,
        Clock.fixed(now),
      );
      final container = ProviderContainer(
        overrides: [
          householdRepositoryProvider.overrideWithValue(
            FirestoreHouseholdRepository(
              firestore,
              Random(1),
              Clock.fixed(now),
            ),
          ),
          relationshipTypeRepositoryProvider.overrideWithValue(labelRepository),
          authServiceProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(householdIdsProvider, (_, _) {});
      addTearDown(subscription.close);

      await controllerOf(
        container,
      ).createHousehold(name: 'The Marx house', displayName: 'Brian');
      await pumpEventQueue();

      final householdId = (await container.read(
        householdIdsProvider.future,
      )).single;
      expect(
        (await labelRepository.watchRelationshipTypes(householdId).first).map(
          (type) => type.name,
        ),
        orderedEquals(RelationshipType.defaultNames),
      );
    });

    test('joining a household does not seed labels over its own', () async {
      whenJoinReturns(Ok(household));
      final container = harness();

      await controllerOf(
        container,
      ).joinHousehold(code: 'ABC123', displayName: 'Partner');

      expect(labels.seedCalls, isEmpty);
    });
  });
}
