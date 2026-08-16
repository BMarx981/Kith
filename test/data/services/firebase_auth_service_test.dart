import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/services/firebase_auth_service.dart';
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

  group('federated providers', () {
    test('report themselves as unavailable until they are wired up', () async {
      final service = FirebaseAuthService(MockFirebaseAuth());

      for (final result in [
        await service.signInWithGoogle(),
        await service.signInWithApple(),
      ]) {
        expect(
          result.failureOrNull,
          isA<AuthFailure>().having(
            (failure) => failure.reason,
            'reason',
            AuthFailureReason.providerUnavailable,
          ),
        );
      }
    });
  });
}
