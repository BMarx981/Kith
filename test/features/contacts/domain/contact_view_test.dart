import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/domain/contact_view.dart';

void main() {
  Contact contact({
    required String id,
    required String name,
    String typeId = 'rid-friend',
    Cadence cadence = Cadence.monthly,
    List<String> tags = const [],
    String? guardianName,
    bool isArchived = false,
    int createdDay = 1,
  }) => Contact(
    id: id,
    name: name,
    relationshipTypeId: typeId,
    cadence: cadence,
    priority: ContactPriority.normal,
    createdAt: DateTime.utc(2026, 8, createdDay),
    updatedAt: DateTime.utc(2026, 8, createdDay),
    guardianName: guardianName,
    tags: tags,
    isArchived: isArchived,
  );

  // Marcus keeps the helper's defaults: a monthly cadence, added on the 1st.
  final marcus = contact(
    id: 'c1',
    name: 'Marcus',
    tags: const ['soccer'],
    guardianName: 'Dana',
  );
  final ada = contact(
    id: 'c2',
    name: 'ada',
    typeId: 'rid-family',
    cadence: Cadence.weekly,
    createdDay: 5,
  );
  final zoe = contact(
    id: 'c3',
    name: 'Zoe',
    cadence: Cadence.quarterly,
    tags: const ['Chess'],
    createdDay: 3,
  );
  final archived = contact(
    id: 'c4',
    name: 'Beatrice',
    isArchived: true,
    createdDay: 2,
  );
  final all = [marcus, ada, zoe, archived];

  group('ContactView.apply filtering', () {
    test('hides archived contacts by default', () {
      expect(const ContactView().apply(all), isNot(contains(archived)));
    });

    test('includes archived contacts when asked to', () {
      expect(
        const ContactView(showArchived: true).apply(all),
        contains(archived),
      );
    });

    test('keeps only the chosen relationship type', () {
      expect(
        const ContactView(relationshipTypeId: 'rid-family').apply(all),
        [ada],
      );
    });

    test('an empty query matches everything', () {
      expect(const ContactView(query: '   ').apply(all), hasLength(3));
    });

    test('searches names, ignoring case', () {
      expect(const ContactView(query: 'MAR').apply(all), [marcus]);
      expect(const ContactView(query: 'ada').apply(all), [ada]);
    });

    test('searches tags, ignoring case', () {
      expect(const ContactView(query: 'chess').apply(all), [zoe]);
    });

    test("searches the guardian's name", () {
      expect(const ContactView(query: 'dana').apply(all), [marcus]);
    });

    test('does not search notes, phone or address', () {
      final noisy = contact(
        id: 'c5',
        name: 'Sam',
      ).copyWith(notes: 'chess club', phone: '555-0100', address: 'Chess Lane');

      expect(const ContactView(query: 'chess').apply([noisy]), isEmpty);
    });

    test('a query that matches nothing gives an empty list', () {
      expect(const ContactView(query: 'nobody').apply(all), isEmpty);
    });

    test('combines search, type filter and the archived toggle', () {
      final archivedFriend = contact(
        id: 'c6',
        name: 'Marcus senior',
        tags: const ['soccer'],
        isArchived: true,
      );

      expect(
        const ContactView(
          query: 'marcus',
          relationshipTypeId: 'rid-friend',
          showArchived: true,
        ).apply([...all, archivedFriend]),
        [marcus, archivedFriend],
      );
    });

    test('leaves the source list untouched', () {
      final source = [zoe, ada, marcus];

      const ContactView().apply(source);

      expect(source, orderedEquals(<Contact>[zoe, ada, marcus]));
    });
  });

  group('ContactView.apply ordering', () {
    test('sorts by name, ignoring case', () {
      expect(const ContactView().apply(all), [ada, marcus, zoe]);
    });

    test('sorts by recently added, newest first', () {
      expect(
        const ContactView(sort: ContactSort.recentlyAdded).apply(all),
        [ada, zoe, marcus],
      );
    });

    test('sorts by cadence, shortest interval first', () {
      expect(
        const ContactView(sort: ContactSort.cadence).apply(all),
        [ada, marcus, zoe],
      );
    });

    test('breaks a cadence tie by name', () {
      final sam = contact(id: 'c7', name: 'Sam', cadence: Cadence.weekly);

      expect(
        const ContactView(sort: ContactSort.cadence).apply([sam, ada]),
        [ada, sam],
      );
    });

    test('breaks a name tie by id, so the order never wobbles', () {
      final second = contact(id: 'c9', name: 'Marcus');
      final first = contact(id: 'c8', name: 'marcus');

      expect(const ContactView().apply([second, first]), [first, second]);
    });

    test('an empty list stays empty under every sort', () {
      for (final sort in ContactSort.values) {
        expect(ContactView(sort: sort).apply(const []), isEmpty);
      }
    });
  });

  group('ContactView', () {
    test('knows when something is narrowing the list', () {
      expect(const ContactView().isFiltered, isFalse);
      expect(const ContactView(query: '  ').isFiltered, isFalse);
      expect(const ContactView(query: 'a').isFiltered, isTrue);
      expect(const ContactView(relationshipTypeId: 'r').isFiltered, isTrue);
      expect(const ContactView(showArchived: true).isFiltered, isTrue);
    });

    test('sort labels are distinct', () {
      expect(
        ContactSort.values.map((s) => s.label).toSet(),
        hasLength(ContactSort.values.length),
      );
    });

    test('copyWith covers every field', () {
      const sample = ContactView(
        query: 'a',
        relationshipTypeId: 'rid-1',
        sort: ContactSort.cadence,
        showArchived: true,
      );

      expect(sample.copyWith(), sample);
      expect(sample.copyWith(query: 'b').query, 'b');
      expect(
        sample.copyWith(relationshipTypeId: 'rid-2').relationshipTypeId,
        'rid-2',
      );
      expect(
        sample.copyWith(clearRelationshipTypeId: true).relationshipTypeId,
        isNull,
      );
      expect(sample.copyWith(sort: ContactSort.name).sort, ContactSort.name);
      expect(sample.copyWith(showArchived: false).showArchived, isFalse);
    });

    test('has value semantics', () {
      const sample = ContactView(query: 'a', sort: ContactSort.cadence);

      expect(sample.copyWith(), sample);
      expect(sample.copyWith().hashCode, sample.hashCode);
      expect(sample.copyWith(query: 'b'), isNot(sample));
      expect(sample.toString(), contains('cadence'));
    });
  });
}
