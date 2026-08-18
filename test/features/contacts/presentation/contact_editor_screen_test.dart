import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/presentation/contact_editor_screen.dart';
import 'package:kith/features/household/application/household_providers.dart';

import '../../../helpers/fake_contact_repository.dart';
import '../../../helpers/fake_relationship_type_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  const householdId = 'hid-1';
  final createdAt = DateTime.utc(2026, 8);

  late FakeContactRepository contacts;
  late FakeRelationshipTypeRepository labels;

  setUp(() {
    contacts = FakeContactRepository();
    addTearDown(contacts.dispose);
    labels = FakeRelationshipTypeRepository();
    addTearDown(labels.dispose);
  });

  List<Override> overrides() => [
    currentHouseholdIdProvider.overrideWithValue(householdId),
    contactRepositoryProvider.overrideWithValue(contacts),
    relationshipTypeRepositoryProvider.overrideWithValue(labels),
  ];

  void seedLabels() {
    labels
      ..seed(
        RelationshipType(
          id: 'rid-friend',
          name: 'Friend',
          sortOrder: 0,
          createdAt: createdAt,
        ),
      )
      ..seed(
        RelationshipType(
          id: 'rid-family',
          name: 'Family',
          sortOrder: 1,
          createdAt: createdAt,
        ),
      );
  }

  Contact seedContact({bool isArchived = false}) {
    final contact = Contact(
      id: 'cid-1',
      name: 'Marcus',
      relationshipTypeId: 'rid-friend',
      cadence: Cadence.monthly,
      priority: ContactPriority.high,
      createdAt: createdAt,
      updatedAt: createdAt,
      phone: '555-0100',
      guardianName: 'Dana',
      notes: 'Allergic to cats.',
      tags: const ['soccer', 'school'],
      isArchived: isArchived,
    );
    contacts.seed(contact);
    return contact;
  }

  Future<void> pumpEditor(WidgetTester tester, {String? contactId}) async {
    // Tall enough that the whole form fits: the editor collects a dozen
    // fields, and a test that has to scroll to reach the save button says
    // less about the form than about the window it was given.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpApp(
      ContactEditorScreen(contactId: contactId),
      overrides: overrides(),
    );
    await tester.pumpAndSettle();
  }

  group('ContactEditorScreen adding', () {
    testWidgets('stores what the form collected', (tester) async {
      seedLabels();

      await pumpEditor(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Marcus',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone'),
        '555-0100',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Guardian name'),
        'Dana',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tags'),
        'soccer, school',
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Weekly'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'High'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ContactEditorScreen.saveKey));
      await tester.pumpAndSettle();

      final draft = contacts.createCalls.single.draft.normalised();
      expect(contacts.createCalls.single.householdId, householdId);
      expect(draft.name, 'Marcus');
      expect(draft.phone, '555-0100');
      expect(draft.guardianName, 'Dana');
      expect(draft.tags, orderedEquals(<String>['soccer', 'school']));
      expect(draft.cadence, Cadence.weekly);
      expect(draft.priority, ContactPriority.high);
      expect(draft.relationshipTypeId, 'rid-friend');
    });

    testWidgets('refuses to store a contact with no name', (tester) async {
      seedLabels();

      await pumpEditor(tester);
      await tester.tap(find.byKey(ContactEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(find.text('Give the contact a name.'), findsOneWidget);
      expect(contacts.createCalls, isEmpty);
    });

    testWidgets('takes a custom cadence in days', (tester) async {
      seedLabels();

      await pumpEditor(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Marcus',
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Custom'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Every how many days'),
        '45',
      );
      await tester.tap(find.byKey(ContactEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(
        contacts.createCalls.single.draft.cadence,
        const Cadence.custom(45),
      );
    });

    testWidgets('refuses a custom cadence that is not a day count', (
      tester,
    ) async {
      seedLabels();

      await pumpEditor(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Marcus',
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Custom'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Every how many days'),
        'soon',
      );
      await tester.tap(find.byKey(ContactEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(find.text('Use a whole number of days.'), findsOneWidget);
      expect(contacts.createCalls, isEmpty);
    });

    testWidgets('shows why the backend refused the save', (tester) async {
      seedLabels();
      contacts.nextFailure = const NetworkFailure('offline');

      await pumpEditor(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Marcus',
      );
      await tester.tap(find.byKey(ContactEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(find.textContaining('You appear to be offline'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'Name'),
        findsOneWidget,
        reason: 'a refused save leaves the form up with what was typed',
      );
    });

    testWidgets('offers no archive action for a contact that is not saved', (
      tester,
    ) async {
      seedLabels();

      await pumpEditor(tester);

      expect(find.byKey(ContactEditorScreen.archiveKey), findsNothing);
    });

    testWidgets('offers no history for a contact that is not saved', (
      tester,
    ) async {
      seedLabels();

      await pumpEditor(tester);

      expect(find.byKey(ContactEditorScreen.historyKey), findsNothing);
    });

    testWidgets("offers the way through to an existing contact's hangouts", (
      tester,
    ) async {
      seedLabels();
      seedContact();

      await pumpEditor(tester, contactId: 'cid-1');

      expect(find.byKey(ContactEditorScreen.historyKey), findsOneWidget);
      expect(find.text('See their hangouts'), findsOneWidget);
    });

    testWidgets('says a label is needed before a contact can be filed', (
      tester,
    ) async {
      await pumpEditor(tester);

      expect(
        find.textContaining('Add a relationship label first'),
        findsOneWidget,
      );
      expect(find.byKey(ContactEditorScreen.saveKey), findsNothing);
    });
  });

  group('ContactEditorScreen editing', () {
    testWidgets('opens with the contact already in the fields', (tester) async {
      seedLabels();
      seedContact();

      await pumpEditor(tester, contactId: 'cid-1');

      expect(find.text('Marcus'), findsOneWidget);
      expect(find.text('555-0100'), findsOneWidget);
      expect(find.text('Dana'), findsOneWidget);
      expect(find.text('soccer, school'), findsOneWidget);
      expect(find.text('Allergic to cats.'), findsOneWidget);
      expect(find.text('Edit contact'), findsOneWidget);
    });

    testWidgets('opens a custom cadence on the custom option', (tester) async {
      seedLabels();
      contacts.seed(
        Contact(
          id: 'cid-2',
          name: 'Sam',
          relationshipTypeId: 'rid-friend',
          cadence: const Cadence.custom(45),
          priority: ContactPriority.normal,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );

      await pumpEditor(tester, contactId: 'cid-2');

      expect(
        find.widgetWithText(TextFormField, 'Every how many days'),
        findsOneWidget,
      );
      expect(find.text('45'), findsOneWidget);
    });

    testWidgets('updates the contact it was opened on', (tester) async {
      seedLabels();
      seedContact();

      await pumpEditor(tester, contactId: 'cid-1');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Marco',
      );
      await tester.tap(find.byKey(ContactEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(contacts.updateCalls.single.contactId, 'cid-1');
      expect(contacts.updateCalls.single.draft.name, 'Marco');
      expect(contacts.createCalls, isEmpty);
    });

    testWidgets('moves the contact to a different label', (tester) async {
      seedLabels();
      seedContact();

      await pumpEditor(tester, contactId: 'cid-1');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Family').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ContactEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(
        contacts.updateCalls.single.draft.relationshipTypeId,
        'rid-family',
      );
    });

    testWidgets('clears a detail that was emptied', (tester) async {
      seedLabels();
      seedContact();

      await pumpEditor(tester, contactId: 'cid-1');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone'),
        '',
      );
      await tester.tap(find.byKey(ContactEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(contacts.updateCalls.single.draft.normalised().phone, isNull);
    });

    testWidgets('archives the contact', (tester) async {
      seedLabels();
      seedContact();

      await pumpEditor(tester, contactId: 'cid-1');
      await tester.tap(find.byKey(ContactEditorScreen.archiveKey));
      await tester.pumpAndSettle();

      expect(contacts.archiveCalls.single.contactId, 'cid-1');
      expect(contacts.archiveCalls.single.isArchived, isTrue);
    });

    testWidgets('offers to restore an archived contact', (tester) async {
      seedLabels();
      seedContact(isArchived: true);

      await pumpEditor(tester, contactId: 'cid-1');

      expect(find.text('Restore contact'), findsOneWidget);

      await tester.tap(find.byKey(ContactEditorScreen.archiveKey));
      await tester.pumpAndSettle();

      expect(contacts.archiveCalls.single.isArchived, isFalse);
    });

    testWidgets('says so when the contact is no longer there', (tester) async {
      seedLabels();

      await pumpEditor(tester, contactId: 'cid-gone');

      expect(find.text('That contact is no longer here.'), findsOneWidget);
    });

    testWidgets('falls back to the first label when the old one is gone', (
      tester,
    ) async {
      seedLabels();
      contacts.seed(
        Contact(
          id: 'cid-3',
          name: 'Orphan',
          relationshipTypeId: 'rid-deleted',
          cadence: Cadence.monthly,
          priority: ContactPriority.normal,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );

      await pumpEditor(tester, contactId: 'cid-3');
      await tester.tap(find.byKey(ContactEditorScreen.saveKey));
      await tester.pumpAndSettle();

      expect(
        contacts.updateCalls.single.draft.relationshipTypeId,
        'rid-friend',
      );
    });
  });
}
