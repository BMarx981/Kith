import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/cadence.dart';

import '../../../helpers/fake_contact_repository.dart';
import '../../../helpers/fake_relationship_type_repository.dart';

void main() {
  const householdId = 'hid-1';
  final createdAt = DateTime.utc(2026, 8);

  late FakeContactRepository contacts;
  late FakeRelationshipTypeRepository labels;
  late ProviderContainer container;

  setUp(() {
    contacts = FakeContactRepository();
    addTearDown(contacts.dispose);
    labels = FakeRelationshipTypeRepository();
    addTearDown(labels.dispose);
    container = ProviderContainer(
      overrides: [
        contactRepositoryProvider.overrideWithValue(contacts),
        relationshipTypeRepositoryProvider.overrideWithValue(labels),
      ],
    );
    addTearDown(container.dispose);
  });

  /// Subscribes before awaiting the first value. A stream provider only runs
  /// while something listens to it, so reading `.future` on its own would
  /// wait forever.
  Future<T> firstValueOf<T>(StreamProvider<T> provider) {
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);
    return container.read(provider.future);
  }

  group('repository providers', () {
    test('throw until the composition root overrides them', () {
      final bare = ProviderContainer();
      addTearDown(bare.dispose);

      for (final provider in [
        contactRepositoryProvider,
        relationshipTypeRepositoryProvider,
      ]) {
        expect(
          () => bare.read(provider),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.exception,
              'exception',
              isUnimplementedError,
            ),
          ),
        );
      }
    });
  });

  group('contactsProvider', () {
    test('emits the household contacts', () async {
      contacts.seed(
        Contact(
          id: 'cid-1',
          name: 'Marcus',
          relationshipTypeId: 'rid-1',
          cadence: Cadence.monthly,
          priority: ContactPriority.normal,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );

      final emitted = await firstValueOf(contactsProvider(householdId));

      expect(emitted.single.name, 'Marcus');
    });

    test('is scoped per household', () {
      expect(
        contactsProvider(householdId),
        isNot(contactsProvider('hid-2')),
      );
    });
  });

  group('relationshipTypesProvider', () {
    test('emits the household labels in order', () async {
      labels
        ..seed(
          RelationshipType(
            id: 'rid-2',
            name: 'Family',
            sortOrder: 1,
            createdAt: createdAt,
          ),
        )
        ..seed(
          RelationshipType(
            id: 'rid-1',
            name: 'Friend',
            sortOrder: 0,
            createdAt: createdAt,
          ),
        );

      final emitted = await firstValueOf(
        relationshipTypesProvider(householdId),
      );

      expect(
        emitted.map((type) => type.name),
        orderedEquals(<String>['Friend', 'Family']),
      );
    });

    test('is scoped per household', () {
      expect(
        relationshipTypesProvider(householdId),
        isNot(relationshipTypesProvider('hid-2')),
      );
    });
  });
}
