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
    this.calendarId,
    this.calendarName,
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
    calendarId: map['calendarId'] as String?,
    calendarName: map['calendarName'] as String?,
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

  /// Id of the Google Calendar this household's plans are written to, or null
  /// while no calendar is linked.
  ///
  /// A property of the household rather than of the member who linked it: the
  /// frame subscribes to one calendar, and both partners' plans belong on it.
  /// The OAuth grant behind it is per-member and never stored — each member
  /// authorises their own Google account, and a member without access to this
  /// calendar finds out when a write is refused.
  final String? calendarId;

  /// What that calendar is called, as its owner named it.
  ///
  /// Kept alongside the id so the settings screen can say "Family" rather than
  /// an address nobody chose. A copy taken at link time: renaming the calendar
  /// in Google does not reach back here, and nothing depends on it matching.
  final String? calendarName;

  /// Longest a linked calendar id may be.
  static const maxCalendarIdLength = 1024;

  /// Longest a linked calendar name may be.
  static const maxCalendarNameLength = 200;

  /// Whether plans made in this household go onto a calendar.
  bool get hasCalendar => calendarId != null;

  /// Serialises to Firestore document data.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'inviteCode': inviteCode?.value,
    'createdAt': createdAt.toUtc().millisecondsSinceEpoch,
    'createdBy': createdBy,
    'calendarId': calendarId,
    'calendarName': calendarName,
  };

  /// Returns a copy with the given fields replaced.
  Household copyWith({
    String? id,
    String? name,
    InviteCode? inviteCode,
    DateTime? createdAt,
    String? createdBy,
    String? calendarId,
    String? calendarName,
    bool clearInviteCode = false,
    bool clearCalendar = false,
  }) => Household(
    id: id ?? this.id,
    name: name ?? this.name,
    inviteCode: clearInviteCode ? null : inviteCode ?? this.inviteCode,
    createdAt: createdAt ?? this.createdAt,
    createdBy: createdBy ?? this.createdBy,
    // One flag for both, because a link is one thing: a calendar id with no
    // name, or a name pointing at nothing, is not a state the app has.
    calendarId: clearCalendar ? null : calendarId ?? this.calendarId,
    calendarName: clearCalendar ? null : calendarName ?? this.calendarName,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Household &&
          other.id == id &&
          other.name == name &&
          other.inviteCode == inviteCode &&
          other.createdAt == createdAt &&
          other.createdBy == createdBy &&
          other.calendarId == calendarId &&
          other.calendarName == calendarName;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    inviteCode,
    createdAt,
    createdBy,
    calendarId,
    calendarName,
  );

  @override
  String toString() =>
      'Household(id: $id, name: $name, inviteCode: ${inviteCode?.value}, '
      'createdAt: $createdAt, createdBy: $createdBy, '
      'calendarId: $calendarId, calendarName: $calendarName)';
}
