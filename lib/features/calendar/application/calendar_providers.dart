import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderFamily;
import 'package:kith/data/services/calendar_directory.dart';
import 'package:kith/data/services/calendar_sink.dart';
import 'package:kith/features/calendar/application/calendar_sync_service.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';

/// The app's [CalendarSink].
///
/// Deliberately has no default: the composition root overrides it with the
/// Google implementation and tests override it with a fake, so reading it
/// unoverridden throws rather than quietly writing nowhere.
final calendarSinkProvider = Provider<CalendarSink>((ref) {
  throw UnimplementedError(
    'calendarSinkProvider must be overridden with a CalendarSink '
    'implementation before it is read.',
  );
});

/// The app's [CalendarDirectory]. Overridden the same way as the sink.
final calendarDirectoryProvider = Provider<CalendarDirectory>((ref) {
  throw UnimplementedError(
    'calendarDirectoryProvider must be overridden with a CalendarDirectory '
    'implementation before it is read.',
  );
});

/// Keeps plans and their calendar events in step.
///
/// Built here rather than in the composition root because it is orchestration
/// over two seams that are themselves bound there, and nothing about it is
/// Firebase's or Google's.
final calendarSyncServiceProvider = Provider<CalendarSyncService>(
  (ref) => CalendarSyncService(
    sink: ref.watch(calendarSinkProvider),
    plans: ref.watch(plannedHangoutRepositoryProvider),
  ),
);

/// The calendar the given household writes its plans to, or null when none is
/// linked or the household has not loaded yet.
///
/// Derived from the household document rather than held separately: the link
/// is a property of the household, and both partners see the same one the
/// moment either of them changes it.
final ProviderFamily<String?, String> householdCalendarIdProvider =
    Provider.family<String?, String>(
      (ref, householdId) =>
          ref.watch(householdProvider(householdId)).value?.calendarId,
    );
