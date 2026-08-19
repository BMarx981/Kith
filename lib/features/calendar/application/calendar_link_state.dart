import 'package:flutter/foundation.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/services/calendar_directory.dart';

/// What the calendar settings screen knows.
///
/// [isAuthorised] is about this member's Google grant, not about the
/// household: the link is shared, but the permission to read and write it is
/// per person, so a partner who has never granted it sees the connect step
/// even though a calendar is already linked.
@immutable
class CalendarLinkState {
  const CalendarLinkState({
    this.isBusy = false,
    this.isAuthorised = false,
    this.calendars = const [],
    this.failure,
  });

  /// Whether a request is in flight; the screen is inert while it is.
  final bool isBusy;

  /// Whether this member has granted Kith the calendar scopes.
  final bool isAuthorised;

  /// The calendars this member could link, primary first. Empty until they
  /// have been read.
  final List<CalendarListing> calendars;

  /// Why the last attempt was refused, or null if none was.
  final Failure? failure;

  /// Returns a copy with the given fields replaced.
  ///
  /// The `clear` flag exists because passing null to a named parameter cannot
  /// be told apart from omitting it.
  CalendarLinkState copyWith({
    bool? isBusy,
    bool? isAuthorised,
    List<CalendarListing>? calendars,
    Failure? failure,
    bool clearFailure = false,
  }) => CalendarLinkState(
    isBusy: isBusy ?? this.isBusy,
    isAuthorised: isAuthorised ?? this.isAuthorised,
    calendars: calendars ?? this.calendars,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarLinkState &&
          other.isBusy == isBusy &&
          other.isAuthorised == isAuthorised &&
          listEquals(other.calendars, calendars) &&
          other.failure == failure;

  @override
  int get hashCode =>
      Object.hash(isBusy, isAuthorised, Object.hashAll(calendars), failure);

  @override
  String toString() =>
      'CalendarLinkState(isBusy: $isBusy, isAuthorised: $isAuthorised, '
      'calendars: ${calendars.length}, failure: $failure)';
}
