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
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/auth/presentation/sign_in_screen.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/presentation/contact_editor_screen.dart';
import 'package:kith/features/contacts/presentation/contacts_screen.dart';
import 'package:kith/features/contacts/presentation/relationship_types_screen.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/hangouts/presentation/hangout_editor_screen.dart';
import 'package:kith/features/hangouts/presentation/hangouts_screen.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/household/domain/invite_code.dart';
import 'package:kith/features/household/presentation/household_screen.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_contact_repository.dart';
import '../helpers/fake_hangout_repository.dart';
import '../helpers/fake_household_repository.dart';
import '../helpers/fake_relationship_type_repository.dart';
import '../helpers/load_fonts.dart';
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

  setUp(() {
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
  });

  List<Override> overrides() => [
    authServiceProvider.overrideWithValue(auth),
    householdRepositoryProvider.overrideWithValue(repository),
    currentHouseholdIdProvider.overrideWithValue('hid-1'),
    contactRepositoryProvider.overrideWithValue(contacts),
    relationshipTypeRepositoryProvider.overrideWithValue(labels),
    hangoutRepositoryProvider.overrideWithValue(hangouts),
    // Pinned, because every gauge in these surfaces is a function of now.
    clockProvider.overrideWithValue(Clock.fixed(seeded)),
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
    // the surfaces worth pinning, so give it one.
    repository.households.updateAll(
      (_, household) => household.copyWith(
        inviteCode: InviteCode.parse('KH7RQ2').valueOrNull,
      ),
    );

    await pumpSurface(tester, const HouseholdScreen(), theme: theme);
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

  goldenTest('the splash held before the first route', 'splash', (
    tester,
    theme,
  ) async {
    await pumpSurface(tester, const AppSplash(), theme: theme, settles: false);
  });
}
