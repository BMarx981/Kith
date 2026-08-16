import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/household.dart';
import 'package:kith/data/models/member.dart';
import 'package:kith/data/models/member_role.dart';
import 'package:kith/data/repositories/household_repository.dart';
import 'package:kith/features/household/domain/invite_code.dart';

/// [HouseholdRepository] backed by Cloud Firestore.
///
/// One of two places in the app that names a Firestore type, the other being
/// the composition root that builds it. Every `FirebaseException` is
/// translated into a domain [Failure] before it leaves.
class FirestoreHouseholdRepository implements HouseholdRepository {
  /// The [Random] seeds invite code generation, so tests can pin the codes
  /// drawn; the [Clock] is what makes join and creation timestamps testable.
  /// Both are positional because a named parameter cannot bind straight to a
  /// private field.
  const FirestoreHouseholdRepository(
    this._firestore,
    this._random, [
    this._clock = const Clock(),
  ]);

  final FirebaseFirestore _firestore;
  final Random _random;
  final Clock _clock;

  /// Top-level households collection.
  static const householdsPath = 'households';

  /// Members subcollection of a household.
  static const membersPath = 'members';

  /// The code to household id index. The only top-level collection besides
  /// [householdsPath], and it holds no user data.
  static const inviteCodesPath = 'inviteCodes';

  /// How many times a colliding invite code is redrawn before giving up.
  ///
  /// The code space is 32^6, so needing even a second draw means something is
  /// wrong rather than unlucky.
  static const maxCodeAttempts = 5;

  @override
  Future<Result<Household>> createHousehold({
    required String name,
    required AuthUser owner,
    required String displayName,
  }) async {
    final householdName = name.trim();
    if (householdName.isEmpty) {
      return const Err(ValidationFailure('Give the household a name.'));
    }
    final memberName = displayName.trim();
    if (memberName.isEmpty) {
      return const Err(ValidationFailure('Enter the name to show others.'));
    }

    return _guard(() async {
      final now = _clock.now().toUtc();
      // The id is drawn locally because the index entry has to name the
      // household before the household document exists. See
      // docs/M1-FIRESTORE-RULES.md: the writes go index, household, member,
      // and each step is inert on its own if the next one never happens.
      final document = _firestore.collection(householdsPath).doc();
      final code = await _reserveInviteCode(
        householdId: document.id,
        createdBy: owner.id,
        now: now,
      );
      if (code == null) {
        return const Err(
          ConflictFailure('Could not reserve an unused invite code.'),
        );
      }

      final household = Household(
        id: document.id,
        name: householdName,
        inviteCode: code,
        createdAt: now,
        createdBy: owner.id,
      );
      await document.set(household.toMap());
      await _memberDocument(document.id, owner.id).set(
        _memberOf(
          user: owner,
          displayName: memberName,
          role: MemberRole.owner,
          joinedAt: now,
        ).toMap(),
      );
      return Ok(household);
    });
  }

  @override
  Future<Result<Household>> joinWithInviteCode({
    required String code,
    required AuthUser user,
    required String displayName,
  }) async {
    final parsed = InviteCode.parse(code);
    if (parsed case Err(:final failure)) return Err(failure);
    final inviteCode = (parsed as Ok<InviteCode>).value;

    final memberName = displayName.trim();
    if (memberName.isEmpty) {
      return const Err(ValidationFailure('Enter the name to show others.'));
    }

    return _guard(() async {
      final entry = await _firestore
          .collection(inviteCodesPath)
          .doc(inviteCode.value)
          .get();
      final householdId = entry.data()?['householdId'] as String?;
      if (householdId == null) return const Err(_noSuchCode);

      // The household document is unreadable until the member document
      // exists, so the code is checked against it server-side: the write
      // echoes the code back in `joinedWithCode` and the rules compare it with
      // the household's current one. A refused write and a wrong code are the
      // same event from here, which is why both surface as "no such code".
      try {
        await _memberDocument(householdId, user.id).set({
          ..._memberOf(
            user: user,
            displayName: memberName,
            role: MemberRole.member,
            joinedAt: _clock.now().toUtc(),
          ).toMap(),
          'joinedWithCode': inviteCode.value,
        });
      } on FirebaseException catch (error) {
        if (error.code == 'permission-denied') {
          return const Err(_noSuchCode);
        }
        rethrow;
      }

      final document = await _firestore
          .collection(householdsPath)
          .doc(householdId)
          .get();
      final data = document.data();
      if (data == null) return const Err(_noSuchCode);
      return Ok(Household.fromMap(data));
    });
  }

  @override
  Stream<Household?> watchHousehold(String householdId) => _domainErrors(
    () =>
        _firestore.collection(householdsPath).doc(householdId).snapshots().map((
          snapshot,
        ) {
          final data = snapshot.data();
          return data == null ? null : Household.fromMap(data);
        }),
  );

  @override
  Stream<List<Member>> watchMembers(String householdId) => _domainErrors(
    () => _firestore
        .collection(householdsPath)
        .doc(householdId)
        .collection(membersPath)
        .orderBy('joinedAt')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Member.fromMap(doc.data())).toList(),
        ),
  );

  /// Claims an unused document in the invite code index.
  ///
  /// Returns null when every attempt collided. The read and the write are in
  /// one transaction because the index is what makes codes unique: a plain
  /// `set` would overwrite somebody else's reservation.
  Future<InviteCode?> _reserveInviteCode({
    required String householdId,
    required String createdBy,
    required DateTime now,
  }) async {
    for (var attempt = 0; attempt < maxCodeAttempts; attempt++) {
      final code = InviteCode.generate(_random);
      final document = _firestore.collection(inviteCodesPath).doc(code.value);
      final reserved = await _firestore.runTransaction<bool>((
        transaction,
      ) async {
        final snapshot = await transaction.get(document);
        if (snapshot.exists) return false;
        transaction.set(document, {
          'householdId': householdId,
          'createdBy': createdBy,
          'createdAt': now.millisecondsSinceEpoch,
        });
        return true;
      });
      if (reserved) return code;
    }
    return null;
  }

  Member _memberOf({
    required AuthUser user,
    required String displayName,
    required MemberRole role,
    required DateTime joinedAt,
  }) => Member(
    id: user.id,
    displayName: displayName,
    email: user.email,
    role: role,
    joinedAt: joinedAt,
    photoUrl: user.photoUrl,
  );

  DocumentReference<Map<String, dynamic>> _memberDocument(
    String householdId,
    String uid,
  ) => _firestore
      .collection(householdsPath)
      .doc(householdId)
      .collection(membersPath)
      .doc(uid);

  static const _noSuchCode = NotFoundFailure(
    'That invite code does not match a household.',
  );

  /// Runs [body], turning anything Firestore throws into a [Failure].
  static Future<Result<T>> _guard<T>(Future<Result<T>> Function() body) async {
    try {
      return await body();
    } on Object catch (error) {
      return Err(_failureFrom(error));
    }
  }

  /// Re-emits the stream [source] builds, mapping Firestore errors onto domain
  /// failures so a listener never has to catch a `FirebaseException`.
  ///
  /// [source] is a callback rather than a stream because opening a query can
  /// throw before there is a stream to attach a handler to.
  static Stream<T> _domainErrors<T>(Stream<T> Function() source) {
    final Stream<T> stream;
    try {
      stream = source();
    } on Object catch (error, stackTrace) {
      return Stream.error(_failureFrom(error), stackTrace);
    }
    return stream.transform(
      StreamTransformer<T, T>.fromHandlers(
        handleError: (error, stackTrace, sink) =>
            sink.addError(_failureFrom(error), stackTrace),
      ),
    );
  }

  /// Maps anything thrown by a call or emitted as a stream error onto the
  /// domain failure that describes it.
  ///
  /// A document that will not parse arrives here too, as whatever `fromMap`
  /// threw, and is reported as unknown rather than pretending to be a
  /// backend error.
  static Failure _failureFrom(Object error) {
    if (error is! FirebaseException) {
      return UnknownFailure('Firestore call failed.', cause: error);
    }
    final message = error.message ?? error.code;
    return switch (error.code) {
      'permission-denied' => PermissionFailure(message),
      'not-found' => NotFoundFailure(message),
      'already-exists' => ConflictFailure(message),
      'unavailable' ||
      'deadline-exceeded' ||
      'aborted' ||
      'cancelled' => NetworkFailure(message),
      _ => UnknownFailure(message, cause: error),
    };
  }
}
