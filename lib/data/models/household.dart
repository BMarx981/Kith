import 'package:flutter/foundation.dart';
import 'package:kith/features/household/domain/invite_code.dart';

/// The shared container every other entity is scoped to.
///
/// Stored at `households/{hid}`. Contacts, hangouts and relationship types all
/// live in subcollections beneath it; nothing user-owned sits at the top level.
@immutable
class Household {
  const Household({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.createdAt,
    required this.createdBy,
  });

  /// Rebuilds a household from its Firestore document data.
  ///
  /// An invite code that no longer parses is surfaced as null rather than
  /// throwing, so one bad document cannot break the household list.
  factory Household.fromMap(Map<String, dynamic> map) => Household(
    id: map['id'] as String,
    name: map['name'] as String,
    inviteCode: InviteCode.parse(
      map['inviteCode'] as String? ?? '',
    ).valueOrNull,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      map['createdAt'] as int,
      isUtc: true,
    ),
    createdBy: map['createdBy'] as String,
  );

  /// Firestore document id.
  final String id;

  /// Display name, e.g. "The Marx house".
  final String name;

  /// Current join code. Null only if a stored code failed to parse.
  final InviteCode? inviteCode;

  /// When the household was created, in UTC.
  final DateTime createdAt;

  /// Uid of the member who created it, who starts as the owner.
  final String createdBy;

  /// Serialises to Firestore document data.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'inviteCode': inviteCode?.value,
    'createdAt': createdAt.toUtc().millisecondsSinceEpoch,
    'createdBy': createdBy,
  };

  /// Returns a copy with the given fields replaced.
  Household copyWith({
    String? id,
    String? name,
    InviteCode? inviteCode,
    DateTime? createdAt,
    String? createdBy,
    bool clearInviteCode = false,
  }) => Household(
    id: id ?? this.id,
    name: name ?? this.name,
    inviteCode: clearInviteCode ? null : inviteCode ?? this.inviteCode,
    createdAt: createdAt ?? this.createdAt,
    createdBy: createdBy ?? this.createdBy,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Household &&
          other.id == id &&
          other.name == name &&
          other.inviteCode == inviteCode &&
          other.createdAt == createdAt &&
          other.createdBy == createdBy;

  @override
  int get hashCode => Object.hash(id, name, inviteCode, createdAt, createdBy);

  @override
  String toString() =>
      'Household(id: $id, name: $name, inviteCode: ${inviteCode?.value}, '
      'createdAt: $createdAt, createdBy: $createdBy)';
}
