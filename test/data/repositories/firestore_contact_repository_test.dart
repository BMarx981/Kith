import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/repositories/firestore_contact_repository.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/domain/contact_draft.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  const householdId = 'hid-1';
  final now = DateTime.utc(2026, 8, 18, 9);
  final later = DateTime.utc(2026, 9, 1, 9);

  const draft = ContactDraft(
    name: 'Marcus',
    relationshipTypeId: 'rid-1',
    cadence: Cadence.monthly,
    priority: ContactPriority.high,
    phone: '555-0100',
    guardianName: 'Dana',
    guardianPhone: '555-0199',
    tags: ['soccer'],
  );

  late FakeFirebaseFirestore firestore;
  late FirestoreContactRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreContactRepository(firestore, Clock.fixed(now));
  });

  CollectionReference<Map<String, dynamic>> contacts() => firestore
      .collection(FirestoreContactRepository.householdsPath)
      .doc(householdId)
      .collection(FirestoreContactRepository.contactsPath);

  Future<Contact> create([ContactDraft input = draft]) async {
    final result = await repository.createContact(
      householdId: householdId,
      draft: input,
    );
    return result.valueOrNull!;
  }

  group('createContact', () {
    test('stores the contact under the household', () async {
      final contact = await create();

      final stored = await contacts().doc(contact.id).get();
      expect(Contact.fromMap(stored.data()!), contact);
      expect(contact.name, 'Marcus');
      expect(contact.guardianName, 'Dana');
      expect(contact.tags, ['soccer']);
    });

    test('stamps both timestamps with the clock', () async {
      final contact = await create();

      expect(contact.createdAt, now);
      expect(contact.updatedAt, now);
    });

    test('starts a contact unarchived', () async {
      expect((await create()).isArchived, isFalse);
    });

    test('normalises what the editor collected', () async {
      final contact = await create(
        draft.copyWith(
          name: '  Marcus  ',
          phone: '  ',
          tags: const [' soccer ', 'Soccer'],
        ),
      );

      expect(contact.name, 'Marcus');
      expect(contact.phone, isNull);
      expect(contact.tags, ['soccer']);
    });

    test(
      'refuses a contact with no name, without touching the backend',
      () async {
        final result = await repository.createContact(
          householdId: householdId,
          draft: draft.copyWith(name: '   '),
        );

        expect(result.failureOrNull, isA<ValidationFailure>());
        expect((await contacts().get()).docs, isEmpty);
      },
    );

    test('refuses a contact with no relationship type', () async {
      final result = await repository.createContact(
        householdId: householdId,
        draft: draft.copyWith(relationshipTypeId: ' '),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('refuses a name past the length the rules allow', () async {
      final result = await repository.createContact(
        householdId: householdId,
        draft: draft.copyWith(name: 'a' * (Contact.maxNameLength + 1)),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('refuses an oversized detail, note, tag or tag list', () async {
      final oversized = <ContactDraft>[
        draft.copyWith(phone: 'a' * (Contact.maxDetailLength + 1)),
        draft.copyWith(guardianName: 'a' * (Contact.maxDetailLength + 1)),
        draft.copyWith(notes: 'a' * (Contact.maxNotesLength + 1)),
        draft.copyWith(
          tags: [for (var i = 0; i <= Contact.maxTags; i++) 'tag-$i'],
        ),
        draft.copyWith(tags: ['a' * (Contact.maxTagLength + 1)]),
      ];

      for (final input in oversized) {
        final result = await repository.createContact(
          householdId: householdId,
          draft: input,
        );
        expect(
          result.failureOrNull,
          isA<ValidationFailure>(),
          reason: '$input',
        );
      }
    });

    test('reports a refused write as a domain failure', () async {
      final contact = await create();
      whenCalling(Invocation.method(#update, null))
          .on(contacts().doc(contact.id))
          .thenThrow(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            ),
          );

      final result = await repository.updateContact(
        householdId: householdId,
        contactId: contact.id,
        draft: draft,
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });

  group('updateContact', () {
    test('applies every editable field', () async {
      final contact = await create();

      final result = await repository.updateContact(
        householdId: householdId,
        contactId: contact.id,
        draft: draft.copyWith(
          name: 'Marco',
          cadence: Cadence.weekly,
          priority: ContactPriority.low,
          clearPhone: true,
          notes: 'Moved house.',
        ),
      );

      expect(result.isOk, isTrue);
      final stored = Contact.fromMap(
        (await contacts().doc(contact.id).get()).data()!,
      );
      expect(stored.name, 'Marco');
      expect(stored.cadence, Cadence.weekly);
      expect(stored.priority, ContactPriority.low);
      expect(stored.phone, isNull);
      expect(stored.notes, 'Moved house.');
    });

    test('moves updatedAt on but leaves createdAt alone', () async {
      final contact = await create();

      await withClock(Clock.fixed(later), () async {
        await FirestoreContactRepository(
          firestore,
          Clock.fixed(later),
        ).updateContact(
          householdId: householdId,
          contactId: contact.id,
          draft: draft.copyWith(name: 'Marco'),
        );
      });

      final stored = Contact.fromMap(
        (await contacts().doc(contact.id).get()).data()!,
      );
      expect(stored.createdAt, now);
      expect(stored.updatedAt, later);
    });

    test('leaves an archived contact archived', () async {
      final contact = await create();
      await repository.setArchived(
        householdId: householdId,
        contactId: contact.id,
        isArchived: true,
      );

      await repository.updateContact(
        householdId: householdId,
        contactId: contact.id,
        draft: draft.copyWith(name: 'Marco'),
      );

      final stored = Contact.fromMap(
        (await contacts().doc(contact.id).get()).data()!,
      );
      expect(stored.isArchived, isTrue);
      expect(stored.name, 'Marco');
    });

    test('refuses an invalid draft without touching the backend', () async {
      final contact = await create();

      final result = await repository.updateContact(
        householdId: householdId,
        contactId: contact.id,
        draft: draft.copyWith(name: ''),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      final stored = Contact.fromMap(
        (await contacts().doc(contact.id).get()).data()!,
      );
      expect(stored.name, 'Marcus');
    });

    test('reports an update to a contact that is gone as not found', () async {
      final result = await repository.updateContact(
        householdId: householdId,
        contactId: 'cid-missing',
        draft: draft,
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('setArchived', () {
    test('archives and restores a contact', () async {
      final contact = await create();

      await repository.setArchived(
        householdId: householdId,
        contactId: contact.id,
        isArchived: true,
      );
      var stored = Contact.fromMap(
        (await contacts().doc(contact.id).get()).data()!,
      );
      expect(stored.isArchived, isTrue);

      await repository.setArchived(
        householdId: householdId,
        contactId: contact.id,
        isArchived: false,
      );
      stored = Contact.fromMap(
        (await contacts().doc(contact.id).get()).data()!,
      );
      expect(stored.isArchived, isFalse);
    });

    test('reports archiving a contact that is gone as not found', () async {
      final result = await repository.setArchived(
        householdId: householdId,
        contactId: 'cid-missing',
        isArchived: true,
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('watchContacts', () {
    test('emits the household contacts, archived ones included', () async {
      final first = await create();
      final second = await create(draft.copyWith(name: 'Sam'));
      await repository.setArchived(
        householdId: householdId,
        contactId: second.id,
        isArchived: true,
      );

      final contactsSeen = await repository.watchContacts(householdId).first;

      expect(contactsSeen.map((c) => c.id), containsAll([first.id, second.id]));
    });

    test('emits again when a contact changes', () async {
      final contact = await create();
      final emissions = repository.watchContacts(householdId);

      expect(
        emissions.map((list) => list.single.name),
        emitsInOrder(<String>['Marcus', 'Marco']),
      );

      await repository.updateContact(
        householdId: householdId,
        contactId: contact.id,
        draft: draft.copyWith(name: 'Marco'),
      );
    });

    test('emits an empty list for a household with no contacts', () async {
      expect(await repository.watchContacts('hid-empty').first, isEmpty);
    });

    test('reports a query that will not open as a domain failure', () async {
      final broken = _MockFirestore();
      when(() => broken.collection(any())).thenThrow(
        FirebaseException(plugin: 'firestore', code: 'permission-denied'),
      );

      expect(
        FirestoreContactRepository(broken).watchContacts(householdId),
        emitsError(isA<PermissionFailure>()),
      );
    });

    test('reports a contact that will not parse as a domain failure', () async {
      await contacts().doc('cid-broken').set({'id': 'cid-broken'});

      expect(
        repository.watchContacts(householdId),
        emitsError(isA<UnknownFailure>()),
      );
    });
  });
}
