import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/features/contacts/domain/cadence.dart';

import '../../helpers/model_test_helpers.dart';

void main() {
  final createdAt = DateTime.utc(2026, 4, 1, 12);
  final updatedAt = DateTime.utc(2026, 5, 2, 9);
  final sample = Contact(
    id: 'cid-1',
    name: 'Marcus',
    relationshipTypeId: 'rid-1',
    cadence: Cadence.monthly,
    priority: ContactPriority.high,
    phone: '555-0100',
    email: 'marcus@example.com',
    address: '12 Elm Street',
    guardianName: 'Dana',
    guardianPhone: '555-0199',
    notes: 'Allergic to cats.',
    tags: const ['soccer', 'school'],
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  final bare = Contact(
    id: 'cid-2',
    name: 'Sam',
    relationshipTypeId: 'rid-2',
    cadence: Cadence.weekly,
    priority: ContactPriority.normal,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  group('Contact', () {
    test('round-trips through toMap/fromMap', () {
      expectMapRoundTrip(
        sample: sample,
        toMap: (c) => c.toMap(),
        fromMap: Contact.fromMap,
      );
    });

    test('round-trips with every optional field absent', () {
      expectMapRoundTrip(
        sample: bare,
        toMap: (c) => c.toMap(),
        fromMap: Contact.fromMap,
      );
      expect(bare.tags, isEmpty);
      expect(bare.phone, isNull);
    });

    test('persists timestamps as UTC epoch milliseconds', () {
      final local = sample.copyWith(
        createdAt: createdAt.toLocal(),
        updatedAt: updatedAt.toLocal(),
      );

      expect(local.toMap()['createdAt'], createdAt.millisecondsSinceEpoch);
      expect(local.toMap()['updatedAt'], updatedAt.millisecondsSinceEpoch);
      expect(Contact.fromMap(local.toMap()).createdAt.isUtc, isTrue);
      expect(Contact.fromMap(local.toMap()).updatedAt.isUtc, isTrue);
    });

    test('persists the cadence as a day count', () {
      expect(sample.toMap()['cadenceDays'], 30);
      expect(
        Contact.fromMap({...sample.toMap(), 'cadenceDays': 45}).cadence,
        const Cadence.custom(45),
      );
    });

    test('clamps a stored cadence that is out of range', () {
      expect(
        Contact.fromMap({...sample.toMap(), 'cadenceDays': 0}).cadence.days,
        Cadence.minDays,
      );
    });

    test('persists the priority by wire name', () {
      expect(sample.toMap()['priority'], 'high');
      expect(
        Contact.fromMap({...sample.toMap(), 'priority': 'low'}).priority,
        ContactPriority.low,
      );
    });

    test('reads a document written without a tags field as untagged', () {
      final map = sample.toMap()..remove('tags');

      expect(Contact.fromMap(map).tags, isEmpty);
    });

    test('reads a document written without an archived flag as active', () {
      final map = sample.toMap()..remove('isArchived');

      expect(Contact.fromMap(map).isArchived, isFalse);
    });

    test('holds tags as an unmodifiable list', () {
      expect(() => sample.tags.add('nope'), throwsUnsupportedError);
    });

    test('copyWith covers every field', () {
      final otherDate = DateTime.utc(2027);
      expectCopyWithCoversEveryField<Contact>(
        sample: sample,
        copyWithNothing: (c) => c.copyWith(),
        cases: [
          CopyWithCase(
            field: 'id',
            mutate: (c) => c.copyWith(id: 'cid-9'),
            read: (c) => c.id,
            expected: 'cid-9',
          ),
          CopyWithCase(
            field: 'name',
            mutate: (c) => c.copyWith(name: 'Marco'),
            read: (c) => c.name,
            expected: 'Marco',
          ),
          CopyWithCase(
            field: 'relationshipTypeId',
            mutate: (c) => c.copyWith(relationshipTypeId: 'rid-9'),
            read: (c) => c.relationshipTypeId,
            expected: 'rid-9',
          ),
          CopyWithCase(
            field: 'cadence',
            mutate: (c) => c.copyWith(cadence: Cadence.weekly),
            read: (c) => c.cadence,
            expected: Cadence.weekly,
          ),
          CopyWithCase(
            field: 'priority',
            mutate: (c) => c.copyWith(priority: ContactPriority.low),
            read: (c) => c.priority,
            expected: ContactPriority.low,
          ),
          CopyWithCase(
            field: 'phone',
            mutate: (c) => c.copyWith(phone: '555-0200'),
            read: (c) => c.phone,
            expected: '555-0200',
          ),
          CopyWithCase(
            field: 'phone (cleared)',
            mutate: (c) => c.copyWith(clearPhone: true),
            read: (c) => c.phone,
            expected: null,
          ),
          CopyWithCase(
            field: 'email',
            mutate: (c) => c.copyWith(email: 'm@example.com'),
            read: (c) => c.email,
            expected: 'm@example.com',
          ),
          CopyWithCase(
            field: 'email (cleared)',
            mutate: (c) => c.copyWith(clearEmail: true),
            read: (c) => c.email,
            expected: null,
          ),
          CopyWithCase(
            field: 'address',
            mutate: (c) => c.copyWith(address: '3 Oak Lane'),
            read: (c) => c.address,
            expected: '3 Oak Lane',
          ),
          CopyWithCase(
            field: 'address (cleared)',
            mutate: (c) => c.copyWith(clearAddress: true),
            read: (c) => c.address,
            expected: null,
          ),
          CopyWithCase(
            field: 'guardianName',
            mutate: (c) => c.copyWith(guardianName: 'Ada'),
            read: (c) => c.guardianName,
            expected: 'Ada',
          ),
          CopyWithCase(
            field: 'guardianName (cleared)',
            mutate: (c) => c.copyWith(clearGuardianName: true),
            read: (c) => c.guardianName,
            expected: null,
          ),
          CopyWithCase(
            field: 'guardianPhone',
            mutate: (c) => c.copyWith(guardianPhone: '555-0300'),
            read: (c) => c.guardianPhone,
            expected: '555-0300',
          ),
          CopyWithCase(
            field: 'guardianPhone (cleared)',
            mutate: (c) => c.copyWith(clearGuardianPhone: true),
            read: (c) => c.guardianPhone,
            expected: null,
          ),
          CopyWithCase(
            field: 'notes',
            mutate: (c) => c.copyWith(notes: 'Plays cello.'),
            read: (c) => c.notes,
            expected: 'Plays cello.',
          ),
          CopyWithCase(
            field: 'notes (cleared)',
            mutate: (c) => c.copyWith(clearNotes: true),
            read: (c) => c.notes,
            expected: null,
          ),
          CopyWithCase(
            field: 'tags',
            mutate: (c) => c.copyWith(tags: const ['chess']),
            read: (c) => c.tags,
            expected: const ['chess'],
          ),
          CopyWithCase(
            field: 'isArchived',
            mutate: (c) => c.copyWith(isArchived: true),
            read: (c) => c.isArchived,
            expected: true,
          ),
          CopyWithCase(
            field: 'createdAt',
            mutate: (c) => c.copyWith(createdAt: otherDate),
            read: (c) => c.createdAt,
            expected: otherDate,
          ),
          CopyWithCase(
            field: 'updatedAt',
            mutate: (c) => c.copyWith(updatedAt: otherDate),
            read: (c) => c.updatedAt,
            expected: otherDate,
          ),
        ],
      );
    });

    test('has value semantics, tags compared by content', () {
      expectValueEquality(
        sample: sample,
        identical: sample.copyWith(tags: ['soccer', 'school']),
        others: [
          sample.copyWith(id: 'other'),
          sample.copyWith(name: 'other'),
          sample.copyWith(relationshipTypeId: 'other'),
          sample.copyWith(cadence: Cadence.quarterly),
          sample.copyWith(priority: ContactPriority.low),
          sample.copyWith(clearPhone: true),
          sample.copyWith(clearEmail: true),
          sample.copyWith(clearAddress: true),
          sample.copyWith(clearGuardianName: true),
          sample.copyWith(clearGuardianPhone: true),
          sample.copyWith(clearNotes: true),
          sample.copyWith(tags: const ['school', 'soccer']),
          sample.copyWith(tags: const []),
          sample.copyWith(isArchived: true),
          sample.copyWith(createdAt: DateTime.utc(2020)),
          sample.copyWith(updatedAt: DateTime.utc(2020)),
        ],
      );
    });

    test('toString names every field', () {
      final text = sample.toString();

      for (final fragment in [
        'cid-1',
        'Marcus',
        'rid-1',
        '30',
        'high',
        '555-0100',
        'marcus@example.com',
        '12 Elm Street',
        'Dana',
        '555-0199',
        'Allergic to cats.',
        'soccer',
      ]) {
        expect(text, contains(fragment));
      }
    });
  });
}
