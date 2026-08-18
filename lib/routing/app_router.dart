import 'dart:async';

import 'package:auto_route/auto_route.dart';
// Key, referenced by the generated route arguments class for the one
// route that takes a parameter. The part file has no imports of its own.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/auth/presentation/sign_in_screen.dart';
import 'package:kith/features/contacts/presentation/contact_editor_screen.dart';
import 'package:kith/features/contacts/presentation/contacts_screen.dart';
import 'package:kith/features/contacts/presentation/relationship_types_screen.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/features/household/presentation/household_onboarding_screen.dart';
import 'package:kith/features/household/presentation/household_screen.dart';
import 'package:kith/features/suggestions/presentation/home_screen.dart';
import 'package:kith/routing/guards/auth_guard.dart';
import 'package:kith/routing/guards/household_guard.dart';

part 'app_router.gr.dart';

/// The app's route graph.
///
/// Routes are declared here and nowhere else; navigation always goes through
/// the generated typed `*Route` classes rather than raw path strings.
/// Everything that reads household data is guarded twice: the auth guard
/// first, then the household guard. The sign-in screen is the one route an
/// unauthenticated user may reach, and onboarding is the one route a signed-in
/// user without a household may reach.
@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  AppRouter({required this.authGuard, required this.householdGuard});

  /// Gate on every route that needs a signed-in user.
  final AutoRouteGuard authGuard;

  /// Gate on every route that reads a household, run after [authGuard].
  final AutoRouteGuard householdGuard;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomeRoute.page,
      path: '/',
      initial: true,
      guards: [
        authGuard,
        householdGuard,
      ],
    ),
    AutoRoute(
      page: ContactsRoute.page,
      path: '/contacts',
      guards: [authGuard, householdGuard],
    ),
    AutoRoute(
      page: ContactEditorRoute.page,
      // The add form and the edit form are the same screen, so they are the
      // same route: the segment is absent when there is nothing to edit yet.
      path: '/contacts/edit/:contactId',
      guards: [authGuard, householdGuard],
    ),
    AutoRoute(
      page: RelationshipTypesRoute.page,
      path: '/contacts/labels',
      guards: [authGuard, householdGuard],
    ),
    AutoRoute(
      page: HouseholdRoute.page,
      path: '/household',
      guards: [authGuard, householdGuard],
    ),
    AutoRoute(page: SignInRoute.page, path: '/sign-in'),
    AutoRoute(
      page: HouseholdOnboardingRoute.page,
      path: '/welcome',
      guards: [authGuard],
    ),
  ];
}

/// Holds the single [AppRouter] instance for the app's lifetime.
///
/// Re-runs the guards whenever the signed-in identity changes: that is what
/// sends an open session to the sign-in screen on sign-out, and what releases
/// the navigation the guard is holding once someone signs in. Emissions that
/// do not change who is signed in are ignored, so the router is not disturbed
/// by the stream simply reporting what it already reported.
///
/// Membership is watched for the same reason, and the subscription does double
/// duty: the household guard reads the membership query, which only runs while
/// something listens to it, and this is what listens.
final appRouterProvider = Provider<AppRouter>((ref) {
  final router = AppRouter(
    authGuard: AuthGuard(ref),
    householdGuard: HouseholdGuard(ref),
  );
  ref
    ..listen(authStateChangesProvider, (previous, next) {
      if (!next.hasValue || previous?.value?.id == next.value?.id) return;
      unawaited(router.reevaluateGuards());
    })
    ..listen(currentHouseholdIdProvider, (previous, next) {
      if (previous == next) return;
      unawaited(router.reevaluateGuards());
    });
  return router;
});
