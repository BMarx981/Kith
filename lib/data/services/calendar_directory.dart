import 'package:flutter/foundation.dart';
import 'package:kith/core/result/result.dart';

/// One calendar the signed-in Google account can write to.
///
/// Thin on purpose: the picker needs something to show and something to
/// store, and everything else about a calendar belongs to whoever owns it.
@immutable
class CalendarListing {
  const CalendarListing({
    required this.id,
    required this.name,
    this.isPrimary = false,
  });

  /// The provider's id for the calendar, which for Google is an address.
  /// What a `Household.calendarId` holds.
  final String id;

  /// What the account calls this calendar.
  final String name;

  /// Whether this is the account's own default calendar.
  ///
  /// Worth telling apart: a household's plans usually belong on a calendar
  /// the frame subscribes to, not on one partner's personal one.
  final bool isPrimary;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarListing &&
          other.id == id &&
          other.name == name &&
          other.isPrimary == isPrimary;

  @override
  int get hashCode => Object.hash(id, name, isPrimary);

  @override
  String toString() =>
      'CalendarListing(id: $id, name: $name, isPrimary: $isPrimary)';
}

/// The calendars a household could link, as the signed-in account sees them.
///
/// Separate from `CalendarSink` because it answers a different question:
/// the sink writes to a calendar the household has already chosen, and this
/// is what lets them choose one. Kith never creates a calendar — the
/// household already runs the one their frame reads, so linking is the whole
/// flow. See `docs/PLAN.md` §7.
///
/// Implementations translate transport and API errors into domain failures
/// before returning; nothing above this interface sees an HTTP status.
abstract interface class CalendarDirectory {
  /// Every calendar the account may write events to, primary first.
  ///
  /// Read-only subscriptions are left out rather than shown and refused
  /// later: a calendar Kith cannot write to is not one a household can link.
  Future<Result<List<CalendarListing>>> listCalendars();
}
