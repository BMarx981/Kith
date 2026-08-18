import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/freshness_gauge.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/domain/contact_view.dart';
import 'package:kith/features/contacts/presentation/contacts_screen.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/hangouts/domain/freshness.dart';
import 'package:kith/features/household/application/household_providers.dart';

import '../../../helpers/fake_contact_repository.dart';
import '../../../helpers/fake_hangout_repository.dart';
import '../../../helpers/fake_relationship_type_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  const householdId = 'hid-1';
  final createdAt = DateTime.utc(2026, 8);
  final now = DateTime.utc(2026, 8, 18);

  late FakeContactRepository contacts;
  late FakeRelationshipTypeRepository labels;
  late FakeHangoutRepository hangouts;

  setUp(() {
    contacts = FakeContactRepository();
    addTearDown(contacts.dispose);
    labels = FakeRelationshipTypeRepository();
    addTearDown(labels.dispose);
    hangouts = FakeHangoutRepository();
    addTearDown(hangouts.dispose);
  });

  List<Override> overrides({String? household = householdId}) => [
    currentHouseholdIdProvider.overrideWithValue(household),
    contactRepositoryProvider.overrideWithValue(contacts),
    relationshipTypeRepositoryProvider.overrideWithValue(labels),
    hangoutRepositoryProvider.overrideWithValue(hangouts),
    clockProvider.overrideWithValue(Clock.fixed(now)),
  ];

  void seedHangout(String id, int daysAgo, List<String> contactIds) {
    hangouts.seed(
      Hangout(
        id: id,
        occurredOn: now.subtract(Duration(days: daysAgo)),
        contactIds: contactIds,
        attendeeIds: const [],
        createdBy: 'uid-1',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  RelationshipType label(String id, String name, {int sortOrder = 0}) =>
      RelationshipType(
        id: id,
        name: name,
        sortOrder: sortOrder,
        createdAt: createdAt,
      );

  Contact contact(
    String id,
    String name, {
    String typeId = 'rid-friend',
    Cadence cadence = Cadence.monthly,
    List<String> tags = const [],
    bool isArchived = false,
    int day = 1,
  }) => Contact(
    id: id,
    name: name,
    relationshipTypeId: typeId,
    cadence: cadence,
    priority: ContactPriority.normal,
    createdAt: DateTime.utc(2026, 8, day),
    updatedAt: DateTime.utc(2026, 8, day),
    tags: tags,
    isArchived: isArchived,
  );

  Future<void> pumpScreen(
    WidgetTester tester, {
    String? household = householdId,
  }) async {
    await tester.pumpApp(
      const ContactsScreen(),
      overrides: overrides(household: household),
    );
    await tester.pumpAndSettle();
  }

  group('ContactsScreen', () {
    testWidgets('lists the household contacts with label and cadence', (
      tester,
    ) async {
      labels.seed(label('rid-friend', 'Friend'));
      contacts.seed(contact('c1', 'Marcus'));

      await pumpScreen(tester);

      expect(find.text('Marcus'), findsOneWidget);
      expect(find.textContaining('Friend'), findsWidgets);
      expect(find.textContaining('Monthly'), findsOneWidget);
    });

    testWidgets('sorts by name by default', (tester) async {
      labels.seed(label('rid-friend', 'Friend'));
      contacts
        ..seed(contact('c1', 'Zoe'))
        ..seed(contact('c2', 'ada'));

      await pumpScreen(tester);

      final names = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => (tile.title! as Text).data)
          .toList();
      expect(names, orderedEquals(<String>['ada', 'Zoe']));
    });

    testWidgets('narrows the list to what was searched for', (tester) async {
      labels.seed(label('rid-friend', 'Friend'));
      contacts
        ..seed(contact('c1', 'Marcus'))
        ..seed(contact('c2', 'Sam'));

      await pumpScreen(tester);
      await tester.enterText(
        find.byKey(ContactsScreen.searchKey),
        'marc',
      );
      await tester.pumpAndSettle();

      expect(find.text('Marcus'), findsOneWidget);
      expect(find.text('Sam'), findsNothing);
    });

    testWidgets('filters to one relationship label', (tester) async {
      labels
        ..seed(label('rid-friend', 'Friend'))
        ..seed(label('rid-family', 'Family', sortOrder: 1));
      contacts
        ..seed(contact('c1', 'Marcus'))
        ..seed(contact('c2', 'Ada', typeId: 'rid-family'));

      await pumpScreen(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Family'));
      await tester.pumpAndSettle();

      expect(find.text('Ada'), findsOneWidget);
      expect(find.text('Marcus'), findsNothing);
    });

    testWidgets('the All chip drops the label filter again', (tester) async {
      labels
        ..seed(label('rid-friend', 'Friend'))
        ..seed(label('rid-family', 'Family', sortOrder: 1));
      contacts
        ..seed(contact('c1', 'Marcus'))
        ..seed(contact('c2', 'Ada', typeId: 'rid-family'));

      await pumpScreen(tester);
      await tester.tap(find.widgetWithText(FilterChip, 'Family'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'All'));
      await tester.pumpAndSettle();

      expect(find.text('Marcus'), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget);
    });

    testWidgets('hides archived contacts until they are asked for', (
      tester,
    ) async {
      labels.seed(label('rid-friend', 'Friend'));
      contacts
        ..seed(contact('c1', 'Marcus'))
        ..seed(contact('c2', 'Beatrice', isArchived: true));

      await pumpScreen(tester);
      expect(find.text('Beatrice'), findsNothing);

      await tester.tap(find.widgetWithText(FilterChip, 'Archived'));
      await tester.pumpAndSettle();

      expect(find.text('Beatrice'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Archived'), findsWidgets);
    });

    testWidgets('reorders the list from the sort menu', (tester) async {
      labels.seed(label('rid-friend', 'Friend'));
      contacts
        ..seed(contact('c1', 'Ada', cadence: Cadence.quarterly))
        ..seed(contact('c2', 'Zoe', cadence: Cadence.weekly));

      await pumpScreen(tester);
      await tester.tap(find.byKey(ContactsScreen.sortKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('How often').last);
      await tester.pumpAndSettle();

      final names = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => (tile.title! as Text).data)
          .toList();
      expect(names, orderedEquals(<String>['Zoe', 'Ada']));
    });

    testWidgets('says so when nothing matches, and offers to clear', (
      tester,
    ) async {
      labels.seed(label('rid-friend', 'Friend'));
      contacts.seed(contact('c1', 'Marcus'));

      await pumpScreen(tester);
      await tester.enterText(find.byKey(ContactsScreen.searchKey), 'nobody');
      await tester.pumpAndSettle();

      expect(find.textContaining('Nothing matches'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('Marcus'), findsOneWidget);
    });

    testWidgets('asks for a label first when the household has none', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(
        find.textContaining('Add a relationship label first'),
        findsOneWidget,
      );
      expect(find.text('Manage labels'), findsOneWidget);
    });

    testWidgets('invites the first contact when there are none', (
      tester,
    ) async {
      labels.seed(label('rid-friend', 'Friend'));

      await pumpScreen(tester);

      expect(find.textContaining('Nobody here yet'), findsOneWidget);
    });

    testWidgets('offers the ways to add a contact and manage labels', (
      tester,
    ) async {
      labels.seed(label('rid-friend', 'Friend'));

      await pumpScreen(tester);

      expect(find.byKey(ContactsScreen.addKey), findsOneWidget);
      expect(find.byKey(ContactsScreen.labelsKey), findsOneWidget);
      expect(find.byIcon(KithIcons.add), findsOneWidget);
    });

    testWidgets('shows a failure the contact stream reports', (tester) async {
      contacts.streamFailure = const PermissionFailure('nope');

      await pumpScreen(tester);

      expect(
        find.textContaining('not allowed to change this household'),
        findsOneWidget,
      );
    });

    testWidgets('waits rather than guessing before the household is known', (
      tester,
    ) async {
      await tester.pumpApp(
        const ContactsScreen(),
        overrides: overrides(household: null),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(ContactsScreen.addKey), findsNothing);
    });

    testWidgets('picks up a contact added on another device', (tester) async {
      labels.seed(label('rid-friend', 'Friend'));

      await pumpScreen(tester);
      expect(find.text('Marcus'), findsNothing);

      contacts.seed(contact('c1', 'Marcus'));
      await tester.pumpAndSettle();

      expect(find.text('Marcus'), findsOneWidget);
    });
  });

  group('the freshness gauge', () {
    testWidgets('rings every row, and says how long it has been', (
      tester,
    ) async {
      labels.seed(label('rid-friend', 'Friend'));
      contacts.seed(contact('c1', 'Marcus'));
      seedHangout('h1', 1, ['c1']);

      await pumpScreen(tester);

      expect(find.byType(FreshnessGauge), findsOneWidget);
      expect(
        find.text('Friend  ·  Monthly  ·  Seen yesterday'),
        findsOneWidget,
      );
    });

    testWidgets('reads never logged for a contact with no hangout', (
      tester,
    ) async {
      labels.seed(label('rid-friend', 'Friend'));
      contacts.seed(contact('c1', 'Marcus'));

      await pumpScreen(tester);

      expect(find.textContaining('Never logged'), findsOneWidget);
      expect(
        tester
            .widget<FreshnessGauge>(find.byType(FreshnessGauge))
            .freshness
            .state,
        FreshnessState.never,
      );
    });

    testWidgets('moves the moment a hangout is logged elsewhere', (
      tester,
    ) async {
      labels.seed(label('rid-friend', 'Friend'));
      contacts.seed(contact('c1', 'Marcus'));

      await pumpScreen(tester);
      expect(find.textContaining('Never logged'), findsOneWidget);

      seedHangout('h1', 0, ['c1']);
      await tester.pumpAndSettle();

      expect(find.textContaining('Seen today'), findsOneWidget);
      expect(
        tester
            .widget<FreshnessGauge>(find.byType(FreshnessGauge))
            .freshness
            .state,
        FreshnessState.fresh,
      );
    });

    testWidgets('keeps the rows drawn when the timeline cannot be read', (
      tester,
    ) async {
      labels.seed(label('rid-friend', 'Friend'));
      contacts.seed(contact('c1', 'Marcus'));
      hangouts.streamFailure = const PermissionFailure('nope');

      await pumpScreen(tester);

      expect(find.text('Marcus'), findsOneWidget);
      expect(find.textContaining('Never logged'), findsOneWidget);
    });

    testWidgets('sorts the list by freshness from the sort menu', (
      tester,
    ) async {
      labels.seed(label('rid-friend', 'Friend'));
      contacts
        ..seed(contact('c1', 'Ada', cadence: Cadence.quarterly))
        ..seed(contact('c2', 'Zoe', cadence: Cadence.weekly));
      seedHangout('h1', 20, ['c1', 'c2']);

      await pumpScreen(tester);
      await tester.tap(find.byKey(ContactsScreen.sortKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ContactSort.freshness.label).last);
      await tester.pumpAndSettle();

      final names = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => (tile.title! as Text).data)
          .toList();
      expect(names, orderedEquals(<String>['Zoe', 'Ada']));
    });
  });
}
