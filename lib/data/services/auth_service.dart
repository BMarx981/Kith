import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/auth_user.dart';

/// The app's view of authentication.
///
/// Implementations translate backend errors into `AuthFailure` before
/// returning; nothing above this interface sees a `FirebaseAuthException`.
/// Every method that can fail returns a [Result] rather than throwing.
abstract interface class AuthService {
  /// Emits the current identity, then again on every sign-in and sign-out.
  ///
  /// Emits null when nobody is signed in. The stream is expected to be
  /// broadcast and to replay the latest value to new listeners, so a provider
  /// that starts listening after sign-in still sees the user.
  Stream<AuthUser?> authStateChanges();

  /// The identity right now, without waiting on [authStateChanges].
  ///
  /// Null when nobody is signed in, and also before the backend has restored
  /// a persisted session on cold start; callers that need to tell those apart
  /// must watch [authStateChanges].
  AuthUser? get currentUser;

  /// Creates an account and signs into it.
  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Signs into an existing email/password account.
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Signs in through Google.
  ///
  /// A user who dismisses the account sheet yields
  /// `AuthFailureReason.cancelled`, which is not worth surfacing as an error.
  Future<Result<AuthUser>> signInWithGoogle();

  /// Signs in through Apple, under the same cancellation contract as
  /// [signInWithGoogle].
  Future<Result<AuthUser>> signInWithApple();

  /// Sends a password reset link.
  ///
  /// Succeeds whether or not the address has an account, so the response
  /// cannot be used to enumerate registered emails.
  Future<Result<void>> sendPasswordResetEmail(String email);

  /// Ends the session. [authStateChanges] then emits null.
  Future<Result<void>> signOut();
}
