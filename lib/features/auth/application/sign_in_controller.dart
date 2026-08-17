import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/auth/application/sign_in_state.dart';
import 'package:kith/features/auth/domain/credential_validator.dart';

/// Drives the sign-in form.
///
/// Owns the submission state and the failure to show; it never navigates.
/// A successful attempt changes the signed-in identity, and the route guard
/// reacts to that, so nothing here needs to know where the user ends up.
class SignInController extends Notifier<SignInState> {
  @override
  SignInState build() => const SignInState();

  /// Switches the form between signing in and creating an account.
  ///
  /// Feedback from the previous mode is dropped: a "wrong password" from a
  /// sign-in attempt says nothing about the sign-up now on screen.
  void setMode(SignInMode mode) {
    if (state.mode == mode) return;
    state = SignInState(mode: mode);
  }

  /// Submits [email] and [password] under the current mode.
  ///
  /// Ignored while an attempt is already in flight, so a double tap cannot
  /// create two accounts.
  Future<void> submit({required String email, required String password}) async {
    if (state.isSubmitting) return;
    final address = email.trim();
    final mode = state.mode;
    state = state.copyWith(
      isSubmitting: true,
      clearFailure: true,
      clearPasswordResetSentTo: true,
    );

    final auth = ref.read(authServiceProvider);
    final result = switch (mode) {
      SignInMode.signIn => await auth.signInWithEmail(
        email: address,
        password: password,
      ),
      SignInMode.signUp => await auth.signUpWithEmail(
        email: address,
        password: password,
      ),
    };

    state = switch (result) {
      // The guard replaces this screen on success; what it leaves behind is a
      // clean form rather than the state of the attempt that got past it.
      Ok() => const SignInState(),
      Err(:final failure) => state.copyWith(
        isSubmitting: false,
        failure: _asAuthFailure(failure),
      ),
    };
  }

  /// Sends a password reset link to [email].
  ///
  /// The address is validated here because the reset button does not run the
  /// form's validators: it is reachable with an untouched password field.
  Future<void> sendPasswordReset(String email) async {
    if (state.isSubmitting) return;
    final address = email.trim();
    final invalid = CredentialValidator.email(address);
    if (invalid != null) {
      state = state.copyWith(
        failure: AuthFailure(AuthFailureReason.invalidEmail, invalid),
        clearPasswordResetSentTo: true,
      );
      return;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearFailure: true,
      clearPasswordResetSentTo: true,
    );
    final auth = ref.read(authServiceProvider);
    final result = await auth.sendPasswordResetEmail(address);
    state = result.fold(
      onOk: (_) =>
          state.copyWith(isSubmitting: false, passwordResetSentTo: address),
      onErr: (failure) =>
          state.copyWith(isSubmitting: false, failure: _asAuthFailure(failure)),
    );
  }

  /// Widens any [Failure] to the [AuthFailure] the screen knows how to render.
  ///
  /// A [NetworkFailure] keeps its meaning on the way through. Collapsing it
  /// into [AuthFailureReason.unknown] would tell someone with no signal that
  /// something went wrong, which is true of every failure there is.
  static AuthFailure _asAuthFailure(Failure failure) => switch (failure) {
    final AuthFailure authFailure => authFailure,
    NetworkFailure() => AuthFailure(
      AuthFailureReason.network,
      failure.message,
    ),
    _ => AuthFailure(AuthFailureReason.unknown, failure.message),
  };
}

/// State of the sign-in form.
final signInControllerProvider =
    NotifierProvider<SignInController, SignInState>(SignInController.new);
