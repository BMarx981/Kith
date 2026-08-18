import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/domain/contact_draft.dart';

void main() {
  const sample = ContactDraft(
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
    tags: ['soccer', 'school'],
  );

  group('ContactDraft.normalised', () {
    test('trims the required fields', () {
      final normalised = sample
          .copyWith(name: '  Marcus  ', relationshipTypeId: ' rid-1 ')
          .normalised();

      expect(normalised.name, 'Marcus');
      expect(normalised.relationshipTypeId, 'rid-1');
    });

    test('reads a blank optional field as absent', () {
      final normalised = sample
          .copyWith(
            phone: '   ',
            email: '',
            address: ' ',
            guardianName: '\t',
            guardianPhone: '  ',
            notes: '',
          )
          .normalised();

      expect(normalised.phone, isNull);
      expect(normalised.email, isNull);
      expect(normalised.address, isNull);
      expect(normalised.guardianName, isNull);
      expect(normalised.guardianPhone, isNull);
      expect(normalised.notes, isNull);
    });

    test('trims an optional field that has content', () {
      expect(
        sample.copyWith(phone: ' 555-0100 ').normalised().phone,
        '555-0100',
      );
    });

    test('trims tags, drops blanks, and keeps the first of any duplicates', () {
      final normalised = sample
          .copyWith(tags: const [' soccer ', '', 'Soccer', 'school', '  '])
          .normalised();

      expect(normalised.tags, orderedEquals(<String>['soccer', 'school']));
    });

    test('leaves an already-normalised draft alone', () {
      expect(sample.normalised(), sample);
    });

    test('does not touch the cadence or the priority', () {
      final normalised = sample.normalised();

      expect(normalised.cadence, Cadence.monthly);
      expect(normalised.priority, ContactPriority.high);
    });
  });

  group('ContactDraft.toContact', () {
    test('builds the contact the draft describes', () {
      final createdAt = DateTime.utc(2026, 4);
      final updatedAt = DateTime.utc(2026, 5);

      final contact = sample.toContact(
        id: 'cid-1',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(contact.id, 'cid-1');
      expect(contact.createdAt, createdAt);
      expect(contact.updatedAt, updatedAt);
      expect(contact.isArchived, isFalse);
      expect(ContactDraft.from(contact), sample);
    });

    test('carries the archived flag through when asked to', () {
      final contact = sample.toContact(
        id: 'cid-1',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        isArchived: true,
      );

      expect(contact.isArchived, isTrue);
    });
  });

  group('ContactDraft.from', () {
    test('round-trips every editable field off a contact', () {
      final contact = Contact(
        id: 'cid-1',
        name: 'Marcus',
        relationshipTypeId: 'rid-1',
        cadence: Cadence.quarterly,
        priority: ContactPriority.low,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        phone: '555-0100',
        notes: 'Allergic to cats.',
        tags: const ['soccer'],
        isArchived: true,
      );

      final draft = ContactDraft.from(contact);

      expect(
        draft.toContact(
          id: contact.id,
          createdAt: contact.createdAt,
          updatedAt: contact.updatedAt,
          isArchived: true,
        ),
        contact,
      );
    });
  });

  test('has value semantics', () {
    expect(sample.copyWith(), sample);
    expect(sample.copyWith().hashCode, sample.hashCode);
    expect(sample.copyWith(name: 'other'), isNot(sample));
    expect(sample.copyWith(tags: const ['soccer']), isNot(sample));
    expect(sample.toString(), contains('Marcus'));
  });
}
