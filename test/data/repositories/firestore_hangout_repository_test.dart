import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/data/repositories/firestore_hangout_repository.dart';
import 'package:kith/features/hangouts/domain/hangout_draft.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  const householdId = 'hid-1';
  const author = 'uid-1';
  final now = DateTime.utc(2026, 8, 18, 9);
  final later = DateTime.utc(2026, 9, 1, 9);

  final draft = HangoutDraft(
    occurredOn: DateTime.utc(2026, 8, 14),
    contactIds: const ['cid-1', 'cid-2'],
    attendeeIds: const ['uid-1'],
    note: 'Barbecue in their garden',
  );

  late FakeFirebaseFirestore firestore;
  late FirestoreHangoutRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreHangoutRepository(firestore, Clock.fixed(now));
  });

  CollectionReference<Map<String, dynamic>> hangouts() => firestore
      .collection(FirestoreHangoutRepository.householdsPath)
      .doc(householdId)
      .collection(FirestoreHangoutRepository.hangoutsPath);

  Future<Hangout> log([HangoutDraft? input]) async {
    final result = await repository.logHangout(
      householdId: householdId,
      draft: input ?? draft,
      createdBy: author,
    );
    return result.valueOrNull!;
  }

  group('logHangout', () {
    test('stores the hangout under the household', () async {
      final hangout = await log();

      final stored = await hangouts().doc(hangout.id).get();
      expect(Hangout.fromMap(stored.data()!), hangout);
      expect(hangout.contactIds, ['cid-1', 'cid-2']);
      expect(hangout.note, 'Barbecue in their garden');
    });

    test(
      'credits the caller and stamps both timestamps with the clock',
      () async {
        final hangout = await log();

        expect(hangout.createdBy, author);
        expect(hangout.createdAt, now);
        expect(hangout.updatedAt, now);
      },
    );

    test('stores the day it happened, not the day it was logged', () async {
      final hangout = await log();

      expect(hangout.occurredOn, DateTime.utc(2026, 8, 14));
    });

    test('normalises what the form collected', () async {
      final hangout = await log(
        draft.copyWith(
          contactIds: const ['cid-1', 'cid-1', ' '],
          note: '   ',
        ),
      );

      expect(hangout.contactIds, ['cid-1']);
      expect(hangout.note, isNull);
    });

    test(
      'refuses a hangout naming nobody, without touching the backend',
      () async {
        final result = await repository.logHangout(
          householdId: householdId,
          draft: draft.copyWith(contactIds: const []),
          createdBy: author,
        );

        expect(result.failureOrNull, isA<ValidationFailure>());
        expect((await hangouts().get()).docs, isEmpty);
      },
    );

    test('refuses a hangout with nobody to credit it to', () async {
      final result = await repository.logHangout(
        householdId: householdId,
        draft: draft,
        createdBy: '',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((await hangouts().get()).docs, isEmpty);
    });

    test('refuses more contacts than the rules allow', () async {
      final result = await repository.logHangout(
        householdId: householdId,
        draft: draft.copyWith(
          contactIds: [
            for (var i = 0; i <= Hangout.maxContacts; i++) 'cid-$i',
          ],
        ),
        createdBy: author,
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('refuses more attendees than the rules allow', () async {
      final result = await repository.logHangout(
        householdId: householdId,
        draft: draft.copyWith(
          attendeeIds: [
            for (var i = 0; i <= Hangout.maxAttendees; i++) 'uid-$i',
          ],
        ),
        createdBy: author,
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('refuses an oversized note', () async {
      final result = await repository.logHangout(
        householdId: householdId,
        draft: draft.copyWith(note: 'a' * (Hangout.maxNoteLength + 1)),
        createdBy: author,
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('reports a backend refusal as a domain failure', () async {
      // The document id is minted inside the write, so the refusal is staged
      // on the collection lookup that precedes it rather than on the set.
      final broken = _MockFirestore();
      when(() => broken.collection(any())).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        ),
      );

      final result = await FirestoreHangoutRepository(broken).logHangout(
        householdId: householdId,
        draft: draft,
        createdBy: author,
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });

  group('updateHangout', () {
    test('applies what the form changed', () async {
      final hangout = await log();
      final repositoryLater = FirestoreHangoutRepository(
        firestore,
        Clock.fixed(later),
      );

      final result = await repositoryLater.updateHangout(
        householdId: householdId,
        hangoutId: hangout.id,
        draft: draft.copyWith(
          occurredOn: DateTime.utc(2026, 8, 15),
          note: 'Actually the 15th',
        ),
      );

      expect(result.isOk, isTrue);
      final stored = Hangout.fromMap(
        (await hangouts().doc(hangout.id).get()).data()!,
      );
      expect(stored.occurredOn, DateTime.utc(2026, 8, 15));
      expect(stored.note, 'Actually the 15th');
      expect(stored.updatedAt, later);
    });

    test('leaves who logged it and when they logged it alone', () async {
      final hangout = await log();
      final repositoryLater = FirestoreHangoutRepository(
        firestore,
        Clock.fixed(later),
      );

      await repositoryLater.updateHangout(
        householdId: householdId,
        hangoutId: hangout.id,
        draft: draft.copyWith(note: 'Edited'),
      );

      final stored = Hangout.fromMap(
        (await hangouts().doc(hangout.id).get()).data()!,
      );
      expect(stored.createdBy, author);
      expect(stored.createdAt, now);
    });

    test('refuses an edit that leaves nobody on the hangout', () async {
      final hangout = await log();

      final result = await repository.updateHangout(
        householdId: householdId,
        hangoutId: hangout.id,
        draft: draft.copyWith(contactIds: const []),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('reports a hangout deleted from under the form', () async {
      final result = await repository.updateHangout(
        householdId: householdId,
        hangoutId: 'nope',
        draft: draft,
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('deleteHangout', () {
    test('removes the entry', () async {
      final hangout = await log();

      final result = await repository.deleteHangout(
        householdId: householdId,
        hangoutId: hangout.id,
      );

      expect(result.isOk, isTrue);
      expect((await hangouts().get()).docs, isEmpty);
    });

    test('reports a backend refusal as a domain failure', () async {
      final hangout = await log();
      whenCalling(Invocation.method(#delete, null))
          .on(hangouts().doc(hangout.id))
          .thenThrow(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'unavailable',
            ),
          );

      final result = await repository.deleteHangout(
        householdId: householdId,
        hangoutId: hangout.id,
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('watchHangouts', () {
    test('emits the household timeline, most recent day first', () async {
      await log(draft.copyWith(occurredOn: DateTime.utc(2026, 8)));
      await log(draft.copyWith(occurredOn: DateTime.utc(2026, 8, 16)));
      await log(draft.copyWith(occurredOn: DateTime.utc(2026, 8, 9)));

      final timeline = await repository.watchHangouts(householdId).first;

      expect(
        [for (final hangout in timeline) hangout.occurredOn],
        [
          DateTime.utc(2026, 8, 16),
          DateTime.utc(2026, 8, 9),
          DateTime.utc(2026, 8),
        ],
      );
    });

    test(
      'orders two hangouts on one day by id, so it never reshuffles',
      () async {
        await log();
        await log();

        final timeline = await repository.watchHangouts(householdId).first;
        final ids = [for (final hangout in timeline) hangout.id];

        expect(ids, [...ids]..sort());
      },
    );

    test('emits again when a hangout is logged', () async {
      final emissions = repository.watchHangouts(householdId).take(2).toList();
      await log();

      expect(await emissions, [isEmpty, hasLength(1)]);
    });

    test(
      'emits an empty timeline for a household with nothing logged',
      () async {
        expect(await repository.watchHangouts(householdId).first, isEmpty);
      },
    );

    test('maps a stream error onto a domain failure', () async {
      final broken = _MockFirestore();
      when(() => broken.collection(any())).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        ),
      );

      expect(
        FirestoreHangoutRepository(broken).watchHangouts(householdId),
        emitsError(isA<PermissionFailure>()),
      );
    });
  });
}
