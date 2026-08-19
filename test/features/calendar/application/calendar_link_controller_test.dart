import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/household.dart';
import 'package:kith/data/services/calendar_directory.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/calendar/application/calendar_link_controller.dart';
import 'package:kith/features/calendar/application/calendar_providers.dart';
import 'package:kith/features/calendar/domain/calendar_scopes.dart';
import 'package:kith/features/household/application/household_providers.dart';

import '../../../helpers/fake_calendar_directory.dart';
import '../../../helpers/fake_google_sign_in_service.dart';
import '../../../helpers/fake_household_repository.dart';

void main() {
  const householdId = 'hid-1';
  const user = AuthUser(id: 'uid-1', email: 'brian@example.com');
  const family = CalendarListing(id: 'cal-1', name: 'Family');

  late FakeGoogleSignInService google;
  late FakeCalendarDirectory directory;
  late FakeHouseholdRepository households;

  setUp(() {
    google = FakeGoogleSignInService();
    directory = FakeCalendarDirectory()..calendars = const [family];
    households = FakeHouseholdRepository();
    addTearDown(households.dispose);
    households.households[householdId] = Household(
      id: householdId,
      name: 'The Marx house',
      inviteCode: null,
      createdAt: DateTime.utc(2026, 8, 16),
      createdBy: user.id,
    );
  });

  ProviderContainer containerOf() {
    final container = ProviderContainer(
      overrides: [
        googleSignInServiceProvider.overrideWithValue(google),
        calendarDirectoryProvider.overrideWithValue(directory),
        householdRepositoryProvider.overrideWithValue(households),
        currentUserProvider.overrideWithValue(user),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  CalendarLinkController controllerOf(ProviderContainer container) =>
      container.read(calendarLinkControllerProvider.notifier);

  group('load', () {
    test('asks for nothing when the scopes were never granted', () async {
      final container = containerOf();

      await controllerOf(container).load();

      final state = container.read(calendarLinkControllerProvider);
      expect(state.isAuthorised, isFalse);
      expect(state.calendars, isEmpty);
      expect(google.authorizeCalls, isEmpty);
      expect(directory.listCalls, 0);
    });

    test('lists the calendars a standing grant already covers', () async {
      google.token = 'granted-earlier';
      final container = containerOf();

      await controllerOf(container).load();

      final state = container.read(calendarLinkControllerProvider);
      expect(state.isAuthorised, isTrue);
      expect(state.calendars, [family]);
      expect(google.existingCalls.single, CalendarScopes.all);
      expect(google.authorizeCalls, isEmpty);
    });

    test('offers the grant again when the list is refused', () async {
      google.token = 'stale';
      directory.failure = const PermissionFailure('insufficient scope');
      final container = containerOf();

      await controllerOf(container).load();

      final state = container.read(calendarLinkControllerProvider);
      expect(state.isAuthorised, isFalse);
      expect(state.failure, isA<PermissionFailure>());
    });
  });

  group('connect', () {
    test('asks for both scopes, then lists what the account has', () async {
      final container = containerOf();

      await controllerOf(container).connect();

      expect(google.authorizeCalls.single, CalendarScopes.all);
      final state = container.read(calendarLinkControllerProvider);
      expect(state.isAuthorised, isTrue);
      expect(state.calendars, [family]);
      expect(state.isBusy, isFalse);
    });

    test('leaves the screen as it was when the sheet is dismissed', () async {
      google.authorizeFailure = const AuthFailure(
        AuthFailureReason.cancelled,
        'user closed it',
      );
      final container = containerOf();

      await controllerOf(container).connect();

      final state = container.read(calendarLinkControllerProvider);
      expect(state.failure, isNull);
      expect(state.isAuthorised, isFalse);
      expect(state.isBusy, isFalse);
      expect(directory.listCalls, 0);
    });

    test('reports a refusal that is not a change of mind', () async {
      google.authorizeFailure = const NetworkFailure('offline');
      final container = containerOf();

      await controllerOf(container).connect();

      expect(
        container.read(calendarLinkControllerProvider).failure,
        isA<NetworkFailure>(),
      );
    });
  });

  group('link', () {
    test('points the household at the chosen calendar', () async {
      final container = containerOf();

      final done = await controllerOf(
        container,
      ).link(householdId: householdId, calendar: family);

      expect(done, isTrue);
      expect(households.linkCalls.single.calendarId, 'cal-1');
      expect(households.linkCalls.single.calendarName, 'Family');
      expect(households.households[householdId]?.hasCalendar, isTrue);
    });

    test('reports a refusal and links nothing', () async {
      households.nextFailure = const PermissionFailure('not a member');
      final container = containerOf();

      final done = await controllerOf(
        container,
      ).link(householdId: householdId, calendar: family);

      expect(done, isFalse);
      expect(
        container.read(calendarLinkControllerProvider).failure,
        isA<PermissionFailure>(),
      );
      expect(households.households[householdId]?.hasCalendar, isFalse);
    });
  });

  group('unlink', () {
    test('stops the household writing to a calendar', () async {
      final container = containerOf();
      await controllerOf(
        container,
      ).link(householdId: householdId, calendar: family);

      final done = await controllerOf(container).unlink(
        householdId: householdId,
      );

      expect(done, isTrue);
      expect(households.unlinkCalls.single, householdId);
      expect(households.households[householdId]?.hasCalendar, isFalse);
    });

    test('reports a refusal', () async {
      households.nextFailure = const NetworkFailure('offline');
      final container = containerOf();

      final done = await controllerOf(container).unlink(
        householdId: householdId,
      );

      expect(done, isFalse);
      expect(
        container.read(calendarLinkControllerProvider).failure,
        isA<NetworkFailure>(),
      );
    });
  });
}
