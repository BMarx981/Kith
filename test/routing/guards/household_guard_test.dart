import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/app.dart';
import 'package:kith/app/widgets/app_splash.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/auth/presentation/sign_in_screen.dart';
import 'package:kith/features/contacts/presentation/contacts_screen.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/household/presentation/household_onboarding_screen.dart';
import 'package:kith/features/suggestions/presentation/home_screen.dart';
import 'package:kith/routing/app_router.dart';

import '../../helpers/fake_auth_service.dart';
import '../../helpers/fake_household_repository.dart';

/// A fake whose membership query stays silent until the test releases it,
/// which is what a cold start looks like while the query is in flight.
class _SlowHouseholdRepository extends FakeHouseholdRepository {
  final answered = Completer<void>();

  @override
  Stream<List<String>> watchHouseholdIdsFor(String uid) async* {
    await answered.future;
    yield* super.watchHouseholdIdsFor(uid);
  }
}

void main() {
  const user = AuthUser(id: 'uid-1', email: 'brian@example.com');

  late FakeAuthService auth;

  setUp(() {
    auth = FakeAuthService(initialUser: user);
    addTearDown(auth.dispose);
  });

  // Pumps the real app rather than a stand-in router, for the reason given in
  // the auth guard suite: the guard reads providers through
  // `appRouterProvider`, which only runs while `KithApp` watches it.
  Future<AppRouter> pumpRouterApp(
    WidgetTester tester,
    FakeHouseholdRepository households,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        householdRepositoryProvider.overrideWithValue(households),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const KithApp()),
    );
    return container.read(appRouterProvider);
  }

  FakeHouseholdRepository emptyRepository() {
    final households = FakeHouseholdRepository();
    addTearDown(households.dispose);
    return households;
  }

  Future<FakeHouseholdRepository> repositoryWithHousehold() async {
    final households = emptyRepository();
    await households.createHousehold(
      name: 'The Marx house',
      owner: user,
      displayName: 'Brian',
    );
    return households;
  }

  group('HouseholdGuard', () {
    testWidgets('sends a user with no household to onboarding', (tester) async {
      await pumpRouterApp(tester, emptyRepository());
      await tester.pumpAndSettle();

      expect(find.byType(HouseholdOnboardingScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('lets a member through to the requested screen', (
      tester,
    ) async {
      await pumpRouterApp(tester, await repositoryWithHousehold());
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(HouseholdOnboardingScreen), findsNothing);
    });

    testWidgets('waits on the membership query rather than assuming none', (
      tester,
    ) async {
      final households = _SlowHouseholdRepository();
      addTearDown(households.dispose);
      await households.createHousehold(
        name: 'The Marx house',
        owner: user,
        displayName: 'Brian',
      );

      await pumpRouterApp(tester, households);
      await tester.pump();

      expect(find.byType(AppSplash), findsOneWidget);
      expect(find.byType(HouseholdOnboardingScreen), findsNothing);

      households.answered.complete();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('runs behind the auth guard, not instead of it', (
      tester,
    ) async {
      await auth.signOut();

      await pumpRouterApp(tester, emptyRepository());
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(HouseholdOnboardingScreen), findsNothing);
    });

    testWidgets('creating a household releases the held navigation', (
      tester,
    ) async {
      final households = emptyRepository();
      final router = await pumpRouterApp(tester, households);
      await tester.pumpAndSettle();
      expect(find.byType(HouseholdOnboardingScreen), findsOneWidget);

      await households.createHousehold(
        name: 'The Marx house',
        owner: user,
        displayName: 'Brian',
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(HouseholdOnboardingScreen), findsNothing);
      // No stale onboarding page underneath to come back on a system back.
      expect(router.stack.map((page) => page.routeData.name), ['HomeRoute']);
    });

    testWidgets('a membership query that fails lands somewhere', (
      tester,
    ) async {
      // The navigation has to be resolved either way. Left unresolved, the
      // app sits on the splash for ever with nothing to act on.
      final households = emptyRepository()
        ..membershipFailure = const PermissionFailure('refused');

      await pumpRouterApp(tester, households);
      await tester.pumpAndSettle();

      expect(find.byType(AppSplash), findsNothing);
      expect(find.byType(HouseholdOnboardingScreen), findsOneWidget);
    });

    testWidgets('a membership query that recovers releases the hold', (
      tester,
    ) async {
      final households = emptyRepository()
        ..membershipFailure = const PermissionFailure('refused');
      final router = await pumpRouterApp(tester, households);
      await tester.pumpAndSettle();
      expect(find.byType(HouseholdOnboardingScreen), findsOneWidget);

      households.membershipFailure = null;
      await households.createHousehold(
        name: 'The Marx house',
        owner: user,
        displayName: 'Brian',
      );
      await tester.tap(find.byKey(HouseholdOnboardingScreen.retryKey));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(router.stack.map((page) => page.routeData.name), ['HomeRoute']);
    });

    testWidgets('guards the deeper screens too, not just the landing one', (
      tester,
    ) async {
      final router = await pumpRouterApp(tester, emptyRepository());
      await tester.pumpAndSettle();

      unawaited(router.push(const ContactsRoute()));
      await tester.pumpAndSettle();

      expect(find.byType(ContactsScreen), findsNothing);
      expect(find.byType(HouseholdOnboardingScreen), findsOneWidget);
    });

    testWidgets('refuses to stack a second onboarding over the first', (
      tester,
    ) async {
      final households = emptyRepository();
      final router = await pumpRouterApp(tester, households);
      await tester.pumpAndSettle();

      unawaited(router.push(const ContactsRoute()));
      await tester.pumpAndSettle();

      expect(find.byType(HouseholdOnboardingScreen), findsOneWidget);

      await households.createHousehold(
        name: 'The Marx house',
        owner: user,
        displayName: 'Brian',
      );
      await tester.pumpAndSettle();

      // The navigation held first wins, and nothing stale is left behind it.
      expect(router.stack.map((page) => page.routeData.name), ['HomeRoute']);
    });
  });
}
