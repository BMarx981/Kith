import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/application/relationship_type_controller.dart';
import 'package:kith/features/contacts/application/save_state.dart';

import '../../../helpers/fake_relationship_type_repository.dart';

void main() {
  const householdId = 'hid-1';

  late FakeRelationshipTypeRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeRelationshipTypeRepository();
    addTearDown(repository.dispose);
    container = ProviderContainer(
      overrides: [
        relationshipTypeRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
  });

  SaveState read() => container.read(relationshipTypeControllerProvider);
  RelationshipTypeController controller() =>
      container.read(relationshipTypeControllerProvider.notifier);

  group('RelationshipTypeController', () {
    test('starts idle', () {
      expect(read(), const SaveState());
    });

    test('adds a label', () async {
      final added = await controller().add(
        householdId: householdId,
        name: 'Bookclub',
      );

      expect(added, isTrue);
      expect(repository.createCalls.single.name, 'Bookclub');
    });

    test('renames a label', () async {
      await controller().add(householdId: householdId, name: 'Neighbor');

      final renamed = await controller().rename(
        householdId: householdId,
        typeId: 'rid-1',
        name: 'Neighbour',
      );

      expect(renamed, isTrue);
      expect(repository.types['rid-1']!.name, 'Neighbour');
    });

    test('reorders the labels', () async {
      await controller().add(householdId: householdId, name: 'Friend');
      await controller().add(householdId: householdId, name: 'Family');

      final reordered = await controller().reorder(
        householdId: householdId,
        orderedIds: ['rid-2', 'rid-1'],
      );

      expect(reordered, isTrue);
      expect(repository.types['rid-2']!.sortOrder, 0);
    });

    test('deletes a label, naming where its contacts go', () async {
      await controller().add(householdId: householdId, name: 'Friend');
      await controller().add(householdId: householdId, name: 'Coworker');

      final deleted = await controller().delete(
        householdId: householdId,
        typeId: 'rid-2',
        reassignToId: 'rid-1',
      );

      expect(deleted, isTrue);
      expect(repository.deleteCalls.single.reassignToId, 'rid-1');
      expect(repository.types.containsKey('rid-2'), isFalse);
    });

    test('reports the failure a refused write came back with', () async {
      repository.nextFailure = const ConflictFailure('duplicate');

      final added = await controller().add(
        householdId: householdId,
        name: 'Friend',
      );

      expect(added, isFalse);
      expect(read().failure, isA<ConflictFailure>());
      expect(read().isSubmitting, isFalse);
    });

    test('drops the failure when asked to', () async {
      repository.nextFailure = const ConflictFailure('duplicate');
      await controller().add(householdId: householdId, name: 'Friend');

      controller().clearFailure();

      expect(read().failure, isNull);
    });

    test('holds the manager inert while a write is in flight', () async {
      repository.gate = Completer<void>();

      final first = controller().add(householdId: householdId, name: 'Friend');
      await Future<void>.delayed(Duration.zero);
      expect(read().isSubmitting, isTrue);

      final second = await controller().add(
        householdId: householdId,
        name: 'Friend',
      );
      expect(second, isFalse);

      repository.gate!.complete();
      await first;
      expect(repository.createCalls, hasLength(1));
    });
  });
}
