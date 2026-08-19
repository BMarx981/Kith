import 'dart:async';

import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/household.dart';
import 'package:kith/data/models/member.dart';
import 'package:kith/data/models/member_role.dart';
import 'package:kith/data/repositories/household_repository.dart';

/// An in-memory [HouseholdRepository] for widget and controller tests.
///
/// Holds households and their members in maps, so a create followed by a
/// membership read behaves the way the backend does without Firestore or an
/// emulator. Widget tests never build the real repository.
class FakeHouseholdRepository implements HouseholdRepository {
  /// Households by id.
  final households = <String, Household>{};

  /// Members by household id, in the order they joined.
  final members = <String, List<Member>>{};

  /// Arguments of every [createHousehold] call, oldest first.
  final createCalls = <({String name, AuthUser owner, String displayName})>[];

  /// Arguments of every [joinWithInviteCode] call, oldest first.
  final joinCalls = <({String code, AuthUser user, String displayName})>[];

  /// Arguments of every [linkCalendar] call, oldest first.
  final linkCalls =
      <({String householdId, String calendarId, String calendarName})>[];

  /// Household ids passed to [unlinkCalendar], oldest first.
  final unlinkCalls = <String>[];

  /// Arguments of every [setDigestPreference] call, oldest first.
  final digestCalls =
      <({String householdId, String uid, int? digestDay, int digestHour})>[];

  /// Failure to return from the next create or join, instead of succeeding.
  /// Cleared once consumed.
  Failure? nextFailure;

  /// Completes before the next create or join returns, when set. Lets a test
  /// observe the form mid-request.
  Completer<void>? gate;

  /// Error the household and member streams emit instead of data, when set.
  /// Stands in for a query the rules refused or a document that would not
  /// parse.
  Failure? streamFailure;

  /// Error the membership query emits instead of data, when set. Separate
  /// from [streamFailure] because the two fail independently: the membership
  /// lookup is a collection group query with a rule of its own.
  Failure? membershipFailure;

  final _memberships = StreamController<void>.broadcast();
  var _nextId = 0;

  @override
  Future<Result<Household>> createHousehold({
    required String name,
    required AuthUser owner,
    required String displayName,
  }) async {
    createCalls.add((name: name, owner: owner, displayName: displayName));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    final household = Household(
      id: 'hid-${++_nextId}',
      name: name,
      inviteCode: null,
      createdAt: DateTime.utc(2026, 8, 17),
      createdBy: owner.id,
    );
    households[household.id] = household;
    _addMember(household.id, owner, displayName, MemberRole.owner);
    return Ok(household);
  }

  @override
  Future<Result<Household>> joinWithInviteCode({
    required String code,
    required AuthUser user,
    required String displayName,
  }) async {
    joinCalls.add((code: code, user: user, displayName: displayName));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    if (households.isEmpty) {
      return const Err(NotFoundFailure('No household to join.'));
    }
    final household = households.values.first;
    _addMember(household.id, user, displayName, MemberRole.member);
    return Ok(household);
  }

  @override
  Stream<Household?> watchHousehold(String householdId) => _failOr(
    streamFailure,
    () => _onMembershipChange().map((_) => households[householdId]),
  );

  @override
  Stream<List<Member>> watchMembers(String householdId) => _failOr(
    streamFailure,
    () => _onMembershipChange().map(
      (_) => List.of(members[householdId] ?? const <Member>[]),
    ),
  );

  @override
  Stream<List<String>> watchHouseholdIdsFor(String uid) => _failOr(
    membershipFailure,
    () => _onMembershipChange().map(
      (_) => [
        for (final entry in members.entries)
          if (entry.value.any((member) => member.id == uid)) entry.key,
      ],
    ),
  );

  @override
  Future<Result<void>> linkCalendar({
    required String householdId,
    required String calendarId,
    required String calendarName,
  }) async {
    linkCalls.add((
      householdId: householdId,
      calendarId: calendarId,
      calendarName: calendarName,
    ));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    final household = households[householdId];
    if (household == null) {
      return const Err(NotFoundFailure('No such household.'));
    }
    households[householdId] = household.copyWith(
      calendarId: calendarId,
      calendarName: calendarName,
    );
    if (_memberships.hasListener) _memberships.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> unlinkCalendar({required String householdId}) async {
    unlinkCalls.add(householdId);
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    final household = households[householdId];
    if (household == null) {
      return const Err(NotFoundFailure('No such household.'));
    }
    households[householdId] = household.copyWith(clearCalendar: true);
    if (_memberships.hasListener) _memberships.add(null);
    return const Ok(null);
  }

  @override
  Future<Result<void>> setDigestPreference({
    required String householdId,
    required String uid,
    required int? digestDay,
    required int digestHour,
  }) async {
    digestCalls.add((
      householdId: householdId,
      uid: uid,
      digestDay: digestDay,
      digestHour: digestHour,
    ));
    await gate?.future;
    final failure = _takeFailure();
    if (failure != null) return Err(failure);

    final roster = members[householdId];
    final index = roster?.indexWhere((member) => member.id == uid) ?? -1;
    if (roster == null || index < 0) {
      return const Err(NotFoundFailure('No such member.'));
    }
    roster[index] = roster[index].copyWith(
      digestDay: digestDay,
      digestHour: digestHour,
      clearDigestDay: digestDay == null,
    );
    if (_memberships.hasListener) _memberships.add(null);
    return const Ok(null);
  }

  /// Releases the change stream. Register with `addTearDown`.
  Future<void> dispose() => _memberships.close();

  /// [source], or [failure] if one is set.
  ///
  /// Read at subscription time, so clearing the failure and resubscribing is
  /// what a successful retry looks like.
  Stream<T> _failOr<T>(Failure? failure, Stream<T> Function() source) =>
      failure == null ? source() : Stream.error(failure);

  /// Emits now, then again on every membership change, the way a Firestore
  /// query does.
  Stream<void> _onMembershipChange() async* {
    yield null;
    yield* _memberships.stream;
  }

  void _addMember(
    String householdId,
    AuthUser user,
    String displayName,
    MemberRole role,
  ) {
    (members[householdId] ??= []).add(
      Member(
        id: user.id,
        displayName: displayName,
        email: user.email,
        role: role,
        joinedAt: DateTime.utc(2026, 8, 17),
        photoUrl: user.photoUrl,
      ),
    );
    if (_memberships.hasListener) _memberships.add(null);
  }

  Failure? _takeFailure() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }
}
