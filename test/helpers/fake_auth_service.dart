import 'dart:async';

import 'package:kith/core/result/failure.dart';
import 'package:kith/core/result/result.dart';
import 'package:kith/data/models/auth_user.dart';
import 'package:kith/data/services/auth_service.dart';

/// An in-memory [AuthService] for unit and widget tests.
///
/// Accounts live in a map keyed by email, so a sign-up followed by a sign-in
/// behaves the way the real backend does without any network or emulator.
class FakeAuthService implements AuthService {
  FakeAuthService({AuthUser? initialUser}) : _currentUser = initialUser;

  final _controller = StreamController<AuthUser?>.broadcast();
  final _passwords = <String, String>{};
  final _accounts = <String, AuthUser>{};

  AuthUser? _currentUser;
  var _nextUid = 0;

  /// Failure to return from the next call to any sign-in method, instead of
  /// succeeding. Cleared once consumed.
  AuthFailure? nextFailure;

  /// Addresses passed to [sendPasswordResetEmail], oldest first.
  final resetEmailsSent = <String>[];

  /// Registers an account the tests can sign into.
  void seedAccount({
    required String email,
    required String password,
    String? displayName,
    String? photoUrl,
  }) {
    final user = AuthUser(
      id: 'uid-${++_nextUid}',
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
    _accounts[email] = user;
    _passwords[email] = password;
  }

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() {
    late StreamController<AuthUser?> listener;
    StreamSubscription<AuthUser?>? subscription;
    listener = StreamController<AuthUser?>(
      onListen: () {
        // Seed with the current state before forwarding, so a subscriber that
        // attaches after sign-in still sees the user, as Firebase does.
        listener.add(_currentUser);
        subscription = _controller.stream.listen(listener.add);
      },
      onCancel: () => subscription?.cancel(),
    );
    return listener.stream;
  }

  @override
  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final injected = _takeFailure();
    if (injected != null) return Err(injected);
    if (_accounts.containsKey(email)) {
      return const Err(
        AuthFailure(
          AuthFailureReason.emailAlreadyInUse,
          'That address already has an account.',
        ),
      );
    }
    seedAccount(email: email, password: password, displayName: displayName);
    return Ok(_emit(_accounts[email]!));
  }

  @override
  Future<Result<AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final injected = _takeFailure();
    if (injected != null) return Err(injected);
    final user = _accounts[email];
    if (user == null || _passwords[email] != password) {
      return const Err(
        AuthFailure(
          AuthFailureReason.invalidCredentials,
          'That email and password do not match an account.',
        ),
      );
    }
    return Ok(_emit(user));
  }

  @override
  Future<Result<AuthUser>> signInWithGoogle() =>
      _federatedSignIn('google@example.com', 'Google User');

  @override
  Future<Result<AuthUser>> signInWithApple() =>
      _federatedSignIn('apple@example.com', 'Apple User');

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    resetEmailsSent.add(email);
    return const Ok(null);
  }

  @override
  Future<Result<void>> signOut() async {
    _currentUser = null;
    _controller.add(null);
    return const Ok(null);
  }

  /// Releases the state stream. Register with `addTearDown`.
  Future<void> dispose() => _controller.close();

  Future<Result<AuthUser>> _federatedSignIn(
    String email,
    String displayName,
  ) async {
    final injected = _takeFailure();
    if (injected != null) return Err(injected);
    if (!_accounts.containsKey(email)) {
      seedAccount(email: email, password: '', displayName: displayName);
    }
    return Ok(_emit(_accounts[email]!));
  }

  AuthFailure? _takeFailure() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }

  AuthUser _emit(AuthUser user) {
    _currentUser = user;
    _controller.add(user);
    return user;
  }
}
