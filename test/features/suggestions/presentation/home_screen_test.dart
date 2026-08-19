import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/freshness_gauge.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/models/planned_hangout_status.dart';
import 'package:kith/data/services/calendar_sink.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/calendar/application/calendar_providers.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';
import 'package:kith/features/suggestions/domain/snooze_horizon.dart';
import 'package:kith/features/suggestions/presentation/home_screen.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/fake_calendar_sink.dart';
import '../../../helpers/fake_contact_repository.dart';
import '../../../helpers/fake_hangout_repository.dart';
import '../../../helpers/fake_household_repository.dart';
import '../../../helpers/fake_planned_hangout_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  const householdId = 'hid-1';
  const owner = AuthUser(id: 'uid-1', email: 'brian@example.com');
  final now = DateTime.utc(2026, 8, 18, 10);

  late FakeAuthService auth;
  late FakeHouseholdRepository households;
  late FakeContactRepository contacts;
  late FakeHangoutRepository hangouts;
  late FakePlannedHangoutRepository plans;
  late FakeCalendarSink sink;

  setUp(() {
    auth = FakeAuthService(initialUser: owner);
    addTearDown(auth.dispose);
    households = FakeHouseholdRepository();
    addTearDown(households.dispose);
    contacts = FakeContactRepository();
    addTearDown(contacts.dispose);
    hangouts = FakeHangoutRepository();
    addTearDown(hangouts.dispose);
    plans = FakePlannedHangoutRepository();
    addTearDown(plans.dispose);
    sink = FakeCalendarSink();
  });

  /// The household has no calendar linked unless [calendarId] says otherwise,
  /// which is the state every household starts in.
  List<Override> overrides({
    String? household = householdId,
    String? calendarId,
  }) => [
    authServiceProvider.overrideWithValue(auth),
    householdRepositoryProvider.overrideWithValue(households),
    currentHouseholdIdProvider.overrideWithValue(household),
    contactRepositoryProvider.overrideWithValue(contacts),
    hangoutRepositoryProvider.overrideWithValue(hangouts),
    plannedHangoutRepositoryProvider.overrideWithValue(plans),
    clockProvider.overrideWithValue(Clock.fixed(now)),
    calendarSinkProvider.overrideWithValue(sink),
    if (household != null)
      householdCalendarIdProvider(household).overrideWithValue(calendarId),
  ];

  void seedContact(
    String id,
    String name, {
    Cadence cadence = Cadence.monthly,
    ContactPriority priority = ContactPriority.normal,
  }) => contacts.seed(
    Contact(
      id: id,
      name: name,
      relationshipTypeId: 'rid-1',
      cadence: cadence,
      priority: priority,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ),
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

  Future<void> pumpHome(
    WidgetTester tester, {
    String? household = householdId,
    String? calendarId,
  }) async {
    await tester.pumpApp(
      const HomeScreen(),
      overrides: overrides(household: household, calendarId: calendarId),
    );
    await tester.pumpAndSettle();
  }

  /// A plan already on the household's calendar, as the other partner's
  /// device would have left it.
  PlannedHangout seedConfirmedPlan({
    String id = 'pid-1',
    String contactId = 'cid-1',
    DateTime? plannedFor,
    String eventId = 'evt_1',
  }) {
    final plan = PlannedHangout(
      id: id,
      plannedFor: plannedFor ?? DateTime.utc(2026, 8, 25),
      contactIds: [contactId],
      status: PlannedHangoutStatus.confirmed,
      createdBy: 'uid-1',
      createdAt: now,
      updatedAt: now,
      calendarEventId: eventId,
    );
    plans.seed(plan);
    return plan;
  }

  group('the frame', () {
    testWidgets('is titled Reconnect', (tester) async {
      await pumpHome(tester);

      expect(find.text('Reconnect'), findsOneWidget);
    });

    // Where the buttons go is the router's business, and is asserted there.
    testWidgets('offers the ways through to the rest of the app', (
      tester,
    ) async {
      await pumpHome(tester);

      expect(find.byKey(HomeScreen.hangoutsKey), findsOneWidget);
      expect(find.byTooltip('Hangouts'), findsOneWidget);
      expect(find.byKey(HomeScreen.contactsKey), findsOneWidget);
      expect(find.byTooltip('Contacts'), findsOneWidget);
      expect(find.byKey(HomeScreen.householdKey), findsOneWidget);
      expect(find.byTooltip('Household'), findsOneWidget);
    });

    testWidgets('tells the three destinations apart by their icons', (
      tester,
    ) async {
      await pumpHome(tester);

      expect(find.byIcon(KithIcons.hangout), findsOneWidget);
      expect(find.byIcon(KithIcons.people), findsOneWidget);
      expect(find.byIcon(KithIcons.household), findsOneWidget);
    });

    testWidgets('waits rather than showing a list with no household', (
      tester,
    ) async {
      await tester.pumpApp(
        const HomeScreen(),
        overrides: overrides(household: null),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('waits while the streams are still arriving', (tester) async {
      await tester.pumpApp(const HomeScreen(), overrides: overrides());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('says so when a stream fails', (tester) async {
      plans.streamFailure = const PermissionFailure('not a member');

      await pumpHome(tester);

      expect(
        find.text('You are not allowed to change this household.'),
        findsOneWidget,
      );
    });
  });

  group('the list', () {
    testWidgets('puts the most pressing contact first, with its reason', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus Bell');
      seedContact('cid-2', 'Ana Reyes', cadence: Cadence.weekly);
      seenDaysAgo('cid-1', 60);
      seenDaysAgo('cid-2', 7);

      await pumpHome(tester);

      expect(find.byKey(HomeScreen.cardKey('cid-1')), findsOneWidget);
      expect(
        find.text("It's been 2 months — you usually see Marcus Bell monthly."),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.byKey(HomeScreen.cardKey('cid-1'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(HomeScreen.cardKey('cid-2'))).dy,
        ),
      );
    });

    testWidgets('leaves out anyone seen well inside their cadence', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 3);

      await pumpHome(tester);

      expect(find.byKey(HomeScreen.cardKey('cid-1')), findsNothing);
      expect(find.textContaining('Nobody is overdue'), findsOneWidget);
    });

    testWidgets('sends someone with nothing logged to the contact list copy', (
      tester,
    ) async {
      await pumpHome(tester);

      expect(find.textContaining('Nobody here yet'), findsOneWidget);
      expect(find.text('Add contacts'), findsOneWidget);
    });

    testWidgets('draws a gauge for every card', (tester) async {
      seedContact('cid-1', 'Marcus Bell');
      seedContact('cid-2', 'Ana Reyes');
      seenDaysAgo('cid-1', 60);

      await pumpHome(tester);

      expect(find.byType(FreshnessGauge), findsNWidgets(2));
    });

    testWidgets('says an arrangement is already standing', (tester) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      plans.seed(
        PlannedHangout(
          id: 'pid-1',
          plannedFor: DateTime.utc(2026, 8, 25),
          contactIds: const ['cid-1'],
          status: PlannedHangoutStatus.proposed,
          createdBy: 'uid-1',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await pumpHome(tester);

      expect(find.text('Planned Tue 25 Aug'), findsOneWidget);
    });
  });

  group('acting on a suggestion', () {
    testWidgets('planning it asks for a day and stores the intent', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      await pumpHome(tester);

      await tester.tap(find.byKey(HomeScreen.planKey('cid-1')));
      await tester.pumpAndSettle();
      // The picker opens a week out, so agreeing with it is the one tap.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(plans.planCalls.single.plannedFor, DateTime.utc(2026, 8, 25));
      expect(
        find.text('Planned with Marcus Bell for Tue 25 Aug.'),
        findsOneWidget,
      );
    });

    testWidgets('backing out of the picker plans nothing', (tester) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      await pumpHome(tester);

      await tester.tap(find.byKey(HomeScreen.planKey('cid-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(plans.planCalls, isEmpty);
    });

    testWidgets('snoozing defers a week and says until when', (tester) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      await pumpHome(tester);

      await tester.tap(
        find.byKey(HomeScreen.snoozeKey('cid-1', SnoozeHorizon.week)),
      );
      await tester.pumpAndSettle();

      expect(plans.snoozeCalls.single.until, DateTime.utc(2026, 8, 25));
      expect(
        find.text('Not asking about Marcus Bell until Tue 25 Aug.'),
        findsOneWidget,
      );
    });

    testWidgets('dismissing defers by a whole cadence', (tester) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      await pumpHome(tester);

      await tester.tap(
        find.byKey(HomeScreen.snoozeKey('cid-1', SnoozeHorizon.fullCadence)),
      );
      await tester.pumpAndSettle();

      expect(plans.snoozeCalls.single.until, DateTime.utc(2026, 9, 17));
      expect(
        find.text('Not asking about Marcus Bell until Thu 17 Sep.'),
        findsOneWidget,
      );
    });

    testWidgets('a deferred contact drops off the list', (tester) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      await pumpHome(tester);

      await tester.tap(
        find.byKey(HomeScreen.snoozeKey('cid-1', SnoozeHorizon.week)),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(HomeScreen.cardKey('cid-1')), findsNothing);
    });

    testWidgets('undo takes the deferral back and returns the card', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      await pumpHome(tester);
      await tester.tap(
        find.byKey(HomeScreen.snoozeKey('cid-1', SnoozeHorizon.week)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(plans.cancelCalls.single.plannedHangoutId, 'pid-1');
      expect(plans.plans, isEmpty);
      expect(find.byKey(HomeScreen.cardKey('cid-1')), findsOneWidget);
    });

    testWidgets('a refused write is reported and changes nothing', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      await pumpHome(tester);
      plans.nextFailure = const NetworkFailure('offline');

      await tester.tap(
        find.byKey(HomeScreen.snoozeKey('cid-1', SnoozeHorizon.week)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'You appear to be offline. Try again once you are connected.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(HomeScreen.cardKey('cid-1')), findsOneWidget);
    });
  });

  group('the household calendar', () {
    testWidgets('puts a new plan on the linked calendar and says so', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      await pumpHome(tester, calendarId: 'cal-1');

      await tester.tap(find.byKey(HomeScreen.planKey('cid-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(sink.createCalls.single.calendarId, 'cal-1');
      expect(sink.createCalls.single.title, 'Marcus Bell');
      expect(
        find.text(
          'Planned with Marcus Bell for Tue 25 Aug. Added to the calendar.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('says the plan stands even when the calendar refused it', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      await pumpHome(tester, calendarId: 'cal-1');
      sink.createFailure = const NetworkFailure('offline');

      await tester.tap(find.byKey(HomeScreen.planKey('cid-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(plans.plans, hasLength(1));
      expect(
        find.textContaining(
          'Planned with Marcus Bell for Tue 25 Aug. Google Calendar could '
          'not be reached.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('marks a plan that reached the calendar', (tester) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      seedConfirmedPlan();
      sink.seed(
        CalendarEvent(
          id: 'evt_1',
          title: 'Marcus Bell',
          day: DateTime.utc(2026, 8, 25),
        ),
      );

      await pumpHome(tester, calendarId: 'cal-1');

      expect(find.text('Planned Tue 25 Aug'), findsOneWidget);
      expect(find.byIcon(KithIcons.calendar), findsOneWidget);
    });

    testWidgets('drops a plan whose event was deleted in the calendar', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      seedConfirmedPlan();

      await pumpHome(tester, calendarId: 'cal-1');

      expect(sink.fetchCalls.single.eventId, 'evt_1');
      expect(plans.plans, isEmpty);
    });

    testWidgets('follows an event that was moved to another day', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      seedConfirmedPlan();
      sink.seed(
        CalendarEvent(
          id: 'evt_1',
          title: 'Marcus Bell',
          day: DateTime.utc(2026, 8, 27),
        ),
      );

      await pumpHome(tester, calendarId: 'cal-1');

      expect(plans.plans['pid-1']?.plannedFor, DateTime.utc(2026, 8, 27));
      expect(find.text('Planned Thu 27 Aug'), findsOneWidget);
    });

    testWidgets('asks the calendar nothing when none is linked', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      seedConfirmedPlan();

      await pumpHome(tester);

      expect(sink.fetchCalls, isEmpty);
      expect(plans.plans, hasLength(1));
    });

    testWidgets('says quietly when the calendar could not be read', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus Bell');
      seenDaysAgo('cid-1', 60);
      seedConfirmedPlan();
      sink.fetchFailure = const NetworkFailure('offline');

      await pumpHome(tester, calendarId: 'cal-1');

      expect(
        find.textContaining('Plans may be out of step with the calendar.'),
        findsOneWidget,
      );
      // The suggestions themselves are Kith's own, and stay on screen.
      expect(find.byKey(HomeScreen.cardKey('cid-1')), findsOneWidget);
    });
  });
}
