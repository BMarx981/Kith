import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/models/planned_hangout_status.dart';

import '../../helpers/model_test_helpers.dart';

void main() {
  final made = DateTime.utc(2026, 8, 18, 9, 30);

  PlannedHangout sample() => PlannedHangout(
    id: 'pid-1',
    plannedFor: DateTime.utc(2026, 8, 25),
    contactIds: const ['cid-1', 'cid-2'],
    status: PlannedHangoutStatus.proposed,
    createdBy: 'uid-1',
    createdAt: made,
    updatedAt: made,
    note: 'Dinner at ours',
    calendarEventId: 'evt-1',
  );

  test('round-trips through its map', () {
    expectMapRoundTrip(
      sample: sample(),
      toMap: (model) => model.toMap(),
      fromMap: PlannedHangout.fromMap,
    );
  });

  test('round-trips with every optional field absent', () {
    expectMapRoundTrip(
      sample: sample().copyWith(clearNote: true, clearCalendarEventId: true),
      toMap: (model) => model.toMap(),
      fromMap: PlannedHangout.fromMap,
    );
  });

  test('round-trips in each status', () {
    for (final status in PlannedHangoutStatus.values) {
      expectMapRoundTrip(
        sample: sample().copyWith(status: status),
        toMap: (model) => model.toMap(),
        fromMap: PlannedHangout.fromMap,
      );
    }
  });

  test('reads a document with no contacts, note or event', () {
    final plan = PlannedHangout.fromMap({
      'id': 'pid-9',
      'plannedFor': DateTime.utc(2026, 8, 25).millisecondsSinceEpoch,
      'status': 'snoozed',
      'createdBy': 'uid-1',
      'createdAt': made.millisecondsSinceEpoch,
      'updatedAt': made.millisecondsSinceEpoch,
    });

    expect(plan.contactIds, isEmpty);
    expect(plan.note, isNull);
    expect(plan.calendarEventId, isNull);
    expect(plan.status, PlannedHangoutStatus.snoozed);
  });

  test('normalises the planned day to midnight UTC', () {
    final plan = sample().copyWith(
      plannedFor: DateTime.utc(2026, 8, 25, 18, 45),
    );

    expect(plan.plannedFor, DateTime.utc(2026, 8, 25));
  });

  test('takes the local date of a local instant, not its UTC date', () {
    final plan = sample().copyWith(plannedFor: DateTime(2026, 8, 25, 23, 30));

    expect(plan.plannedFor, DateTime.utc(2026, 8, 25));
  });

  test('holds an unmodifiable contact list', () {
    expect(() => sample().contactIds.add('cid-3'), throwsUnsupportedError);
  });

  test('says who it is about', () {
    expect(sample().includes('cid-2'), isTrue);
    expect(sample().includes('cid-9'), isFalse);
  });

  group('isActiveOn', () {
    final plan = PlannedHangout(
      id: 'pid-1',
      plannedFor: DateTime.utc(2026, 8, 25),
      contactIds: const ['cid-1'],
      status: PlannedHangoutStatus.snoozed,
      createdBy: 'uid-1',
      createdAt: made,
      updatedAt: made,
    );

    test('is active before the day it names', () {
      expect(plan.isActiveOn(DateTime.utc(2026, 8, 24, 23, 59)), isTrue);
    });

    test('is active through the whole day it names', () {
      expect(plan.isActiveOn(DateTime.utc(2026, 8, 25)), isTrue);
      expect(plan.isActiveOn(DateTime.utc(2026, 8, 25, 23, 59)), isTrue);
    });

    test('has run out the morning after', () {
      expect(plan.isActiveOn(DateTime.utc(2026, 8, 26)), isFalse);
    });
  });

  test('copyWith covers every field', () {
    expectCopyWithCoversEveryField(
      sample: sample(),
      copyWithNothing: (model) => model.copyWith(),
      cases: [
        CopyWithCase<PlannedHangout>(
          field: 'id',
          mutate: (m) => m.copyWith(id: 'pid-2'),
          read: (m) => m.id,
          expected: 'pid-2',
        ),
        CopyWithCase<PlannedHangout>(
          field: 'plannedFor',
          mutate: (m) => m.copyWith(plannedFor: DateTime.utc(2026, 9)),
          read: (m) => m.plannedFor,
          expected: DateTime.utc(2026, 9),
        ),
        CopyWithCase<PlannedHangout>(
          field: 'contactIds',
          mutate: (m) => m.copyWith(contactIds: const ['cid-9']),
          read: (m) => m.contactIds,
          expected: const ['cid-9'],
        ),
        CopyWithCase<PlannedHangout>(
          field: 'status',
          mutate: (m) => m.copyWith(status: PlannedHangoutStatus.snoozed),
          read: (m) => m.status,
          expected: PlannedHangoutStatus.snoozed,
        ),
        CopyWithCase<PlannedHangout>(
          field: 'createdBy',
          mutate: (m) => m.copyWith(createdBy: 'uid-2'),
          read: (m) => m.createdBy,
          expected: 'uid-2',
        ),
        CopyWithCase<PlannedHangout>(
          field: 'createdAt',
          mutate: (m) => m.copyWith(createdAt: DateTime.utc(2026)),
          read: (m) => m.createdAt,
          expected: DateTime.utc(2026),
        ),
        CopyWithCase<PlannedHangout>(
          field: 'updatedAt',
          mutate: (m) => m.copyWith(updatedAt: DateTime.utc(2027)),
          read: (m) => m.updatedAt,
          expected: DateTime.utc(2027),
        ),
        CopyWithCase<PlannedHangout>(
          field: 'note',
          mutate: (m) => m.copyWith(note: 'Lunch instead'),
          read: (m) => m.note,
          expected: 'Lunch instead',
        ),
        CopyWithCase<PlannedHangout>(
          field: 'note (cleared)',
          mutate: (m) => m.copyWith(clearNote: true),
          read: (m) => m.note,
          expected: null,
        ),
        CopyWithCase<PlannedHangout>(
          field: 'calendarEventId',
          mutate: (m) => m.copyWith(calendarEventId: 'evt-2'),
          read: (m) => m.calendarEventId,
          expected: 'evt-2',
        ),
        CopyWithCase<PlannedHangout>(
          field: 'calendarEventId (cleared)',
          mutate: (m) => m.copyWith(clearCalendarEventId: true),
          read: (m) => m.calendarEventId,
          expected: null,
        ),
      ],
    );
  });

  test('is equal by value and differs on every field', () {
    expectValueEquality(
      sample: sample(),
      identical: sample(),
      others: [
        sample().copyWith(id: 'pid-2'),
        sample().copyWith(plannedFor: DateTime.utc(2026, 9)),
        sample().copyWith(contactIds: const ['cid-1']),
        sample().copyWith(status: PlannedHangoutStatus.confirmed),
        sample().copyWith(createdBy: 'uid-2'),
        sample().copyWith(createdAt: DateTime.utc(2026)),
        sample().copyWith(updatedAt: DateTime.utc(2027)),
        sample().copyWith(note: 'Lunch instead'),
        sample().copyWith(clearNote: true),
        sample().copyWith(calendarEventId: 'evt-2'),
        sample().copyWith(clearCalendarEventId: true),
      ],
    );
  });

  test('names itself, its day and its status in toString', () {
    final text = sample().toString();

    expect(text, contains('pid-1'));
    expect(text, contains('proposed'));
    expect(text, contains('2026-08-25'));
  });
}
