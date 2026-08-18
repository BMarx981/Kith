import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/models/planned_hangout_status.dart';
import 'package:kith/data/repositories/firestore_planned_hangout_repository.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  const householdId = 'hid-1';
  const author = 'uid-1';
  final now = DateTime.utc(2026, 8, 18, 9);
  final nextWeek = DateTime.utc(2026, 8, 25);

  late FakeFirebaseFirestore firestore;
  late FirestorePlannedHangoutRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestorePlannedHangoutRepository(
      firestore,
      Clock.fixed(now),
    );
  });

  CollectionReference<Map<String, dynamic>> plans() => firestore
      .collection(FirestorePlannedHangoutRepository.householdsPath)
      .doc(householdId)
      .collection(FirestorePlannedHangoutRepository.plannedHangoutsPath);

  Future<PlannedHangout> makePlan({
    List<String> contactIds = const ['cid-1'],
    DateTime? plannedFor,
    String? note,
  }) async {
    final result = await repository.planHangout(
      householdId: householdId,
      contactIds: contactIds,
      plannedFor: plannedFor ?? nextWeek,
      createdBy: author,
      note: note,
    );
    return result.valueOrNull!;
  }

  group('planHangout', () {
    test('stores the plan under the household', () async {
      final plan = await makePlan(note: 'Dinner at ours');

      final stored = await plans().doc(plan.id).get();
      expect(PlannedHangout.fromMap(stored.data()!), plan);
      expect(plan.contactIds, ['cid-1']);
      expect(plan.note, 'Dinner at ours');
    });

    test('records it as proposed, with no calendar event yet', () async {
      final plan = await makePlan();

      expect(plan.status, PlannedHangoutStatus.proposed);
      expect(plan.calendarEventId, isNull);
    });

    test('credits the caller and stamps both timestamps', () async {
      final plan = await makePlan();

      expect(plan.createdBy, author);
      expect(plan.createdAt, now);
      expect(plan.updatedAt, now);
    });

    test('keeps the day it is for, not the day it was made', () async {
      final plan = await makePlan(
        plannedFor: DateTime.utc(2026, 8, 25, 19, 30),
      );

      expect(plan.plannedFor, nextWeek);
    });

    test('names each contact once, in the order given', () async {
      final plan = await makePlan(
        contactIds: const ['cid-2', ' cid-1 ', 'cid-2', '  '],
      );

      expect(plan.contactIds, ['cid-2', 'cid-1']);
    });

    test('reads a note of whitespace as no note', () async {
      final plan = await makePlan(note: '   ');

      expect(plan.note, isNull);
    });

    test('refuses a plan naming nobody, without any I/O', () async {
      final result = await repository.planHangout(
        householdId: householdId,
        contactIds: const ['  '],
        plannedFor: nextWeek,
        createdBy: author,
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect((await plans().get()).docs, isEmpty);
    });

    test('refuses a plan naming more people than the rules allow', () async {
      final result = await repository.planHangout(
        householdId: householdId,
        contactIds: [
          for (var index = 0; index <= PlannedHangout.maxContacts; index++)
            'cid-$index',
        ],
        plannedFor: nextWeek,
        createdBy: author,
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('refuses a note past the stored length', () async {
      final result = await repository.planHangout(
        householdId: householdId,
        contactIds: const ['cid-1'],
        plannedFor: nextWeek,
        createdBy: author,
        note: 'x' * (PlannedHangout.maxNoteLength + 1),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('refuses a plan with nobody to credit it to', () async {
      final result = await repository.planHangout(
        householdId: householdId,
        contactIds: const ['cid-1'],
        plannedFor: nextWeek,
        createdBy: '',
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

      final result = await FirestorePlannedHangoutRepository(broken)
          .planHangout(
            householdId: householdId,
            contactIds: const ['cid-1'],
            plannedFor: nextWeek,
            createdBy: author,
          );

      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });

  group('snoozeContacts', () {
    test('stores a snooze running to the day given', () async {
      final result = await repository.snoozeContacts(
        householdId: householdId,
        contactIds: const ['cid-1'],
        until: nextWeek,
        createdBy: author,
      );
      final plan = result.valueOrNull!;

      expect(plan.status, PlannedHangoutStatus.snoozed);
      expect(plan.plannedFor, nextWeek);
      expect(plan.note, isNull);
      expect(
        PlannedHangout.fromMap((await plans().doc(plan.id).get()).data()!),
        plan,
      );
    });

    test('refuses a snooze naming nobody', () async {
      final result = await repository.snoozeContacts(
        householdId: householdId,
        contactIds: const [],
        until: nextWeek,
        createdBy: author,
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('cancelPlan', () {
    test('removes the plan', () async {
      final plan = await makePlan();

      final result = await repository.cancelPlan(
        householdId: householdId,
        plannedHangoutId: plan.id,
      );

      expect(result.isOk, isTrue);
      expect((await plans().get()).docs, isEmpty);
    });

    test('reports a backend refusal as a domain failure', () async {
      final plan = await makePlan();
      whenCalling(Invocation.method(#delete, null))
          .on(plans().doc(plan.id))
          .thenThrow(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'unavailable',
            ),
          );

      final result = await repository.cancelPlan(
        householdId: householdId,
        plannedHangoutId: plan.id,
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('watchPlannedHangouts', () {
    test('emits the household plans, soonest day first', () async {
      await makePlan(plannedFor: DateTime.utc(2026, 9, 10));
      await makePlan(plannedFor: DateTime.utc(2026, 8, 20));
      await makePlan(plannedFor: DateTime.utc(2026, 8, 30));

      final standing = await repository
          .watchPlannedHangouts(householdId)
          .first;

      expect(
        [for (final plan in standing) plan.plannedFor],
        [
          DateTime.utc(2026, 8, 20),
          DateTime.utc(2026, 8, 30),
          DateTime.utc(2026, 9, 10),
        ],
      );
    });

    test('orders two plans for one day by id, so it never reshuffles', ()
        async {
      await makePlan();
      await makePlan();

      final standing = await repository
          .watchPlannedHangouts(householdId)
          .first;
      final ids = [for (final plan in standing) plan.id];

      expect(ids, [...ids]..sort());
    });

    test('emits again when a plan is made', () async {
      final emissions = repository
          .watchPlannedHangouts(householdId)
          .take(2)
          .toList();
      await makePlan();

      expect(await emissions, [isEmpty, hasLength(1)]);
    });

    test('emits nothing for a household with no plans', () async {
      expect(await repository.watchPlannedHangouts(householdId).first, isEmpty);
    });

    test('maps a stream error onto a domain failure', () async {
      final broken = _MockFirestore();
      when(() => broken.collection(any())).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        ),
      );

      expect(
        FirestorePlannedHangoutRepository(
          broken,
        ).watchPlannedHangouts(householdId),
        emitsError(isA<PermissionFailure>()),
      );
    });
  });
}
