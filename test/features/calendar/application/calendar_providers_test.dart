import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/household.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/calendar/application/calendar_providers.dart';
import 'package:kith/features/calendar/application/calendar_sync_controller.dart';
import 'package:kith/features/household/application/household_providers.dart';

import '../../../helpers/fake_household_repository.dart';

void main() {
  const householdId = 'hid-1';

  late FakeHouseholdRepository households;

  setUp(() {
    households = FakeHouseholdRepository();
    addTearDown(households.dispose);
  });

  ProviderContainer containerOf() {
    final container = ProviderContainer(
      overrides: [householdRepositoryProvider.overrideWithValue(households)],
    );
    addTearDown(container.dispose);
    return container;
  }

  void seedHousehold({String? calendarId}) =>
      households.households[householdId] = Household(
        id: householdId,
        name: 'The Marx house',
        inviteCode: null,
        createdAt: DateTime.utc(2026, 8, 16),
        createdBy: 'uid-1',
        calendarId: calendarId,
        calendarName: calendarId == null ? null : 'Hangouts',
      );

  Future<String?> calendarIdOf(ProviderContainer container) async {
    // A stream provider only runs while something listens to it, so the
    // household has to be subscribed before the derived value means anything.
    final subscription = container.listen(
      householdProvider(householdId),
      (_, _) {},
    );
    addTearDown(subscription.close);
    await container.read(householdProvider(householdId).future);
    return container.read(householdCalendarIdProvider(householdId));
  }

  group('service providers', () {
    test('throw until the composition root overrides them', () {
      final bare = ProviderContainer();
      addTearDown(bare.dispose);

      for (final provider in [
        calendarSinkProvider,
        calendarDirectoryProvider,
        googleSignInServiceProvider,
      ]) {
        expect(
          () => bare.read(provider),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.exception,
              'exception',
              isUnimplementedError,
            ),
          ),
        );
      }
    });
  });

  group('householdCalendarIdProvider', () {
    test('reads the link off the household document', () async {
      seedHousehold(calendarId: 'cal-1');

      expect(await calendarIdOf(containerOf()), 'cal-1');
    });

    test('is null for a household with no calendar linked', () async {
      seedHousehold();

      expect(await calendarIdOf(containerOf()), isNull);
    });

    test('is null while the household has not arrived', () {
      seedHousehold(calendarId: 'cal-1');

      expect(
        containerOf().read(householdCalendarIdProvider(householdId)),
        isNull,
      );
    });
  });

  group('CalendarSyncState', () {
    test('starts idle with nothing to report', () {
      const state = CalendarSyncState();

      expect(state.isSyncing, isFalse);
      expect(state.failure, isNull);
    });

    test('has value semantics', () {
      const state = CalendarSyncState(failure: NetworkFailure('offline'));

      expect(
        state,
        const CalendarSyncState(failure: NetworkFailure('offline')),
      );
      expect(
        state.hashCode,
        const CalendarSyncState(failure: NetworkFailure('offline')).hashCode,
      );
      expect(state, isNot(const CalendarSyncState()));
      expect(state, isNot(const CalendarSyncState(isSyncing: true)));
    });

    test('toString names both fields', () {
      const state = CalendarSyncState(
        isSyncing: true,
        failure: NetworkFailure('offline'),
      );

      expect(state.toString(), contains('isSyncing: true'));
      expect(state.toString(), contains('offline'));
    });
  });
}
