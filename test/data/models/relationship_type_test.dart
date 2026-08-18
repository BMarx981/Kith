import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/relationship_type.dart';

import '../../helpers/model_test_helpers.dart';

void main() {
  final createdAt = DateTime.utc(2026, 4, 1, 12);
  final sample = RelationshipType(
    id: 'rid-1',
    name: 'Neighbor',
    sortOrder: 2,
    createdAt: createdAt,
  );

  group('RelationshipType', () {
    test('round-trips through toMap/fromMap', () {
      expectMapRoundTrip(
        sample: sample,
        toMap: (t) => t.toMap(),
        fromMap: RelationshipType.fromMap,
      );
    });

    test('persists createdAt as UTC epoch milliseconds', () {
      final local = sample.copyWith(createdAt: createdAt.toLocal());

      expect(local.toMap()['createdAt'], createdAt.millisecondsSinceEpoch);
      expect(RelationshipType.fromMap(local.toMap()).createdAt.isUtc, isTrue);
    });

    test('copyWith covers every field', () {
      final otherDate = DateTime.utc(2027);
      expectCopyWithCoversEveryField<RelationshipType>(
        sample: sample,
        copyWithNothing: (t) => t.copyWith(),
        cases: [
          CopyWithCase(
            field: 'id',
            mutate: (t) => t.copyWith(id: 'rid-2'),
            read: (t) => t.id,
            expected: 'rid-2',
          ),
          CopyWithCase(
            field: 'name',
            mutate: (t) => t.copyWith(name: 'Coworker'),
            read: (t) => t.name,
            expected: 'Coworker',
          ),
          CopyWithCase(
            field: 'sortOrder',
            mutate: (t) => t.copyWith(sortOrder: 9),
            read: (t) => t.sortOrder,
            expected: 9,
          ),
          CopyWithCase(
            field: 'createdAt',
            mutate: (t) => t.copyWith(createdAt: otherDate),
            read: (t) => t.createdAt,
            expected: otherDate,
          ),
        ],
      );
    });

    test('has value semantics', () {
      expectValueEquality(
        sample: sample,
        identical: sample.copyWith(),
        others: [
          sample.copyWith(id: 'other'),
          sample.copyWith(name: 'other'),
          sample.copyWith(sortOrder: 99),
          sample.copyWith(createdAt: DateTime.utc(2020)),
        ],
      );
    });

    test('toString names every field', () {
      final text = sample.toString();

      for (final fragment in ['rid-1', 'Neighbor', '2']) {
        expect(text, contains(fragment));
      }
    });
  });

  group('RelationshipType.defaultNames', () {
    test('seeds the set the plan names, in order', () {
      expect(
        RelationshipType.defaultNames,
        orderedEquals(<String>[
          'Friend',
          'Family',
          'Neighbor',
          "Child's friend",
          'Coworker',
        ]),
      );
    });

    test('holds no duplicates', () {
      expect(
        RelationshipType.defaultNames.toSet(),
        hasLength(RelationshipType.defaultNames.length),
      );
    });
  });
}
