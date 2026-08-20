import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override, ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/birthday.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/notifications/application/notification_providers.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';
import 'package:kith/l10n/gen/app_localizations_en.dart';

import '../../../helpers/fake_auth_service.dart';
import '../../../helpers/fake_contact_repository.dart';
import '../../../helpers/fake_hangout_repository.dart';
import '../../../helpers/fake_household_repository.dart';
import '../../../helpers/fake_planned_hangout_repository.dart';

void main() {
  final l10n = AppLocalizationsEn();

  const householdId = 'hid-1';
  const owner = AuthUser(id: 'uid-1', email: 'brian@example.com');
  const partner = AuthUser(id: 'uid-2', email: 'sam@example.com');
  final now = DateTime.utc(2026, 8, 18, 10);

  late FakeAuthService auth;
  late FakeHouseholdRepository households;
  late FakeContactRepository contacts;
  late FakeHangoutRepository hangouts;
  late FakePlannedHangoutRepository plans;

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

    await households.createHousehold(
      name: 'The Marx house',
      owner: owner,
      displayName: 'Brian',
    );
  });

  List<Override> overrides({AuthUser? user = owner}) => [
    authServiceProvider.overrideWithValue(auth),
    householdRepositoryProvider.overrideWithValue(households),
    currentHouseholdIdProvider.overrideWithValue(householdId),
    contactRepositoryProvider.overrideWithValue(contacts),
    hangoutRepositoryProvider.overrideWithValue(hangouts),
    plannedHangoutRepositoryProvider.overrideWithValue(plans),
    clockProvider.overrideWithValue(Clock.fixed(now)),
    if (user == null) currentUserProvider.overrideWithValue(null),
  ];

  Future<ProviderContainer> settled({AuthUser? user = owner}) async {
    final container = ProviderContainer(overrides: overrides(user: user));
    addTearDown(container.dispose);
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

  group('currentMemberProvider', () {
    test('finds the signed-in user among the members', () async {
      final container = await settled();

      final member = container.read(currentMemberProvider(householdId));

      expect(member?.id, owner.id);
      expect(member?.displayName, 'Brian');
    });

    test('is null before the identity is known', () async {
      final container = await settled(user: null);

      expect(container.read(currentMemberProvider(householdId)), isNull);
    });

    test('is null for somebody who is not on the roster', () async {
      auth = FakeAuthService(initialUser: partner);
      addTearDown(auth.dispose);
      final container = await settled();

      expect(container.read(currentMemberProvider(householdId)), isNull);
    });

    test('is null before the roster has arrived', () {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);

      expect(container.read(currentMemberProvider(householdId)), isNull);
    });
  });

  group('weeklyDigestProvider', () {
    test('is empty for a household with nobody to report', () async {
      final container = await settled();

      expect(container.read(weeklyDigestProvider(householdId)).isEmpty, isTrue);
    });

    test('carries the ranking and the week ahead', () async {
      contacts.seed(
        Contact(
          id: 'cid-1',
          name: 'Marcus Bell',
          relationshipTypeId: 'rid-1',
          cadence: Cadence.monthly,
          priority: ContactPriority.normal,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          birthday: const Birthday(month: 8, day: 21, year: 1990),
        ),
      );
      final container = await settled();

      final digest = container.read(weeklyDigestProvider(householdId));

      expect(digest.overdue.single.contact.name, 'Marcus Bell');
      expect(digest.birthdays.single.turningAge, 36);
      expect(digest.title(l10n), '1 person is overdue');
    });

    test('looks only a week ahead for birthdays', () async {
      contacts.seed(
        Contact(
          id: 'cid-1',
          name: 'Ana Reyes',
          relationshipTypeId: 'rid-1',
          cadence: Cadence.monthly,
          priority: ContactPriority.normal,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
          // Three weeks out: on the home screen's month-long strip, but not in
          // the week this digest covers.
          birthday: const Birthday(month: 9, day: 8),
        ),
      );
      final container = await settled();

      expect(
        container.read(weeklyDigestProvider(householdId)).birthdays,
        isEmpty,
      );
      expect(
        container.read(upcomingBirthdaysProvider(householdId)),
        hasLength(1),
      );
    });

    test('is empty while the contacts are still loading', () {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);

      expect(container.read(weeklyDigestProvider(householdId)).isEmpty, isTrue);
    });
  });

  group('notificationSchedulerProvider', () {
    test('throws unless the composition root bound one', () {
      final container = ProviderContainer(overrides: overrides());
      addTearDown(container.dispose);

      expect(
        () => container.read(notificationSchedulerProvider),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.exception,
            'exception',
            isUnimplementedError,
          ),
        ),
      );
    });
  });
}
