import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/features/auth/application/auth_providers.dart';

import '../../../helpers/fake_auth_service.dart';

void main() {
  const user = AuthUser(
    id: 'uid-1',
    email: 'brian@example.com',
    displayName: 'Brian',
  );

  ({
    ProviderContainer container,
    FakeAuthService auth,
    List<AuthUser?> seen,
  })
  harness({AuthUser? initialUser}) {
    final auth = FakeAuthService(initialUser: initialUser);
    final container = ProviderContainer(
      overrides: [authServiceProvider.overrideWithValue(auth)],
    );
    // A stream provider only subscribes while something listens to it. The
    // router watches the auth state for the app's lifetime; these tests hold
    // the equivalent subscription and record what it saw.
    final seen = <AuthUser?>[];
    final subscription = container.listen(authStateChangesProvider, (_, next) {
      if (next.hasValue) seen.add(next.value);
    }, fireImmediately: true);
    addTearDown(subscription.close);
    addTearDown(container.dispose);
    addTearDown(auth.dispose);
    return (container: container, auth: auth, seen: seen);
  }

  group('authServiceProvider', () {
    test('throws when read without an override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(authServiceProvider),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.exception,
            'exception',
            isA<UnimplementedError>(),
          ),
        ),
      );
    });

    test('yields the overridden service', () {
      final h = harness();

      expect(h.container.read(authServiceProvider), same(h.auth));
    });
  });

  group('authStateChangesProvider', () {
    test('starts loading before the backend reports', () {
      final h = harness();

      expect(h.container.read(authStateChangesProvider).isLoading, isTrue);
    });

    test('emits null when nobody is signed in', () async {
      final h = harness();

      await expectLater(
        h.container.read(authStateChangesProvider.future),
        completion(isNull),
      );
    });

    test('replays an already signed-in user to a late subscriber', () async {
      final h = harness(initialUser: user);

      await expectLater(
        h.container.read(authStateChangesProvider.future),
        completion(user),
      );
    });

    test('tracks sign-in and sign-out', () async {
      final h = harness();
      h.auth.seedAccount(email: user.email, password: 'hunter22');
      await h.container.read(authStateChangesProvider.future);

      await h.auth.signInWithEmail(email: user.email, password: 'hunter22');
      await pumpEventQueue();
      await h.auth.signOut();
      await pumpEventQueue();

      expect(h.seen.map((u) => u?.email).toList(), [null, user.email, null]);
    });
  });

  group('currentUserProvider', () {
    test('is null while the auth state is still loading', () {
      final h = harness(initialUser: user);

      expect(h.container.read(currentUserProvider), isNull);
    });

    test('exposes the user once the stream has emitted', () async {
      final h = harness(initialUser: user);
      await h.container.read(authStateChangesProvider.future);

      expect(h.container.read(currentUserProvider), user);
    });

    test('goes back to null after sign-out', () async {
      final h = harness(initialUser: user);
      await h.container.read(authStateChangesProvider.future);

      await h.auth.signOut();
      await pumpEventQueue();

      expect(h.container.read(currentUserProvider), isNull);
    });
  });

  group('FakeAuthService', () {
    test('rejects a wrong password with invalidCredentials', () async {
      final h = harness();
      h.auth.seedAccount(email: user.email, password: 'hunter22');

      final result = await h.auth.signInWithEmail(
        email: user.email,
        password: 'wrong',
      );

      expect(
        result.failureOrNull,
        isA<AuthFailure>().having(
          (f) => f.reason,
          'reason',
          AuthFailureReason.invalidCredentials,
        ),
      );
    });

    test('rejects a duplicate sign-up', () async {
      final h = harness();
      h.auth.seedAccount(email: user.email, password: 'hunter22');

      final result = await h.auth.signUpWithEmail(
        email: user.email,
        password: 'hunter22',
      );

      expect(
        result.failureOrNull,
        isA<AuthFailure>().having(
          (f) => f.reason,
          'reason',
          AuthFailureReason.emailAlreadyInUse,
        ),
      );
    });

    test('returns an injected failure once, then behaves normally', () async {
      final h = harness();
      h.auth
        ..seedAccount(email: user.email, password: 'hunter22')
        ..nextFailure = const AuthFailure(
          AuthFailureReason.userDisabled,
          'disabled',
        );

      final first = await h.auth.signInWithEmail(
        email: user.email,
        password: 'hunter22',
      );
      final second = await h.auth.signInWithEmail(
        email: user.email,
        password: 'hunter22',
      );

      expect(first.isErr, isTrue);
      expect(second.isOk, isTrue);
    });

    test('federated sign-in creates and reuses one account', () async {
      final h = harness();

      final first = await h.auth.signInWithGoogle();
      final second = await h.auth.signInWithGoogle();

      expect(first.valueOrNull, second.valueOrNull);
      expect(h.auth.currentUser, first.valueOrNull);
    });

    test('records password reset requests', () async {
      final h = harness();

      final result = await h.auth.sendPasswordResetEmail(user.email);

      expect(result.isOk, isTrue);
      expect(h.auth.resetEmailsSent, [user.email]);
    });
  });
}
