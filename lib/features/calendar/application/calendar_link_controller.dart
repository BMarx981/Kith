import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/services/calendar_directory.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/calendar/application/calendar_link_state.dart';
import 'package:kith/features/calendar/application/calendar_providers.dart';
import 'package:kith/features/calendar/domain/calendar_scopes.dart';
import 'package:kith/features/household/application/household_providers.dart';

/// Drives linking a household to one of the account's Google Calendars.
///
/// Two steps, kept apart on purpose. Granting Kith access to a Google account
/// is this member's decision and shows a sheet; choosing which calendar the
/// household writes to is a household decision and is stored on the household
/// document. A member can do the first without the second.
class CalendarLinkController extends Notifier<CalendarLinkState> {
  @override
  CalendarLinkState build() {
    // Watched, not read on demand: the grant belongs to the signed-in account,
    // so signing in as somebody else has to start the screen over rather than
    // leave the previous member's calendars listed.
    ref.watch(currentUserProvider);
    return const CalendarLinkState();
  }

  /// Lists the calendars this member has already let Kith see.
  ///
  /// Shows nothing and asks for nothing when the scopes were never granted:
  /// opening a settings screen is not consent, so the sheet waits for
  /// [connect].
  Future<void> load() async {
    if (state.isBusy) return;
    state = state.copyWith(isBusy: true, clearFailure: true);

    final token = await ref
        .read(googleSignInServiceProvider)
        .existingAccessToken(CalendarScopes.all);
    if (token == null) {
      state = const CalendarLinkState();
      return;
    }
    await _listCalendars();
  }

  /// Asks this member to grant the calendar scopes, then lists what they have.
  ///
  /// A dismissed sheet leaves the screen exactly as it was: the member closed
  /// it deliberately, and an error telling them they cancelled only reports
  /// back what they just did.
  Future<void> connect() async {
    if (state.isBusy) return;
    state = state.copyWith(isBusy: true, clearFailure: true);

    final granted = await ref
        .read(googleSignInServiceProvider)
        .authorizeScopes(CalendarScopes.all);
    if (granted case Err(:final failure)) {
      state = _wasCancelled(failure)
          ? state.copyWith(isBusy: false, clearFailure: true)
          : state.copyWith(isBusy: false, failure: failure);
      return;
    }
    await _listCalendars();
  }

  /// Points [householdId] at [calendar]. Answers whether it worked.
  Future<bool> link({
    required String householdId,
    required CalendarListing calendar,
  }) => _write(
    () => ref
        .read(householdRepositoryProvider)
        .linkCalendar(
          householdId: householdId,
          calendarId: calendar.id,
          calendarName: calendar.name,
        ),
  );

  /// Stops writing [householdId]'s plans to a calendar. Answers whether it
  /// worked.
  Future<bool> unlink({required String householdId}) => _write(
    () => ref
        .read(householdRepositoryProvider)
        .unlinkCalendar(householdId: householdId),
  );

  /// Reads the account's calendars into the state, keeping the grant.
  Future<void> _listCalendars() async {
    final listed = await ref.read(calendarDirectoryProvider).listCalendars();
    state = switch (listed) {
      Ok(:final value) => state.copyWith(
        isBusy: false,
        isAuthorised: true,
        calendars: value,
        clearFailure: true,
      ),
      // A refused read means the grant is not what it looked like — lapsed, or
      // never covering both scopes — so the screen goes back to offering it.
      Err(:final failure) => CalendarLinkState(failure: failure),
    };
  }

  /// Runs [write], holding the screen inert until it settles so a double tap
  /// cannot link twice.
  Future<bool> _write(Future<Result<void>> Function() write) async {
    if (state.isBusy) return false;
    state = state.copyWith(isBusy: true, clearFailure: true);

    final result = await write();
    if (result case Err(:final failure)) {
      state = state.copyWith(isBusy: false, failure: failure);
      return false;
    }
    state = state.copyWith(isBusy: false, clearFailure: true);
    return true;
  }

  static bool _wasCancelled(Failure failure) =>
      failure is AuthFailure && failure.reason == AuthFailureReason.cancelled;
}

/// State of the calendar settings screen.
final calendarLinkControllerProvider =
    NotifierProvider<CalendarLinkController, CalendarLinkState>(
      CalendarLinkController.new,
    );
