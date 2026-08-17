import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/services/auth_service.dart';
import 'package:kith/features/auth/application/auth_providers.dart';
import 'package:kith/features/auth/application/sign_in_controller.dart';
import 'package:kith/features/auth/application/sign_in_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_auth_service.dart';

class _MockAuthService extends Mock implements AuthService {}

void main() {
  ({ProviderContainer container, FakeAuthService auth, SignInController it})
  harness() {
    final auth = FakeAuthService();
    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    addTearDown(auth.dispose);
    return (
      container: container,
      auth: auth,
      it: container.read(signInControllerProvider.notifier),
    );
  }

  SignInState stateOf(ProviderContainer container) =>
      container.read(signInControllerProvider);

  group('SignInController.setMode', () {
    test('starts on the sign-in form', () {
      final h = harness();

      expect(stateOf(h.container).mode, SignInMode.signIn);
    });

    test('switches to sign-up', () {
      final h = harness();

      h.it.setMode(SignInMode.signUp);

      expect(stateOf(h.container).mode, SignInMode.signUp);
    });

    test('drops feedback from the mode being left behind', () async {
      final h = harness();
      await h.it.submit(email: 'nobody@example.com', password: 'hunter22');
      expect(stateOf(h.container).failure, isNotNull);

      h.it.setMode(SignInMode.signUp);

      expect(stateOf(h.container).failure, isNull);
    });

    test('setting the mode it is already in changes nothing', () async {
      final h = harness();
      await h.it.submit(email: 'nobody@example.com', password: 'hunter22');
      final before = stateOf(h.container);

      h.it.setMode(SignInMode.signIn);

      expect(stateOf(h.container), same(before));
    });
  });

  group('SignInController.submit', () {
    test('signs into a seeded account', () async {
      final h = harness();
      h.auth.seedAccount(email: 'brian@example.com', password: 'hunter22');

      await h.it.submit(email: 'brian@example.com', password: 'hunter22');

      expect(h.auth.currentUser?.email, 'brian@example.com');
      expect(stateOf(h.container), const SignInState());
    });

    test('trims the address before sending it', () async {
      final h = harness();
      h.auth.seedAccount(email: 'brian@example.com', password: 'hunter22');

      await h.it.submit(email: '  brian@example.com  ', password: 'hunter22');

      expect(h.auth.currentUser?.email, 'brian@example.com');
    });

    test('creates an account in sign-up mode', () async {
      final h = harness();
      h.it.setMode(SignInMode.signUp);

      await h.it.submit(email: 'new@example.com', password: 'hunter22');

      expect(h.auth.currentUser?.email, 'new@example.com');
    });

    test('keeps the failure and stops submitting when refused', () async {
      final h = harness();
      h.auth.seedAccount(email: 'brian@example.com', password: 'hunter22');

      await h.it.submit(email: 'brian@example.com', password: 'wrong');

      final state = stateOf(h.container);
      expect(state.isSubmitting, isFalse);
      expect(state.failure?.reason, AuthFailureReason.invalidCredentials);
      expect(h.auth.currentUser, isNull);
    });

    test('is submitting while the request is in flight', () async {
      final h = harness();
      h.auth.seedAccount(email: 'brian@example.com', password: 'hunter22');

      final pending = h.it.submit(
        email: 'brian@example.com',
        password: 'hunter22',
      );

      expect(stateOf(h.container).isSubmitting, isTrue);
      await pending;
    });

    test('ignores a second submit while the first is in flight', () async {
      final h = harness();
      h.it.setMode(SignInMode.signUp);

      final first = h.it.submit(email: 'new@example.com', password: 'hunter22');
      final second = h.it.submit(
        email: 'other@example.com',
        password: 'hunter22',
      );
      await Future.wait([first, second]);

      expect(h.auth.currentUser?.email, 'new@example.com');
    });

    test('clears a previous failure before retrying', () async {
      final h = harness();
      h.auth.seedAccount(email: 'brian@example.com', password: 'hunter22');
      await h.it.submit(email: 'brian@example.com', password: 'wrong');

      final pending = h.it.submit(
        email: 'brian@example.com',
        password: 'hunter22',
      );

      expect(stateOf(h.container).failure, isNull);
      await pending;
    });

    test('keeps the reason the service reported', () async {
      final h = harness();
      h.auth.nextFailure = const AuthFailure(
        AuthFailureReason.tooManyRequests,
        'slow down',
      );

      await h.it.submit(email: 'brian@example.com', password: 'hunter22');

      expect(
        stateOf(h.container).failure?.reason,
        AuthFailureReason.tooManyRequests,
      );
    });

    /// Submits against a service that fails with [failure].
    Future<AuthFailure?> failureFrom(Failure failure) async {
      final auth = _MockAuthService();
      when(
        () => auth.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Err(failure));
      final container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      await container
          .read(signInControllerProvider.notifier)
          .submit(email: 'brian@example.com', password: 'hunter22');
      return stateOf(container).failure;
    }

    test('keeps an unreachable backend distinguishable', () async {
      // Flattened into `unknown` this reads as "something went wrong", which
      // tells someone with no signal nothing about why.
      expect(
        await failureFrom(const NetworkFailure('offline')),
        const AuthFailure(AuthFailureReason.network, 'offline'),
      );
    });

    test(
      'widens any other non-auth failure to an unknown AuthFailure',
      () async {
        // Nothing in the interface promises an AuthFailure specifically, so a
        // service that returns some other Failure still has to render.
        expect(
          await failureFrom(const UnknownFailure('boom')),
          const AuthFailure(AuthFailureReason.unknown, 'boom'),
        );
      },
    );
  });

  group('SignInController.sendPasswordReset', () {
    test('sends to the trimmed address and records it', () async {
      final h = harness();

      await h.it.sendPasswordReset('  brian@example.com ');

      expect(h.auth.resetEmailsSent, ['brian@example.com']);
      expect(stateOf(h.container).passwordResetSentTo, 'brian@example.com');
      expect(stateOf(h.container).isSubmitting, isFalse);
    });

    test('refuses an unusable address without calling the backend', () async {
      final h = harness();

      await h.it.sendPasswordReset('not-an-address');

      expect(h.auth.resetEmailsSent, isEmpty);
      expect(
        stateOf(h.container).failure?.reason,
        AuthFailureReason.invalidEmail,
      );
      expect(stateOf(h.container).passwordResetSentTo, isNull);
    });

    test('sending to a second address is a fresh state change', () async {
      final h = harness();

      await h.it.sendPasswordReset('one@example.com');
      await h.it.sendPasswordReset('two@example.com');

      expect(stateOf(h.container).passwordResetSentTo, 'two@example.com');
    });

    test('a later submit clears the reset confirmation', () async {
      final h = harness();
      h.auth.seedAccount(email: 'brian@example.com', password: 'hunter22');
      await h.it.sendPasswordReset('brian@example.com');

      await h.it.submit(email: 'brian@example.com', password: 'wrong');

      expect(stateOf(h.container).passwordResetSentTo, isNull);
    });

    test('surfaces a backend refusal instead of confirming', () async {
      final auth = _MockAuthService();
      when(() => auth.sendPasswordResetEmail(any())).thenAnswer(
        (_) async => const Err(
          AuthFailure(AuthFailureReason.tooManyRequests, 'slow down'),
        ),
      );
      final container = ProviderContainer(
        overrides: [authServiceProvider.overrideWithValue(auth)],
      );
      addTearDown(container.dispose);

      await container
          .read(signInControllerProvider.notifier)
          .sendPasswordReset('brian@example.com');

      final state = stateOf(container);
      expect(state.passwordResetSentTo, isNull);
      expect(state.failure?.reason, AuthFailureReason.tooManyRequests);
      expect(state.isSubmitting, isFalse);
    });

    test('is ignored while a submit is in flight', () async {
      final h = harness();
      h.auth.seedAccount(email: 'brian@example.com', password: 'hunter22');

      final pending = h.it.submit(
        email: 'brian@example.com',
        password: 'hunter22',
      );
      await h.it.sendPasswordReset('brian@example.com');
      await pending;

      expect(h.auth.resetEmailsSent, isEmpty);
    });
  });
}
