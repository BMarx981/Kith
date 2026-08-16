import 'package:flutter/foundation.dart';
import 'package:kith/data/models/member_role.dart';

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
  };

  /// Returns a copy with the given fields replaced.
  Member copyWith({
    String? id,
    String? displayName,
    String? email,
    MemberRole? role,
    DateTime? joinedAt,
    String? photoUrl,
    bool clearPhotoUrl = false,
  }) => Member(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    role: role ?? this.role,
    joinedAt: joinedAt ?? this.joinedAt,
    photoUrl: clearPhotoUrl ? null : photoUrl ?? this.photoUrl,
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
          other.photoUrl == photoUrl;

  @override
  int get hashCode =>
      Object.hash(id, displayName, email, role, joinedAt, photoUrl);

  @override
  String toString() =>
      'Member(id: $id, displayName: $displayName, email: $email, '
      'role: ${role.wireName}, joinedAt: $joinedAt, photoUrl: $photoUrl)';
}
