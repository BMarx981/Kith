import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/household/domain/invite_code.dart';
import 'package:kith/features/household/presentation/household_screen.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/fake_household_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  const owner = AuthUser(id: 'uid-owner', email: 'brian@example.com');
  const partner = AuthUser(id: 'uid-partner', email: 'partner@example.com');

  late FakeAuthService auth;
  late FakeHouseholdRepository repository;

  setUp(() {
    auth = FakeAuthService(initialUser: owner);
    addTearDown(auth.dispose);
    repository = FakeHouseholdRepository();
    addTearDown(repository.dispose);
  });

  List<Override> overrides() => [
    authServiceProvider.overrideWithValue(auth),
    householdRepositoryProvider.overrideWithValue(repository),
  ];

  Future<void> seedHousehold() => repository.createHousehold(
    name: 'The Marx house',
    owner: owner,
    displayName: 'Brian',
  );

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpApp(const HouseholdScreen(), overrides: overrides());
    await tester.pumpAndSettle();
  }

  group('HouseholdScreen', () {
    testWidgets('names the household', (tester) async {
      await seedHousehold();

      await pumpScreen(tester);

      expect(find.text('The Marx house'), findsOneWidget);
    });

    testWidgets('lists the members and marks the owner', (tester) async {
      await seedHousehold();
      await repository.joinWithInviteCode(
        code: 'KH7RQ2',
        user: partner,
        displayName: 'Partner',
      );

      await pumpScreen(tester);

      expect(find.text('2 members'), findsOneWidget);
      expect(find.text('Brian'), findsOneWidget);
      expect(find.text('Partner'), findsOneWidget);
      expect(find.text(partner.email), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Owner'), findsOneWidget);
    });

    testWidgets('counts a household of one in the singular', (tester) async {
      await seedHousehold();

      await pumpScreen(tester);

      expect(find.text('1 member'), findsOneWidget);
    });

    testWidgets('says when there is no invite code to share', (tester) async {
      // The fake creates households without one, which is also what a
      // household whose stored code failed to parse looks like.
      await seedHousehold();

      await pumpScreen(tester);

      expect(
        find.text('This household has no invite code right now.'),
        findsOneWidget,
      );
      expect(find.byKey(HouseholdScreen.copyCodeKey), findsNothing);
    });

    testWidgets('copies the invite code to the clipboard', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await seedHousehold();
      repository.households.updateAll(
        (_, household) => household.copyWith(inviteCode: _code('KH7RQ2')),
      );

      await pumpScreen(tester);
      await tester.tap(find.byKey(HouseholdScreen.copyCodeKey));
      await tester.pumpAndSettle();

      expect(copied, ['KH7RQ2']);
      expect(find.text('Invite code copied.'), findsOneWidget);
      expect(find.text('KH7-RQ2'), findsOneWidget);
    });

    testWidgets('reports a household it could not read', (tester) async {
      await seedHousehold();
      repository.streamFailure = const PermissionFailure('refused');

      await pumpScreen(tester);

      expect(find.text('Sign in again to continue.'), findsAtLeast(1));
    });

    testWidgets('says when the household has gone', (tester) async {
      // What a member who was removed sees: the membership that got them here
      // is still cached, but the household itself no longer reads back.
      await seedHousehold();
      repository.households.clear();

      await pumpScreen(tester);

      expect(find.text('This household no longer exists.'), findsOneWidget);
    });

    testWidgets('signs out from the app bar', (tester) async {
      await seedHousehold();

      await pumpScreen(tester);
      await tester.tap(find.byKey(HouseholdScreen.signOutKey));
      // Pumped rather than settled: with nobody signed in there is no
      // household to show, so this screen falls back to its spinner and never
      // goes idle. In the app the auth guard has replaced it by now.
      await tester.pump();

      expect(auth.currentUser, isNull);
    });
  });
}

/// Builds a code the only way there is one: by parsing it.
InviteCode _code(String value) => InviteCode.parse(value).valueOrNull!;
