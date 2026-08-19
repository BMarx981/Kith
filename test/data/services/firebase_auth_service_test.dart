import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/services/firebase_auth_service.dart';
import 'package:kith/data/services/google_sign_in_service.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

void main() {
  final mockUser = MockUser(
    uid: 'uid-1',
    email: 'brian@example.com',
    displayName: 'Brian',
    photoURL: 'https://example.com/a.png',
  );

  /// Registers [code] to be thrown by the next call to any auth method.
  void throwCode(MockFirebaseAuth auth, String code, {String? message}) {
    whenCalling(
      Invocation.method(#signInWithEmailAndPassword, null),
    ).on(auth).thenThrow(FirebaseAuthException(code: code, message: message));
  }

  group('currentUser', () {
    test('is null when nobody is signed in', () {
      final service = FirebaseAuthService(MockFirebaseAuth());

      expect(service.currentUser, isNull);
    });

    test('maps the Firebase user onto AuthUser', () {
      final service = FirebaseAuthService(
        MockFirebaseAuth(signedIn: true, mockUser: mockUser),
      );

      expect(
        service.currentUser,
        const AuthUser(
          id: 'uid-1',
          email: 'brian@example.com',
          displayName: 'Brian',
          photoUrl: 'https://example.com/a.png',
        ),
      );
    });

    test('normalises an account with no address to an empty email', () {
      final service = FirebaseAuthService(
        MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'uid-2')),
      );

      expect(service.currentUser?.email, isEmpty);
      expect(service.currentUser?.displayName, isNull);
    });
  });

  group('authStateChanges', () {
    test('replays the current state, then maps sign-in and sign-out', () async {
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final service = FirebaseAuthService(auth);
      final seen = <AuthUser?>[];
      final subscription = service.authStateChanges().listen(seen.add);
      addTearDown(subscription.cancel);

      await service.signInWithEmail(
        email: 'brian@example.com',
        password: 'hunter22',
      );
      await service.signOut();
      await pumpEventQueue();

      // The leading null is the replay a new subscriber gets: Firebase reports
      // the current state on listen before reporting any change.
      expect(seen.map((user) => user?.id).toList(), [null, 'uid-1', null]);
    });
  });

  group('signInWithEmail', () {
    test('returns the signed-in user', () async {
      final service = FirebaseAuthService(
        MockFirebaseAuth(mockUser: mockUser),
      );

      final result = await service.signInWithEmail(
        email: 'brian@example.com',
        password: 'hunter22',
      );

      expect(result.valueOrNull?.id, 'uid-1');
    });

    test('translates Firebase error codes into domain failures', () async {
      const expected = <String, Failure>{
        'invalid-credential': AuthFailure(
          AuthFailureReason.invalidCredentials,
          'boom',
        ),
        'wrong-password': AuthFailure(
          AuthFailureReason.invalidCredentials,
          'boom',
        ),
        'user-not-found': AuthFailure(
          AuthFailureReason.invalidCredentials,
          'boom',
        ),
        'email-already-in-use': AuthFailure(
          AuthFailureReason.emailAlreadyInUse,
          'boom',
        ),
        'weak-password': AuthFailure(AuthFailureReason.weakPassword, 'boom'),
        'invalid-email': AuthFailure(AuthFailureReason.invalidEmail, 'boom'),
        'user-disabled': AuthFailure(AuthFailureReason.userDisabled, 'boom'),
        'too-many-requests': AuthFailure(
          AuthFailureReason.tooManyRequests,
          'boom',
        ),
        'operation-not-allowed': AuthFailure(
          AuthFailureReason.providerUnavailable,
          'boom',
        ),
        // What a project whose Authentication product was never provisioned
        // returns. Unmapped it reads as "something went wrong", which sends
        // whoever hits it looking for a bug in the app instead of at the
        // Firebase console.
        'configuration-not-found': AuthFailure(
          AuthFailureReason.providerUnavailable,
          'boom',
        ),
        'api-key-not-valid': AuthFailure(
          AuthFailureReason.providerUnavailable,
          'boom',
        ),
        'app-not-authorized': AuthFailure(
          AuthFailureReason.providerUnavailable,
          'boom',
        ),
        'network-request-failed': NetworkFailure('boom'),
        'something-new': AuthFailure(AuthFailureReason.unknown, 'boom'),
      };

      for (final entry in expected.entries) {
        final auth = MockFirebaseAuth(mockUser: mockUser);
        throwCode(auth, entry.key, message: 'boom');

        final result = await FirebaseAuthService(auth).signInWithEmail(
          email: 'brian@example.com',
          password: 'hunter22',
        );

        expect(
          result.failureOrNull,
          entry.value,
          reason: 'code ${entry.key} mapped to the wrong failure',
        );
      }
    });

    test(
      'recognises a configuration error the iOS SDK hid in the message',
      () async {
        // The iOS SDK reports a project with no Authentication product as a
        // generic internal error; the backend's actual complaint survives only
        // in the message body. Left unread it says "something went wrong" for a
        // setup problem with a one-click fix.
        final auth = MockFirebaseAuth(mockUser: mockUser);
        throwCode(
          auth,
          'internal-error',
          message:
              'An internal error has occurred. [ Error '
              'Domain=FIRAuthErrorDomain Code=17999 ... '
              'CONFIGURATION_NOT_FOUND ]',
        );

        final result = await FirebaseAuthService(auth).signInWithEmail(
          email: 'brian@example.com',
          password: 'hunter22',
        );

        expect(
          result.failureOrNull,
          isA<AuthFailure>().having(
            (failure) => failure.reason,
            'reason',
            AuthFailureReason.providerUnavailable,
          ),
        );
      },
    );

    test('leaves an internal error that says nothing more unknown', () async {
      final auth = MockFirebaseAuth(mockUser: mockUser);
      throwCode(auth, 'internal-error', message: 'boom');

      final result = await FirebaseAuthService(auth).signInWithEmail(
        email: 'brian@example.com',
        password: 'hunter22',
      );

      expect(
        result.failureOrNull,
        const AuthFailure(AuthFailureReason.unknown, 'boom'),
      );
    });

    test('wraps a non-auth Firebase error as an unknown failure', () async {
      final auth = MockFirebaseAuth(mockUser: mockUser);
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(
            FirebaseException(plugin: 'firebase_auth', message: 'backend down'),
          );

      final result = await FirebaseAuthService(auth).signInWithEmail(
        email: 'brian@example.com',
        password: 'hunter22',
      );

      expect(
        result.failureOrNull,
        isA<UnknownFailure>().having(
          (failure) => failure.message,
          'message',
          'backend down',
        ),
      );
    });

    test('falls back to the error code when there is no message', () async {
      final auth = MockFirebaseAuth(mockUser: mockUser);
      throwCode(auth, 'user-disabled');

      final result = await FirebaseAuthService(auth).signInWithEmail(
        email: 'brian@example.com',
        password: 'hunter22',
      );

      expect(result.failureOrNull?.message, 'user-disabled');
    });
  });

  group('signUpWithEmail', () {
    test('creates the account and reports the new user', () async {
      final service = FirebaseAuthService(MockFirebaseAuth());

      final result = await service.signUpWithEmail(
        email: 'new@example.com',
        password: 'hunter22',
      );

      expect(result.valueOrNull?.email, 'new@example.com');
    });

    test('applies the display name when one is supplied', () async {
      final service = FirebaseAuthService(MockFirebaseAuth());

      final result = await service.signUpWithEmail(
        email: 'new@example.com',
        password: 'hunter22',
        displayName: 'Brian',
      );

      expect(result.valueOrNull?.displayName, 'Brian');
    });

    test('surfaces a rejected sign-up as a domain failure', () async {
      final auth = MockFirebaseAuth();
      whenCalling(
        Invocation.method(#createUserWithEmailAndPassword, null),
      ).on(auth).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      final result = await FirebaseAuthService(auth).signUpWithEmail(
        email: 'taken@example.com',
        password: 'hunter22',
      );

      expect(
        result.failureOrNull,
        isA<AuthFailure>().having(
          (failure) => failure.reason,
          'reason',
          AuthFailureReason.emailAlreadyInUse,
        ),
      );
    });
  });

  group('sendPasswordResetEmail', () {
    test('succeeds for a known address', () async {
      final service = FirebaseAuthService(MockFirebaseAuth());

      final result = await service.sendPasswordResetEmail('brian@example.com');

      expect(result.isOk, isTrue);
    });

    test('reports success for an unknown address', () async {
      final auth = MockFirebaseAuth();
      whenCalling(
        Invocation.method(#sendPasswordResetEmail, null),
      ).on(auth).thenThrow(FirebaseAuthException(code: 'user-not-found'));

      final result = await FirebaseAuthService(
        auth,
      ).sendPasswordResetEmail('nobody@example.com');

      expect(
        result.isOk,
        isTrue,
        reason: 'a failure here would let callers enumerate accounts',
      );
    });

    test('still surfaces other failures', () async {
      final auth = MockFirebaseAuth();
      whenCalling(
        Invocation.method(#sendPasswordResetEmail, null),
      ).on(auth).thenThrow(FirebaseAuthException(code: 'invalid-email'));

      final result = await FirebaseAuthService(
        auth,
      ).sendPasswordResetEmail('not-an-email');

      expect(
        result.failureOrNull,
        isA<AuthFailure>().having(
          (failure) => failure.reason,
          'reason',
          AuthFailureReason.invalidEmail,
        ),
      );
    });
  });

  group('signOut', () {
    test('clears the current user', () async {
      final service = FirebaseAuthService(
        MockFirebaseAuth(signedIn: true, mockUser: mockUser),
      );

      final result = await service.signOut();

      expect(result.isOk, isTrue);
      expect(service.currentUser, isNull);
    });

    test('surfaces a failed sign-out', () async {
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      whenCalling(Invocation.method(#signOut, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      final result = await FirebaseAuthService(auth).signOut();

      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('signInWithGoogle', () {
    test('exchanges Google tokens for a Firebase session', () async {
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final google = _StubGoogleSignInService(
        const Ok(GoogleTokens(idToken: 'id-token', accessToken: 'access')),
      );
      final service = FirebaseAuthService(auth, google);

      final result = await service.signInWithGoogle();

      expect(
        result.valueOrNull,
        const AuthUser(
          id: 'uid-1',
          email: 'brian@example.com',
          displayName: 'Brian',
          photoUrl: 'https://example.com/a.png',
        ),
      );
      expect(google.authenticateCalls, 1);
    });

    test('passes a cancelled picker straight through', () async {
      final google = _StubGoogleSignInService(
        const Err(
          AuthFailure(AuthFailureReason.cancelled, 'Sign-in was cancelled.'),
        ),
      );
      final service = FirebaseAuthService(MockFirebaseAuth(), google);

      final result = await service.signInWithGoogle();

      expect(
        result.failureOrNull,
        isA<AuthFailure>().having(
          (failure) => failure.reason,
          'reason',
          AuthFailureReason.cancelled,
        ),
      );
    });

    test('does not reach Firebase when Google itself failed', () async {
      final auth = MockFirebaseAuth(mockUser: mockUser);
      final google = _StubGoogleSignInService(
        const Err(AuthFailure(AuthFailureReason.network, 'Offline.')),
      );
      final service = FirebaseAuthService(auth, google);

      final result = await service.signInWithGoogle();

      expect(result.failureOrNull, isA<AuthFailure>());
      expect(auth.currentUser, isNull);
    });

    test('rejects a sign-in that produced no usable token', () async {
      final google = _StubGoogleSignInService(const Ok(GoogleTokens()));
      final service = FirebaseAuthService(MockFirebaseAuth(), google);

      final result = await service.signInWithGoogle();

      expect(
        result.failureOrNull,
        isA<AuthFailure>().having(
          (failure) => failure.reason,
          'reason',
          AuthFailureReason.unknown,
        ),
      );
    });

    test('translates a Firebase rejection into a domain failure', () async {
      final auth = MockFirebaseAuth(mockUser: mockUser);
      whenCalling(Invocation.method(#signInWithCredential, null))
          .on(auth)
          .thenThrow(
            FirebaseAuthException(
              code: 'account-exists-with-different-credential',
              message: 'Already registered another way.',
            ),
          );
      final google = _StubGoogleSignInService(
        const Ok(GoogleTokens(idToken: 'id-token')),
      );
      final service = FirebaseAuthService(auth, google);

      final result = await service.signInWithGoogle();

      expect(
        result.failureOrNull,
        isA<AuthFailure>().having(
          (failure) => failure.reason,
          'reason',
          AuthFailureReason.accountExistsWithDifferentCredential,
        ),
      );
    });

    test('reports itself unavailable when no Google service is wired '
        'up', () async {
      final service = FirebaseAuthService(MockFirebaseAuth());

      expect(
        (await service.signInWithGoogle()).failureOrNull,
        isA<AuthFailure>().having(
          (failure) => failure.reason,
          'reason',
          AuthFailureReason.providerUnavailable,
        ),
      );
    });
  });

  group('signInWithApple', () {
    test('reports itself as unavailable until it is wired up', () async {
      final service = FirebaseAuthService(MockFirebaseAuth());

      expect(
        (await service.signInWithApple()).failureOrNull,
        isA<AuthFailure>().having(
          (failure) => failure.reason,
          'reason',
          AuthFailureReason.providerUnavailable,
        ),
      );
    });
  });

  group('signOut', () {
    test('also ends the Google session so the picker returns', () async {
      final google = _StubGoogleSignInService(const Ok(GoogleTokens()));
      final service = FirebaseAuthService(
        MockFirebaseAuth(signedIn: true, mockUser: mockUser),
        google,
      );

      await service.signOut();

      expect(google.signOutCalls, 1);
    });

    test('still ends the Firebase session when Google sign-out throws',
        () async {
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final service = FirebaseAuthService(
        auth,
        _StubGoogleSignInService(const Ok(GoogleTokens()), signOutThrows: true),
      );

      final result = await service.signOut();

      expect(result.isOk, isTrue);
      expect(auth.currentUser, isNull);
    });
  });
}

/// Stands in for the plugin-backed Google service, which cannot run in a unit
/// test: it answers with whatever result the case under test needs and counts
/// the calls it received.
class _StubGoogleSignInService implements GoogleSignInService {
  _StubGoogleSignInService(this._result, {this.signOutThrows = false});

  final Result<GoogleTokens> _result;
  final bool signOutThrows;

  int authenticateCalls = 0;
  int signOutCalls = 0;

  @override
  Future<Result<GoogleTokens>> authenticate() async {
    authenticateCalls++;
    return _result;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutThrows) throw StateError('Google sign-out failed.');
  }

  /// Signing in never asks for a scope; the calendar does, and it is tested
  /// where it lives.
  @override
  Future<Result<String>> authorizeScopes(List<String> scopes) =>
      throw UnimplementedError();

  @override
  Future<String?> existingAccessToken(List<String> scopes) =>
      throw UnimplementedError();
}
