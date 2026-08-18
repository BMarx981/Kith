import 'package:flutter/foundation.dart';
import 'package:kith/core/time/calendar_day.dart';
import 'package:kith/data/models/planned_hangout_status.dart';

/// An intent about a meetup that has not happened yet.
///
/// Stored at `households/{hid}/plannedHangouts/{pid}`. It is what the
/// Reconnect section writes when you act on a suggestion: "Plan it" records a
/// day you mean to see someone, and "not now" records a day to stop asking
/// until. Both are a future intent with a date and a status, which is the
/// entity `docs/PLAN.md` describes, so they are one document shape rather than
/// two.
///
/// Unlike a `Hangout` this is not history: it says nothing about whether
/// anyone was seen, and the freshness maths never reads it. Only the
/// suggestion engine does.
@immutable
class PlannedHangout {
  PlannedHangout({
    required this.id,
    required DateTime plannedFor,
    required List<String> contactIds,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.calendarEventId,
  }) : plannedFor = CalendarDay.of(plannedFor),
       contactIds = List.unmodifiable(contactIds);

  /// Rebuilds a plan from its Firestore document data.
  ///
  /// Tolerant where a missing value has an obvious reading — no note, no
  /// calendar event, an unrecognised status — because one odd document should
  /// not take the whole Reconnect section down with it.
  factory PlannedHangout.fromMap(Map<String, dynamic> map) => PlannedHangout(
    id: map['id'] as String,
    plannedFor: DateTime.fromMillisecondsSinceEpoch(
      map['plannedFor'] as int,
      isUtc: true,
    ),
    contactIds: (map['contactIds'] as List<dynamic>? ?? const [])
        .cast<String>(),
    status: PlannedHangoutStatus.fromWireName(map['status'] as String?),
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
    calendarEventId: map['calendarEventId'] as String?,
  );

  /// Firestore document id.
  final String id;

  /// The calendar day the plan is about, as midnight UTC.
  ///
  /// For an arranged plan it is the day you mean to meet. For a snooze it is
  /// the day the contact becomes suggestible again. A day rather than an
  /// instant, for the same reason a hangout's day is one: nobody plans
  /// the minute, and a floating date survives the household being in two
  /// timezones. Normalised by the constructor. See [CalendarDay].
  final DateTime plannedFor;

  /// Ids of the contacts the plan is about. Unmodifiable, never empty for a
  /// plan that came through the repository.
  final List<String> contactIds;

  /// Whether the meetup is arranged, on the calendar, or simply deferred.
  final PlannedHangoutStatus status;

  /// Uid of the member who made the plan. Never changes.
  final String createdBy;

  /// When the plan was made, in UTC.
  final DateTime createdAt;

  /// When the plan was last changed, in UTC. Equal to [createdAt] until the
  /// first change.
  final DateTime updatedAt;

  /// What the plan is, in one line. Optional, and usually empty.
  final String? note;

  /// Id of the calendar event this plan owns, once it has one.
  ///
  /// Null until the plan is confirmed onto the household's calendar, which is
  /// M5's job; the field is here because it is part of the entity and adding
  /// it later would mean migrating documents and rules for a value the model
  /// already round-trips.
  final String? calendarEventId;

  /// Most contacts one plan may name. Mirrors `Hangout.maxContacts` and the
  /// bound in `firestore.rules`.
  static const maxContacts = 50;

  /// Longest [note] may be.
  static const maxNoteLength = 2000;

  /// Longest a calendar event id may be.
  static const maxCalendarEventIdLength = 1024;

  /// Serialises to Firestore document data.
  ///
  /// [plannedFor] is written straight rather than through `toUtc()`, because
  /// the constructor has already made it midnight UTC and shifting it again
  /// would be a second conversion of an already-converted value.
  Map<String, dynamic> toMap() => {
    'id': id,
    'plannedFor': plannedFor.millisecondsSinceEpoch,
    'contactIds': contactIds,
    'status': status.wireName,
    'createdBy': createdBy,
    'createdAt': createdAt.toUtc().millisecondsSinceEpoch,
    'updatedAt': updatedAt.toUtc().millisecondsSinceEpoch,
    'note': note,
    'calendarEventId': calendarEventId,
  };

  /// Whether this plan is about [contactId].
  bool includes(String contactId) => contactIds.contains(contactId);

  /// Whether this plan still has anything to say as of [now].
  ///
  /// A plan runs out at the end of the day it names: an arranged meetup whose
  /// day has gone by either happened, in which case a hangout has reset the
  /// gauge, or it did not, in which case the contact belongs back in the
  /// suggestions rather than damped by an arrangement nobody kept. A snooze
  /// ends the same way, on the day it was set to end.
  bool isActiveOn(DateTime now) => !plannedFor.isBefore(CalendarDay.of(now));

  /// Returns a copy with the given fields replaced.
  ///
  /// The optional fields have `clear` flags, because passing null to a named
  /// parameter cannot be told apart from omitting it.
  PlannedHangout copyWith({
    String? id,
    DateTime? plannedFor,
    List<String>? contactIds,
    PlannedHangoutStatus? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
    String? calendarEventId,
    bool clearNote = false,
    bool clearCalendarEventId = false,
  }) => PlannedHangout(
    id: id ?? this.id,
    plannedFor: plannedFor ?? this.plannedFor,
    contactIds: contactIds ?? this.contactIds,
    status: status ?? this.status,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    note: clearNote ? null : note ?? this.note,
    calendarEventId: clearCalendarEventId
        ? null
        : calendarEventId ?? this.calendarEventId,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlannedHangout &&
          other.id == id &&
          other.plannedFor == plannedFor &&
          listEquals(other.contactIds, contactIds) &&
          other.status == status &&
          other.createdBy == createdBy &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.note == note &&
          other.calendarEventId == calendarEventId;

  @override
  int get hashCode => Object.hash(
    id,
    plannedFor,
    Object.hashAll(contactIds),
    status,
    createdBy,
    createdAt,
    updatedAt,
    note,
    calendarEventId,
  );

  @override
  String toString() =>
      'PlannedHangout(id: $id, plannedFor: $plannedFor, '
      'contactIds: $contactIds, status: ${status.wireName}, '
      'createdBy: $createdBy, createdAt: $createdAt, '
      'updatedAt: $updatedAt, note: $note, '
      'calendarEventId: $calendarEventId)';
}
