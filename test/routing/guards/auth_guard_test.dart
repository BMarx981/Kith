import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/app/app.dart';
import 'package:kith/app/widgets/app_splash.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/auth/presentation/sign_in_screen.dart';
import 'package:kith/features/contacts/presentation/contacts_screen.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/suggestions/presentation/home_screen.dart';
import 'package:kith/routing/app_router.dart';

import '../../helpers/fake_auth_service.dart';
import '../../helpers/fake_household_repository.dart';

/// A fake whose auth stream stays silent until the test releases it, which is
/// what a cold start looks like while Firebase restores a stored session.
class _SlowAuthService extends FakeAuthService {
  _SlowAuthService({super.initialUser});

  final restored = Completer<void>();

  @override
  Stream<AuthUser?> authStateChanges() async* {
    await restored.future;
    yield* super.authStateChanges();
  }
}

/// A fake whose auth stream the test drives by hand, errors included.
///
/// Errors do not close it, which is how `Stream.map` behaves over the stream
/// Firebase hands back: a later sign-in still arrives on the same
/// subscription.
class _DrivenAuthService extends FakeAuthService {
  final controller = StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> authStateChanges() => controller.stream;

  @override
  Future<void> dispose() async {
    await controller.close();
    await super.dispose();
  }
}

void main() {
  const user = AuthUser(id: 'uid-1', email: 'brian@example.com');

  late FakeHouseholdRepository households;

  // Every signed-in user in this suite already has a household, so the
  // household guard waves them through and what these tests observe is the
  // auth guard alone. The uid matches the one `FakeAuthService` hands the
  // first seeded account, so a sign-in mid-test lands on the same membership.
  setUp(() async {
    households = FakeHouseholdRepository();
    addTearDown(households.dispose);
    await households.createHousehold(
      name: 'The Marx house',
      owner: user,
      displayName: 'Brian',
    );
  });

  // Pumps the real app rather than a stand-in router: the guard reads the
  // auth state through `appRouterProvider`, whose subscriptions Riverpod keeps
  // paused until something watches it, and watching it is `KithApp`'s job.
  Future<AppRouter> pumpRouterApp(
    WidgetTester tester,
    FakeAuthService auth,
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

  group('AuthGuard', () {
    testWidgets('sends a signed-out user to sign-in', (tester) async {
      final auth = FakeAuthService();
      addTearDown(auth.dispose);

      await pumpRouterApp(tester, auth);
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('lets a signed-in user through to the requested screen', (
      tester,
    ) async {
      final auth = FakeAuthService(initialUser: user);
      addTearDown(auth.dispose);

      await pumpRouterApp(tester, auth);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
    });

    testWidgets('waits on the session restore instead of assuming signed out', (
      tester,
    ) async {
      final auth = _SlowAuthService(initialUser: user);
      addTearDown(auth.dispose);

      await pumpRouterApp(tester, auth);
      await tester.pump();

      expect(find.byType(AppSplash), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);

      auth.restored.complete();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('a restore that finds nobody lands on sign-in', (tester) async {
      final auth = _SlowAuthService();
      addTearDown(auth.dispose);

      await pumpRouterApp(tester, auth);
      await tester.pump();
      expect(find.byType(AppSplash), findsOneWidget);

      auth.restored.complete();
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('signing in releases the navigation the guard held', (
      tester,
    ) async {
      final auth = FakeAuthService()
        ..seedAccount(email: user.email, password: 'hunter22');
      addTearDown(auth.dispose);
      final router = await pumpRouterApp(tester, auth);
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);

      await auth.signInWithEmail(email: user.email, password: 'hunter22');
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
      // No stale sign-in page underneath to come back on a system back.
      expect(router.stack.map((page) => page.routeData.name), ['HomeRoute']);
    });

    testWidgets('signing out puts the sign-in screen back', (tester) async {
      final auth = FakeAuthService(initialUser: user);
      addTearDown(auth.dispose);
      await pumpRouterApp(tester, auth);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      await auth.signOut();
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('an auth stream that fails lands somewhere', (tester) async {
      // The navigation has to be resolved either way. Left unresolved, the
      // app sits on the splash for ever with nothing to act on. Sign-in is
      // where it lands because signing in is what fixes it.
      final auth = _DrivenAuthService();
      addTearDown(auth.dispose);
      await pumpRouterApp(tester, auth);

      auth.controller.addError(StateError('auth unavailable'));
      await tester.pumpAndSettle();

      expect(find.byType(AppSplash), findsNothing);
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('a session arriving after a failure is let through', (
      tester,
    ) async {
      final auth = _DrivenAuthService();
      addTearDown(auth.dispose);
      await pumpRouterApp(tester, auth);
      auth.controller.addError(StateError('auth unavailable'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);

      auth.controller.add(user);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SignInScreen), findsNothing);
    });

    testWidgets('guards the deeper screens too, not just the landing one', (
      tester,
    ) async {
      final auth = FakeAuthService();
      addTearDown(auth.dispose);
      final router = await pumpRouterApp(tester, auth);
      await tester.pumpAndSettle();

      unawaited(router.push(const ContactsRoute()));
      await tester.pumpAndSettle();

      expect(find.byType(ContactsScreen), findsNothing);
      expect(find.byType(SignInScreen), findsOneWidget);
    });

    testWidgets('refuses to stack a second sign-in over the first', (
      tester,
    ) async {
      final auth = FakeAuthService()
        ..seedAccount(email: user.email, password: 'hunter22');
      addTearDown(auth.dispose);
      final router = await pumpRouterApp(tester, auth);
      await tester.pumpAndSettle();

      unawaited(router.push(const ContactsRoute()));
      await tester.pumpAndSettle();

      expect(find.byType(SignInScreen), findsOneWidget);

      await auth.signInWithEmail(email: user.email, password: 'hunter22');
      await tester.pumpAndSettle();

      // The navigation held first wins, and nothing stale is left behind it.
      expect(router.stack.map((page) => page.routeData.name), ['HomeRoute']);
    });
  });
}
