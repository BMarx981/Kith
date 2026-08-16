import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/features/auth/application/sign_in_state.dart';

void main() {
  const failure = AuthFailure(
    AuthFailureReason.invalidCredentials,
    'no match',
  );

  group('SignInState', () {
    test('defaults to an idle sign-in form with nothing to report', () {
      const state = SignInState();

      expect(state.mode, SignInMode.signIn);
      expect(state.isSubmitting, isFalse);
      expect(state.failure, isNull);
      expect(state.passwordResetSentTo, isNull);
    });

    test('copyWith replaces each field', () {
      const state = SignInState();

      expect(state.copyWith(mode: SignInMode.signUp).mode, SignInMode.signUp);
      expect(state.copyWith(isSubmitting: true).isSubmitting, isTrue);
      expect(state.copyWith(failure: failure).failure, failure);
      expect(
        state.copyWith(passwordResetSentTo: 'a@b.com').passwordResetSentTo,
        'a@b.com',
      );
    });

    test('copyWith keeps fields it is not given', () {
      const state = SignInState(
        mode: SignInMode.signUp,
        isSubmitting: true,
        failure: failure,
        passwordResetSentTo: 'a@b.com',
      );

      expect(state.copyWith(), state);
    });

    test('clear flags null out what copyWith cannot', () {
      const state = SignInState(
        failure: failure,
        passwordResetSentTo: 'a@b.com',
      );

      final cleared = state.copyWith(
        clearFailure: true,
        clearPasswordResetSentTo: true,
      );

      expect(cleared.failure, isNull);
      expect(cleared.passwordResetSentTo, isNull);
    });

    test('clear flags win over a replacement value', () {
      const state = SignInState();

      final cleared = state.copyWith(failure: failure, clearFailure: true);

      expect(cleared.failure, isNull);
    });

    test('equal states compare equal and hash alike', () {
      const a = SignInState(mode: SignInMode.signUp, failure: failure);
      const b = SignInState(mode: SignInMode.signUp, failure: failure);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differing states compare unequal', () {
      const base = SignInState();

      expect(base, isNot(base.copyWith(mode: SignInMode.signUp)));
      expect(base, isNot(base.copyWith(isSubmitting: true)));
      expect(base, isNot(base.copyWith(failure: failure)));
      expect(base, isNot(base.copyWith(passwordResetSentTo: 'a@b.com')));
    });

    test('toString names the mode and carries the feedback', () {
      const state = SignInState(
        mode: SignInMode.signUp,
        failure: failure,
        passwordResetSentTo: 'a@b.com',
      );

      expect(
        state.toString(),
        'SignInState(mode: signUp, isSubmitting: false, '
        'failure: AuthFailure(invalidCredentials: no match), '
        'passwordResetSentTo: a@b.com)',
      );
    });
  });
}
