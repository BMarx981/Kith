import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/theme.dart';
import 'package:kith/app/widgets/app_splash.dart';
import 'package:kith/core/clock/clock_provider.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/data/models/planned_hangout.dart';
import 'package:kith/data/models/planned_hangout_status.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/data/services/calendar_directory.dart';
import 'package:kith/data/services/device_contact_directory.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/auth/presentation/sign_in_screen.dart';
import 'package:kith/features/calendar/application/calendar_providers.dart';
import 'package:kith/features/calendar/presentation/calendar_settings_screen.dart';
import 'package:kith/features/contacts/application/contact_import_controller.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/birthday.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/presentation/contact_editor_screen.dart';
import 'package:kith/features/contacts/presentation/contact_import_screen.dart';
import 'package:kith/features/contacts/presentation/contacts_screen.dart';
import 'package:kith/features/contacts/presentation/relationship_types_screen.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/hangouts/presentation/hangout_editor_screen.dart';
import 'package:kith/features/hangouts/presentation/hangouts_screen.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/household/domain/invite_code.dart';
import 'package:kith/features/household/presentation/household_screen.dart';
import 'package:kith/features/notifications/application/notification_providers.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';
import 'package:kith/features/suggestions/presentation/home_screen.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_calendar_directory.dart';
import '../helpers/fake_contact_repository.dart';
import '../helpers/fake_device_contact_directory.dart';
import '../helpers/fake_google_sign_in_service.dart';
import '../helpers/fake_hangout_repository.dart';
import '../helpers/fake_household_repository.dart';
import '../helpers/fake_notification_scheduler.dart';
import '../helpers/fake_planned_hangout_repository.dart';
import '../helpers/fake_relationship_type_repository.dart';
import '../helpers/load_fonts.dart';
import '../helpers/precache_images.dart';
import '../helpers/pump_app.dart';

/// Pins the design language on the surfaces that exist today.
///
/// These are about the theme, not about behaviour: each screen is pumped in a
/// single settled state, in both brightnesses, at one phone-sized window. A
/// diff here means a palette, type or component change reached the pixels, so
/// regenerate them only when that was the point of the change.
///
/// Authored on macOS. Text rasterises differently on other platforms, so a
/// Linux CI would need its own set rather than a shared one.
void main() {
  const owner = AuthUser(id: 'uid-owner', email: 'brian@example.com');
  const partner = AuthUser(id: 'uid-partner', email: 'partner@example.com');

  const window = Size(400, 800);
  final seeded = DateTime.utc(2026, 8, 18);

  setUpAll(loadAppFonts);

  late FakeAuthService auth;
  late FakeHouseholdRepository repository;
  late FakeContactRepository contacts;
  late FakeRelationshipTypeRepository labels;
  late FakeHangoutRepository hangouts;
  late FakePlannedHangoutRepository plans;
  late FakeGoogleSignInService google;
  late FakeCalendarDirectory calendars;
  late FakeNotificationScheduler scheduler;
  late FakeDeviceContactDirectory deviceContacts;

  setUp(() {
    scheduler = FakeNotificationScheduler();
    deviceContacts = FakeDeviceContactDirectory();
    auth = FakeAuthService(initialUser: owner);
    addTearDown(auth.dispose);
    repository = FakeHouseholdRepository();
    addTearDown(repository.dispose);
    contacts = FakeContactRepository();
    addTearDown(contacts.dispose);
    labels = FakeRelationshipTypeRepository();
    addTearDown(labels.dispose);
    hangouts = FakeHangoutRepository();
    addTearDown(hangouts.dispose);
    plans = FakePlannedHangoutRepository();
    addTearDown(plans.dispose);
    // A member who has already granted the calendar scopes, so the picker is
    // the state worth pinning rather than the connect button.
    google = FakeGoogleSignInService()..token = 'granted-earlier';
    calendars = FakeCalendarDirectory()
      ..calendars = const [
        CalendarListing(id: 'cal-me', name: 'Brian', isPrimary: true),
        CalendarListing(id: 'cal-1', name: 'Hangouts'),
        CalendarListing(id: 'cal-2', name: 'School term dates'),
      ];
  });

  List<Override> overrides() => [
    authServiceProvider.overrideWithValue(auth),
    householdRepositoryProvider.overrideWithValue(repository),
    currentHouseholdIdProvider.overrideWithValue('hid-1'),
    contactRepositoryProvider.overrideWithValue(contacts),
    relationshipTypeRepositoryProvider.overrideWithValue(labels),
    hangoutRepositoryProvider.overrideWithValue(hangouts),
    plannedHangoutRepositoryProvider.overrideWithValue(plans),
    googleSignInServiceProvider.overrideWithValue(google),
    calendarDirectoryProvider.overrideWithValue(calendars),
    // Pinned, because every gauge in these surfaces is a function of now.
    clockProvider.overrideWithValue(Clock.fixed(seeded)),
    notificationSchedulerProvider.overrideWithValue(scheduler),
    deviceContactDirectoryProvider.overrideWithValue(deviceContacts),
  ];

  /// Fills the fakes with a household worth looking at: four labels and four
  /// contacts spanning the cadences, an archived one, a kid's friend with a
  /// guardian, and enough logged hangouts to put a gauge in each of its four
  /// readings.
  void seedContacts() {
    const names = ['Friend', 'Family', "Child's friend", 'Neighbor'];
    for (final (index, name) in names.indexed) {
      labels.seed(
        RelationshipType(
          id: 'rid-$index',
          name: name,
          sortOrder: index,
          createdAt: seeded,
        ),
      );
    }
    final people = <(String, String, Cadence, ContactPriority, String?, bool)>[
      (
        'Marcus Bell',
        'rid-0',
        Cadence.monthly,
        ContactPriority.high,
        null,
        false,
      ),
      (
        'Priya Raman',
        'rid-2',
        Cadence.weekly,
        ContactPriority.normal,
        'Dana Raman',
        false,
      ),
      (
        'The Okonkwos',
        'rid-3',
        Cadence.quarterly,
        ContactPriority.low,
        null,
        false,
      ),
      (
        'Beatrice Lang',
        'rid-1',
        Cadence.twiceAYear,
        ContactPriority.normal,
        null,
        true,
      ),
    ];
    for (final (index, person) in people.indexed) {
      final (name, typeId, cadence, priority, guardian, archived) = person;
      contacts.seed(
        Contact(
          id: 'cid-$index',
          name: name,
          relationshipTypeId: typeId,
          cadence: cadence,
          priority: priority,
          createdAt: seeded,
          updatedAt: seeded,
          guardianName: guardian,
          guardianPhone: guardian == null ? null : '555-0199',
          // Marcus's birthday is four days out, which puts the strip on the
          // Reconnect surface; Priya's has no year, so the two forms the
          // editor and the strip can render are both pinned.
          birthday: switch (index) {
            0 => const Birthday(month: 8, day: 22, year: 1988),
            1 => const Birthday(month: 9, day: 3),
            _ => null,
          },
          tags: index == 1 ? const ['soccer'] : const [],
          isArchived: archived,
        ),
      );
    }

    // Chosen so the gauge appears in all four of its readings at once:
    // Marcus is monthly and eight days back, so fresh; Priya is weekly and a
    // month back, so overdue; the Okonkwos are quarterly and eleven weeks
    // back, so due; and Beatrice has nothing logged, so never.
    final logs = <(String, int, List<String>, String?)>[
      ('hgid-1', 8, ['cid-0'], 'Coffee, and he brought the dog'),
      ('hgid-2', 30, ['cid-0', 'cid-1'], 'Barbecue in their garden'),
      ('hgid-3', 77, ['cid-2'], null),
    ];
    for (final (id, daysAgo, contactIds, note) in logs) {
      hangouts.seed(
        Hangout(
          id: id,
          occurredOn: seeded.subtract(Duration(days: daysAgo)),
          contactIds: contactIds,
          attendeeIds: const ['uid-owner'],
          createdBy: 'uid-owner',
          createdAt: seeded,
          updatedAt: seeded,
          note: note,
        ),
      );
    }
  }

  /// Pumps [surface] at a fixed window size.
  ///
  /// A surface whose only motion is an indeterminate spinner never settles, so
  /// [settles] trades `pumpAndSettle` for a fixed advance: fake time makes the
  /// spinner land at the same angle every run.
  Future<void> pumpSurface(
    WidgetTester tester,
    Widget surface, {
    required ThemeData theme,
    bool settles = true,
  }) async {
    tester.view.physicalSize = window;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpApp(surface, overrides: overrides(), theme: theme);
    if (settles) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 250));
    }
    await precacheImages(tester);
  }

  /// Runs [body] against both themes, naming each golden after the brightness.
  void goldenTest(
    String description,
    String file,
    Future<void> Function(WidgetTester tester, ThemeData theme) body,
  ) {
    for (final (name, theme) in [
      ('light', KithTheme.light),
      ('dark', KithTheme.dark),
    ]) {
      testWidgets('$description ($name)', (tester) async {
        await body(tester, theme);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('${file}_$name.png'),
        );
      });
    }
  }

  goldenTest('sign-in, waiting for credentials', 'sign_in', (
    tester,
    theme,
  ) async {
    await pumpSurface(tester, const SignInScreen(), theme: theme);
  });

  goldenTest('the household, its code and its members', 'household', (
    tester,
    theme,
  ) async {
    await repository.createHousehold(
      name: 'The Marx house',
      owner: owner,
      displayName: 'Brian',
    );
    await repository.joinWithInviteCode(
      code: 'KH7RQ2',
      user: partner,
      displayName: 'Partner',
    );
    // The fake creates households without a code; the invite card is one of
    // the surfaces worth pinning, so give it one, and a calendar with it.
    repository.households.updateAll(
      (_, household) => household.copyWith(
        inviteCode: InviteCode.parse('KH7RQ2').valueOrNull,
        calendarId: 'cal-1',
        calendarName: 'Hangouts',
      ),
    );
    // The digest turned on, so the pickers are pinned as well as the switch.
    await repository.setDigestPreference(
      householdId: 'hid-1',
      uid: owner.id,
      digestDay: DateTime.sunday,
      digestHour: 9,
    );

    await pumpSurface(tester, const HouseholdScreen(), theme: theme);
  });

  goldenTest('the calendar picker, with one linked', 'calendar', (
    tester,
    theme,
  ) async {
    await repository.createHousehold(
      name: 'The Marx house',
      owner: owner,
      displayName: 'Brian',
    );
    repository.households.updateAll(
      (_, household) => household.copyWith(
        calendarId: 'cal-1',
        calendarName: 'Hangouts',
      ),
    );

    await pumpSurface(tester, const CalendarSettingsScreen(), theme: theme);
  });

  goldenTest('the contact list, filtered and sorted', 'contacts', (
    tester,
    theme,
  ) async {
    seedContacts();

    await pumpSurface(tester, const ContactsScreen(), theme: theme);
  });

  goldenTest('the contact editor, opened on someone', 'contact_editor', (
    tester,
    theme,
  ) async {
    seedContacts();

    await pumpSurface(
      tester,
      const ContactEditorScreen(contactId: 'cid-1'),
      theme: theme,
    );
  });

  goldenTest('the address book, ready to import', 'contact_import', (
    tester,
    theme,
  ) async {
    seedContacts();
    // Marcus is already in Kith, so the list shows him greyed and ticked
    // rather than leaving him out: both row states are worth pinning.
    for (final (id, name, phone) in const [
      ('row-1', 'Ana Reyes', '555-0201'),
      ('row-2', 'Marcus Bell', null),
      ('row-3', 'Ben Okafor', '555-0202'),
      ('row-4', 'Dr Whitfield', null),
    ]) {
      deviceContacts.seed(DeviceContact(id: id, name: name, phone: phone));
    }

    await pumpSurface(tester, const ContactImportScreen(), theme: theme);
    await tester.tap(find.byKey(ContactImportScreen.readKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ContactImportScreen.rowKey('row-1')));
    await tester.pumpAndSettle();
  });

  goldenTest('the relationship labels, in their order', 'relationship_types', (
    tester,
    theme,
  ) async {
    seedContacts();

    await pumpSurface(tester, const RelationshipTypesScreen(), theme: theme);
  });

  goldenTest('the household timeline, grouped by day', 'hangouts', (
    tester,
    theme,
  ) async {
    seedContacts();
    await repository.createHousehold(
      name: 'The Marx house',
      owner: owner,
      displayName: 'Brian',
    );

    await pumpSurface(tester, const HangoutsScreen(), theme: theme);
  });

  goldenTest(
    "one contact's history, headed by their gauge",
    'contact_hangouts',
    (
      tester,
      theme,
    ) async {
      seedContacts();

      await pumpSurface(
        tester,
        const HangoutsScreen(contactId: 'cid-1'),
        theme: theme,
      );
    },
  );

  goldenTest('the quick log, opened on today', 'hangout_editor', (
    tester,
    theme,
  ) async {
    seedContacts();
    await repository.createHousehold(
      name: 'The Marx house',
      owner: owner,
      displayName: 'Brian',
    );

    await pumpSurface(tester, const HangoutEditorScreen(), theme: theme);
  });

  goldenTest('the Reconnect section, ranked', 'home', (tester, theme) async {
    seedContacts();
    // Priya is a week overdue and has an arrangement standing, which is the
    // one card state the ranked list cannot produce on its own.
    plans.seed(
      PlannedHangout(
        id: 'pid-1',
        plannedFor: seeded.add(const Duration(days: 7)),
        contactIds: const ['cid-1'],
        status: PlannedHangoutStatus.proposed,
        createdBy: 'uid-owner',
        createdAt: seeded,
        updatedAt: seeded,
      ),
    );

    await pumpSurface(tester, const HomeScreen(), theme: theme);
  });

  goldenTest('Reconnect with nobody overdue', 'home_clear', (
    tester,
    theme,
  ) async {
    labels.seed(
      RelationshipType(
        id: 'rid-0',
        name: 'Friend',
        sortOrder: 0,
        createdAt: seeded,
      ),
    );
    contacts.seed(
      Contact(
        id: 'cid-0',
        name: 'Marcus Bell',
        relationshipTypeId: 'rid-0',
        cadence: Cadence.monthly,
        priority: ContactPriority.normal,
        createdAt: seeded,
        updatedAt: seeded,
      ),
    );
    hangouts.seed(
      Hangout(
        id: 'hgid-1',
        occurredOn: seeded.subtract(const Duration(days: 2)),
        contactIds: const ['cid-0'],
        attendeeIds: const ['uid-owner'],
        createdBy: 'uid-owner',
        createdAt: seeded,
        updatedAt: seeded,
      ),
    );

    await pumpSurface(tester, const HomeScreen(), theme: theme);
  });

  goldenTest('the splash held before the first route', 'splash', (
    tester,
    theme,
  ) async {
    await pumpSurface(tester, const AppSplash(), theme: theme, settles: false);
  });
}
