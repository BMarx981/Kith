import 'package:flutter/foundation.dart';
import 'package:kith/core/time/calendar_day.dart';
import 'package:kith/data/models/hangout.dart';

/// The editable half of a [Hangout]: everything the quick-log form collects.
///
/// A hangout's id, its author and its timestamps belong to whoever stores it,
/// so the form never has to invent them and logging and editing take the same
/// shape.
@immutable
class HangoutDraft {
  HangoutDraft({
    required DateTime occurredOn,
    required List<String> contactIds,
    List<String> attendeeIds = const [],
    this.note,
  }) : occurredOn = CalendarDay.of(occurredOn),
       contactIds = List.unmodifiable(contactIds),
       attendeeIds = List.unmodifiable(attendeeIds);

  /// The draft that reproduces [hangout], for opening it in the form.
  factory HangoutDraft.from(Hangout hangout) => HangoutDraft(
    occurredOn: hangout.occurredOn,
    contactIds: hangout.contactIds,
    attendeeIds: hangout.attendeeIds,
    note: hangout.note,
  );

  /// The calendar day it happened on, normalised to midnight UTC.
  final DateTime occurredOn;

  /// Ids of the contacts who were seen.
  final List<String> contactIds;

  /// Ids of the household members who were there.
  final List<String> attendeeIds;

  /// What happened, in one line.
  final String? note;

  /// The same draft with whitespace taken off, blanks read as absent and each
  /// id named once.
  ///
  /// Run before validation and before storing, so a note someone cleared to a
  /// space is stored as null rather than as " ", and so tapping a contact
  /// twice cannot record them twice.
  HangoutDraft normalised() {
    final note = this.note?.trim() ?? '';
    return HangoutDraft(
      occurredOn: occurredOn,
      contactIds: _distinct(contactIds),
      attendeeIds: _distinct(attendeeIds),
      note: note.isEmpty ? null : note,
    );
  }

  /// Builds the stored hangout this draft describes.
  ///
  /// The timestamps are supplied rather than read from a clock here, so the
  /// repository stays the one place that decides what "now" is for a write.
  Hangout toHangout({
    required String id,
    required String createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) => Hangout(
    id: id,
    occurredOn: occurredOn,
    contactIds: contactIds,
    attendeeIds: attendeeIds,
    createdBy: createdBy,
    createdAt: createdAt,
    updatedAt: updatedAt,
    note: note,
  );

  /// Returns a copy with the given fields replaced.
  HangoutDraft copyWith({
    DateTime? occurredOn,
    List<String>? contactIds,
    List<String>? attendeeIds,
    String? note,
    bool clearNote = false,
  }) => HangoutDraft(
    occurredOn: occurredOn ?? this.occurredOn,
    contactIds: contactIds ?? this.contactIds,
    attendeeIds: attendeeIds ?? this.attendeeIds,
    note: clearNote ? null : note ?? this.note,
  );

  /// [ids] with the blanks dropped and the first of any repeat kept, so the
  /// order the user tapped survives.
  static List<String> _distinct(List<String> ids) {
    final seen = <String>{};
    return [
      for (final id in ids)
        if (id.trim().isNotEmpty && seen.add(id.trim())) id.trim(),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HangoutDraft &&
          other.occurredOn == occurredOn &&
          listEquals(other.contactIds, contactIds) &&
          listEquals(other.attendeeIds, attendeeIds) &&
          other.note == note;

  @override
  int get hashCode => Object.hash(
    occurredOn,
    Object.hashAll(contactIds),
    Object.hashAll(attendeeIds),
    note,
  );

  @override
  String toString() =>
      'HangoutDraft(occurredOn: $occurredOn, contactIds: $contactIds, '
      'attendeeIds: $attendeeIds, note: $note)';
}
