import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/data/repositories/firestore_contact_repository.dart';
import 'package:kith/data/repositories/firestore_relationship_type_repository.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/domain/contact_draft.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  const householdId = 'hid-1';
  final now = DateTime.utc(2026, 8, 18, 9);

  late FakeFirebaseFirestore firestore;
  late FirestoreRelationshipTypeRepository repository;
  late FirestoreContactRepository contactRepository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreRelationshipTypeRepository(
      firestore,
      Clock.fixed(now),
    );
    contactRepository = FirestoreContactRepository(firestore, Clock.fixed(now));
  });

  CollectionReference<Map<String, dynamic>> types() => firestore
      .collection(FirestoreRelationshipTypeRepository.householdsPath)
      .doc(householdId)
      .collection(
        FirestoreRelationshipTypeRepository.relationshipTypesPath,
      );

  Future<RelationshipType> createType(String name) async {
    final result = await repository.createRelationshipType(
      householdId: householdId,
      name: name,
    );
    return result.valueOrNull!;
  }

  Future<Contact> createContact(String name, String typeId) async {
    final result = await contactRepository.createContact(
      householdId: householdId,
      draft: ContactDraft(
        name: name,
        relationshipTypeId: typeId,
        cadence: Cadence.monthly,
      ),
    );
    return result.valueOrNull!;
  }

  group('seedDefaults', () {
    test('writes the starter set in order', () async {
      final result = await repository.seedDefaults(householdId);

      expect(
        result.valueOrNull!.map((t) => t.name),
        orderedEquals(RelationshipType.defaultNames),
      );
      expect(
        result.valueOrNull!.map((t) => t.sortOrder),
        orderedEquals(
          List.generate(RelationshipType.defaultNames.length, (i) => i),
        ),
      );
      expect((await types().get()).docs, hasLength(5));
    });

    test('stamps the seeded labels with the clock', () async {
      final result = await repository.seedDefaults(householdId);

      expect(result.valueOrNull!.every((t) => t.createdAt == now), isTrue);
    });

    test('leaves a household that already has labels untouched', () async {
      final existing = await createType('Bookclub');

      final result = await repository.seedDefaults(householdId);

      expect(result.valueOrNull, [existing]);
      expect((await types().get()).docs, hasLength(1));
    });

    test('reports a refused read as a domain failure', () async {
      final broken = _MockFirestore();
      when(() => broken.collection(any())).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        ),
      );

      final result = await FirestoreRelationshipTypeRepository(
        broken,
      ).seedDefaults(householdId);

      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });

  group('createRelationshipType', () {
    test('appends the label past the current end of the list', () async {
      await repository.seedDefaults(householdId);

      final added = await createType('Bookclub');

      expect(added.sortOrder, RelationshipType.defaultNames.length);
      expect(added.createdAt, now);
    });

    test('starts a fresh household at sort order zero', () async {
      expect((await createType('Friend')).sortOrder, 0);
    });

    test('trims the name', () async {
      expect((await createType('  Bookclub  ')).name, 'Bookclub');
    });

    test('refuses a blank name without touching the backend', () async {
      final result = await repository.createRelationshipType(
        householdId: householdId,
        name: '   ',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((await types().get()).docs, isEmpty);
    });

    test('refuses a name past the length the rules allow', () async {
      final result = await repository.createRelationshipType(
        householdId: householdId,
        name: 'a' * (RelationshipType.maxNameLength + 1),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('refuses a duplicate, whatever its casing', () async {
      await createType('Neighbor');

      final result = await repository.createRelationshipType(
        householdId: householdId,
        name: '  neighbor ',
      );

      expect(result.failureOrNull, isA<ConflictFailure>());
      expect((await types().get()).docs, hasLength(1));
    });
  });

  group('renameRelationshipType', () {
    test('renames the label, reaching every contact filed under it', () async {
      final type = await createType('Neighbor');
      final contact = await createContact('Marcus', type.id);

      final result = await repository.renameRelationshipType(
        householdId: householdId,
        typeId: type.id,
        name: 'Neighbour',
      );

      expect(result.isOk, isTrue);
      expect(
        RelationshipType.fromMap(
          (await types().doc(type.id).get()).data()!,
        ).name,
        'Neighbour',
      );
      final stored = await firestore
          .collection(FirestoreContactRepository.householdsPath)
          .doc(householdId)
          .collection(FirestoreContactRepository.contactsPath)
          .doc(contact.id)
          .get();
      expect(stored.data()!['relationshipTypeId'], type.id);
    });

    test('lets a label keep its own name, in a new casing', () async {
      final type = await createType('Neighbor');

      final result = await repository.renameRelationshipType(
        householdId: householdId,
        typeId: type.id,
        name: 'neighbor',
      );

      expect(result.isOk, isTrue);
    });

    test('refuses a name another label already has', () async {
      await createType('Family');
      final type = await createType('Neighbor');

      final result = await repository.renameRelationshipType(
        householdId: householdId,
        typeId: type.id,
        name: 'family',
      );

      expect(result.failureOrNull, isA<ConflictFailure>());
    });

    test('refuses a blank name', () async {
      final type = await createType('Neighbor');

      final result = await repository.renameRelationshipType(
        householdId: householdId,
        typeId: type.id,
        name: ' ',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('reports renaming a label that is gone as not found', () async {
      final result = await repository.renameRelationshipType(
        householdId: householdId,
        typeId: 'rid-missing',
        name: 'Neighbour',
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('reorderRelationshipTypes', () {
    test('renumbers the labels to match the order given', () async {
      final first = await createType('Friend');
      final second = await createType('Family');
      final third = await createType('Neighbor');

      final result = await repository.reorderRelationshipTypes(
        householdId: householdId,
        orderedIds: [third.id, first.id, second.id],
      );

      expect(result.isOk, isTrue);
      expect(
        (await repository.watchRelationshipTypes(householdId).first).map(
          (t) => t.name,
        ),
        orderedEquals(<String>['Neighbor', 'Friend', 'Family']),
      );
    });

    test('accepts an empty order as a no-op', () async {
      await createType('Friend');

      final result = await repository.reorderRelationshipTypes(
        householdId: householdId,
        orderedIds: const [],
      );

      expect(result.isOk, isTrue);
    });
  });

  group('deleteRelationshipType', () {
    test('deletes the label and moves its contacts to the target', () async {
      final doomed = await createType('Coworker');
      final target = await createType('Friend');
      final moved = await createContact('Marcus', doomed.id);
      final untouched = await createContact('Sam', target.id);

      final result = await repository.deleteRelationshipType(
        householdId: householdId,
        typeId: doomed.id,
        reassignToId: target.id,
      );

      expect(result.isOk, isTrue);
      expect((await types().doc(doomed.id).get()).exists, isFalse);
      final contacts = await contactRepository.watchContacts(householdId).first;
      expect(
        contacts.firstWhere((c) => c.id == moved.id).relationshipTypeId,
        target.id,
      );
      expect(
        contacts.firstWhere((c) => c.id == untouched.id).relationshipTypeId,
        target.id,
      );
    });

    test('stamps the moved contacts as edited', () async {
      final doomed = await createType('Coworker');
      final target = await createType('Friend');
      final moved = await createContact('Marcus', doomed.id);
      final later = DateTime.utc(2026, 9);

      await FirestoreRelationshipTypeRepository(
        firestore,
        Clock.fixed(later),
      ).deleteRelationshipType(
        householdId: householdId,
        typeId: doomed.id,
        reassignToId: target.id,
      );

      final contacts = await contactRepository.watchContacts(householdId).first;
      expect(contacts.firstWhere((c) => c.id == moved.id).updatedAt, later);
    });

    test('deletes a label nothing is filed under', () async {
      final doomed = await createType('Coworker');
      final target = await createType('Friend');

      final result = await repository.deleteRelationshipType(
        householdId: householdId,
        typeId: doomed.id,
        reassignToId: target.id,
      );

      expect(result.isOk, isTrue);
      expect((await types().doc(doomed.id).get()).exists, isFalse);
    });

    test('refuses to reassign a label to itself', () async {
      final type = await createType('Coworker');
      await createContact('Marcus', type.id);

      final result = await repository.deleteRelationshipType(
        householdId: householdId,
        typeId: type.id,
        reassignToId: type.id,
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((await types().doc(type.id).get()).exists, isTrue);
    });

    test('refuses a target that no longer exists, keeping the label', () async {
      final type = await createType('Coworker');

      final result = await repository.deleteRelationshipType(
        householdId: householdId,
        typeId: type.id,
        reassignToId: 'rid-missing',
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
      expect((await types().doc(type.id).get()).exists, isTrue);
    });
  });

  group('watchRelationshipTypes', () {
    test('emits the labels in their sort order', () async {
      await repository.seedDefaults(householdId);

      final emitted = await repository
          .watchRelationshipTypes(householdId)
          .first;

      expect(
        emitted.map((t) => t.name),
        orderedEquals(RelationshipType.defaultNames),
      );
    });

    test('emits again when a label is added', () async {
      await createType('Friend');

      expect(
        repository.watchRelationshipTypes(householdId).map((l) => l.length),
        emitsInOrder(<int>[1, 2]),
      );

      await createType('Family');
    });

    test('emits an empty list for a household with no labels', () async {
      expect(
        await repository.watchRelationshipTypes('hid-empty').first,
        isEmpty,
      );
    });

    test('reports a query that will not open as a domain failure', () async {
      final broken = _MockFirestore();
      when(() => broken.collection(any())).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        ),
      );

      expect(
        FirestoreRelationshipTypeRepository(
          broken,
        ).watchRelationshipTypes(householdId),
        emitsError(isA<PermissionFailure>()),
      );
    });

    test('reports a label that will not parse as a domain failure', () async {
      await types().doc('rid-broken').set({'id': 'rid-broken', 'sortOrder': 0});

      expect(
        repository.watchRelationshipTypes(householdId),
        emitsError(isA<UnknownFailure>()),
      );
    });
  });
}
