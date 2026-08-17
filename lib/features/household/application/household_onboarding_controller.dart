import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/household/application/household_onboarding_state.dart';
import 'package:kith/features/household/application/household_providers.dart';

/// Drives the create-or-join form a user without a household lands on.
///
/// Owns the submission state and the failure to show; it never navigates.
/// A successful attempt writes the membership the household guard is waiting
/// on, and the guard reacts to that, so nothing here needs to know where the
/// user ends up.
class HouseholdOnboardingController
    extends Notifier<HouseholdOnboardingState> {
  @override
  HouseholdOnboardingState build() => const HouseholdOnboardingState();

  /// Switches the form between creating and joining.
  ///
  /// Feedback from the previous mode is dropped: "that code matches no
  /// household" says nothing about the create form now on screen.
  void setMode(HouseholdOnboardingMode mode) {
    if (state.mode == mode) return;
    state = HouseholdOnboardingState(mode: mode);
  }

  /// Creates a household called [name], with the signed-in user as its owner
  /// and [displayName] as the name their partner will see.
  Future<void> createHousehold({
    required String name,
    required String displayName,
  }) => _submit(
    (user) => ref
        .read(householdRepositoryProvider)
        .createHousehold(name: name, owner: user, displayName: displayName),
  );

  /// Joins the household [code] points at, as [displayName].
  Future<void> joinHousehold({
    required String code,
    required String displayName,
  }) => _submit(
    (user) => ref
        .read(householdRepositoryProvider)
        .joinWithInviteCode(code: code, user: user, displayName: displayName),
  );

  /// Runs [attempt] for the signed-in user, holding the form inert until it
  /// settles so a double tap cannot create two households.
  Future<void> _submit(Future<Result<Object?>> Function(AuthUser) attempt)
  async {
    if (state.isSubmitting) return;
    // Asked of the auth service rather than the auth stream provider: this
    // screen sits behind the auth guard, so the session is already restored,
    // and the service answers without depending on whether anything else
    // happens to be listening to the stream.
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      // Only reachable if the session ended between the screen opening and
      // the button being tapped; the auth guard keeps everyone else out.
      state = state.copyWith(failure: _signedOut);
      return;
    }

    state = state.copyWith(isSubmitting: true, clearFailure: true);
    final result = await attempt(user);
    if (result case Err(:final failure)) {
      state = state.copyWith(isSubmitting: false, failure: failure);
      return;
    }

    // The membership query is a collection group read that was already
    // running and matched nothing; re-running it is what turns this success
    // into the guard letting the user through, without waiting on the
    // backend to push the new document.
    ref.invalidate(householdIdsProvider);
    state = HouseholdOnboardingState(mode: state.mode);
  }

  static const _signedOut = PermissionFailure('Sign in again to continue.');
}

/// State of the create-or-join form.
final householdOnboardingControllerProvider =
    NotifierProvider<HouseholdOnboardingController, HouseholdOnboardingState>(
      HouseholdOnboardingController.new,
    );
