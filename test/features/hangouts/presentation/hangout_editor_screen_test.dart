import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
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
import 'package:kith/features/hangouts/presentation/hangout_editor_screen.dart';
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

  void seedContact(String id, String name, {bool isArchived = false}) {
    contacts.seed(
      Contact(
        id: id,
        name: name,
        relationshipTypeId: 'rid-1',
        cadence: Cadence.monthly,
        priority: ContactPriority.normal,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        isArchived: isArchived,
      ),
    );
  }

  void seedHangout(String id, List<String> contactIds, {String? note}) {
    hangouts.seed(
      Hangout(
        id: id,
        occurredOn: DateTime.utc(2026, 8, 14),
        contactIds: contactIds,
        attendeeIds: const ['uid-1'],
        createdBy: owner.id,
        createdAt: now,
        updatedAt: now,
        note: note,
      ),
    );
  }

  Future<void> pump(
    WidgetTester tester, {
    String? hangoutId,
    String? prefilledContactId,
    List<Override>? withOverrides,
    bool settles = true,
  }) async {
    await tester.pumpApp(
      HangoutEditorScreen(
        hangoutId: hangoutId,
        prefilledContactId: prefilledContactId,
      ),
      overrides: withOverrides ?? overrides(),
    );
    // A screen whose only motion is an indeterminate spinner never settles.
    if (settles) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  /// The chip for [name], told apart from the same text sitting in the search
  /// field.
  Finder chipFor(String name) => find.widgetWithText(FilterChip, name);

  group('logging', () {
    testWidgets('opens on today with nobody chosen', (tester) async {
      seedContact('cid-1', 'Marcus');

      await pump(tester);

      expect(find.text('Log a hangout'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Marcus'), findsOneWidget);
    });

    testWidgets('logs who was tapped, crediting the signed-in user', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus');
      seedContact('cid-2', 'Priya');
      await pump(tester);

      await tester.tap(find.text('Marcus'));
      await tester.pump();
      await tester.enterText(
        find.byKey(HangoutEditorScreen.noteKey),
        'Coffee at theirs',
      );
      await tester.tap(find.byKey(HangoutEditorScreen.saveKey));
      await tester.pumpAndSettle();

      final call = hangouts.logCalls.single;
      expect(call.draft.contactIds, ['cid-1']);
      expect(call.draft.occurredOn, DateTime.utc(2026, 8, 18));
      expect(call.draft.note, 'Coffee at theirs');
      expect(call.createdBy, 'uid-1');
    });

    testWidgets('refuses to log with nobody chosen, and says why', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus');
      await pump(tester);

      await tester.tap(find.byKey(HangoutEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(find.text('Choose who you saw.'), findsOneWidget);
      expect(hangouts.logCalls, isEmpty);
    });

    testWidgets('clears the complaint as soon as somebody is chosen', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus');
      await pump(tester);
      await tester.tap(find.byKey(HangoutEditorScreen.saveKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Marcus'));
      await tester.pump();

      expect(find.text('Choose who you saw.'), findsNothing);
    });

    testWidgets('starts with the contact it was opened from chosen', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus');
      await pump(tester, prefilledContactId: 'cid-1');

      await tester.tap(find.byKey(HangoutEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(hangouts.logCalls.single.draft.contactIds, ['cid-1']);
    });

    testWidgets('ignores a prefill naming somebody who is not there', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus');
      await pump(tester, prefilledContactId: 'cid-gone');

      await tester.tap(find.byKey(HangoutEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(hangouts.logCalls, isEmpty);
    });

    testWidgets('records who from the house was there', (tester) async {
      seedContact('cid-1', 'Marcus');
      await households.createHousehold(
        name: 'The Marx house',
        owner: owner,
        displayName: 'Brian',
      );
      await pump(tester);

      await tester.tap(find.text('Marcus'));
      await tester.pump();
      await tester.tap(find.byKey(HangoutEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(hangouts.logCalls.single.draft.attendeeIds, ['uid-1']);
    });

    testWidgets('takes a contact back off when their chip is tapped again', (
      tester,
    ) async {
      seedContact('cid-1', 'Marcus');
      seedContact('cid-2', 'Priya');
      await pump(tester);

      await tester.tap(chipFor('Marcus'));
      await tester.pump();
      await tester.tap(chipFor('Priya'));
      await tester.pump();
      await tester.tap(chipFor('Marcus'));
      await tester.pump();
      await tester.tap(find.byKey(HangoutEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(hangouts.logCalls.single.draft.contactIds, ['cid-2']);
    });

    testWidgets('lets an attendee be taken off and put back', (tester) async {
      seedContact('cid-1', 'Marcus');
      await households.createHousehold(
        name: 'The Marx house',
        owner: owner,
        displayName: 'Brian',
      );
      await pump(tester);

      await tester.tap(chipFor('Marcus'));
      await tester.pump();
      await tester.tap(chipFor('Brian'));
      await tester.pump();
      await tester.tap(find.byKey(HangoutEditorScreen.saveKey));
      await tester.pumpAndSettle();
      expect(hangouts.logCalls.single.draft.attendeeIds, isEmpty);

      await tester.tap(chipFor('Brian'));
      await tester.pump();
      await tester.tap(find.byKey(HangoutEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(hangouts.logCalls.last.draft.attendeeIds, ['uid-1']);
    });

    testWidgets('leaves archived contacts off the list', (tester) async {
      seedContact('cid-1', 'Marcus');
      seedContact('cid-2', 'Beatrice', isArchived: true);

      await pump(tester);

      expect(find.text('Marcus'), findsOneWidget);
      expect(find.text('Beatrice'), findsNothing);
    });

    testWidgets('says so when there is nobody to have seen', (tester) async {
      await pump(tester);

      expect(
        find.text('Add a contact first, so there is somebody to have seen.'),
        findsOneWidget,
      );
    });
  });

  group('choosing who you saw', () {
    testWidgets('offers no search field for a short list', (tester) async {
      for (var i = 0; i < 4; i++) {
        seedContact('cid-$i', 'Person $i');
      }

      await pump(tester);

      expect(find.byKey(HangoutEditorScreen.searchKey), findsNothing);
    });

    testWidgets('narrows a long list by what is typed', (tester) async {
      for (var i = 0; i < 12; i++) {
        seedContact('cid-$i', 'Person $i');
      }
      seedContact('cid-m', 'Marcus');
      await pump(tester);

      await tester.enterText(
        find.byKey(HangoutEditorScreen.searchKey),
        'Marcus',
      );
      await tester.pumpAndSettle();

      expect(chipFor('Marcus'), findsOneWidget);
      expect(chipFor('Person 3'), findsNothing);
    });

    testWidgets('keeps a chosen contact visible through a search', (
      tester,
    ) async {
      for (var i = 0; i < 12; i++) {
        seedContact('cid-$i', 'Person $i');
      }
      seedContact('cid-m', 'Marcus');
      await pump(tester);

      await tester.tap(chipFor('Marcus'));
      await tester.pump();
      await tester.enterText(
        find.byKey(HangoutEditorScreen.searchKey),
        'Person 3',
      );
      await tester.pumpAndSettle();

      expect(chipFor('Marcus'), findsOneWidget);
      expect(chipFor('Person 3'), findsOneWidget);
    });

    testWidgets('says so when nothing matches', (tester) async {
      for (var i = 0; i < 12; i++) {
        seedContact('cid-$i', 'Person $i');
      }
      await pump(tester);

      await tester.enterText(
        find.byKey(HangoutEditorScreen.searchKey),
        'nobody',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Nobody matches what you are looking for.'),
        findsOneWidget,
      );
    });
  });

  group('the date', () {
    testWidgets('is set from the picker, and never past today', (tester) async {
      seedContact('cid-1', 'Marcus');
      await pump(tester);

      await tester.tap(find.byKey(HangoutEditorScreen.dateKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('14'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Fri 14 Aug'), findsOneWidget);

      await tester.tap(find.text('Marcus'));
      await tester.pump();
      await tester.tap(find.byKey(HangoutEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(
        hangouts.logCalls.single.draft.occurredOn,
        DateTime.utc(2026, 8, 14),
      );
    });
  });

  group('editing', () {
    testWidgets('opens on what was logged', (tester) async {
      seedContact('cid-1', 'Marcus');
      seedHangout('hgid-1', ['cid-1'], note: 'Barbecue');

      await pump(tester, hangoutId: 'hgid-1');

      expect(find.text('Edit hangout'), findsOneWidget);
      expect(find.text('Fri 14 Aug'), findsOneWidget);
      expect(find.text('Barbecue'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('sends the change to the same hangout', (tester) async {
      seedContact('cid-1', 'Marcus');
      seedHangout('hgid-1', ['cid-1'], note: 'Barbecue');
      await pump(tester, hangoutId: 'hgid-1');

      await tester.enterText(
        find.byKey(HangoutEditorScreen.noteKey),
        'Barbecue, and cake',
      );
      await tester.tap(find.byKey(HangoutEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(hangouts.updateCalls.single.hangoutId, 'hgid-1');
      expect(hangouts.updateCalls.single.draft.note, 'Barbecue, and cake');
    });

    testWidgets('keeps an archived contact on an entry that names them', (
      tester,
    ) async {
      seedContact('cid-1', 'Beatrice', isArchived: true);
      seedHangout('hgid-1', ['cid-1']);

      await pump(tester, hangoutId: 'hgid-1');

      expect(find.text('Beatrice'), findsOneWidget);
    });

    testWidgets('deletes the entry when asked', (tester) async {
      seedContact('cid-1', 'Marcus');
      seedHangout('hgid-1', ['cid-1']);
      await pump(tester, hangoutId: 'hgid-1');

      await tester.tap(find.byKey(HangoutEditorScreen.deleteKey));
      await tester.pumpAndSettle();

      expect(hangouts.deleteCalls.single.hangoutId, 'hgid-1');
    });

    testWidgets('offers no delete when logging something new', (tester) async {
      seedContact('cid-1', 'Marcus');

      await pump(tester);

      expect(find.byKey(HangoutEditorScreen.deleteKey), findsNothing);
    });

    testWidgets('says so when the entry has gone', (tester) async {
      seedContact('cid-1', 'Marcus');

      await pump(tester, hangoutId: 'hgid-gone');

      expect(find.text('That hangout is no longer here.'), findsOneWidget);
    });
  });

  group('while a write is in flight', () {
    testWidgets('holds the form inert and shows a spinner', (tester) async {
      seedContact('cid-1', 'Marcus');
      final gate = Completer<void>();
      hangouts.gate = gate;
      await pump(tester);

      await tester.tap(find.text('Marcus'));
      await tester.pump();
      await tester.tap(find.byKey(HangoutEditorScreen.saveKey));
      await tester.pump();

      expect(
        tester
            .widget<FilledButton>(find.byKey(HangoutEditorScreen.saveKey))
            .onPressed,
        isNull,
      );

      gate.complete();
      await tester.pumpAndSettle();
    });
  });

  testWidgets('shows the failure a refused log came back with', (tester) async {
    seedContact('cid-1', 'Marcus');
    hangouts.nextFailure = const NetworkFailure('offline');
    await pump(tester);

    await tester.tap(find.text('Marcus'));
    await tester.pump();
    await tester.tap(find.byKey(HangoutEditorScreen.saveKey));
    await tester.pumpAndSettle();

    expect(
      find.text('You appear to be offline. Try again once you are connected.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the failure when the contacts cannot be read', (
    tester,
  ) async {
    contacts.streamFailure = const PermissionFailure('nope');

    await pump(tester);

    expect(
      find.text('You are not allowed to change this household.'),
      findsOneWidget,
    );
  });

  testWidgets('waits while there is no household yet', (tester) async {
    await pump(
      tester,
      withOverrides: overrides(household: null),
      settles: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
