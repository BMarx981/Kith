import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/presentation/relationship_types_screen.dart';
import 'package:kith/features/household/application/household_providers.dart';

import '../../../helpers/fake_relationship_type_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  const householdId = 'hid-1';
  final createdAt = DateTime.utc(2026, 8);

  late FakeRelationshipTypeRepository labels;

  setUp(() {
    labels = FakeRelationshipTypeRepository();
    addTearDown(labels.dispose);
  });

  List<Override> overrides({String? household = householdId}) => [
    currentHouseholdIdProvider.overrideWithValue(household),
    relationshipTypeRepositoryProvider.overrideWithValue(labels),
  ];

  void seed(List<String> names) {
    for (final (index, name) in names.indexed) {
      labels.seed(
        RelationshipType(
          id: 'rid-$index',
          name: name,
          sortOrder: index,
          createdAt: createdAt,
        ),
      );
    }
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    String? household = householdId,
  }) async {
    await tester.pumpApp(
      const RelationshipTypesScreen(),
      overrides: overrides(household: household),
    );
    await tester.pumpAndSettle();
  }

  group('RelationshipTypesScreen', () {
    testWidgets('lists the labels in their order', (tester) async {
      seed(['Friend', 'Family', 'Neighbor']);

      await pumpScreen(tester);

      final names = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => (tile.title! as Text).data)
          .toList();
      expect(names, orderedEquals(<String>['Friend', 'Family', 'Neighbor']));
    });

    testWidgets('invites a first label when there are none', (tester) async {
      await pumpScreen(tester);

      expect(find.textContaining('No labels yet'), findsOneWidget);
    });

    testWidgets('adds a label', (tester) async {
      seed(['Friend']);

      await pumpScreen(tester);
      await tester.tap(find.byKey(RelationshipTypesScreen.addKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(RelationshipTypesScreen.nameFieldKey),
        'Bookclub',
      );
      await tester.tap(find.byKey(RelationshipTypesScreen.confirmKey));
      await tester.pumpAndSettle();

      expect(labels.createCalls.single.name, 'Bookclub');
      expect(labels.createCalls.single.householdId, householdId);
      expect(find.text('Bookclub'), findsOneWidget);
    });

    testWidgets('refuses to add a label with no name', (tester) async {
      seed(['Friend']);

      await pumpScreen(tester);
      await tester.tap(find.byKey(RelationshipTypesScreen.addKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(RelationshipTypesScreen.confirmKey));
      await tester.pumpAndSettle();

      expect(find.text('Give the label a name.'), findsOneWidget);
      expect(labels.createCalls, isEmpty);
    });

    testWidgets('renames a label, starting from its current name', (
      tester,
    ) async {
      seed(['Neighbor']);

      await pumpScreen(tester);
      await tester.tap(find.byTooltip('Rename Neighbor'));
      await tester.pumpAndSettle();

      expect(find.text('Neighbor'), findsWidgets);

      await tester.enterText(
        find.byKey(RelationshipTypesScreen.nameFieldKey),
        'Neighbour',
      );
      await tester.tap(find.byKey(RelationshipTypesScreen.confirmKey));
      await tester.pumpAndSettle();

      expect(labels.renameCalls.single.name, 'Neighbour');
      expect(labels.renameCalls.single.typeId, 'rid-0');
    });

    testWidgets('asks where contacts go before deleting a label', (
      tester,
    ) async {
      seed(['Friend', 'Coworker']);

      await pumpScreen(tester);
      await tester.tap(find.byTooltip('Delete Coworker'));
      await tester.pumpAndSettle();

      expect(find.text('Delete "Coworker"'), findsOneWidget);

      await tester.tap(find.byKey(RelationshipTypesScreen.confirmKey));
      await tester.pumpAndSettle();

      expect(labels.deleteCalls.single.typeId, 'rid-1');
      expect(labels.deleteCalls.single.reassignToId, 'rid-0');
      expect(find.text('Coworker'), findsNothing);
    });

    testWidgets('moves the contacts to the label chosen in the dialog', (
      tester,
    ) async {
      seed(['Friend', 'Family', 'Coworker']);

      await pumpScreen(tester);
      await tester.tap(find.byTooltip('Delete Coworker'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Family').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(RelationshipTypesScreen.confirmKey));
      await tester.pumpAndSettle();

      expect(labels.deleteCalls.single.reassignToId, 'rid-1');
    });

    testWidgets('leaves the label alone when the dialog is dismissed', (
      tester,
    ) async {
      seed(['Friend', 'Coworker']);

      await pumpScreen(tester);
      await tester.tap(find.byTooltip('Delete Coworker'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(labels.deleteCalls, isEmpty);
      expect(find.text('Coworker'), findsOneWidget);
    });

    testWidgets('refuses to delete the only label', (tester) async {
      seed(['Friend']);

      await pumpScreen(tester);
      await tester.tap(find.byTooltip('Delete Friend'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Keep at least one label'), findsOneWidget);
      expect(labels.deleteCalls, isEmpty);
    });

    testWidgets('reorders labels by dragging one', (tester) async {
      seed(['Friend', 'Family', 'Neighbor']);

      await pumpScreen(tester);
      await tester.drag(
        find.byTooltip('Rename Neighbor'),
        const Offset(0, -140),
      );
      await tester.pumpAndSettle();

      expect(labels.reorderCalls, isEmpty, reason: 'a rename is not a drag');

      final handle = find.byIcon(KithIcons.reorder).first;
      await tester.timedDrag(
        handle,
        const Offset(0, 120),
        const Duration(milliseconds: 500),
      );
      await tester.pumpAndSettle();

      expect(labels.reorderCalls, hasLength(1));
      expect(
        labels.reorderCalls.single.orderedIds.first,
        isNot('rid-0'),
        reason: 'the dragged label moved off the top',
      );
    });

    testWidgets('shows why the backend refused a write', (tester) async {
      seed(['Friend']);
      labels.nextFailure = const ConflictFailure('duplicate');

      await pumpScreen(tester);
      await tester.tap(find.byKey(RelationshipTypesScreen.addKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(RelationshipTypesScreen.nameFieldKey),
        'friend',
      );
      await tester.tap(find.byKey(RelationshipTypesScreen.confirmKey));
      await tester.pumpAndSettle();

      expect(find.text('That label already exists.'), findsOneWidget);
    });

    testWidgets('shows a failure the label stream reports', (tester) async {
      labels.streamFailure = const PermissionFailure('nope');

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
        const RelationshipTypesScreen(),
        overrides: overrides(household: null),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(RelationshipTypesScreen.addKey), findsNothing);
    });
  });
}
