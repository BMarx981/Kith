import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/features/household/application/household_providers.dart';
import 'package:kith/routing/app_router.dart';

/// Keeps a signed-in user without a household off the screens that read one.
///
/// Holds the refused navigation open rather than cancelling it, the same way
/// the auth guard does: onboarding is shown in the destination's place, and
/// once a household is created or joined `appRouterProvider` re-runs the
/// guards, which resolves the held navigation and drops the onboarding page.
/// That is what carries a new member to the screen they originally asked for.
///
/// Runs after the auth guard, so there is always a signed-in user by the time
/// it is consulted.
class HouseholdGuard extends AutoRouteGuard {
  /// Reads the membership through a ref that outlives every navigation.
  HouseholdGuard(this._ref);

  final Ref _ref;

  /// The navigation parked behind onboarding, if there is one.
  NavigationResolver? _held;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    // Waiting on the first emission is what stops a cold start bouncing an
    // existing member into onboarding: until the membership query answers,
    // "no household" and "not asked yet" look alike.
    final householdIds = await _ref.read(householdIdsProvider.future);
    if (householdIds.isNotEmpty) {
      if (identical(_held, resolver)) _held = null;
      resolver.next();
      return;
    }
    // A re-run of the navigation that is already parked: leave it parked.
    if (identical(_held, resolver)) return;
    // Something else asked to navigate while onboarding is already on screen.
    // Refusing it keeps one held navigation and one onboarding page.
    if (_held?.isResolved == false) {
      resolver.next(false);
      return;
    }
    _held = resolver;
    // Deliberately not awaited, for the reason spelled out in `AuthGuard`:
    // resolving this resolver is the job of the next run of this guard, which
    // cannot start until this call returns.
    resolver.redirectUntil(const HouseholdOnboardingRoute());
  }
}
