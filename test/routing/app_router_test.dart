import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/models/contact.dart';
import 'package:kith/data/models/contact_priority.dart';
import 'package:kith/data/models/hangout.dart';
import 'package:kith/data/models/relationship_type.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/contacts/application/contact_providers.dart';
import 'package:kith/features/contacts/domain/cadence.dart';
import 'package:kith/features/contacts/presentation/contact_editor_screen.dart';
import 'package:kith/features/contacts/presentation/contacts_screen.dart';
import 'package:kith/features/contacts/presentation/relationship_types_screen.dart';
import 'package:kith/features/hangouts/application/hangout_providers.dart';
import 'package:kith/features/hangouts/presentation/hangout_editor_screen.dart';
import 'package:kith/features/hangouts/presentation/hangouts_screen.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/household/presentation/household_screen.dart';
import 'package:kith/features/suggestions/application/suggestion_providers.dart';
import 'package:kith/features/suggestions/presentation/home_screen.dart';
import 'package:kith/routing/app_router.dart';
import 'package:kith/routing/guards/auth_guard.dart';

import '../helpers/fake_auth_service.dart';
import '../helpers/fake_contact_repository.dart';
import '../helpers/fake_hangout_repository.dart';
import '../helpers/fake_household_repository.dart';
import '../helpers/fake_planned_hangout_repository.dart';
import '../helpers/fake_relationship_type_repository.dart';

/// Stands in for the real guards so these tests describe the route graph
/// rather than who is signed in or where they belong; each guard has its own
/// suite.
class _OpenGuard extends AutoRouteGuard {
  const _OpenGuard();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) =>
      resolver.next();
}

void main() {
  const user = AuthUser(id: 'uid-1', email: 'brian@example.com');

  AppRouter buildRouter() => AppRouter(
    authGuard: const _OpenGuard(),
    householdGuard: const _OpenGuard(),
  );

  group('AppRouter', () {
    test('declares its routes at stable paths', () {
      final paths = {
        for (final route in buildRouter().routes) route.name: route.path,
      };

      expect(paths, {
        'HomeRoute': '/',
        'ContactsRoute': '/contacts',
        'ContactEditorRoute': '/contacts/edit/:contactId',
        'RelationshipTypesRoute': '/contacts/labels',
        'ContactImportRoute': '/contacts/import',
        'HangoutsRoute': '/hangouts/:contactId',
        'HangoutEditorRoute': '/log/:hangoutId',
        'HouseholdRoute': '/household',
        'CalendarSettingsRoute': '/household/calendar',
        'SignInRoute': '/sign-in',
        'HouseholdOnboardingRoute': '/welcome',
      });
    });

    test('starts at the home route', () {
      final initial = buildRouter().routes.where((r) => r.initial).toList();

      expect(initial, hasLength(1));
      expect(initial.single.name, 'HomeRoute');
    });

    test('guards everything that reads household data, and only that', () {
      final guarded = {
        for (final route in buildRouter().routes)
          route.name: route.guards.length,
      };

      // Onboarding is behind the auth guard only: it is where a signed-in
      // user without a household is sent, so guarding it on membership too
      // would send them back to themselves.
      expect(guarded, {
        'HomeRoute': 2,
        'ContactsRoute': 2,
        'ContactEditorRoute': 2,
        'RelationshipTypesRoute': 2,
        'ContactImportRoute': 2,
        'HangoutsRoute': 2,
        'HangoutEditorRoute': 2,
        'HouseholdRoute': 2,
        'CalendarSettingsRoute': 2,
        'SignInRoute': 0,
        'HouseholdOnboardingRoute': 1,
      });
    });

    testWidgets('resolves the initial path to the home screen', (tester) async {
      final router = buildRouter();

      await tester.pumpWidget(
        ProviderScope(
          // The home screen reads household data, so it needs a scope. Given
          // no household it waits, which is all this test needs: what is being
          // asserted is which screen the initial path lands on.
          overrides: [currentHouseholdIdProvider.overrideWithValue(null)],
          child: MaterialApp.router(routerConfig: router.config()),
        ),
      );
      // A fixed advance rather than `pumpAndSettle`: with no household the
      // home screen holds an indeterminate spinner, which never settles.
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('navigates to contacts via the generated typed route', (
      tester,
    ) async {
      final auth = FakeAuthService(initialUser: user);
      addTearDown(auth.dispose);
      final contacts = FakeContactRepository();
      addTearDown(contacts.dispose);
      final labels = FakeRelationshipTypeRepository();
      addTearDown(labels.dispose);
      final hangouts = FakeHangoutRepository();
      addTearDown(hangouts.dispose);
      final plans = FakePlannedHangoutRepository();
      addTearDown(plans.dispose);
      final router = buildRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            currentHouseholdIdProvider.overrideWithValue('hid-1'),
            contactRepositoryProvider.overrideWithValue(contacts),
            relationshipTypeRepositoryProvider.overrideWithValue(labels),
            hangoutRepositoryProvider.overrideWithValue(hangouts),
            plannedHangoutRepositoryProvider.overrideWithValue(plans),
          ],
          child: MaterialApp.router(routerConfig: router.config()),
        ),
      );
      await tester.pumpAndSettle();

      // push() completes when the route is popped, so it is deliberately
      // not awaited here.
      unawaited(router.push(const ContactsRoute()));
      await tester.pumpAndSettle();

      expect(find.byType(ContactsScreen), findsOneWidget);

      unawaited(router.push(const RelationshipTypesRoute()));
      await tester.pumpAndSettle();

      expect(find.byType(RelationshipTypesScreen), findsOneWidget);

      unawaited(router.push(ContactEditorRoute(contactId: 'cid-1')));
      await tester.pumpAndSettle();

      expect(find.byType(ContactEditorScreen), findsOneWidget);
    });

    testWidgets('the contact list reaches the editor and the labels', (
      tester,
    ) async {
      final auth = FakeAuthService(initialUser: user);
      addTearDown(auth.dispose);
      final contacts = FakeContactRepository();
      addTearDown(contacts.dispose);
      final labels = FakeRelationshipTypeRepository();
      addTearDown(labels.dispose);
      final hangouts = FakeHangoutRepository();
      addTearDown(hangouts.dispose);
      final plans = FakePlannedHangoutRepository();
      addTearDown(plans.dispose);
      labels.seed(
        RelationshipType(
          id: 'rid-1',
          name: 'Friend',
          sortOrder: 0,
          createdAt: DateTime.utc(2026, 8),
        ),
      );
      contacts.seed(
        Contact(
          id: 'cid-1',
          name: 'Marcus',
          relationshipTypeId: 'rid-1',
          cadence: Cadence.monthly,
          priority: ContactPriority.normal,
          createdAt: DateTime.utc(2026, 8),
          updatedAt: DateTime.utc(2026, 8),
        ),
      );
      final router = buildRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            currentHouseholdIdProvider.overrideWithValue('hid-1'),
            contactRepositoryProvider.overrideWithValue(contacts),
            relationshipTypeRepositoryProvider.overrideWithValue(labels),
            hangoutRepositoryProvider.overrideWithValue(hangouts),
            plannedHangoutRepositoryProvider.overrideWithValue(plans),
          ],
          child: MaterialApp.router(routerConfig: router.config()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(HomeScreen.contactsKey));
      await tester.pumpAndSettle();
      expect(find.byType(ContactsScreen), findsOneWidget);

      await tester.tap(find.byKey(ContactsScreen.labelsKey));
      await tester.pumpAndSettle();
      expect(find.byType(RelationshipTypesScreen), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ContactsScreen.addKey));
      await tester.pumpAndSettle();
      expect(find.text('Add a contact'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Marcus'));
      await tester.pumpAndSettle();
      expect(find.text('Edit contact'), findsOneWidget);
    });

    testWidgets('the home screen reaches the hangouts and the quick log', (
      tester,
    ) async {
      final auth = FakeAuthService(initialUser: user);
      addTearDown(auth.dispose);
      final contacts = FakeContactRepository();
      addTearDown(contacts.dispose);
      final labels = FakeRelationshipTypeRepository();
      addTearDown(labels.dispose);
      final hangouts = FakeHangoutRepository();
      addTearDown(hangouts.dispose);
      final plans = FakePlannedHangoutRepository();
      addTearDown(plans.dispose);
      contacts.seed(
        Contact(
          id: 'cid-1',
          name: 'Marcus',
          relationshipTypeId: 'rid-1',
          cadence: Cadence.monthly,
          priority: ContactPriority.normal,
          createdAt: DateTime.utc(2026, 8),
          updatedAt: DateTime.utc(2026, 8),
        ),
      );
      final router = buildRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            currentHouseholdIdProvider.overrideWithValue('hid-1'),
            contactRepositoryProvider.overrideWithValue(contacts),
            relationshipTypeRepositoryProvider.overrideWithValue(labels),
            hangoutRepositoryProvider.overrideWithValue(hangouts),
            plannedHangoutRepositoryProvider.overrideWithValue(plans),
          ],
          child: MaterialApp.router(routerConfig: router.config()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(HomeScreen.hangoutsKey));
      await tester.pumpAndSettle();
      expect(find.byType(HangoutsScreen), findsOneWidget);

      await tester.tap(find.byKey(HangoutsScreen.logKey));
      await tester.pumpAndSettle();
      expect(find.byType(HangoutEditorScreen), findsOneWidget);
      expect(find.text('Log a hangout'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      hangouts.seed(
        Hangout(
          id: 'hgid-1',
          occurredOn: DateTime.utc(2026, 8, 14),
          contactIds: const ['cid-1'],
          attendeeIds: const [],
          createdBy: user.id,
          createdAt: DateTime.utc(2026, 8, 18),
          updatedAt: DateTime.utc(2026, 8, 18),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Marcus'));
      await tester.pumpAndSettle();

      expect(find.text('Edit hangout'), findsOneWidget);
    });

    testWidgets("the contact editor reaches that contact's history", (
      tester,
    ) async {
      final auth = FakeAuthService(initialUser: user);
      addTearDown(auth.dispose);
      final contacts = FakeContactRepository();
      addTearDown(contacts.dispose);
      final labels = FakeRelationshipTypeRepository();
      addTearDown(labels.dispose);
      final hangouts = FakeHangoutRepository();
      addTearDown(hangouts.dispose);
      final plans = FakePlannedHangoutRepository();
      addTearDown(plans.dispose);
      labels.seed(
        RelationshipType(
          id: 'rid-1',
          name: 'Friend',
          sortOrder: 0,
          createdAt: DateTime.utc(2026, 8),
        ),
      );
      contacts.seed(
        Contact(
          id: 'cid-1',
          name: 'Marcus',
          relationshipTypeId: 'rid-1',
          cadence: Cadence.monthly,
          priority: ContactPriority.normal,
          createdAt: DateTime.utc(2026, 8),
          updatedAt: DateTime.utc(2026, 8),
        ),
      );
      final router = buildRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            currentHouseholdIdProvider.overrideWithValue('hid-1'),
            contactRepositoryProvider.overrideWithValue(contacts),
            relationshipTypeRepositoryProvider.overrideWithValue(labels),
            hangoutRepositoryProvider.overrideWithValue(hangouts),
            plannedHangoutRepositoryProvider.overrideWithValue(plans),
          ],
          child: MaterialApp.router(routerConfig: router.config()),
        ),
      );
      await tester.pumpAndSettle();

      unawaited(router.push(ContactEditorRoute(contactId: 'cid-1')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(ContactEditorScreen.historyKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ContactEditorScreen.historyKey));
      await tester.pumpAndSettle();

      expect(find.byType(HangoutsScreen), findsOneWidget);
      expect(find.text('Nothing logged with Marcus yet.'), findsOneWidget);
    });

    testWidgets("a suggestion card reaches that contact's history", (
      tester,
    ) async {
      final auth = FakeAuthService(initialUser: user);
      addTearDown(auth.dispose);
      final contacts = FakeContactRepository();
      addTearDown(contacts.dispose);
      final labels = FakeRelationshipTypeRepository();
      addTearDown(labels.dispose);
      final hangouts = FakeHangoutRepository();
      addTearDown(hangouts.dispose);
      final plans = FakePlannedHangoutRepository();
      addTearDown(plans.dispose);
      // Nothing logged, so the contact is suggested with no reading at all,
      // which is the state that most wants a way through to logging one.
      contacts.seed(
        Contact(
          id: 'cid-1',
          name: 'Marcus',
          relationshipTypeId: 'rid-1',
          cadence: Cadence.monthly,
          priority: ContactPriority.normal,
          createdAt: DateTime.utc(2026, 8),
          updatedAt: DateTime.utc(2026, 8),
        ),
      );
      final router = buildRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            currentHouseholdIdProvider.overrideWithValue('hid-1'),
            contactRepositoryProvider.overrideWithValue(contacts),
            relationshipTypeRepositoryProvider.overrideWithValue(labels),
            hangoutRepositoryProvider.overrideWithValue(hangouts),
            plannedHangoutRepositoryProvider.overrideWithValue(plans),
          ],
          child: MaterialApp.router(routerConfig: router.config()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(HomeScreen.cardKey('cid-1')), findsOneWidget);
      await tester.tap(find.text('Marcus'));
      await tester.pumpAndSettle();

      expect(find.byType(HangoutsScreen), findsOneWidget);
      expect(find.text('Hangouts with Marcus'), findsOneWidget);
    });

    testWidgets('an empty Reconnect section reaches the contact list', (
      tester,
    ) async {
      final auth = FakeAuthService(initialUser: user);
      addTearDown(auth.dispose);
      final contacts = FakeContactRepository();
      addTearDown(contacts.dispose);
      final labels = FakeRelationshipTypeRepository();
      addTearDown(labels.dispose);
      final hangouts = FakeHangoutRepository();
      addTearDown(hangouts.dispose);
      final plans = FakePlannedHangoutRepository();
      addTearDown(plans.dispose);
      final router = buildRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            currentHouseholdIdProvider.overrideWithValue('hid-1'),
            contactRepositoryProvider.overrideWithValue(contacts),
            relationshipTypeRepositoryProvider.overrideWithValue(labels),
            hangoutRepositoryProvider.overrideWithValue(hangouts),
            plannedHangoutRepositoryProvider.overrideWithValue(plans),
          ],
          child: MaterialApp.router(routerConfig: router.config()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add contacts'));
      await tester.pumpAndSettle();

      expect(find.byType(ContactsScreen), findsOneWidget);
    });

    testWidgets('the home screen action reaches the household', (
      tester,
    ) async {
      final auth = FakeAuthService(initialUser: user);
      addTearDown(auth.dispose);
      final households = FakeHouseholdRepository();
      addTearDown(households.dispose);
      await households.createHousehold(
        name: 'The Marx house',
        owner: user,
        displayName: 'Brian',
      );
      final router = buildRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            householdRepositoryProvider.overrideWithValue(households),
          ],
          child: MaterialApp.router(routerConfig: router.config()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(HomeScreen.householdKey));
      await tester.pumpAndSettle();

      expect(find.byType(HouseholdScreen), findsOneWidget);
    });
  });

  group('appRouterProvider', () {
    ProviderContainer harness(FakeAuthService auth) {
      final container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);
      // The provider's auth subscription only runs while something listens to
      // it, which in the app is KithApp watching it.
      final subscription = container.listen(appRouterProvider, (_, _) {});
      addTearDown(subscription.close);
      return container;
    }

    test('exposes an AppRouter behind the auth guard', () {
      final auth = FakeAuthService();
      addTearDown(auth.dispose);
      final container = harness(auth);

      final router = container.read(appRouterProvider);

      expect(router, isA<AppRouter>());
      expect(router.authGuard, isA<AuthGuard>());
    });

    test('returns the same instance across reads', () {
      final auth = FakeAuthService();
      addTearDown(auth.dispose);
      final container = harness(auth);

      expect(
        container.read(appRouterProvider),
        same(container.read(appRouterProvider)),
      );
    });

    test('subscribes to the auth state so guards can be re-run', () async {
      final auth = FakeAuthService(initialUser: user);
      addTearDown(auth.dispose);
      final container = harness(auth);

      await container.read(authStateChangesProvider.future);

      expect(container.read(currentUserProvider), user);
    });
  });
}
