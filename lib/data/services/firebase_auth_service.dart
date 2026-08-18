import 'package:firebase_auth/firebase_auth.dart';
import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/services/auth_service.dart';

/// [AuthService] backed by Firebase Auth.
///
/// This is the only place in the app that names a Firebase Auth type: every
/// `FirebaseAuthException` is translated into a domain [Failure] before it
/// leaves.
class FirebaseAuthService implements AuthService {
  const FirebaseAuthService(this._auth);

  final FirebaseAuth _auth;

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() =>
      _auth.authStateChanges().map(_mapUser);

  @override
  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) => _guard(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return _noUser;
    if (displayName == null) return Ok(_mapSignedInUser(user));
    await user.updateDisplayName(displayName);
    return Ok(_mapSignedInUser(user).copyWith(displayName: displayName));
  });

  @override
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(() async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    return user == null ? _noUser : Ok(_mapSignedInUser(user));
  });

  @override
  Future<Result<AuthUser>> signInWithGoogle() async => _notWiredUp('Google');

  @override
  Future<Result<AuthUser>> signInWithApple() async => _notWiredUp('Apple');

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) => _guard(() async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      // Reporting "no such account" would turn the reset form into an
      // email-enumeration oracle, so an unknown address looks like success.
      if (error.code != 'user-not-found') rethrow;
    }
    return const Ok(null);
  });

  @override
  Future<Result<void>> signOut() => _guard(() async {
    await _auth.signOut();
    return const Ok(null);
  });

  /// Returned when Firebase reports success but hands back no user. Should not
  /// happen; treated as a failure rather than an assertion so a bad response
  /// cannot crash a sign-in screen.
  static const _noUser = Err<AuthUser>(
    UnknownFailure('Sign-in succeeded but returned no account.'),
  );

  static Result<AuthUser> _notWiredUp(String provider) => Err(
    AuthFailure(
      AuthFailureReason.providerUnavailable,
      '$provider sign-in is not available in this build.',
    ),
  );

  /// Firebase permits accounts with no address (phone, anonymous). Kith uses
  /// neither, so a null address is normalised rather than widening the model.
  static AuthUser _mapSignedInUser(User user) => AuthUser(
    id: user.uid,
    email: user.email ?? '',
    displayName: user.displayName,
    photoUrl: user.photoURL,
  );

  static AuthUser? _mapUser(User? user) =>
      user == null ? null : _mapSignedInUser(user);

  static Future<Result<T>> _guard<T>(
    Future<Result<T>> Function() body,
  ) async {
    try {
      return await body();
    } on FirebaseAuthException catch (error) {
      return Err(_failureFor(error));
    } on FirebaseException catch (error) {
      return Err(
        UnknownFailure(error.message ?? error.code, cause: error),
      );
    }
  }

  /// What the backend calls a project whose Authentication product was never
  /// provisioned. The Android SDK surfaces it as a code; the iOS one buries it
  /// in the message of a generic `internal-error`.
  static const _noAuthProduct = 'CONFIGURATION_NOT_FOUND';

  static Failure _failureFor(FirebaseAuthException error) {
    final message = error.message ?? error.code;
    // Read out of the message because on iOS there is nowhere else to read it
    // from. Matching on message text is brittle, and worth it here: the
    // alternative is "something went wrong" for a setup problem whose fix is
    // one switch in the Firebase console.
    if (message.contains(_noAuthProduct)) {
      return AuthFailure(AuthFailureReason.providerUnavailable, message);
    }
    return switch (error.code) {
      // Firebase collapses wrong-password and unknown-account into
      // invalid-credential when email enumeration protection is on; the older
      // codes still arrive from projects that have it off.
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => AuthFailure(
        AuthFailureReason.invalidCredentials,
        message,
      ),
      'email-already-in-use' => AuthFailure(
        AuthFailureReason.emailAlreadyInUse,
        message,
      ),
      'weak-password' => AuthFailure(AuthFailureReason.weakPassword, message),
      'invalid-email' => AuthFailure(AuthFailureReason.invalidEmail, message),
      'user-disabled' => AuthFailure(AuthFailureReason.userDisabled, message),
      'too-many-requests' => AuthFailure(
        AuthFailureReason.tooManyRequests,
        message,
      ),
      // `operation-not-allowed` is the provider being switched off. The
      // rest are the project itself not being set up: Authentication never
      // provisioned, or an API key that does not belong to it. All of them
      // mean the same thing to whoever is looking at the screen, and none of
      // them are worth retrying.
      'operation-not-allowed' ||
      'configuration-not-found' ||
      'api-key-not-valid' ||
      'app-not-authorized' => AuthFailure(
        AuthFailureReason.providerUnavailable,
        message,
      ),
      'network-request-failed' => NetworkFailure(message),
      _ => AuthFailure(AuthFailureReason.unknown, message),
    };
  }
}
