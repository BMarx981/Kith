import 'package:flutter/foundation.dart';
import 'package:kith/core/time/calendar_day.dart';

/// A meetup that happened: who you saw, when, and who from the house was
/// there.
///
/// Stored at `households/{hid}/hangouts/{hgid}`. One hangout can name several
/// contacts, because seeing three people at the same barbecue is one event
/// and logging it three times would be three times the work for the same
/// truth. Every contact named is treated as seen on [occurredOn], which is
/// what the freshness maths reads.
@immutable
class Hangout {
  Hangout({
    required this.id,
    required DateTime occurredOn,
    required List<String> contactIds,
    required List<String> attendeeIds,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  }) : occurredOn = CalendarDay.of(occurredOn),
       contactIds = List.unmodifiable(contactIds),
       attendeeIds = List.unmodifiable(attendeeIds);

  /// Rebuilds a hangout from its Firestore document data.
  ///
  /// Tolerant where a missing value has an obvious reading — no note, nobody
  /// from the house recorded as present — because one odd document should not
  /// take the whole timeline down with it.
  factory Hangout.fromMap(Map<String, dynamic> map) => Hangout(
    id: map['id'] as String,
    occurredOn: DateTime.fromMillisecondsSinceEpoch(
      map['occurredOn'] as int,
      isUtc: true,
    ),
    contactIds: (map['contactIds'] as List<dynamic>? ?? const [])
        .cast<String>(),
    attendeeIds: (map['attendeeIds'] as List<dynamic>? ?? const [])
        .cast<String>(),
    createdBy: map['createdBy'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      map['createdAt'] as int,
      isUtc: true,
    ),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      map['updatedAt'] as int,
      isUtc: true,
    ),
    note: map['note'] as String?,
  );

  /// Firestore document id.
  final String id;

  /// The calendar day it happened on, as midnight UTC.
  ///
  /// A day rather than an instant: nobody logs the minute they met, and a
  /// floating date is what survives the household being in two timezones.
  /// Normalised by the constructor, so this is always midnight UTC however it
  /// was passed in. See [CalendarDay].
  final DateTime occurredOn;

  /// Ids of the contacts who were seen. Unmodifiable, never empty for a
  /// hangout that came through the repository.
  final List<String> contactIds;

  /// Ids of the household members who were there.
  ///
  /// Separate from [createdBy]: one partner logs the hangout the other went
  /// to often enough that conflating the two would misreport both.
  final List<String> attendeeIds;

  /// Uid of the member who logged it. Never changes, even after an edit.
  final String createdBy;

  /// When it was logged, in UTC. Distinct from [occurredOn]: you can log
  /// last Tuesday's coffee on Friday.
  final DateTime createdAt;

  /// When the entry was last edited, in UTC. Equal to [createdAt] until the
  /// first edit.
  final DateTime updatedAt;

  /// What happened, in one line. Optional, and the field most often left
  /// empty in a ten-second log.
  final String? note;

  /// Most contacts one hangout may name. Mirrors the bound in
  /// `firestore.rules`.
  static const maxContacts = 50;

  /// Most household members one hangout may record as present.
  static const maxAttendees = 20;

  /// Longest [note] may be.
  static const maxNoteLength = 2000;

  /// Serialises to Firestore document data.
  ///
  /// [occurredOn] is written straight rather than through `toUtc()`, because
  /// the constructor has already made it midnight UTC and shifting it again
  /// would be a second conversion of an already-converted value.
  Map<String, dynamic> toMap() => {
    'id': id,
    'occurredOn': occurredOn.millisecondsSinceEpoch,
    'contactIds': contactIds,
    'attendeeIds': attendeeIds,
    'createdBy': createdBy,
    'createdAt': createdAt.toUtc().millisecondsSinceEpoch,
    'updatedAt': updatedAt.toUtc().millisecondsSinceEpoch,
    'note': note,
  };

  /// Whether this hangout says [contactId] was seen.
  bool includes(String contactId) => contactIds.contains(contactId);

  /// Returns a copy with the given fields replaced.
  ///
  /// [note] has a `clear` flag, because passing null to a named parameter
  /// cannot be told apart from omitting it.
  Hangout copyWith({
    String? id,
    DateTime? occurredOn,
    List<String>? contactIds,
    List<String>? attendeeIds,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
    bool clearNote = false,
  }) => Hangout(
    id: id ?? this.id,
    occurredOn: occurredOn ?? this.occurredOn,
    contactIds: contactIds ?? this.contactIds,
    attendeeIds: attendeeIds ?? this.attendeeIds,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    note: clearNote ? null : note ?? this.note,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hangout &&
          other.id == id &&
          other.occurredOn == occurredOn &&
          listEquals(other.contactIds, contactIds) &&
          listEquals(other.attendeeIds, attendeeIds) &&
          other.createdBy == createdBy &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.note == note;

  @override
  int get hashCode => Object.hash(
    id,
    occurredOn,
    Object.hashAll(contactIds),
    Object.hashAll(attendeeIds),
    createdBy,
    createdAt,
    updatedAt,
    note,
  );

  @override
  String toString() =>
      'Hangout(id: $id, occurredOn: $occurredOn, '
      'contactIds: $contactIds, attendeeIds: $attendeeIds, '
      'createdBy: $createdBy, createdAt: $createdAt, '
      'updatedAt: $updatedAt, note: $note)';
}
