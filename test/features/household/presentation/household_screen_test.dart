import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/household/domain/invite_code.dart';
import 'package:kith/features/household/presentation/household_screen.dart';
import 'package:kith/features/notifications/application/notification_providers.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/fake_contact_repository.dart';
import '../../../helpers/fake_hangout_repository.dart';
import '../../../helpers/fake_household_repository.dart';
import '../../../helpers/fake_notification_scheduler.dart';
import '../../../helpers/fake_planned_hangout_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  const owner = AuthUser(id: 'uid-owner', email: 'brian@example.com');
  const partner = AuthUser(id: 'uid-partner', email: 'partner@example.com');

  late FakeAuthService auth;
  late FakeHouseholdRepository repository;
  late FakeNotificationScheduler scheduler;
  late FakeContactRepository contacts;
  late FakeHangoutRepository hangouts;
  late FakePlannedHangoutRepository plans;

  setUp(() {
    auth = FakeAuthService(initialUser: owner);
    addTearDown(auth.dispose);
    repository = FakeHouseholdRepository();
    addTearDown(repository.dispose);
    scheduler = FakeNotificationScheduler();
    contacts = FakeContactRepository();
    addTearDown(contacts.dispose);
    hangouts = FakeHangoutRepository();
    addTearDown(hangouts.dispose);
    plans = FakePlannedHangoutRepository();
    addTearDown(plans.dispose);
  });

  List<Override> overrides() => [
    authServiceProvider.overrideWithValue(auth),
    householdRepositoryProvider.overrideWithValue(repository),
    currentHouseholdIdProvider.overrideWithValue('hid-1'),
    notificationSchedulerProvider.overrideWithValue(scheduler),
    contactRepositoryProvider.overrideWithValue(contacts),
    hangoutRepositoryProvider.overrideWithValue(hangouts),
    plannedHangoutRepositoryProvider.overrideWithValue(plans),
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

    testWidgets('says the household writes to no calendar yet', (
      tester,
    ) async {
      await seedHousehold();

      await pumpScreen(tester);

      expect(find.byKey(HouseholdScreen.calendarKey), findsOneWidget);
      expect(find.text('Not linked'), findsOneWidget);
    });

    testWidgets('names the calendar the household plans go on', (
      tester,
    ) async {
      await seedHousehold();
      await repository.linkCalendar(
        householdId: repository.households.keys.single,
        calendarId: 'cal-1',
        calendarName: 'Hangouts',
      );

      await pumpScreen(tester);

      expect(find.text('Plans go on "Hangouts"'), findsOneWidget);
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

  group('the weekly digest', () {
    testWidgets('reads off as off, with the switch clear', (tester) async {
      await seedHousehold();

      await pumpScreen(tester);

      expect(find.text('Weekly digest'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      final tile = tester.widget<SwitchListTile>(
        find.byKey(HouseholdScreen.digestKey),
      );
      expect(tile.value, isFalse);
      expect(find.byKey(HouseholdScreen.digestDayKey), findsNothing);
    });

    testWidgets('turning it on stores a default of Sunday', (tester) async {
      await seedHousehold();

      await pumpScreen(tester);
      await tester.tap(find.byKey(HouseholdScreen.digestKey));
      await tester.pumpAndSettle();

      expect(scheduler.permissionAsks, 1);
      expect(repository.digestCalls.single.digestDay, DateTime.sunday);
      expect(repository.digestCalls.single.uid, owner.id);
      expect(find.text('Sunday at 9am'), findsOneWidget);
      expect(find.byKey(HouseholdScreen.digestDayKey), findsOneWidget);
      expect(find.byKey(HouseholdScreen.digestHourKey), findsOneWidget);
    });

    testWidgets('turning it off stores no day', (tester) async {
      await seedHousehold();
      await repository.setDigestPreference(
        householdId: 'hid-1',
        uid: owner.id,
        digestDay: DateTime.sunday,
        digestHour: 9,
      );

      await pumpScreen(tester);
      await tester.tap(find.byKey(HouseholdScreen.digestKey));
      await tester.pumpAndSettle();

      expect(repository.digestCalls.last.digestDay, isNull);
      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('picking a day and an hour stores both', (tester) async {
      await seedHousehold();
      await repository.setDigestPreference(
        householdId: 'hid-1',
        uid: owner.id,
        digestDay: DateTime.sunday,
        digestHour: 9,
      );

      await pumpScreen(tester);
      await tester.tap(find.byKey(HouseholdScreen.digestDayKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Friday').last);
      await tester.pumpAndSettle();

      expect(repository.digestCalls.last.digestDay, DateTime.friday);
      expect(repository.digestCalls.last.digestHour, 9);

      await tester.tap(find.byKey(HouseholdScreen.digestHourKey));
      await tester.pumpAndSettle();
      // An hour next to the selected one: the menu opens scrolled to 9am, and
      // a distant entry would be off-screen rather than absent.
      await tester.tap(find.text('8am').last);
      await tester.pumpAndSettle();

      expect(repository.digestCalls.last.digestDay, DateTime.friday);
      expect(repository.digestCalls.last.digestHour, 8);
      expect(find.text('Friday at 8am'), findsOneWidget);
    });

    testWidgets('says where to look when notifications are refused', (
      tester,
    ) async {
      await seedHousehold();
      scheduler.permissionGranted = false;

      await pumpScreen(tester);
      await tester.tap(find.byKey(HouseholdScreen.digestKey));
      await tester.pumpAndSettle();

      expect(repository.digestCalls, isEmpty);
      expect(
        find.textContaining('Notifications are switched off for Kith.'),
        findsOneWidget,
      );
      expect(find.text('Off'), findsOneWidget);
    });

    testWidgets('says when the preference could not be stored', (tester) async {
      await seedHousehold();
      repository.nextFailure = const NetworkFailure('offline');

      await pumpScreen(tester);
      await tester.tap(find.byKey(HouseholdScreen.digestKey));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('could not be saved'),
        findsOneWidget,
      );
    });
  });
}

/// Builds a code the only way there is one: by parsing it.
InviteCode _code(String value) => InviteCode.parse(value).valueOrNull!;
