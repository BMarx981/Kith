import 'dart:math';

import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/household.dart';
import 'package:kith/data/models/member.dart';
import 'package:kith/data/models/member_role.dart';
import 'package:kith/data/repositories/firestore_household_repository.dart';
import 'package:kith/features/household/domain/invite_code.dart';
import 'package:kith/features/notifications/domain/digest_schedule.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  const owner = AuthUser(
    id: 'uid-owner',
    email: 'brian@example.com',
    displayName: 'Brian',
  );
  const joiner = AuthUser(id: 'uid-joiner', email: 'partner@example.com');
  final now = DateTime.utc(2026, 8, 16, 12);

  late FakeFirebaseFirestore firestore;
  late FirestoreHouseholdRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreHouseholdRepository(
      firestore,
      Random(1),
      Clock.fixed(now),
    );
  });

  Future<Household> createHousehold({String name = 'The Marx house'}) async {
    final result = await repository.createHousehold(
      name: name,
      owner: owner,
      displayName: 'Brian',
    );
    return result.valueOrNull!;
  }

  /// Fills the index with the codes [random] is about to draw, so the next
  /// reservation collides however many times the test wants.
  Future<void> occupyCodesDrawnBy(Random random, {required int count}) async {
    for (var i = 0; i < count; i++) {
      await firestore
          .collection(FirestoreHouseholdRepository.inviteCodesPath)
          .doc(InviteCode.generate(random).value)
          .set({'householdId': 'someone-else', 'createdBy': 'uid-x'});
    }
  }

  Future<Map<String, dynamic>?> memberData(
    String householdId,
    String uid,
  ) async {
    final snapshot = await firestore
        .collection(FirestoreHouseholdRepository.householdsPath)
        .doc(householdId)
        .collection(FirestoreHouseholdRepository.membersPath)
        .doc(uid)
        .get();
    return snapshot.data();
  }

  group('createHousehold', () {
    test('stores the household with a fresh invite code', () async {
      final result = await repository.createHousehold(
        name: 'The Marx house',
        owner: owner,
        displayName: 'Brian',
      );

      final household = result.valueOrNull!;
      expect(household.name, 'The Marx house');
      expect(household.createdBy, owner.id);
      expect(household.createdAt, now);
      expect(household.inviteCode, isNotNull);

      final stored = await firestore
          .collection(FirestoreHouseholdRepository.householdsPath)
          .doc(household.id)
          .get();
      expect(Household.fromMap(stored.data()!), household);
    });

    test('makes the creator the owner', () async {
      final household = await createHousehold();

      final member = await memberData(household.id, owner.id);
      expect(member!['role'], MemberRole.owner.wireName);
      expect(member['displayName'], 'Brian');
      expect(member['email'], owner.email);
      expect(member['joinedAt'], now.millisecondsSinceEpoch);
    });

    test('points the invite code index at the new household', () async {
      final household = await createHousehold();

      final entry = await firestore
          .collection(FirestoreHouseholdRepository.inviteCodesPath)
          .doc(household.inviteCode!.value)
          .get();

      expect(entry.data(), {
        'householdId': household.id,
        'createdBy': owner.id,
        'createdAt': now.millisecondsSinceEpoch,
      });
    });

    test('reserves the code before writing the household', () async {
      // The rules require the index entry to exist first, so a creation that
      // cannot reserve a code must not leave a household behind.
      await occupyCodesDrawnBy(
        Random(1),
        count: FirestoreHouseholdRepository.maxCodeAttempts,
      );

      final result = await repository.createHousehold(
        name: 'The Marx house',
        owner: owner,
        displayName: 'Brian',
      );

      expect(result.failureOrNull, isA<ConflictFailure>());
      final households = await firestore
          .collection(FirestoreHouseholdRepository.householdsPath)
          .get();
      expect(households.docs, isEmpty);
    });

    test('redraws a code that is already taken', () async {
      final first = InviteCode.generate(Random(1));
      await firestore
          .collection(FirestoreHouseholdRepository.inviteCodesPath)
          .doc(first.value)
          .set({'householdId': 'someone-else', 'createdBy': 'uid-x'});

      final household = await createHousehold();

      expect(household.inviteCode!.value, isNot(first.value));
    });

    test('gives two households different codes', () async {
      final first = await createHousehold();
      final second = await createHousehold(name: 'The other house');

      expect(first.inviteCode, isNot(second.inviteCode));
    });

    test('refuses an empty household name', () async {
      final result = await repository.createHousehold(
        name: '   ',
        owner: owner,
        displayName: 'Brian',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('refuses an empty display name', () async {
      final result = await repository.createHousehold(
        name: 'The Marx house',
        owner: owner,
        displayName: '  ',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('trims what it stores', () async {
      final result = await repository.createHousehold(
        name: '  The Marx house  ',
        owner: owner,
        displayName: '  Brian  ',
      );

      final household = result.valueOrNull!;
      expect(household.name, 'The Marx house');
      expect(
        (await memberData(household.id, owner.id))!['displayName'],
        'Brian',
      );
    });
  });

  group('joinWithInviteCode', () {
    test('adds the joiner as a plain member', () async {
      final household = await createHousehold();

      final result = await repository.joinWithInviteCode(
        code: household.inviteCode!.value,
        user: joiner,
        displayName: 'Partner',
      );

      expect(result.valueOrNull, household);
      final member = await memberData(household.id, joiner.id);
      expect(member!['role'], MemberRole.member.wireName);
      expect(member['displayName'], 'Partner');
    });

    test('echoes the code back for the rules to check', () async {
      final household = await createHousehold();

      await repository.joinWithInviteCode(
        code: household.inviteCode!.value,
        user: joiner,
        displayName: 'Partner',
      );

      final member = await memberData(household.id, joiner.id);
      expect(member!['joinedWithCode'], household.inviteCode!.value);
    });

    test(
      'accepts a code typed with separators and confusable letters',
      () async {
        final household = await createHousehold();
        final typed = household.inviteCode!.value
            .toLowerCase()
            .replaceAll('1', 'l')
            .replaceAll('0', 'o');

        final result = await repository.joinWithInviteCode(
          code: '  $typed ',
          user: joiner,
          displayName: 'Partner',
        );

        expect(result.valueOrNull, household);
      },
    );

    test('refuses a malformed code without touching the backend', () async {
      final result = await repository.joinWithInviteCode(
        code: 'nope',
        user: joiner,
        displayName: 'Partner',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('reports a code that matches no household', () async {
      final result = await repository.joinWithInviteCode(
        code: 'ABC123',
        user: joiner,
        displayName: 'Partner',
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('reports an index entry left pointing at nothing', () async {
      await firestore
          .collection(FirestoreHouseholdRepository.inviteCodesPath)
          .doc('ABC123')
          .set({'householdId': 'gone', 'createdBy': 'uid-x'});

      final result = await repository.joinWithInviteCode(
        code: 'ABC123',
        user: joiner,
        displayName: 'Partner',
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('a refused member write reads as a code that does not work', () async {
      // The rules, not the client, compare the echoed code with the
      // household's current one, so a stale or wrong code comes back as a
      // refused write. Both mean the same thing to whoever typed it.
      await firestore
          .collection(FirestoreHouseholdRepository.inviteCodesPath)
          .doc('ABC123')
          .set({'householdId': 'hid-1', 'createdBy': 'uid-x'});
      whenCalling(Invocation.method(#set, null))
          .on(
            firestore
                .collection(FirestoreHouseholdRepository.householdsPath)
                .doc('hid-1')
                .collection(FirestoreHouseholdRepository.membersPath)
                .doc(joiner.id),
          )
          .thenThrow(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            ),
          );

      final result = await repository.joinWithInviteCode(
        code: 'ABC123',
        user: joiner,
        displayName: 'Partner',
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test(
      'a member write that fails for any other reason is reported as is',
      () async {
        await firestore
            .collection(FirestoreHouseholdRepository.inviteCodesPath)
            .doc('ABC123')
            .set({'householdId': 'hid-1', 'createdBy': 'uid-x'});
        whenCalling(Invocation.method(#set, null))
            .on(
              firestore
                  .collection(FirestoreHouseholdRepository.householdsPath)
                  .doc('hid-1')
                  .collection(FirestoreHouseholdRepository.membersPath)
                  .doc(joiner.id),
            )
            .thenThrow(
              FirebaseException(
                plugin: 'cloud_firestore',
                code: 'unavailable',
                message: 'offline',
              ),
            );

        final result = await repository.joinWithInviteCode(
          code: 'ABC123',
          user: joiner,
          displayName: 'Partner',
        );

        expect(result.failureOrNull, const NetworkFailure('offline'));
      },
    );

    test('refuses an empty display name', () async {
      final household = await createHousehold();

      final result = await repository.joinWithInviteCode(
        code: household.inviteCode!.value,
        user: joiner,
        displayName: ' ',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(await memberData(household.id, joiner.id), isNull);
    });
  });

  group('failure mapping', () {
    /// Makes the invite code lookup fail the way the backend would.
    void throwOnCodeLookup(String errorCode, {String? message}) {
      whenCalling(Invocation.method(#get, null))
          .on(
            firestore
                .collection(FirestoreHouseholdRepository.inviteCodesPath)
                .doc('ABC123'),
          )
          .thenThrow(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: errorCode,
              message: message,
            ),
          );
    }

    Future<Object?> joinFailure() async {
      final result = await repository.joinWithInviteCode(
        code: 'ABC123',
        user: joiner,
        displayName: 'Partner',
      );
      return result.failureOrNull;
    }

    test('rules refusing a read becomes a PermissionFailure', () async {
      throwOnCodeLookup('permission-denied', message: 'refused');

      expect(await joinFailure(), const PermissionFailure('refused'));
    });

    test('an unreachable backend becomes a NetworkFailure', () async {
      throwOnCodeLookup('unavailable', message: 'offline');

      expect(await joinFailure(), const NetworkFailure('offline'));
    });

    test('an unrecognised code becomes an UnknownFailure', () async {
      throwOnCodeLookup('internal', message: 'boom');

      expect(await joinFailure(), isA<UnknownFailure>());
    });

    test('no Firebase type escapes the repository', () async {
      throwOnCodeLookup('permission-denied');

      final failure = await joinFailure();

      expect(failure, isA<Failure>());
      expect(failure, isNot(isA<FirebaseException>()));
    });

    test('a query that will not even open reports a domain failure', () async {
      // fake_cloud_firestore always opens a query, so refusing at that point
      // takes a mock. It is worth covering: a member removed from a household
      // is refused here rather than mid-stream.
      final unusable = _MockFirestore();
      when(() => unusable.collection(any())).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'refused',
        ),
      );

      await expectLater(
        FirestoreHouseholdRepository(
          unusable,
          Random(1),
        ).watchHousehold('hid-1').first,
        throwsA(const PermissionFailure('refused')),
      );
    });

    test('a document that will not parse reports a domain failure', () async {
      await firestore
          .collection(FirestoreHouseholdRepository.householdsPath)
          .doc('hid-1')
          .set({'id': 'hid-1', 'name': 42});

      await expectLater(
        repository.watchHousehold('hid-1').first,
        throwsA(isA<UnknownFailure>()),
      );
    });
  });

  group('setDigestPreference', () {
    test('stores the day and hour on the member document', () async {
      final household = await createHousehold();

      final result = await repository.setDigestPreference(
        householdId: household.id,
        uid: owner.id,
        digestDay: DateTime.friday,
        digestHour: 18,
      );

      expect(result.isOk, isTrue);
      final member = await memberData(household.id, owner.id);
      expect(member!['digestDay'], DateTime.friday);
      expect(member['digestHour'], 18);
    });

    test('turning it off keeps the hour that was picked', () async {
      final household = await createHousehold();
      await repository.setDigestPreference(
        householdId: household.id,
        uid: owner.id,
        digestDay: DateTime.friday,
        digestHour: 18,
      );

      await repository.setDigestPreference(
        householdId: household.id,
        uid: owner.id,
        digestDay: null,
        digestHour: 18,
      );

      final member = await memberData(household.id, owner.id);
      expect(member!['digestDay'], isNull);
      expect(member['digestHour'], 18);
    });

    test('the preference reaches the member stream', () async {
      final household = await createHousehold();

      await repository.setDigestPreference(
        householdId: household.id,
        uid: owner.id,
        digestDay: DateTime.sunday,
        digestHour: 9,
      );

      final members = await repository.watchMembers(household.id).first;
      expect(members.single.digestDay, DateTime.sunday);
      expect(members.single.digestHour, 9);
      expect(members.single.wantsDigest, isTrue);
    });

    test('leaves the rest of the member alone', () async {
      final household = await createHousehold();

      await repository.setDigestPreference(
        householdId: household.id,
        uid: owner.id,
        digestDay: DateTime.sunday,
        digestHour: 9,
      );

      final member = await memberData(household.id, owner.id);
      expect(member!['role'], MemberRole.owner.wireName);
      expect(member['displayName'], 'Brian');
      expect(member['joinedAt'], now.millisecondsSinceEpoch);
    });

    test('refuses a day or an hour out of range, without any I/O', () async {
      final household = await createHousehold();

      final noSuchDay = await repository.setDigestPreference(
        householdId: household.id,
        uid: owner.id,
        digestDay: 8,
        digestHour: 9,
      );
      final noSuchHour = await repository.setDigestPreference(
        householdId: household.id,
        uid: owner.id,
        digestDay: DateTime.sunday,
        digestHour: 24,
      );

      expect(noSuchDay.failureOrNull, isA<ValidationFailure>());
      expect(noSuchHour.failureOrNull, isA<ValidationFailure>());
      // The member was written with no digest asked for, and neither refusal
      // reached the document to change that.
      final member = await memberData(household.id, owner.id);
      expect(member!['digestDay'], isNull);
      expect(member['digestHour'], DigestSchedule.defaultHour);
    });

    test('maps a refused write onto a domain failure', () async {
      final household = await createHousehold();
      whenCalling(Invocation.method(#update, null))
          .on(
            firestore
                .collection(FirestoreHouseholdRepository.householdsPath)
                .doc(household.id)
                .collection(FirestoreHouseholdRepository.membersPath)
                .doc(owner.id),
          )
          .thenThrow(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            ),
          );

      final result = await repository.setDigestPreference(
        householdId: household.id,
        uid: owner.id,
        digestDay: DateTime.sunday,
        digestHour: 9,
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });

  group('linkCalendar', () {
    test('points the household at the chosen calendar', () async {
      final household = await createHousehold();

      final result = await repository.linkCalendar(
        householdId: household.id,
        calendarId: 'kith@group.calendar.google.com',
        calendarName: 'Hangouts',
      );

      expect(result.isOk, isTrue);
      final stored = await repository.watchHousehold(household.id).first;
      expect(stored?.calendarId, 'kith@group.calendar.google.com');
      expect(stored?.calendarName, 'Hangouts');
      expect(stored?.hasCalendar, isTrue);
    });

    test('leaves the name and the invite code where they were', () async {
      final household = await createHousehold();

      await repository.linkCalendar(
        householdId: household.id,
        calendarId: 'cal-1',
        calendarName: 'Family',
      );

      final stored = await repository.watchHousehold(household.id).first;
      expect(stored?.name, household.name);
      expect(stored?.inviteCode, household.inviteCode);
    });

    test('trims what it is given', () async {
      final household = await createHousehold();

      await repository.linkCalendar(
        householdId: household.id,
        calendarId: '  cal-1 ',
        calendarName: ' Family  ',
      );

      final stored = await repository.watchHousehold(household.id).first;
      expect(stored?.calendarId, 'cal-1');
      expect(stored?.calendarName, 'Family');
    });

    test('refuses a link the rules would reject, without I/O', () async {
      final household = await createHousehold();

      final blank = await repository.linkCalendar(
        householdId: household.id,
        calendarId: '   ',
        calendarName: 'Family',
      );
      final huge = await repository.linkCalendar(
        householdId: household.id,
        calendarId: 'c' * (Household.maxCalendarIdLength + 1),
        calendarName: 'Family',
      );
      final longName = await repository.linkCalendar(
        householdId: household.id,
        calendarId: 'cal-1',
        calendarName: 'n' * (Household.maxCalendarNameLength + 1),
      );

      expect(blank.failureOrNull, isA<ValidationFailure>());
      expect(huge.failureOrNull, isA<ValidationFailure>());
      expect(longName.failureOrNull, isA<ValidationFailure>());
      final stored = await repository.watchHousehold(household.id).first;
      expect(stored?.hasCalendar, isFalse);
    });

    test('maps a refused write onto a domain failure', () async {
      final household = await createHousehold();
      whenCalling(Invocation.method(#update, null))
          .on(
            firestore
                .collection(FirestoreHouseholdRepository.householdsPath)
                .doc(household.id),
          )
          .thenThrow(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'permission-denied',
            ),
          );

      final result = await repository.linkCalendar(
        householdId: household.id,
        calendarId: 'cal-1',
        calendarName: 'Family',
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });

  group('unlinkCalendar', () {
    test('clears both halves of the link', () async {
      final household = await createHousehold();
      await repository.linkCalendar(
        householdId: household.id,
        calendarId: 'cal-1',
        calendarName: 'Family',
      );

      final result = await repository.unlinkCalendar(
        householdId: household.id,
      );

      expect(result.isOk, isTrue);
      final stored = await repository.watchHousehold(household.id).first;
      expect(stored?.calendarId, isNull);
      expect(stored?.calendarName, isNull);
      expect(stored?.hasCalendar, isFalse);
    });

    test('reports a household that is no longer there', () async {
      final result = await repository.unlinkCalendar(householdId: 'gone');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });

  group('watchHousehold', () {
    test('emits the household and then its changes', () async {
      final household = await createHousehold();
      final seen = <Household?>[];
      final subscription = repository
          .watchHousehold(household.id)
          .listen(seen.add);
      addTearDown(subscription.cancel);
      await pumpEventQueue();

      await firestore
          .collection(FirestoreHouseholdRepository.householdsPath)
          .doc(household.id)
          .update({'name': 'Renamed'});
      await pumpEventQueue();

      expect(seen.first, household);
      expect(seen.last?.name, 'Renamed');
    });

    test('emits null for a household that does not exist', () async {
      await expectLater(
        repository.watchHousehold('nope').first,
        completion(isNull),
      );
    });
  });

  group('watchMembers', () {
    test('emits members longest-standing first', () async {
      final household = await createHousehold();
      repository = FirestoreHouseholdRepository(
        firestore,
        Random(2),
        Clock.fixed(now.add(const Duration(days: 1))),
      );
      await repository.joinWithInviteCode(
        code: household.inviteCode!.value,
        user: joiner,
        displayName: 'Partner',
      );

      final members = await repository.watchMembers(household.id).first;

      expect(members.map((m) => m.id), [owner.id, joiner.id]);
      expect(members.first.role, MemberRole.owner);
      expect(members.last.role, MemberRole.member);
      expect(members.last.joinedAt, now.add(const Duration(days: 1)));
    });

    test('emits an empty list for a household with no members', () async {
      await expectLater(
        repository.watchMembers('nope').first,
        completion(isEmpty),
      );
    });
  });

  group('watchHouseholdIdsFor', () {
    /// Writes a membership document straight into [householdId], the way a
    /// join the rules accepted would leave one behind.
    Future<void> addMembership(
      String householdId,
      String uid, {
      required DateTime joinedAt,
    }) => firestore
        .collection(FirestoreHouseholdRepository.householdsPath)
        .doc(householdId)
        .collection(FirestoreHouseholdRepository.membersPath)
        .doc(uid)
        .set(
          Member(
            id: uid,
            displayName: 'Someone',
            email: 'someone@example.com',
            role: MemberRole.member,
            joinedAt: joinedAt,
          ).toMap(),
        );

    test('finds the household the user created', () async {
      final household = await createHousehold();

      await expectLater(
        repository.watchHouseholdIdsFor(owner.id).first,
        completion([household.id]),
      );
    });

    test('finds the household the user joined', () async {
      final household = await createHousehold();
      await repository.joinWithInviteCode(
        code: household.inviteCode!.value,
        user: joiner,
        displayName: 'Partner',
      );

      await expectLater(
        repository.watchHouseholdIdsFor(joiner.id).first,
        completion([household.id]),
      );
    });

    test('emits an empty list for a user in no household', () async {
      await createHousehold();

      await expectLater(
        repository.watchHouseholdIdsFor('uid-stranger').first,
        completion(isEmpty),
      );
    });

    test("ignores other people's memberships", () async {
      final household = await createHousehold();

      final ids = await repository.watchHouseholdIdsFor(joiner.id).first;

      expect(ids, isEmpty);
      expect(await repository.watchHouseholdIdsFor(owner.id).first, [
        household.id,
      ]);
    });

    test('orders several households longest-standing first', () async {
      // Written newest first, so an implementation that just takes the query
      // order rather than sorting comes back the wrong way round.
      await addMembership(
        'hid-newest',
        joiner.id,
        joinedAt: now.add(const Duration(days: 2)),
      );
      await addMembership('hid-oldest', joiner.id, joinedAt: now);
      await addMembership(
        'hid-middle',
        joiner.id,
        joinedAt: now.add(const Duration(days: 1)),
      );

      await expectLater(
        repository.watchHouseholdIdsFor(joiner.id).first,
        completion(['hid-oldest', 'hid-middle', 'hid-newest']),
      );
    });

    test('a query that will not even open reports a domain failure', () async {
      final unusable = _MockFirestore();
      when(() => unusable.collectionGroup(any())).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'refused',
        ),
      );

      await expectLater(
        FirestoreHouseholdRepository(
          unusable,
          Random(1),
        ).watchHouseholdIdsFor(owner.id).first,
        throwsA(const PermissionFailure('refused')),
      );
    });

    test('a membership that will not parse reports a domain failure', () async {
      await firestore
          .collection(FirestoreHouseholdRepository.householdsPath)
          .doc('hid-1')
          .collection(FirestoreHouseholdRepository.membersPath)
          .doc(owner.id)
          .set({'id': owner.id, 'joinedAt': 'the other day'});

      await expectLater(
        repository.watchHouseholdIdsFor(owner.id).first,
        throwsA(isA<UnknownFailure>()),
      );
    });
  });
}
