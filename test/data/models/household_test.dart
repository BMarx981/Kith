import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/household.dart';
import 'package:kith/features/household/domain/invite_code.dart';

import '../../helpers/model_test_helpers.dart';

void main() {
  final createdAt = DateTime.utc(2026, 2, 3, 10, 30);
  final code = InviteCode.parse('KH7RQ2').valueOrNull!;
  final otherCode = InviteCode.parse('MN4XV9').valueOrNull!;
  final sample = Household(
    id: 'hh-1',
    name: 'The Marx house',
    inviteCode: code,
    createdAt: createdAt,
    createdBy: 'uid-1',
    calendarId: 'kith@group.calendar.google.com',
    calendarName: 'Hangouts',
  );
  final unlinked = sample.copyWith(clearCalendar: true);

  group('Household', () {
    test('round-trips through toMap/fromMap', () {
      expectMapRoundTrip(
        sample: sample,
        toMap: (h) => h.toMap(),
        fromMap: Household.fromMap,
      );
    });

    test('round-trips with a cleared invite code', () {
      expectMapRoundTrip(
        sample: sample.copyWith(clearInviteCode: true),
        toMap: (h) => h.toMap(),
        fromMap: Household.fromMap,
      );
    });

    test('round-trips a household with no calendar linked', () {
      expectMapRoundTrip(
        sample: unlinked,
        toMap: (h) => h.toMap(),
        fromMap: Household.fromMap,
      );
    });

    test('reads a document written before calendars as unlinked', () {
      final map = {...sample.toMap()}
        ..remove('calendarId')
        ..remove('calendarName');

      final household = Household.fromMap(map);

      expect(household.calendarId, isNull);
      expect(household.calendarName, isNull);
      expect(household.hasCalendar, isFalse);
    });

    test('has a calendar only once one is linked', () {
      expect(unlinked.hasCalendar, isFalse);
      expect(sample.hasCalendar, isTrue);
    });

    test('round-trips generated codes', () {
      for (var seed = 0; seed < 10; seed++) {
        expectMapRoundTrip(
          sample: sample.copyWith(
            inviteCode: InviteCode.generate(Random(seed)),
          ),
          toMap: (h) => h.toMap(),
          fromMap: Household.fromMap,
        );
      }
    });

    test('persists the invite code as its bare string value', () {
      expect(sample.toMap()['inviteCode'], 'KH7RQ2');
    });

    test('persists createdAt as UTC epoch milliseconds', () {
      expect(sample.toMap()['createdAt'], createdAt.millisecondsSinceEpoch);
      expect(Household.fromMap(sample.toMap()).createdAt.isUtc, isTrue);
    });

    test(
      'surfaces an unparseable stored code as null rather than throwing',
      () {
        final map = {...sample.toMap(), 'inviteCode': 'not-a-code'};

        expect(Household.fromMap(map).inviteCode, isNull);
      },
    );

    test('tolerates a missing invite code field', () {
      final map = {...sample.toMap()}..remove('inviteCode');

      expect(Household.fromMap(map).inviteCode, isNull);
    });

    test('copyWith covers every field', () {
      final otherDate = DateTime.utc(2027);
      expectCopyWithCoversEveryField<Household>(
        sample: sample,
        copyWithNothing: (h) => h.copyWith(),
        cases: [
          CopyWithCase(
            field: 'id',
            mutate: (h) => h.copyWith(id: 'hh-2'),
            read: (h) => h.id,
            expected: 'hh-2',
          ),
          CopyWithCase(
            field: 'name',
            mutate: (h) => h.copyWith(name: 'Beach house'),
            read: (h) => h.name,
            expected: 'Beach house',
          ),
          CopyWithCase(
            field: 'inviteCode',
            mutate: (h) => h.copyWith(inviteCode: otherCode),
            read: (h) => h.inviteCode,
            expected: otherCode,
          ),
          CopyWithCase(
            field: 'inviteCode (cleared)',
            mutate: (h) => h.copyWith(clearInviteCode: true),
            read: (h) => h.inviteCode,
            expected: null,
          ),
          CopyWithCase(
            field: 'createdAt',
            mutate: (h) => h.copyWith(createdAt: otherDate),
            read: (h) => h.createdAt,
            expected: otherDate,
          ),
          CopyWithCase(
            field: 'createdBy',
            mutate: (h) => h.copyWith(createdBy: 'uid-2'),
            read: (h) => h.createdBy,
            expected: 'uid-2',
          ),
          CopyWithCase(
            field: 'calendarId',
            mutate: (h) => h.copyWith(calendarId: 'cal-2'),
            read: (h) => h.calendarId,
            expected: 'cal-2',
          ),
          CopyWithCase(
            field: 'calendarName',
            mutate: (h) => h.copyWith(calendarName: 'Family'),
            read: (h) => h.calendarName,
            expected: 'Family',
          ),
          CopyWithCase(
            field: 'calendar (cleared)',
            mutate: (h) => h.copyWith(clearCalendar: true),
            read: (h) => h.calendarId ?? h.calendarName,
            expected: null,
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
          sample.copyWith(inviteCode: otherCode),
          sample.copyWith(clearInviteCode: true),
          sample.copyWith(createdAt: DateTime.utc(2020)),
          sample.copyWith(createdBy: 'uid-9'),
          sample.copyWith(calendarId: 'cal-9'),
          sample.copyWith(calendarName: 'Family'),
          unlinked,
        ],
      );
    });

    test('toString names every field', () {
      final text = sample.toString();

      for (final fragment in [
        'hh-1',
        'The Marx house',
        'KH7RQ2',
        'uid-1',
        'calendarId',
        'calendarName',
      ]) {
        expect(text, contains(fragment));
      }
    });
  });
}
