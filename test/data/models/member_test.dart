import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/member.dart';
import 'package:kith/data/models/member_role.dart';

import '../../helpers/model_test_helpers.dart';

void main() {
  final joinedAt = DateTime.utc(2026, 4, 1, 12);
  final sample = Member(
    id: 'uid-1',
    displayName: 'Brian',
    email: 'brian@example.com',
    role: MemberRole.owner,
    joinedAt: joinedAt,
    photoUrl: 'https://example.com/a.png',
  );

  group('Member', () {
    test('round-trips through toMap/fromMap', () {
      expectMapRoundTrip(
        sample: sample,
        toMap: (m) => m.toMap(),
        fromMap: Member.fromMap,
      );
    });

    test('round-trips with a null photoUrl', () {
      expectMapRoundTrip(
        sample: sample.copyWith(clearPhotoUrl: true),
        toMap: (m) => m.toMap(),
        fromMap: Member.fromMap,
      );
    });

    test('persists joinedAt as UTC epoch milliseconds', () {
      final local = sample.copyWith(
        joinedAt: DateTime.utc(2026, 4, 1, 12).toLocal(),
      );

      expect(local.toMap()['joinedAt'], joinedAt.millisecondsSinceEpoch);
      expect(Member.fromMap(local.toMap()).joinedAt.isUtc, isTrue);
    });

    test('persists the role by wire name', () {
      expect(sample.toMap()['role'], 'owner');
      expect(
        Member.fromMap({...sample.toMap(), 'role': 'member'}).role,
        MemberRole.member,
      );
    });

    test('copyWith covers every field', () {
      final otherDate = DateTime.utc(2027);
      expectCopyWithCoversEveryField<Member>(
        sample: sample,
        copyWithNothing: (m) => m.copyWith(),
        cases: [
          CopyWithCase(
            field: 'id',
            mutate: (m) => m.copyWith(id: 'uid-2'),
            read: (m) => m.id,
            expected: 'uid-2',
          ),
          CopyWithCase(
            field: 'displayName',
            mutate: (m) => m.copyWith(displayName: 'Sam'),
            read: (m) => m.displayName,
            expected: 'Sam',
          ),
          CopyWithCase(
            field: 'email',
            mutate: (m) => m.copyWith(email: 'sam@example.com'),
            read: (m) => m.email,
            expected: 'sam@example.com',
          ),
          CopyWithCase(
            field: 'role',
            mutate: (m) => m.copyWith(role: MemberRole.member),
            read: (m) => m.role,
            expected: MemberRole.member,
          ),
          CopyWithCase(
            field: 'joinedAt',
            mutate: (m) => m.copyWith(joinedAt: otherDate),
            read: (m) => m.joinedAt,
            expected: otherDate,
          ),
          CopyWithCase(
            field: 'photoUrl',
            mutate: (m) => m.copyWith(photoUrl: 'https://example.com/b.png'),
            read: (m) => m.photoUrl,
            expected: 'https://example.com/b.png',
          ),
          CopyWithCase(
            field: 'photoUrl (cleared)',
            mutate: (m) => m.copyWith(clearPhotoUrl: true),
            read: (m) => m.photoUrl,
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
          sample.copyWith(displayName: 'other'),
          sample.copyWith(email: 'other@example.com'),
          sample.copyWith(role: MemberRole.member),
          sample.copyWith(joinedAt: DateTime.utc(2020)),
          sample.copyWith(clearPhotoUrl: true),
        ],
      );
    });

    test('toString names every field', () {
      final text = sample.toString();

      for (final fragment in [
        'uid-1',
        'Brian',
        'brian@example.com',
        'owner',
        'https://example.com/a.png',
      ]) {
        expect(text, contains(fragment));
      }
    });
  });
}
