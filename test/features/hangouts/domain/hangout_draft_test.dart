import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/features/hangouts/domain/hangout_draft.dart';

import '../../../helpers/model_test_helpers.dart';

void main() {
  final logged = DateTime.utc(2026, 8, 18, 9);

  HangoutDraft sample() => HangoutDraft(
    occurredOn: DateTime.utc(2026, 8, 14),
    contactIds: const ['cid-1', 'cid-2'],
    attendeeIds: const ['uid-1'],
    note: 'Barbecue in their garden',
  );

  test('copyWith covers every field', () {
    expectCopyWithCoversEveryField(
      sample: sample(),
      copyWithNothing: (model) => model.copyWith(),
      cases: [
        CopyWithCase<HangoutDraft>(
          field: 'occurredOn',
          mutate: (m) => m.copyWith(occurredOn: DateTime.utc(2026, 8)),
          read: (m) => m.occurredOn,
          expected: DateTime.utc(2026, 8),
        ),
        CopyWithCase<HangoutDraft>(
          field: 'contactIds',
          mutate: (m) => m.copyWith(contactIds: const ['cid-9']),
          read: (m) => m.contactIds,
          expected: const ['cid-9'],
        ),
        CopyWithCase<HangoutDraft>(
          field: 'attendeeIds',
          mutate: (m) => m.copyWith(attendeeIds: const ['uid-2']),
          read: (m) => m.attendeeIds,
          expected: const ['uid-2'],
        ),
        CopyWithCase<HangoutDraft>(
          field: 'note',
          mutate: (m) => m.copyWith(note: 'Coffee'),
          read: (m) => m.note,
          expected: 'Coffee',
        ),
        CopyWithCase<HangoutDraft>(
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
        sample().copyWith(contactIds: const ['cid-1']),
        sample().copyWith(attendeeIds: const []),
        sample().copyWith(clearNote: true),
        sample().copyWith(occurredOn: DateTime.utc(2026, 8)),
      ],
    );
  });

  group('from', () {
    test('reproduces the editable half of a stored hangout', () {
      final hangout = Hangout(
        id: 'hgid-1',
        occurredOn: DateTime.utc(2026, 8, 14),
        contactIds: const ['cid-1', 'cid-2'],
        attendeeIds: const ['uid-1'],
        createdBy: 'uid-1',
        createdAt: logged,
        updatedAt: logged,
        note: 'Barbecue in their garden',
      );

      expect(HangoutDraft.from(hangout), sample());
    });
  });

  group('normalised', () {
    test('reads a blank note as absent', () {
      expect(sample().copyWith(note: '   ').normalised().note, isNull);
    });

    test('trims a note that has something in it', () {
      expect(sample().copyWith(note: '  Coffee  ').normalised().note, 'Coffee');
    });

    test('names each contact once, keeping the order they were tapped', () {
      final draft = sample()
          .copyWith(contactIds: const ['cid-2', 'cid-1', 'cid-2'])
          .normalised();

      expect(draft.contactIds, ['cid-2', 'cid-1']);
    });

    test('drops blank ids on both lists', () {
      final draft = sample()
          .copyWith(contactIds: const ['cid-1', ' '], attendeeIds: const [''])
          .normalised();

      expect(draft.contactIds, ['cid-1']);
      expect(draft.attendeeIds, isEmpty);
    });

    test('leaves the day alone', () {
      expect(sample().normalised().occurredOn, DateTime.utc(2026, 8, 14));
    });
  });

  group('occurredOn', () {
    test('is normalised to midnight UTC by the constructor', () {
      final draft = sample().copyWith(
        occurredOn: DateTime.utc(2026, 8, 14, 21, 15),
      );

      expect(draft.occurredOn, DateTime.utc(2026, 8, 14));
    });
  });

  group('toHangout', () {
    test('builds the stored hangout the draft describes', () {
      final hangout = sample().toHangout(
        id: 'hgid-1',
        createdBy: 'uid-1',
        createdAt: logged,
        updatedAt: logged,
      );

      expect(hangout.id, 'hgid-1');
      expect(hangout.occurredOn, DateTime.utc(2026, 8, 14));
      expect(hangout.contactIds, ['cid-1', 'cid-2']);
      expect(hangout.attendeeIds, ['uid-1']);
      expect(hangout.createdBy, 'uid-1');
      expect(hangout.createdAt, logged);
      expect(hangout.updatedAt, logged);
      expect(hangout.note, 'Barbecue in their garden');
    });

    test('round-trips back through from', () {
      final hangout = sample().toHangout(
        id: 'hgid-1',
        createdBy: 'uid-1',
        createdAt: logged,
        updatedAt: logged,
      );

      expect(HangoutDraft.from(hangout), sample());
    });
  });

  group('lists', () {
    test('are unmodifiable', () {
      expect(() => sample().contactIds.add('cid-3'), throwsUnsupportedError);
      expect(() => sample().attendeeIds.add('uid-2'), throwsUnsupportedError);
    });
  });

  test('attendees default to nobody', () {
    final draft = HangoutDraft(
      occurredOn: DateTime.utc(2026, 8, 14),
      contactIds: const ['cid-1'],
    );

    expect(draft.attendeeIds, isEmpty);
    expect(draft.note, isNull);
  });

  test('toString names every field', () {
    final text = sample().toString();

    for (final fragment in ['cid-1', 'uid-1', 'Barbecue in their garden']) {
      expect(text, contains(fragment));
    }
  });
}
