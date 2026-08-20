import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/birthday.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/notifications/application/digest_controller.dart';
import 'package:kith/features/notifications/application/notification_providers.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';
import 'package:kith/l10n/gen/app_localizations_en.dart';
import 'package:kith/l10n/l10n_providers.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/fake_contact_repository.dart';
import '../../../helpers/fake_hangout_repository.dart';
import '../../../helpers/fake_household_repository.dart';
import '../../../helpers/fake_notification_scheduler.dart';
import '../../../helpers/fake_planned_hangout_repository.dart';

void main() {
  const householdId = 'hid-1';
  const owner = AuthUser(id: 'uid-1', email: 'brian@example.com');
  // 2026-08-18, a Tuesday, 10:00 local.
  final now = DateTime(2026, 8, 18, 10);

  late FakeAuthService auth;
  late FakeHouseholdRepository households;
  late FakeContactRepository contacts;
  late FakeHangoutRepository hangouts;
  late FakePlannedHangoutRepository plans;
  late FakeNotificationScheduler scheduler;

  setUp(() async {
    auth = FakeAuthService(initialUser: owner);
    addTearDown(auth.dispose);
    households = FakeHouseholdRepository();
    addTearDown(households.dispose);
    contacts = FakeContactRepository();
    addTearDown(contacts.dispose);
    hangouts = FakeHangoutRepository();
    addTearDown(hangouts.dispose);
    plans = FakePlannedHangoutRepository();
    addTearDown(plans.dispose);
    scheduler = FakeNotificationScheduler();

    await households.createHousehold(
      name: 'The Marx house',
      owner: owner,
      displayName: 'Brian',
    );
  });

  List<Override> overrides() => [
    authServiceProvider.overrideWithValue(auth),
    householdRepositoryProvider.overrideWithValue(households),
    currentHouseholdIdProvider.overrideWithValue(householdId),
    contactRepositoryProvider.overrideWithValue(contacts),
    hangoutRepositoryProvider.overrideWithValue(hangouts),
    plannedHangoutRepositoryProvider.overrideWithValue(plans),
    notificationSchedulerProvider.overrideWithValue(scheduler),
    // The digest is worded through the app's localizations, which resolve off
    // the platform in the app; pinned to English here like the clock is.
    appLocalizationsProvider.overrideWithValue(AppLocalizationsEn()),
    clockProvider.overrideWithValue(Clock.fixed(now)),
  ];

  /// A container with the member roster and the contacts already streamed, so
  /// the controller reads settled data rather than an empty first frame.
  Future<ProviderContainer> settled() async {
    final container = ProviderContainer(overrides: overrides());
    addTearDown(container.dispose);
    // Listened to before they are awaited: providers auto-dispose without a
    // listener, and one disposed mid-load never emits at all.
    container
      ..listen(authStateChangesProvider, (_, _) {})
      ..listen(householdMembersProvider(householdId), (_, _) {})
      ..listen(contactsProvider(householdId), (_, _) {})
      ..listen(hangoutsProvider(householdId), (_, _) {})
      ..listen(plannedHangoutsProvider(householdId), (_, _) {});
    await container.read(authStateChangesProvider.future);
    await container.read(householdMembersProvider(householdId).future);
    await container.read(contactsProvider(householdId).future);
    await container.read(hangoutsProvider(householdId).future);
    await container.read(plannedHangoutsProvider(householdId).future);
    return container;
  }

  void seedOverdueContact() {
    contacts.seed(
      Contact(
        id: 'cid-1',
        name: 'Marcus Bell',
        relationshipTypeId: 'rid-1',
        cadence: Cadence.monthly,
        priority: ContactPriority.normal,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    hangouts.seed(
      Hangout(
        id: 'hgid-1',
        occurredOn: DateTime.utc(2026, 6),
        contactIds: const ['cid-1'],
        attendeeIds: const ['uid-1'],
        createdBy: 'uid-1',
        createdAt: DateTime.utc(2026, 6),
        updatedAt: DateTime.utc(2026, 6),
      ),
    );
  }

  group('setPreference turning the digest on', () {
    test('asks for permission, stores the day, and schedules', () async {
      seedOverdueContact();
      final container = await settled();

      await container
          .read(digestControllerProvider.notifier)
          .setPreference(day: DateTime.sunday, hour: 9);

      expect(scheduler.permissionAsks, 1);
      expect(households.digestCalls.single.digestDay, DateTime.sunday);
      expect(households.digestCalls.single.digestHour, 9);
      expect(households.digestCalls.single.uid, owner.id);
      // The Sunday after Tuesday 2026-08-18.
      expect(scheduler.lastScheduled?.at, DateTime(2026, 8, 23, 9));
      expect(scheduler.lastScheduled?.title, '1 person is overdue');
      expect(scheduler.lastScheduled?.body, 'Marcus Bell.');
      expect(container.read(digestControllerProvider).failure, isNull);
    });

    test('stores nothing when the permission prompt is declined', () async {
      seedOverdueContact();
      scheduler.permissionGranted = false;
      final container = await settled();

      await container
          .read(digestControllerProvider.notifier)
          .setPreference(day: DateTime.sunday, hour: 9);

      expect(households.digestCalls, isEmpty);
      expect(scheduler.scheduled, isEmpty);
      expect(
        container.read(digestControllerProvider).isPermissionDenied,
        isTrue,
      );
    });

    test('reports a write that was refused, and schedules nothing', () async {
      seedOverdueContact();
      households.nextFailure = const PermissionFailure('nope');
      final container = await settled();

      await container
          .read(digestControllerProvider.notifier)
          .setPreference(day: DateTime.sunday, hour: 9);

      expect(scheduler.scheduled, isEmpty);
      expect(
        container.read(digestControllerProvider).failure,
        const PermissionFailure('nope'),
      );
    });

    test('cancels rather than schedules with nothing to say', () async {
      // No contacts at all: nobody is overdue and nobody has a birthday.
      final container = await settled();

      await container
          .read(digestControllerProvider.notifier)
          .setPreference(day: DateTime.sunday, hour: 9);

      expect(households.digestCalls.single.digestDay, DateTime.sunday);
      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.cancelCount, 1);
    });

    test('schedules on a birthday alone', () async {
      // Seen two days ago, so she is fresh and the ranking leaves her out;
      // her birthday is the only thing the digest has to report.
      hangouts.seed(
        Hangout(
          id: 'hgid-1',
          occurredOn: DateTime.utc(2026, 8, 16),
          contactIds: const ['cid-1'],
          attendeeIds: const ['uid-1'],
          createdBy: 'uid-1',
          createdAt: DateTime.utc(2026, 8, 16),
          updatedAt: DateTime.utc(2026, 8, 16),
        ),
      );
      contacts.seed(
        Contact(
          id: 'cid-1',
          name: 'Ana Reyes',
          relationshipTypeId: 'rid-1',
          cadence: Cadence.monthly,
          priority: ContactPriority.normal,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          birthday: const Birthday(month: 8, day: 21),
        ),
      );
      final container = await settled();

      await container
          .read(digestControllerProvider.notifier)
          .setPreference(day: DateTime.sunday, hour: 9);

      expect(scheduler.lastScheduled?.title, '1 birthday this week');
    });
  });

  group('setPreference turning the digest off', () {
    test('stores no day, cancels, and never asks for permission', () async {
      seedOverdueContact();
      final container = await settled();

      await container
          .read(digestControllerProvider.notifier)
          .setPreference(day: null, hour: 9);

      expect(scheduler.permissionAsks, 0);
      expect(households.digestCalls.single.digestDay, isNull);
      expect(households.digestCalls.single.digestHour, 9);
      expect(scheduler.cancelCount, 1);
      expect(scheduler.scheduled, isEmpty);
    });
  });

  group('reschedule', () {
    test('follows the stored preference', () async {
      seedOverdueContact();
      final container = await settled();
      await households.setDigestPreference(
        householdId: householdId,
        uid: owner.id,
        digestDay: DateTime.friday,
        digestHour: 18,
      );
      await container.read(householdMembersProvider(householdId).future);

      await container.read(digestControllerProvider.notifier).reschedule();

      expect(scheduler.lastScheduled?.at, DateTime(2026, 8, 21, 18));
      // Rescheduling is not a preference change; nothing is written.
      expect(households.digestCalls, hasLength(1));
    });

    test('cancels for a member who never asked for one', () async {
      seedOverdueContact();
      final container = await settled();

      await container.read(digestControllerProvider.notifier).reschedule();

      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.cancelCount, 1);
    });

    test('does nothing before the roster has arrived', () async {
      seedOverdueContact();
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);

      await container.read(digestControllerProvider.notifier).reschedule();

      expect(scheduler.scheduled, isEmpty);
      expect(scheduler.cancelCount, 0);
    });

    test('keeps a scheduling failure without interrupting', () async {
      seedOverdueContact();
      final container = await settled();
      await households.setDigestPreference(
        householdId: householdId,
        uid: owner.id,
        digestDay: DateTime.friday,
        digestHour: 18,
      );
      await container.read(householdMembersProvider(householdId).future);
      scheduler.nextFailure = const UnknownFailure('no alarm slots');

      await container.read(digestControllerProvider.notifier).reschedule();

      expect(
        container.read(digestControllerProvider).failure,
        const UnknownFailure('no alarm slots'),
      );
    });
  });
}
