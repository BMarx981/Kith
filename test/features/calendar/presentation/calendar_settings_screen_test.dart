import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/household.dart';
import 'package:kith/data/services/calendar_directory.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/calendar/application/calendar_providers.dart';
import 'package:kith/features/calendar/presentation/calendar_settings_screen.dart';
import 'package:kith/features/household/application/household_providers.dart';

import '../../../helpers/fake_calendar_directory.dart';
import '../../../helpers/fake_google_sign_in_service.dart';
import '../../../helpers/fake_household_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  const householdId = 'hid-1';
  const owner = AuthUser(id: 'uid-1', email: 'brian@example.com');
  const family = CalendarListing(id: 'cal-1', name: 'Family');
  const mine = CalendarListing(
    id: 'cal-me',
    name: 'Brian',
    isPrimary: true,
  );

  late FakeGoogleSignInService google;
  late FakeCalendarDirectory directory;
  late FakeHouseholdRepository households;

  setUp(() {
    google = FakeGoogleSignInService();
    directory = FakeCalendarDirectory()..calendars = const [mine, family];
    households = FakeHouseholdRepository();
    addTearDown(households.dispose);
  });

  void seedHousehold({String? calendarId, String? calendarName}) =>
      households.households[householdId] = Household(
        id: householdId,
        name: 'The Marx house',
        inviteCode: null,
        createdAt: DateTime.utc(2026, 8, 16),
        createdBy: owner.id,
        calendarId: calendarId,
        calendarName: calendarName,
      );

  List<Override> overrides() => [
    googleSignInServiceProvider.overrideWithValue(google),
    calendarDirectoryProvider.overrideWithValue(directory),
    householdRepositoryProvider.overrideWithValue(households),
    currentHouseholdIdProvider.overrideWithValue(householdId),
    currentUserProvider.overrideWithValue(owner),
  ];

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpApp(
      const CalendarSettingsScreen(),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
  }

  group('before the account is connected', () {
    testWidgets('offers the grant and lists nothing', (tester) async {
      seedHousehold();

      await pumpScreen(tester);

      expect(find.byKey(CalendarSettingsScreen.connectKey), findsOneWidget);
      expect(
        find.byKey(CalendarSettingsScreen.calendarKey('cal-1')),
        findsNothing,
      );
      expect(directory.listCalls, 0);
    });

    testWidgets('says plans are going nowhere yet', (tester) async {
      seedHousehold();

      await pumpScreen(tester);

      expect(find.textContaining('No calendar linked'), findsOneWidget);
      expect(find.byKey(CalendarSettingsScreen.unlinkKey), findsNothing);
    });

    testWidgets('lists the calendars once the grant is given', (tester) async {
      seedHousehold();
      await pumpScreen(tester);

      await tester.tap(find.byKey(CalendarSettingsScreen.connectKey));
      await tester.pumpAndSettle();

      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Brian'), findsOneWidget);
      expect(find.text('Your own calendar'), findsOneWidget);
      expect(find.byKey(CalendarSettingsScreen.connectKey), findsNothing);
    });

    testWidgets('reports a refused grant', (tester) async {
      seedHousehold();
      google.authorizeFailure = const NetworkFailure('offline');
      await pumpScreen(tester);

      await tester.tap(find.byKey(CalendarSettingsScreen.connectKey));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Google Calendar could not be reached'),
        findsOneWidget,
      );
    });
  });

  group('with the account connected', () {
    setUp(() => google.token = 'granted-earlier');

    testWidgets('lists the account calendars without being asked', (
      tester,
    ) async {
      seedHousehold();

      await pumpScreen(tester);

      expect(find.text('Family'), findsOneWidget);
      expect(find.byKey(CalendarSettingsScreen.connectKey), findsNothing);
    });

    testWidgets('links the calendar that was tapped', (tester) async {
      seedHousehold();
      await pumpScreen(tester);

      await tester.tap(
        find.byKey(CalendarSettingsScreen.calendarKey('cal-1')),
      );
      await tester.pumpAndSettle();

      expect(households.linkCalls.single.calendarId, 'cal-1');
      expect(find.text('Plans now go on "Family".'), findsOneWidget);
    });

    testWidgets('marks the linked calendar and says where plans go', (
      tester,
    ) async {
      seedHousehold(calendarId: 'cal-1', calendarName: 'Family');

      await pumpScreen(tester);

      expect(find.text('Linked'), findsOneWidget);
      expect(find.textContaining('Plans go on "Family"'), findsOneWidget);
    });

    testWidgets('unlinks, and says the events were left alone', (
      tester,
    ) async {
      seedHousehold(calendarId: 'cal-1', calendarName: 'Family');
      await pumpScreen(tester);

      await tester.tap(find.byKey(CalendarSettingsScreen.unlinkKey));
      await tester.pumpAndSettle();

      expect(households.unlinkCalls.single, householdId);
      expect(
        find.textContaining('left where they are'),
        findsOneWidget,
      );
    });

    testWidgets('says when the account has nothing to write to', (
      tester,
    ) async {
      seedHousehold();
      directory.calendars = const [];

      await pumpScreen(tester);

      expect(
        find.textContaining('no calendar Kith can write to'),
        findsOneWidget,
      );
    });

    testWidgets('reports a refused link', (tester) async {
      seedHousehold();
      await pumpScreen(tester);
      households.nextFailure = const PermissionFailure('not a member');

      await tester.tap(
        find.byKey(CalendarSettingsScreen.calendarKey('cal-1')),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Kith is not allowed to use that calendar'),
        findsOneWidget,
      );
      expect(find.textContaining('Plans now go on'), findsNothing);
    });
  });
}
