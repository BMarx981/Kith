import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/features/contacts/presentation/contacts_screen.dart';
import 'package:kith/features/suggestions/presentation/home_screen.dart';
import 'package:kith/routing/app_router.dart';

void main() {
  group('AppRouter', () {
    test('declares the M0 skeleton routes at stable paths', () {
      final paths = {
        for (final route in AppRouter().routes) route.name: route.path,
      };

      expect(paths, {
        'HomeRoute': '/',
        'ContactsRoute': '/contacts',
        'SignInRoute': '/sign-in',
      });
    });

    test('starts at the home route', () {
      final initial = AppRouter().routes.where((r) => r.initial).toList();

      expect(initial, hasLength(1));
      expect(initial.single.name, 'HomeRoute');
    });

    testWidgets('resolves the initial path to the home screen', (tester) async {
      final router = AppRouter();

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router.config()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('navigates to contacts via the generated typed route', (
      tester,
    ) async {
      final router = AppRouter();

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
    test('exposes an AppRouter', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(appRouterProvider), isA<AppRouter>());
    });

    test('returns the same instance across reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(appRouterProvider),
        same(container.read(appRouterProvider)),
      );
    });
  });
}
