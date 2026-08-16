import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/auth/presentation/sign_in_screen.dart';
import 'package:kith/features/contacts/presentation/contacts_screen.dart';
import 'package:kith/features/suggestions/presentation/home_screen.dart';
import 'package:kith/routing/guards/auth_guard.dart';

part 'app_router.gr.dart';

/// The app's route graph.
///
/// Routes are declared here and nowhere else; navigation always goes through
/// the generated typed `*Route` classes rather than raw path strings.
/// Everything that reads household data is guarded; the sign-in screen is the
/// one route an unauthenticated user may reach. The household-membership
/// guard joins them once households can be created.
@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  AppRouter({required this.authGuard});

  /// Gate on every route that needs a signed-in user.
  final AutoRouteGuard authGuard;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(
      page: HomeRoute.page,
      path: '/',
      initial: true,
      guards: [
        authGuard,
      ],
    ),
    AutoRoute(page: ContactsRoute.page, path: '/contacts', guards: [authGuard]),
    AutoRoute(page: SignInRoute.page, path: '/sign-in'),
  ];
}

/// Holds the single [AppRouter] instance for the app's lifetime.
///
/// Re-runs the guards whenever the signed-in identity changes: that is what
/// sends an open session to the sign-in screen on sign-out, and what releases
/// the navigation the guard is holding once someone signs in. Emissions that
/// do not change who is signed in are ignored, so the router is not disturbed
/// by the stream simply reporting what it already reported.
final appRouterProvider = Provider<AppRouter>((ref) {
  final router = AppRouter(authGuard: AuthGuard(ref));
  ref.listen(authStateChangesProvider, (previous, next) {
    if (!next.hasValue || previous?.value?.id == next.value?.id) return;
    unawaited(router.reevaluateGuards());
  });
  return router;
});
