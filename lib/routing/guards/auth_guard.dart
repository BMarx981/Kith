import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/routing/app_router.dart';

/// Keeps unauthenticated users off the household's screens.
///
/// A refused navigation is held open rather than cancelled: the sign-in screen
/// is shown in the destination's place, and when the identity changes
/// `appRouterProvider` re-runs the guards, which resolves the held navigation
/// and drops the sign-in page. That is what carries a user to the screen they
/// originally asked for instead of a fixed landing page.
class AuthGuard extends AutoRouteGuard {
  /// Reads the auth state through a ref that outlives every navigation.
  AuthGuard(this._ref);

  final Ref _ref;

  /// The navigation parked behind the sign-in screen, if there is one.
  NavigationResolver? _held;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    // Waiting on the first emission is what makes a cold start with a stored
    // session land on the requested screen: treating "not reported yet" as
    // signed out would bounce a returning user to the sign-in form. The router
    // shows its placeholder for the beat this takes.
    final user = await _ref.read(authStateChangesProvider.future);
    if (user != null) {
      if (identical(_held, resolver)) _held = null;
      resolver.next();
      return;
    }
    // A re-run of the navigation that is already parked: leave it parked.
    if (identical(_held, resolver)) return;
    // Something else asked to navigate while sign-in is already on screen.
    // Refusing it keeps one held navigation and one sign-in page, so signing
    // in lands on the screen that was asked for first rather than on a stack
    // of stale redirects.
    if (_held?.isResolved == false) {
      resolver.next(false);
      return;
    }
    _held = resolver;
    // Deliberately not awaited. `redirectUntil` only returns once the resolver
    // is resolved, and resolving it is the job of the *next* run of this
    // guard, which cannot start until this call returns.
    resolver.redirectUntil(const SignInRoute());
  }
}
