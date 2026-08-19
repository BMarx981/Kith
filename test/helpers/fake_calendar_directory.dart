import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/services/calendar_directory.dart';

/// An in-memory [CalendarDirectory] standing in for a Google account's
/// calendar list.
class FakeCalendarDirectory implements CalendarDirectory {
  /// What the account subscribes to, in the order the picker will show them.
  List<CalendarListing> calendars = const [];

  /// Failure returned instead of the list, when set.
  Failure? failure;

  /// Number of [listCalendars] calls.
  int listCalls = 0;

  @override
  Future<Result<List<CalendarListing>>> listCalendars() async {
    listCalls++;
    final refused = failure;
    return refused == null ? Ok(calendars) : Err(refused);
  }
}
