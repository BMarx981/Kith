import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/contacts/presentation/contacts_screen.dart';
import 'package:kith/features/suggestions/presentation/home_screen.dart';
import 'package:kith/routing/app_router.dart';
import 'package:kith/routing/guards/auth_guard.dart';

import '../helpers/fake_auth_service.dart';

/// Stands in for the auth guard so these tests describe the route graph
/// rather than who is signed in; the guard has its own suite.
class _OpenGuard extends AutoRouteGuard {
  const _OpenGuard();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) =>
      resolver.next();
}

void main() {
  const user = AuthUser(id: 'uid-1', email: 'brian@example.com');

  AppRouter buildRouter() => AppRouter(authGuard: const _OpenGuard());

  group('AppRouter', () {
    test('declares its routes at stable paths', () {
      final paths = {
        for (final route in buildRouter().routes) route.name: route.path,
      };

      expect(paths, {
        'HomeRoute': '/',
        'ContactsRoute': '/contacts',
        'SignInRoute': '/sign-in',
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
          route.name: route.guards.isNotEmpty,
      };

      expect(guarded, {
        'HomeRoute': true,
        'ContactsRoute': true,
        'SignInRoute': false,
      });
    });

    testWidgets('resolves the initial path to the home screen', (tester) async {
      final router = buildRouter();

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router.config()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('navigates to contacts via the generated typed route', (
      tester,
    ) async {
      final router = buildRouter();

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router.config()),
      );
      await tester.pumpAndSettle();

      // push() completes when the route is popped, so it is deliberately
      // not awaited here.
      unawaited(router.push(const ContactsRoute()));
      await tester.pumpAndSettle();

      expect(find.byType(ContactsScreen), findsOneWidget);
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
