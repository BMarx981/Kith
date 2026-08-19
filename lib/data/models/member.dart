import 'package:flutter/foundation.dart';
import 'package:kith/data/models/member_role.dart';
import 'package:kith/features/notifications/domain/digest_schedule.dart';

/// An authenticated adult belonging to a household.
///
/// Stored at `households/{hid}/members/{uid}`; [id] is the Firebase Auth uid.
@immutable
class Member {
  const Member({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.photoUrl,
    this.digestDay,
    this.digestHour = DigestSchedule.defaultHour,
  });

  /// Rebuilds a member from its Firestore document data.
  factory Member.fromMap(Map<String, dynamic> map) => Member(
    id: map['id'] as String,
    displayName: map['displayName'] as String,
    email: map['email'] as String,
    role: MemberRole.fromWireName(map['role'] as String?),
    joinedAt: DateTime.fromMillisecondsSinceEpoch(
      map['joinedAt'] as int,
      isUtc: true,
    ),
    photoUrl: map['photoUrl'] as String?,
    digestDay: _readDigestDay(map['digestDay']),
    digestHour: _readDigestHour(map['digestHour']),
  );

  /// Firebase Auth uid.
  final String id;

  /// Name shown next to hangouts this member logged.
  final String displayName;

  /// Sign-in address.
  final String email;

  /// Authority within the household.
  final MemberRole role;

  /// When this member joined, in UTC.
  final DateTime joinedAt;

  /// Optional avatar from the auth provider.
  final String? photoUrl;

  /// Which day this member wants the weekly digest on, Monday being 1, or
  /// null when they do not want one.
  ///
  /// Null rather than a separate on/off flag: "off" and "no day chosen" are
  /// the same state, and two fields that could disagree about it would be one
  /// bug waiting to happen.
  ///
  /// A member preference rather than a household one, and stored rather than
  /// kept on the device, because it is personal — one partner may want the
  /// nudge and the other may not — and because a member who signs in on a
  /// second phone should get the digest there too.
  final int? digestDay;

  /// The hour of [digestDay] the digest arrives, 0–23. Meaningless while
  /// [digestDay] is null, and kept anyway so turning the digest off and on
  /// again does not lose the time they picked.
  final int digestHour;

  /// Whether this member wants the weekly digest at all.
  bool get wantsDigest => digestDay != null;

  /// Serialises to Firestore document data.
  ///
  /// Timestamps are written as epoch milliseconds rather than Firestore
  /// `Timestamp`s so that models stay free of Firestore types while remaining
  /// sortable and range-queryable server-side.
  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'email': email,
    'role': role.wireName,
    'joinedAt': joinedAt.toUtc().millisecondsSinceEpoch,
    'photoUrl': photoUrl,
    'digestDay': digestDay,
    'digestHour': digestHour,
  };

  /// Returns a copy with the given fields replaced.
  Member copyWith({
    String? id,
    String? displayName,
    String? email,
    MemberRole? role,
    DateTime? joinedAt,
    String? photoUrl,
    int? digestDay,
    int? digestHour,
    bool clearPhotoUrl = false,
    bool clearDigestDay = false,
  }) => Member(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    role: role ?? this.role,
    joinedAt: joinedAt ?? this.joinedAt,
    photoUrl: clearPhotoUrl ? null : photoUrl ?? this.photoUrl,
    digestDay: clearDigestDay ? null : digestDay ?? this.digestDay,
    digestHour: digestHour ?? this.digestHour,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Member &&
          other.id == id &&
          other.displayName == displayName &&
          other.email == email &&
          other.role == role &&
          other.joinedAt == joinedAt &&
          other.photoUrl == photoUrl &&
          other.digestDay == digestDay &&
          other.digestHour == digestHour;

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    email,
    role,
    joinedAt,
    photoUrl,
    digestDay,
    digestHour,
  );

  @override
  String toString() =>
      'Member(id: $id, displayName: $displayName, email: $email, '
      'role: ${role.wireName}, joinedAt: $joinedAt, photoUrl: $photoUrl, '
      'digestDay: $digestDay, digestHour: $digestHour)';

  /// Reads a stored digest day, answering null for anything that is not a
  /// weekday. Tolerant on the way in, like every other `fromMap`: a member
  /// document written before M6 has no digest field at all, and reads as
  /// somebody who has not asked for one.
  static int? _readDigestDay(Object? value) =>
      value is int && value >= DateTime.monday && value <= DateTime.sunday
      ? value
      : null;

  /// Reads a stored digest hour, falling back to the default for a missing or
  /// out-of-range one.
  static int _readDigestHour(Object? value) =>
      value is int && value >= DigestSchedule.minHour &&
          value <= DigestSchedule.maxHour
      ? value
      : DigestSchedule.defaultHour;
}
