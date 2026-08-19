import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/data/services/device_contact_directory.dart';
import 'package:kith/features/contacts/application/contact_import_controller.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/presentation/contact_import_screen.dart';
import 'package:kith/features/household/application/household_providers.dart';

import '../../../helpers/fake_contact_repository.dart';
import '../../../helpers/fake_device_contact_directory.dart';
import '../../../helpers/fake_relationship_type_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  const householdId = 'hid-1';

  late FakeContactRepository contacts;
  late FakeRelationshipTypeRepository labels;
  late FakeDeviceContactDirectory directory;

  setUp(() {
    contacts = FakeContactRepository();
    addTearDown(contacts.dispose);
    labels = FakeRelationshipTypeRepository();
    addTearDown(labels.dispose);
    directory = FakeDeviceContactDirectory();
  });

  List<Override> overrides() => [
    currentHouseholdIdProvider.overrideWithValue(householdId),
    contactRepositoryProvider.overrideWithValue(contacts),
    relationshipTypeRepositoryProvider.overrideWithValue(labels),
    deviceContactDirectoryProvider.overrideWithValue(directory),
  ];

  void seedLabels() {
    for (final (index, name) in ['Friend', 'Neighbor'].indexed) {
      labels.seed(
        RelationshipType(
          id: 'rid-$index',
          name: name,
          sortOrder: index,
          createdAt: DateTime.utc(2026),
        ),
      );
    }
  }

  void seedDevice(String id, String name, {String? phone}) =>
      directory.seed(DeviceContact(id: id, name: name, phone: phone));

  void seedExisting(String name) => contacts.seed(
    Contact(
      id: 'cid-$name',
      name: name,
      relationshipTypeId: 'rid-0',
      cadence: Cadence.monthly,
      priority: ContactPriority.normal,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    ),
  );

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpApp(const ContactImportScreen(), overrides: overrides());
    await tester.pumpAndSettle();
  }

  /// Gets past the intro step and onto the list.
  Future<void> readContacts(WidgetTester tester) async {
    await tester.tap(find.byKey(ContactImportScreen.readKey));
    await tester.pumpAndSettle();
  }

  group('before the address book is read', () {
    testWidgets('says what it will do and touches nothing yet', (tester) async {
      seedLabels();

      await pumpScreen(tester);

      expect(find.textContaining('Nothing is sent anywhere'), findsOneWidget);
      expect(directory.permissionAsks, 0);
      expect(directory.reads, 0);
    });

    testWidgets('refuses to start without a relationship label', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(
        find.textContaining('Add a relationship label first'),
        findsOneWidget,
      );
      expect(find.byKey(ContactImportScreen.readKey), findsNothing);
    });
  });

  group('the list', () {
    testWidgets('shows everybody, sorted, with duplicates marked', (
      tester,
    ) async {
      seedLabels();
      seedDevice('row-m', 'Marcus Bell', phone: '555-0100');
      seedDevice('row-a', 'Ana Reyes');
      seedExisting('Marcus Bell');

      await pumpScreen(tester);
      await readContacts(tester);

      expect(find.text('Ana Reyes'), findsOneWidget);
      expect(find.text('Marcus Bell'), findsOneWidget);
      expect(find.text('Already in Kith'), findsOneWidget);
      expect(find.text('No details'), findsOneWidget);
      expect(find.text('Nobody chosen'), findsOneWidget);
    });

    testWidgets('says when the address book is empty', (tester) async {
      seedLabels();

      await pumpScreen(tester);
      await readContacts(tester);

      expect(
        find.textContaining('nobody in your address book'),
        findsOneWidget,
      );
    });

    testWidgets('a duplicate cannot be ticked', (tester) async {
      seedLabels();
      seedDevice('row-m', 'Marcus Bell');
      seedExisting('Marcus Bell');

      await pumpScreen(tester);
      await readContacts(tester);
      await tester.tap(find.byKey(ContactImportScreen.rowKey('row-m')));
      await tester.pumpAndSettle();

      expect(find.text('Nobody chosen'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(ContactImportScreen.importKey))
            .onPressed,
        isNull,
      );
    });

    testWidgets('ticking somebody arms the import button', (tester) async {
      seedLabels();
      seedDevice('row-a', 'Ana Reyes');

      await pumpScreen(tester);
      await readContacts(tester);
      await tester.tap(find.byKey(ContactImportScreen.rowKey('row-a')));
      await tester.pumpAndSettle();

      expect(find.text('1 chosen'), findsOneWidget);
      expect(find.text('Import 1 contact'), findsOneWidget);
    });

    testWidgets('All ticks everybody importable, then None clears', (
      tester,
    ) async {
      seedLabels();
      seedDevice('row-a', 'Ana Reyes');
      seedDevice('row-b', 'Ben Okafor');

      await pumpScreen(tester);
      await readContacts(tester);
      await tester.tap(find.byKey(ContactImportScreen.selectAllKey));
      await tester.pumpAndSettle();

      expect(find.text('2 chosen'), findsOneWidget);
      expect(find.text('Import 2 contacts'), findsOneWidget);

      await tester.tap(find.byKey(ContactImportScreen.selectAllKey));
      await tester.pumpAndSettle();

      expect(find.text('Nobody chosen'), findsOneWidget);
    });
  });

  group('importing', () {
    testWidgets('files everybody under the chosen label and cadence', (
      tester,
    ) async {
      seedLabels();
      seedDevice('row-a', 'Ana Reyes', phone: '555-0200');

      await pumpScreen(tester);
      await readContacts(tester);
      await tester.tap(find.byKey(ContactImportScreen.selectAllKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ContactImportScreen.labelKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Neighbor').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ContactImportScreen.cadenceKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Weekly').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ContactImportScreen.importKey));
      await tester.pumpAndSettle();

      final call = contacts.createCalls.single;
      expect(call.draft.name, 'Ana Reyes');
      expect(call.draft.phone, '555-0200');
      expect(call.draft.relationshipTypeId, 'rid-1');
      expect(call.draft.cadence, Cadence.weekly);
      expect(find.text('1 contact added.'), findsOneWidget);
    });

    testWidgets('counts more than one in the plural', (tester) async {
      seedLabels();
      seedDevice('row-a', 'Ana Reyes');
      seedDevice('row-b', 'Ben Okafor');

      await pumpScreen(tester);
      await readContacts(tester);
      await tester.tap(find.byKey(ContactImportScreen.selectAllKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ContactImportScreen.importKey));
      await tester.pumpAndSettle();

      expect(find.text('2 contacts added.'), findsOneWidget);
    });

    testWidgets('stays on the list and says so when a write is refused', (
      tester,
    ) async {
      seedLabels();
      seedDevice('row-a', 'Ana Reyes');
      contacts.nextFailure = const NetworkFailure('offline');

      await pumpScreen(tester);
      await readContacts(tester);
      await tester.tap(find.byKey(ContactImportScreen.selectAllKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ContactImportScreen.importKey));
      await tester.pumpAndSettle();

      expect(find.text('Ana Reyes'), findsOneWidget);
      expect(find.textContaining('once you are connected'), findsOneWidget);
    });
  });

  group('permission', () {
    testWidgets('says where to look when the prompt is declined', (
      tester,
    ) async {
      seedLabels();
      directory.permissionGranted = false;

      await pumpScreen(tester);
      await readContacts(tester);

      expect(
        find.textContaining('Allow access in your phone settings'),
        findsOneWidget,
      );
    });

    testWidgets('reports a read that failed, and offers to try again', (
      tester,
    ) async {
      seedLabels();
      directory.nextFailure = const PermissionFailure('revoked');

      await pumpScreen(tester);
      await readContacts(tester);

      expect(find.byKey(ContactImportScreen.readKey), findsOneWidget);
      expect(find.textContaining('not allowed'), findsOneWidget);
    });
  });
}
