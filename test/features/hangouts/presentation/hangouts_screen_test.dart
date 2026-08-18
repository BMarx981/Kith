import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/widgets/freshness_gauge.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/hangouts/presentation/hangouts_screen.dart';
import 'package:kith/features/household/application/household_providers.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/fake_contact_repository.dart';
import '../../../helpers/fake_hangout_repository.dart';
import '../../../helpers/fake_household_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  const householdId = 'hid-1';
  const owner = AuthUser(id: 'uid-1', email: 'brian@example.com');
  final now = DateTime.utc(2026, 8, 18);

  late FakeHangoutRepository hangouts;
  late FakeContactRepository contacts;
  late FakeHouseholdRepository households;
  late FakeAuthService auth;

  setUp(() {
    hangouts = FakeHangoutRepository();
    addTearDown(hangouts.dispose);
    contacts = FakeContactRepository();
    addTearDown(contacts.dispose);
    households = FakeHouseholdRepository();
    addTearDown(households.dispose);
    auth = FakeAuthService(initialUser: owner);
    addTearDown(auth.dispose);
  });

  List<Override> overrides({String? household = householdId}) => [
    authServiceProvider.overrideWithValue(auth),
    householdRepositoryProvider.overrideWithValue(households),
    currentHouseholdIdProvider.overrideWithValue(household),
    contactRepositoryProvider.overrideWithValue(contacts),
    hangoutRepositoryProvider.overrideWithValue(hangouts),
    clockProvider.overrideWithValue(Clock.fixed(now)),
  ];

  void seedContact(
    String id,
    String name, {
    Cadence cadence = Cadence.monthly,
  }) {
    contacts.seed(
      Contact(
        id: id,
        name: name,
        relationshipTypeId: 'rid-1',
        cadence: cadence,
        priority: ContactPriority.normal,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
  }

  void seedHangout(
    String id,
    DateTime on,
    List<String> contactIds, {
    String? note,
    List<String> attendeeIds = const [],
  }) {
    hangouts.seed(
      Hangout(
        id: id,
        occurredOn: on,
        contactIds: contactIds,
        attendeeIds: attendeeIds,
        createdBy: owner.id,
        createdAt: now,
        updatedAt: now,
        note: note,
      ),
    );
  }

  Future<void> pump(WidgetTester tester, {String? contactId}) async {
    await tester.pumpApp(
      HangoutsScreen(contactId: contactId),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
  }

  group('the household timeline', () {
    testWidgets('is titled for the whole house', (tester) async {
      await pump(tester);

      expect(find.text('Hangouts'), findsOneWidget);
    });

    testWidgets('lists what has been logged, newest day first', (tester) async {
      seedContact('cid-1', 'Marcus');
      seedContact('cid-2', 'Priya');
      seedHangout('hgid-1', DateTime.utc(2026, 8, 17), ['cid-1']);
      seedHangout('hgid-2', DateTime.utc(2026, 8, 4), ['cid-2']);

      await pump(tester);

      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.text('Marcus'), findsOneWidget);
      expect(find.text('Priya'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Marcus')).dy,
        lessThan(tester.getTopLeft(find.text('Priya')).dy),
      );
    });

    testWidgets('heads each day once, however many hangouts it holds', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus');
      seedContact('cid-2', 'Priya');
      seedHangout('hgid-1', DateTime.utc(2026, 8, 17), ['cid-1']);
      seedHangout('hgid-2', DateTime.utc(2026, 8, 17), ['cid-2']);

      await pump(tester);

      expect(find.text('YESTERDAY'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('names several contacts the way a person would', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus');
      seedContact('cid-2', 'Priya');
      seedContact('cid-3', 'Bo');
      seedHangout('hgid-1', now, ['cid-1', 'cid-2', 'cid-3']);

      await pump(tester);

      expect(find.text('Marcus, Priya and Bo'), findsOneWidget);
    });

    testWidgets('shows the note and who from the house went', (tester) async {
      seedContact('cid-1', 'Marcus');
      await households.createHousehold(
        name: 'The Marx house',
        owner: owner,
        displayName: 'Brian',
      );
      seedHangout(
        'hgid-1',
        now,
        ['cid-1'],
        note: 'Barbecue',
        attendeeIds: [owner.id],
      );

      await pump(tester);

      expect(find.textContaining('Brian'), findsOneWidget);
      expect(find.textContaining('Barbecue'), findsOneWidget);
    });

    testWidgets('names a contact who has since been removed', (tester) async {
      seedHangout('hgid-1', now, ['cid-gone']);

      await pump(tester);

      expect(find.text('Someone since removed'), findsOneWidget);
    });

    testWidgets('offers the empty state before anything is logged', (
      tester,
    ) async {
      await pump(tester);

      expect(
        find.text('Nothing logged yet. The first hangout goes here.'),
        findsOneWidget,
      );
    });

    testWidgets('shows the failure when the timeline cannot be read', (
      tester,
    ) async {
      hangouts.streamFailure = const PermissionFailure('nope');

      await pump(tester);

      expect(
        find.text('You are not allowed to change this household.'),
        findsOneWidget,
      );
    });
  });

  group("one contact's history", () {
    testWidgets('keeps only the hangouts naming them', (tester) async {
      seedContact('cid-1', 'Marcus');
      seedContact('cid-2', 'Priya');
      seedHangout('hgid-1', DateTime.utc(2026, 8, 17), ['cid-1']);
      seedHangout('hgid-2', DateTime.utc(2026, 8, 4), ['cid-2']);

      await pump(tester, contactId: 'cid-1');

      expect(find.text('Priya'), findsNothing);
      expect(find.text('YESTERDAY'), findsOneWidget);
    });

    testWidgets('names them in the app bar', (tester) async {
      seedContact('cid-1', 'Marcus');

      await pump(tester, contactId: 'cid-1');

      expect(find.text('Hangouts with Marcus'), findsOneWidget);
    });

    testWidgets('heads the list with their gauge and how long it has been', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus');
      seedHangout('hgid-1', DateTime.utc(2026, 8, 17), ['cid-1']);

      await pump(tester, contactId: 'cid-1');

      expect(find.byType(FreshnessGauge), findsOneWidget);
      expect(find.text('Marcus'), findsOneWidget);
      expect(find.textContaining('Seen yesterday'), findsOneWidget);
    });

    testWidgets('the gauge moves as soon as a hangout is logged', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus', cadence: Cadence.weekly);
      seedHangout('hgid-1', DateTime.utc(2026, 7), ['cid-1']);

      await pump(tester, contactId: 'cid-1');
      expect(find.textContaining('Seen 7 weeks ago'), findsOneWidget);

      seedHangout('hgid-2', now, ['cid-1']);
      await tester.pumpAndSettle();

      expect(find.textContaining('Seen today'), findsOneWidget);
    });

    testWidgets('says so when nothing has been logged with them', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus');

      await pump(tester, contactId: 'cid-1');

      expect(find.text('Nothing logged with Marcus yet.'), findsOneWidget);
      expect(find.textContaining('Never logged'), findsOneWidget);
    });

    testWidgets('does not repeat their name on every row', (tester) async {
      seedContact('cid-1', 'Marcus');
      seedContact('cid-2', 'Priya');
      seedHangout('hgid-1', now, ['cid-1', 'cid-2']);

      await pump(tester, contactId: 'cid-1');

      // Once in the header, and not again in the row, which reads "Priya".
      expect(find.text('Marcus'), findsOneWidget);
      expect(find.text('Priya'), findsOneWidget);
    });

    testWidgets('reads a hangout with nobody else on it as just the two', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus');
      seedHangout('hgid-1', now, ['cid-1']);

      await pump(tester, contactId: 'cid-1');

      expect(find.text('Just the two of you'), findsOneWidget);
    });
  });

  testWidgets('offers the log button once a household is known', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byKey(HangoutsScreen.logKey), findsOneWidget);
  });

  testWidgets('waits rather than offering to log with no household', (
    tester,
  ) async {
    await tester.pumpApp(
      const HangoutsScreen(),
      overrides: overrides(household: null),
    );
    await tester.pump();

    expect(find.byKey(HangoutsScreen.logKey), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
