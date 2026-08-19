import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/services/device_contact_directory.dart';
import 'package:kith/features/contacts/domain/birthday.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/domain/contact_import.dart';

DeviceContact _person(
  String name, {
  String id = 'row-1',
  String? phone,
  String? email,
  String? address,
  Birthday? birthday,
}) => DeviceContact(
  id: id,
  name: name,
  phone: phone,
  email: email,
  address: address,
  birthday: birthday,
);

Contact _existing(
  String name, {
  String id = 'cid-1',
  String? phone,
  String? email,
  bool isArchived = false,
}) => Contact(
  id: id,
  name: name,
  relationshipTypeId: 'rid-1',
  cadence: Cadence.monthly,
  priority: ContactPriority.normal,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  phone: phone,
  email: email,
  isArchived: isArchived,
);

void main() {
  group('importCandidates', () {
    test('is empty when the address book is', () {
      expect(
        importCandidates(device: const [], existing: [_existing('Marcus')]),
        isEmpty,
      );
    });

    test('marks nobody when the household is empty', () {
      final found = importCandidates(
        device: [_person('Marcus Bell')],
        existing: const [],
      );

      expect(found.single.person.name, 'Marcus Bell');
      expect(found.single.isAlreadyHere, isFalse);
    });

    test('matches on the name, ignoring case and spacing', () {
      for (final stored in ['Marcus Bell', 'marcus bell', '  MARCUS   BELL ']) {
        final found = importCandidates(
          device: [_person('Marcus Bell')],
          existing: [_existing(stored)],
        );
        expect(found.single.isAlreadyHere, isTrue, reason: stored);
      }
    });

    test('matches on the phone number, however it is punctuated', () {
      final found = importCandidates(
        device: [_person('M. Bell', phone: '(555) 010-0')],
        existing: [_existing('Marcus Bell', phone: '555-0100')],
      );

      expect(found.single.isAlreadyHere, isTrue);
    });

    test('matches on the email address, ignoring case', () {
      final found = importCandidates(
        device: [_person('M. Bell', email: 'Marcus@Example.com')],
        existing: [_existing('Marcus Bell', email: 'marcus@example.com')],
      );

      expect(found.single.isAlreadyHere, isTrue);
    });

    test('does not match two people who share nothing', () {
      final found = importCandidates(
        device: [_person('Ana Reyes', phone: '555-0200')],
        existing: [_existing('Marcus Bell', phone: '555-0100')],
      );

      expect(found.single.isAlreadyHere, isFalse);
    });

    test('two contacts with no phone at all are not a match', () {
      final found = importCandidates(
        device: [_person('Ana Reyes')],
        existing: [_existing('Marcus Bell')],
      );

      expect(found.single.isAlreadyHere, isFalse);
    });

    test('counts an archived contact as already here', () {
      final found = importCandidates(
        device: [_person('Marcus Bell')],
        existing: [_existing('Marcus Bell', isArchived: true)],
      );

      expect(found.single.isAlreadyHere, isTrue);
    });

    test('keeps the ones already here on the list', () {
      final found = importCandidates(
        device: [
          _person('Marcus Bell', id: 'row-m'),
          _person('Ana Reyes', id: 'row-a'),
        ],
        existing: [_existing('Marcus Bell')],
      );

      expect(found, hasLength(2));
      // Sorted by name, so Ana comes first and Marcus is the marked one.
      expect(found.map((c) => c.person.name), ['Ana Reyes', 'Marcus Bell']);
      expect(found.map((c) => c.isAlreadyHere), [false, true]);
    });

    test('sorts by name, then by the platform id', () {
      final found = importCandidates(
        device: [
          _person('ana reyes', id: 'row-z'),
          _person('Marcus Bell', id: 'row-m'),
          _person('Ana Reyes', id: 'row-a'),
        ],
        existing: const [],
      );

      expect(found.map((c) => c.person.id), ['row-a', 'row-z', 'row-m']);
    });

    test('the list it hands back cannot be modified', () {
      final found = importCandidates(
        device: [_person('Marcus Bell')],
        existing: const [],
      );

      expect(found.clear, throwsUnsupportedError);
    });

    test('has value semantics', () {
      final a = importCandidates(
        device: [_person('Marcus Bell')],
        existing: const [],
      ).single;
      final b = importCandidates(
        device: [_person('Marcus Bell')],
        existing: const [],
      ).single;

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(
          importCandidates(
            device: [_person('Marcus Bell')],
            existing: [_existing('Marcus Bell')],
          ).single,
        ),
      );
      expect(a.toString(), 'ImportCandidate(Marcus Bell, alreadyHere: false)');
    });
  });

  group('draftFor', () {
    test('carries every field Kith has room for', () {
      final draft = draftFor(
        _person(
          'Marcus Bell',
          phone: '555-0100',
          email: 'marcus@example.com',
          address: '12 Elm Street',
          birthday: const Birthday(month: 3, day: 14, year: 1988),
        ),
        relationshipTypeId: 'rid-friend',
        cadence: Cadence.weekly,
      );

      expect(draft.name, 'Marcus Bell');
      expect(draft.phone, '555-0100');
      expect(draft.email, 'marcus@example.com');
      expect(draft.address, '12 Elm Street');
      expect(draft.birthday, const Birthday(month: 3, day: 14, year: 1988));
      expect(draft.relationshipTypeId, 'rid-friend');
      expect(draft.cadence, Cadence.weekly);
      expect(draft.priority, ContactPriority.normal);
    });

    test('arrives normalised, so a padded row is not stored padded', () {
      final draft = draftFor(
        _person('  Marcus Bell  ', phone: '   '),
        relationshipTypeId: 'rid-friend',
        cadence: Cadence.monthly,
      );

      expect(draft.name, 'Marcus Bell');
      expect(draft.phone, isNull);
    });

    test('leaves absent fields absent rather than blank', () {
      final draft = draftFor(
        _person('Marcus Bell'),
        relationshipTypeId: 'rid-friend',
        cadence: Cadence.monthly,
      );

      expect(draft.phone, isNull);
      expect(draft.email, isNull);
      expect(draft.address, isNull);
      expect(draft.birthday, isNull);
      expect(draft.tags, isEmpty);
    });
  });
}
