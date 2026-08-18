import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/hangout.dart';

import '../../helpers/model_test_helpers.dart';

void main() {
  final logged = DateTime.utc(2026, 8, 18, 9, 30);

  Hangout sample() => Hangout(
    id: 'hgid-1',
    occurredOn: DateTime.utc(2026, 8, 14),
    contactIds: const ['cid-1', 'cid-2'],
    attendeeIds: const ['uid-1'],
    createdBy: 'uid-1',
    createdAt: logged,
    updatedAt: logged,
    note: 'Barbecue in their garden',
  );

  test('round-trips through its map', () {
    expectMapRoundTrip(
      sample: sample(),
      toMap: (model) => model.toMap(),
      fromMap: Hangout.fromMap,
    );
  });

  test('round-trips with every optional field absent', () {
    expectMapRoundTrip(
      sample: sample().copyWith(clearNote: true, attendeeIds: const []),
      toMap: (model) => model.toMap(),
      fromMap: Hangout.fromMap,
    );
  });

  test('reads a document with no lists and no note', () {
    final hangout = Hangout.fromMap({
      'id': 'hgid-9',
      'occurredOn': DateTime.utc(2026, 8, 14).millisecondsSinceEpoch,
      'createdBy': 'uid-1',
      'createdAt': logged.millisecondsSinceEpoch,
      'updatedAt': logged.millisecondsSinceEpoch,
    });

    expect(hangout.contactIds, isEmpty);
    expect(hangout.attendeeIds, isEmpty);
    expect(hangout.note, isNull);
  });

  test('copyWith covers every field', () {
    expectCopyWithCoversEveryField(
      sample: sample(),
      copyWithNothing: (model) => model.copyWith(),
      cases: [
        CopyWithCase<Hangout>(
          field: 'id',
          mutate: (m) => m.copyWith(id: 'hgid-2'),
          read: (m) => m.id,
          expected: 'hgid-2',
        ),
        CopyWithCase<Hangout>(
          field: 'occurredOn',
          mutate: (m) => m.copyWith(occurredOn: DateTime.utc(2026, 8)),
          read: (m) => m.occurredOn,
          expected: DateTime.utc(2026, 8),
        ),
        CopyWithCase<Hangout>(
          field: 'contactIds',
          mutate: (m) => m.copyWith(contactIds: const ['cid-9']),
          read: (m) => m.contactIds,
          expected: const ['cid-9'],
        ),
        CopyWithCase<Hangout>(
          field: 'attendeeIds',
          mutate: (m) => m.copyWith(attendeeIds: const ['uid-2']),
          read: (m) => m.attendeeIds,
          expected: const ['uid-2'],
        ),
        CopyWithCase<Hangout>(
          field: 'createdBy',
          mutate: (m) => m.copyWith(createdBy: 'uid-2'),
          read: (m) => m.createdBy,
          expected: 'uid-2',
        ),
        CopyWithCase<Hangout>(
          field: 'createdAt',
          mutate: (m) => m.copyWith(createdAt: DateTime.utc(2026)),
          read: (m) => m.createdAt,
          expected: DateTime.utc(2026),
        ),
        CopyWithCase<Hangout>(
          field: 'updatedAt',
          mutate: (m) => m.copyWith(updatedAt: DateTime.utc(2027)),
          read: (m) => m.updatedAt,
          expected: DateTime.utc(2027),
        ),
        CopyWithCase<Hangout>(
          field: 'note',
          mutate: (m) => m.copyWith(note: 'Coffee'),
          read: (m) => m.note,
          expected: 'Coffee',
        ),
        CopyWithCase<Hangout>(
          field: 'note (cleared)',
          mutate: (m) => m.copyWith(clearNote: true),
          read: (m) => m.note,
          expected: null,
        ),
      ],
    );
  });

  test('compares and hashes by value', () {
    expectValueEquality(
      sample: sample(),
      identical: sample(),
      others: [
        sample().copyWith(id: 'hgid-2'),
        sample().copyWith(contactIds: const ['cid-1']),
        sample().copyWith(attendeeIds: const []),
        sample().copyWith(clearNote: true),
      ],
    );
  });

  group('occurredOn', () {
    test('is normalised to midnight UTC however it is passed in', () {
      final hangout = sample().copyWith(
        occurredOn: DateTime.utc(2026, 8, 14, 19, 45),
      );

      expect(hangout.occurredOn, DateTime.utc(2026, 8, 14));
      expect(hangout.occurredOn.isUtc, isTrue);
    });

    test('takes the local date off a local instant', () {
      final hangout = sample().copyWith(occurredOn: DateTime(2026, 8, 14, 22));

      expect(hangout.occurredOn, DateTime.utc(2026, 8, 14));
    });

    test('survives the map round trip as the same day', () {
      final hangout = sample().copyWith(
        occurredOn: DateTime.utc(2026, 8, 14, 19, 45),
      );

      expect(
        Hangout.fromMap(hangout.toMap()).occurredOn,
        DateTime.utc(2026, 8, 14),
      );
    });
  });

  group('lists', () {
    test('are unmodifiable', () {
      expect(() => sample().contactIds.add('cid-3'), throwsUnsupportedError);
      expect(() => sample().attendeeIds.add('uid-2'), throwsUnsupportedError);
    });

    test('keep the order they were given', () {
      expect(sample().contactIds, ['cid-1', 'cid-2']);
    });
  });

  group('includes', () {
    test('is true for a contact the hangout names', () {
      expect(sample().includes('cid-2'), isTrue);
    });

    test('is false for anyone else', () {
      expect(sample().includes('cid-9'), isFalse);
    });
  });

  test('toString names every field', () {
    final text = sample().toString();

    for (final fragment in [
      'hgid-1',
      'cid-1',
      'uid-1',
      'Barbecue in their garden',
    ]) {
      expect(text, contains(fragment));
    }
  });
}
