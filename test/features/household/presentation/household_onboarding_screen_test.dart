import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/household/presentation/household_onboarding_screen.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/fake_household_repository.dart';
import '../../../helpers/fake_relationship_type_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  const user = AuthUser(id: 'uid-owner', email: 'brian@example.com');

  late FakeAuthService auth;
  late FakeHouseholdRepository repository;
  late FakeRelationshipTypeRepository labels;

  setUp(() {
    labels = FakeRelationshipTypeRepository();
    addTearDown(labels.dispose);
    auth = FakeAuthService(initialUser: user);
    addTearDown(auth.dispose);
    repository = FakeHouseholdRepository();
    addTearDown(repository.dispose);
  });

  List<Override> overrides() => [
    authServiceProvider.overrideWithValue(auth),
    householdRepositoryProvider.overrideWithValue(repository),
    relationshipTypeRepositoryProvider.overrideWithValue(labels),
  ];

  Future<void> pumpScreen(WidgetTester tester) => tester.pumpApp(
    const HouseholdOnboardingScreen(),
    overrides: overrides(),
  );

  Future<void> switchToJoin(WidgetTester tester) async {
    await tester.tap(find.byKey(HouseholdOnboardingScreen.modeToggleKey));
    await tester.pump();
  }

  Future<void> enterText(WidgetTester tester, Key key, String value) =>
      tester.enterText(find.byKey(key), value);

  group('HouseholdOnboardingScreen', () {
    testWidgets('opens on the create form', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Start a household'), findsOneWidget);
      expect(
        find.byKey(HouseholdOnboardingScreen.nameFieldKey),
        findsOneWidget,
      );
      expect(find.byKey(HouseholdOnboardingScreen.codeFieldKey), findsNothing);
    });

    testWidgets('swaps the name field for a code field', (tester) async {
      await pumpScreen(tester);

      await switchToJoin(tester);

      expect(find.text('Join a household'), findsOneWidget);
      expect(
        find.byKey(HouseholdOnboardingScreen.codeFieldKey),
        findsOneWidget,
      );
      expect(find.byKey(HouseholdOnboardingScreen.nameFieldKey), findsNothing);
    });

    testWidgets('creates a household from what was typed', (tester) async {
      await pumpScreen(tester);

      await enterText(
        tester,
        HouseholdOnboardingScreen.nameFieldKey,
        'The Marx house',
      );
      await enterText(
        tester,
        HouseholdOnboardingScreen.displayNameFieldKey,
        'Brian',
      );
      await tester.tap(find.byKey(HouseholdOnboardingScreen.submitButtonKey));
      await tester.pumpAndSettle();

      expect(repository.createCalls, [
        (name: 'The Marx house', owner: user, displayName: 'Brian'),
      ]);
    });

    testWidgets('joins with the code that was typed', (tester) async {
      await repository.createHousehold(
        name: 'The Marx house',
        owner: const AuthUser(id: 'uid-other', email: 'other@example.com'),
        displayName: 'Someone',
      );
      await pumpScreen(tester);
      await switchToJoin(tester);

      await enterText(
        tester,
        HouseholdOnboardingScreen.codeFieldKey,
        'kh7-rq2',
      );
      await enterText(
        tester,
        HouseholdOnboardingScreen.displayNameFieldKey,
        'Partner',
      );
      await tester.tap(find.byKey(HouseholdOnboardingScreen.submitButtonKey));
      await tester.pumpAndSettle();

      expect(repository.joinCalls, [
        (code: 'kh7-rq2', user: user, displayName: 'Partner'),
      ]);
    });

    testWidgets('will not submit an empty form', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(HouseholdOnboardingScreen.submitButtonKey));
      await tester.pump();

      expect(repository.createCalls, isEmpty);
      expect(find.text('Give the household a name.'), findsOneWidget);
      expect(find.text('Enter the name to show others.'), findsOneWidget);
    });

    testWidgets('judges the invite code before sending it', (tester) async {
      await pumpScreen(tester);
      await switchToJoin(tester);

      await enterText(tester, HouseholdOnboardingScreen.codeFieldKey, 'KH7');
      await enterText(
        tester,
        HouseholdOnboardingScreen.displayNameFieldKey,
        'Partner',
      );
      await tester.tap(find.byKey(HouseholdOnboardingScreen.submitButtonKey));
      await tester.pump();

      expect(repository.joinCalls, isEmpty);
      expect(find.text('Invite codes are 6 characters long.'), findsOneWidget);
    });

    testWidgets('shows why the backend refused', (tester) async {
      repository.nextFailure = const NotFoundFailure('no such code');
      await pumpScreen(tester);
      await switchToJoin(tester);

      await enterText(
        tester,
        HouseholdOnboardingScreen.codeFieldKey,
        'KH7RQ2',
      );
      await enterText(
        tester,
        HouseholdOnboardingScreen.displayNameFieldKey,
        'Partner',
      );
      await tester.tap(find.byKey(HouseholdOnboardingScreen.submitButtonKey));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'That code does not match a household. Check it and try again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('goes inert while the request is in flight', (tester) async {
      repository.gate = Completer<void>();
      await pumpScreen(tester);

      await enterText(
        tester,
        HouseholdOnboardingScreen.nameFieldKey,
        'The Marx house',
      );
      await enterText(
        tester,
        HouseholdOnboardingScreen.displayNameFieldKey,
        'Brian',
      );
      await tester.tap(find.byKey(HouseholdOnboardingScreen.submitButtonKey));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(HouseholdOnboardingScreen.submitButtonKey),
      );
      expect(button.onPressed, isNull);

      repository.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('withholds the form when membership cannot be read', (
      tester,
    ) async {
      // Offering the form here invites a second household to be created
      // alongside the one that is merely unreadable right now.
      repository.membershipFailure = const PermissionFailure('refused');

      await pumpScreen(tester);
      await tester.pump();

      expect(find.byKey(HouseholdOnboardingScreen.nameFieldKey), findsNothing);
      expect(
        find.byKey(HouseholdOnboardingScreen.submitButtonKey),
        findsNothing,
      );
      expect(find.text('Sign in again to continue.'), findsOneWidget);
      expect(find.byKey(HouseholdOnboardingScreen.retryKey), findsOneWidget);
    });

    testWidgets('retrying brings the form back once it reads', (tester) async {
      repository.membershipFailure = const PermissionFailure('refused');
      await pumpScreen(tester);
      await tester.pump();
      expect(find.byKey(HouseholdOnboardingScreen.retryKey), findsOneWidget);

      repository.membershipFailure = null;
      await tester.tap(find.byKey(HouseholdOnboardingScreen.retryKey));
      await tester.pumpAndSettle();

      expect(
        find.byKey(HouseholdOnboardingScreen.nameFieldKey),
        findsOneWidget,
      );
      expect(find.byKey(HouseholdOnboardingScreen.retryKey), findsNothing);
    });

    testWidgets('still offers sign-out when membership is unreadable', (
      tester,
    ) async {
      repository.membershipFailure = const PermissionFailure('refused');
      await pumpScreen(tester);
      await tester.pump();

      await tester.tap(find.byKey(HouseholdOnboardingScreen.signOutKey));
      await tester.pump();

      expect(auth.currentUser, isNull);
    });

    testWidgets('offers a way back out for the wrong account', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(HouseholdOnboardingScreen.signOutKey));
      await tester.pumpAndSettle();

      expect(auth.currentUser, isNull);
    });
  });
}
