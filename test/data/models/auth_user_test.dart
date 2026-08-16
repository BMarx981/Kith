import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/auth_user.dart';

import '../../helpers/model_test_helpers.dart';

void main() {
  const sample = AuthUser(
    id: 'uid-1',
    email: 'brian@example.com',
    displayName: 'Brian',
    photoUrl: 'https://example.com/a.png',
  );

  group('AuthUser', () {
    test('round-trips through toMap/fromMap', () {
      expectMapRoundTrip(
        sample: sample,
        toMap: (u) => u.toMap(),
        fromMap: AuthUser.fromMap,
      );
    });

    test('round-trips with both optional fields absent', () {
      expectMapRoundTrip(
        sample: sample.copyWith(clearDisplayName: true, clearPhotoUrl: true),
        toMap: (u) => u.toMap(),
        fromMap: AuthUser.fromMap,
      );
    });

    test('reads a missing displayName as null rather than throwing', () {
      final map = sample.toMap()..remove('displayName');

      expect(AuthUser.fromMap(map).displayName, isNull);
    });

    test('copyWith covers every field', () {
      expectCopyWithCoversEveryField<AuthUser>(
        sample: sample,
        copyWithNothing: (u) => u.copyWith(),
        cases: [
          CopyWithCase(
            field: 'id',
            mutate: (u) => u.copyWith(id: 'uid-2'),
            read: (u) => u.id,
            expected: 'uid-2',
          ),
          CopyWithCase(
            field: 'email',
            mutate: (u) => u.copyWith(email: 'other@example.com'),
            read: (u) => u.email,
            expected: 'other@example.com',
          ),
          CopyWithCase(
            field: 'displayName',
            mutate: (u) => u.copyWith(displayName: 'Bee'),
            read: (u) => u.displayName,
            expected: 'Bee',
          ),
          CopyWithCase(
            field: 'photoUrl',
            mutate: (u) => u.copyWith(photoUrl: 'https://example.com/b.png'),
            read: (u) => u.photoUrl,
            expected: 'https://example.com/b.png',
          ),
        ],
      );
    });

    test('copyWith clears the optional fields explicitly', () {
      expect(sample.copyWith(clearDisplayName: true).displayName, isNull);
      expect(sample.copyWith(clearPhotoUrl: true).photoUrl, isNull);
      expect(
        sample.copyWith(clearDisplayName: true).photoUrl,
        sample.photoUrl,
      );
    });

    test('a clear flag wins over a value passed for the same field', () {
      expect(
        sample
            .copyWith(displayName: 'Ignored', clearDisplayName: true)
            .displayName,
        isNull,
      );
    });

    test('has value equality', () {
      expectValueEquality(
        sample: sample,
        identical: AuthUser.fromMap(sample.toMap()),
        others: [
          sample.copyWith(id: 'uid-2'),
          sample.copyWith(email: 'other@example.com'),
          sample.copyWith(clearDisplayName: true),
          sample.copyWith(clearPhotoUrl: true),
        ],
      );
    });

    test('toString names every field', () {
      expect(
        sample.toString(),
        'AuthUser(id: uid-1, email: brian@example.com, displayName: Brian, '
        'photoUrl: https://example.com/a.png)',
      );
    });
  });
}
